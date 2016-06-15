#!/usr/bin/perl -w

use strict;

use TimUtil;
use TimDB;

use constant REPORT_ALL	=> 0;
use constant REPORT_HOSTS	=> 1;
use constant REPORT_PACKAGES	=> 2;
use constant REPORT_GUESTS	=> 3;

my %Hosts;

our $Limit = FALSE;
our $List = FALSE;
our $Report = REPORT_ALL;
our $Host = "";
our $Package = "";
our $Guest = "";
our $Datacenter = "";
our $Rebooted = undef();

our %ParamDefs = (
    "limit"	=> {
        name	=> "Limit",
        type	=> PARAMTYPE_BOOL,
        var	=> \$Limit,
        usage	=> "--limit|-l",
        comment	=> "Limit the number of iterations",
    },
    "list"	=> {
        name	=> "List",
        type	=> PARAMTYPE_BOOL,
        var	=> \$List,
        usage	=> "--list",
        comment	=> "List the desired entities (requires --report=<hosts|packages>)",
    },
    "report"	=> {
        name	=> "Report",
        type	=> PARAMTYPE_ENUM,
        var	=> \$Report,
        usage	=> "--report|-r",
        comment	=> "Select the report type",
        selectors	=> {
            all		=> REPORT_ALL,
            hosts	=> REPORT_HOSTS,
            packages	=> REPORT_PACKAGES,
            guests	=> REPORT_GUESTS,
        },
    },
    "host"	=> {
        name	=> "Host",
        type	=> PARAMTYPE_STRING,
        var	=> \$Host,
        usage	=> "--host",
        comment	=> "Specify the host to scope by",
    },
    "package"	=> {
        name	=> "Package",
        type	=> PARAMTYPE_STRING,
        var	=> \$Package,
        usage	=> "--package",
        comment	=> "Specify the package to scope by",
    },
    "guest"	=> {
        name	=> "Guest",
        type	=> PARAMTYPE_STRING,
        var	=> \$Guest,
        usage	=> "--guest",
        comment	=> "Specify the guest to scope by",
    },
    "dc"	=> {
        name	=> "Datacenter",
        type	=> PARAMTYPE_STRING,
        var	=> \$Datacenter,
        usage	=> "--dc",
        comment	=> "Specify the datacenter to scope by",
    },
    "rebooted"	=> {
        name	=> "Rebooted",
        type	=> PARAMTYPE_BOOL,
        var	=> \$Rebooted,
        usage	=> "--rebooted",
        comment	=> "Show only hosts whose rebooted flag matches",
    },
);

our $DSN = {
    dbhost	=> "localhost",
    dbname	=> "xenscan",
    dbuser	=> "xenscan",
    dbpass	=> qw/xenscan/,
    dbbackend	=> "Pg",
    dbport	=> 5432,
};

my $DB = TimDB->new($DSN);

sub report_host {
    my ($host) = @_;

    printf("Packages on host %s:\n", $host->{hostname});

    foreach my $package ( @{$host->{packages}} ) {
        printf("  %s\n", $package->{name});
        last if $Limit;
    }

    printf("\n");
}

sub report_hosts {

    printf("NOTE: Showing only hosts that have%s been rebooted.\n\n", $Rebooted?"":" NOT");

    if ( $List ) {
        printf("Hosts found:\n\n");
        foreach my $host ( values(%Hosts) ) {
            printf("  %s\n", $host->{hostname});
        last if $Limit;
        }
    }
    elsif ( $Guest ne "" ) {
        my $fmt = "%-24s\t%-24s\n";
        printf($fmt, "Guest", "Host");
        printf($fmt, "=" x 24, "=" x 24);
        foreach my $host ( values(%Hosts) ) {
            printf($fmt, $host->{guestname}, $host->{hostname});
        }
    }
    else {
        printf("Packages by host:\n\n");
        if ( $Host eq "" ) {
            foreach my $host ( values(%Hosts) ) {
                report_host($host);
                last if $Limit;
            }
        }
        else {
            report_host(grep({$_->{hostname} =~ $Host} values(%Hosts)));
        }
    }
}

sub report_package {
    my ($package) = @_;

    printf("Hosts with package %s:\n", $package->{name});

    my @hosts;

    my $query="SELECT hosts.* FROM hosts,installs WHERE hosts.id=installs.host_id AND installs.package_id=$package->{id}";

    $DB->get_hashref_array(\@hosts, $query);
    debugdump(DEBUG_DUMP, "hosts", \@hosts);

    foreach my $host ( @hosts ) {
        printf("  %s\n", $host->{hostname});
        last if $Limit;
    }

    printf("\n");
}

