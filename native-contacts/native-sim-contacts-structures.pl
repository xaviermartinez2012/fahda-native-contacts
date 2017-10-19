#!/usr/bin/perl

# ------------------------------------------------------------------------------
# Add 2nd structure notation/symbol to each frame
# ------------------------------------------------------------------------------

use strict;
use POSIX qw/strftime/;

$timeStart = strftime('%Y-%m-%d-%H-%M-%S', localtime);
print "Script starts at: $timeStart.\n";

$usage = "perl perlname.pl [input-contacts]  [structures-key]  [output]\n";

# GET CLI ARGUMENTS
# ------------------------------------------------------------------------------
$contactsFile = $ARGV[0] or die "$usage\n";
$keyFile      = $ARGV[1] or die "$usage\n";
$outputFile   = $ARGV[2] or die "$usage\n";

if ($ARGV[0] eq "-h" or $ARGV[0] eq "--help") {
    print $usage;
    exit();
}

# READING IN THE STRUCTURE KEY
# ------------------------------------------------------------------------------
open(my $KEY, '<', $keyFile) or die "Cannot open structure map file $keyFile. $!.\n";
@nativeKey = ();

while (my $line = <$KEY>) {
    if ($line =~ m/#/) { next; }    # skip comments in input file
    chomp($line);

    # remove whitespace from beginning, end, and
    # replace any excess whitespace by a single space
    foreach ($line) { s/^\s+//; s/\s+$//; s/\s+/ /g; }

    # creating 2D array, each element is a reference to a line in the key
    push(@nativeKey, [ split(/ /, $line) ]);
}
close $KEY or die "ERROR: $keyFile: $!\n";

$keyIndex = scalar(@nativeKey);

# Check if the structure file is empty
if ($keyIndex == 0) {
    print "FATAL ERROR: Did not read in the sturcture key correctly.\n
				Check file information to verify the title is correct.\n";
    exit();
}

# STARTING THE PROCESS OF READING IN CONTACTS
# ------------------------------------------------------------------------------
open(my $NC,  '<', $contactsFile) or die "ERROR: $contactsFile: $!\n";
open(my $OUT, '>', $outputFile)   or die "ERROR: $outputFile: $!\n";

while (my $line = <$NC>) {
    $originalLine = chomp $line;
    my @contact = split(/\s+/, chomp $line);

    # matching the residue numbers with those in the key,
    # if matched assign the 2' structure (1st column in the key)
    # if not matched, assign tertiary structure (letter T)
    for (my $i = 0 ; $i < $keyIndex ; $i++) {
        if (   ($contact[3] == $nativeKey[$i][1])
            && ($contact[7] == $nativeKey[$i][2]))
        {
            printf $OUT "$originalLine\t$nativeKey[$i][0]\n";
            $tertiaryFlag = "false";
            last;    # why not next?
        }
        elsif (($contact[3] == $nativeKey[$i][2])
            && ($contact[7] == $nativeKey[$i][1]))
        {
            printf $OUT "$originalLine\t$nativeKey[$i][0]\n";
            $tertiaryFlag = "false";
            last;
        }
        else {
            $tertiaryFlag = "true";
        }
    }

    if ($tertiaryFlag eq "true") {
        printf $OUT "$originalLine\tT\n";
    }
}

close $NC  or die "ERROR: $contactsFile: $!\n";
close $OUT or die "ERROR: $outputFile: $!\n";

print "Done!\n";
$timeEnd = strftime('%Y-%m-%d-%H-%M-%S', localtime);
print "Script ends at $timeEnd\n";
