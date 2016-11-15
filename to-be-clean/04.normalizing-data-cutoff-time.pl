#!/usr/bin/perl 

# ========================================================================================
#   KHAI K.Q. NGUYEN
#   California State University, Long Beach
#   Biochemistry, 2014
# ========================================================================================

# ========================================================================================
# FILE INFO
    $usage = "./04.nomalizing-data.pl [input] [Nat-column] [Non-nat-column] [Time-column] [Cut-off-time] [output]\n";
    $argument ="
    Option    Value       Description\n
    -----------------------------------------------------------------------------
    0.        Input.txt   Input file with native and non-native contact information\n
    1.        Integer     Column number for native contacts.\n
                          Remeber that the first column is counted as 0.\n
    2.        Integer     Column number for non-native contacts.\n
                          Remeber that the first column is counted as 0.\n
    3.        Integer     Column number for time frame.\n
    4.        Integer     Cut-off time in picoseconds.
    5.        Output.txt  Duh.\n\n

    Type `./04.normalizing-data.pl help` or `./04.normalizing-data.pl help` to display this information.\n";
# ========================================================================================


# ========================================================================================
# ASSIGNING VALUES FROM INPUT INFORMATION
    $inputFile   = $ARGV[0];
    $NCcolumn    = $ARGV[1];
    $NonNCcolumn = $ARGV[2];
    $timeColumn  = $ARGV[3];
    $cutoffTime  = $ARGV[4];
    $outputFile  = $ARGV[5];

    if (($ARGV[0] eq "help") or ($ARGV[0] eq "h") or ($ARGV[0] eq "-h")) { 
        print $usage; exit(); 
    }
# ========================================================================================


# ========================================================================================
# FIND MAX VALUES FOR NATIVE CONTACTS AND NON-NATIVE CONTACTS
    print "Finding max values for native contacts and non-native contacts...\n";

    open(INPUT,'<',$inputFile) or die "No input file. $!\n";

    $maxNC    = 0;
    $minNC    = 0;
    $maxNonNC = 0;
    $minNonNC = 0;

    while ($line = <INPUT>) {
        chomp($line);

        # remove whitespace from both ends and replace any number 
        # of whitespace between the words by one single whitespace
        foreach ($line) { s/^\s+//; s/\s+$//; s/\s+/ /g; }

        @line = split(' ',$line);

        # bubble sorting, but only use values for time frame greater than or equal to the input cut-off time
        if (@line[$timeColumn] >= $cutoffTime) {
            if (@line[$NCcolumn] >= $maxNC)       { $maxNC = @line[$NCcolumn]; }
            if (@line[$NCcolumn] <= $minNC)       { $minNC = @line[$NCcolumn]; }
            if (@line[$NonNCcolumn] >= $maxNonNC) { $maxNonNC = @line[$NonNCcolumn]; }
            if (@line[$NonNCcolumn] <= $minNonNC) { $minNonNC = @line[$NonNCcolumn]; }
        }
    }

    close INPUT;

    # print max & min values for native and non-native contacts to a file
    $maxminOutputFile = $outputFile.".maxmin";
    open (MAXMIN,">>", $maxminOutputFile) or die "Cannot write max & min values to the $maxminOutputFile file. $!\n";
        printf MAXMIN "For native contacts:\n";
        printf MAXMIN "The maximum value is $maxNC.\n";
        printf MAXMIN "The minimum value is $minNC.\n";
        printf MAXMIN "For non-native contacts:\n";
        printf MAXMIN "The maximum value is $maxNonNC.\n";
        printf MAXMIN "The minimum value is $minNonNC.\n";
    close MAXMIN;
    
# ========================================================================================



# ========================================================================================
# normalizing
    $fractionNC    = 0; # ratio of native contacts to max navtive contacts ($maxNC)
    $fractionNonNC = 0; # ratio of non-native contacts to max non-native contacts ($maxNonNC)
    $NCh           = 0; # native character = $fractionNC - $fractionNonNC

    open (INPUT,"<$inputFile")     or die "Cannot read from input file. $!\n";
    open (OUTPUT, ">>$outputFile") or die "Cannot write to output file. $!\n";

    if (($maxNC == 0) or ($maxNonNC == 0)) { print "There is no timeframe above the cutoff time of $cutoffTime ps.\n"; }
    else {
        while ($line = <INPUT>) {
            chomp ($line);
            $originalLine = $line; # so that we can print out to output later.

            # remove whitespace from both ends and replace any number 
            # of whitespace between the words by one single whitespace
            foreach ($line) { s/^\s+//; s/\s+$//; s/\s+/ /g; }

            @line = split(' ',$line);

            $fractionNC = @line[$NCcolumn] / $maxNC;
            $fractionNonNC = @line[$NonNCcolumn] / $maxNonNC;
            $NCh = $fractionNC - $fractionNonNC;

            printf OUTPUT "$originalLine"."\t%1.5f\t%1.5f\t%2.5f\n", $fractionNC, $fractionNonNC, $NCh;
        } # end of `while` loop
    } # end of `else`
    close INPUT;
    close OUTPUT;
# ========================================================================================
