#!/usr/bin/perl -w
##################################################################################################
#
#  Categorizing all native contacts into s1 s2 l1 l2 or T contacts         By: Arad  10/7/13
#
##################################################################################################
$usage = "perl perlname.pl input_filename lower-case-project-name <percentage>";
$inFile = $ARGV[0] || die "$usage\n";
$proj = $ARGV[1] || die "$usage\n";
$cutOffP = 1.000 * $ARGV[2] || die "$usage\n";
#$cutOffD = 1.000 * $ARGV[3] || die "$usage\n";

$outFile = "$proj".".categorized-native-contacts.txt";

# Sort the file by atom number 
# system("sort -nk1 -nk5 $inFile -o $tempFile");

# Read the Native Contacts List to prepare for comparing later
@nativeKey = (); 
$newLine=0;
$line1=0; $line2=0;
@temp1=(); $temp2=();
$tempr=0;
@nativeContacts;


###  Reading in the structure key for the project 
open(KEY,"<structure_$proj".".key") || die "Don't have key file.\n";
while ($line1 = <KEY>) {
	chomp($line1);
	foreach($line1) { s/^\s+//;s/\s+$//; s/\s+/ /g; }  # should there be a loop here?
	@temp1 = split(/ /,$line1);
	$tempr = [@temp1];
	push (@nativeKey,$tempr);
	@temp1=();
}
close(KEY) || die "Couldn't close the structure key file...\n";

$keyIndex = scalar(@nativeKey);

### Checking to make sure there is a structure file
if ($keyIndex == 0){
	print "FATAL ERROR: Did not read in the sturcture key correctly.\n
               Check file information to verify the title is correct.\n";
	exit();	
}

###  Starting the process of reading in contacts
open(NC,  "<$inFile")   || die "Could not open the input: $inFile\n"; 
# read in the native sim contacts list w/ percentage

open(OUT, ">>$outFile") || die "Could not open the output: $outFile\n";
# output the contacts with the same info with addition of categories at the end

while($line2 = <NC>){
	chomp($line2);
	$originalLine = $line2;
	foreach($line2) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
	@temp2=split(/ /,$line2);
	for ($i=0;$i<$keyIndex;$i++){
	        if ($temp2[9] >= $cutOffP){
        	    if ( ($temp2[3] == $nativeKey[$i][1]) && ($temp2[7] == $nativeKey[$i][2]) ) {
                	$newLine = "$originalLine"." $nativeKey[$i][0]";
                	print OUT "$newLine\n";
                	last;
            	    }
		    elsif(($temp2[3] == $nativeKey[$i][2])&&($temp2[7] == $nativeKey[$i][1])){
                	$newLine = "$originalLine"." $nativeKey[$i][0]";
                	print OUT "$newLine\n";
                	last;
            	    }
            	    else{
                	$newLine =  "$originalLine"." T";
                	print OUT "$newLine\n";
                	last;
            	    }
        	}
		elsif ($temp2<$cutOffP){
			$newLine =  "$originalLine"." NonNC";
			print OUT "$newLine\n";
			last;
		}
	}	
	@temp2=();
}

close(NC)  || die $!;
close(OUT) || die $!;
