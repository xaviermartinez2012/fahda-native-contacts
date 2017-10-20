#!/usr/bin/env perl

use strict;
use warnings;

use Config::Simple;
use Getopt::Long qw(HelpMessage :config pass_through);

GetOptions(
    "sample-config|s" => sub { generate_sample_config(); exit(0); },
    "help|h" => sub { print STDOUT HelpMessage(0); }
);

my $Config_File = $ARGV[0] or die "A config file must be specified\n";
find_native_contacts($Config_File);

sub find_native_contacts {
    my ($config_file) = @_;

    my $cfg                      = new Config::Simple($config_file);
    my $excluded_contacts_file   = $cfg->param("excluded_contacts_file");
    my $native_contacts_file     = $cfg->param("native_contacts_file");
    my $native_sim_contacts_file = $cfg->param("native_sim_contacts_file");

    open(my $NATIVE_SIM_CONTACTS, '<', $native_sim_contacts_file) or die "$native_sim_contacts_file: $!\n";
    open(my $NATIVE_CONTACTS,     '>', $native_contacts_file)     or die "$native_contacts_file: $!\n";
    open(my $EXCLUDED_CONTACTS,   '>', $excluded_contacts_file)   or die "$excluded_contacts_file: $!\n";

    while (my $line = <$NATIVE_SIM_CONTACTS>) {
        chomp(my @fields = split(/\b\s+\b/, $line));

        my $atom_i                         = $fields[0];
        my $atom_j                         = $fields[1];
        my $mean_atomic_distance_angstroms = $fields[2];
        my $mean_atomic_distance_stddev    = $fields[3];
        my $contact_occurance_percent      = $fields[4];

        my $contact_is_native = $contact_occurance_percent >= $cfg->param("min_native_contact_occurance_percent")
          && ($mean_atomic_distance_angstroms + 2 * $mean_atomic_distance_stddev) <=
          $cfg->param("max_native_contact_distance_angstroms");

        if ($contact_is_native) {
            print $NATIVE_CONTACTS "$line";
        }
        else {
            print $EXCLUDED_CONTACTS "$line";
        }
    }

    close($NATIVE_SIM_CONTACTS);
    close($NATIVE_CONTACTS);
    close($EXCLUDED_CONTACTS);
}

sub generate_sample_config {
    my $cfg = new Config::Simple(syntax => 'http');
    $cfg->param("min_native_contact_occurance_percent",  "0.25");
    $cfg->param("max_native_contact_distance_angstroms", "6.0");
    $cfg->param("excluded_contacts_file",                "excluded.txt");
    $cfg->param("native_contacts_file",                  "native_cons.txt");
    $cfg->param("native_sim_contacts_file",              "native_sims.txt");
    $cfg->write("run.cfg");
}

=head1 NAME

native-contacts-find.pl - find native contacts

=head1 SYNOPSIS

./native-contacts-find.pl --help

./native-contacts-find.pl --sample-config

./native-contacts-find.pl run.cfg

=cut
