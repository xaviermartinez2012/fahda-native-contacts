# fahda-native-contacts

Native contact calculations for Folding@Home datasets

## Download

The scripts can be downloaded from [here](https://github.com/sorinlab/fahda-native-contacts/archive/master.zip).

You can also use the `git clone` command.

```bash
git clone https://github.com/sorinlab/fahda-native-contacts
git submodule init
git submodule update
```

## RMSD & Rg calculation

Calculate RMSD & Rg for each frame in all simulations and output to logfile. The script will not regenerate the `*.xvg` files if they already exist.

```bash
$ usegromacs33
$ ./calc-rmsd-rg.pl PROJ1797 index.ndx topol.gro output.log
$ head output.log
1797       0       1         0      0.034     11.335
1797       0       1       100      3.492     12.696
1797       0       1       200      3.266     12.475
1797       0       1       300      3.324     12.576
1797       0       1       400      3.330     12.642
...
```

## All Atom-to-atom Contact Calculation

Calculate all atom-to-atom contacts given a maximum atomic distance (in Angstrom) and residue separation. Output: a concetenated `.con` file.

See [all-contacts/README.md](all-contacts/README.md) for details on how to run the scripts.

## Native Contact Calculation

TODO: More info here ([more details](native-contacts/README.md))

## Native Contact Normalization

TODO: More info here ([Percent Native Contact](http://folding.cnsm.csulb.edu/wiki/index.php/Percent_Native_Contact))
