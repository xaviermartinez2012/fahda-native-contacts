# pknot-native-contacts

Native contact characterization for pseudoknot structures

## Atom-to-atom Contact Calculation

TBD

## Native Contact Calculation

### `1-find-native-contacts-from-native-sims.pl`

#### Input
- File contains native simulations info (project/run/clone) and total time (in ps) for each of those simulations
- Concatenated contacts file

#### Output

- Contacts from native sims only.

#### Algorithm

1. Read in list of native simulations (project/run/clone)
2. Read in concatenated contacts file

    1. If project/run/clone in this file matches one from native simulations list, print to output all contacts info

3. Sort the output file

### `2-find-native-contacts-from-native-sims-add-percent-avg-distance-sd.pl`

#### Input
- List of contacts from native sims (output from 01.a)
- List of native sims (to obtain number of frames)

#### Output

Unique contacts with percent of time this contact appears in native sims (collectively), mean distances, standard deviation, and mean + 2 SD

#### Algorithm

1. Read the list of native sims (proj/run/clone/total time) and import the times (in ps), sum them up then divide by 100 to get the total number of frames.

2. Read in the list of contacts from native sims

    1. For each line, remove the distance

        1. If the current $i-$j contact is the same as the i-j contact from the previous line (or if the previous line is empty [when reading the beginning of this file]), save the $i-$j distance to a temporary location (id’ed by “$i-$j”).

        2. If the current $i-$j contact is not the same as the previous $i-$j contact, save this current contact, then look at all of the contacts id’ed by the previous $i-$j pair. This should contains all the distances of all $i-$j contacts. To this collections of distances, find the following statistical quantities: mean (average) distance, total number of distances, standard deviation, mean distance + 2 standard dev, and percentage (total number of distances divided by total number of frames in all native sims). If this percentage is larger than a set cut-off, print these quantities to output.

### `3-find-native-contacts-from-native-sims-add-2nd-structure.pl`

#### Input
- secondary structures key file
- contacts from native sims with statistics (output of 01.b.v3)

#### Output

Same as input but with 2nd structure info

#### Algorithm

1. Read in secondary structure file and save its content to memory.
2. Read in the output from 01.b.v3 and add on secondary structure info for each line based on $i-$j atom pair.


### `4-summarize-all-contact-data.pl`

#### Input

- a file with $i-$j contact, mean distance, mean + 2 * std dev, & structure info (output of 01.c)
- Concatenated file
- $P = 25
- $distance = 4.5
- $distanceNC = 6.0

#### Output

- categorized contacts for all sim & time frames
- list of native contacts
- list of excluded contacts

#### Algorithm

1. Read the file with summarized info of contacts from native sims.

    1. save $i-$j pair, percentage, mean distance, mean + 2*stddev, and 2nd structures.

    2. if the appearance percentage of a contact is smaller $P OR the distance is bigger than (>) $distanceNC (6.0) , save that contact to an excluded list

    3. else, consider that contact native

2. Read concatenated contacts file, for all contacts of a given timestamp:

    1. if a $i-$j distance smaller than $distance (4.5), and if $i-$j pair is on the native list (and not on excluded list), and if  $i-$j distance is smaller than mean distance + 2 stddev (from native sims contacts list), count the number of NC (S1, S2, L1, L2, T)

    2. else, consider that contact non native

#### Additional Information
Logic behind summarizing all data's native contact information (implemented in the original "03" script written by A. Radcliff and K. Nguyen)

1. Initializes all variables

2. Reads in native contacts data from 01.c output
	- in tandem: fills in hashmap for all {i,j} pairs
	- define if on excluded or native contact lists (comparing to $P)

3. Reads in `all_contact_P$proj` data file
	- checks the timestamp and extracts P/R/C/T
	- foreach contact
		- check distance and compares to $D = [mean + 2SD]
		- (in each frame) assigning 2'/3' structure
		- output line states contact status

4. Every time a new timestamp is found
	- print previous frame info
