# 00.Luteo_find_native_sims.pl
0. Description: “It looks through the log file for simulations that fit the criteria and prints out P R C and the final T of each simulation that is classified as being a "Native State Simulation”
1. Input: 1796_1798_all-luteo-data.log.
2. Output: Native sim including project run clone and last time frame of native sims.
3. Algorithm

1. Import data from input in memory as a 2D matrix.
2. For any clone:
* if structures of all frames have RMSD to be smaller than a cut-off (3.75 & 4.25 were used)
** then prints out project-run-clone-time of last frame of that clone.



# 01.new.luteo.standard.NC.pl
0. Description: “Reads in list of native simulations, goes through these PROJ/RUN/CLONE directories, and uses ONLY $D distance requirement to write out list of contacts”
1. Input: 
  * Native sims list (output from 00.Luteo_find_native_sims.pl)
  * $nativeLength
  * frame_0.nat6 file for each native sim/clone
2. Output: List of native contacts
3. Algorithm
For each native simulation:
  * For each line of frame_0.nat6:
			** If the 10th column ($line[9]) is smaller or equal to $nativeLength:
				*** Write that line to output



# 02.luteo_standard_NC_with_Structures.pl
0. Description: “It looks through the standard native list and structure key to assign structure with percentage of existing.”
1. Input:
 * Contacts from native sims that have distances no more than $D (output from _01.new.luteo.standard.NC.pl_)
 * Cut-off percentage $P
 * structure_luteo.key
2. Output: ?
3. Algorithm
	1. Sort native sims contacts file by 1st then 2nd atom numbers.
	2. For each line in this sorted data, if atom numbers of current line are not equal to those of previous line:
		a. this i-j pair, and 
		b. number of rows for the __previous__ i-j pair (counts)
	3. For each of the contacts + counts saved in #2
		a. Convert the counts of i-j to percentage (by dividing it by the total number of frames)
		b. If this percentage is not smaller $P, prints out the contacts and secondary/tertiary structure



# 03. new.luteo.NC.for.All.pl
0. Description: “It looks through all data to identify which contacts in the RNA.”
1. Input: 
* Output file from _02.luteo_standard_NC_with_Structures.pl_
* $nativeLength
2. Output: ?
3. Algorithm

	1. From native contacts file
	a. Save all info to memory, and
	b. Save atom i number, all contacts to atom i, and last line in the native contacts file that have this contact from atom i

2. Look into each simulation (project-run-clone)
	a. for each .nat6 (of each frame)
- if a contact is smaller than $nativeLength
— if the contact is on native list, increase contact count by 1 (whether S1, S2, L1, L2, or T)
— if the contact is not on the native list, increase native contact count by 1
print to output file