#!/usr/bin/perl

# ------------------------------------------------------------------------------
# Generate pdb file for a specific time
# Originally written by Phuc La
# ------------------------------------------------------------------------------

use strict;

$chdir   = '/home/la/Desktop/testing/';
$outxtc  = "${chdir}P1796_R0_C78.xtc";
$tprfile = "${chdir}frame0.tpr";

chdir $chdir;

# Remove all pdb file in the location
system('rm *.pdb');

# Generate all pdb files, including duplicates
system("echo 1 | trjconv -f $outxtc -s $tprfile -sep -o frame.pdb");

# Count how many PDBs were generated
$filepath    = "${chdir}frame\*.pdb";
$filecount   = `ls $filepath | wc| awk '{print $1}'`;
$lastpdbfile = int($filecount) - 1;

# Determine the last frames
$frame = 0;
for ($i = 0 ; $i <= $lastpdbfile ; $i++) {
    open(my $pdbIn, '<', "${chdir}frame${i}.pdb") || die "No pdb file";
    while ($line = <$pdbIn>) {
        chomp($line);
        foreach ($line) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
        my @lines = split(' ', $line);
        if ($lines[2] eq "t=") {
            $frame = int($lines[3]) / 100; # time in frame unit
            break;
        }
    }
    close($pdbIn) || die $!;
    $mvCommand = "mv -f ${chdir}frame${i}.pdb ${chdir}frame${frame}.pdb";
    system($mvCommand);
}
