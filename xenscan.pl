#!/usr/bin/perl -w

use strict;

use TimUtil;
use TimDB;

our $Limit = FALSE;

our %ParamDefs = (
    "limit"     => {
        name    => "Limit",
        type    => PARAMTYPE_BOOL,
        var     => \$Limit,
        usage   => "--limit|-l",
        comment => "Limit the number of iterations",
    },
);

our $DSN = {
    dbhost      => "localhost",
    dbname      => "xenscan",
    dbuser      => "xenscan",
    dbpass      => qw/xenscan/,
    dbbackend   => "Pg",
    dbport      => 5432,
};

my $DB = TimDB->new($DSN);

sub query_guest {
    my ($guest_name) = @_;

    debugprint(DEBUG_TRACE, "Querying guest name '%s'...", $guest_name);
    my $guest_id = 0;
    $DB->get_int(\$guest_id, "SELECT id FROM guests WHERE guestname='$guest_name'");

    debugprint(DEBUG_TRACE, "Returning '%d'", $guest_id);
    return $guest_id;
}

sub register_guest {
    my ($host_id,$guest_name) = @_;

    # Query the database for this guest...
    my $guest_id = query_guest($guest_name);

    if ( $guest_id == 0 ) {
        debugprint(DEBUG_INFO, "Registering guest '%s'...", $guest_name);
        my $query = "INSERT INTO guests (host_id,guestname) VALUES($host_id,'$guest_name')";
        $DB->dbexec($query) unless $TestOnly;

        # Now, query it again...
        $guest_id = query_guest($guest_name);
    }
    else {
        debugprint(DEBUG_TRACE, "Guest already registered as '%d'", $guest_id);
    }

    debugprint(DEBUG_TRACE, "Returning '%d'", $guest_id);
    return $guest_id;
}

sub query_package {
    my ($package) = @_;

    debugprint(DEBUG_TRACE, "Querying package name '%s'...", $package->{name});
    my $package_id = 0;
    $DB->get_int(\$package_id, "SELECT id FROM packages WHERE packages.name='$package->{name}' AND packages.version='$package->{version}' AND packages.release='$package->{release}' AND packages.arch='$package->{arch}';");

    debugprint(DEBUG_TRACE, "Returning '%d'", $package_id);
    return $package_id;
}

sub register_package {
    my ($package) = @_;

    # Query the database for this package...
    my $package_id = query_package($package);

    if ( $package_id == 0 ) {
        debugprint(DEBUG_INFO, "Registering package '%s'...", $package->{name});
        my $values = "'$package->{name}', '$package->{version}', '$package->{release}', '$package->{arch}'";
        my $query = "INSERT INTO packages (name,version,release,arch) VALUES($values)";
        $DB->dbexec($query) unless $TestOnly;

        # Now, query it again...
        $package_id = query_package($package);
    }
    else {
        debugprint(DEBUG_TRACE, "Package already registered as '%d'", $package_id);
    }

    debugprint(DEBUG_TRACE, "Returning '%d'", $package_id);
    return $package_id;
}

sub query_install {
    my ($host_id,$package) = @_;

    debugprint(DEBUG_TRACE, "Querying install (%d,%s)....", $host_id, $package->{name});

    my $install_id = 0;
    my $query = "SELECT installs.id FROM installs,packages WHERE installs.host_id=$host_id AND installs.package_id=packages.id " . 
        "AND packages.name='$package->{name}' AND packages.version='$package->{version}' " .
        "AND packages.release='$package->{release}' AND packages.arch='$package->{arch}';";
    $DB->get_int(\$install_id, $query);

    debugprint(DEBUG_TRACE, "Returning '%d'", $install_id);
    return $install_id;
}

sub register_install {
    my ($host_id,$package) = @_;

    # Query the database about this install...
    my $install_id = query_install($host_id, $package);

    if ( $install_id == 0 ) {
        debugprint(DEBUG_INFO, "Registering install of package '%s'...", $package->{name});
        my $package_id = register_package($package);
        my $query = "INSERT INTO installs (host_id,package_id) VALUES($host_id,$package_id)";
        $DB->dbexec($query) unless $TestOnly;

        # Now, query it again...
        $install_id = query_install($host_id, $package);
    }
    else {
        debugprint(DEBUG_TRACE, "Install already registered as '%d'", $install_id);
    }

    debugprint(DEBUG_TRACE, "Returning '%d'", $install_id);
    return $install_id;
}

