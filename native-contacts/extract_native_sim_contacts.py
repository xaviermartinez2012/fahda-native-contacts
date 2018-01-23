#!/usr/bin/env python3

import argparse
import os


def valid_file(path):
    ''' Check the existence of a file. Used in conjunction with argparse
    to check that the given parameter files exist.'''
    if not os.path.isfile(path):
        raise argparse.ArgumentTypeError(
            '\"{}\" does not exist (must be in the same directory or '
            'specify full path).'.format(path)
        )
    return path


def parse_native_sims_file(nst_path):
    ''' Extract native sims from .nst file.'''
    native_sims = {}
    with open(nst_path, mode='r') as nst_file:
        lines = nst_file.readlines()
        for line in lines:
            # line => <Project> <Run> <Clone> <Time>
            if line.startswith('#'):
                continue
            project_number, run_number, clone_number, _ = line.strip().split()
            native_sims['p{}_r{}_c{}'.format(
                project_number, run_number, clone_number)] = 1
    return native_sims


def extract_native_sims_contacts(jcon_path, native_sims_dict, out_path):
    '''Extract native contacts'''
    with open(jcon_path, mode='r') as jcon_file:
        try:
            with open(out_path, mode='w') as out_file:
                jcon_file_lines = jcon_file.readlines()
                for line in jcon_file_lines:
                    prc, frame_number = line.strip().split("_f")
                    if prc in native_sims_dict and frame_number != '0.con':
                        out_file.write('{}'.format(line))
                print("Writing out results to {}.".format(out_path))
        except EnvironmentError as env_error:
            print(env_error.strerror)

# Initialization of the argument parser.
PARSER = argparse.ArgumentParser(
    description='Collect all contacts from native simulations.',
    epilog="Python3 rewrite of Khai's extract-native-sim-contacts.pl script.\n"
    "Written by Xavier Martinez on January 22nd, 2018.",
    formatter_class=argparse.RawTextHelpFormatter)
PARSER.add_argument('nst', type=valid_file, help='<native_sims.lst>')
PARSER.add_argument('jcons', type=valid_file, help='<joined_cons.con>')
PARSER.add_argument('outcon', help='<out.con>')
ARGS = PARSER.parse_args()
NST = ARGS.nst
JCONS = ARGS.jcons
# "Main"
print("Parsing {}".format(NST))
NATIVE_SIMS_DICT = parse_native_sims_file(ARGS.nst)
print("Extrating native sim contact data from {}".format(JCONS))
extract_native_sims_contacts(ARGS.jcons, NATIVE_SIMS_DICT, ARGS.outcon)
print("Done!")
