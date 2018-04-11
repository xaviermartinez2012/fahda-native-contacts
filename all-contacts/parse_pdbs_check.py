#!/usr/bin/env python3

import argparse
import os

def valid_file(path):
    """ Function to check the existence of a file.
        Used in conjunction with argparse to check that the given parameter
        files exist.
    """
    if not os.path.isfile(path):
        raise argparse.ArgumentTypeError(
            '\"{}\" does not exist'.format(path) +
            '(must be in the same directory or specify full path).')
    return path

def parse_output(log_file_path, output_path):
    
    with open(log_file_path, mode='r') as log_file:
        lines = log_file.readlines()
        empty_clones = find_empty_clones(lines)
    with open(output_path, mode='w') as output_file:
        output_file.write('-- Clones without any .pdbs --\n')
        for clone in empty_clones:
            output_file.write('{}'.format(clone))
        output_file.write('-- Total Missing Empty Clones: {} --'.format(len(empty_clones)))
    

def find_empty_clones(lines):
    return [lines[(i - 1)].replace('Working on ', '').replace('...', '') for i in range(len(lines)) if 'No PDB found' in lines[i]]

if __name__ == '__main__':
    MODULE_DESCRIPTION = str("Parse the output from pdbs-check.pl.\n" +
                             "Written by Xavier Martinez on 4/9/18.\n"
                            )
    ARGUMENT_PARSER = argparse.ArgumentParser(description=MODULE_DESCRIPTION,
                                              formatter_class=argparse.RawTextHelpFormatter)
    ARGUMENT_PARSER.add_argument('log_file',
                                 type=valid_file,
                                 metavar='LOG_FILE',
                                 help='Path to the log file provided with pdbs-check.pl (usually named check_FAH-PDBs_PROJ<#>.log).')
    ARGUMENT_PARSER.add_argument('output',
                                 type=str,
                                 metavar='OUTPUT',
                                 help='Path for output log file provided with pdbs-check.pl (usually named check_FAH-PDBs_PROJ<#>.log).')
    
    ARGS = ARGUMENT_PARSER.parse_args()
    parse_output(ARGS.log_file, ARGS.output)
