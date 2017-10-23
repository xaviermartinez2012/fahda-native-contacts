package Share::Fahda;

use strict;
use warnings;

use English;
use List::Util qw(first max);

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_xtc_file get_prc_from_clone_path get_prc_from_filename get_prcf_from_filename get_max_dir_number);

sub get_xtc_file {
    my ($clone_path) = @_;
    $clone_path =~ s/\/$//;

    my ($project_number, $run_number, $clone_number) = get_prc_from_clone_path($clone_path);
    my $xtc_file = "P${project_number}_R${run_number}_C${clone_number}.xtc";
    if (-e $xtc_file) { return $xtc_file; }

    opendir(my $CLONE_PATH, $clone_path);
    my @xtc_files = grep { -e "$clone_path/$_" && /\.xtc$/ } readdir($CLONE_PATH);
    closedir($CLONE_PATH);

    return (scalar(@xtc_files) > 0) ? $xtc_files[0] : undef;
}

sub get_prc_from_clone_path {
    my ($clone_path) = @_;
    chomp($clone_path);
    my @bread_crumbs = split('/', $clone_path);

    my $project_dir = first { /^PROJ\d+$/ } @bread_crumbs;
    my $run_dir     = first { /^RUN\d+$/ } @bread_crumbs;
    my $clone_dir   = first { /^CLONE\d+$/ } @bread_crumbs;

    my ($project_number) = (defined $project_dir) ? ($project_dir =~ /(\d+$)/) : undef;
    my ($run_number)     = (defined $run_dir)     ? ($run_dir =~ /(\d+$)/)     : undef;
    my ($clone_number)   = (defined $clone_dir)   ? ($clone_dir =~ /(\d+$)/)   : undef;

    return ($project_number, $run_number, $clone_number);
}

sub get_prc_from_filename {
    my ($filename) = @_;

    $filename =~ s/\.[^.]*$//;    # remove extension
    my @fields = split(/_/, $filename);

    my $project_field = first { /^P\d+$/i } @fields;
    my $run_field     = first { /^R\d+$/i } @fields;
    my $clone_field   = first { /^C\d+$/i } @fields;

    my ($project_number) = (defined $project_field) ? ($project_field =~ /(\d+$)/) : undef;
    my ($run_number)     = (defined $run_field)     ? ($run_field =~ /\d+$/)       : undef;
    my ($clone_number)   = (defined $clone_field)   ? ($clone_field =~ /\d+$/)     : undef;

    return ($project_number, $run_number, $clone_number);
}

sub get_prcf_from_filename {
    my ($filename) = @_;

    $filename =~ s/\.[^.]*$//;    # remove extension
    my @fields = split(/_/, $filename);

    my $project_field = first { /^P\d+$/i } @fields;
    my $run_field     = first { /^R\d+$/i } @fields;
    my $clone_field   = first { /^C\d+$/i } @fields;
    my $frame_field   = first { /^F\d+$/i } @fields;

    my ($project_number) = (defined $project_field) ? ($project_field =~ /(\d+$)/) : undef;
    my ($run_number)     = (defined $run_field)     ? ($run_field =~ /\d+$/)       : undef;
    my ($clone_number)   = (defined $clone_field)   ? ($clone_field =~ /\d+$/)     : undef;
    my ($frame_number)   = (defined $frame_field)   ? ($frame_field =~ /\d+$/)     : undef;

    return ($project_number, $run_number, $clone_number, $frame_number);
}

sub get_max_dir_number {
    my (@dirs) = @_;
    if (not @dirs) { return; }
    my @dir_numbers = ();
    foreach my $dir (@dirs) {
        my $dir_number = $dir;
        $dir_number =~ s/^\D+//;
        push(@dir_numbers, int($dir_number));
    }
    return max(@dir_numbers);
}

42;
