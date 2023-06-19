#!/usr/bin/perl

use strict;
use warnings;

sub find_file {
    my ($dir, $file) = @_;

    opendir my $dh, $dir or die "Unable to open directory $dir: $!";
    my @files = readdir $dh;
    closedir $dh;

    foreach my $f (@files) {
        next if $f eq '.' || $f eq '..';
        my $filepath = "$dir/$f";
        
        if (-d $filepath) {
            find_file($filepath, $file);
        }
        elsif ($f eq $file) {
            print "Found $file in directory $dir!\n";
        }
    }
}

find_file('.', 'example.txt');
