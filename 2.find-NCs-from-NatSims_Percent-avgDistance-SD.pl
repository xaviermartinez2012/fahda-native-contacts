#!/usr/bin/perl
use POSIX qw/strftime/;
use Statistics::Descriptive;
use FileHandle;
STDOUT->autoflush(1); # flush anything in buffer to output to avoid delayed outputing

# ==============================================================================
#   KHAI K.Q. NGUYEN
#   California State University, Long Beach
#   Biochemistry, 2014
# ==============================================================================


 
# ==============================================================================
# SCRIPT INFO
	$scriptInfo = 
	"This script calculates the percent a native contact appears and its average distance.\n
	./01.b-find-NCs-from-NatSims.pl [0] [1] [2]\n
	Option     Filename       Type           Description\n
	----------------------------------------------------------------------------\n
	0.         contacts.txt   Input          List of contacts from native simulations\n
	1.         natsims.txt    Input          List of native simulations, used to find the number of frames\n 
											   (contains project, run, clone, time)\n
	2.         output.txt     Output         Textfile ______________\n
	\n
	Run the script with \"h\" or\"help\" argument to display this message.\n";

	$usage = "\$perl script.pl [nat-sims-contacts]  [native-sims-list]  [output]\n";


# ==============================================================================
# GET VALUES FROM USER INPUT
	$contactsList = $ARGV[0] or die "$usage\n";
	$nativeSims   = $ARGV[1] or die "$usage\n";
	$outputFile   = $ARGV[2] or die "$usage\n";

	if (($ARGV[0] eq "h") or ($ARGV[0] eq "help")) { print $usage; exit(); }

	# Print input arguments & start time
	print "$0 "; foreach my $item (@ARGV) { print "$item "; } print "\n";
	$timeStart = strftime('%Y-%m-%d-%H-%M-%S', localtime);
	print "Script starts at: $timeStart.\n";


