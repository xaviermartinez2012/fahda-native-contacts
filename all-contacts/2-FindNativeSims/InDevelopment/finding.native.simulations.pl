#!/usr/bin/perl -w  
######################################################################################################################
########                   find_native_sims.pl   For identifing Native RNA simulations                      ############
########                             Written by: Amethyst Radcliffe
######################################################################################################################
$input = "/home/server/FAHdata/PKNOT/1-NativeContacts/2-FindNativeSims/1796_1798_all-luteo-data.log";
######### Initializing variables
@num=();
@data=();
$rmsd=0;
$time=0;
$run=0;
$clone=0;
$lastclone = 0;
$BREAKPOINT = 3.750;
$output = "/home/server/FAHdata/PKNOT/1-NativeContacts/2-FindNativeSims/luteo.cutoff$BREAKPOINT".".native.sims.txt";

$line;
$last = 0;
$point = 0;
$shouldWePrint = 0;
$areWeGood = 0;
######### Reading in Data all at once for analysis ###############
open DATA, "<$input" or die "Unable to open the input file... Check location of input2.";
open OUT,">>$output" or die "Unable to open the output1 file... Check the location of output.";
while ($line = <DATA>) {  ### For each line, it will...
    chomp ($line);    ### ..cut off any extra newlines
                        ##... and for each line, it cuts out the spaces and splits the numbers into an array
    foreach ($line) { s/^\s+//; s/\s+$//; s/\s+/ /g;}
    @num = split(/ /,$line);
    ####### setting variables
    $time = $num[3];
    $clone = $num[2];
    $run = $num[1];
    $rmsd = $num[4];
    ### Making sure it is within RUN0 ONLY!!
    if ($run == 0 && $time > 0.0) {
        ### Making sure we are only looking within one simulation at a time AND no simulation has passed the breaking point yet
        if ($clone == $lastclone  && $areWeGood == 0){
            if ($rmsd > $BREAKPOINT){
                $areWeGood = 1;
            }
            elsif ($rmsd <= $BREAKPOINT){
                $point = [@num];
                push (@data, $point);
		$last = scalar(@data);
		#print "adding point to data set...... $last\n";
            }
        }
        #####  Checking and accounting for simulation change
        if ($clone == ($lastclone+1)){
            $areWeGood = 0;
            $shouldWePrint = 1;
            $lastclone++;
            if ($rmsd > $BREAKPOINT){
                $areWeGood = 1;
            }
        }
        #####  Printing and clearing all working varables and arrays
        if ($shouldWePrint == 1 && $areWeGood == 0){
            $last = scalar[@data];
            $last--;
	    $proj = $data[$last][0]; $run = $data[$last][1]; $clone = $data[$last][2]; $time = $data[$last][3];    
            print OUT "$proj"."   $run"."   $clone"."   $time   \n";
            print "$proj"."   $run"."   $clone"."   $time   \n";
            @data=();
            if ($rmsd <= $BREAKPOINT && $areWeGood == 0){
                $point = [@num];
                push (@data, $point);
            }
            $shouldWePrint=0;
        }
    }
}
close(DATA);
close(OUT);
print "All done ^__^ \n";
