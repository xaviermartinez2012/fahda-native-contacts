#!/usr/bin/perl
####################################################################################
## Goal: This script is used for generating missing con file from pdb files list   #
## Scripter: Phuc La							           #
####################################################################################

$dataDir='/home/server/FAHdata/PKNOT/';
$zeroConList="/home/server/FAHdata/PKNOT/check_FAH_CON-files_1799.log";
$proj=1799;

$DELTA_RESIDUES=4;
$MAX_DISTANCE=6;

#variable for run, clone has empty pdf files
my ($run,$rIndex, $clone,$cIndex,$frame,$fIndex, $curDir,$natFile, $pdbFile, $filename);

#read ZERO files
open(pdbList,'<',$zeroConList)|| die "No pdb file";
while($line=<pdbList>)
{
   chomp($line);
   foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
   my @lines = split(' ',$line);
   $rIndex=index($lines[0],'_r');
   $cIndex=index($lines[0],'_c');
   $fIndex=index($lines[0],'_f');
   $eIndex=index($lines[0],'.con');
   if(substr($lines[0],$cIndex + 2, $fIndex - $cIndex - 2) ne $clone)   
   {
      $run = substr($lines[0],$rIndex + 2, $cIndex - $rIndex -2);   
      $clone= substr($lines[0],$cIndex + 2, $fIndex - $cIndex - 2);
      $frame= substr($lines[0],$fIndex + 2, $eIndex - $fIndex - 2);
      $curDir = $dataDir."PROJ".$proj.'/RUN'.$run.'/CLONE'.$clone.'/';
      $filename = "p".$proj.'_r'.$run.'_c'.$clone.'_f'.$frame;
      $pdbFile = $curDir.$filename.'.pdb';
      $natFile = $curDir.$filename.'.con';     
#      print "$run $clone $frame\n";
      if (-e $pdbFile)
      {
         find_native_contacts($pdbFile);
         check_con_file($natFile);
      }else
      {
         print "PDB Non-Exist $filename".".pdb\n";
      }
   }
}	
#close Reading ZERO Files
close(pdbList)||die $!;


sub find_native_contacts {
   `rm $natFile`;
#   $pdbFile=pop(@_);
   # help to keep track the processing in stderr.log
#   print STDOUT $filename.".\n"; 	
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

sub check_con_file {
#   $natFile=pop(@_);
   # help to keep track the processing in stderr.log
#   print STDOUT $pdbFile."\n"; 	
   $size = `wc $natFile | awk '{print \$1}'`; chomp $size;
#   print $size."\n";
   if (-e $natFile) 
   {
      if(int($size) == 0)
      { 
         print STDOUT "Empty $filename".".con\n";
         cp_pdb_has_no_con();
      }
      else {print STDOUT "OK $filename".".con\n"; }
   } 
   else
   {
      print STDOUT "Con Non-Exist $filename".".con\n" ;
   }
}

sub cp_pdb_has_no_con {
   $mkcommand = $dataDir.'PDB_with_empty_Con_Files/';
   `mkdir $mkcommand`;
    `cp $pdbFile  $mkcommand`;
}
print "Job is done\n";
