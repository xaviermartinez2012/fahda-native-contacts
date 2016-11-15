#!/usr/bin/perl

$usage = "perl 01.b.1-removing-tab-chars.pl input.txt output.txt";
$input = $ARGV[0] or die "$usage\n";
$output = $ARGV[1] or die "$usage\n";

# =======================================================================================
# The code below replaces all tab characters in a text file by four whitespaces.
# This is needed because this script write temporary files whose names are the
# lines from the input file which might contain tab characters.
# UNIX system doesn't allow tab characters in the filename.
    open (IN, "<$input") or die "Could not open input file $input. $!\n";
    print "Reading $input...\n";
    open (OUT, ">>$output") or die "Could not write to output file $output. $!\n";
    print "Opening $output...\n";
    print "Writing contacts list with no tab characters in its body...\n";
    while (my $line = <IN>) {
       chomp ($line);
       $line =~ s/\t/    /g;
       print OUT "$line\n";
    }

    close IN;
    close OUT;
    print "Done!\n";
# =======================================================================================

