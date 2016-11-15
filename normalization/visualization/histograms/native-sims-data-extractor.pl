#!/usr/bin/env perl
use strict;
use warnings;

our $usage = "$0 {native-simulation-list} {all-data} {output-(no-extension)}";
our $equilibriumCutOff = 6000; #in picoseconds

&Main();

sub Main()
{
    (my $nativeSimFileName, my $allDataFileName, my $outputFileName) = &ValidateAndParseCLIArgs(@ARGV);
    $outputFileName = &GenerateOutputFileName($outputFileName);
    Log($outputFileName);
    our %NativeSimList = &ParseNativeSimulationList($nativeSimFileName);
    &ExtractNativeSimData($allDataFileName, \%NativeSimList, $outputFileName);
}

sub Log() {
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

sub ValidateAndParseCLIArgs() {
    my @arguments = @_;
    if (scalar(@arguments) != 3) { 
        print "ERROR: Too many or too few arguments. Please see usage below.\n$usage\n"; 
        exit; 
    }

    my $nativeSimFileName = $ARGV[0];
    my $allDataFileName = $ARGV[1];
    my $outputFileName = $ARGV[2];

    return ($nativeSimFileName, $allDataFileName, $outputFileName);
}

sub GenerateOutputFileName() {
    my $outputFileNameNoExt = $_[0];
    my $outputFileNameFinal = "${outputFileNameNoExt}.txt";
    print "INFO: Result will be saved to $outputFileNameFinal\n";
    return $outputFileNameFinal;
}

sub ParseNativeSimulationList() {
    my $nativeSimFileName = $_[0];
    if (!(-e $nativeSimFileName)) { print "ERROR: $nativeSimFileName does not exist. Please try again.\n"; exit; }
    open(NATIVE_SIM_LIST, "<", $nativeSimFileName);

    my %NativeSimList = ();

    while (my $line = <NATIVE_SIM_LIST>)
    {
        if ($line =~ m/^#/) { next; }
        foreach ($line) { s/^\s+//; s/\s+$//; }
        if ($line eq "") { next; }

        (my $project, my $run, my $clone, my $lastTimeFrame) = split(/\s+/, $line);
        $NativeSimList{"${project}_${run}_${clone}"} = $lastTimeFrame;
    }

    close(NATIVE_SIM_LIST);

    # See import result (testing purposes)
    foreach my $key (sort keys %NativeSimList)
    {
        print "$key => $NativeSimList{$key}\n";
    }

    return %NativeSimList;
}

sub ExtractNativeSimData()
{
    my $allDataFileName = $_[0];
    my %nativeSimList = %{$_[1]};
    my $outputFileName = $_[2];
    
    if (!(-e $allDataFileName)) {
        print "ERROR: $allDataFileName does not exist. Please try again.\n";
        exit;
    }

    open(ALL_DATA, "<", $allDataFileName);
    open(OUTPUT, ">", $outputFileName);

    my $sumNC_S1 = 0;
    my $sumNC_S2 = 0;
    my $sumNC_L1 = 0;
    my $sumNC_L2 = 0;
    my $sumNC_T = 0;
    my $sumNC = 0;
    my $sumNNC = 0;

    while (my $line = <ALL_DATA>) {
        if ($line =~ m/^#/) { next; }
        my $originalLine = $line;
        foreach ($line) { s/^\s+//; s/\s+$//; }
        if ($line eq "") { next; }

        (my $project, my $run, my $clone, my $time,
         my $RMSD, my $Rg,
         my $S1, my $S2, my $L1, my $L2, my $T,
         my $NC, my $NNC)
        = split(/\s+/, $line);
        
        if (defined($nativeSimList{"${project}_${run}_${clone}"}) and 
            $time >= $equilibriumCutOff) {
            printf OUTPUT $originalLine;
        }        
    }

    close(ALL_DATA);
    close(OUTPUT);
}