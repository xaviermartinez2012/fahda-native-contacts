#!/usr/bin/perl

use Cwd;
use FindBin qw($Bin);
use Getopt::Long qw(HelpMessage :config pass_through);
use lib "$Bin/../lib";
use Share::DirUtil qw(get_dirs);
use Share::Fahda qw(get_xtc_file);
use strict;
use warnings;

my $Max_Pdb_Count   = 100000000;
my $Remove_Existing = 0;
my $Is_Dry_Run      = 0;

GetOptions(
    "logfile|l:s"     => \my $Log_File,
    "remove-existing" => sub { $Remove_Existing = 1 },
    "pdbmax|m:i"      => \$Max_Pdb_Count,
    "dry-run"         => sub { $Is_Dry_Run = 1 },
    "help|h" => sub { print HelpMessage(0) }
);

my $Project_Dir = $ARGV[0] or die "Project directory must be specified\n";
$Project_Dir =~ s/\/$//;    # Remove trailing slash if any
my ($Project_Number) = $Project_Dir =~ /(\d+$)/;

open(my $OUT, '>', "make_FAH-PDBs_$Project_Dir.log");

if ($Is_Dry_Run) { print $OUT "Executing in dry-run mode\n"; }
my $project_path = "${\getcwd()}/$Project_Dir";
if (defined $Log_File && -e $Log_File) { generate_pdbs_from_logfile($project_path, $Log_File); }
else                                   { generate_all_pdbs($project_path); }

close($OUT);

sub generate_pdbs_from_logfile {
    my ($project_path, $logfile) = @_;

    my $total_pdbs_count      = 0;
    my $current_pdbs_count    = 0;
    my $previous_run_number   = -1;
    my $previous_clone_number = -1;

    open(my $LOGFILE, '<', $logfile) or die "[FATAL]  $logfile: $!\n";
    while (defined(my $line = <$LOGFILE>) and $total_pdbs_count <= $Max_Pdb_Count) {
        chomp(my @fields = split(/\b\s+\b/, $line));

        my $logproj = $fields[0];
        if ($logproj != $Project_Number) {
            die "PROJ$logproj found in $logfile is not the same as the expected PROJ$Project_Number!";
        }

        my $run_number   = $fields[1];
        my $clone_number = $fields[2];
        my $time_in_ps   = $fields[3];          # time in ps
        my $frame_number = $time_in_ps / 100;

        my $clone_path = "$project_path/RUN$run_number/CLONE$clone_number/";

        # change directory only if the current run or clone # has changed in the log file
        if ($run_number != $previous_run_number or $clone_number != $previous_clone_number) {

            # print informative statistics and reset PDB count
            print $OUT "PROJ$Project_Number/RUN$run_number/CLONE$clone_number\t$current_pdbs_count PDBs created\n";
            $current_pdbs_count = 0;

            chdir $clone_path;
            print $OUT "Working on $clone_path ...\n";

            if (!$Is_Dry_Run && $Remove_Existing) {
                `rm *.pdb *# 2> /dev/null`;
            }
        }

        my $xtc_file = get_xtc_file($clone_path);
        if (not defined $xtc_file || not -e $xtc_file) {
            print $OUT "Skipped $clone_path: $xtc_file does not exist\n";
            $previous_clone_number = $clone_number;
            $previous_run_number   = $run_number;
            next;
        }

        my $pdb_file = "p${Project_Number}_r${run_number}_c${clone_number}_f${frame_number}.pdb";

        #TODO: trjconv might only need `echo 1`; need to check
        my $trjconv_cmd = "echo 1 1 | trjconv -s frame0.tpr -f $xtc_file -dump $time_in_ps -o $pdb_file  2> /dev/null";
        print $OUT "Executing `$trjconv_cmd`\n";
        if (!$Is_Dry_Run) { `$trjconv_cmd`; }

        if (-e $pdb_file) {
            $total_pdbs_count++;
            $current_pdbs_count++;
        }
        elsif (!$Is_Dry_Run) {
            print $OUT "Failed to create $pdb_file\n";
        }

        $previous_clone_number = $clone_number;
        $previous_run_number   = $run_number;
    }

    close($LOGFILE);
}

sub generate_all_pdbs {
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
        print $OUT "Working on $run_path\n";

        my @clone_dirs = get_dirs("$run_path", '^CLONE\d+$');
        if (scalar(@clone_dirs) == 0) {
            print $OUT "No CLONE* found in $run_dir\n";
            next;
        }

        foreach my $clone_dir (@clone_dirs) {
            chdir $clone_dir;
            my $clone_path = "$run_path/$clone_dir";
            print $OUT "Working on $clone_path\n";

            if (!$Is_Dry_Run) { `rm *.pdb *# 2> /dev/null`; }

            my $xtc_file = get_xtc_file($clone_path);
            if (not defined $xtc_file || not -e $xtc_file) {
                print $OUT "Skipped $clone_path: $xtc_file does not exist\n";
                next;
            }

            my ($run_number)   = $run_dir =~ /(\d+$)/;
            my ($clone_number) = $clone_dir =~ /(\d+$)/;
            my $pdb_file       = "p${Project_Number}_r${run_number}_c${clone_number}_f.pdb";

            # `echo 1` to select the RNA (Protein) group in trjconv command
            my $trjconv_cmd = "echo 1 | trjconv -s frame0.tpr -f $xtc_file -o $pdb_file -sep  2> /dev/null";
            print $OUT "Executing `$trjconv_cmd`\n";
            if (!$Is_Dry_Run) {
                `$trjconv_cmd`;
                rename_pdbs($clone_path);
            }

            chdir "..";
        }

        chdir "..";
    }
}

sub rename_pdbs {
    my ($cwd) = @_;
    opendir(my $CWD, $cwd);
    my @pdbs = grep { /\.pdb$/ } readdir($CWD);
    closedir($CWD);
    if (scalar(@pdbs) == 0) { return; }

    foreach my $pdb (@pdbs) {
        chomp $pdb;
        if (!$pdb =~ m/_f_/) { next; }
        my $new_pdb = $pdb;
        $new_pdb =~ s/_f_/_f/;
        `mv $pdb $new_pdb 2> /dev/null`;
    }
}

=head1 NAME

pdbs-make.pl - generate all PDBs for a F@H project

=head1 SYNOPSIS

pdbs-make.pl -h

pdbs-make.pl <project_dir>

pdbs-make.pl <project_dir> --remove-existing

pdbs-make.pl <project_dir> --dry-run

pdbs-make.pl <project_dir> -l=LOGFILE

pdbs-make.pl <project_dir> -l=LOGFILE -m=NUMBER_OF_MAX_PDB

Run this script in the same location as the PROJ* directories.
And don't forget the good old C<usegromacs33> (or similar) before running the script!

Additionally overwrite F<aminoacids.dat> with F<aminoacids-NA.dat> so that Gromacs
tools can recognize RNA molecules.

Progress is printed to an output log file (make_FAH-PDBs_PROJ*.log).

=over

=item --logfile, -l <log_file>

If specified will generate PDBs for frames listed in this file only.
All existing PDBs are removed before new ones are generated.

=item --remove-existing

Used together with --logfile. If specified will remove all existing PDBs.
This option is ignored if a log file is not specified.

=item --dry-run

When specified, no files would be created/modified.

=item --pdbmax, -m <num>

If specified will process this number <num> of PDBs only. Default to 100,000,000.

=item --help, -h

Print this help message.

=back

=cut
