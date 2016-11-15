#!/usr/bin/perl -w
use POSIX qw/strftime/;
use FileHandle;
STDOUT->autoflush(1); # flush anything in buffer to output to avoid delayed outputing

# ==============================================================================
#  Summing up categorized native contacts for entire project per time stamp    
#  By: Arad & Khai 1/13/14
# ==============================================================================


# ============== INPUT =========================================================
	$usage = 
	"$0 [project] [nat-con-file] [all-contact-file] [percent] [distance] [distanceNC] 
	[output-file] [exclude-list-output-file] [native-contacts-list-output-file]\n";
	
	$proj            = $ARGV[0] || die "$usage\n";
	$ncFile          = $ARGV[1] || die "$usage\n";
	$allConFile      = $ARGV[2] || die "$usage\n";
	$cutOffPercent   = $ARGV[3] || die "$usage\n";
	$distance        = $ARGV[4] || die "$usage\n";
	$distanceNC      = $ARGV[5] || die "$usage\n";
	$outputFile      = $ARGV[6] || die "$usage\n";
	$excludeListFile = $ARGV[7] || die "$usage\n";
	$nativeConList   = $ARGV[8] || die "$usage\n";

	# print entered command with arguments used and start time
	print "$0 ";   foreach my $item (@ARGV) {print "$item ";}   print "\n";
	$timeStart = strftime('%Y-%m-%d-%H-%M-%S',localtime);
	print "Script starts at: $timeStart.\n";



# ==============================================================================
# INITIALIZE HASH TABLES
	# number of atoms there are for the molecule, must be changed for every new molecule
	$numAtom       = 839; 
	for($i = 1; $i < $numAtom; $i++)
	{
		for ($j = 1; $j < $numAtom ; $j++)
		{
			$nativeSim{"$i:$j"} = 0;
			$meanDista{"$i:$j"} = 0;
			$mean2SDev{"$i:$j"} = 0;
			$percent{"$i:$j"}   = 0;
			$secStruc{"$i:$j"}  = "";
			$exlu{"$i:$j"}      = 0;
		}
	}



# ==============================================================================
# OPENING AND STORING NATIVE SIMULATIONS CONTACTS INFO INTO HASH TABLES FOR LATER COMPARISON
	open (outNAT, ">$nativeConList")   || die "Could not generate native contacts list.\n";
	open (outEXL, ">$excludeListFile") || die "Could not generate excluded contacts list.\n";
	open (inNCLIST, "<$ncFile")       || die "Could not open the native contact file correctly.\n";
	
	#$line1         = 0;	
	#@line1         = ();
	$nativeAtom1   = 0;
	$nativeAtom2   = 0;
	while (my $line = <inNCLIST>) 
	{
		# chomp($line1);
		# removes white spaces beginning and end of a line,
		# replaces any white space between words by a single white space.
		foreach($line) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
		@line1       = split(/ /, $line1);
		
		$nativeAtom1 = $line1[0];
		$nativeAtom2 = $line1[4];

		$nativeSim{"$nativeAtom1:$nativeAtom2"} = 1;
		$percent{"$nativeAtom1:$nativeAtom2"}   = $line1[9];   #= $ncPercent;
		$meanDista{"$nativeAtom1:$nativeAtom2"} = $line1[10];  #= $ncMeanDist;
		$mean2SDev{"$nativeAtom1:$nativeAtom2"} = $line1[12];  #= $mean2SD;
		$secStruc{"$nativeAtom1:$nativeAtom2"}  = $line1[13];  #= $secStru;

		###### Printing out exluded contacts for reference
		# if the percent is small, print line to exclusion list
		if (($line1[9] < $cutOffPercent) or ($line1[12] > $distanceNC)) 
		{
			$exlu{"$nativeAtom1:$nativeAtom2"} = 1;
			print outEXL "$line1\n";
		}
		else
		{
			print outNAT "$line1\n";
		}
	} # end of `while` loop

	close(inNCLIST);
	close(outNAT);
	close(outEXL);


# ==============================================================================
# OPENING OUTPUT FILE
	open(OUT,   ">$outputFile") || die "Could not open output file correctly. $!\n";
	open(inCON,"<$allConFile") || die "Could not open all contact file correctly. $!\n";

	$count         = 0;
	#$line2         = 0;
	#@line2         = ();
	@line2Char     = ();
	$run           = 0;
	$lastRun       = 0;
	$clone         = 0;
	$lastClone     = 0;
	$time          = 0;
	$lastTime      = 0;
	$shouldWePrint = 0;
	$prevClone     = 0;
	$dist          = 0; # distance variable

	# number of secondary structures (i.e. how many contacts in stem 1, stem 2, loop 1, loop 2)
	$s1            = 0;
	$s2            = 0;
	$l1            = 0;
	$l2            = 0;
	$t             = 0;

	$totNC         = 0;
	$nonNC         = 0;