sub report_packages {

    my @packages;

    $DB->get_hashref_array(\@packages, "SELECT * FROM packages ORDER BY name");
    debugdump(DEBUG_DUMP, "packages", \@packages);

    if ( $List ) {
        printf("Packages found:\n\n");
        foreach my $package ( @packages ) {
            printf("  %s\n", $package->{name});
            last if $Limit;
        }
    }
    else {
        printf("Hosts by package:\n\n");
        if ( $Package eq "" ) {
            foreach my $package ( @packages ) {
                report_package($package);
                last if $Limit;
            }
        }
        else {
            report_package(grep({$_->{name} eq $Package} @packages));
        }
    }
}

sub report_guest {
    my ($guest) = @_;

    debugdump(DEBUG_DUMP, "guest", \$guest);
    my $guestinfo = {};
    my $query="SELECT guests.*,hosts.hostname FROM hosts,guests WHERE hosts.id=guests.host_id AND guests.id=$guest->{id}";

    $DB->get_hashref($guestinfo, $query);
    debugdump(DEBUG_DUMP, "guestinfo", \$guestinfo);

    printf("Guest '%s' resides on host '%s'\n\n", $guestinfo->{guestname}, $guestinfo->{hostname});
}

sub report_guests {

    if ( $List ) {
        printf("Guests found:\n\n");
        foreach my $host ( values(%Hosts) ) {
            foreach my $guest ( @{$host->{guests}} ) {
                printf("  %s\n", $guest->{guestname});
                last if $Limit;
            }
        }
    }
    else {
        printf("Guests by host:\n\n");

        if ( $Host eq "" ) {

            foreach my $host ( values(%Hosts) ) {

                printf("%s:\n", $host->{hostname});

                foreach my $guest ( @{$host->{guests}} ) {
                    printf("  %s\n", $guest->{guestname});
                    last if $Limit;
                }

                printf("\n");

                last if $Limit;
            }
        }
        else {

            if ( exists($Hosts{$Host}) ) {

                printf("%s:\n", $Host);

                foreach my $guest ( @{$Hosts{$Host}{guests}} ) {
                    printf("  %s\n", $guest->{guestname});
                    last if $Limit;
                }
            }
            else {
                debugprint(DEBUG_WARN, "Host not found: '%s'", $Host);
            }
        }
    }
}

sub gather_data
{
    debugprint(DEBUG_TRACE, "Gathering host, guest, and package information...");

    my @hosts;
    my $queryspec = {
        action	=> ACTION_SELECT,
        select	=> "hosts.*",
        join	=> "hosts",
        order	=> "hostname",
    };

    push(@{$queryspec->{where}}, "rebooted='$Rebooted'") if defined($Rebooted);
    push(@{$queryspec->{where}}, "datacenter='$Datacenter'") if defined($Datacenter);

    my $query = $DB->query($queryspec);
    $DB->get_hashref_array(\@hosts, $query);
    map({$Hosts{$_->{hostname}} = $_} @hosts);

    foreach my $host ( @hosts ) {

        # Gather data about guests on this host...
        my $guests = [];

        $queryspec = {
            action	=> ACTION_SELECT,
            select	=> "*",
            join	=> "guests",
            where	=> [
                "guests.host_id=$host->{id}"
            ]
        };

        $query = $DB->query($queryspec);
        $DB->get_hashref_array($guests, $query);
        debugdump(DEBUG_DUMP, "guests", $guests);

        $Hosts{$host->{hostname}}{guests} = $guests;

        # Gather data on packages installed on this host...
        my $packages = [];

        $queryspec = {
            action	=> ACTION_SELECT,
            select	=> "packages.*",
            join	=> "packages,installs",
            where	=> [
                "packages.id=installs.package_id",
                "installs.host_id=$host->{id}",
            ],
        };

        $query = $DB->query($queryspec);
        $DB->get_hashref_array($packages, $query);
        debugdump(DEBUG_DUMP, "packages", $packages);

        $Hosts{$host->{hostname}}{packages} = $packages;

        last if $Limit;
    }

    debugdump(DEBUG_DUMP, "Hosts", \%Hosts);
}

# Main Program
{
    # Set up...
    register_params(\%ParamDefs);

    parse_args();

    gather_data();

    printf("Xen Server Package Inventory\n\n");

    if ( $Report == REPORT_ALL ) {
        report_hosts();
        report_packages();
        report_guests();
    }
    elsif ( $Report == REPORT_HOSTS ) {
        report_hosts();
    }
    elsif ( $Report == REPORT_PACKAGES ) {
        report_packages();
    }
    elsif ( $Report == REPORT_GUESTS ) {
        report_guests();
    }
    else {
        debugprint(DEBUG_ERROR, "Invalid report type requested: %s", $Report);
    }
}

