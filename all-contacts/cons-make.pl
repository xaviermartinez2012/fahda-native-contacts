#!/usr/bin/perl

use strict;
use warnings;
use Cwd;
use Getopt::Long qw(HelpMessage);

GetOptions("help|h" => sub { print STDOUT HelpMessage() });

# 7.0 A or less atomic seperations will be recorded
# my $MAX_DISTANCE = 7.0;

# Delta(res) = res(j) - res(i) = the number of residues between atoms i's and j's residues
# e.g. if delta(res) >= 3, there are 2 or more residues between atoms i's and j's residues
my $DELTA_RESIDUES = 2;

my $Project_Number = $ARGV[0] or die "A project number must be specified\n";
$MAX_DISTANCE   = $ARGV[1] or die "\n";    #TODO:
$DELTA_RESIDUES = $ARGV[2] or die "\n";    #TODO:

my $Cwd = getcwd();
my $Total_Frames;
do_work($Cwd);

print STDOUT "Total Frames = $Total_Frames ... ";
print STDOUT "Done!\n";

sub do_work {
    my ($cwd) = @_;
    my $project_path = "$cwd/PROJ$Project_Number";
    my $run_count = scalar(get_dirs($project_path, '^RUN\d+$'));

    for (my $run_number = 0 ; $run_number < $run_count ; $run_number++) {
        my $run_path = "$project_path/RUN$run_number";
        if (not -d $run_path) { next; } #TODO: print info?

        my $clone_count = scalar(get_dirs($run_path, '^CLONE\d+$'));
        for (my $clone_number = 0 ; $clone_number < $clone_count ; $clone_number++) {
            my $clone_path = "$run_path/CLONE$clone_number";
            if (not -d $clone_path) { next; } #TODO: print info?

            my $pdb_file_count = scalar(get_files($clone_path, "p${Project_Number}_.*\.pdb\$"));
            for (my $frame_number = 0 ; $frame_number < $pdb_file_count ; $frame_number++) {
                my $pdb_name   = "p${Project_Number}_r${run_number}_c${clone_number}_f${frame_number}.pdb";
                my $pdb_values = parse_pdb("$clone_path/$pdb_name");
                if (not defined $pdb_values || scalar(@$pdb_values) == 0) { next; }    #TODO: print info?

                my $con_name = $pdb_name;
                $con_name =~ s/pdb$/con/;
                calculate_contacts($pdb_values, "$clone_path/$con_name");
            }
        }
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

sub get_files {
    my ($root, $match_pattern) = @_;
    if (not -d $root) { return; }
    if ($root !~ m/\/$/) { $root .= "/"; }

    opendir(my $ROOT_HANDLE, $root);
    my @files = grep { -e "$root$_" && /$match_pattern/ } readdir($ROOT_HANDLE);
    closedir($ROOT_HANDLE);

    return @files;
}

sub parse_pdb {
    my ($pdb_file) = @_;

    if (not -e $pdb_file) {
        print STDOUT "[ERROR] $pdb_file does not exist ...\n";
        return;
    }

    my $pdbsize = calc_file_size($pdb_file);
    if ($pdbsize == 0) {
        print STDOUT "[ERROR]  $pdb_file is zero-sized ...\n";
        return;
    }

    print STDOUT "[INFO]  Parsing $pdb_file\n";

    my @pdb_values;
    open(my $PDB, '<', $pdb_file) or die $!;
    while (my $line = <$PDB>) {
        if ($line !~ m/^\s*ATOM/) { next; }
        chomp(my @pdb_values = split(/\b\s+\b/, $line));
        push(@pdb_values, \@pdb_values);

    }
    close($PDB) or die "$pdb_file: $!\n";

    return \@pdb_values;
}

sub calc_file_size {
    my ($file) = @_;
    return int(-s $file);
}

sub calculate_contacts {
    my ($pdb_values, $con_file) = @_;
    my $total_rows = scalar(@$pdb_values);
    open(my $CON, '>', $con_file) or die "[FATAL]  $con_file: $!\n";
    for (my $i = 0 ; $i < $total_rows ; $i++) {
        for (my $j = $i + 1 ; $j < $total_rows ; $j++) {
            my $delta_residues = abs($$pdb_values[$j][4] - $$pdb_values[$i][4]);
            if ($delta_residues <= $DELTA_RESIDUES) { next; }

            my $deltaX   = $$pdb_values[$j][5] - $$pdb_values[$i][5];
            my $deltaY   = $$pdb_values[$j][6] - $$pdb_values[$i][6];
            my $deltaZ   = $$pdb_values[$j][7] - $$pdb_values[$i][7];
            my $distance = sqrt($deltaX**2 + $deltaY**2 + $deltaZ**2);

            # only keep it if it's < the desired cutoff ... default at 6.0 A (#REVIEW: out-dated value?)
            if ($distance > $MAX_DISTANCE) { next; }

            print $CON $$pdb_values[$i][1] . "\t"    # atom number
              . $$pdb_values[$i][2] . "\t"           # atom name
              . $$pdb_values[$i][3] . "\t"           # residue name
              . $$pdb_values[$i][4] . "\t\t";        # residue number
            print $CON $$pdb_values[$j][1] . "\t"    # atom number
              . $$pdb_values[$j][2] . "\t"           # atom name
              . $$pdb_values[$j][3] . "\t"           # residue name
              . $$pdb_values[$j][4] . "\t\t"         # residue number
              . $delta_residues . "\t";
            printf $CON "%7.3f\n", $distance;        # Euclidean distance in Angstroms
        }
    }
    close($CON) or die "[FATAL]  $con_file: $!\n";
}

=head1 NAME

fah-cons-calc.pl - #TODO: description
# find native contacts with condition delta residue >=4 and distant between two atoms <=3.0
# No, this code is finding ALL contacts, not just native contacts ... that's why it's now called a *.con file

=head1 SYNOPSIS

./fah-cons-calc.pl  PROJ  <max_atomic_distance (7.0 A)>  <min residue seperation (2 res)> >& stderr.log &

Prints out individual con files but does NOT concatenate them into a single contacts-log file,
which is done by fah-cons-join.pl

=cut
