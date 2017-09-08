#! /usr/bin/perl
##########################################################################
##########   Create all properly titled F@H PDB's from logfile	##########
##########     This #2 script is meant to fill in blanks	##########
##########	when the first script fails to make pdbs	##########
##########        	Written By:  Sorin 08/2013	        ##########
##########################################################################


########## global variables ####################
$pdbmax = 100000000;
$maxpdb = 0;
$numpdb = 0;
$currentpdbs = 0;
$numlines = 0;
$oldrun = -1;
$oldclone = -1;

$usage="\nUsage: \.\/make_FAH-PDBs_from_logfile.pl  \[Project \#\]  \[Max PDB's (optional)\]
Run this script in the location of the F\@H PROJ\$X directories ...
And don't forget the good old usegromacs33 before running this script\!\n\n";
$proj   = $ARGV[0] || die "$usage\n";
chomp $proj;
$maxpdb = $ARGV[1]; 
if($maxpdb > 0){ $pdbmax = $maxpdb; }
$outfile = "make_FAH-PDBs_"."$proj".".log2";
open(OUT,">$outfile");


##########   read in the logfile and go to the P/R/C directory   ######### 
$homedir = `pwd`; chomp $homedir;
$checkfile = "check_FAH-PDBs_"."$proj".".log";
$logfile = "/home/server/FAHdata/PKNOT/$checkfile";
open(LOG,"$logfile") || die "Can't open $logfile\n\n";

while((defined($line = <LOG>))&&($numpdb <= $pdbmax)) {
	$numlines++;
	chomp $line;
	$origline = $line;	
     	for($line){ s/^\s+//; s/\s+$//; s/\s+/ /g; }
     	@input = split(/ /,$line); 
	$test = @input[1]; chomp $test;	
	if($test eq "created") {
		print OUT "$line\n";	
	}else{
	     	$loginfo = @input[0];
		@rcfinfo = split(/\_/,$loginfo);
		$run   = $rcfinfo[1]; for($run){  s/r//; }; chomp $run;
		$clone = $rcfinfo[2]; for($clone){  s/c//; }; chomp $run;
		$frame = $rcfinfo[3]; for($frame){  s/f//; s/\.pdb//;}; chomp $run;
	 	$time  = 100 * $frame;; 		   	# this is the time in ps
		# print STDOUT "@rcfinfo\n\n$run\n\n$clone\n\n$frame\n\n";


		##########     change directory only if the current     #########
		##########  run or clone # has chenged in the log file  ######### 
		if(($run != $oldrun)||($clone != $oldclone)){
			# print OUT "$proj $run $clone\t$currentpdbs created\n";
			$currentpdbs = 0;
			$workdir = "$homedir/PROJ$proj/RUN$run/CLONE$clone/";	
			chdir $workdir;
	        	$test = `pwd`; chomp $test;
			# print OUT "Working on directory $test ...\n";
			# `rm *.pdb *# 2> /dev/null`;
		}		

		##########    now make the PDB files!!!     #########
		$xtcfile = "P$proj"."_R$run"."_C$clone".".xtc";
		$pdbfile = "p$proj"."_r$run"."_c$clone"."_f$frame".".pdb";
		if(-e $xtcfile){
			$command = "echo 1 1 | trjconv -s frame0.tpr -f $xtcfile -dump $time -o $pdbfile";
			`$command 2> /dev/null`;
			if(-e $pdbfile){ 
				$numpdb++; 
				$currentpdbs++;
				print OUT "$pdbfile CREATED ... $origline\n";
			}else{ 
				print OUT "FAILED to create new pdb file $pdbfile\n";
			}
		}	
		$oldclone = $clone;
		$oldrun   = $run;
	}
}
close(LOG);
close(OUT);


