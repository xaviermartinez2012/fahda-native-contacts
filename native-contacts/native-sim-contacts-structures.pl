#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(HelpMessage :config pass_through);

GetOptions("help|h" => sub { print STDOUT HelpMessage(0) });

my $Native_Sim_Contacts_File = $ARGV[0] or die "A native simulation atomic contacts file must be specified\n";
my $Structure_Key_File       = $ARGV[1] or die "A structure map file must be specified\n";
my $Outfile                  = $ARGV[2] or die "An output file must be specified\n";

my @Structure_Keys = read_structure_keys($Structure_Key_File);
add_structure_keys($Native_Sim_Contacts_File, \@Structure_Keys, $Outfile);

sub add_structure_keys {
    my ($native_sim_contacts_file, $structure_keys, $outfile) = @_;

    open(my $NC, '<', $native_sim_contacts_file) or die "$native_sim_contacts_file: $!\n";
    open(my $OUT, '>', $outfile) or die "$outfile: $!\n";

    while (my $line = <$NC>) {
        chomp($line);
        my @fields         = split(/\b\s+\b/, $line);
        my $atom_i_residue = $fields[1];
        my $atom_j_residue = $fields[3];

        # matching the residue numbers with those in the key,
        # if matched assign the 2' structure (1st column in the key)
        # if not matched, assign tertiary structure (letter T)
        my $structure_key =
          defined($$structure_keys{"$atom_i_residue:$atom_j_residue"})
          ? $$structure_keys{"$atom_i_residue:$atom_j_residue"}
          : 'T';
        print $OUT "$line    $structure_key\n";
    }

    close($NC);
    close($OUT);
}

sub read_structure_keys {
    my ($structure_keys_file) = @_;

    my %structure_keys = {};
    open(my $KEY, '<', $structure_keys_file) or die "$structure_keys_file: $!\n";
    while (my $line = <$KEY>) {
        if ($line =~ m/^#/) { next; }    # skip comments

        chomp(my @fields = split(/\b\s+\b/, $line));
        my $structure_key  = $fields[0];
        my $atom_i_residue = $fields[1];
        my $atom_j_residue = $fields[2];
        $structure_keys{"$atom_i_residue:$atom_j_residue"} = $structure_key;
        $structure_keys{"$atom_j_residue:$atom_i_residue"} = $structure_key;
    }
    close($KEY);

    return \%structure_keys;
}

=head1 NAME

native-sim-contacts-structures.pl - add 2nd structure notation/symbol to each frame

=head1 SYNOPSIS

native-sim-contacts-structures.pl <native_sim_contacts>  <structures_key>  <outfile>

=cut
