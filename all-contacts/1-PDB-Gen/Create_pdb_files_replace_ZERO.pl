#!/usr/bin/perl
##########################################################################
## Goal: This script is used for generate pdb from empty pdb files list  #
## Scripter: Phuc La							 #
##########################################################################

$dataDir='/home/server/FAHdata/PKNOT/';
$zeroPdbList="/home/server/FAHdata/PKNOT/check_FAH-PDBs_1799.ZERO";
$proj=1799;
print "Project : $proj with $zeroPdbList\n";

#xtc file, tpr file variable
my ($xtcFile,$tprFile);

#variable for run, clone has empty pdf files
my ($run,$rIndex, $clone,$cIndex,$fIndex, $curDir);

#read ZERO files
open(pdbList,'<',$zeroPdbList)|| die "No pdb file";
while($line=<pdbList>)
{
   chomp($line);
   foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
   my @lines = split(' ',$line);
   $rIndex=index($lines[0],'_r');
   $cIndex=index($lines[0],'_c');
   $fIndex=index($lines[0],'_f');
   if(substr($lines[0],$cIndex + 2, $fIndex - $cIndex - 2) ne $clone)   
   {
      $run = substr($lines[0],$rIndex + 2, $cIndex - $rIndex -2);   
      $clone= substr($lines[0],$cIndex + 2, $fIndex - $cIndex - 2);
      $curDir = $dataDir."PROJ".$proj.'/RUN'.$run.'/CLONE'.$clone.'/';
      $xtcFile = $curDir."P".$proj.'_R'.$run.'_C'.$clone.'.xtc';
      $tprFile = $curDir.'frame0.tpr';
      print "\nProject $proj Run $run Clone $clone\n";
      removePdbDuplicate();
      checkPdbSize();
   }
}	
#close Reading ZERO Files
close(pdbList)||die $!;


sub removePdbDuplicate
{
   chdir $curDir;
   #remove all previous pdb files in clone folder  
   system('rm *.pdb');
   system('rm *.con');
   system('rm \#*');
   chdir $dataDir;

   #template for pdb filename
   $pdbFile = $curDir.'p'.$proj.'_r'.$run.'_c'.$clone.'_f';
   
   #generate all pdf files that have duplicates pdb files.
   $trjCommand = "echo 1 | trjconv -f $xtcFile -s $tprFile -sep -o ".$curDir."frame.pdb 2> /dev/null";
   system("$trjCommand");

   #this part help to know how many pdf files were generated
   $filepath = $curDir.'*.pdb';
   $filecount = `ls $filepath | wc| awk '{print $1}'`;
   foreach ($filecount) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
   @lsResult =split(' ',$filecount);
   $lastpdbfile = int($lsResult[0])-1;
   print "Number of pdb files generated $lastpdbfile\n";
   
   #determine the last frames.
   $frame=0;
   for($i=0;$i<=$lastpdbfile;$i++)
   {   
      open(pdbIn,'<',$curDir.'frame_'.$i.'.pdb')|| die "No pdb file";
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
      $mvCommand='mv -f '.$curDir.'frame_'.$i.'.pdb '.$pdbFile.$frame.'.pdb';
      system("$mvCommand");  
    }
}

sub checkPdbSize
{
   #this part help to know how many actual pdb files
   $filepath = $curDir.'*.pdb';
   $filecount = `ls $filepath | wc| awk '{print $1}'`;
   foreach ($filecount) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
   @lsResult =split(' ',$filecount);
   $lastpdbfile = int($lsResult[0])-1;
   print "Number of actual pdb files generated $lastpdbfile\n\n";

   #determine the last frames.
   for($i=0;$i<=$lastpdbfile;$i++)
   {
      #check file size
      $wcResult=`wc $pdbFile$frame.pdb`; chomp $wcResult;
      foreach ($wcResult) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
      my @size=split(' ', $wcResult);
      if ($size[0] == 0 ) { print "Frame: $i with size: ZERO\n"; }
   }
}
print "Job is done\n";
