#!/usr/bin/perl -w

$usage        = "perlname.pl  output_filename.txt  <the native bond distance>";
$outFile      = $ARGV[0] || die "$usage";
$nativeLength = 1.00 * $ARGV[1] || die "$usage";

my($tmpFile);
@native_sims = ();
$totalFrames = 0;
$WORK_DIR    = "/home/server/FAHdata/PKNOT/";

open (Read,'<', $WORK_DIR."NativeCont-Analysis/luteo.cutoff3.5.native.sims.txt") || die "No native simes file";

## SAVING NATIVE CONTACT FILES TO MEMORY
while ($line = <Read>)
{
   chomp($line);
   foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
   my @temp=split(' ', $line);
   push (@native_sims, \@temp); 
}
close(Read)||die $!;

## FOR EACH NATIVE SIM
for($row = 0; $row < scalar(@native_sims); $row++)
{
	$proj    = $native_sims[$row][0];
	$run     = $native_sims[$row][1];
	$clone   = $native_sims[$row][2];
	$time    = int($native_sims[$row][3]/100); # gives number of frame should be present for a simulation (clone)
	$natFile = $WORK_DIR."PROJ$proj/RUN$run/CLONE$clone/frame_0.nat6";

	if (-e $natFile)
	{
		for ($f = 1; $f <= $time; $f++)
		{
			$natFile = $WORK_DIR."PROJ$proj/RUN$run/CLONE$clone/frame_".$f.".nat6";
			$tmpFile = $natFile.".tmp";
		
			open(tmpIn, '<', $natFile) || die "No native simes file";
			open(tmpOut,'>', $tmpFile) || die "No native simes file";
			$count = 0;

			while($tmpline = <tmpIn>) # read in native contact file .nat6
			{
				$natline = $tmpline;
				chomp($tmpline);
				foreach($tmpline) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
				my @tmplines = split(' ',$tmpline);
				
				if (int($tmplines[9] * 1000) <= int($nativeLength * 1000))
				{
				   print tmpOut $natline;
				   $count++;
				}
			}
		
			close(tmpIn)  || die $!;
			close(tmpOut) || die $!;

			if ($count > 0)
			{
				system("cat $tmpFile >> $outFile");
				$totalFrames++;
				print $natFile."\n";
			}
			system("rm $tmpFile");
		} # END OF for ($f = 1; $f <= $time; $f++)
	} # END OF if (-e $natFile)
}


open (W,'>>',$outFile) || die "$usage";
print W "\nTotal Frames: ".$totalFrames;
close (W) || die $!;