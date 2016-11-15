#!/usr/bin/env perl
use strict;
use warnings;
use POSIX qw/strftime/;

# input is (1) list of native contacts and (2) all data points
# arguments should include 2 of the above and the output name

# This script calculates the normal average for all substructures
# except for loop 2 (L2) and tertiary (T) contacts. For these two
# the average is calculated over the "highest-valued peak",
# according to EJS 10/3/16.

our $usage = "$0 {native-simulation-list} {all-data} {output-(no-extension)}";
our $runTime = strftime('_%Y%m%d_%H%M%S', localtime);
our $equilibriumCutOff = 6000; #in picoseconds

&Main();

sub Main() {
    (my $nativeSimFileName, my $allDataFileName, my $outputFileName) = &ValidateAndParseCLIArgs(@ARGV);
    $outputFileName = &GenerateAndAppendTimeStampToOutputFileName($outputFileName);
    Log($outputFileName);
    our %NativeSimList = &ParseNativeSimulationList($nativeSimFileName);

    (my $sumNC_S1, my $populationNC_S1, 
     my $sumNC_S2, my $populationNC_S2,
     my $sumNC_L1, my $populationNC_L1,
     my $sumNC_L2, my $populationNC_L2,
     my $sumNC_T,  my $populationNC_T,
     my $sumNC,    my $populationNC,
     my $sumNNC,   my $populationNNC) = &ParseNativeSimData($allDataFileName, \%NativeSimList);
    
    my $averageNC_S1 = ($populationNC_S1 > 0) ? ($sumNC_S1 / $populationNC_S1) : 0;
    my $averageNC_S2 = ($populationNC_S2 > 0) ? ($sumNC_S2 / $populationNC_S2) : 0;
    my $averageNC_L1 = ($populationNC_L1 > 0) ? ($sumNC_L1 / $populationNC_L1) : 0;
    my $averageNC_L2 = ($populationNC_L2 > 0) ? ($sumNC_L2 / $populationNC_L2) : 0;
    my $averageNC_T  = ($populationNC_T > 0)  ? ($sumNC_T  / $populationNC_T) : 0;
    my $averageNC    = ($populationNC > 0)    ? ($sumNC    / $populationNC) : 0;
    my $averageNNC   = ($populationNNC > 0)   ? ($sumNNC   / $populationNNC) : 0;

    open (OUTPUT, ">>", $outputFileName);
    printf OUTPUT "#\tS1\tS2\tL1\tL2\tT\tNC\tNNC\n";
    printf OUTPUT "\t%.2f\t", $averageNC_S1;
    printf OUTPUT "%.2f\t", $averageNC_S2;
    printf OUTPUT "%.2f\t", $averageNC_L1; 
    printf OUTPUT "%.2f\t", $averageNC_L2;
    printf OUTPUT "%.2f\t", $averageNC_T;
    printf OUTPUT "%.2f\t", $averageNC;
    printf OUTPUT "%.2f\n", $averageNNC;
    close(OUTPUT);
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
    if (scalar(@arguments) < 3) { 
        print "ERROR: Invalid argument(s). Please see usage below.\n$usage\n"; 
        exit; 
    }

    my $nativeSimFileName = $ARGV[0];
    my $allDataFileName = $ARGV[1];
    my $outputFileName = $ARGV[2];

    return ($nativeSimFileName, $allDataFileName, $outputFileName);
}

sub GenerateAndAppendTimeStampToOutputFileName() {
    my $outputFileNameNoExt = $_[0];
    my $outputFileNameFinal = "${outputFileNameNoExt}${runTime}.txt";
    print "INFO: Result will be saved to $outputFileNameFinal\n";
    return $outputFileNameFinal;
}

sub ParseNativeSimulationList() {
    my $nativeSimFileName = $_[0];
    if (!(-e $nativeSimFileName)) { print "ERROR: $nativeSimFileName does not exist. Please try again.\n"; exit; }
    open(NATIVE_SIM_LIST, "<", $nativeSimFileName);

    my %NativeSimList = ();

    while (my $line = <NATIVE_SIM_LIST>) {
        if ($line =~ m/^#/) { next; }
        foreach ($line) { s/^\s+//; s/\s+$//; }
        if ($line eq "") { next; }

        (my $project, my $run, my $clone, my $lastTimeFrame) = split(/\s+/, $line);
        $NativeSimList{"${project}_${run}_${clone}"} = $lastTimeFrame;
    }

    close(NATIVE_SIM_LIST);

    # See import result (testing purposes)
    foreach my $key (sort keys %NativeSimList) {
        print "$key => $NativeSimList{$key}\n";
    }

    return %NativeSimList;
}

sub ParseNativeSimData() {
    my $allDataFileName = $_[0];
    my %nativeSimList = %{$_[1]};
    
    if (!(-e $allDataFileName)) {
        print "ERROR: $allDataFileName does not exist. Please try again.\n";
        exit;
    }

    open(ALL_DATA, "<", $allDataFileName);

    my $sumNC_S1 = 0; my $populationNC_S1 = 0;
    my $sumNC_S2 = 0; my $populationNC_S2 = 0;
    my $sumNC_L1 = 0; my $populationNC_L1 = 0;
    my $sumNC_L2 = 0; my $populationNC_L2 = 0;
    my $sumNC_T = 0;  my $populationNC_T = 0;
    my $sumNC = 0;    my $populationNC = 0;
    my $sumNNC = 0;   my $populationNNC = 0;

    while (my $line = <ALL_DATA>) {
        if ($line =~ m/^#/) { next; }
        foreach ($line) { s/^\s+//; s/\s+$//; }
        if ($line eq "") { next; }

        (my $project, my $run, my $clone, my $time,
         my $RMSD, my $Rg,
         my $S1, my $S2, my $L1, my $L2, my $T,
         my $NC, my $NNC)
        = split(/\s+/, $line);
        
        if (defined($nativeSimList{"${project}_${run}_${clone}"}) and $time >= $equilibriumCutOff) {
            $sumNC_S1 += $S1;
            $populationNC_S1 += 1;
            
            $sumNC_S2 += $S2;
            $populationNC_S2 += 1;
            
            $sumNC_L1 += $L1;
            $populationNC_L1 += 1;
            
            if ($L2 >= 120) {
                $sumNC_L2 += $L2;
                $populationNC_L2 += 1;
            }            
            
            if ($T >= 400) {
                $sumNC_T += $T;
                $populationNC_T += 1;
            }            
            
            $sumNC += $NC,
            $populationNC += 1;
            
            $sumNNC += $NNC;
            $populationNNC += 1;
        }
        
    }

    close(ALL_DATA);
    
    return ($sumNC_S1, $populationNC_S1,
            $sumNC_S2, $populationNC_S2,
            $sumNC_L1, $populationNC_L1,
            $sumNC_L2, $populationNC_L2,
            $sumNC_T,  $populationNC_T,
            $sumNC,    $populationNC,
            $sumNNC,   $populationNNC);
}