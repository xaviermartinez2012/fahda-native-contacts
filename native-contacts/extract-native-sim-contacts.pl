#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(HelpMessage :config pass_through);

GetOptions("help|h" => sub { print HelpMessage(0) });

my $Native_Sims_File = $ARGV[0] or die "A list of proj/run/clone of native sims must be specified\n";
my $Joined_Cons_File = $ARGV[1] or die "A atomic contact data (.con) file must be specified\n";
my $Outfile          = $ARGV[2] or die "An outfile must be specified\n";

print STDOUT "Parsing $Native_Sims_File\n";
my $Native_Sim_List = parse_native_sims_file($Native_Sims_File);

print STDOUT "Extracting native sim contact data from $Joined_Cons_File\n";
extract_native_sim_contacts($Joined_Cons_File, $Native_Sim_List);
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

sub extract_native_sim_contacts {
    my ($joined_cons_file, $native_sim_list) = @_;

    my $is_from_native_sim = 0;
    open(my $OUT,     '>', $Outfile)          or die "$Outfile: $!\n";
    open(my $CONFILE, '<', $Joined_Cons_File) or die "$Joined_Cons_File: $!\n";
    while (my $line = <$CONFILE>) {
        chomp($line);

        if ($is_from_native_sim and $line !~ /^p/) {
            print $OUT "$line\n";
        }

        # Skip if current line is not a timestamp (e.g. "p1796_r0_c0_f0.con")
        if ($line !~ /^p/) { next; }

        my ($prc, $frame_number) = split(/_f/, $line);
        $is_from_native_sim = ($$native_sim_list{$prc} == 1 and $frame_number ne "0.con") ? 1 : 0;
    }
    close($CONFILE);
    close($OUT);
}

=head1 NAME

extract-native-sims-contacts.pl - collect all contacts from native simulations

=head1 SYNOPSIS

./extract-native-sim-contacts.pl -h

./extract-native-sim-contacts.pl  <native_sims.lst> <joined_cons.con> <out.con>

=cut
