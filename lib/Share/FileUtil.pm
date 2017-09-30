package Share::FileUtil;

use strict;
use warnings;
require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_files file_ok $File_Ok_Message);

sub get_files {
    my ($path, $match_pattern) = @_;
    if (not -d $path) { return; }
    $path =~ s/\/$//;

    opendir(my $PATH, $path);
    my @files = grep { -e "$path/$_" && /$match_pattern/ } readdir($PATH);
    closedir($PATH);

    return @files;
}

our $File_Ok_Message;

sub file_ok {
    my ($filename) = @_;
    my $file_ok = 1;

    if (not -e $filename) {
        $File_Ok_Message = "$filename does not exist";
        return !$file_ok;
    }

    if (int(-s $filename) == 0) {
        $File_Ok_Message = "$filename is zero-sized";
        return !$file_ok;
    }

    return $file_ok;
}

42;
