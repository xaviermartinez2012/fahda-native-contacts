#!/usr/bin/perl -w
##################################################################################################
#
#  Summing up categorized native contacts for entire project per time stamp    By: Arad 10/10/13
#
##################################################################################################
$usage = "\nUsage: perl aqui_optimal\.pl [project] [native contact file] [contact file] [percent] [distance] [output file]\n";

$proj = $ARGV[0] || die "$usage\n";
$ncFile = $ARGV[1] || die "$usage\n";
$allConFile = $ARGV[2] || die "$usage\n";
$cutPercent = $ARGV[3] || die "$usage\n";
$distance =$ARGV[4]|| die "$usage\n";
$outputFile = $ARGV[5] || die "$usage\n";

#######  Global variables
$line1=0; $tempn =0; @temp1=(); @nativeList=();
$ncIndex=0;
$line2=0; @temp2=(); @temptest=();
$run =0; $lastRun = 0; $clone=0; $lastClone =0; $time=0; $lastTime=0; 
$shouldWePrint=0; 
$s1=0; $s2=0; $l1=0; $l2=0; $t=0; $totNC=0; $nonNC=0;
$nativePercent=0;
$dist = 0;
$res1 = 0;
$res2 = 0;
$meanDist = 0;
$mean2SD = 0;
$nativeAtm1 = 0;
$nativeAtm2 = 0;
$diffDist =0; $secStru=0; 

for($i=1; $i<839; $i++){
	for ($j=1; $j<839; $j++){
		$nativeSim{"$i:$j"}=0;
		$meanDista{"$i:$j"}=0;
		$mean2SDev{"$i:$j"}=0;
		$percent{"$i:$j"}=0;
		$secStruc{"$i:$j"}="";
		$exlu{"$i:$j"}=0;
	}
}

######  Opening and storing native contact info for comparison later
$excludeList = "excluded-NCs-P$proj".".txt";
open (EXL, ">>$excludeList") || die "Could not generate excluded contacts list\n";

open(NCLIST, "<$ncFile")|| die "Could not open the native contact file correctly\n";
while($line1=<NCLIST>){
	chomp($line1);
	foreach($line1) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
	@temp1=split(/ /,$line1);
	$nativeAtm1 = $temp1[0];
	$nativeAtm2 = $temp1[4];
	$ncPercent = $temp1[9];
	$ncMeanDist = $temp1[10];
	$mean2SD = $temp1[12];
	$secStru = $temp1[13];
	
	$nativeSim{"$nativeAtm1:$nativeAtm2"}=1;
	$mean2SDev{"$nativeAtm1:$nativeAtm2"}=$mean2SD;
	$meanDista{"$nativeAtm1:$nativeAtm2"}=$ncMeanDist;
	$percent{"$nativeAtm1:$nativeAtm2"}=$ncPercent;
	$secStruc{"$nativeAtm1:$nativeAtm2"}=$secStru;
        ###### Printing out exluded contacts for reference
	if ($ncPercent < $cutPercent){
		$exlu{"$nativeAtm1:$nativeAtm2"}=1;
		print EXL "$line1\n";
	}
}
close(NCLIST);
close(EXL);

###### Opening output file
open(OUT,">>$outputFile")|| die "Could not open output file correctly\n";
$count =0;
#######  Beginning the process of running through contact info
open(CON,"<$allConFile") || die "Could not open all contact file correctly\n";
while($line2=<CON>){
	chomp($line2);
	foreach($line2) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
	@temp2=split(/ /,$line2);
	@temptest = split(//,$line2);
	
	#### Extracting information about proj run clone and time.
	$realIndex = scalar(@temp2);
	$TTindex = scalar(@temptest);
	if ($temptest[0] eq "p"){
		if ($count >1){ $shouldWePrint =1; $lastRun = $run; $lastClone = $clone; $lastTime = $time;}

		$run = "$temptest[7]";
		for ($j=8;$j<$TTindex;$j++){
			if ($temptest[$j] eq "_"){
				$cstart = $j+2; 
				last;
			}
			else{ $run = "$run"."$temptest[$j]"; }
		}
		$clone = "$temptest[$cstart]";
		$cstart++;
		for ($j=$cstart;$j<$TTindex;$j++){
			if ($temptest[$j] eq "_"){
				$fstart = $j+2; 
				last;
			}
			else { $clone = "$clone"."$temptest[$j]"; }
		}
		$time = "$temptest[$fstart]";
		$fstart++;
		for ($j=$fstart;$j<$TTindex;$j++){
			if ($temptest[$j] eq "."){
				last;
			}
			$time = "$time"."$temptest[$j]";
		}
		$time = $time*100;
	print "$proj $run $clone $time \n";
	}
	###### starting to evaluate contacts
	if ($realIndex == 10) {
		$atm1 = $temp2[0];
		$atm2 = $temp2[4];
    		$dist = $temp2[9];		

		##### Checkng and tabulating contact information for each simulation
		if ($dist <= $distance) {
			if ($nativeSim{"$atm1:$atm2"} == 1 && $exlu{"$atm1:$atm2"} == 0){
				$diffDist = abs($dist - $meanDista{"$atm1:$atm2"});
				if ($diffDist <= $mean2SDev{"$atm1:$atm2"}){
					if ($secStruc{"$atm1:$atm2"} eq "S1"){
						$s1++;
					}
					elsif ($secStruc{"$atm1:$atm2"} eq "S2"){
						$s2++;
					}
					elsif ($secStruc{"$atm1:$atm2"} eq "L1"){
						$l1++;
					}
					elsif ($secStruc{"$atm1:$atm2"} eq "L2"){
						$l2++;
					}
					elsif ($secStruc{"$atm1:$atm2"} eq "T"){
						$t++;
					}
				}
				else { 
					print "$line2  is NOT a contact.  Does not meet the percentage and/or standard deviation requirments\n";
				}
			}
			elsif ($nativeSim{"$atm1:$atm2"} == 0 && $exlu{"$atm1:$atm2"} == 0){
				$nonNC++;
			}
			else {
				print "$line2  is NOT a contact.  It is considered excluded because of statistical irrelevance\n";
			}
		}
		else {
			print "$line2  is NOT a contact.  Does not meet the distance requirment\n";
		}
	}
    	####  Printing to output file
	if ($shouldWePrint==1){
		#print "I am printing!!\n";
		$totNC = $s1 + $s2 + $l1 + $l2 + $t;
		printf OUT "%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\n", $proj, $lastRun, $lastClone, $lastTime, $s1, $s2, $l1, $l2, $t, $totNC, $nonNC;
		#printf "%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\n", $proj, $lastRun, $lastClone, $lastTime, $s1, $s2, $l1, $l2, $t, $totNC, $nonNC;
		$s1=0; $s2=0; $l1=0; $l2=0; $t=0; $totNC=0; $nonNC=0;
		$shouldWePrint=0;
	}
	$count++;
}
close(CON);
#print "I am printing!!\n";
$totNC = $s1 + $s2 + $l1 + $l2 + $t;
printf OUT "%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\n", $proj, $lastRun, $lastClone, $lastTime, $s1, $s2, $l1, $l2, $t, $totNC, $nonNC;
$s1=0; $s2=0; $l1=0; $l2=0; $t=0; $totNC=0; $nonNC=0;
$shouldWePrint=0;
close(OUT);

