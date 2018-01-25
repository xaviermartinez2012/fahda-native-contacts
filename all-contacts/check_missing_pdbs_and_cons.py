'''Module docstring...'''
import os
import re
import argparse


def valid_dir(path):
    '''Check the existence of a directory.'''
    # Used in conjunction with argparse to check that the given parameter
    # dataset exist.
    if not os.path.exists(path):
        raise argparse.ArgumentTypeError(
            '\"{}\" does not exist '
            '(must be in the same directory or specify full path).'.format(path))
    return path

# Initialization of the argument parser.
PARSER = argparse.ArgumentParser(
    description='Check for missing .pdb and .con files by testing for consecutive frames.',
    epilog="Written by Jennifer Nguyen & Xavier Martinez on January 24th, 2018.",
    formatter_class=argparse.RawTextHelpFormatter)
# Project directory is a required argument for program execution
PARSER.add_argument('projDirectory',
                    type=valid_dir,
                    help='Relative or absolute path to a PROJ<#> F@H data directory.\n'
                    'Ex:\n'
                    '   ../PROJ<#>- \n'
                    '              |\n'
                    '               - RUN0-\n'
                    '              .       |\n'
                    '              .        - CLONE0-\n'
                    '              .                 |\n'
                    '              .                  - p<#>_r0_c0.pdb\n'
                    '              |                  - p<#>_r0_c0.con\n'
                    '               - RUN1-\n'
                    '                      |\n'
                    '                       - CLONE0-\n'
                    '                                |\n'
                    '                                 - p<#>_r1_c0.pdb\n'
                    '                                 - p<#>_r1_c0.con\n'
                   )
ARGS = PARSER.parse_args()

PROJDIRECTORY = ARGS.projDirectory
NUMERRORS = 0
for dirPath, _, files in os.walk(PROJDIRECTORY):
    # If there are no files in the directory, then skip
    if not files:
        continue
    print('Working on {}'.format(dirPath))
    # Grabs all pdb files and put them in a list
    pdbFiles = [pdb for pdb in files if '.pdb' in pdb]
    conFiles = [con for con in files if '.con' in con]
    if not pdbFiles:
        print("[ERROR] No pdb files in {}".format(dirPath))
        NUMERRORS += 1
        continue
    else:
        pdbPrefix = re.sub(r'\d*\.pdb', '{}.pdb', pdbFiles[0])
        conPrefix = re.sub(r'.pdb', '.con', pdbPrefix)
    pdbFrameNumbers = list()
    for pdb in pdbFiles:
        match = re.findall(r'\d*\.pdb', pdb)
        pdbFrameNumbers.append(int(re.sub(r'.pdb', '', match[0])))
    sortedPdbFrameNumbers = sorted(pdbFrameNumbers)
    conFrameNumbers = list()
    for con in conFiles:
        match = re.findall(r'\d*\.con', con)
        conFrameNumbers.append(int(re.sub(r'.con', '', match[0])))
    sortedConFrameNumbers = sorted(conFrameNumbers)
    missingPdbFrames = [frame for frame in list(
        range(0, sortedPdbFrameNumbers[-1] + 1)) if frame not in sortedPdbFrameNumbers]
    missingConFrames = [frame for frame in list(
        range(0, sortedPdbFrameNumbers[-1] + 1)) if frame not in sortedConFrameNumbers]
    for frame in missingPdbFrames:
        print("[ERROR] Missing {}".format(pdbPrefix.format(frame)))
        NUMERRORS += 1
    for frame in missingConFrames:
        print("[ERROR] Missing {}".format(conPrefix.format(frame)))
        NUMERRORS += 1
print("Total errors: {}".format(NUMERRORS))
