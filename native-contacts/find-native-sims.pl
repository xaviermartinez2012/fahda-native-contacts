#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long qw(HelpMessage :config pass_through);

GetOptions("help|h" => sub { print HelpMessage(0) });

my $Log_File        = $ARGV[0] or die "[FATAL]  A logfile (w/ RMSDs) must be specified\n";
my $Max_Native_Rmsd = $ARGV[1] or die "[FATAL]  A max native RMSD must be specified\n";
my $Output_File     = "native_sims_${Max_Native_Rmsd}A.txt";

my %data;    # "proj:run:clone" => [time_in_ps, is_native_sim]
open(my $LOG_FILE, '<', $Log_File) or die "[FATAL]  $Log_File: $!\n";
while (my $line = <$LOG_FILE>) {
    my ($project_number, $run_number, $clone_number, $time_in_ps, $rmsd) = split(/\b\s+\b/, $line);
    my $key = "$project_number:$run_number:$clone_number";
    if (defined $data{$key}) {
        $data{$key}[0] = $time_in_ps;
        $data{$key}[1] &= ($rmsd <= $Max_Native_Rmsd);
    }
    else {
        $data{$key} = [ $time_in_ps, ($rmsd <= $Max_Native_Rmsd) ];
    }
}
close($LOG_FILE);

open(my $OUT, '>', $Output_File) or die "[FATAL]  $Output_File: $!\n";
foreach my $key (keys %data) {
    my $is_native_sim = $data{$key}[1];
    if (!$is_native_sim) { next; }

    my ($project_number, $run_number, $clone_number) = split(/:/, $key);
    my $time_in_ps = $data{$key}[0];
    printf $OUT "%4d    %3d    %4d    %6d\n", $project_number, $run_number, $clone_number, $time_in_ps;
}
close($OUT);

=head1 NAME

find-native-sims.pl - find native simulations

=head1 SYNOPSIS

find-native-sims.pl <log_file> <max_native_rmsd>

Given a max native RMSD in Angstroms, Max_Native_Rmsd, a simulation is "native"
when all timeframes has RMSD <= max_native_rmsd

=cut
