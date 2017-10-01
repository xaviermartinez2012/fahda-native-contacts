#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use FindBin qw($Bin);
use Getopt::Long qw(HelpMessage :config pass_through);
use lib "$Bin/../lib";
use Share::DirUtil qw(get_dirs);
use Share::Fahda qw(get_max_dir_number);
use Share::FileUtil qw(get_files);

GetOptions("help|h" => sub { print STDOUT HelpMessage(0) });

my $Project_Dir = $ARGV[0] or die "[FATAL]  A PROJ* dir must be specified\n";
my $Output_File = $ARGV[1] or die "[FATAL]  An output file name must be specified\n";

my ($Project_Number) = $Project_Dir =~ /(\d+$)/;
my $Cwd              = getcwd();
my $Project_Path     = "$Cwd/$Project_Dir";

my $Joined_Con_File = "$Cwd/$Output_File";
if (-e $Joined_Con_File) {
    `rm $Joined_Con_File`;
}
`touch $Joined_Con_File`;

do_work();
print STDOUT "Done!\n";

sub do_work {
    my $max_run_number = get_max_dir_number(get_dirs($Project_Path, '^RUN\d$'));
    if (not defined $max_run_number) { return; }

    for (my $run_number = 0 ; $run_number <= $max_run_number ; $run_number++) {
        my $run_path = "$Project_Path/RUN$run_number";
        if (not -d $run_path) { next; }

        my $max_clone_number = get_max_dir_number(get_dirs($run_path, '^CLONE\d+$'));

        for (my $clone_number = 0 ; $clone_number <= $max_clone_number ; $clone_number++) {
            my $clone_path = "$run_path/CLONE$clone_number";
            if (not -d $clone_path) { next; }
            my @con_files = get_files($clone_path, '\.con$');

            my $con_file_count = scalar(@con_files);
            for (my $frame_number = 0 ; $frame_number < $con_file_count ; $frame_number++) {
                my $con_file = "p${Project_Number}_r${run_number}_c${clone_number}_f${frame_number}.con";
                my $con_path = "$clone_path/$con_file";
                if (not -e $con_path) { print STDOUT "$con_path does not exist\n"; next; }

                `echo $con_file >> $Joined_Con_File`;
                `less $con_path >> $Joined_Con_File`;
            }
        }
    }
}

=head1 NAME

cons-join.pl - Concatenates all individual .con in the given F@H directory
into a single all-contacts*.con file

=head1 SYNOPSIS

cons-join.pl <project_dir> <output.con>

It is recommended to include Max_Distance_In_A and Min_Delta_Residues values
used in cons-make.pl in the output filename.

=cut
