#!/usr/bin/perl -w
use strict;
use warnings;
use JSON;
use Math::BigFloat;
use String::Util qw(trim);

# description: in a fun riff on windirstat, collects the sizes of everything in an AWS bucket, and
# displays the result.  Fair warning: for larger buckets, this will take awhile, as the methodology
# for this involves pulling metadata for everything in the bucket.

# format: ./s3DirStat.pl --profile <profile> <s3RootUrl>
my $profile = "default";
my $rootS3Url = "";

#scalar(@ARGV) < 1 and die("usage: $0 [--profile <profile>] <s3RootUrl>");
if(scalar(@ARGV) > 0) {
    my $vArg = shift(@ARGV);
    if($vArg eq "--profile") {
        $profile = shift(@ARGV);
        $rootS3Url = shift(@ARGV);
    }
    else {
        $rootS3Url = $vArg;
    }
}

# sometimes i'm lazy
if($rootS3Url ne "") {
    if($rootS3Url =~ /^s3:\/\/[a-zA-Z0-9\-]*\/$/) {
        #print "MATCH!\n";
    }
    else {
        #print "NOT A MATCH!\n";
        $rootS3Url .= "/";
    }
}

my @topRes = ();
open ( my $jh, "-|", "aws", "--profile", $profile, "s3", "ls", $rootS3Url) or die($!);
while (my $row = <$jh>) {
  chomp $row;
  $row = trim($row);
  push @topRes, $row
}
#my $json = from_json( do { local $/; <$jh> } );
close($jh);

my $rcnt = scalar(@topRes);
print "found $rcnt top-level results\n";

# if no path is specified, we're doing a root-level list of buckets....don't support doing this for a full account (yet), because huge
if($rootS3Url eq "") {
    foreach my $bkt(@topRes) {
        print "$bkt\n";
    }
    exit;
}

sub toGBString {
    my $rawBytes = shift;
    return sprintf("%.3f", $rawBytes / 1024.0 / 1024.0 / 1024.0) . " GB";
}

sub crawlDir {
    # get path to check
    my $checkPath = shift;

    # define our byte counter
    my $bc = 0;

    # get items in dir

    my $wsCnt = 0;
    my $wsInt = 1000;
    my $lastSize = 0;

    # turn on auto-flush for console buffer (progress)
    $| = 1;

    my @pathRes = ();
    open ( my $dh, "-|", "aws", "--profile", $profile, "s3", "ls", $checkPath, "--recursive") or die($!);
    while (my $row = <$dh>) {
        chomp $row;
        $row = trim($row);
        push @pathRes, $row;

        # TEST: put code inline?
        my @pargs = split(/ /, $row);

        # find size in bytes
        my $wval = undef;

        foreach my $pv(@pargs) {
            if($pv =~ /^(\d+)$/) {
                $wval = Math::BigFloat->new($pv);
                last;
            }
        }

        $bc += $wval;
        
        # increment file counter
        $wsCnt++;
        
        if($wsCnt % $wsInt == 0) {
            print "\b" x $lastSize;
            print "\r";
            my $sline = "scanning $checkPath: $wsCnt objects, " . toGBString($bc) . "...";
            $lastSize = length $sline;
            print "\r$sline";
        }
    }
    close($dh);

    # reset output ghetto-style
    print "\r";
    print " " x $lastSize;
    print "\r";

    # turn off auto-flush for console buffer (progress)
    $| = 0;

    return $bc;
} 

my $totalSize = 0.0;

foreach my $entry(@topRes) {
    my @lArgs = split(/ /, $entry);

    my $dsize = 0.0;
    my $dName = $entry;
    if($lArgs[0] eq "PRE") {

        my $rootDir = $lArgs[1];
        
        my $spath = $rootS3Url . $rootDir;
        $dsize = crawlDir($spath);        
    }
    else {
        $dsize = Math::BigFloat->new($lArgs[2]);
        $dName = $lArgs[3];
    }

    $totalSize += $dsize;

    print toGBString($dsize) . "\t$dName\n";
}

print "Total Size: " . toGBString($totalSize) . "\n";