# ==============================================================================
# CALCULATING THE NUMBER OF FRAMES
	open (NATSIMS, "<$nativeSims");

	print "Calculating the total number of frames...\n";
	# Get the last column only because it contains simulation time from all simulations.
	@totalTime = ();
	while (my $line = <NATSIMS>) 
	{
		chomp($line);
		if ($line =~ m/#/) { next; } # skip comments
		foreach ($line) { s/^\s+//; s/\s+$//; s/\s+/ /g;}
		my @splitLine = split(/\s+/,$line);
		push (@totalTime, @splitLine[scalar(@splitLine)-1]);
	}

	# Caculate total simulation time...
	$totalTime = 0;
	foreach my $item (@totalTime) 
	{
		$totalTime = $totalTime + $item;
	}

	# Each frame is recorded every 100ps. We don't take into account the frame0 for each simulation.
	# So the number of frames = (total sim time)/100
	$numFrames = ($totalTime/100);
	print "Number of frames is $numFrames\n";

	close NATSIMS;


# =======================================================================================
# COUNTING NUMBER OF INSTANCES A CONTACT APPEARS
	$prevLine = "";
	$line     = "";
	# the above two variables are always conjecutive lines from the input (native sims contacts list)

	$count       = 0;
	$percent     = 0;
	$meanDist    = 0;
	$std         = 0;
	$meanDist2SD = 0;

	# Get current time to be used as prefix for temporary files which store distance(s) for an atoms pair
	$currentTime   = strftime('%Y-%m-%d-%H-%M-%S',localtime);
	$fileTimeStamp = "$currentTime"."-01b-temp-";
	print "The prefixed \"$fileTimeStamp\" will be used for temparory files.\n";

	open (CON,    "<$contactsList")  or die ("Could not open native simulations contacts file.\n");
	open (OUTPUT, ">$outputFile")   or die ("Could not write to output file.\n");

	while ($line = <CON>) 
	{
		chomp ($line);
		$distance = substr($line,-5); # extract the distance
		$line =~ s/.....$//; ### remove the distance--which is 5-character long--at the end of a line

		if ($prevLine eq "")  #(1) # $prevLine is an empty string ONLY at the beginning of the loop
		{
			print "reading the first line...\n\n";
			$prevLine = $line;
			
			#writing the distance to a temp file
			$file = "$fileTimeStamp"."$line".".txt";
			open (DISTANCE, ">>$file");
			print DISTANCE "$distance\n";
			close DISTANCE;
			next; 
		}             

		elsif ($line eq $prevLine)  #(2)  # if $prevLine is not a null string, then...
		{
			$file = "$fileTimeStamp"."$line".".txt";
			open (DISTANCE, ">>$file");
			print DISTANCE "$distance\n";
			close DISTANCE;
			next;
		}

		elsif ($line ne $prevLine)  # if $line isn't idential to $prevLine
		{
			$file = "$fileTimeStamp"."$line".".txt";
			open (DISTANCE, ">>$file");
			print DISTANCE "$distance\n";
			close DISTANCE;

			# count the number of distances per unique contact and get descriptive stat
			
			$file = "$fileTimeStamp"."$prevLine".".txt";
			open (DISTANCE, "<$file");
			my @distanceArray = ();
			while (my $di = <DISTANCE>) { chomp($di);  push(@distanceArray,$di); }
			close DISTANCE;

			my $stat     = Statistics::Descriptive::Full -> new();
			$stat -> add_data(@distanceArray);
			$meanDist    = $stat -> mean();
			$count       = $stat -> count();
			$std         = $stat -> standard_deviation();
			$meanDist2SD = $meanDist + 2 * $std;
			$percent     = ($count/$numFrames) * 100;

			if ($percent < $P)  # if the percentage is smaller than the cut-off $P (user-input)...
			{
				$prevLine = $line;
				next;
			}

			else 
			{
				print "Writing to output file...\n\n";
				$printLine = $prevLine;
				$printLine =~ s/\s+/\t/g;
				printf OUTPUT "$printLine"."%6.3f\t%6.3f\t%6.10f\t%6.10f\n", $percent, $meanDist, $std, $meanDist2SD;

				$prevLine = $line;
				next;
			}
		} #end of the last 'elsif'
	} #end of 'while' loop

	# Write the last contact...
	# Why: The last set of identical lines will not be written because of condition (2)

	$file = "$fileTimeStamp"."$prevLine".".txt";
	open (DISTANCE, "<$file");
	my @distanceArray = ();
	while (my $di = <DISTANCE>) { chomp($di);  push(@distanceArray,$di); }
	close DISTANCE;

	my $stat     = Statistics::Descriptive::Full -> new();
	$stat -> add_data(@distanceArray);
	$meanDist    = $stat -> mean();
	$count       = $stat -> count();
	$std         = $stat -> standard_deviation();
	$meanDist2SD = $meanDist + 2 * $std;
	$percent     = ($count/$numFrames) * 100;

	print "Writing to output file...\n\n";
	$printLine = $prevLine;
	$printLine =~ s/\s+/\t/g;
	printf OUTPUT "$printLine"."%6.3f\t%6.3f\t%6.10f\t%6.10f\n", $percent, $meanDist, $std, $meanDist2SD;

	close OUTPUT;
	close CON;


# =======================================================================================
# MOVING TEMP FILES TO A TEMP DIRECTORY TO BE DELETED LATER BY USER
	@tempFiles = `tree -Li 1 | grep $currentTime`;
	$tempDir = "$currentTime-01b-temp-files";
	`mkdir $tempDir`;

	print "Moving temporary files to a $tempDir...\n";
	foreach $item (@tempFiles) {
		chomp $item;
		`mv \"$item\" $tempDir\/`;
	}
	print "All temporary files have been moved to ./$tempDir.\n";
	print "The output file is $outputFile.\n";
# =======================================================================================

$timeEnd = strftime('%Y-%m-%d-%H-%M-%S',localtime);
print "Script ends at $timeEnd\n";