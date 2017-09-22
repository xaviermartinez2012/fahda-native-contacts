#!/usr/bin/perl

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

my $Path_To_Project_Dir = "${\getcwd()}/$Project_Dir";
if (defined $Log_File && -e $Log_File) { check_pdbs_from_logfile($Path_To_Project_Dir, $Log_File); }
else                                   { check_all_pdbs($Path_To_Project_Dir); }

close($OUT);

sub check_pdbs_from_logfile {
    my ($path_to_project_dir, $logfile) = @_;
    open(my $LOG, '<', $logfile) or die "[FATAL]  $logfile: $!\n";

    my $previous_run   = -1;
    my $previous_clone = -1;

    while (defined(my $line = <$LOG>)) {
        chomp(my @values = split(/\s+/, $line));
        my ($logproj, $run, $clone, $time) = @values;

        if ($logproj != $Project) {
            die "[FATAL]  PROJ $logproj found is not the same as the expected PROJ$Project!";
        }

        # change directory only if the current
        # run or clone # has changed in the log file
        if ($run != $previous_run || $clone != $previous_clone) {
            chdir "$path_to_project_dir/RUN$run/CLONE$clone/";
        }

        my $frame   = $time / 100;                                     # time in ps
        my $pdbfile = "p${Project}_r${run}_c${clone}_f${frame}.pdb";

        my $pdb_check_result = check_pdb($pdbfile);
        print $OUT "$pdb_check_result\n";

        $previous_clone = $clone;
        $previous_run   = $run;
    }

    close($LOG);
}

sub check_all_pdbs {
    my ($path_to_project_dir) = @_;
    chdir($path_to_project_dir);

    my @run_dirs = get_dirs($path_to_project_dir, "^RUN\\d+\$");
    if (scalar(@run_dirs) == 0) {
        print $OUT "[INFO]  No RUN found\n";
        return;
    }

    foreach my $run_dir (@run_dirs) {
        chdir $run_dir;

        my @clone_dirs = get_dirs("$path_to_project_dir/$run_dir", "^CLONE\\d+\$");
        if (scalar(@clone_dirs) == 0) {
            print $OUT "[INFO]  No CLONE found in $run_dir\n";
            next;
        }

        foreach my $clone_dir (@clone_dirs) {
            chdir $clone_dir;
            check_pdbs("$path_to_project_dir/$run_dir/$clone_dir");
            chdir "..";
        }

        chdir "..";
    }
}

sub get_dirs {
    my ($root, $match_pattern) = @_;
    if (not -d $root) { return; }
    if ($root !~ m/\/$/) { $root .= "/"; }

    opendir(my $ROOT_HANDLE, $root);
    my @dirs = grep { -d "$root$_" && /$match_pattern/ } readdir($ROOT_HANDLE);
    closedir($ROOT_HANDLE);

    return @dirs;
}

sub check_pdbs {
    my ($cwd) = @_;

    opendir(my $CWD, $cwd);
    my @pdbs = grep { /\.pdb/i } readdir($CWD);
    closedir($CWD);

    if   (scalar(@pdbs) == 0) { print $OUT "[INFO]  No PDB found in $cwd\n"; }
    else                      { print $OUT "[INFO]  Found ${\scalar(@pdbs)} PDBs in $cwd\n"; }

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

    my $pdbsize = get_filesize($pdb_filename);
    if ($pdbsize == 0) {
        return "$pdb_filename of ZERO size";
    }

    my $pdb_time_from_content = get_time_from_pdb_content($pdb_filename);
    if ($pdb_time_from_content != $expected_time) {
        return "$pdb_filename has the WRONG time";
    }

    return "$pdb_filename created successfully!";
}

sub get_filesize {
    my ($pdb_filename) = @_;
    my $filesize = -s $pdb_filename;
    return int($filesize);
}

sub get_time_from_pdb_content {
    my ($pdb_filename) = @_;

    chomp(my $title_line = `head $pdb_filename | grep TITLE`);
    chomp(my @values = split(/\s+/, $title_line));
    my $time_in_ps = int($values[3]);
    return $time_in_ps;
}

sub get_time_from_pdb_filename {
    my ($pdb_filename) = @_;
    $pdb_filename =~ s/\.pdb//;
    chomp(my @filename_parts = split(/_f/, $pdb_filename));
    my $time_in_ps = int($filename_parts[1]) * 100;
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
