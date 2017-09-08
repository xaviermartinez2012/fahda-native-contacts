#! /usr/bin/perl
$findpair = "/home/server/X3DNA/bin/find_pair";
$fix3dna  = "/home/server/FAHdata/PKNOT-DATA/old.PKNOT.analysis/scripts/fix_3DNA_output.pl";

########## global variables ####################
$usage="\nUsage: \.\/Analaysis_PKNOT\.pl \[Project\] \[\# of Runs\] \[\# of Clones\] [Output File]\n\n";
$proj     = $ARGV[0] || die "$usage\n";
$maxrun   = $ARGV[1] || die "$usage\n";
$maxclone = $ARGV[2] || die "$usage\n";
$outfile  = $ARGV[3] || die "$usage\n";

if($proj==1798){ 
  $ndxfile = "/home/server/FAHdata/PKNOT-DATA/old.PKONT.analysis/2A43_luteo.ndx"; 
  $tprfile = "/home/server/FAHdata/PKNOT-DATA/PROJ1798/RUN0/CLONE0/frame0.tpr";
  $natbpfile = "/home/server/FAHdata/PKNOT-DATA/old.PKNOT.analysis/carolyn_native_base_pairs_luteo";
}
if($proj==1799){ 
  $ndxfile = "/home/server/FAHdata/PKNOT-DATA/old.PKNOT.analysis/2G1W_aquifex.ndx"; 
  $tprfile = "/home/server/FAHdata/PKNOT-DATA/PROJ1799/RUN0/CLONE0/frame0.tpr";
  $natbpfile = "/home/server/FAHdata/PKNOT-DATA/old.PKNOT.analysis/carolyn_native_base_pairs_aqui";
}

open (OUT, ">$outfile") or die "Can't open $outfile\n";


############ iterate through max run & max clone ##########################
$currentrun = 0;

while($currentrun < $maxrun){
  $currentclone = 0;
  while($currentclone < $maxclone){
  
	# define the work directory and go there #
	# then concatenate xtc files into one single trajectory file #
	$workdir = "/home/server/FAHdata/PKNOT-DATA/PROJ$proj/RUN$currentrun/CLONE$currentclone/";
	chdir $workdir;
	$numxtcfiles = `ls \*xtc | wc | awk '{print $1}'`;

	@xtcfiles = ();
        if($numxtcfiles > 0){
	    for($i=0;$i<$numxtcfiles;$i++){
	       $xtc = "frame$i".".xtc";	
	       if($i==0){
		  push (@xtcfiles, $xtc);
	       }else{ 
		  $newxtc = "new$i".".xtc";
		  $starttime = $i * 1000;	
		  `trjconv -f $xtc -t0 $starttime -o $newxtc >& /dev/null`;
                  push (@xtcfiles, $newxtc); 
	       }  	
            }	
	    $outxtc = "p$proj"."r$currentclone"."c$currentclone".".xtc";
	    `trjcat -o $outxtc -f @xtcfiles >& /dev/null`;


	############## calculate desired quantities ################
	   system("echo 1 1 | g_rms -s $tprfile -f $outxtc -n $ndxfile >& /dev/null");	
   
	   # make pdb's at all times and run 3DNA on them #
	   `echo 0 | trjconv -f $outxtc -s 'frame0.tpr' -sep -o 'frame.pdb' >& /dev/null`;	
	   $totaltime = `tail -1 rmsd.xvg | awk '{print $1}'`;		   
	   $numframes = $totaltime / 100;

	   `rm 3dnaout.txt`;
	   for($i=0;$i<=$numframes;$i++){
	   	 $currentpdb = "frame_"."$i".".pdb";
		 $threednaout = "pdbout_"."$i"; 
		 # print STDOUT "find_pair -z -p $currentpdb $threednaout\n";
		 `$findpair -z -p $currentpdb $threednaout >& /dev/null`;
		 `$fix3dna $threednaout $natbpfile >> 3dnaout.txt`; 
	   }






	   open (DNA, "<3dnaout.txt") or die "Can't open 3dnaout.txt\n";
		$time = 0;
                while ($line = <RMS>){
                     chomp ($line);
                     $data{$time}  = $line;
		     $time += 100;
                }
           close (DNA);





	############### print out data ####################
	   for($i=0;$i<=$numberframes;$i++){
		 $timepoint = 100 * $i;

 		print OUT "$data{$timepoint}\n";
 	   }    
############### remove all excess files ##############
#	`rm p*xtc new*xtc $outxtc *.xvg frame*pdb pdbout* tmp_* mref* ref_* mul* all* >& /dev/null`;
        }
    $currentclone++;
  }
$currentrun++;
}

close(OUT);

