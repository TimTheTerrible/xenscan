# xenscan
A simple tool for gathering installed package info from xen servers

# Overview
The purpose of these scripts is to gather information about installed Xen packages from Xen servers in various datacenters.

# Requirements
Xenscan requires a functioning PostgreSQL database server, configured as described below, two Perl modules, and passwordless SSH access to the datacenters to be scanned. In their current form, the scripts expect to be initiated from a workstation running the PostgreSQL server. The doit.sh script contains SSH tunnel commands that forward the psql connection back through the command tunnel.

## Perl Modules
* https://github.com/TimTheTerrible/TimUtil
* https://github.com/TimTheTerrible/TimDB

## PostgreSQL Setup
The scripts require a PostgreSQL role named "xenscan," with login privileges, as well as ownership of the "xenscan" dataase.

# Theory of Operation
This package consists of two bash scripts, two Perl scripts, and a PostgreSQL database schema.

* recreate.sh - Issues commands to drop the database and recreate it from the included schema.
* doit.sh - Issues commands to deploy and execute the scripts.
* xenscan.pl - Scans all Xen servers for Xen package and guest info.
* xeninfo.pl - Runs various queries against the database and reports the results.
* xenscan.sql - the PostgreSQL schema required by the scripts.

# Typical Use Case
After cloning the bithub repo, edit doit.sh to reflect the location of the cripts and the datacenters to be scanned. Execute doit.sh to start the scan process.

Starting with Falkland, the doit.sh script will copy the xenscan.pl script and its required libraries to the login server, open an ssh tunnel for PostgreSQL connections back to the launching workstation, then start the xenscan.pl script. Xenscan.pl will then query genders for a list of Xen servers in the current datacenter. Xenscan.pl then logs into each Xen server, capturing its OS version, and a list of relevant Xen RPMs installed. Finally, it again queries genders to capture a list of guests running on the current server.
As each Xen server is scanned, its information is recorded in the PostgreSQL database.

# Querying the Database
The xeninfo.pl script can run several useful quries against the database, and report on the results of those queries. The script has a number of command-line arguments that control its operation. These include --report, --list, --dc, and --guest, among others. Running xeninfo.pl with the --report switch, and supplying the argument "hosts" will list all pacakges installed, ordered by host. Specifying the additional switch --dc, with the argument "fal" will limit the output to only those hosts in the Falkland datacenter.

*NOTE* These command line options were only ever partially implemented. They were intended to work together to neck down the scope of information presented. Some combinations work exactly as expected and produce useful syntheses of information. Other combinations produce meaningless output, or no output at all.
