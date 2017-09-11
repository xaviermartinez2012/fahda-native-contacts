#!/usr/bin/perl
######################################################################################################################
########                   find_native_sims.pl   For identifing Native RNA simulations                      ##########
########                             Written by: Amethyst Radcliffe
######################################################################################################################
$input2 = "/home/server/FAHdata/PKNOT/NativeCont-Analysis/findingnativesim/1796_1798_all-luteo-data.log";
$output = "/home/server/FAHdata/PKNOT/NativeCont-Analysis/findingnativesim/newluteo.cutoff3.75.native.sims.txt";
$output2 = "/home/server/FAHdata/PKNOT/NativeCont-Analysis/findingnativesim/newluteo.cutoff4.25.native.sims.txt";

######### Reading in Data all at once for analysis
open DATA2, $input2 or die "Unable to open the input file... Check location of input2.";
open OUT, ">>$output" or die "Unable to open the output1 file... Check the location of output.";
open OUT2, ">>$output2" or die "Unable to open the output2 file... Check the location of output.";

while ($line2 = <DATA2>)
{
	chomp ($line2);    ### ..cut off any extra newlines
	                   ##... and for each line, it cuts out the spaces and splits the numbers into an array
	foreach ($line2) { s/^\s+//; s/\s+$//; s/\s+/ /g;}
	@num2 = split(/ /,$line2);
	$num = [@num2];    ### Then takes each array created in the loop and pushes it into another array
	push @data, $num;
}
close(DATA2);


##########  Setting Limits
$totrow = scalar(@data);
$totfields = scalar(@num2);
$clock = 0; # counts number of lines in input file


########## Setting up Do Loop for iterative analysis of simulation sets
for ($j=0; $j<$totrow;$j++)
{

	do {  # for every simulation set... per clone
		$time = $data[$j][3];	                         # set values
		$clone = $data[$j][2];
		
		if ($time > 0.0) 
		{   
			$rmsd = $data[$j][4];  # checking for native state under 4
			if ($rmsd <= 3.750) 
			{ 
				$count  = "yes"; 
				push @totaltime, $time;
				push @resp, $count;
			}
			else { $count = "no"; push @resp, $count; }  # Keeping count of native states...... for later
		}
		
		if ($time > 0.0) 
		{   
		$rmsd = $data[$j][4];  # checking for native state under 4.5
			if ($rmsd <= 4.250) { $count2  = "yes";
				  push @totaltime2, $time;
				  push @resp2, $count2;}
			else { $count2 = "no"; push @resp2, $count2;}  # Keeping count of native states...... for later
		}
		
		$j++; # making sure it passes through all the time points in a clone
	} until ($data[$j][2] != $clone);    # termination condition for do loop

	##########   Summing up the times
	$clock++;
	$j = $j - 1;
	$shouldWePrint = "yes";
	$shouldWePrint2 = "yes";

	$timeindex1 = scalar(@totaltime);
	$timeindex2 = scalar(@totaltime2);

	####### Now Checking to see if entire simulation is native by using the counts
	$totresp = scalar(@resp);
	$totresp2 = scalar(@resp2);

	############# cutoff 4
	for ($c = 0; $c < $totresp; $c++)
	{
		if ($resp[$c] eq "no" ) 
		{ 
			$shouldWePrint = "no"; 
			last; 
		}  # checks if there is a no
	}
	
	if ($shouldWePrint eq "yes")
	{  # prints out run and clone if all frames in simulation were native
		print OUT "$data[$j][0]	  $data[$j][1]   $data[$j][2]	$data[$j][3]\n";
	}
	
	########## cutoff 4.5
	for ($n=0;$n<$totresp2;$n++){
		if ($resp2[$n] eq "no" ) { $shouldWePrint2 = "no";  last;}  #checks if there is a no
		else {	
			$shouldWePrint2 = "yes";        # Initializes print to yes;
		}

	}
	if ($shouldWePrint2 eq "yes") { print OUT2 "$data[$j][0]   $data[$j][1]   $data[$j][2]	 $data[$j][3]\n"; }  # prints out run and clone if all frames in simulation were native
	
	########## cutoff 4.5
	@resp = "";
	@resp2 = "";
	@totaltime = "";
	@totaltime2 = "";
}

close(OUT);
close(OUT2);
print "ALl done....... ~,~  \*sigh\* ..... That was a hard one. Total simulations are $clock\n";