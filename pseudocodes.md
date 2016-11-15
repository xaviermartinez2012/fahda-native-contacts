# 01.a.find-NCs-from-NatSims.pl
I. INPUT: 
- file contains native simulations info (project/run/clone) and total time (ps) for each of those simulations.
- Concatenated contacts file

II. OUTPUT: Contacts from native sims only.

III. ALGORITHM
1. Read in list of native simulations (project/run/clone)
2. Read in concatenated contacts file
a. If project/run/clone in this file matches one from native simulations list, print to output all contacts info
3. Sort the output file


# 01.b.v3-find-NCs-from-NatSims_Percent-avgDistance-SD.pl
I. INPUT:
- List of contacts from native sims (output from 01.a)
- List of native sims (to obtain number of frames)

II. OUTPUT: unique contacts with percent of time this contact appears in native sims (collectively), mean distances, standard deviation, and mean + 2 SD

III. ALGORITHM
1. Read the list of native sims (proj/run/clone/total time) and import the times (in ps), sum them up then divide by 100 to get the total number of frames.
2. Read in the list of contacts from native sims
a. For each line, remove the distance
a.1 If the current $i-$j contact is the same as the i-j contact from the previous line (or if the previous line is empty [when reading the beginning of this file]), save the $i-$j distance to a temporary location (id’ed by “$i-$j”).
a.2 If the current $i-$j contact is not the same as the previous $i-$j contact, save this current contact, then look at all of the contacts id’ed by the previous $i-$j pair. This should contains all the distances of all $i-$j contacts. To this collections of distances, find the following statistical quantities: mean (average) distance, total number of distances, standard deviation, mean distance + 2 standard dev, and percentage (total number of distances divided by total number of frames in all native sims). If this percentage is larger than a set cut-off, print these quantities to output.


# 01.c.find-NCs-from-NatSims_2ndStructure.pl
I. INPUT
- secondary structures key file
- contacts from native sims with statistics (output of 01.b.v3)

II. OUTPUT: Same as input but with 2nd structure info

III. ALGORITHM
1. Read in secondary structure file and save its content to memory.
2. Read in the output from 01.b.v3 and add on secondary structure info for each line based on $i-$j atom pair.


# 03.summarize-all-contact-data.pl
I. INPUT
- a file with $i-$j contact, mean distance, mean + 2 * std dev, & structure info (output of 01.c)
- Concatenated file
- $P = 25
- $distance = 4.5
- $distanceNC = 6.0

II. OUTPUT
- categorized contacts for all sim & time frames
- list of native contacts
- list of excluded contacts

III. ALGORITHM

1. Read the file with summarized info of contacts from native sims.
a. save $i-$j pair, percentage, mean distance, mean + 2*stddev, and 2nd structures.
b. if the appearance percentage of a contact is smaller $P OR the distance is bigger than (>) $distanceNC (6.0) , save that contact to an excluded list
c. else, consider that contact native

2. Read concatenated contacts file, for all contacts of a given timestamp:
a. if a $i-$j distance smaller than $distance (4.5), and if $i-$j pair is on the native list (and not on excluded list), and if  $i-$j distance is smaller than mean distance + 2 stddev (from native sims contacts list), count the number of NC (S1, S2, L1, L2, T)
b. else, consider that contact non native