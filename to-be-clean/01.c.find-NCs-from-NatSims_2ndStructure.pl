#!/usr/bin/perl
use POSIX qw/strftime/;

# ========================================================================================
#   KHAI K.Q. NGUYEN
#   California State University, Long Beach
#   Biochemistry, 2014
# ========================================================================================

$timeStart = strftime('%Y-%m-%d-%H-%M-%S',localtime);
print "Script starts at: $timeStart.\n";

## =======================================================================================
## Script info
$usage = "perl perlname.pl [input-contacts]  [structures-key]  [output]\n";


## =======================================================================================
## Takes in arguments
$contactsFile     = $ARGV[0] or die "$usage\n";
$keyFile          = $ARGV[1] or die "$usage\n";
$outputFile       = $ARGV[2] or die "$usage\n";

if (($ARGV[0] eq "h") or ($ARGV[0] eq "help") or ($ARGV[0] eq "-h")) { print $usage; exit();}

print "$0 ";
foreach my $item (@ARGV) { print "$item "; }
print "\n";


## =======================================================================================
## Reading in the structure key
open(KEY,"<$keyFile") or die "Cannot open structure map file $keyFile. $!.\n";

@nativeKey = ();

while (my $line = <KEY>) {
    if ($line =~ m/#/) { next; } # skip comments in input file
    chomp($line);

    #remove whitespace from beginning, end, and replace any excess whitespace by a single space
    foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }

    push (@nativeKey,[split(/ /,$line)]); # creating 2D array, each element is a reference to a line in the key
}
close KEY or die "Couldn't close the structure key file...\n";

$keyIndex = scalar(@nativeKey);

# Check if the structure file is empty
if ($keyIndex == 0) {
    print "FATAL ERROR: Did not read in the sturcture key correctly.\n
               Check file information to verify the title is correct.\n";
    exit(); 
}


## =======================================================================================
## Starting the process of reading in contacts

open(NC,  "<$contactsFile") or die "Could not open the input $contactsFile\n";
open(OUT, ">>$outputFile")  or die "Could not open the output: $outputFile\n";
# output the contacts with the same info with addition of categories at the end

@contact = ();
while(my $line = <NC>){
    chomp($line);
    $originalLine = $line;
    
    #remove whitespace from beginning, end, and replace any excess whitespace by a single space
    foreach($line) { s/^\s+//; s/\s+$//; s/\s+/ /g; }

    @contact=split(/ /,$line);

    # matching the residue numbers with those in the key, if matched assign the 2' structure (1st column in the key)
    # if not matched, assign tertiary structure (letter T)
    for ($i=0; $i < $keyIndex; $i++){

        if (($contact[3] == $nativeKey[$i][1]) 
         && ($contact[7] == $nativeKey[$i][2])) {

            printf OUT "$originalLine"."\t$nativeKey[$i][0]\n";
            $tertiaryFlag = "false";
            last; # why not next?
        }

        elsif (($contact[3] == $nativeKey[$i][2])
            && ($contact[7] == $nativeKey[$i][1])) {
            
            printf OUT "$originalLine"."\t$nativeKey[$i][0]\n";
            $tertiaryFlag = "false";
            last;
        }

        else {
                $tertiaryFlag = "true";
        } # last else
    } # end of 'for' loop

    if ($tertiaryFlag eq "true") { printf OUT "$originalLine"."\tT\n"; }
    @contact=();
}

close NC  or die $!;
close OUT or die $!;

print "Done!\n";
$timeEnd = strftime('%Y-%m-%d-%H-%M-%S',localtime);
print "Script ends at $timeEnd\n";
