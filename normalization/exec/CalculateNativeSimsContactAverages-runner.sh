#!/bin/sh

# This was written after the fact. --KN 09/27/2016
NATIVE_SIM_LIST="../native-sims-luteo-cutoff5A-rmsd.txt"
DATA="../luteo-1796-1798-categorized-contacts-rmsd-rg.txt"
OUTPUT_PREFIX="luteo-1796-1798-averaged-native-contacts"
./CalculateNativeSimsContactAverages.pl $NATIVE_SIM_LIST $DATA $OUTPUT_PREFIX