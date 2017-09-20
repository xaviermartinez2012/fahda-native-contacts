#! /usr/bin/perl

#TODO: Specify optional Log_Filename
#TODO: Implement check_all_pdbs()
#TODO: Specify optional rerun log filename

use strict;
use warnings;
use Cwd;
use Getopt::Long qw(HelpMessage :config pass_through);

GetOptions(
    "logfile|l:s" => \my $Log_File,
    "help|h"      => sub { print HelpMessage(0) }
);

my $Project_Dir = $ARGV[0] or die "[FATAL]  Project directory must be specified\n";
$Project_Dir =~ s/\/$//;    # Remove trailing slash if any
my $Project = $Project_Dir;
$Project =~ s/^PROJ//;      # Remove leading 'PROJ'

my $outfile = "check_FAH-PDBs_$Project.log";
open(my $OUT, '>', $outfile);

if   (defined $Log_File && -e $Log_File) { check_specific_pdbs($Log_File); }
else                                     { check_all_pdbs(); }

close($OUT);

sub check_specific_pdbs {
    my ($logfile) = @_;
    open(my $LOG, '<', $logfile) or die "[FATAL]  $logfile: $!\n";

    my $homedir        = getcwd();
    my $previous_run   = -1;
    my $previous_clone = -1;

    while (defined(my $line = <$LOG>)) {
        chomp(my @values = split(/\s+/, $line));
        my ($logproj, $run, $clone, $time) = @values;

        if ($logproj != $Project) {
            die "[FATAL]  PROJ $logproj found is not the same as the expected PROJ$Project!";
        }

        # change directory only if the current
        # run or clone # has chenged in the log file
        if ($run != $previous_run || $clone != $previous_clone) {
            chdir "$homedir/PROJ$Project/RUN$run/CLONE$clone/";
        }

        my $frame = $time / 100;    # time in ps
        my $pdbfile = "p${Project}_r${run}_c${clone}_f${frame}.pdb";

        my $pdb_check_result = check_pdb($pdbfile);
        print $OUT "$pdb_check_result\n";

        $previous_clone = $clone;
        $previous_run   = $run;
    }

    close($LOG);
}

sub check_pdb {

    # Check for correctly written PDB file
    # by looking for wrong time stamps and zero filesize

    my ($pdbfile, $expected_time) = @_;
    if (not -e $pdbfile) {
        return "$pdbfile was NOT created";
    }

    my $pdbsize = get_filesize($pdbfile);
    if ($pdbsize == 0) {
        return "$pdbfile of ZERO size";
    }

    my $pdbtime = get_time_from_pdb_content($pdbfile);
    if ($pdbtime != $expected_time) {
        return "$pdbfile has the WRONG time";
    }

    return "$pdbfile created successfully!";
}

sub check_all_pdbs {
    die "to be implemented";
}

sub get_filesize {
    my ($pdb_filename) = @_;
    return -e $pdb_filename;
}

sub get_time_from_pdb_content {
    my ($pdb_filename) = @_;
    chomp(my $title_line = `head $pdb_filename | grep TITLE`);
    chomp(my @values = split(/\s+/, $title_line));
    my $pdbtime = $values[3];
    return $pdbtime;
}

sub get_time_from_pdb_filename {
    my ($pdb_filename) = @_;
    $pdb_filename =~ s/\.pdb//;
    chomp(my @filename_parts = split(/_f/, $pdb_filename));
    my $time_in_ps = $filename_parts[1] * 100;
    return $time_in_ps;
}

=head1 NAME

fah-pdbs-check.pl - check the integrity of the PDBs

=head1 SYNOPSIS

TBD

./fah-pdbs-check.pl  <project_dir>

./fah-pdbs-check.pl  <project_dir> --logfile=<log_file>

Run this script in the location of the F@H PROJ* directories.
After running, grep resulting log file for "WRONG", "ZERO", and
"NOT" to look for bad or missing PDBs.

=over

=item --logfile, -l <log_file>

TBD

=item -h, --help

Print this help message.

=back

=cut
