#!/usr/bin/perl
##########################################################################
## Goal: This script is used for generate pdb from empty pdb files list  #
## Scripter: Phuc La
#input file sample
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN10/CLONE61/p1796_r10_c61_f0.pdb does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN11/CLONE109/p1796_r11_c109_f0.pdb does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN15/CLONE57/p1796_r15_c57_f0.pdb does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN16/CLONE137/p1796_r16_c137_f0.pdb does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN16/CLONE42/p1796_r16_c42_f0.pdb does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN17/CLONE193/p1796_r17_c193_f0.pdb does not exist ...							 #
##########################################################################

$MissingPdbList="/home/server/FAHdata/PKNOT/1796.log";

#xtc file, tpr file variable
$DELTA_RESIDUES=4;
$MAX_DISTANCE=6;

#variable for run, clone has empty pdf files

#read ZERO files
open(pdbList,'<',$MissingPdbList)|| die "No pdb file";
while($line=<pdbList>)
{
   chomp($line);
   foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
   my @lines = split(' ',$line);
   $firstIndex=index($lines[3],'p179');
   $secondIndex=index($lines[3],'_f');
   $curDir = substr($lines[3],0, $firstIndex);
   $fileName = substr($lines[3],$firstIndex, $secondIndex - $firstIndex);   
   generateFramesPdb($curDir,$fileName);
   
   #this part help to know how many pdf files were generated
   $filepath = $curDir.'*.pdb';
   $filecount = `ls $filepath | wc| awk '{print \$1}'`;
   $lastpdbfile = int($filecount)-1;
   #determine the last frames.
   
   $frame=0;
   for($i=0;$i<=$lastpdbfile;$i++)
   {
      $pdb = $curDir.$fileName.'_f'.$i.'.pdb';
      $con =  $curDir.$fileName.'_f'.$i.'.con'; 
      if (-e $pdb) 
      {
         unless (-e $con)
         {
            find_native_contacts($pdb,$con,$DELTA_RESIDUES,$MAX_DISTANCE);
         }
      }
      else
      {
         print STDOUT "Non-pdb $pdb\n";
      }
      
   }
}	
#close Reading ZERO Files
close(pdbList)||die $!;


sub generateFramesPdb
{
   my ($curDir,$fileName)=@_;
   $xtcFileName = uc($fileName); 
   $xtcFile = $curDir.$xtcFileName.'.xtc';
   $tprFile = $curDir.'frame0.tpr';
   print "$curDir \n $xtcFile\n $tprFile\n";
   #remove all previous pdb files in clone folder  
   system("rm $curDir\*.pdb");
   #template for pdb filename
   $pdbFile = $curDir.$fileName.'_f';
   
   #generate all pdf files that have duplicates pdb files.
   $trjCommand = "echo 1 | trjconv -f $xtcFile -s $tprFile -sep -o ".$pdbFile.'.pdb 2> /dev/null';
   system("$trjCommand");

   #this part help to know how many pdf files were generated
   $filepath = $curDir.'*.pdb';
   $filecount = `ls $filepath | wc| awk '{print \$1}'`;
   $lastpdbfile = int($filecount)-1;

   #determine the last frames.
   $frame=0;
   for($i=0;$i<=$lastpdbfile;$i++)
   {   
      open(pdbIn,'<',$pdbFile.'_'.$i.'.pdb')|| die "No pdb file";
      while($tmpline=<pdbIn>)
      {
         chomp($tmpline);
         foreach($tmpline) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
         my @tmplines = split(' ',$tmpline);
         if ($tmplines[2] eq "t=")
         { 
            $frame=int($tmplines[3])/100; # time in frame unit
            break;
         }
      }	
      close(pdbIn)||die $!;
      #change the name pdb file match with timestamp in the file
      $mvCommand="mv -f ".$pdbFile.'_'.$i.".pdb ".$pdbFile.$frame.".pdb";
      system("$mvCommand");
   }
}

sub find_native_contacts {
   my($pdbFile,$conFile,$DELTA_RES,$MAX_DIST)=@_;
 
    system("rm $conFile");

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
   open(W,'>',$conFile) || die "Please give me output filename $!";
   for ($i=0;$i<$totalRows;$i++) {
      for ($j=$i+1;$j<$totalRows;$j++) {
         $deltaRes = abs($data[$j][4]-$data[$i][4]);
	 # delta residues >=3 ... No: now we use only > and start at 4, so it's >= 5 now
         if($deltaRes > $DELTA_RES) {  
            $deltaX=$data[$j][5]-$data[$i][5];
            $deltaY=$data[$j][6]-$data[$i][6];
            $deltaZ=$data[$j][7]-$data[$i][7];
            $distance = sqrt(($deltaX*$deltaX) + ($deltaY*$deltaY) + ($deltaZ*$deltaZ));
	    # only keep it if it's < the desired cutoff ... default at 6.0 A
            if($distance <= $MAX_DIST) {
               print W $data[$i][1]."\t".$data[$i][2]."\t".$data[$i][3]."\t".$data[$i][4]."\t\t";
               print W $data[$j][1]."\t".$data[$j][2]."\t".$data[$j][3]."\t".$data[$j][4]."\t\t".$deltaRes."\t";
	       printf W "%7.3f\n",$distance;
            }
         }
      }
   }
   close(W) || die $!;
}
print "Job is done\n";
