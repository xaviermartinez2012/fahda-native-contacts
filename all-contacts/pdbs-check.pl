#!/usr/bin/perl

#TODO: Specify optional rerun log filename

use Cwd;
use FindBin qw($Bin);
use Getopt::Long qw(HelpMessage :config pass_through);
use lib "$Bin/../lib";
use Share::DirUtil qw(get_dirs);
use strict;
use warnings;
use English;

GetOptions(
    "logfile|l:s" => \my $Log_File,
    "help|h"      => sub { print HelpMessage(0) }
);

my $Project_Dir = $ARGV[0] or die "[FATAL]  Project directory must be specified\n";
$Project_Dir =~ s/\/$//;    # Remove trailing slash if any
my ($Project_Number) = $Project_Dir =~ /(\d+$)/;

my $outfile = "check_FAH-PDBs_$Project_Dir.log";
open(my $OUT, '>', $outfile);

my $project_path = "${\getcwd()}/$Project_Dir";
if (defined $Log_File && -e $Log_File) { check_pdbs_from_logfile($project_path, $Log_File); }
else                                   { check_all_pdbs($project_path); }

close($OUT);

sub check_pdbs_from_logfile {
    my ($project_path, $logfile) = @_;
    open(my $LOG, '<', $logfile) or die "[FATAL]  $logfile: $!\n";

    my $previous_run_number   = -1;
    my $previous_clone_number = -1;

    while (defined(my $line = <$LOG>)) {
        chomp(my @fields = split(/\b\s+\b/, $line));
        my ($logproj, $run_number, $clone_number, $time_in_ps) = @fields;

        if ($logproj != $Project_Number) {
            die "[FATAL]  PROJ$logproj found is not the same as the expected PROJ$Project_Number!";
        }

        # change directory only if the current
        # run or clone # has changed in the log file
        if ($run_number != $previous_run_number || $clone_number != $previous_clone_number) {
            chdir "$project_path/RUN$run_number/CLONE$clone_number/";
        }

        my $frame_number = $time_in_ps / 100;                                                           # time in ps
        my $pdbfile      = "p${Project_Number}_r${run_number}_c${clone_number}_f${frame_number}.pdb";

        my $pdb_check_result = check_pdb($pdbfile);
        print $OUT "$pdb_check_result\n";

        $previous_clone_number = $clone_number;
        $previous_run_number   = $run_number;
    }

    close($LOG);
}

sub check_all_pdbs {
    my ($project_path) = @_;
    chdir($project_path);

    my @run_dirs = get_dirs($project_path, '^RUN\d+$');
    if (scalar(@run_dirs) == 0) {
        print $OUT "No RUN* found\n";
        return;
    }

    foreach my $run_dir (@run_dirs) {
        chdir $run_dir;
        my $run_path = "$project_path/$run_dir";
        print $OUT "Working on $run_path...\n";

        my @clone_dirs = get_dirs("$run_path", '^CLONE\d+$');
        if (scalar(@clone_dirs) == 0) {
            print $OUT "No CLONE* found in $run_dir\n";
            next;
        }

        foreach my $clone_dir (@clone_dirs) {
            chdir $clone_dir;
            my $clone_path = "$project_path/$run_dir/$clone_dir";
            print $OUT "Working on $clone_path...\n";
            check_pdbs($clone_path);
            chdir "..";
        }

        chdir "..";
    }
}

sub check_pdbs {
    my ($clone_path) = @_;

    opendir(my $CLONE_PATH, $clone_path);
    my @pdbs = grep { /\.pdb/i } readdir($CLONE_PATH);
    closedir($CLONE_PATH);

    if   (scalar(@pdbs) == 0) { print $OUT "No PDB found\n"; }
    else                      { print $OUT "Found ${\scalar(@pdbs)} PDBs\n"; }

    foreach my $pdb (@pdbs) {
        my $expected_time = get_time_from_pdb_filename($pdb);
        my $pdb_check_result = check_pdb($pdb, $expected_time);
        print $OUT "$pdb_check_result\n";
    }
}

sub check_pdb {

    # Check for correctly written PDB file
    # by looking for wrong time stamps and zero filesize

    my ($pdb_filename, $expected_time) = @_;
    if (not -e $pdb_filename) {
        return "$pdb_filename was NOT created";
    }

    my $pdbsize = int(-s $pdb_filename);
    if ($pdbsize == 0) {
        return "$pdb_filename of ZERO size";
    }

    my $pdb_time_from_content = get_time_from_pdb_content($pdb_filename);
    if ($pdb_time_from_content != $expected_time) {
        return "$pdb_filename has the WRONG time: time_from_content=$pdb_time_from_content, expected_time=$expected_time";
    }

    return "$pdb_filename created successfully!";
}

sub get_time_from_pdb_content {
    my ($pdb_filename) = @_;

    chomp(my $title_line = `head $pdb_filename | grep TITLE`);
    chomp(my @fields = split(/\b\s+\b/, $title_line));
    my $time_in_ps = int($fields[3]);
    return $time_in_ps;
}

sub get_time_from_pdb_filename {
    my ($pdb_filename) = @_;
    $pdb_filename =~ s/\.pdb//;
    chomp(my @fields = split(/_f/, $pdb_filename));
    my $time_in_ps = int($fields[1]) * 100;
    return $time_in_ps;
}

=head1 NAME

pdbs-check.pl - check the integrity of the PDBs

=head1 SYNOPSIS

pdbs-check.pl  -h

pdbs-check.pl  <project_dir>

pdbs-check.pl  <project_dir> --logfile=<log_file>

Run this script in the location of the F@H PROJ* directories.
After running, grep resulting log file for "WRONG", "ZERO", and
"NOT" to look for bad or missing PDBs.

=over

=item --logfile, -l <log_file>

Path to an input logfile. When specified only check the PDBs whose project,
run, clone, and time (ps) listed in the logfile.

=item -h, --help

Print this help message.

=back

=cut
