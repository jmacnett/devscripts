#!/usr/bin/perl -w
use strict;
use warnings;
use JSON;

# description: display a list of domains, hosted zones, and entries for the default aws user (via ~/.aws/config)

my $verbose = 0;

my $vArg = shift(@ARGV);
if($vArg && $vArg eq "--verbose") {
    $verbose = 1;
}

# get list of domains
open ( my $jh, "-|", "aws", "route53domains", "list-domains") or die($!);
my $json = from_json( do { local $/; <$jh> } );
close($jh);

my @domainArr = @{$json->{Domains}};
my $dcnt = scalar @domainArr;

if($verbose) { print "Retrieved $dcnt registered domains:\n" };
if($verbose) { print "\n" };
if($verbose) {
    foreach my $dm(@domainArr) {
        my $dname = $dm->{DomainName};
        print "$dname\n"
    }
}

if($verbose) { print "\n" };

open ( my $jh2, "-|", "aws", "route53", "list-hosted-zones") or die($!);
$json = from_json( do { local $/; <$jh2> } );
close($jh2);
my @zoneRootArr = @{$json->{HostedZones}};
my $zcnt = scalar @zoneRootArr;
if($verbose) { print "Retrieved $zcnt hosted zones:\n" };
if($verbose) { print "\n" };

if(!$verbose) {
    print "Zone\tType\tTTL\tName\tValue\n";
}

foreach my $zn(@zoneRootArr) {
    my $zName = $zn->{Name};
    my $zid = $zn->{Id};
    my $zcomment = $zn->{Config}->{Comment};

    if($verbose) {  print "Zone: $zName\t Id: $zid\t Comment: \"$zcomment\"\n" };
    #print "Comment: $zcomment\n";

    # get record sets
    open ( my $jh3, "-|", "aws", "route53", "list-resource-record-sets", "--hosted-zone-id", $zid) or die($!);
    my $rsjson = from_json( do { local $/; <$jh3> } );
    close($jh3);
    my @rsArr = @{$rsjson->{ResourceRecordSets}};

    foreach my $rs(@rsArr) {
        my $rsType = $rs->{Type};
        my $rsName = $rs->{Name};
        my $ttl = $rs->{TTL};
        if(!$rs->{ResourceRecords}) {
            if($rs->{AliasTarget}) {
                print $zName . "\t" . $rsType . "\t-\t" . $rsName . "\t" . $rs->{AliasTarget}->{DNSName} . "\n";
                next;
            }
            else {
                print "********* UNKNOWN FORMAT! ****************\n";
                next;
            }
        }

        my $rsValueArr = $rs->{ResourceRecords};
        my $rsValueCnt = scalar $rsValueArr;
        # print "Found $rsValueCnt values!\n";
        my $leadString = "$zName\t$rsType\t$ttl\t$rsName\t";
        my $len = length $leadString;

        for(my $i=0;$i<@$rsValueArr;$i++) {
            print $leadString . $rsValueArr->[$i]->{Value} . "\n";
        }
    }
    if($verbose) { print "\n" };
}

if($verbose) { print "\n" };
if($verbose) { print "Execution complete!\n" };
