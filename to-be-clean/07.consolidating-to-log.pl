#!/usr/bin/perl -w
##################################################################################################
#
#       Collecting all contacts from simulations that were determined to be native       By: ARAD 
#                                                                                         10/1/13
##################################################################################################
$usage = "perl perlname.pl [03 categorized data file.txt] [project log file] [project number]\n";
$catDataFile = $ARGV[0] || die "$usage\n";
$projLog = $ARGV[1] || die "$usage\n";

$TheDis = int($newDistance);
########  Setting global variables
$outFile= "all-contact-data-P$proj"."_$TheDis"."Ang_4res.txt";
@newtemp=();
$newline=0;
$distance = 0;
print "Reading in the all contacts file... \n";
#####  Setting loop variables
$printLine = 0;
$testing=0;
@testtemp=();


##### Opening output file
open (OUT, ">>$outFile") || die "Could not create the output file\n";


print "Output file was generated... now starting the examination of contacts\n";
#####  Reading in contacts filing and pulling information 
open (CONFILE, "<$allConFile") || die "Couldn't open all_contacts_file\n";
while ($newline=<CONFILE>){
	chomp($newline);
	$printLine = $newline;
	$testing= $newline;  ### For testing which simulation and frame
	foreach($newline) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
	@newtemp=split(/ /,$newline);
	$distance = $newtemp[9];
	######  For checking which Proj-Run-Clone-Frame is being examined
	foreach($testing) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
	@testtemp=split(//,$testing);
	
	#####  Firstly, it checks to see if the line should be printed
	if ($testtemp[0] eq "p"){
	print OUT "$printLine\n";
	}
	elsif ($distance <= $newDistance){
	print OUT "$printLine\n";
	}
}
close(CONFILE);
close(OUT);
