#! /usr/bin/perl

#TODO: Add option to generate rerun logfile

use strict;
use warnings;

use Cwd;
use English;
use FindBin qw($Bin);
use Getopt::Long qw(HelpMessage :config pass_through);
use lib "$Bin/../lib";
use Share::DirUtil qw(get_dirs);
use Share::FileUtil qw(get_files);

GetOptions(
    "logfile|l:s" => \my $Log_File,
    "help|h"      => sub { print HelpMessage(0) }
);

my $Project_Dir = $ARGV[0] or die "PROJ* dir must be specified\n";
$Project_Dir =~ s/\/$//;    # Remove trailing slash if any
my ($Project_Number) = $Project_Dir =~ /(\d+$)/;

my $outfile = "check_FAH-CONs_$Project_Dir.log";
open(my $OUT, '>', $outfile);

my $project_path = "${\getcwd()}/$Project_Dir";
if (defined $Log_File && -e $Log_File) { check_cons_from_logfile($project_path, $Log_File); }
else                                   { check_all_cons($project_path); }

close($OUT);

sub check_cons_from_logfile {
    my ($project_path, $logfile) = @_;

    my $previous_run_number   = -1;
    my $previous_clone_number = -1;

    open(my $LOG, '<', $logfile) or die "Can't open $logfile: $!\n";
    while (defined(my $line = <$LOG>)) {

        my @fields = split(/\s+/, $line);
        my ($logproj, $run_number, $clone_number, $time_in_ps) = @fields;
        if ($logproj != $Project_Number) {
            die "PROJ$logproj found in $logfile is not the same the expected PROJ$Project_Number!\n";
        }

        # change directory only if the current
        # run or clone # has chenged in the log file
        if (($run_number != $previous_run_number) || ($clone_number != $previous_clone_number)) {
            chdir "$project_path/RUN$run_number/CLONE$clone_number";
        }

        my $frame_number = $time_in_ps / 100;
        my $con_file      = "p${Project_Number}_r${run_number}_c${clone_number}_f$frame_number.con";

        print $OUT check_con($con_file) . "\n";

        $previous_clone_number = $clone_number;
        $previous_run_number   = $run_number;
    }

    close($LOG);
}

sub check_all_cons {
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
            my $clone_path = "$run_path/$clone_dir";
            print $OUT "Working on $clone_path...\n";
            print $OUT check_cons($clone_path) . "\n";
            chdir "..";
        }

        chdir "..";
    }
}

sub check_cons {
    my ($clone_path) = @_;
    my @con_files = get_files($clone_path, '\.con$');
    my $check_results = '';
    foreach my $con_file (@con_files) {
        $check_results .= check_con("$clone_path/$con_file") . "\n";
    }
    return $check_results;
}

sub check_con {
    my ($con_file) = @_;
    if (!Share::FileUtil::file_ok($con_file)) {
        return $Share::FileUtil::File_Ok_Message;
    }
    return "$con_file was created successfully";
}

=head1 NAME

cons-check.pl - Check that all atom-contact files were properly created

=head1 SYNOPSIS

cons-check.pl  <project_dir>

cons-check.pl <project_dir> [--logfile|-l=<logfile.log>]

Run this script in the location of the F@H PROJ* directories.
After running, grep resulting log file (check_FAH-CONs_PROJ*.log) for
"NOT" to look for missing .con files.

=cut
