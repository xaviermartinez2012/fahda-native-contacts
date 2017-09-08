#! /usr/bin/perl
##################################################################
##########  remove unwanted files from F@H data sets  ############
##########        Written By:  Sorin 08/2013          ############
##################################################################

########## global variables ####################
$usage="\nUsage: \.\/clean_up_fah_data.pl \[Project \#\] \[\# of Runs\] \[\# of Clones\]
Run this script from the location of the PROJ\$X F\@H Directories to clean up ...
Currently removes all tpr's and edr's other than frame0.tpr and ener.edr\n\n";
$proj     = $ARGV[0] || die "$usage\n";
$maxrun   = $ARGV[1] || die "$usage\n";
$maxclone = $ARGV[2] || die "$usage\n";


############ iterate through max run & max clone ##########################
$currentrun = 0;
$homedir = `pwd`; chomp $homedir;
while($currentrun < $maxrun){
	$currentclone = 0;
  	while($currentclone < $maxclone){
		# define the work directory and go there  #
		# then remove the unwanted file types ... #
		$workdir = "$homedir/PROJ$proj/RUN$currentrun/CLONE$currentclone/";
		chdir $workdir;
		$test = `pwd`; chomp $test;
		print "Working on directory $test ...\n";			
		`rm *# *.xvg *.pdb *.out *.nat *.nat6 temp* 2> /dev/null`;
		`mv frame0.tpr temp`;
		`rm *.tpr 2> /dev/null`;
		`mv temp frame0.tpr`;
		`mv ener.edr temp`;
		`rm *.edr 2> /dev/null`;
		`mv temp ener.edr`;
		$currentclone++;
	}
	$currentrun++;
}
print "done! ^.^! \n";

