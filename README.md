# CESM-Builds
 Source Code and Use Instructions for CESM on Scinet's Niagara, as well as macOS for the bold and brave souls looking to run the single column version of the model (SCAM)- CFG Edition brought to you by Jack, with some help from Haruki over at U of T

# Source Code and Picking a Particular Version
I'm just going to be discussing running/modifying the model version that's already sitting in my home directory, as it's been modified accordingly for Niagara specifically. However, I'll also throw in some comments on acquiring your own model version, with some helpful links and slides. Eventually, I'll get the single column model up and running on my mac and I'll add all of that data and scripts here.

### Pre-configured version from my home directory (CESM2.1.0)
Log into scinet and pop over to my home directory:

```
cd /home/c/cgf/jgvirgin
```
You should see a directory labelled ```cesm2_1_0```, which is the version of CESM2 that's configured for use on Niagara. Copy that directory over to your home directory. If you don't have permissions, see the alternative below

### Getting the Source code from NCAR and the Niagara specific configuration files from this github
If permissions aren't allowing you to steal the ```cesm2_1_0``` directory from my home folder, you can download the model source code from NCAR directly:

```
git clone -b release-cesm2.1.0 https://github.com/ESCOMP/cesm.git
```

move into the ```cesm``` folder that was just downloaded and run the checkout externals command to get the component specific source code (land, atmosphere, sea ice, ocean, etc):

```
cd cesm
./manage_externals/checkout_externals
```

NOTE: ```./manage_externals/checkout_externals``` will only work if you have the subversion software loaded into your current session. If you haven't done that prior to downloading, fire this command off:

```
module load subversion
```

Now You've got a full copy of the model (minus the input data, but we'll get to that later). All that's left is to snag the Niagara specific .xml files in this repo and replace the ones sitting in your ```cesm2_1_0``` directory.

```
git clone https://github.com/JohnVirgin/CESM-Builds/Niagara/cesm2_1_0_xml
```

These three .xml files- config_compilers, config_machines, and config_batch- configure CESM's compilers, hardware specifics, and SLURM batch submission system specifically for Niagara. Three files of the same names should be sitting in:

```
~/cesm2_1_0/cime/config/cesm/machines
```

Replace those default files with the ones from this repo, and you should be good to go.


### Getting the Source code for the Single Column Atmosphere Model (SCAM) from NCAR and the macOS configuration files from this Github
To be updated in the future


# Running the Model (Quickstart version)
Running the model consists of four mandatory steps, with an unlimited number of options in between to modify a given case with your own desired specifications. Steps as follows are:

```
./create_newcase
./case.setup
./case.build
./case.submit
```

### Creating a new case
