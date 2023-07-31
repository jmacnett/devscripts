#!/usr/bin/perl -w
use strict;
use warnings;
use JSON;

# description: display a list of certificates for all accounts defined in the local aws config

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

    if($verbose) { print "scanning for certificates..."; }

    # pull list of functions as json
    open ( $jh, "-|", "aws", "--profile", $pr,
        "--region", "us-east-1",
        "acm", "list-certificates") or die($!);
    $json = from_json( do { local $/; <$jh> } );
    close($jh);

    my @certArr = @{$json->{CertificateSummaryList}};
    my $fcnt = scalar @certArr;
    if($verbose) { print "Total cert count: $fcnt\n"; }

    # display functions and runtimes, if we have em
    if($fcnt > 0) {
        foreach my $crt(@certArr) {
            #print "$displayName\t" . $fn->{FunctionName} . "\t" . $fn->{Runtime} . "\n";

            my $line = sprintf "%-25s %-s\n", $displayName, $crt->{DomainName};
            print $line;
        }
    }
}

print "\n";
print "Inspected accounts:\n";
foreach my $acct(@acctList) {
    print "$acct\n";
}
