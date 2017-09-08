#!/usr/bin/perl -w
##################################################################################################
#
#       Collecting all contacts from simulations that were determined to be native       By: ARAD 
#                                                                                         10/1/13
##################################################################################################
$usage = "\n\tperl perlname.pl native_sim_filename.txt  all_contact_filename.txt\n\n";
$natSimFile = $ARGV[0] || die "$usage";
$allConFile = $ARGV[1] || die "$usage";


########  Setting global variables
$outFile="native_simulation_contacts_".$allConFile;
@native_sims=();
@temp=();
@newtemp=();
$firsttemp=0;
$line=0;
$newline=0;

print "Reading in the native sim file... \n";
#####  Reading in file containing simulations considered native
open(NSFILE,"<$natSimFile")|| die "Couldn't open native_sims_file\n";
while($line=<NSFILE>){
	chomp($line);
	foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
	@temp=split(/ /,$line);
	$firsttemp = [@temp];           ### Storing data into a 2D array for accessment later
	push (@native_sims,$firsttemp);
	@temp = (); 
}
close(NSFILE)||die "Didn't close native_simulation_file properly... \n";
$NSindex = scalar(@native_sims);

#####  Adding a check to make sure that the native simulations data is useable
if ($NSindex == 0){
	print "FATAL ERROR: There are no native simulations being used, make sure native_sim_file exists and is not empty\n";
	exit();
}
else {
	print "\nNative sim file contained usable data... reading in contact file now\n";
 }

#####  Setting loop variables
$frame=1;
$counter=0;
$printLine = 0;
$shouldWePrint=0;
$testing=0;
@testtemp=();


##### Opening output file
open (OUT, ">>$outFile") || die "Could not create the output file\n";


print "Output file was generated... now starting the examination of contacts\n";
#####  Reading in contacts filing and pulling information 
open (CONFILE, "<$allConFile") || die "Couldn't open all_contacts_file\n";
while ($newline=<CONFILE>){
	chomp($newline);
	$printLine = $newline;
	$testing= $newline;  ### For testing which simulation and frame
	foreach($newline) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
	@newtemp=split(/ /,$newline);

	######  For checking which Proj-Run-Clone-Frame is being examined
	foreach($testing) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
	@testtemp=split(//,$testing);
	
	#####  Firstly, it checks to see if the line should be printed
	if (($shouldWePrint == 1) && ($testtemp[0] ne "p")){
	print OUT "$printLine\n";
	}

        ####  Setting which native simulation we want to pull contacts for   p$proj"."_r$run"."_c$clone"."_$f".".con"
	if (($counter < $NSindex)&&($testtemp[0] eq "p")){
		#print "	       looking at $counter position in $natSimFile \n";
		##  current native simulation 
		$simulation = "p$native_sims[$counter][0]"."_r$native_sims[$counter][1]"."_c$native_sims[$counter][2]"."_f$frame".".con";
		#print "$newtemp[0]"."      $simulation\n";

		###  Accounting for frame changes
		$nextFrame = $frame + 1;
		$nextSimulation= "p$native_sims[$counter][0]"."_r$native_sims[$counter][1]"."_c$native_sims[$counter][2]"."_f$nextFrame".".con";
		#print "$newtemp[0]"."      $nextSimulation\n";

		### Accounting for starting at a new native simulation		
		$newSim = $counter +1;
		$newSimulation="p$native_sims[$newSim][0]"."_r$native_sims[$newSim][1]"."_c$native_sims[$newSim][2]"."_f1".".con";
		#print "$newtemp[0]"."      $newSimulation\n";

		if ($newtemp[0] eq $simulation){
			$shouldWePrint = 1;
			print "Printing information for $simulation\n";
		}
		elsif ($newtemp[0] eq $nextSimulation){
			$shouldWePrint = 1;
			$frame++;
			print "Printing information for $nextSimulation\n";
		}
		elsif ($newtemp[0] eq $newSimulation){
			$shouldWePrint = 1;
			$counter++;
			$frame=2;
			print "Printing information for $newSimulation\n";
		}

		elsif (($newtemp[0] ne $simulation)&&($newtemp[0] ne $nextSimulation)&&($newtemp[0] ne $newSimulation)&&($testtemp[0] eq "p")){
			$shouldWePrint = 0;
			$frame=1;
		}
		else {
			print "FATAL ERROR: Current line is not reading as con file title or a contact\n"."Check conditions again\n";
			exit();
		}
	#exit();
	}
}
close(CONFILE);
close(OUT);

system("sort $outFile >> $outFile".".sorted.txt");


