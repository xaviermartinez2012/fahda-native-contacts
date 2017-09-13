#!/usr/bin/perl

# ------------------------------------------------------------------------------
# Collecting all contacts from simulations that were determined to be native
# Originally written by Amethyst Radcliffe on 10/01/2013
# ------------------------------------------------------------------------------

use strict;

# immediately flush anything in buffer to output stream
use FileHandle;
STDOUT->autoflush(1);

# USAGE & GETTING INPUT INFORMATION INTO APPROPRIATE VARIABLES
# ------------------------------------------------------------------------------
$usage      = "\$perl script.pl  [native-sims-list.txt]  [all-contact-data.txt]  [output.txt]\n";
$natSimFile = $ARGV[0] or die "$usage\n";
$allConFile = $ARGV[1] or die "$usage\n";
$outFile    = $ARGV[2] or die "$usage\n";

if ($ARGV[0] eq "-h" || $ARGV[0] eq "--help") {
    print $usage;
    exit();
}

@Native_Simulations      = ();

# READING IN & STORING THE LIST CONTAINING NATIVE STATE SIMULATIONS
# ------------------------------------------------------------------------------
open(my $NSFILE, '<', $natSimFile) or die "ERROR: Cannot open $natSimFile: $!\n";
print "Reading $natSimFile...\n";

while (my $line = <$NSFILE>) {
    if ($line =~ m/#/) { next; }    # ignore comments/header in file
    chomp($line);

    # @values should have (0) project, (1) run, (2) clone, (3) total time (ps)
    my @values = split(/\s+/, $line);
    push(@Native_Simulations, "p$values[0]_r$values[1]_c$values[2]");
}

close($NSFILE) or die "ERROR: $natSimFile: $!\n";

#  Adding a check to make sure that the native simulations data is useable
$NSindex = scalar(@Native_Simulations);
if ($NSindex == 0) {
    print STDOUT "FATAL ERROR: There are no native simulations being used, ";
    print STDOUT "make sure native simulation file $natSimFile exists and is not empty.\n";
    exit;
}
else {
    print "Native sim file $natSimFile contains usable data. ";
}

# SETTING LOOP VARIABLES
# ------------------------------------------------------------------------------
$printLine     = 0;
$shouldWePrint = 0;
@ProjRunClone  = ();
$projIndicator = "";    # to get the first letter in the time stamp
                        # (from the concatenated data file)

# PROCESS LINES FROM THE ALL CONTACTS DATA FILE
# ------------------------------------------------------------------------------
open(my $OUT, '>>', $outFile) || die "ERROR: Cannot open $outFile: $!\n";
open(my $CONFILE, "<", $allConFile) or die "ERROR: Cannot open $allConFile: $!\n";

LBL: while (my $line = <$CONFILE>) {
    chomp($line);
    $printLine = $line;

    # get the first letter to check if this line is indicating a set of contacts for a new time stamp
    $projIndicator = substr($line, 0, 1);

    #####  Firstly, it checks to see if the line should be printed
    if ($shouldWePrint == 1 and $projIndicator ne "p") {
        print $OUT "$printLine\n";
    }

    # COMPARE & PRINT NATIVE SIMS CONTACTS
    # check the current line is that of a time stamp (e.g. "p1796_r0_c0_f0.con");
    # it is a timestamp if the first letter of the string is "p"
    if ($projIndicator ne "p") { next LBL; }

    @ProjRunClone = split(/_f/, $line);    #split away frame number

    for ($i = 0 ; $i < $NSindex ; $i++) {
        if (    ($ProjRunClone[0] eq $Native_Simulations[$i])
            and ($ProjRunClone[1] ne "0.con"))
        {
            $shouldWePrint = 1;
            print "Match found: 1: $ProjRunClone[0]_f$ProjRunClone[1], 2: $Native_Simulations[$i]\n";
            next LBL;
        }
        else {
            $shouldWePrint = 0;
        }
    }
}
close $CONFILE;
close $OUT;

print "Sorting $outFile...\n";
system("sort $outFile >> $outFile_sorted.txt");
print "Done!\n";
