# Native Contact Calculations

## [`find-native-sims.pl`](https://github.com/xaviermartinez2012/fahda-native-contacts/blob/master/native-contacts/find-native-sims.pl)

Find native simulations where the structure of each data point has an RMSD no
greater than a max RMSD (when compared to frame0).

**Input**: (_a_) logfile (project/run/clone/last_time_in_ps/RMSD);
           (_b_) max RMSD (Angstroms).

**Output**: `native_sims_<MAX_RMSD>A.txt`, containing project/run/clone/last_time_in_ps.

**Logic**: For each simulation (having a unique project/run/clone), if all data point
           has an RMSD not greater than MAX_RMSD, it is considered native. When this is
           the case, output the simulation's project, run, clone, and final timeframe (ps).

## [`extract_native_sim_contacts.py`](https://github.com/xaviermartinez2012/fahda-native-contacts/blob/master/native-contacts/extract_native_sim_contacts.py)

Given a list of native simulations, extract atomic contact data to an outfile.

**Input**: 
* (_nst_) <native-sims.lst> - list of native simulations (proj/run/clone/last_time_in_ps)
* (_jcon_) <joined-cons.con> - concatenated all_contact.con.

**Output**: 
* (_outcon_) <output.con> - atomic contacts data from native sims only.

**Logic**:

  1. Read in list of native simulations (project/run/clone)
  1. Read in concatenated contacts file
     1. If project/run/clone in this file matches one from native simulations list,
        print to output all contacts info

## `native-sim-contacts-stats.pl`

**Input**: (_a_) native simulation atomic contact data;
           (_b_) list of native simulations (proj/run/clone/last_time_in_ps).

**Output**: Unique contacts with percent of time this contact appears in native sims (collectively),
            mean atomic distances, and their standard deviations.

**Logic**:

  1. Calculate the total number of frames in all native simulations
      1. Read the list of native simulations (proj/run/clone/total_time_in_ps) and import the times
      1. Sum them up
      1. Divide by 100
  1. Import atomic contact data from native simulations
      1. Store this data in a hash/dictionary whose keys are `i`-`j` atom numbers and whose
         corresponding values are arrays of atomic distances
  1. For each `i`-`j` atom pair's atomic distances, find the following statistical quantities:
      + mean atomic distance,
      + mean atomic distance standard deviation,
      + percentage (total number of distances divided by total number of frames in all native simulations)

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
