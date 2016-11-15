#!/usr/bin/perl -w
use POSIX qw/strftime/;
use FileHandle;
STDOUT->autoflush(1); # flush anything in buffer to output to avoid delayed outputing
##################################################################################################
#
#       Collecting all contacts from simulations that were determined to be native       By: ARAD 
#                                                                                         10/1/13
##################################################################################################



# ================================================================================================
# USAGE & GETTING INPUT INFORMATION INTO APPROPRIATE VARIABLES
	$usage      = "\$perl script.pl  [native-sims-list.txt]  [all-contact-data.txt]  [output.txt]\n";
	$natSimFile = $ARGV[0] or die "$usage\n";
	$allConFile = $ARGV[1] or die "$usage\n";
	$outFile    = $ARGV[2] or die "$usage\n";
	if (($ARGV[0] eq "h") or ($ARGV[0] eq "help") or ($ARGV[0] eq "-h")) { print $usage; exit(); }
# ================================================================================================

# Print out entered command with arguments used
	print "$0 ";
	foreach my $item (@ARGV) { print "$item "; }
	print "\n";
# Time start
	$timeStart = strftime('%Y-%m-%d-%H-%M-%S',localtime);
	print "Script starts at: $timeStart.\n";

# ================================================================================================
# SETTING GLOBAL VARIABLES
	@lineInNatSims      = ();
	$referenceNatSim    = "";
	@nativeSims         = ();
	$line1              = "";
	$line2              = "";
# ================================================================================================


# ================================================================================================
# READING IN & STORING THE LIST CONTAINING NATIVE STATE SIMULATIONS
	open(NSFILE, "<$natSimFile") or die "Couldn't open $natSimFile. $!\n";
	print "Reading in the native sim file... \n";
	while($line1 = <NSFILE>){
		if ($line1 =~ m/#/) {next;} #ignore comments/header in file
		chomp($line1);
		
		# remove leading & trailing whitespace, replace any whitespace between words by a single whitespace
		foreach($line1) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
			
		# the array below should contain: (0) project, (1) run, (2) clone, (3) total time in ps
		@lineInNatSims = split(/ /,$line1);
			
		# creating reference time stamp (without frame number)
		$referenceNatSim = "p".$lineInNatSims[0]."_r".$lineInNatSims[1]."_c".$lineInNatSims[2];
			
		# storing reference data into a 1D array for accessment later
		push (@nativeSims,$referenceNatSim);
	}
	close(NSFILE) or die "Didn't close $natSimFile properly. $!\n";

	#print "Native sims:\n";
	#foreach my $item (@nativeSims) {print "$item\; ";}

	#####  Adding a check to make sure that the native simulations data is useable
	$NSindex = scalar(@nativeSims);
	if ($NSindex == 0){
		print "FATAL ERROR: There are no native simulations being used, make sure native simulation file $natSimFile exists and is not empty.\n";
		exit();
	}
	else {
		print "\nNative sim file $natSimFile contains usable data. Reading in contact file $allConFile now...\n";
	}
# ================================================================================================


# ================================================================================================
# SETTING LOOP VARIABLES
	$printLine     = 0;
	$shouldWePrint = 0;
	@ProjRunClone  = ();
	$projIndicator = ""; # to get the first letter in the time stamp (from the concatenated data file)
# ================================================================================================


# ================================================================================================
# PROCESS LINES FROM THE ALL CONTACTS DATA FILE
	open (OUT, ">>$outFile") or die "Could not create the $outFile output file. $!\n";
	print "Output file $outFile was generated. Now starting the examination of contacts.\n";
	open (CONFILE, "<$allConFile") or die "Couldn't open $allConFile. $!\n";
	print "Reading from concatenated contacts file: $allConFile.\n";
	
	LBL: while ($line2 = <CONFILE>){
		chomp($line2);
		$printLine = $line2;

		# get the first letter to check if this line is indicating a set of contacts for a new time stamp
		$projIndicator = substr($line2,0,1); 
		
		#####  Firstly, it checks to see if the line should be printed
		if (($shouldWePrint == 1) && ($projIndicator ne "p")) { print OUT "$printLine\n"; }
# ================================================================================================


# ================================================================================================
# COMPARE & PRINT NATIVE SIMS CONTACTS
	# check the current line is that of a time stamp (e.g. "p1796_r0_c0_f0.con"); 
	# it is a timestamp if the first letter of the string is "p"
		if ($projIndicator eq "p") { 
			print "Checking $line2\n"; # to display progress
			@ProjRunClone = split(/_f/,$line2); #split away frame number
			for ($i = 0; $i < $NSindex; $i++) {
				if (($ProjRunClone[0] eq $nativeSims[$i]) and ($ProjRunClone[1] ne "0.con")) { 
					$shouldWePrint = 1; 
					print "Match found: 1: $ProjRunClone[0]_f$ProjRunClone[1], 2: $nativeSims[$i]\n"; 
					next LBL;}
				else { $shouldWePrint = 0; }
			}
		}
	} # END OF `WHILE` LOOP
	close CONFILE;
	close OUT;
# ================================================================================================

print "Sorting the output $outFile...\n";
system("sort $outFile >> $outFile".".sorted.txt");
print "Finished!\n";

$timeEnd = strftime('%Y-%m-%d-%H-%M-%S',localtime);
print "Script ends at $timeEnd\n";