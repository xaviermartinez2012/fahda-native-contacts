# fahda-native-contacts

Native contact calculations for Folding@Home datasets

## Git Clone Instructions

```bash
git clone https://github.com/sorinlab/fahda-native-contacts
cd fahda-native-contacts
git submodule init
git submodule update
```

## Prerequisites 

Use `cpan` or `cpanm` as root to install the following CPAN packages before running the scripts.

```bash
sudo cpan <package>

# or

sudo cpanm <package> #recommended
```

* [Sort::Natural::Key](https://metacpan.org/pod/Sort::Key::Natural)

## All Atom-to-atom Contact Calculations

Calculate all atom-to-atom contacts given a maximum atomic distance (in Angstrom) and residue separation. Output: a concetenated `.con` file.

See [all-contacts/README.md](all-contacts/README.md) for details on how to run the scripts.

## Native Contact Calculations

TODO: More info here ([more details](native-contacts/README.md))

## Native Contact Normalization

TODO: More info here ([Percent Native Contact](http://folding.cnsm.csulb.edu/wiki/index.php/Percent_Native_Contact))
