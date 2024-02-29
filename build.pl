#!/bin/perl


use warnings;
use strict;
use utf8;
use File::Find;
use File::Copy;

mkdir "_site";

my @htmls = ();
my @fhs = ();
chdir 'contents';
find({wanted => \&make_array, no_chdir => 1}, '.');
chdir '..';


sub make_array {
    return 1 if $_ eq '.';
    if(-d $_){
        mkdir "../_site/$_";
        print "making directory '../_site/$_'\n";
    }
    elsif($_ =~ /\.html$/) {
        local *FILE;
        open(FILE, '>', "../_site/$_");
        push @htmls, $_ ;
        push @fhs, *FILE;
        print "pushing '$_' to \@htmls\n";
    }
    else {
        copy($_, "../_site/$_");
        print "copying '$_' to '../_site/$_'\n";
    }
}

open(MOOSTER,'<','mooster.html') or die "Couldn't open mooster";

while(<MOOSTER>) {
    if($_ !~ /<custom-content\/>/) {
        my $line = $_;
        for (@fhs) {
            print $_ $line;
        }
    }
    else {
        for my $i (0..(scalar @htmls - 1)) {
            print "for cycle $i\n";
            open(CONTENT, '<', "contents/$htmls[$i]") or die "couldn't open 'contents/$htmls[$i]'";
            while(<CONTENT>) {
                print {$fhs[$i]} $_;
            }
            close(CONTENT);
        }
    }
}
for(@fhs) {
    close $_;
}
close(MOOSTER);
