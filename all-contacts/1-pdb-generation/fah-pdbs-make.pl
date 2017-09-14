#!/usr/bin/perl

=head1 NAME

fah-pdbs-make-all.pl - generate all PDBs for a F@H project

=head1 SYNOPSIS

./fah-pdbs-make-all.pl  project  [--m=<number_of_max_pdb>] [--l=<log_file>] [--h]

e.g. ./fah-pdbs-make-all.pl 1797 --max-pdb=1000 --logfile=../1797.log

Run this script in the location of the F@H PROJ directory.
And don't forget the good old `usegromacs33` before running this script!

Additionally overwrite aminoacids.dat with aminoacids-NA.dat so that Gromacs
tools can recognize RNA molecules.

=over

=item --logfile, -l <log_file>

If specified will generate PDBs for frames listed in this file only.
All existing PDBs are removed before new ones are generated.

=item --remove-existing

Used together with --logfile. If specified will remove all existing PDBs.
This option is ignored if a log file is not specified.

=item --pdbmax, -p <num>

If specified will process this number <num> of PDBs only. Default to 100,000,000.

=item --help, -h

Print this help message.

=back

=cut

use strict;
use warnings;
use Getopt::Long qw(HelpMessage :config pass_through);

my $Max_Pdb_Count   = 100000000;
my $Remove_Existing = "false";
GetOptions(
    "logfile|l:s"     => \my $Log_File,
    "remove-existing" => sub { $Remove_Existing = "true" },
    "pdbmax|m:i"      => \$Max_Pdb_Count,
    "help|h" => sub { print HelpMessage(0) }
);
my $Project = $ARGV[0] or die "[FATAL]  Project number must be specified\n" . HelpMessage(1);

open(my $OUT, '>', "make_FAH-PDBs_$Project.log");
if   (-e $Log_File) { generate_pdbs_from_logfile($Log_File); }
else                { generate_all_pdbs(); }
close($OUT);

sub generate_pdbs_from_logfile {
    my ($logfile) = @_;

    my $homedir = `pwd`;
    chomp $homedir;

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
            print $OUT "PROJ$Project/RUN$run/CLONE/$clone\t$current_pdbs_count PDBs created\n";
            $current_pdbs_count = 0;

            # change to new working directory and remove all existing PDBs
            my $workdir = "$homedir/PROJ$Project/RUN$run/CLONE$clone/";
            chdir $workdir;
            print $OUT "[INFO]  Working on directory $workdir ...\n";

            if ($Remove_Existing eq "true") {
                `rm *.pdb *# 2> /dev/null`;
            }
        }

        my $xtc_file = "P${Project}_R${run}_C${clone}.xtc";
        if (not -e $xtc_file) {
            print $OUT "[INFO]  Skipped PROJ$Project/RUN$run/CLONE$clone: $xtc_file does not exist\n";
            $previous_clone = $clone;
            $previous_run   = $run;
            next;
        }

        my $pdb_file = "p${Project}_r${run}_c${clone}_f${frame}.pdb";

        #TODO: Comment on what `echo 1 1` is for
        my $trjconv_cmd = "echo 1 1 | trjconv -s frame0.tpr -f $xtc_file -dump $time -o $pdb_file  2> /dev/null";
        print $OUT "Executing `$trjconv_cmd`\n";
        `$trjconv_cmd`;

        if (-e $pdb_file) {
            $total_pdbs_count++;
            $current_pdbs_count++;
        }
        else {
            print $OUT "[ERROR]  Failed to create $pdb_file\n";
        }

        $previous_clone = $clone;
        $previous_run   = $run;
    }

    close($LOGFILE);
}

sub generate_all_pdbs {
    my @runs = `ls | grep RUN`;
    if (scalar(@runs) == 0) { return; }

    foreach my $run (@runs) {
        chdir($run);

        my @clones = `ls | grep CLONE`;
        if (scalar(@clones) == 0) { next; }

        foreach my $clone (@clones) {
            `rm *.pdb *# 2> /dev/null`;

            my $xtc_file = "P${Project}_R${run}_C${clone}.xtc";
            if (not -e $xtc_file) {
                print $OUT "[INFO]  Skipped PROJ$Project/RUN$run/CLONE$clone: $xtc_file does not exist\n";
                next;
            }

            my $pdb_file = "p${Project}_r${run}_c${clone}_f.pdb";

            #TODO: Comment on what `echo 1` means
            my $trjconv_cmd = "echo 1 | trjconv -s frame0.tpr -f $xtc_file -o $pdb_file -sep  2> /dev/null";
            print $OUT "[INFO]  Executing `$trjconv_cmd`\n";
            `$trjconv_cmd`;

            my @pdb_files = `ls | grep .pdb`;
            rename_pdbs(@pdb_files);
        }

        chdir("..");
    }
}

sub rename_pdbs {
    my (@pdbs) = @_;
    if (scalar(@pdbs) == 0) { return; }

    foreach my $pdb (@pdbs) {
        if (!$pdb =~ m/_f_/) { next; }
        my $new_pdb = $pdb;
        $new_pdb =~ s/_f_/_f/;
        `mv $pdb $new_pdb 2> /dev/null`;
    }
}
