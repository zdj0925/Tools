#!/oracle11g/product/11.2.0/perl/bin/perl
##!usr/bin/perl
#perl script used to connect to Oracle
use strict;
use DBI;
my @drivers = DBI->available_drivers();
die "No drivers found!\n" unless @drivers;
foreach my $driver (@drivers)
{
    print "Driver: $driver\n";
    my @dataSources = DBI->data_sources($driver);
    foreach my $dataSource(@dataSources)
    {
        print "\tData Source is :$dataSource\n";
    }
    print ("\n");
}
