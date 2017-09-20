#!/usr/bin/perl

######################################################################################################################
########                   find_native_sims.pl   For identifing Native RNA simulations                      ############
########                             Written by: Amethyst Radcliffe
######################################################################################################################

use strict;

$input2  = "1797_1799_all-aquif-data.log";

$output  = "aqui.cutoff4.5.native.sims.txt";
$output2 = "aqui.cutoff5.native.sims.txt";
$output3 = "aqui.cutoff5.5.native.sims.txt";

######### Reading in Data all at once for analysis ###############
open DATA2, $input2      or die "Unable to open the input file... Check location of input2.";
open OUT,   ">>$output"  or die "Unable to open the output1 file... Check the location of output.";
open OUT2,  ">>$output2" or die "Unable to open the output2 file... Check the location of output.";
open OUT3,  ">>$output3" or die "Unable to open the output3 file... Check the location of output.";

while ($line2 = <DATA2>) {    ### For each line, it will...
    chomp($line2);            ### ..cut off any extra newlines
    ##... and for each line, it cuts out the spaces and splits the numbers into an array
    foreach ($line2) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
    @num2 = split(/ /, $line2);
    $num = [@num2];    ### Then takes each array created in the loop and pushes it into another array
    push @data, $num;
}
close(DATA2);
##########  Setting Limits ###########
$totrow    = scalar(@data);
$totfields = scalar(@num2);
########## Setting up Do Loop for iterative analysis of simulation sets ##############
for ($j = 0 ; $j < $totrow ; $j++) {
    if ($data[$j][1] == 0.0) {
        do {    # for every simulation set... per clone
            $time  = $data[$j][3];    # set values
            $clone = $data[$j][2];
            if ($time > 0.0) {
                $rmsd = $data[$j][4];    # checking for native state under 4
                if ($rmsd <= 4.5) {
                    $count = "yes";
                    push @totaltime, $time;
                    push @resp,      $count;
                }
                else { $count = "no"; push @resp, $count; }    # Keeping count of native states.....for later
            }
            if ($time > 0.0) {
                $rmsd = $data[$j][4];                          # checking for native state under 4.5
                if ($rmsd <= 5) {
                    $count2 = "yes";
                    push @totaltime2, $time;
                    push @resp2,      $count2;
                }
                else { $count2 = "no"; push @resp2, $count2; }    # Keeping count of native states...... for
            }
            if ($time > 0.0) {
                $rmsd = $data[$j][4];                             # checking for native state under 5
                if ($rmsd <= 5.5) {
                    $count3 = "yes";
                    push @totaltime3, $time;
                    push @resp3,      $count3;
                }
                else { $count3 = "no"; push @resp3, $count3; }    # Keeping count of native states...... for later
            }
            $j++;                                                 # making sure it passes through all the time points in a clone
        } until ($data[$j][2] != $clone);    # termination condition for do loop
##########   Summing up the times    ####################
        $j          = $j - 1;
        $timeindex1 = scalar(@totaltime);
        $timeindex2 = scalar(@totaltime2);
        $timeindex3 = scalar(@totaltime3);
####### Now Checking to see if entire simulation is native by using the counts ##########
        $shouldWePrint  = "yes";             # Initializes print to yes;
        $shouldWePrint2 = "yes";
        $shouldWePrint3 = "yes";
        $totresp        = scalar(@resp);
        $totresp2       = scalar(@resp2);
        $totresp3       = scalar(@resp3);
############# cutoff 4
        for ($c = 0 ; $c < $totresp ; $c++) {
            if ($resp[$c] eq "no") { print "$resp[$c]  found a NO....\n"; $shouldWePrint = "no"; }    #checks if there is a no
        }
        if ($shouldWePrint eq "yes") {
            print OUT "$data[$j][0]    $data[$j][1]   $data[$j][2]    $data[$j][3]\n";
        }    # prints out run and clone if all frames in simulation were native
########## cutoff 4.5
        for ($n = 0 ; $n < $totresp2 ; $n++) {
            if ($resp2[$n] eq "no") { $shouldWePrint2 = "no"; }    #checks if there is a no
        }
        if ($shouldWePrint2 eq "yes") {
            print OUT2 "$data[$j][0]    $data[$j][1]   $data[$j][2]    $data[$j][3]\n";
        }    # prints out run and clone if all frames in simulation were native
########## cutoff 4.5
        for ($y = 0 ; $y < $totresp3 ; $y++) {
            if ($resp3[$y] eq "no") { $shouldWePrint3 = "no"; }    #checks if there is a no
        }
        if ($shouldWePrint3 eq "yes") {
            print OUT3 "$data[$j][0]    $data[$j][1]   $data[$j][2]    $data[$j][3]\n";
        }    # prints out run and clone if all frames in simulation were native

        @resp       = "";
        @resp2      = "";
        @resp3      = "";
        @totaltime  = "";
        @totaltime2 = "";
        @totaltime3 = "";
    }
}
close(OUT);
close(OUT2);
close(OUT3);
print "ALl done....... ~,~  \*sigh\* ..... That was a hard one.. \n";
