#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use Getopt::Long qw(HelpMessage :config pass_through);
use List::Util qw(max);

GetOptions("help|h" => sub { print HelpMessage(0) });

my $Project_Dir     = $ARGV[0] or die "[FATAL]  Project directory must be specified\n";
my $Output_Filename = $ARGV[1] or die "[FATAL]  Output filename must be specified\n";

$Project_Dir =~ s/\/$//;    # Remove trailing slash if any
my $Project_Number = $Project_Dir;
$Project_Number =~ s/^PROJ//;    # Remove leading 'PROJ'

my $Path_To_Project_Dir = "${\getcwd()}/$Project_Dir";
$Output_Filename = "${\getcwd()}/$Output_Filename";
generate_logfile($Path_To_Project_Dir, $Project_Number);

sub generate_logfile {
    my ($path_to_project_dir, $project_number) = @_;

    chdir($path_to_project_dir);

    my @run_dirs = get_dirs($path_to_project_dir, "^RUN\\d+\$");
    if (scalar(@run_dirs) == 0) {
        print STDOUT "[INFO]  No RUN found\n";
        return;
    }

    for (my $run_number = 0 ; $run_number <= get_max_dir_number(@run_dirs) ; $run_number++) {
        my $run_dir = "RUN$run_number";
        if (not -d $run_dir) { next; }

        chdir $run_dir;

        my @clone_dirs = get_dirs("$path_to_project_dir/$run_dir", "^CLONE\\d+\$");
        if (scalar(@clone_dirs) == 0) {
            print STDOUT "[INFO]  No CLONE found in $run_dir\n";
            next;
        }

        foreach (my $clone_number = 0 ; $clone_number <= get_max_dir_number(@clone_dirs) ; $clone_number++) {
            my $clone_dir = "CLONE$clone_number";
            if (not -d $clone_dir) { next; }

            chdir $clone_dir;

            my $path_to_clone_dir = "$path_to_project_dir/$run_dir/$clone_dir";
            my $xtc_file          = get_xtc_file($cwd, $project_number, $run_number, $clone_number);
            my $all_frames_pdb    = generate_all_frames_pdb($xtc_file);
            my $log_string        = parse_all_frames_pdb($all_frames_pdb, $project_number, $run_number, $clone_number);

            open(my $OUT, ">>", $Output_Filename) or die "[FATAL]  $Output_Filename: $!\n";
            print $OUT $log_string;
            close($OUT);

            chdir "..";
        }

        chdir "..";
    }

}

sub get_dirs {
    my ($root, $match_pattern) = @_;
    if (not -d $root) { return; }
    if ($root !~ m/\/$/) { $root .= "/"; }

    opendir(my $ROOT_HANDLE, $root);
    my @dirs = grep { -d "$root$_" && /$match_pattern/ } readdir($ROOT_HANDLE);
    closedir($ROOT_HANDLE);

    return @dirs;
}

sub get_max_dir_number {
    my (@dirs) = @_;
    my @dir_numbers = ();
    foreach my $dir (@dirs) {
        my $dir_number = $dir;
        $dir_number =~ s/^\D+//;
        push(@dir_numbers, int($dir_number));
    }
    return max(@dir_numbers);
}

sub get_xtc_file {
    my ($cwd, $project_number, $run_number, $clone_number) = @_;

    my $xtc_file = "P${project_number}_R${run_number}_C${clone_number}.xtc";
    if (-e $xtc_file) { return $xtc_file; }

    opendir(my $CWD, $cwd);
    my @xtc_files = grep { /\.xtc$/ } readdir($CWD);
    closedir($CWD);

    if (scalar(@xtc_files) == 0) {
        print STDOUT "[WARN]  No XTC file found\n";
        return;
    }

    if (scalar(@xtc_files) > 1) {
        print STDOUT "[WARN]  More than one XTC file found; ";
        chomp($xtc_file = $xtc_files[0]);
        print STDOUT "using the first one: $xtc_file\n";
        return $xtc_file;
    }

    chomp($xtc_file = $xtc_files[0]);
    return $xtc_file;
}

sub generate_all_frames_pdb {
    my ($xtc_file) = @_;

    my $pdb_file = $xtc_file;
    $pdb_file =~ s/\.xtc$/.pdb/;
    if (-e $pdb_file) { return $pdb_file; }

    # `echo 1` to select the RNA (protein) group
    my $trjconv_cmd = "echo 1 | trjconv -s frame0.tpr -f $xtc_file -o $pdb_file  2> /dev/null";
    print STDOUT "Executing `$trjconv_cmd`\n";
    `$trjconv_cmd`;

    return $pdb_file;
}

sub parse_all_frames_pdb {
    my ($all_frames_pdb, $project_number, $run_number, $clone_number) = @_;

    open(my $ALL_FRAME_PDB, '<', $all_frames_pdb) or die "[FATAL]  $all_frames_pdb: $!";
    my $log_string = "";
    while (my $line = <$ALL_FRAME_PDB>) {
        if ($line !~ m/^TITLE/) { next; }
        chomp(my @values = split(/t=\s/, $line));
        my $time = int($values[1]);
        $log_string = $log_string . sprintf("%5d    %3d    %3d    %6d\n", $project_number, $run_number, $clone_number, $time);
    }
    close($ALL_FRAME_PDB);
    return $log_string;
}

=head1 NAME

fah-logfile-make.pl - Make F@H logfile

=head1 SYNOPSIS

./fah-logfile-make.pl <project_dir> <output.log>

./fah-logfile-make.pl PROJ1797 aquifex_PROJ1797.log

This script generates the F@H logfile.

=cut
