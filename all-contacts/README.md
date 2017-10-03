# All Atomic Contact Calculation

Order of execution

  1. Generate PDBs
  1. Check if the generated PDBs are ok
  1. Generate CONs, which requires the PDBs
  1. Check if the generated CONs are ok
  1. Concatenate (join) the generated CONs into one `.con` file

## `pdbs-make.pl`

```man
    pdbs-make.pl -h

    pdbs-make.pl <project_dir>

    pdbs-make.pl --l=<log_file>

    pdbs-make.pl --l=<log_file> --m=<number_of_max_pdb>

    Run this script in the same location as the PROJ* directories. And don't
    forget the good old "usegromacs33" (or similar) before running the
    script!

    Additionally overwrite aminoacids.dat with aminoacids-NA.dat so that
    Gromacs tools can recognize RNA molecules.

    Progress is printed to an output log file (make_FAH-PDBs_PROJ*.log).

    --logfile, -l <log_file>
        If specified will generate PDBs for frames listed in this file only.
        All existing PDBs are removed before new ones are generated.

    --remove-existing
        Used together with --logfile. If specified will remove all existing
        PDBs. This option is ignored if a log file is not specified.

    --dry-run
        When specified, no files would be created/modified.

    --pdbmax, -p <num>
        If specified will process this number <num> of PDBs only. Default to
        100,000,000.

    --help, -h
        Print this help message.
```

## `pdbs-check.pl`

```man
    pdbs-check.pl -h

    pdbs-check.pl <project_dir>

    pdbs-check.pl <project_dir> --logfile=<log_file>

    Run this script in the location of the F@H PROJ* directories. After
    running, grep resulting log file (check_FAH-PDBs_PROJ*.log) for "WRONG",
    "ZERO", and "NOT" to look for bad or missing PDBs.

    --logfile, -l <log_file>
        Path to an input logfile. When specified only check the PDBs whose
        project, run, clone, and time (ps) listed in the logfile.

    -h, --help
        Print this help message.
```

## `cons-make.pl`

```man
    cons-make.pl <project_dir> -a=<max_atomic_distance> -r=<min_residue_separation>

    Find atom-to-atom contacts where delta residue >= <min_residue_separation>
    and atomic distance <= <max_atomic_distance>. Prints out to individual con
    files, run cons-join.pl to concatenate them. Progress is printed to an output
    log file (make_FAH-CONs_PROJ*.log).
```

## `cons-check.pl`

```man
    cons-check.pl <project_dir>

    cons-check.pl <project_dir> [--logfile|-l=<logfile.log>]

    Run this script in the location of the F@H PROJ* directories. After
    running, grep resulting log file (check_FAH-CONs_PROJ*.log) for "NOT" to
    look for missing .con files.
```

## `cons-join.pl`

```man
    cons-join.pl <project_dir> --output=<output.con>

    It is recommended to include Max_Distance_In_A and Min_Delta_Residues
    values used in cons-make.pl in the output filename.
```