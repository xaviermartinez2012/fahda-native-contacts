#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(HelpMessage);

GetOptions("help|h" => sub { print STDOUT HelpMessage() });

# 7.0 A or less atomic seperations will be recorded
my $MAX_DISTANCE = 7.0;

# Delta(res) = res(j) - res(i) >= 3, must have 2 or more residues between
my $DELTA_RESIDUES = 2;

my $Project_Number = $ARGV[0] or die "\n";    #TODO:
$MAX_DISTANCE   = $ARGV[1] or die "\n";       #TODO:
$DELTA_RESIDUES = $ARGV[2] or die "\n";       #TODO:

my $work = `pwd`;
chomp $work;
print STDOUT "$work\n";

my $Total_Frames;
do_work();

print STDOUT "Total Frames = $Total_Frames ... ";
print STDOUT "Done!\n";

sub do_work {
    my $run_path  = $work . "/PROJ" . $Project_Number . "\/RUN" . "\*\/";
    my $run_count = `ls -d $run_path | wc | awk '{print \$1}'`;
    chomp $run_count;

    for (my $run_number = 0 ; $run_number < int($run_count) ; $run_number++) {
        my $clonepath   = "${work}/PROJ${Project_Number}/RUN${run_number}/CLONE*/";
        my $clone_count = `ls -d $clonepath | wc | awk '{print \$1}'`;
        chomp($clone_count);

        for (my $clone_number = 0 ; $clone_number < int($clone_count) ; $clone_number++) {
            my $file_path  = "${work}/PROJ${Project_Number}/RUN${run_number}/CLONE${clone_number}/p${Project_Number}*.pdb";
            my $file_count = `ls $file_path | wc | awk '{print \$1}'`;
            chomp $file_count;

            for (my $frame_number = 0 ; $frame_number < int($file_count) ; $frame_number++) {
                my $pdb_name = "p${Project_Number}_r${run_number}_c${clone_number}_f${frame_number}.pdb";
                my $pdb_file = "${work}/PROJ${Project_Number}/RUN${run_number}/CLONE${clone_number}/${pdb_name}";

                my $con_name = "p${Project_Number}_r${run_number}_c${clone_number}_f${frame_number}.con";
                my $con_file = "${work}/PROJ$Project_Number/RUN$run_number/CLONE$clone_number/$con_name";

                calculate_contacts($pdb_file, $con_file);
            }
        }
    }
}

# find native contacts with condition delta residue >=4 and distant between two atoms <=3.0
# No, this code is finding ALL contacts, not just native contacts ... that's why it's now called a *.con file
sub calculate_contacts {
    my ($pdb_file, $con_file) = pop(@_);

    if (not -e $pdb_file) {
        print STDOUT "ERROR: pdb file $pdb_file does not exist ...\n";
        return;
    }

    my $pdbsize = calc_file_size($pdb_file);
    if ($pdbsize == 0) {
        print STDOUT "ERROR: pdb file $pdb_file is zero-sized ...\n";
        return;
    }

    calculate_contacts_for_real($pdb_file, $con_file);
}

sub calc_file_size {
    my ($pdb_file) = @_;
    my $size = `wc $pdb_file`;
    chomp $size;
    my @sizearray = split(/\b\s+\b/, $size);
    my $pdbsize = $sizearray[0];
    return $pdbsize;
}

sub calculate_contacts_for_real {
    my ($pdb_file, $con_file) = @_;

    print STDOUT "Parsing $pdb_file\n";
    my @data;
    my $total_rows;
    open(my $PDB, '<', $pdb_file) or die $!;
    while (my $line = <$PDB>) {
        chomp(my @pdb_values = split(/\b\s+\b/, $line));
        if ($pdb_values[0] ne "ATOM") { next; }
        push(@data, \@pdb_values);
        $total_rows++;
    }
    close($PDB) || die $!;

    #compare distance between two atoms
    open(my $W, '>', $con_file) or die "[FATAL]  $con_file: $!\n";
    for (my $i = 0 ; $i < $total_rows ; $i++) {
        for (my $j = $i + 1 ; $j < $total_rows ; $j++) {
            my $deltaRes = abs($data[$j][4] - $data[$i][4]);

            # delta residues >=3 ... No: now we use only > and start at 4, so it's >= 5 now
            if ($deltaRes <= $DELTA_RESIDUES) { next; }

            my $deltaX   = $data[$j][5] - $data[$i][5];
            my $deltaY   = $data[$j][6] - $data[$i][6];
            my $deltaZ   = $data[$j][7] - $data[$i][7];
            my $distance = sqrt(($deltaX * $deltaX) + ($deltaY * $deltaY) + ($deltaZ * $deltaZ));

            # only keep it if it's < the desired cutoff ... default at 6.0 A
            if ($distance > $MAX_DISTANCE) { next; }
            print $W $data[$i][1] . "\t" . $data[$i][2] . "\t" . $data[$i][3] . "\t" . $data[$i][4] . "\t\t";
            print $W $data[$j][1] . "\t" . $data[$j][2] . "\t" . $data[$j][3] . "\t" . $data[$j][4] . "\t\t" . $deltaRes . "\t";
            printf $W "%7.3f\n", $distance;
        }
    }
    close($W) or die "[FATAL]  $con_file: $!\n";
}

=head1 NAME

fah-cons-calc.pl - #TODO: description

=head1 SYNOPSIS

./fah-cons-calc.pl  PROJ  <max_atomic_distance (7.0 A)>  <min residue seperation (2 res)> >& stderr.log &

Prints out individual con files but does NOT concatenate them into a single contacts-log file,
which is done by fah-cons-join.pl

=cut
