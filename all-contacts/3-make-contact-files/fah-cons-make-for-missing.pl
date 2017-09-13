#!/usr/bin/perl
##########################################################################
## Goal: This script is used for generate pdb from empty pdb files list  #
## Scripter: Phuc La
#input file sample
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN10/CLONE61/p1796_r10_c61_f0.con does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN11/CLONE109/p1796_r11_c109_f0.con does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN15/CLONE57/p1796_r15_c57_f0.con does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN16/CLONE137/p1796_r16_c137_f0.con does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN16/CLONE42/p1796_r16_c42_f0.con does not exist ...
#PDB-ERROR: pdb file /home/server/FAHdata/PKNOT/PROJ1796/RUN17/CLONE193/p1796_r17_c193_f0.con does not exist ...							 #
##########################################################################

$MissingConList = "/home/server/FAHdata/PKNOT/1797.log";

#xtc file, tpr file variable
$DELTA_RESIDUES = 4;
$MAX_DISTANCE   = 6;

#variable for run, clone has empty pdf files

#read ZERO files
open(pdbList, '<', $MissingConList) || die "No pdb file";
while ($line = <pdbList>) {
    chomp($line);
    foreach ($line) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
    my @lines = split(' ', $line);
    $firstIndex = index($lines[3], '.con');
    $fileName = substr($lines[3], 0, $firstIndex);
    $pdb      = $fileName . '.pdb';
    $con      = $fileName . '.con';
    if (-e $pdb) {

        unless (-e $con) {
            find_native_contacts($pdb, $con, $DELTA_RESIDUES, $MAX_DISTANCE);
            print STDOUT "$con\n";
        }
    }
    else {
        print STDOUT "Non-pdb $pdb\n";
    }

}

#close Reading ZERO Files
close(pdbList) || die $!;

sub find_native_contacts {
    my ($pdbFile, $conFile, $DELTA_RES, $MAX_DIST) = @_;

    system("rm $conFile");

    # help to keep track the processing in stderr.log
    print STDOUT $pdbFile . "\n";
    my @data;
    my $totalRows;
    open(PDB, '<', $pdbFile) || die $!;
    while ($pdbline = <PDB>) {
        chomp($pdbline);
        foreach ($pdbline) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
        my @pdbTemp = split(' ', $pdbline);
        if ($pdbTemp[0] eq "ATOM") {    #condition for reading atoms in pdb file
            push(@data, \@pdbTemp);
            $totalRows++;
        }
    }
    close(PDB) || die $!;

    #compare distance between two atoms
    open(W, '>', $conFile) || die "Please give me output filename $!";
    for ($i = 0 ; $i < $totalRows ; $i++) {
        for ($j = $i + 1 ; $j < $totalRows ; $j++) {
            $deltaRes = abs($data[$j][4] - $data[$i][4]);

            # delta residues >=3 ... No: now we use only > and start at 4, so it's >= 5 now
            if ($deltaRes > $DELTA_RES) {
                $deltaX   = $data[$j][5] - $data[$i][5];
                $deltaY   = $data[$j][6] - $data[$i][6];
                $deltaZ   = $data[$j][7] - $data[$i][7];
                $distance = sqrt(($deltaX * $deltaX) + ($deltaY * $deltaY) + ($deltaZ * $deltaZ));

                # only keep it if it's < the desired cutoff ... default at 6.0 A
                if ($distance <= $MAX_DIST) {
                    print W $data[$i][1] . "\t" . $data[$i][2] . "\t" . $data[$i][3] . "\t" . $data[$i][4] . "\t\t";
                    print W $data[$j][1] . "\t" . $data[$j][2] . "\t" . $data[$j][3] . "\t" . $data[$j][4] . "\t\t" . $deltaRes . "\t";
                    printf W "%7.3f\n", $distance;
                }
            }
        }
    }
    close(W) || die $!;
}
print "Job is done\n";
