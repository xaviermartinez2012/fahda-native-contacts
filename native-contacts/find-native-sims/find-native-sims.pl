#!/usr/bin/perl

# ------------------------------------------------------------------------------
# find_native_sims.pl: Identify native RNA simulations
# Originally written by Amethyst Radcliffe
# ------------------------------------------------------------------------------

use strict;

$input =
"/home/server/FAHdata/PKNOT-DATA/new.PKNOT.project/Analysis/find_native_contacts/1797_1799_all-aquif-data.log";

$output =
"/home/server/FAHdata/PKNOT-DATA/new.PKNOT.project/Analysis/find_native_contacts/aqui.cutoff4.native.sims.txt";
$output2 =
"/home/server/FAHdata/PKNOT-DATA/new.PKNOT.project/Analysis/find_native_contacts/aqui.cutoff4.5.native.sims.txt";
$output3 =
"/home/server/FAHdata/PKNOT-DATA/new.PKNOT.project/Analysis/find_native_contacts/aqui.cutoff5.native.sims.txt";

######### Reading in Data all at once for analysis ###############
open my $INPUT_LOG, '<',  $input  or die "Unable to open $input: $!\n";
open my $OUT,   ">>", $output  or die "Unable to open $output: $!\n";
open my $OUT2,  ">>", $output2 or die "Unable to open $output2: $!\n";
open my $OUT3,  ">>", $output3 or die "Unable to open $output3: $!\n";

while (my $line2 = <$INPUT_LOG>) {
    chomp($line2);
    foreach ($line2) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
    my @num2 = split(/ /, $line2);
    $num = [@num2];
    push @data, $num;
}
close($INPUT_LOG);

# Setting Limits
$totrow    = scalar(@data);
$totfields = scalar(@num2);

# Setting up Do Loop for iterative analysis of simulation sets
$j = 0;
while ($data[$j][1] == 0) {
    do {
        $time  = $data[$j][3];
        $clone = $data[$j][2];
        if ($time > 0.0) {
            $rmsd = $data[$j][4];    # checking for native state under 4
            if ($rmsd <= 3.0) {
                $count = "yes";
                push @totaltime, $time;
                push @resp,      $count;
            }
            else {
                $count = "no";
                push @resp, $count;
            }
        }
        if ($time > 0.0) {
            $rmsd = $data[$j][4];    # checking for native state under 4.5
            if ($rmsd <= 3.5) {
                $count2 = "yes";
                push @totaltime2, $time;
                push @resp2,      $count2;
            }
            else {
                $count2 = "no";
                push @resp2, $count2;
            }    # Keeping count of native states...... for later
        }
        if ($time > 0.0) {
            $rmsd = $data[$j][4];    # checking for native state under 5
            if ($rmsd <= 4.0) {
                $count3 = "yes";
                push @totaltime3, $time;
                push @resp3,      $count3;
            }
            else {
                $count3 = "no";
                push @resp3, $count3;
            }    # Keeping count of native states...... for later
        }
        $j++;    # making sure it passes through all the time points in a clone
    } until ($data[$j][2] != $clone);    # termination condition for do loop

    $j          = $j - 1;
    $timeindex1 = scalar(@totaltime);
    $timeindex2 = scalar(@totaltime2);
    $timeindex3 = scalar(@totaltime3);

	# Now Checking to see if entire simulation is native by using the counts
    $shouldWePrint  = "yes";             # Initializes print to yes;
    $shouldWePrint2 = "yes";
    $shouldWePrint3 = "yes";
    $totresp        = scalar(@resp);
    $totresp2       = scalar(@resp2);
    $totresp3       = scalar(@resp3);

	# cutoff 4
    for ($c = 0 ; $c < $totresp ; $c++) {

        if ($resp[$c] eq "no") {
            print "$resp[$c]  found a NO....\n";
            $shouldWePrint = "no";
        }
    }
    if ($shouldWePrint eq "yes") {
        print $OUT
"For Run $data[$j][1] Clone $data[$j][2] .... number of frames that meet requirement $timeindex1"
          . ", total time $data[$j][3]\n";
        print $OUT "$data[$j][1]   $data[$j][2] ......native sim\n\n";
    }

	########## cutoff 4.5
    for ($n = 0 ; $n < $totresp2 ; $n++) {
        if ($resp2[$n] eq "no") {
            $shouldWePrint2 = "no";
        }    #checks if there is a no
    }
    if ($shouldWePrint2 eq "yes") {
        print $OUT2
"For Run $data[$j][1] Clone $data[$j][2] .... number of frames that meet requirement $timeindex2"
          . ", total time $data[$j][3]\n";
        print OUT2 "$data[$j][1]   $data[$j][2] ..... native sim\n\n";
    }    # prints out run and clone if all frames in simulation were native

	########## cutoff 4.5
    for ($y = 0 ; $y < $totresp3 ; $y++) {
        if ($resp3[$y] eq "no") {
            $shouldWePrint3 = "no";
        }    #checks if there is a no
    }
    if ($shouldWePrint3 eq "yes") {
        print $OUT3
"For Run $data[$j][1] Clone $data[$j][2] .... number of frames that meet requirement $timeindex3"
          . ", total time $data[$j][3]\n";
        print $OUT3 "$data[$j][1]   $data[$j][2] ..... native sim\n\n";
    }    # prints out run and clone if all frames in simulation were native

    @resp       = "";
    @resp2      = "";
    @resp3      = "";
    @totaltime  = "";
    @totaltime2 = "";
    @totaltime3 = "";
    $j++;
}
close($OUT);
close($OUT2);
close($OUT3);
