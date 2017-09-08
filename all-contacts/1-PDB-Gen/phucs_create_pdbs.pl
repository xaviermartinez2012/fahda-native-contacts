#!/usr/bin/perl
## This script is used for generating pdb file a specific time#

$chdir='/home/la/Desktop/testing/';
#xtc file
$outxtc=$chdir."P1796_R0_C78.xtc";
#tpr file
$tprfile=$chdir."frame0.tpr";

chdir $chdir;
#remove all pdb file in the location
system('rm *.pdb');


#generate all pdf files includes duplicates pdb files.
system("echo 1 | trjconv -f $outxtc -s $tprfile -sep -o frame.pdb");

#this part help to know how many pdf files were generated
$filepath = $chdir."frame\*.pdb";
$filecount = `ls $filepath | wc| awk '{print $1}'`;
$lastpdbfile=int($filecount)-1;

#determine the last frames.
$frame=0;
for($i=0;$i<=$lastpdbfile;$i++)
{   
   open(pdbIn,'<',$chdir."frame".$i.'.pdb')|| die "No pdb file";
   while($line=<pdbIn>)
   {
      chomp($line);
      foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
      my @lines = split(' ',$line);
      if ($lines[2] eq "t=")
      { 
         $frame=int($lines[3])/100;#time in frame unit
         break;
      }
   }	
   close(pdbIn)||die $!;
   $mvCommand="mv -f ".$chdir."frame".$i.".pdb ".$chdir."frame".$frame.".pdb";
   system("$mvCommand");
}


