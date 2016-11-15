#!/usr/bin/perl

$usage        = "\nUsage: $0  [input file]  [output file]  [NC length]\n";
#read the AquifexNativeContacts List to prepare for comparing later;
$WORK_DIR     = "/home/server/FAHdata/PKNOT/";
$inputFile    = $WORK_DIR."NativeCont-Analysis/".$ARGV[0] || die "$usage";
$outputFile   = $WORK_DIR."NativeCont-Analysis/".$ARGV[1] || die "$usage";
$nativeLength = 1.00 * $ARGV[2] || die "$usage";


# ================= IMPORTING NATIVE SIM CONTACTS INFO =========================
	my @nativeList  = (); # save the whole content of native list
	my @jump        = ();
	my $atomNo      = 0;
	my $count       = 0;
	my $currentline = 0;

	open NCList, '<', $inputFile;
	while ($line1 = <NCList>)
	{
		chomp($line1);
		foreach($line1) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
		my @temp1 = split(' ', $line1);
		
		push(@nativeList, \@temp1);

		if (int($temp1[0]) > int($atomNo))
		{
			my @marker = ($atomNo, $count, $currentline); # push(@jump, \@marker);
			push(@jump, \@marker);
			$atomNo = $temp1[0];
			$count  = 1;
		}
		
		elsif (int($temp1[0]) == int($atomNo))
		{ $count++; }
	   
		$currentline++;
		print $jump[1][0]."\t".$jump[1][1]."\t".$jump[1][2]."\n"; # why print this one?
	}
	close(NCList);


# ============= global variables ===============================================
my($proj, $run, $clone, $runcount, $clonecount, $totalFrames, $filecount, $natFile, $time);

open (OUT, '>', $outputFile);

for ($p = 1796; $p < 1799; $p += 2)
{
	$runpath = $WORK_DIR."PROJ".$p."\/RUN"."\*\/";
	$runcount = `ls -d $runpath | wc | awk '{print $1}'`;
	chomp $runcount;

	for ($r = 0; $r < int($runcount); $r++)
	{
		$clonepath  = $WORK_DIR."PROJ".$p."\/RUN".$r."\/CLONE"."\*\/";
		$clonecount = `ls -d $clonepath | wc | awk '{print $1}'`;
		chomp $clonecount;

		for ($c = 0; $c < int($clonecount); $c++)
		{
			$proj    = $p;
			$run     = $r;
			$clone   = $c;
			$natFile = $WORK_DIR."PROJ$proj/RUN$run/CLONE$clone/frame_0.nat6";
			
			if (-e $natFile)
			{
				$filepath  = $WORK_DIR."PROJ$proj/RUN$run/CLONE$clone\/frame_\*.pdb";
				$filecount = `ls $filepath | wc | awk '{print $1}'`;
				chomp $filecount;

				for ($f = 0; $f < int($filecount); $f++)
				{
					$time = $f;
					$natFile = $WORK_DIR."PROJ$proj/RUN$run/CLONE$clone/frame_".$f.".nat6";
					compare_native_contacts($natFile);
					$totalFrames++;
				}
			}
		} # END OF CLONE LOOP
	} # END OF RUN LOOP
} # END OF PROJECT LOOP
close(OUT);
print "Thank for your waiting.";


# ==============================================================================
sub compare_native_contacts
{
	my $file = $_[0];
	my $S1   = 0;
	my $S2   = 0;
	my $L1   = 0;
	my $L2   = 0;
	my $T    = 0;
	my $Non  = 0;
	my $found;
	my($start,$end);

	open(Nat, '<', $natFile) || die "Please give me input filename $!";
	while ($line2 = <Nat>)
	{
		$found = 0;
		chomp($line2);
		foreach($line2) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
		my @temp2 = split(' ', $line2);

		if (int($temp2[9] * 1000) <= int($nativeLength * 1000))
		{
			# From above:
			# my @marker = ($atomNo, $count, $currentline); 
			# push(@jump, \@marker);
			for ($j = 1; $j < scalar(@jump); $j++)
			{
				if (int($temp2[0]) == int($jump[$j][0])) 
				{
					$start = $jump[$j][2] - $jump[$j][1];
					$end   = $jump[$j][2];
					print $start."\t".$end."\n";
					last;
				}
			}
			
			for ($i = $start; $i < $end; $i++)
			{
 				if
 				(
 					(int($temp2[0]) == int($nativeList[$i][0])) and 
 					(int($temp2[4]) == int($nativeList[$i][4]))
 				)
				{
					if ($nativeList[$i][12] eq "S1")
					{
						$S1++;
						$found = 1;
						last;
			   		} 
			   		
			   		elsif ($nativeList[$i][12] eq "S2") 
			   		{
						$S2++;
						$found = 1;
						last;
			   		} 

			   		elsif ($nativeList[$i][12] eq "L1") 
			   		{
						$L1++;
						$found = 1;
						last;
					} 

					elsif ($nativeList[$i][12] eq "L2") 
					{
						$L2++;
						$found = 1;
						last;
					}

					elsif($nativeList[$i][12] eq "T") 
					{
						$T++;
						$found = 1;
						last;
					}
				}
			}
		
			if ($found == 0)
			{  $Non++;  }
		}
	}
	
	close(Nat) || die $!;
	$totalNC = $S1 + $S2 + $L1 + $L2 + $T;
	printf OUT "%5d\t%5d\t%5d\t%5d\t", $proj, $run, $clone, $time * 100;
	printf OUT "%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\n",
				$S1, $S2, $L1, $L2, $T, $totalNC, $Non;
	print $natFile."\n";
}