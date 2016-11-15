#!/usr/bin/perl -w
##################################################################################################
#
#  Tabulating Outlier (unusal data) information    By: Arad 11/26/13
#
##################################################################################################


# =========================================================
# Setting Globals

	$usage = "\nUsage: perl aqui_optimal\.pl [all categorized data file] [percent NC cutoff for outliers] [output file]\n";
	
	$inFile = $ARGV[0] || die "$usage\n";
	$desiredCutOff = $ARGV[1] || die "$usage\n";
	$outputFile = $ARGV[2] || die "$usage\n";

# =========================================================

# =====================================================================
# Code variables
	$line1=0; @data= (); $outLier =0; $original =0;

# =====================================================================

# ====================================================================
#  Opening and storing native contact info for comparison later

	open (OUT, ">>$outputFile") || die "Could not generate excluded contacts list\n";
	
	open(INP, "<$inFile")|| die "Could not open the native contact file correctly\n";
	while($line1=<INP>){
		chomp($line1);	
		$original = $line1;
		foreach($line1) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
		@data=split(/ /,$line1);
		$outLier = $data[11];
		
		if ($outLier > $desiredCutOff){
			print OUT "$original\n";
		}
	}
	close(INP);
	close(OUT);
# ====================================================================
