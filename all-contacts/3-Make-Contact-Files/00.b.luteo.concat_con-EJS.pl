#! /usr/bin/perl
# edited by EJS on 8/5/2013 
# edited on 12/06/13 to shorten DeltaRes and lengthen $D


#######  GLOBALS
$MAX_DIS   = 7.0; # 7.0 A or less atomic seperations will be recorded
$DELTA_RES = 2;	# this means Delta(res) = res(j) - res(i) >= 3, must have 2 or more residues between

my($proj, $run, $clone, $runcount, $clonecount, $totalFrames,$filecount, $pdbFile);
$work = `pwd`; chomp $work;
print STDOUT "$work\n";

$usage="\nUsage: \.\/00.b.luteo.concat_con-EJS.pl  \[ PROJ \] \>\& 00.b.PROJ\$proj.log \&
\n   Current version concatenates all individual .con in F@H directories into a single all-contacts\*.log file
\n";
$proj = $ARGV[0] || die "$usage\n";
$p = $proj;
$date = `date`; chomp $date;
$pwd = `pwd`; chomp $pwd;
$projectlog = "$pwd"."\/all-contacts-P$proj"."_$MAX_DIS"."Ang_$DELTA_RES"."Res.txt";
`rm $projectlog`; 
`touch $projectlog`;
print STDOUT "Just getting started at $date\n";


##########  Now go to work creating nat6 (.con) files ..
do {
   $runpath = $work."/PROJ".$proj."\/RUN"."\*\/";
   $runcount = `ls -d $runpath | wc | awk '{print \$1}'`;
   chomp $runcount;
   # print STDOUT "$runpath	$runcount\n";

   # for each RUN, do the following ...
   for ($r=0;$r<int($runcount);$r++) {
      $clonepath = $work."/PROJ".$p."\/RUN".$r."\/CLONE"."\*\/";
      $clonecount = `ls -d $clonepath | wc | awk '{print \$1}'`;
      chomp($clonecount);
      # print STDOUT "$clonepath	$clonecount\n";

      # for each CLONE, do the following ...
      for ($c=0;$c<int($clonecount);$c++) {
         $proj=$p;
         $run=$r;
         $clone=$c;
         $filepath = $work."/PROJ".$p."\/RUN".$r."\/CLONE".$c."\/p$proj"."\*.pdb";
         $filecount = `ls $filepath | wc| awk '{print \$1}'`;
         chomp $filecount;
	 # print STDOUT "$filepath 	$filecount\n";

	 # for each PDB file, do the following ...
         for ($f=0;$f<int($filecount);$f++) {
	    $pdbname = "p$proj"."_r$run"."_c$clone"."_f$f".".pdb";
	    $conname = "p$proj"."_r$run"."_c$clone"."_f$f".".con";
            $pdbFile=$work."/PROJ$proj/RUN$run/CLONE$clone/$pdbname";
            $natFile=$work."/PROJ$proj/RUN$run/CLONE$clone/$conname";  
	    # now we call them *con files, for "contacts"
	    # print STDOUT "$pdbname      $conname      \n$pdbFile     \n$natFile\n\n";

	    if(-e $pdbFile){
                $size = `wc $pdbFile`; chomp $size;
                for($size){  s/^\s+//; s/\s+$//; s/\s+/ /g; }
                @sizearray = split(/ /,$size);
                $pdbsize = @sizearray[0];

		if(!($pdbsize > 0)){   print STDOUT "PDB-ERROR: pdb file $pdbFile is zero-sized ...\n"; }
                if(-e $natFile) { 
                	$natsize = `wc $natFile`; chomp $natsize;
                	for($natsize){  s/^\s+//; s/\s+$//; s/\s+/ /g; }
                	@natsizearray = split(/ /,$natsize);
                	$natsize = @natsizearray[0];

			if(!($natsize > 0)){ print STDOUT "CON-ERROR: con file $natFile is zero-sized ...\n";  	}
			$totalFrames++; 
			`echo $conname >> $projectlog`;
			`less $natFile >> $projectlog`;

		}else{
			print STDOUT "CON-ERROR: con file $natFile does not exist ...\n";
		}  
	    }else{
		print STDOUT "PDB-ERROR: pdb file $pdbFile does not exist ...\n";
	    }	
         }
      }
   }
};

$date = `date`; 
chomp $date ;
print STDOUT "Total Frames = $totalFrames ... ";
print STDOUT "Done at $date\n\n";
