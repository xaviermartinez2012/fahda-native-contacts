#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long qw(HelpMessage :config pass_through);

GetOptions("help|h" => sub { print HelpMessage(0) });

my $Native_Sims_File = $ARGV[0] or die "[FATAL]  A list of proj/run/clone of native sims must be specified\n";
my $Joined_Cons_File = $ARGV[1] or die "[FATAL]  A contact .con file must be specified\n";
my $Output_File      = $ARGV[2] or die "[FATAL]  An output filename must be specified\n";

print STDOUT "[INFO]  Parsing $Native_Sims_File\n";
my $Native_Sims = parse_native_sims_file($Native_Sims_File);

#  Adding a check to make sure that the native simulations data is useable
my $NSindex = scalar(keys %$Native_Sims);
if ($NSindex == 0) {
    die "[FATAL]  There are no native simulations being used, "
      . "make sure native simulation file $Native_Sims_File exists and is not empty.\n";
}
else {
    print STDOUT "[INFO]  Native sim file $Native_Sims_File contains usable data";
}

my $Is_From_Native_Sim = 0;
open(my $OUT,     '>', $Output_File)      or die "[FATAL]  $Output_File: $!\n";
open(my $CONFILE, '<', $Joined_Cons_File) or die "[FATAL]  $Joined_Cons_File: $!\n";
while (my $line = <$CONFILE>) {
    chomp($line);

    if ($Is_From_Native_Sim and $line !~ /^p/) {
        print $OUT "$line\n";
    }

    # Skip if current line is not a timestamp (e.g. "p1796_r0_c0_f0.con")
    if ($line !~ /^p/) { next; }

    my ($prc, $frame_number) = split(/_f/, $line);
    $Is_From_Native_Sim = ($$Native_Sims{$prc} == 1 and $frame_number ne "0.con") ? 1 : 0;
}
close($CONFILE);
close($OUT);

#REVIEW: do we need to sort?
# print STDOUT "[INFO]  Sorting $Output_File...\n";
# `sort $Output_File > $Output_File_sorted.txt`;
print "Done!\n";

sub parse_native_sims_file {
    my ($native_sims_file) = @_;
    my %native_sims = {};
    open(my $NSFILE, '<', $native_sims_file) or die "[FATAL]  $native_sims_file: $!\n";
    while (my $line = <$NSFILE>) {
        if ($line =~ m/^#/) { next; }
        chomp(my @fields = split(/\b\s+\b/, $line));
        my ($project_number, $run_number, $clone_number) = @fields;
        $native_sims{"p${project_number}_r${run_number}_c${clone_number}"} = 1;
    }
    close($NSFILE);
    return \%native_sims;
}

=head1 NAME

find-native-sims-contacts.pl - collect all contacts from native simulations

=head1 SYNOPSIS

find-native-sims-contacts.pl  <native_sims.txt> <joined_cons.con> <output.txt>

=cut
