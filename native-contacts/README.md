# Native Contact Calculation

## `find-native-sims.pl`

Find native simulations where the structure of each data point has an RMSD no
greater than a max RMSD (when compared to frame0).

**Input**: (_a_) logfile (project/run/clone/last_time_in_ps/RMSD);
           (_b_) max RMSD (Angstroms).

**Output**: `native_sims_<MAX_RMSD>A.txt`, containing project/run/clone/last_time_in_ps.

**Logic**: For each simulation (having a unique project/run/clone), if all data point
           has an RMSD not greater than MAX_RMSD, it is considered native. When this is
           the case, output the simulation's project, run, clone, and final timeframe (ps).

## `extract-native-sim-contacts.pl`

Given a list of native simulations, extract atomic contact data to an outfile.

**Input**: (_a_) list of native simulations (proj/run/clone/last_time_in_ps);
           (_b_) concatenated all_contact.con.

**Output**: atomic contacts data from native sims only.

**Logic**:

  1. Read in list of native simulations (project/run/clone)
  1. Read in concatenated contacts file
     1. If project/run/clone in this file matches one from native simulations list,
        print to output all contacts info

## `native-sim-contacts-distance-stats.pl`

+ Input
  + List of contacts from native sims
  + List of native simulations (proj/run/clone/last_time_in_ps)
+ Output
  + Unique contacts with percent of time this contact appears in native sims (collectively),
    mean distances, standard deviation, and mean + 2 * standard devisions

### Logic of `native-sim-contacts-distance-stats.pl`

1. Read the list of native sims (proj/run/clone/total time) and import the times (in ps), sum them up then divide by 100 to get the total number of frames.
1. Read in the list of contacts from native sims
    1. For each line, remove the distance
        1. If the current i-j contact is the same as the i-j contact from the previous line
           (or if the previous line is empty [when reading the beginning of this file]),
           save the i-j distance to a temporary location (id’ed by “$i-$j”).
        1. If the current $i-$j contact is not the same as the previous $i-$j contact,
           save this current contact, then look at all of the contacts id’ed by the previous $i-$j pair.
           This should contains all the distances of all $i-$j contacts. To this collections of distances,
           find the following statistical quantities: mean (average) distance, total number of distances,
           standard deviation, mean distance + 2 standard dev, and percentage (total number of distances
           divided by total number of frames in all native sims). If this percentage is larger than a
           set cut-off, print these quantities to output.

## `native-sim-contacts-2nd-structure.pl`

<<<<<<< HEAD
+ Input
  + secondary structures key file
  + native sim contacts
+ Output
  + Same as input but add 2nd structure info
=======
## `native-sim-contacts-structures.pl`

**Input**: (_a_) native sim contacts;
           (_b_) secondary structure keys file.
**Output**: Same as input but add 2nd structure info.

**Logic**:

  1. Import structure keys from file
  1. ??? Read in the output from 01.b.v3 and add on secondary structure info
     for each line based on `i`-`j` atom pair

## `find-native-contacts.pl`

**Input**: TBD
>>>>>>> 34802ea... Rename 4-summarize-all-contact-data.pl to native-contacts-count.pl

**Output**: TBD

**Logic**: TBD

## `summarize-all-contact-data.pl`

+ Input
  + a file with $i-$j contact, mean distance, mean + 2 * std dev, & structure info (output of 01.c)
  + Concatenated file
  + $P = 25
  + $distance = 4.5
  + $distanceNC = 6.0
+ Output
  + categorized contacts for all sim & time frames
  + list of native contacts
  + list of excluded contacts

### Logic of `summarize-all-contact-data.pl`

1. Read the file with summarized info of contacts from native sims.
    1. save $i-$j pair, percentage, mean distance, mean + 2*stddev, and 2nd structures.
    1. if the appearance percentage of a contact is smaller $P OR the distance is
       greater than $distanceNC (6.0), save that contact to an excluded list
    1. else, consider that contact native
1. Read concatenated contacts file, for all contacts of a given timestamp:
    1. if a $i-$j distance smaller than $distance (4.5), and if $i-$j pair is on the
       native list (and not on excluded list), and if  $i-$j distance is smaller than
       mean distance + 2 stddev (from native sims contacts list), count the number of
       NC (S1, S2, L1, L2, T)
    1. else, consider that contact non native

#### Additional Information

Logic behind summarizing all data's native contact information (implemented in the original "03" script written by A. Radcliff and K. Nguyen)

1. Initializes all variables
1. Reads in native contacts data from 01.c output
   + in tandem: fills in hashmap for all {i,j} pairs
   + define if on excluded or native contact lists (comparing to $P)
1. Reads in `all_contact_P$proj` data file
   + checks the timestamp and extracts P/R/C/T
   + foreach contact
     + check distance and compares to $D = [mean + 2SD]
     + (in each frame) assigning 2'/3' structure
     + output line states contact status
1. Every time a new timestamp is found, print the previous frame info