#!/bin/sh

NATIVE_SIM_LIST="../../native-sims-luteo-cutoff5A-rmsd.txt"
DATA="../../luteo-1796-1798-categorized-contacts-rmsd-rg.txt"
OUTPUT_PREFIX="luteo-1796-1798-native-sims"

./native-sims-data-extractor.pl NATIVE_SIM_LIST DATA OUTPUT_PREFIX