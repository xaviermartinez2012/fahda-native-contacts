#!/usr/bin/perl

use strict;
use warnings;
use Cwd;
use Getopt::Long qw(HelpMessage :config pass_through);

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

my $Project_Dir = $ARGV[0] or die "[FATAL]  Project directory must be specified\n";
$Project_Dir =~ s/\/$//;    # Remove trailing slash if any
my $Project = $Project_Dir;
$Project =~ s/^PROJ//;      # Remove leading 'PROJ'

open(my $OUT, '>', "make_FAH-PDBs_$Project.log");

if ($Is_Dry_Run) { print $OUT "[INFO]  Executing in dry-run mode\n"; }

if   (defined $Log_File && -e $Log_File) { generate_pdbs_from_logfile($Log_File); }
else                                     { generate_all_pdbs(); }

close($OUT);

sub generate_pdbs_from_logfile {
    my ($logfile) = @_;

    my $homedir = getcwd();

    my $total_pdbs_count   = 0;
    my $current_pdbs_count = 0;
    my $previous_run       = -1;
    my $previous_clone     = -1;

    open(my $LOGFILE, '<', $logfile) or die "[FATAL]  $logfile: $!\n";
    while (defined(my $line = <$LOGFILE>) and $total_pdbs_count <= $Max_Pdb_Count) {
        my @values = split(/\s+/, chomp $line);

        my $logproj = $values[0];
        if ($logproj != $Project) {
            die "[FATAL]  Project $logproj found in $logfile is not the same as the expected PROJ$Project\!";
        }

        my $run   = $values[1];
        my $clone = $values[2];
        my $time  = $values[3];    # time in ps
        my $frame = $time / 100;

        # change directory only if the current run or clone # has changed in the log file
        if ($run != $previous_run or $clone != $previous_clone) {

            # print informative statistics and reset PDB count
            print $OUT "[INFO]  PROJ$Project/RUN$run/CLONE$clone\t$current_pdbs_count PDBs created\n";
            $current_pdbs_count = 0;

            # change to new working directory and remove all existing PDBs
            my $workdir = "$homedir/$Project_Dir/RUN$run/CLONE$clone/";
            chdir $workdir;
            print $OUT "[INFO]  Working on directory $workdir ...\n";

            if (!$Is_Dry_Run && $Remove_Existing) {
                `rm *.pdb *# 2> /dev/null`;
            }
        }

        my $xtc_file = get_xtc_file($Project, $run, $clone);
        if (not -e $xtc_file) {
            print $OUT "[WARN]  Skipped PROJ$Project/RUN$run/CLONE$clone: $xtc_file does not exist\n";
            $previous_clone = $clone;
            $previous_run   = $run;
            next;
        }

        my $pdb_file = "p${Project}_r${run}_c${clone}_f${frame}.pdb";

        #TODO: Comment on what `echo 1 1` is for
        my $trjconv_cmd = "echo 1 1 | trjconv -s frame0.tpr -f $xtc_file -dump $time -o $pdb_file  2> /dev/null";
        print $OUT "[INFO]  Executing `$trjconv_cmd`\n";
        if (!$Is_Dry_Run) { `$trjconv_cmd`; }

        if (-e $pdb_file) {
            $total_pdbs_count++;
            $current_pdbs_count++;
        }
        elsif (!$Is_Dry_Run) {
            print $OUT "[ERROR]  Failed to create $pdb_file\n";
        }

        $previous_clone = $clone;
        $previous_run   = $run;
    }

    close($LOGFILE);
}

sub generate_all_pdbs {
    chdir $Project_Dir;
    my $cwd = getcwd();

    my @run_dirs = get_dirs($cwd, "^RUN\\d+\$");
    if (scalar(@run_dirs) == 0) {
        print $OUT "[INFO]  No RUN found\n";
        return;
    }

    foreach my $run_dir (@run_dirs) {
        chdir $run_dir;

        my @clone_dirs = get_dirs("$cwd/$run_dir", "^CLONE\\d+\$");
        if (scalar(@clone_dirs) == 0) {
            print $OUT "No CLONE found in $run_dir\n";
            next;
        }

        foreach my $clone_dir (@clone_dirs) {
            chdir $clone_dir;

            if (!$Is_Dry_Run) { `rm *.pdb *# 2> /dev/null`; }

            my $xtc_file = get_xtc_file($Project, $run_dir, $clone_dir);
            if (not defined $xtc_file or not -e $xtc_file) {
                print $OUT "[INFO]  Skipped PROJ$Project/$run_dir/$clone_dir: $xtc_file does not exist\n";
                next;
            }

            my ($run_number, $clone_number) = get_run_clone_numbers_from_xtc_filename($xtc_file);

            my $pdb_file = "p${Project}_r${run_number}_c${clone_number}_f.pdb";

            #TODO: Comment on what `echo 1` means
            my $trjconv_cmd = "echo 1 | trjconv -s frame0.tpr -f $xtc_file -o $pdb_file -sep  2> /dev/null";
            print $OUT "[INFO]  Executing `$trjconv_cmd`\n";
            if (!$Is_Dry_Run) {
                `$trjconv_cmd`;
                rename_pdbs_in_cwd();
            }

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

sub get_xtc_file {
    my ($project, $run, $clone) = @_;
    $run =~ s/^RUN//;
    $clone =~ s/^CLONE//;

    my $xtc_file = "P${project}_R${run}_C${clone}.xtc";
    if (-e $xtc_file) { return $xtc_file; }

    my $cwd = getcwd();
    opendir(my $CWD, $cwd);
    my @xtc_files = grep { /\.xtc$/ } readdir($CWD);
    closedir($CWD);

    if (scalar(@xtc_files) == 0) {
        print $OUT "[WARN]  No XTC file found\n";
        return;
    }

    if (scalar(@xtc_files) > 1) {
        print $OUT "[WARN]  More than one XTC file found; using the first one\n";
        chomp($xtc_file = $xtc_files[0]);
        return $xtc_file;
    }

    chomp($xtc_file = $xtc_files[0]);
    return $xtc_file;
}

sub get_run_clone_numbers_from_xtc_filename {
    my ($xtc_filename) = @_;
    $xtc_filename =~ s/\.xtc$//;
    my @filename_parts = split(/_/, $xtc_filename);

    my $run_number = $filename_parts[1];
    $run_number =~ s/R//;

    my $clone_number = $filename_parts[2];
    $clone_number =~ s/C//;

    return ($run_number, $clone_number);
}

sub rename_pdbs_in_cwd {
    my $cwd = getcwd();
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

./fah-pdbs-make.pl - generate all PDBs for a F@H project

=head1 SYNOPSIS

./fah-pdbs-make.pl  project_dir  [--m=<number_of_max_pdb>] [--l=<log_file>] [--h]

e.g. ./fah-pdbs-make.pl PROJ1797 --max-pdb=1000 --logfile=../1797.log

Run this script in the same location as the PROJ* directories.
And don't forget the good old `usegromacs33` before running the script!

Additionally overwrite aminoacids.dat with aminoacids-NA.dat so that Gromacs
tools can recognize RNA molecules.

=over

=item --logfile, -l <log_file>

If specified will generate PDBs for frames listed in this file only.
All existing PDBs are removed before new ones are generated.

=item --remove-existing

Used together with --logfile. If specified will remove all existing PDBs.
This option is ignored if a log file is not specified.

=item --dry-run

When specified, no files would be created/modified.

=item --pdbmax, -p <num>

If specified will process this number <num> of PDBs only. Default to 100,000,000.

=item --help, -h

Print this help message.

=back

=cut
