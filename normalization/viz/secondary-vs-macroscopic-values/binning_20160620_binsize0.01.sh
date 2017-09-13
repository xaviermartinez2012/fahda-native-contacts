#!/bin/sh

# $ binning2d [input]  [y] [y-min] [y-max] [y-resolution]   [x] [x-min] [x-max] [x-resolution] [TimeCut] [output]

INPUT="../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized_20160406_225330.txt"
CUTOFF="6000"

BINSIZE=0.01
STEM1="6 0.0 1.211 $BINSIZE"
STEM2="7 0.0 1.345 $BINSIZE"
LOOP1="8 0.0 1.580 $BINSIZE"
LOOP2="9 0.0 2.508 $BINSIZE"
TERT=" 10 0.0 1.734 $BINSIZE"

BINSIZE1=0.25
RMSD="4 0.043 32.660 $BINSIZE1"
RG="5 10.639 34.398 $BINSIZE1"
NC="11 0.0 1.308 $BINSIZE"
NNC="12 0.0 1.000 $BINSIZE"

binning2d $INPUT  $STEM1 $RMSD $CUTOFF S1-${BINSIZE}_RMSD-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $STEM1 $RG   $CUTOFF S1-${BINSIZE}_RG-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $STEM1 $NC   $CUTOFF S1-${BINSIZE}_NC-${BINSIZE}_6ns.bin &
binning2d $INPUT  $STEM1 $NNC  $CUTOFF S1-${BINSIZE}_NNC-${BINSIZE}_6ns.bin &

binning2d $INPUT  $STEM2 $RMSD $CUTOFF S2-${BINSIZE}_RMSD-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $STEM2 $RG   $CUTOFF S2-${BINSIZE}_RG-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $STEM2 $NC   $CUTOFF S2-${BINSIZE}_NC-${BINSIZE}_6ns.bin &
binning2d $INPUT  $STEM2 $NNC  $CUTOFF S2-${BINSIZE}_NNC-${BINSIZE}_6ns.bin &

binning2d $INPUT  $LOOP1 $RMSD $CUTOFF L1-${BINSIZE}_RMSD-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $LOOP1 $RG   $CUTOFF L1-${BINSIZE}_RG-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $LOOP1 $NC   $CUTOFF L1-${BINSIZE}_NC-${BINSIZE}_6ns.bin &
binning2d $INPUT  $LOOP1 $NNC  $CUTOFF L1-${BINSIZE}_NNC-${BINSIZE}_6ns.bin &

binning2d $INPUT  $LOOP2 $RMSD $CUTOFF L2-${BINSIZE}_RMSD-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $LOOP2 $RG   $CUTOFF L2-${BINSIZE}_RG-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $LOOP2 $NC   $CUTOFF L2-${BINSIZE}_NC-${BINSIZE}_6ns.bin &
binning2d $INPUT  $LOOP2 $NNC  $CUTOFF L2-${BINSIZE}_NNC-${BINSIZE}_6ns.bin &

binning2d $INPUT  $TERT $RMSD $CUTOFF T-${BINSIZE}_RMSD-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $TERT $RG   $CUTOFF T-${BINSIZE}_RG-${BINSIZE1}_6ns.bin &
binning2d $INPUT  $TERT $NC   $CUTOFF T-${BINSIZE}_NC-${BINSIZE}_6ns.bin &
binning2d $INPUT  $TERT $NNC  $CUTOFF T-${BINSIZE}_NNC-${BINSIZE}_6ns.bin &