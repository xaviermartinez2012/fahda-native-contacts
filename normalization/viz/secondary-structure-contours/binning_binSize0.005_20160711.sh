#!/bin/sh

# $ binning2d [input]  [y] [y-min] [y-max] [y-resolution]   [x] [x-min] [x-max] [x-resolution] [TimeCut] [output]

BINSIZE=0.005
STEM1="6 0.0 1.211 $BINSIZE"
STEM2="7 0.0 1.345 $BINSIZE"
LOOP2="9 0.0 2.508 $BINSIZE"
TERT=" 10 0.0 1.734 $BINSIZE"

# 1. Native Contacts: Stem 1 vs. Stem 2
binning2d ../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized_20160406_225330.txt  $STEM1 $STEM2 6000 S1-${BINSIZE}_S2-${BINSIZE}_6ns.bin &

# 2. Native Contacts: Stem 1 vs. Tertiary
binning2d ../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized_20160406_225330.txt  $STEM1 $TERT 6000 S1-${BINSIZE}_T-${BINSIZE}_6ns.bin &

# 3. Native Contacts: Stem 2 vs. Tertiary
binning2d ../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized_20160406_225330.txt  $STEM2 $TERT 6000 S2-${BINSIZE}_T-${BINSIZE}_6ns.bin &

# 4. Native Contacts: Stem 1 vs. Loop 2
binning2d ../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized_20160406_225330.txt  $STEM1 $LOOP2 6000 S1-${BINSIZE}_L2-${BINSIZE}_6ns.bin &

# 5. Native Contacts: Stem 2 vs. Loop 2
binning2d ../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized_20160406_225330.txt  $STEM2 $LOOP2 6000 S2-${BINSIZE}_L2-${BINSIZE}_6ns.bin &

# 6. Native Contacts: Loop 2 vs. Tertiary
binning2d ../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized_20160406_225330.txt  $LOOP2 $TERT 6000 L2-${BINSIZE}_T-${BINSIZE}_6ns.bin &
