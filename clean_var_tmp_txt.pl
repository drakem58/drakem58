#!/usr/bin/perl
# this script will clean out files ending with txt under the
# /var/tmp directory

use strict;
use File::Glob;
use warnings;

my $tmp_path="/var/tmp";

print "\n";
print $tmp_path;
print "\n";
print "current path this will look in";
print "\n";

my $currenttime = time();

print $currenttime . "\n";
$currenttime = $currenttime - 604800;
print $currenttime . "\n";
print "\n";
print "the second time line is set for 1 week back";
print "\n";

opendir(D, $tmp_path) || die "can't open $tmp_path: $!";

my $count = 0;
while ((my $f = readdir(D))) {
        next if ($f =~ m/^\./);
        if ($f =~ m/\.txt/) {
                if ( (stat("$tmp_path/$f"))[9] < $currenttime) {
                        unlink "$tmp_path/$f";
                        $count++;
                        if ($count > 1000) {
                                print "1000 records checked.\n";
                                $count = 0;
                        }
                }
        }

}

closedir(D);