sub query_host {
    my ($hostinfo) = @_;

    debugprint(DEBUG_TRACE, "Querying hostname '%s'", $hostinfo->{hostname});
    my $host_id = 0;
    $DB->get_int(\$host_id, "SELECT id FROM hosts WHERE hostname='$hostinfo->{hostname}'");

    debugprint(DEBUG_TRACE, "Returning '%d'", $host_id);
    return $host_id;
}

sub register_host {
    my ($hostinfo) = @_;

    debugdump(DEBUG_DUMP, "hostinfo", $hostinfo);

    # Query the database for this host...
    my $host_id = query_host($hostinfo);

    if ( $host_id == 0 ) {
        debugprint(DEBUG_INFO, "Registering host '%s'...", $hostinfo->{hostname});
        my $query = "INSERT INTO hosts (hostname,osname) VALUES('$hostinfo->{hostname}','$hostinfo->{osname}')";
        $DB->dbexec($query) unless $TestOnly;

        # Now, query it again...
        $host_id = query_host($hostinfo);

        # Register the installed packages...
        foreach my $package ( @{$hostinfo->{packages}} ) {
            register_install($host_id, $package);
            last if $Limit;
        }

        # Register the running quests...
        foreach my $guest_name ( @{$hostinfo->{guests}} ) {
            register_guest($host_id, $guest_name);
            last if $Limit;
        }
    }
    else {
        debugprint(DEBUG_TRACE, "Host already registered as '%d'", $host_id);
    }

    debugprint(DEBUG_TRACE, "Returning '%d'", $host_id);
    return $host_id;
}

# Main Program
{
    # Set up...
    register_params(\%ParamDefs);
    parse_args();

    # Figure out which DC we're in...
    my $domain = qx(dnsdomainname); chomp($domain);

    # Pick the right genders attribute...
    my $attr = ( $domain =~ /^fal$/ ) ? "xen_server" : "xen";
    
    # Get the list of xen servers...
    my @xenservers = map({chomp($_); "$_.$domain";} qx(nodeattr -n $attr));
    debugdump(DEBUG_DUMP, "xenservers", \@xenservers);

    foreach my $hostname ( @xenservers ) {

        debugprint(DEBUG_INFO, "Scanning '%s'...", $hostname);

        # Get the os name...
        my $osname = qx(ssh $hostname "cat /etc/redhat-release"); chomp($osname);
        next if $osname eq "";

        my $hostinfo = {
            hostname  => $hostname,
            osname    => $osname,
        };

        # Get the list of installed packages...
        my @packages = map(
            {
                chomp($_);
                my $parts = {};
                ($parts->{name},$parts->{version},$parts->{release},$parts->{arch}) = split(',', $_);
                $parts;
            }
            qx(ssh $hostinfo->{hostname} "rpm -qa --queryformat '%{NAME},%{VERSION},%{RELEASE},%{ARCH}\n'" 2> /dev/null)
        );

        # Select all the relevant packages...
        my $packages = [
            grep({$_->{name} eq "xen"} @packages),
            grep({$_->{name} =~ /^qemu/} @packages),
            grep({$_->{name} =~ /^libcacard/} @packages),
        ];
        $hostinfo->{packages} = $packages;
        debugdump(DEBUG_DUMP, "packages", $hostinfo->{packages});

        # Get the list of guests...
        my $shorthost = substr($hostname, 0, index($hostname, "\."));
        debugprint(DEBUG_TRACE, "shorthost = '%s'", $shorthost);

        my @guests = map({chomp($_); $_;} qx(nodeattr -n dom0=$shorthost));
        debugdump(DEBUG_DUMP, "guests", \@guests);

        $hostinfo->{guests} = \@guests;

        # Register the host...
        register_host($hostinfo);

        last if $Limit;
    }
}

