#!/usr/bin/env perl
use strict;
use warnings;
use POSIX qw/strftime/;

#   KHAI K.Q. NGUYEN
#   2016

our $usage = "$0  {all-data-file} {output-file-no-ext}";
our $runTime = strftime('_%Y%m%d_%H%M%S', localtime);

&Main();

sub Main
{
    my ($allDataFileName, $outputFileName) = &ValidateAndParseCLIArgs(@ARGV);
    $outputFileName = &GenerateAndAppendTimeStampToOutputFileName($outputFileName);
    Log($outputFileName);

    NormalizeData($allDataFileName, $outputFileName);
}

sub ValidateAndParseCLIArgs()
{
    my @arguments = @_;
    if (scalar(@arguments) != 2) 
    { 
        print "ERROR: Too many or too few arguments. Please see usage below.\n$usage\n"; 
        exit; 
    }

    my $allDataFileName = $arguments[0];
    my $outputFileName = $arguments[1];

    return ($allDataFileName, $outputFileName);
}

sub GenerateAndAppendTimeStampToOutputFileName()
{
    my $outputFileNameNoExt = $_[0];
    my $outputFileNameFinal = "${outputFileNameNoExt}${runTime}.txt";
    print "INFO: Result will be saved to $outputFileNameFinal\n";
    return $outputFileNameFinal;
}

sub Log()
{
    my $outputFileName = $_[0];
    open (OUTPUT, ">", $outputFileName);
    print OUTPUT "# $0 ";
    foreach my $arg (@ARGV)
    {
        print OUTPUT $arg, " ";
    }
    print OUTPUT "\n";
    close(OUTPUT);
}

sub NormalizeData
{
    my $averageS1 = 428.61;
    my $averageS2 = 188.08;
    my $averageL1 = 8.23;
    my $averageL2 = 146.78; #Old value: 107.25;
    my $averageT  = 457.25; #Old value: 369.61;
    my $averageNC = 1101.77;
    my $averageNNC = 1930.00;

    my ($inputFile, $outputFile) = ($_[0], $_[1]);

    open (INPUT,"<", $inputFile) or die "Cannot read from $inputFile. $!\n";
    open (OUTPUT, ">", $outputFile) or die "Cannot write to $outputFile. $!\n";

    while (my $line = <INPUT>)
    {
        if ($line =~ m/^#/) { next; }

        (my $project, my $run, my $clone, my $time,
         my $RMSD, my $Rg,
         my $S1, my $S2, my $L1, my $L2, my $T,
         my $NC, my $NNC)
        = &SplitLineIntoValues($line);;

        printf OUTPUT "%d\t", $project;
        printf OUTPUT "%d\t", $run;
        printf OUTPUT "%d\t", $clone;
        printf OUTPUT "%d\t", $time;

        printf OUTPUT "%5.3f\t", $RMSD;
        printf OUTPUT "%5.3f\t", $Rg;

        printf OUTPUT "%5.3f\t", $S1/$averageS1;
        printf OUTPUT "%5.3f\t", $S2/$averageS2;
        printf OUTPUT "%5.3f\t", $L1/$averageL1;
        printf OUTPUT "%5.3f\t", $L2/$averageL2;
        printf OUTPUT "%5.3f\t", $T/$averageT;

        printf OUTPUT "%5.3f\t", $NC/$averageNC;
        printf OUTPUT "%5.3f\n", $NNC/$averageNNC;
    }
    
    close INPUT;
    close OUTPUT;
}

sub SplitLineIntoValues()
{
    my $line = $_[0];
    foreach ($line) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
    my @values = split(/ /, $line);
    return @values;
}