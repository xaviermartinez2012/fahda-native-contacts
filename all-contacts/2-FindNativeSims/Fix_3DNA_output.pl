#!/usr/bin/perl

$usage="\nUsage: \.\/fix_3DNA_output\.pl  \[3DNA Output File\]  \[Native BPs File\]\n\n";
$infile  = $ARGV[0] || die "$usage\n";
$bpfile  = $ARGV[1] || die "$usage\n";

########### read in native bp info ############
for($i=0;$i<100;$i++){
  for($i=0;$i<100;$i++){
    $nativebps{$i,$j} = 0; 
  }
}

open (BPF, "<$bpfile") or die "Can't open $bpfile\n";
while(defined($line = <BPF>)){
   chomp ($line);
   for($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
   @linein = split(/ /,$line);
   $a = $linein[0];
   $b = $linein[1];
   $nativebps{$a,$b} = 1;
   # print STDOUT "$a \t $b \t $nativebps{$a,$b} \n\n\n";
}
close(BPF);


########### prep the temp files ################
$filesize = `less $infile | wc | awk '{print \$1}'`;
$filesize -= 23;
`tail -$filesize $infile > temp`;
$filesize2 = `grep -n Detail temp`;
@filesz = split(/\:/, $filesize2);
$filesize3 = @filesz[0];
$filesize3 -= 2;
`head -$filesize3 temp > temp2`;


########### count the number of HBonds in all ##############
$numbp = `less temp2 | wc | awk '{print \$1}'`;
$numbp /= 6;


########### sort through each hbond and info ##############
$numhb = 0;
$numbps = 0;
$basepairs = "";
$bpsnat = 0;
$bpsnon = 0;
$hbsnat = 0;
$hbsnon = 0;

open (TMP, "<temp2") or die "Can't open temp2\n";
       for($i=1;$i<=$numbp;$i++){
	    $line = <TMP>;
            chomp ($line);
            foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
            @linein = split(/ /,$line);
	    $resa = $linein[2];            
	    $resb = $linein[3];
	    # print STDOUT "$resa $resb $nativebps{$resa,$resb}\n";
	    $resdiff = $resb - $resa;
	    # print STDOUT "$i resdiff = $resdiff\n\n";
	    if($resdiff > 1){
               $basepairs = "$basepairs"."$resa"."-$resb"."_";
	       $numbps++;	
	       <TMP>;
	       $line = <TMP>;
               chomp ($line);
               for($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
               @linein = split(/ /,$line);
	       $hbs = @linein[1];
	       for($hbs){ s/\]//g; s/\[//g; }	 
	       $numhb += $hbs;

               if($nativebps{$resa,$resb} > 0){
	         # print STDOUT "i=$i a=$resa b=$resb nat=$nativebps{$resa,$resb}\n";
		 $bpsnat++;
		 $hbsnat+=$hbs;
	       }else{
	         # print STDOUT "i=$i a=$resa b=$resb not=$nativebps{$resa,$resb}\n";
		 $bpsnon++;
		 $hbsnon+=$hbs;
               }


	    }else{
	      <TMP>;
	      <TMP>;
	    }
	    <TMP>;
	    <TMP>;
	    <TMP>;
       }
close (TMP);
`rm temp temp2`;

printf STDOUT "%7d %7d %7d %7d %7d %7d     ",$numbps,$bpsnat,$bpsnon,$numhb,$hbsnat,$hbsnon,$basepairs;
print STDOUT "$basepairs\n";


