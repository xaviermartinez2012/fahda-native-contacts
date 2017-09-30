package Share::DirUtil;

use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_dirs);

sub get_dirs {
    my ($path, $match_pattern) = @_;
    if (not -d $path) { return; }

    $path =~ s/\/$//;
    opendir(my $PATH, $path);
    my @dirs = grep { -d "$path/$_" && /$match_pattern/ } readdir($PATH);
    closedir($PATH);

    return @dirs;
}

42;