# ==============================================================================
# EXTRACTING INFORMATION ABOUT PROJ, RUN, CLONE, AND TIME
	while (my $line = <inCON>)
	{
		chomp($line);
		foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
		my @line2  = split(/ /, $line);

		# split line into characters in order to detect c3eyhange in frame
		@line2Char = split(//, $line); 
		$charIndex = scalar(@line2Char); # number of characters in line
		
		if ($line2Char[0] eq "p")
		{
			if ($count > 1)
			{
				$shouldWePrint = 1;
				$lastRun       = $run;
				$lastClone     = $clone;
				$lastTime      = $time;
			}

			# No need to extract project number because it is input by user.
			# An example of timestamp in all-contact-data file: p1796_r0_c0_f0.con

			# extract run number
			$run = "$line2Char[7]";
			for ($j = 8; $j < $charIndex; $j++)
			{
				if ($line2Char[$j] eq "_")
				{
					$cstart = $j + 2; # position for clone number, see next code block below
					last;
				}
				else
				{ $run = "$run"."$line2Char[$j]"; }
			}

			# extract clone number
			$clone = "$line2Char[$cstart]";
			$cstart++;
			for ($j = $cstart; $j < $charIndex; $j++)
			{
				if ($line2Char[$j] eq "_")
				{
					$fstart = $j+2;   # position for frame/time number, see next code block below
					last;
				}
				else 
				{ $clone = "$clone"."$line2Char[$j]"; }
			}

			# extract frame number
			$time = "$line2Char[$fstart]";
			$fstart++;
			for ($j = $fstart;$j < $charIndex;$j++)
			{
				if ($line2Char[$j] eq ".")
				{
					last;
				}
				$time = "$time"."$line2Char[$j]";
			}

			# frame number time 100 to get time in picoseconds
			$time = $time * 100;

			if ($clone != $prevClone)
			{
				print "$proj $run $prevClone\n";
				$prevClone = $clone;
			}
		} # end of `if ($line2Char[0] eq "p"){`


# ==============================================================================
# STARTING TO EVALUATE CONTACTS
	$numColumn = scalar(@line2);

	if ($numColumn == 10) # to check if the input concatenated all-contact data file is valid
	{
		$atom1 = $line2[0];
		$atom2 = $line2[4];
		$dist  = $line2[9];

		##### Checkng and tabulating contact information for each simulation
		if ($dist <= $distance) 
		{
			# if the atoms pair is on native list but not on exclusion list
			if ($nativeSim{"$atom1:$atom2"} == 1 && $exlu{"$atom1:$atom2"} == 0)
			{
				if ($dist <= $mean2SDev{"$atom1:$atom2"})
				{
					if ($secStruc{"$atom1:$atom2"}    eq "S1"){   $s1++;   }
					elsif ($secStruc{"$atom1:$atom2"} eq "S2"){   $s2++;   }
					elsif ($secStruc{"$atom1:$atom2"} eq "L1"){   $l1++;   }
					elsif ($secStruc{"$atom1:$atom2"} eq "L2"){   $l2++;   }
					elsif ($secStruc{"$atom1:$atom2"} eq "T" ){   $t++;    }
				}
			}
			elsif ($nativeSim{"$atom1:$atom2"} == 0 and $exlu{"$atom1:$atom2"} == 0)
			{
				$nonNC++;
			}
		}
	}

	####  Printing to output file
	if ($shouldWePrint==1)
	{
		$totNC = $s1 + $s2 + $l1 + $l2 + $t;
		printf OUT "%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\n", 
		$proj, $lastRun, $lastClone, $lastTime, $s1, $s2, $l1, $l2, $t, $totNC, $nonNC;

		# reseting counters for next time frame
		$s1 = 0; $s2 = 0; $l1 = 0; $l2 = 0; $t = 0; $totNC = 0; $nonNC = 0; 
		$shouldWePrint = 0;
	}
	$count++;
} # end of `while` loop

$lastTime = $lastTime + 100;
$totNC = $s1 + $s2 + $l1 + $l2 + $t;
printf OUT "%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\n", 
       $proj, $lastRun, $lastClone, $lastTime, $s1, $s2, $l1, $l2, $t, $totNC, $nonNC;

close(OUT);
close(inCON);

$timeEnd = strftime('%Y-%m-%d-%H-%M-%S',localtime);
print "Script ends at $timeEnd\n";