#! /usr/bin/perl
# edited by EJS on 8/5/2013 
# edited on 9/9/13 to remove concatenating of .con files functionality


#######  GLOBALS
$MAX_DIS   = 7.0; # 7.0 A or less atomic seperations will be recorded
$DELTA_RES = 2;	# this means Delta(res) = res(j) - res(i) >= 3, must have 2 or more residues between
my($proj, $run, $clone, $runcount, $clonecount, $totalFrames, $filecount, $pdbFile);
$work = `pwd`; chomp $work;
print STDOUT "$work\n";

$usage="\nUsage: \.\/00.a.luteo.create_con-EJS.pl  \[ PROJ \]  \[ max atomic distance (7.0 A)\]  \[ min residue seperation (2 res) \] \>\& stderr.log \&
\n   Current version prints out individual con files but DOES NOT concatenate them into a single contacts-log file,\n   which is done by the next script 00.b.luteo.concat_con-EJS.pl 
\n";
$proj            = $ARGV[0] || die "$usage\n";
$p 		 = $proj;
$MAX_DISTANCE    = $ARGV[1] || die "$usage\n";
$DELTA_RESIDUES  = $ARGV[2] || die "$usage\n";	
$date = `date`; chomp $date;
$pwd = `pwd`; chomp $pwd;
$projectlog = "$pwd"."\/contact-data-P$proj"."_$MAX_DISTANCE"."Ang_$DELTA_RESIDUES"."res.txt";
# `rm $projectlog`; 
# `touch $projectlog`;
print STDOUT "Just getting started at $date\n";


##########  Now go to work creating nat6 (.con) files ..
do {
   $runpath = $work."/PROJ".$proj."\/RUN"."\*\/";
   $runcount = `ls -d $runpath | wc | awk '{print \$1}'`;
   chomp $runcount;
   # print STDOUT "$runpath	$runcount\n";

   for ($r=0;$r<int($runcount);$r++) {
      $clonepath = $work."/PROJ".$p."\/RUN".$r."\/CLONE"."\*\/";
      $clonecount = `ls -d $clonepath | wc | awk '{print \$1}'`;
      chomp($clonecount);
      # print STDOUT "$clonepath	$clonecount\n";

      for ($c=0;$c<int($clonecount);$c++) {
         $proj=$p;
         $run=$r;
         $clone=$c;
         $filepath = $work."/PROJ".$p."\/RUN".$r."\/CLONE".$c."\/p$proj"."\*.pdb";
         $filecount = `ls $filepath | wc| awk '{print \$1}'`;
         chomp $filecount;
	 # print STDOUT "$filepath 	$filecount\n";

         for ($f=0;$f<int($filecount);$f++) {
	    $pdbname = "p$proj"."_r$run"."_c$clone"."_f$f".".pdb";
	    $conname = "p$proj"."_r$run"."_c$clone"."_f$f".".con";
            $pdbFile=$work."/PROJ$proj/RUN$run/CLONE$clone/$pdbname";
            $natFile=$work."/PROJ$proj/RUN$run/CLONE$clone/$conname";  # now we'll call them *con files, for "contacts"
	    # print STDOUT "$pdbname      $conname      \n$pdbFile     \n$natFile\n\n";

	    if(-e $pdbFile){
                $size = `wc $pdbFile`; chomp $size;
                for($size){  s/^\s+//; s/\s+$//; s/\s+/ /g; }
                @sizearray = split(/ /,$size);
                $pdbsize = @sizearray[0];
		if($pdbsize > 0){   
			find_native_contacts($pdbFile);  
		}else{
			print STDOUT "ERROR: pdb file $pdbFile is zero-sized ...\n";
		}  
	    }else{
		print STDOUT "ERROR: pdb file $pdbFile does not exist ...\n";
	    }	
#            if(-e $natFile) { 
#		$totalFrames++; 
#		`echo $conname >> $projectlog`;
#		`less $natFile >> $projectlog`;
	    }
         }
      }
   }
#}
;

$date = `date`; 
chomp $date ;
print STDOUT "Total Frames = $totalFrames ... ";
print STDOUT "Done at $date\n\n";


# find native contacts with condition delta residue >=4 and distant between two atoms <=3.0
# No, this code is finding ALL contacts, not just native contacts ... that's why it's now called a *.con file
sub find_native_contacts {
   $pdbFile=pop(@_);
   # help to keep track the processing in stderr.log
   print STDOUT $pdbFile."\n"; 	
   my @data;
   my $totalRows;
   open(PDB,'<',$pdbFile)|| die $!;
   while($pdbline=<PDB>){
      chomp($pdbline);
      foreach($pdbline) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
      my @pdbTemp=split(' ',$pdbline);
      if ($pdbTemp[0] eq "ATOM") {   #condition for reading atoms in pdb file
         push(@data,\@pdbTemp);
         $totalRows++;
      }
   }
   close(PDB)|| die $!;   

   #compare distance between two atoms
   open(W,'>',$natFile) || die "Please give me output filename $!";
   for ($i=0;$i<$totalRows;$i++) {
      for ($j=$i+1;$j<$totalRows;$j++) {
         $deltaRes = abs($data[$j][4]-$data[$i][4]);
	 # delta residues >=3 ... No: now we use only > and start at 4, so it's >= 5 now
         if($deltaRes > $DELTA_RESIDUES) {  
            $deltaX=$data[$j][5]-$data[$i][5];
            $deltaY=$data[$j][6]-$data[$i][6];
            $deltaZ=$data[$j][7]-$data[$i][7];
            $distance = sqrt(($deltaX*$deltaX) + ($deltaY*$deltaY) + ($deltaZ*$deltaZ));
	    # only keep it if it's < the desired cutoff ... default at 6.0 A
            if($distance <= $MAX_DISTANCE) {
               print W $data[$i][1]."\t".$data[$i][2]."\t".$data[$i][3]."\t".$data[$i][4]."\t\t";
               print W $data[$j][1]."\t".$data[$j][2]."\t".$data[$j][3]."\t".$data[$j][4]."\t\t".$deltaRes."\t";
	       printf W "%7.3f\n",$distance;
            }
         }
      }
   }
   close(W) || die $!;
}

