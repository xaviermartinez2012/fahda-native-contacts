#!/usr/bin/env perl

use strict;
use warnings;

use Config::Simple;
use FindBin qw($Bin);
use Getopt::Long qw(HelpMessage :config pass_through);
use lib "$Bin/../lib";
use Share::Fahda qw(get_prc_from_filename);

GetOptions(
    "sample-config|s" => sub { generate_sample_config_file(); exit(0); },
    "help|h" => sub { print STDOUT HelpMessage(0); }
);

my $Config_File = $ARGV[0] or die "A config file must be specified\n";
count_native_contacts($Config_File);

sub count_native_contacts {
    my ($config_file) = @_;

    my $cfg                  = new Config::Simple($config_file);
    my $all_contacts_file    = $cfg->param("all_contacts_file");
    my $native_contact_specs = $cfg->param("native_contact_specs_file");
    my $max_atomic_distance  = $cfg->param("max_atomic_distance");
    my $outfile              = $cfg->param("outfile");

    my $native_contact_specs = read_native_contact_specs($native_contact_specs_File);

    my $stem1_native_contact_count    = 0;
    my $stem2_native_contact_count    = 0;
    my $loop1_native_contact_count    = 0;
    my $loop2_native_contact_count    = 0;
    my $tertiary_native_contact_count = 0;
    my $total_native_contact_count    = 0;
    my $non_native_contact_count      = 0;

    my $previous_project_number = undef;
    my $previous_run_number     = undef;
    my $previous_clone_number   = undef;
    my $previous_time_in_ps     = undef;

    open(my $OUT,   '>', $outfile)           or die "$outfile: $!\n";
    open(my $inCON, '<', $all_contacts_file) or die "$all_contacts_file: $!\n";
    while (my $line = <$inCON>) {
        my ($project_number, $run_number, $clone_number, $frame_number) = get_prcf_from_filename($line);

        if ($. == 1) {
            $previous_project_number = $project_number;
            $previous_run_number     = $run_number;
            $previous_clone_number   = $clone_number;
            $previous_time_in_ps     = $frame_number * 100;
            next;
        }

        if (is_end_of_frame_data($line) || eof) {
            $total_native_contact_count =
              $stem1_native_contact_count +
              $stem2_native_contact_count +
              $loop1_native_contact_count +
              $loop2_native_contact_count +
              $tertiary_native_contact_count;

            printf $OUT "%5d\t%5d\t%5d\t%6d\t",
              $previous_project_number, $previous_run_number, $previous_clone_number, $previous_time_in_ps;
            printf $OUT "%5d\t%5d\t",      $stem1_native_contact_count, $stem2_native_contact_count;
            printf $OUT "%5d\t%5d\t%5d\t", $loop1_native_contact_count, $loop2_native_contact_count, $tertiary_native_contact_count;
            printf $OUT "%5d\t%5d\n",      $total_native_contact_count, $non_native_contact_count;

            # reseting counters for next time frame
            $stem1_native_contact_count    = 0;
            $stem2_native_contact_count    = 0;
            $loop1_native_contact_count    = 0;
            $loop2_native_contact_count    = 0;
            $tertiary_native_contact_count = 0;
            $total_native_contact_count    = 0;
            $non_native_contact_count      = 0;

            $previous_project_number = $project_number;
            $previous_run_number     = $run_number;
            $previous_clone_number   = $clone_number;
            $previous_time_in_ps     = $time_in_ps;
            next;
        }

        chomp(my @fields = split(/\b\s+\b/, $line));
        my $atom_i          = $fields[0];
        my $atom_j          = $fields[4];
        my $atomic_distance = $fields[9];

        if ($atomic_distance > $max_atomic_distance) { next; }

        if (!defined($$native_contact_specs{"$atom_i:$atom_j"})) {
            $non_native_contact_count++;
            next;
        }

        if ($atomic_distance <= $$native_contact_specs{"$atom_i:$atom_j"}{"mean_atomic_distance"} +
            2 * $$native_contact_specs{"$atom_i:$atom_j"}{"mean_atomic_distance_stddev"})
        {
            if    ($$native_contact_specs{"$atom_i:$atom_j"}{"structure_key"} eq "s1") { $stem1_native_contact_count++; }
            elsif ($$native_contact_specs{"$atom_i:$atom_j"}{"structure_key"} eq "s2") { $stem2_native_contact_count++; }
            elsif ($$native_contact_specs{"$atom_i:$atom_j"}{"structure_key"} eq "l1") { $loop1_native_contact_count++; }
            elsif ($$native_contact_specs{"$atom_i:$atom_j"}{"structure_key"} eq "l2") { $loop2_native_contact_count++; }
            elsif ($$native_contact_specs{"$atom_i:$atom_j"}{"structure_key"} eq "t")  { $tertiary_native_contact_count++; }
        }
    }

    close($OUT);
    close($inCON);
}

sub is_end_of_frame_data {

    # When a line is of the format "pX_rY_cZ_fW.con", where
    # X, Y, Z, and W represent project, run, clone, and time (picosecond),
    # respectively, it signifies the start of a new frame's atom-contact data

    my ($line) = @_;
    return ($line =~ '^p\d+_r\d+_c\d+_f\d+\.con$');
}

sub read_native_contact_specs {
    my ($native_contact_specs_file) = @_;
    my %native_contact_specs = {};
    open(my $NAT_SPECS, '<', $native_contact_specs_file) or die "$native_contact_specs_file: $!\n";
    while (my $line = <$NAT_SPECS>) {
        chomp(my @fields = split(/\b\s+\b/, $line));
        my $atom_i                      = $fields[0];
        my $atom_j                      = $fields[1];
        my $mean_atomic_distance        = $fields[2];
        my $mean_atomic_distance_stddev = $fields[3];
        my $occurance_percent           = $fields[4];
        my $structure_key               = $fields[5];

        $native_contact_specs{"$atom_i:$atom_j"} = \{
            "mean_atomic_distance"        => $mean_atomic_distance,
            "mean_atomic_distance_stddev" => $mean_atomic_distance_stddev,
            "occurance_percent"           => $occurance_percent,
            "structure_key"               => $structure_key
        };
    }

    return \%native_contact_specs;
}

sub generate_sample_config_file {
    my $cfg = new Config::Simple(syntax => 'http');
    $cfg->param("all_contacts_file",         "contacts.con");
    $cfg->param("native_contact_specs_file", "native_contacts.spc");
    $cfg->param("max_atomic_distance",       "5.0");
    $cfg->param("outfile",                   "out.log");
    $cfg->write("run.cfg");
}

=head1 NAME

script.pl - Count number of native & non-native contacts for every data point

=head1 SYNOPSIS

./native-contacts-count.pl -h

./native-contacts-count.pl --sample-config

./native-contacts-count.pl run.cfg

=cut
