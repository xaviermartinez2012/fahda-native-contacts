#!/usr/bin/perl
# This script to apply the con
$usage         = "Need input file";
$inFile        = $ARGV[0] || die "$usage";
$outFile       = $ARGV[1] || die "$usage";
$CutOffPercent = 1.00 *$ARGV[2] || die "$usage";
$tempFile      = "LUTEO-TEMP.txt";
$WORK_DIR      = "/home/server/FAHdata/PKNOT/";

#sort input file by atome number 
system("sort -nk1 -nk5 $inFile -o $tempFile");

#read the AquifexNativeContacts List to prepare for comparing later
	### NATIVE LIST
	my @nativeList; 
	open(R1, '<', "structure_luteo.key") || die "Don't have key file";
	while($line1=<R1>)
	{
		 chomp($line1);
		 foreach($line1) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
		 my @temp1=split(' ',$line1);
		 push(@nativeList, \@temp1);
	}
	close R1 || die $!;


	open (R, '<', $tempFile) || die "Please give me input filename $!";  
	$atomA           = "";
	$atomB           = "";
	$count           = 0;
	my $TOTAL_FRAMES = 0;
	my @nativeContacts;

	### IMPORT INFO FROM LUTEO-TEMP.txt which is the sorted $inFile
	while ($line2 = <R>)
	{
		chomp($line2);
		foreach($line2) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
		my @temp2 = split(' ', $line2);
		 
		if ($temp2[0] eq "Total")  { $TOTAL_FRAMES = $temp2[2]; }
		else
		{
			if 
			(
				(
					($atomA ne $temp2[0]) or ($atomB ne $temp2[4])
				) 
				and ($count != 0)
			)
			{
				push(@temp2, $count);
				push(@nativeContacts, \@temp2);
				$count = 0;
			}

			$atomA = $temp2[0];
			$atomB = $temp2[4];
			$count++;
		 }
	}
	close(R) || die $!;
	print "Finished Native Contacts List\n";


open (OUT, '>', $outFile) || die "Please give me output filename $!";
$percentage = 0;
$found      = 0;

for ($row = 1; $row < scalar(@nativeContacts); $row++)
{           
	$found = 0;
	$percentage = ($nativeContacts[$row][10] * 100) / ($TOTAL_FRAMES);
	
	if (int($percentage) >= $CutOffPercent)
	{
		for($col = 0; $col < 11; $col++)
		{
			if ($col == 9)
			{  printf OUT "%2.2f\t",$nativeContacts[$row][$col];  }
			else 
			{ print OUT $nativeContacts[$row][$col]."\t"; }
		}
		
		printf OUT "%2.2f",$percentage;  
		
		for ($i = 0; $i < scalar(@nativeList); $i++)
		{
			if (
					( 
						(int($nativeList[$i][1]) == int($nativeContacts[$row][3])) and
						(int($nativeList[$i][2]) == int($nativeContacts[$row][7]))
					) or
					(
						(int($nativeList[$i][1]) == int($nativeContacts[$row][7])) and  
						(int($nativeList[$i][2]) == int($nativeContacts[$row][3]))
					)
				)
			{
				print "$percentage \> $CutOffPercent\n";
				print OUT "\t".$nativeList[$i][0]."\n"; # prints out 2nd structure
				$found = 1;
				last;                                      
			}              
		}
		
		if ($found == 0) 
		{ 
			print "$percentage \> $CutOffPercent\n";
			print OUT "\tT\n";
		}
	}
}

print $CutOffPercent."\n";
close OUT || die $!;
system("rm $tempFile");
print "I am done.\n";