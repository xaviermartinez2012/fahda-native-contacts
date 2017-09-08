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

$usage="\nUsage: \.\/check_FAH-PDBs_from_logfile.pl  \[Project \#\]  \[Max PDB's (optional)\]
Run this script in the location of the F\@H PROJ\$X directories ...
After running, grep resulting log file for WRONG, ZERO, and NOT to look for bad/missing PDB's\n\n";

$proj   = $ARGV[0] || die "$usage\n";
chomp $proj;
$maxpdb = $ARGV[1]; 
if($maxpdb > 0){ $pdbmax = $maxpdb; }
$outfile = "check_FAH-PDBs_"."$proj".".log";
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
	########## look for wrong time stamps and zero filesize ##########
	$pdbfile = "p$proj"."_r$run"."_c$clone"."_f$frame".".pdb";
	$numpdb++;
	if(-e $pdbfile){
		$size = `wc $pdbfile`; chomp $size;
		for($size){  s/^\s+//; s/\s+$//; s/\s+/ /g; }
		@sizearray = split(/ /,$size);
		$pdbsize = @sizearray[0];
		if($pdbsize == 0){
			print OUT "$pdbfile of ZERO size ($numpdb) ... ";
		}	
		$timeline = `head $pdbfile | grep TITLE`;
		chomp $timeline;
		for($timeline){ s/^\s+//; s/\s+$//; s/\s+/ /g; }
		@timetest = split(/ /,$line); 
		$pdbtime  = @timetest[3];
		if($pdbtime == $time){
			print OUT "$pdbfile created successfully ($numpdb)\n";
		}else{
			print OUT "$pdbfile WRONG TIME ($numpdb)\n";
		}
	}else{
		print OUT "$pdbfile NOT CREATED ($numpdb)\n";
	}
	$oldclone = $clone;
	$oldrun   = $run;
}

close(LOG);
close(OUT);



