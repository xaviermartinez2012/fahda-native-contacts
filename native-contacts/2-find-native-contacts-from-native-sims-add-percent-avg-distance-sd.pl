#!/usr/bin/perl

# ------------------------------------------------------------------------------
# Calculate the percent of time a native contact appears and its average
# distance and standard deviation
# ------------------------------------------------------------------------------

# TODO: fix the funny temp file using

use strict;
use POSIX qw/strftime/;
use Statistics::Descriptive;

# flush anything in buffer to output to avoid delayed outputing
use FileHandle;
STDOUT->autoflush(1);

$scriptInfo = "This script calculates the percent a native contact appears and its average distance.\n
./01.b-find-NCs-from-NatSims.pl [0] [1] [2]\n
Option     Filename       Type           Description\n
----------------------------------------------------------------------------\n
0.         contacts.txt   Input          List of contacts from native simulations\n
1.         natsims.txt    Input          List of native simulations, used to find the number of frames\n
											(contains project, run, clone, time)\n
2.         output.txt     Output         Textfile ______________\n
\n
Run the script with \"h\" or\"help\" argument to display this message.\n";

$usage = "\$perl script.pl [nat-sims-contacts]  [native-sims-list]  [output]\n";

# GET VALUES FROM THE CLI
# ------------------------------------------------------------------------------
$contactsList = $ARGV[0] or die "$usage\n";
$nativeSims   = $ARGV[1] or die "$usage\n";
$outputFile   = $ARGV[2] or die "$usage\n";

if ($ARGV[0] eq "-h" or $ARGV[0] eq "--help") {
    print $usage;
    exit();
}

# Print input arguments & start time
print "$0 ";
foreach my $item (@ARGV) { print "$item "; }
print "\n";
$timeStart = strftime('%Y-%m-%d-%H-%M-%S', localtime);
print "Script starts at: $timeStart.\n";

# CALCULATING THE NUMBER OF FRAMES
# ------------------------------------------------------------------------------
open(my $NATSIMS, '<', $nativeSims) || die "ERROR: $nativeSims: $!\n";

print "Calculating the total number of frames...\n";

# Get the last column only because it contains simulation time from all simulations.
@totalTime = ();
while (my $line = <$NATSIMS>) {
    if ($line =~ m/#/) { next; }    # skip comments
    my @splitLine = split(/\s+/, chomp $line);
    push(@totalTime, @splitLine[ scalar(@splitLine) - 1 ]);
}
close $NATSIMS;

# Caculate total simulation time...
$totalTime = 0;
foreach my $item (@totalTime) {
    $totalTime = $totalTime + $item;
}

# Each frame is recorded every 100ps. We don't take into account the frame0 for each simulation.
# So the number of frames = (total sim time)/100
$numFrames = ($totalTime / 100);
print "Number of frames is $numFrames\n";

# COUNTING NUMBER OF INSTANCES A CONTACT APPEARS
# ------------------------------------------------------------------------------
$prevLine = "";
$line     = "";

# the above two variables are always conjecutive lines from the input (native sims contacts list)

$count       = 0;
$percent     = 0;
$meanDist    = 0;
$std         = 0;
$meanDist2SD = 0;

# Get current time to be used as prefix for temporary files which store distance(s) for an atoms pair
$currentTime = strftime('%Y-%m-%d-%H-%M-%S', localtime);
$fileTimeStamp = "$currentTime" . "-01b-temp-";
print "The prefixed \"$fileTimeStamp\" will be used for temparory files.\n";

open(my $CON,    '<', $contactsList) or die("Could not open native simulations contacts file.\n");
open(my $OUTPUT, '>', $outputFile)   or die("Could not write to output file.\n");

while ($line = <$CON>) {
    chomp($line);
    $distance = substr($line, -5);    # extract the distance
    $line =~ s/.....$//;              # remove the distance--which is 5-character long--at the end of a line

    # (1) $prevLine is an empty string ONLY at the beginning of the loop
    if ($. == 1) {
        print "reading the first line...\n\n";
        $prevLine = $line;

        #writing the distance to a temp file
        $file = "$fileTimeStamp" . "$line" . ".txt";
        open(my $DISTANCE, '>>', $file);
        print $DISTANCE "$distance\n";
        close $DISTANCE;
        next;
    }

    # (2) if $prevLine is not a null string, then...
    elsif ($line eq $prevLine) {
        $file = "$fileTimeStamp" . "$line" . ".txt";
        open(my $DISTANCE, '>>', $file);
        print $DISTANCE "$distance\n";
        close $DISTANCE;
        next;
    }

    # if $line isn't idential to $prevLine
    elsif ($line ne $prevLine) {
        $file = "${fileTimeStamp}${line}.txt";
        open(my $DISTANCE, '>>', $file);
        print $DISTANCE "$distance\n";
        close $DISTANCE;

        # count the number of distances per unique contact and get descriptive stat

        $file = "${fileTimeStamp}${prevLine}.txt";
        open(my $DISTANCE, '<', $file);
        my @distanceArray = ();
        while (my $di = <$DISTANCE>) {
            chomp($di);
            push(@distanceArray, $di);
        }
        close $DISTANCE;

        my $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@distanceArray);
        $meanDist    = $stat->mean();
        $count       = $stat->count();
        $std         = $stat->standard_deviation();
        $meanDist2SD = $meanDist + 2 * $std;
        $percent     = ($count / $numFrames) * 100;

        # if the percentage is smaller than the cut-off $P (user-input)...
        if ($percent < $P) {
            $prevLine = $line;
        }
        else {
            print "Writing to output file...\n\n";
            $printLine = $prevLine;
            $printLine =~ s/\s+/\t/g;
            printf $OUTPUT "$printLine" . "%6.3f\t%6.3f\t%6.10f\t%6.10f\n", $percent, $meanDist, $std, $meanDist2SD;

            $prevLine = $line;
        }
    }
}

# Write the last contact...
# Why: The last set of identical lines will not be written because of condition (2)

$file = "${fileTimeStamp}${prevLine}.txt";
open(my $DISTANCE, '<', $file);
my @distanceArray = ();
while (my $di = <$DISTANCE>) {
    chomp($di);
    push(@distanceArray, $di);
}
close $DISTANCE;

my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@distanceArray);
$meanDist    = $stat->mean();
$count       = $stat->count();
$std         = $stat->standard_deviation();
$meanDist2SD = $meanDist + 2 * $std;
$percent     = ($count / $numFrames) * 100;

print "Writing to output file...\n\n";
$printLine = $prevLine;
$printLine =~ s/\s+/\t/g;
printf $OUTPUT "$printLine" . "%6.3f\t%6.3f\t%6.10f\t%6.10f\n", $percent, $meanDist, $std, $meanDist2SD;

close $OUTPUT;
close $CON;

# MOVING TEMP FILES TO A TEMP DIRECTORY TO BE DELETED LATER BY USER
# ------------------------------------------------------------------------------
@tempFiles = `tree -Li 1 | grep $currentTime`;
$tempDir   = "$currentTime-01b-temp-files";
`mkdir $tempDir`;

print "Moving temporary files to a $tempDir...\n";
foreach my $item (@tempFiles) {
    chomp $item;
    `mv \"$item\" $tempDir\/`;
}
print STDOUT "All temporary files have been moved to ./$tempDir.\n";
print STDOUT "The output file is $outputFile.\n";
