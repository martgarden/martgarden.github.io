#!/bin/perl


use warnings;
use strict;
use utf8;
use File::Find;
use File::Copy;
use List::MoreUtils qw(zip zip_unflatten);






my @langs = ('cs', 'en'); #the first language is the default

my @open_tags = map {"<$_>"} @langs;
my @close_tags = map {"</$_>"} @langs;
my $ored_string = join '|', @open_tags;


my %search_mapping = ((zip @open_tags, @close_tags) ,(map {$_, $ored_string} @close_tags));

my ($head, @tail) = @langs;
my @dirs = ("_site", map {"_site/$_"} @tail);
my %dir_mapping = (($ored_string => \@dirs),
    (map {($_->[0] => [$_->[1]])} (zip_unflatten @close_tags, @dirs)));

for my $dir (@dirs) {
    mkdir $dir;
}



my @htmls;
my @fhs;
chdir 'contents';
find({wanted => \&make_array, no_chdir => 1}, '.');
chdir '..';

sub make_array {
    return 1 if $_ eq '.';
    if(-d $_){
        for my $dir (@dirs) {
            mkdir "../$dir/$_";
        }
    }
    elsif($_ =~ /\.html$/) {
        my %fhh;
        push @htmls, $_;
        push @fhs, \%fhh;
        for my $dir (@dirs) {
            local *FILE;
            open(FILE, '>', "../$dir/$_");
            $fhh{$dir} = *FILE ;
        }
    }
    else {
        for my $dir (@dirs) {
            copy($_, "../$dir/$_");
        }
    }
}

open(MOOSTER,'<','mooster.html') or die "Couldn't open mooster";

my $searched = $ored_string;

sub saving {
    for my $dir (@{$dir_mapping{$searched}}) {
        for my $fh (@fhs) {
            print {$fh->{$dir}} $_[0];
        }
    }
}

sub saving_spec {
    for my $dir (@{$dir_mapping{$searched}}) {
        print {$_[1]->{$dir}} $_[0];
    }
}


while(<MOOSTER>) {
    if($_ !~ /<custom-content\/>/) {
        my $line = $_;
        while($line =~ /$searched/) {
            saving $`;
            $searched = $search_mapping{$&};
            $line = $';
        }
        saving $line;
    }
    else {
        for my $i (0..(scalar @htmls - 1)) {
            print "for cycle $i\n";
            open(CONTENT, '<', "contents/$htmls[$i]") or die "couldn't open 'contents/$htmls[$i]'";
            while(<CONTENT>) {
                my $line = $_;
                while($line =~ /$searched/) {
                    saving_spec($`, $fhs[$i]);
                    $searched = $search_mapping{$&};
                    $line = $';
                }
                saving_spec($line, $fhs[$i]);
            }
            close CONTENT;
        }
    }
}
for my $fh_hash (@fhs) {
    for my $dir (@dirs) {
        close $fh_hash->{$dir};
    }
}
close(MOOSTER);

sub replace_file_name {
    return 1 if -d;
    my $file = $_;
    rename($file, "$file.bak") or die "error renaming to .bak";
    open(FHIN, '<', "$file.bak") or die "can't open FHIN $file.bak";
    open(FHOUT, '>', $file) or die "can't open FHOUT $file";
    while(<FHIN>) {
        $_ =~ s/<this-file-name>/$file/g;
        print FHOUT $_;
    }
    close FHIN;
    close FHOUT;
}
find(\&replace_file_name, '_site');
