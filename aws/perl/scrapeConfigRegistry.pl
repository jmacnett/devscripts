#!/usr/bin/perl -w
use strict;
use warnings;
use JSON;
use Set::Object qw(set);

# description: for a given account and region with AWS Config enabled, get a cli dump of all resources managed by Config

# get arguments
if(scalar(@ARGV) < 2) {
    die("Invalid arguments!  Usage: ./scrapConfigRegistry <aws account profile> <region>");
}
my $profile = shift(@ARGV);
my $region = shift(@ARGV);

print("profile: $profile region: $region\n");

# verify that Config is set up for this account and region
open( my $jhr, "-|", "aws", "--profile", $profile, "--region", $region, "configservice", "describe-delivery-channels") or die($!);
my $dcjson = from_json( do { local $/; <$jhr> } );
close($jhr);
my @dcArr = @{$dcjson->{DeliveryChannels}};
if(scalar(@dcArr) < 1) {
    die("No AWS Config delivery channels configured!  It is likely that Config is not enabled for this account and region.  Please review.");
}

# start our calls
my $distinctRes = Set::Object->new();
my $nextToken = undef;
do 
{
    # pull
    my $json = undef;
    if($nextToken) {
        print "Next Token: $nextToken\n";

        open( my $jh, "-|", "aws", 
            "--profile", $profile, "--region", $region, 
            "configservice", "select-resource-config", "--expression", "select resourceType", "--limit", "100",
            "--next-token", $nextToken) or die($!);
        $json = from_json( do { local $/; <$jh> } );
        close($jh);
    }
    else {
        
        open( my $jh, "-|", "aws", 
            "--profile", $profile, "--region", $region, 
            "configservice", "select-resource-config", "--expression", "select resourceType", "--limit", "100") or die($!);
        $json = from_json( do { local $/; <$jh> } );
        close($jh);
    }

    $nextToken = $json->{NextToken};
    my @results = @{$json->{Results}};
    my $rcnt = scalar @results;
    print "Found $rcnt resources\n";
    
    foreach my $rt(@results) {
        #print($rt);
        $distinctRes->insert($rt);
    }
    #last;

} while($nextToken);

my @allRes = sort $distinctRes->members();
foreach my $m(@allRes) {
    print("$m\n");
}