#!/bin/sh

# $ binning2d [input]  [y] [y-min] [y-max] [y-resolution]   [x] [x-min] [x-max] [x-resolution] [TimeCut] [output]

BINSIZE=0.01
INPUT="../../luteo-1796-1798-categorized-contacts-rmsd-rg-normalized_20160406_225330.txt"

# 1. Rg vs. RMSD
binning2d $INPUT  5  10.639 34.398 0.25  4  0.043 32.66 0.25  6000  Rg-0.25_RMSD-0.25_6ns.bin &

# 2. Rg vs. Non-Native Contacts
binning2d $INPUT  5  10.639 34.398 0.25  12 0.0 1.0 $BINSIZE     6000  Rg-0.25_NNC-${BINSIZE}_6ns.bin &

# 3. Rg vs. Native Contacts
binning2d $INPUT  5  10.639 34.398 0.25  11 0.0 1.308 $BINSIZE   6000  Rg-0.25_NC-${BINSIZE}_6ns.bin &

# 4. Native Contacts vs. RMSD
binning2d $INPUT  11 0.0    1.308 $BINSIZE     4  0.043 32.66 0.25  6000  NC-${BINSIZE}_RMSD-0.25_6ns.bin &

# 5. Non-Native Contacts vs. RMSD
binning2d $INPUT  12 0.0    1.0 $BINSIZE       4  0.043 32.66 0.25  6000  NNC-${BINSIZE}_RMSD-0.25_6ns.bin &

# 6. Native Contacts vs. Non-Native Contacts
binning2d $INPUT  11 0.0    1.308 $BINSIZE     12 0.0 1.0 $BINSIZE     6000  NC-${BINSIZE}_NNC-${BINSIZE}_6ns.bin &

