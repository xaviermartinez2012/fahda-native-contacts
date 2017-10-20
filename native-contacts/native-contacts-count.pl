#!/usr/bin/perl

# ------------------------------------------------------------------------------
# Summing up categorized native contacts for entire project per time stamp
# Originally written by Amethyst Radcliffe and Khai Nguyen in 01/2014
# ------------------------------------------------------------------------------

use strict;
use POSIX qw/strftime/;

# flush anything in buffer to output to avoid delayed outputing
use FileHandle;
STDOUT->autoflush(1);

$usage = "$0 [project] [nat-con-file] [all-contact-file] [percent] [distance] [distanceNC]
[output-file] [exclude-list-output-file] [native-contacts-list-output-file]\n";

# number of atoms there are for the molecule, must be changed for every new molecule
$MOLECULE_ATOM_COUNT = 839;

$Project                                  = $ARGV[0] || die "$usage\n";
$Native_Contact_File                      = $ARGV[1] || die "$usage\n";
$All_Contact_File                         = $ARGV[2] || die "$usage\n";
$Minimum_Native_Contact_Occurance_Percent = $ARGV[3] || die "$usage\n";

$Distance   = $ARGV[4] || die "$usage\n";
$DistanceNC = $ARGV[5] || die "$usage\n";

$Output_File                       = $ARGV[6] || die "$usage\n";
$Excluded_Native_Contact_File      = $ARGV[7] || die "$usage\n";
$Included_Native_Contact_List_File = $ARGV[8] || die "$usage\n";

# INITIALIZE HASH TABLES
# ------------------------------------------------------------------------------
for (my $i = 1 ; $i < $MOLECULE_ATOM_COUNT ; $i++) {
    for (my $j = 1 ; $j < $MOLECULE_ATOM_COUNT ; $j++) {
        $Is_From_Native_Sim{"$i:$j"}                        = 0;
        $Native_Contact_Average_Distance{"$i:$j"}           = 0;
        $Native_Contact_Average_Distance_Plus_2SD{"$i:$j"}  = 0;
        $Native_Contact_Occurance_Percent{"$i:$j"}          = 0;
        $Native_Contact_Secondary_Structure_Symbol{"$i:$j"} = "";
        $Is_Excluded{"$i:$j"}                               = 0;
    }
}

# OPENING AND STORING NATIVE SIMULATIONS CONTACTS INFO
# INTO HASH TABLES FOR LATER COMPARISON
# ------------------------------------------------------------------------------
open(my $outNAT, '>', $Included_Native_Contact_List_File)
  || die "ERROR: Cannot write to $Included_Native_Contact_List_File: $!\n";

open(my $outEXL, '>', $Excluded_Native_Contact_File)
  || die "ERROR: Cannot write to $Excluded_Native_Contact_File: $!\n";

open(my $inNCLIST, '<', $Native_Contact_File) || die "ERROR: Cannot read $Native_Contact_File: $!\n";

while (my $line = <$inNCLIST>) {
    my @values = split(/s+/, chomp $line);

    my $nativeAtom1 = $values[0];
    my $nativeAtom2 = $values[4];

    $Is_From_Native_Sim{"$nativeAtom1:$nativeAtom2"}                        = 1;
    $Native_Contact_Occurance_Percent{"$nativeAtom1:$nativeAtom2"}          = $values[9];
    $Native_Contact_Average_Distance{"$nativeAtom1:$nativeAtom2"}           = $values[10];
    $Native_Contact_Average_Distance_Plus_2SD{"$nativeAtom1:$nativeAtom2"}  = $values[12];
    $Native_Contact_Secondary_Structure_Symbol{"$nativeAtom1:$nativeAtom2"} = $values[13];    # secondary structure symbol

    # Printing out exluded contacts for reference:
    # if the percent is small, print line to exclusion list
    if (($values[9] < $Minimum_Native_Contact_Occurance_Percent) or ($values[12] > $DistanceNC)) {
        $Is_Excluded{"$nativeAtom1:$nativeAtom2"} = 1;
        print $outEXL "$values\n";
    }
    else {
        print $outNAT "$values\n";
    }
}

close($inNCLIST);
close($outNAT);
close($outEXL);

# SAVE RESULT TO OUTPUT FILE
# ------------------------------------------------------------------------------
open(my $OUT,   '>', $Output_File)      || die "ERROR: Cannot write to $Output_File: $!\n";
open(my $inCON, '<', $All_Contact_File) || die "ERROR: Cannot read from $All_Contact_File: $!\n";

