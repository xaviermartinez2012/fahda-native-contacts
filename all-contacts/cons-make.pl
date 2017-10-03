#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use FindBin qw($Bin);
use Getopt::Long qw(HelpMessage :config pass_through);
use Getopt::Long qw(HelpMessage);
use lib "$Bin/../lib";
use Share::DirUtil qw(get_dirs);
use Share::FileUtil qw(get_files);
use Share::Fahda;

my $Max_Distance_In_A = undef;
my $Min_Delta_Residues = undef;
GetOptions(
    "max-atomic-distance|a" => \$Max_Distance_In_A,
    "min-delta-res|r"       => \$Min_Delta_Residues,
    "help|h"                => sub { print STDOUT HelpMessage() }
);

# HISTORICAL:
## 7.0 A or less atomic seperations will be recorded
# my $MAX_DISTANCE 7.0;
## Delta(res) = res(j) - res(i) = the number of residues between atoms i's and j's residues
## e.g. if delta(res) >= 3, there are 2 or more residues between atoms i's and j's residues
# my $DELTA_RESIDUES = 2;

# BREAKING CHANGE
# Delta(res) = res(j) - res(i) - 1 = # of residues between atoms i's & j's residues
# e.g. if delta(res) >= 2, there are 2 or more residues between atoms i's & j's residues

my $Project_Dir = $ARGV[0] or die "PROJ* dir must be specified\n";
if (not defined $Max_Distance_In_A) {
    die "A max atomic distance (in Angstroms) must be specified with --max-atomic-distance or -a\n";
}
if (not defined $Min_Delta_Residues) {
    die "A min delta residues value must be specified with --min-delta-res or -r\n";
}

$Project_Dir =~ s/\/$//;
my ($Project_Number) = $Project_Dir =~ /(\d+$)/;

my $Output_File = "make_FAH-CONs_$Project_Dir.log";
open(my $OUT, '>', $Output_File) or die "[FATAL]  $Output_File: $!\n";

do_work("${\getcwd()}/$Project_Dir");

close($Output_File);
print STDOUT "Done!\n";

sub do_work {
    my ($project_path) = @_;

    my $max_run_number = Share::Fahda::get_max_dir_number(get_dirs($project_path, '^RUN\d+$'));
    for (my $run_number = 0 ; $run_number <= $max_run_number ; $run_number++) {
        my $run_path = "$project_path/RUN$run_number";
        if (not -d $run_path) {
            print $OUT "$run_path not found\n";
            next;
        }
        print $OUT "Working on $run_path\n";

        my $max_clone_number = Share::Fahda::get_max_dir_number(get_dirs($run_path, '^CLONE\d+$'));
        for (my $clone_number = 0 ; $clone_number <= $max_clone_number ; $clone_number++) {
            my $clone_path = "$run_path/CLONE$clone_number";
            if (not -d $clone_path) {
                print $OUT "$clone_path not found\n";
                next;
            }
            print $OUT "Working on $clone_path\n";

            my $pdb_file_count = scalar(get_files($clone_path, "p${Project_Number}_.*\.pdb\$"));
            for (my $frame_number = 0 ; $frame_number < $pdb_file_count ; $frame_number++) {
                my $pdb_filename = "p${Project_Number}_r${run_number}_c${clone_number}_f${frame_number}.pdb";
                my $pdb_path     = "$clone_path/$pdb_filename";
                if (!Share::FileUtil::file_ok($pdb_path)) {
                    print $OUT "${Share::FileUtil::File_Ok_Message}\n";
                    next;
                }

                print $OUT "Parsing $pdb_path\n";
                my $pdb_values = parse_pdb("$pdb_path");
                if (not defined $pdb_values || scalar(@$pdb_values) == 0) {
                    print $OUT "No atom info found in $pdb_path\n";
                    next;
                }
                my $con_filename = $pdb_filename;
                $con_filename =~ s/pdb$/con/;
                calculate_contacts($pdb_values, "$clone_path/$con_filename");
            }
        }
    }
}

sub parse_pdb {
    my ($pdb_file) = @_;

    my @pdb_values = ();
    open(my $PDB, '<', $pdb_file) or die $!;
    while (my $line = <$PDB>) {
        $line =~ s/^\s*//;
        if ($line !~ m/^\s*ATOM/) { next; }
        chomp(my @fields = split(/\s+/, $line));
        push(@pdb_values, \@fields);
    }
    close($PDB) or die "$pdb_file: $!\n";

    return \@pdb_values;
}

sub calculate_contacts {
    my ($pdb_values, $con_file) = @_;

    my $total_rows = scalar(@$pdb_values);

    open(my $CON, '>', $con_file) or die "$con_file: $!\n";
    for (my $i = 0 ; $i < $total_rows ; $i++) {
        for (my $j = $i + 1 ; $j < $total_rows ; $j++) {
            my $delta_residues = abs($$pdb_values[$j][4] - $$pdb_values[$i][4]) - 1;
            if ($delta_residues < $Min_Delta_Residues) { next; }

            my $deltaX   = $$pdb_values[$j][5] - $$pdb_values[$i][5];
            my $deltaY   = $$pdb_values[$j][6] - $$pdb_values[$i][6];
            my $deltaZ   = $$pdb_values[$j][7] - $$pdb_values[$i][7];
            my $distance = sqrt($deltaX**2 + $deltaY**2 + $deltaZ**2);

            # only keep it if it's <= the desired cutoff ...
            # default at 6.0 A (#REVIEW: out-dated value?)
            if ($distance > $Max_Distance_In_A) { next; }

            printf $CON "%5d\t%5s\t%3s\t%4d\t", $$pdb_values[$i][1],    # atom number
              $$pdb_values[$i][2],                                      # atom name
              $$pdb_values[$i][3],                                      # residue name
              $$pdb_values[$i][4];                                      # residue number
            printf $CON "%5d\t%5s\t%3s\t%4d\t", $$pdb_values[$j][1],    # atom number
              $$pdb_values[$j][2],                                      # atom name
              $$pdb_values[$j][3],                                      # residue name
              $$pdb_values[$j][4];                                      # residue number
            printf $CON "%4d\t%7.3f\n", $delta_residues, $distance;
        }
    }
    close($CON);
}

=head1 NAME

cons-make.pl - find all atom-atom contacts

=head1 SYNOPSIS

cons-make.pl <project_dir> -a=<max_atomic_distance> -r=<min_residue_separation>

Find atom-to-atom contacts where delta residue >= <min_residue_separation> and
atomic distance <= <max_atomic_distance>. Prints out to individual con files,
run cons-join.pl to concatenate them. Progress is printed to an output log file
(make_FAH-CONs_PROJ*.log).

=cut
