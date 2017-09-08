#! /usr/bin/perl
####################################################################################
############ Check that all F@H PDB's from logfile were properly created ###########
##########	        	Written By:  Sorin 08/2013	         ###########
####################################################################################


########## global variables ####################
$pdbmax = 100000000;
$maxpdb = 0;
$numpdb = 0;
$currentpdbs = 0;
$numlines = 0;
$oldrun = -1;
$oldclone = -1;

$usage="\nUsage: \.\/check_FAH_CON-files.pl  \[Project \#\]  \[Max PDB's (optional)\]
Run this script in the location of the F\@H PROJ\$X directories ...
After running, grep resulting log file for NOT to look for missing .con files\n\n";

$proj   = $ARGV[0] || die "$usage\n";
chomp $proj;
$maxpdb = $ARGV[1]; 
if($maxpdb > 0){ $pdbmax = $maxpdb; }
$outfile = "check_FAH_CON-files_"."$proj".".log";
open(OUT,">$outfile");


##########   read in the logfile and go to the P/R/C directory   ######### 
$homedir = `pwd`;
chomp $homedir;
$logfile = "/home/server/FAHdata/PKNOT/log$proj";
open(LOG,"$logfile") || die "Can't open $logfile\n\n";
while((defined($line = <LOG>))&&($numpdb <= $pdbmax)) {
	$numlines++;
     	for($line){ s/^\s+//; s/\s+$//; s/\s+/ /g; }
     	@input = split(/ /,$line); 
     	$logproj  = $input[0];
	if($logproj != $proj){ die "PROJ $logproj found is not the same a PROJ $proj expected\!"; }
	$run   = $input[1];
	$clone = $input[2];
 	$time  = $input[3];   	# this is the time in ps
	$frame = $time / 100;
		
	##########     change directory only if the current     #########
	##########  run or clone # has chenged in the log file  ######### 
	if(($run != $oldrun)||($clone != $oldclone)){
		$currentpdbs = 0;
		$workdir = "$homedir/PROJ$proj/RUN$run/CLONE$clone/";	
		chdir $workdir;
	}

	##########	Check for correctly written PDB file	##########
	$confile = "p$proj"."_r$run"."_c$clone"."_f$frame".".con";
	$numpdb++;
	if(-e $confile){
		$test = `wc $confile`;
		chomp $test;
		for($test){ s/^\s+//; s/\s+$//; s/\s+/ /g; }
		@testarray = split(/ /,$test); 
		$wc  = @testarray[0];
		if($wc > 0){
		}else{
			print OUT "$confile does NOT have any data ...\n";
		}
	}else{
		print OUT "$confile does NOT exist!\n";
	}
	$oldclone = $clone;
	$oldrun   = $run;
}

close(LOG);
close(OUT);