$Stem1_Native_Contact_Count    = 0;
$Stem2_Native_Contact_Count    = 0;
$Loop1_Native_Contact_Count    = 0;
$Loop2_Native_Contact_Count    = 0;
$Tertiary_Native_Contact_Count = 0;
$Total_Native_Contact_Count    = 0;
$Non_Native_Contact_Count      = 0;

$Run            = 0;
$Previous_Run   = 0;
$Clone          = 0;
$Previous_Clone = 0;
$Time           = 0;
$Previous_Time  = 0;

$Is_End_Of_Frame_Data = 0;

# EXTRACTING INFORMATION ABOUT PROJ, RUN, CLONE, AND TIME
# ------------------------------------------------------------------------------
while (my $line = <$inCON>) {
    my @values = split(/\s+/, chomp $line);

    if (is_end_of_frame_data($line)) {
        if ($. > 1) {    # if not the first line
            $Is_End_Of_Frame_Data = 1;
            $Previous_Run      = $Run;
            $Previous_Clone    = $Clone;
            $Previous_Time     = $Time;
        }

        ($Run, $Clone, $Time) = get_project_run_clone_frame($line);

        if ($Clone != $Previous_Clone) {
            print STDOUT "Processed $Project $Run $Previous_Clone\n";
            $Previous_Clone = $Clone;
        }
    }

    my $atom1 = $values[0];
    my $atom2 = $values[4];
    my $distance  = $values[9];

    if ($distance <= $Distance) {
        # if the atoms pair is on native list but not on exclusion list
        if ($Is_From_Native_Sim{"$atom1:$atom2"} == 1 && $Is_Excluded{"$atom1:$atom2"} == 0) {
            if ($distance <= $Native_Contact_Average_Distance_Plus_2SD{"$atom1:$atom2"}) {
                if    ($Native_Contact_Secondary_Structure_Symbol{"$atom1:$atom2"} eq "S1") { $Stem1_Native_Contact_Count++; }
                elsif ($Native_Contact_Secondary_Structure_Symbol{"$atom1:$atom2"} eq "S2") { $Stem2_Native_Contact_Count++; }
                elsif ($Native_Contact_Secondary_Structure_Symbol{"$atom1:$atom2"} eq "L1") { $Loop1_Native_Contact_Count++; }
                elsif ($Native_Contact_Secondary_Structure_Symbol{"$atom1:$atom2"} eq "L2") { $Loop2_Native_Contact_Count++; }
                elsif ($Native_Contact_Secondary_Structure_Symbol{"$atom1:$atom2"} eq "T")  { $t++; }
            }
        }
        elsif ($Is_From_Native_Sim{"$atom1:$atom2"} == 0 and $Is_Excluded{"$atom1:$atom2"} == 0) {
            $Non_Native_Contact_Count++;
        }
    }

    #  Print to output file
    if (eof() || $Is_End_Of_Frame_Data == 1) {
        $Total_Native_Contact_Count =
          $Stem1_Native_Contact_Count +
          $Stem2_Native_Contact_Count +
          $Loop1_Native_Contact_Count +
          $Loop2_Native_Contact_Count + $t;
        printf $OUT "%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\n",
          $Project, $Previous_Run, $Previous_Clone, $Previous_Time, $Stem1_Native_Contact_Count, $Stem2_Native_Contact_Count,
          $Loop1_Native_Contact_Count, $Loop2_Native_Contact_Count, $Tertiary_Native_Contact_Count, $Total_Native_Contact_Count,
          $Non_Native_Contact_Count;

        # reseting counters for next time frame
        $Stem1_Native_Contact_Count    = 0;
        $Stem2_Native_Contact_Count    = 0;
        $Loop1_Native_Contact_Count    = 0;
        $Loop2_Native_Contact_Count    = 0;
        $Tertiary_Native_Contact_Count = 0;
        $Total_Native_Contact_Count    = 0;
        $Non_Native_Contact_Count      = 0;

        $Is_End_Of_Frame_Data = 0;
    }
}

close($OUT);
close($inCON);


sub get_project_run_clone_frame {

    # No need to extract project number because it is input by user.
    # An example of timestamp in all-contact-data file: p1796_r0_c0_f0.con

    my ($line) = @_;
    my @values = split('_', $line);

    my $run   = $values[1] =~ s/r//r;
    my $clone = $values[2] =~ s/c//r;

    $values[3] =~ s/r//r;
    $values[3] =~ s/\.con//r;
    my $time = $values[3] * 100;

    return ($run, $clone, $time);
}


sub is_end_of_frame_data {
    # When a line is of the format "pX_rY_cZ_fW.con", where
	# X, Y, Z, and W represent project, run, clone, and time, respectively
    # it signifies the start of a new frame's atom-contact data
    my ($line) = @_;
    return ($line =~ "^p.+");
}
