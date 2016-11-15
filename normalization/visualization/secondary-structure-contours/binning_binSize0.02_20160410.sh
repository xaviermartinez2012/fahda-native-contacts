#!/bin/sh

# $ cat luteo-normalized-min-max-special-l2-tert-treatment.txt
# ...........
# S1 (column #6)
# [0.000, 1.211]
# ...........
# S2 (column #7)
# [0.000, 1.345]
# ...........
# L1 (column #8)
# [0.000, 1.580]
# ...........
# L2 (column #9)
# [0.000, 1.833]
# ...........
# T (column #10)
# [0.000, 1.402]
# ...........
# NC (column #11)
# [0.000, 1.308]
# ...........
# NNC (column #12)
# [0.000, 1.000]

# $ binning2d [input]  [y] [y-min] [y-max] [y-resolution]   [x] [x-min] [x-max] [x-resolution] [TimeCut] [output]
INPUT="../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized-special-l2-tert-treatment_20161004_223320.txt"
BINSIZE=0.02
STEM1="6 0.0 1.211 $BINSIZE"
STEM2="7 0.0 1.345 $BINSIZE"
LOOP2="9 0.0 1.833 $BINSIZE"
TERT=" 10 0.0 1.402 $BINSIZE"

# 1. Native Contacts: Stem 1 vs. Stem 2
binning2d $INPUT  $STEM1 $STEM2 6000 S1-${BINSIZE}_S2-${BINSIZE}_6ns.bin &

# 2. Native Contacts: Stem 1 vs. Tertiary
binning2d $INPUT  $STEM1 $TERT 6000 S1-${BINSIZE}_T-${BINSIZE}_6ns.bin &

# 3. Native Contacts: Stem 2 vs. Tertiary
binning2d $INPUT  $STEM2 $TERT 6000 S2-${BINSIZE}_T-${BINSIZE}_6ns.bin &

# 4. Native Contacts: Stem 1 vs. Loop 2
binning2d $INPUT  $STEM1 $LOOP2 6000 S1-${BINSIZE}_L2-${BINSIZE}_6ns.bin &

# 5. Native Contacts: Stem 2 vs. Loop 2
binning2d $INPUT  $STEM2 $LOOP2 6000 S2-${BINSIZE}_L2-${BINSIZE}_6ns.bin &

# 6. Native Contacts: Loop 2 vs. Tertiary
binning2d $INPUT  $LOOP2 $TERT 6000 L2-${BINSIZE}_T-${BINSIZE}_6ns.bin &
