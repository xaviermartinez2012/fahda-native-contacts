#!/usr/bin/env perl

use strict;
use warnings;

use Config::Simple;
use Getopt::Long qw(HelpMessage :config pass_through);
use Statistics::Descriptive;

GetOptions(
    "sample-config|s" => sub { generate_sample_config(); exit(0); },
    "help|h" => sub { print STDOUT HelpMessage(0) }
);

my $Config_File = $ARGV[0] or die "A config file must be specified\n";
perform_stats_calculations($Config_File);

sub perform_stats_calculations {
    my ($config_file) = @_;

    my $cfg                      = new Config::Simple($config_file);
    my $native_sim_contacts_file = $cfg->param("native_sim_contacts");
    my $native_sim_list_file     = $cfg->param("native_sims");
    my $outfile                  = $cfg->param("outfile");

    print STDOUT "Reading distance data from $native_sim_contacts_file...\n";
    my $atomic_distance_data = read_atomic_distance_data($native_sim_contacts_file);

    print STDOUT "Calculating the total number of frames from $native_sim_list_file...\n";
    my $number_of_frames = calculate_number_of_frames($native_sim_list_file);

    print STDOUT "Calculate atomic distance data statistics...\n";
    calculate_atomic_distance_stats($atomic_distance_data, $number_of_frames, $outfile);
}

sub read_atomic_distance_data {
    my ($native_sim_atomic_contact_file) = @_;
    my %atomic_distance_data = {};    # "$i-$j" => \[distances]
    open(my $CON, '<', $native_sim_atomic_contact_file) or die "$native_sim_atomic_contact_file: $!\n";
    while (my $line = <$CON>) {
        chomp(my @fields = split(/\b\s+\b/, $line));
        my $atomic_distance = $fields[9];
        my $atom_i          = $fields[0];
        my $atom_i_residue  = $fields[3];
        my $atom_j          = $fields[4];
        my $atom_j_residue  = $fields[7];

        my $atom_pair_id = "$atom_i:$atom_i_residue:$atom_j:$atom_j_residue";
        if (defined $atomic_distance_data{$atom_pair_id}) {
            push(@{ $atomic_distance_data{$atom_pair_id} }, $atomic_distance);
        }
        else {
            $atomic_distance_data{$atom_pair_id} = [$atomic_distance];
        }
    }
    close($CON);
    return \%atomic_distance_data;
}

sub calculate_number_of_frames {
    my ($native_sim_list_file) = @_;

    my $total_time_in_ps = 0;
    open(my $NATSIMS, '<', $native_sim_list_file) or die "$native_sim_list_file: $!\n";
    while (my $line = <$NATSIMS>) {
        if ($line =~ m/^#/) { next; }    # skip comments
        chomp(my @fields = split(/\b\s+\b/, $line));
        $total_time_in_ps += @fields[ scalar(@fields) - 1 ];
    }
    close $NATSIMS;

    # Each frame is recorded every 100ps. We don't
    # take into account the frame0 for each simulation.
    # So the number of frames = (total sim time)/100
    my $number_of_frames = $total_time_in_ps / 100;
    return $number_of_frames;
}

sub calculate_atomic_distance_stats {
    my ($atomic_distance_data, $number_of_frames, $outfile) = @_;

    open(my $OUTPUT, '>', $outfile) or die "$outfile: $!\n";
    foreach my $atom_pair (keys %$atomic_distance_data) {
        my $full_descriptive_stats = Statistics::Descriptive::Full->new();
        $full_descriptive_stats->add_data(@$atomic_distance_data{$atom_pair});

        my $contact_occurance_percent =
          ($full_descriptive_stats->count() / $number_of_frames);    # how many time a contact appears

        my $mean_atomic_distance        = $full_descriptive_stats->mean();
        my $mean_atomic_distance_stddev = $full_descriptive_stats->standard_deviation();

        my ($atom_i, $atom_i_residue, $atom_j, $atom_j_residue) = split(/:/, $atom_pair);
        printf $OUTPUT "%5d    %5d    %5d    %5d    %6.3f    %6.10f     %6.3f\n",
          $atom_i, $atom_i_residue, $atom_j, $atom_j_residue,
          $mean_atomic_distance, $mean_atomic_distance_stddev, $contact_occurance_percent;
    }
    close($OUTPUT);
}

sub generate_sample_config {
    my $cfg = new Config::Simple(syntax => 'http');
    $cfg->param("native_sim_contacts", "native_sim_contacts.nsc");
    $cfg->param("native_sims",         "native_sims.lst");
    $cfg->param("outfile",             "output.nscs");
    $cfg->write("run.cfg");
}

=head1 NAME

native-sim-contacts-stats.pl - Calculate the mean and standard deviation of atomic contact distances
and the percent of time a contact appears

=head1 SYNOPSIS

./native-sim-contacts-stats.pl -h

./native-sim-contacts-stats.pl --sample-config

./native-sim-contacts-stats.pl run.cfg

=cut
