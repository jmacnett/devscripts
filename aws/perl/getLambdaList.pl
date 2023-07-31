#!/usr/bin/perl -w
use strict;
use warnings;
use JSON;

# description: display a list of all lambdas and runtimes in all regions, for all aws accounts defined in ~/.aws/confg
my $verbose = 0;

my $vArg = shift(@ARGV);
if($vArg && $vArg eq "--verbose") {
    $verbose = 1;
}

# pull list of account aliases from local aws profile files (add "default" manually, since it doesn't match the pattern)
my @profiles = ("default");
open( my $fh, "cat ~/.aws/config| grep \"\\[profile\"|sed \"s/\\[profile //g\"|sed \"s/\\]//g\"|") or die($!);
while (my $row = <$fh>) {
  chomp $row;
  push @profiles, $row
}
close($fh);

my @acctList = ();

my @regionList = ("us-east-1","us-east-2","us-west-2");

# for each profile, let's do AWS-y things
foreach my $pr(@profiles) {
    if($verbose) { print "processing profile $pr...\n"; }

    # get account aliases (for readability of display, later)
    open ( my $jh, "-|", "aws", "--profile", $pr, "iam", "list-account-aliases") or die($!);
    my $json = from_json( do { local $/; <$jh> } );
    close($jh);
    my @aliasArr = @{$json->{AccountAliases}};
    my $displayName = $pr;
    if((scalar @aliasArr) > 0){
        $displayName = $aliasArr[0];
    }
    push @acctList, $displayName;

    # new: iterate through regions
    foreach my $rg(@regionList) {
        # pull list of functions as json
        open ( $jh, "-|", "aws", "--profile", $pr,
            "--region", $rg,
            "lambda", "list-functions") or die($!);
        $json = from_json( do { local $/; <$jh> } );
        close($jh);

        my @funcArr = @{$json->{Functions}};
        my $fcnt = scalar @funcArr;
        if($verbose) { print "Total function count ($rg): $fcnt\n"; }

        # display functions and runtimes, if we have em
        if($fcnt > 0) {
            foreach my $fn(@funcArr) {
                #print "$displayName\t" . $fn->{FunctionName} . "\t" . $fn->{Runtime} . "\n";

                # docker containers don't actually have a runtime value, so this gets weird
                my $rt = "n/a";
                if($fn->{Runtime}) {
                    $rt = $fn->{Runtime};
                }
                my $line = sprintf "%-25s %-10s %-20s %-s\n", $displayName,$rg,$rt, $fn->{FunctionName};

                print $line;
                
            }
        }
    }
}

print "\n";
print "Inspected accounts:\n";
foreach my $acct(@acctList) {
    print "$acct\n";
}
