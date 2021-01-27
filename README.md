# CESM-Builds
 Source Code and Use Instructions for CESM on Scinet's Niagara. The files include options for porting both major release versions of CESM (1 and 2), but the information below only documents porting and setting up CESM2. Information regarding CESM1.2.2 will be updated in the future

# Source Code and Picking a Particular Version
I'm just going to be discussing running/modifying the model version that's already sitting in my home directory, as it's been modified accordingly for Niagara specifically.

### Getting the Source code from NCAR and the Niagara specific configuration files from this github
Download the model source code from NCAR directly:

```
git clone -b release-cesm2.1.3 https://github.com/ESCOMP/cesm.git
```

move into the ```cesm_sandbox``` folder that was just downloaded and run the checkout externals command to get the component specific source code (land, atmosphere, sea ice, ocean, etc). Make sure subversion is loaded before checkout (```module load subversion```)

```
cd cesm_sandbox
./manage_externals/checkout_externals
```

Now You've got a full copy of the model (minus the input data). All that's left is to access the Niagara specific .xml files in this repository and replace the ones sitting in your cesm_sandbox directory. I'd reccomend renaming your directory into whichever CESM2 version you're using (e.g. ```cesm2_1_3```)

```
git clone https://github.com/JohnVirgin/CESM-Builds/Niagara/cesm2_1_3_xml
```

These three .xml files- ```config_compilers.xml```, ```config_machines.xml```, and ```config_batch.xml```- set CESM's compilers, software modules, and the SLURM batch submission system specifically for Niagara. Three files of the same names should be sitting in:

```
$HOME/cesm2_1_3/cime/config/cesm/machines
```

Replace those default files with the ones from this repository. You'll need to make some modifications to ```config_batch.xml``` that specify user specific SLURM batch directives. You're account allocation needs to be changed accordingly, and your mail-user email address does as well, otherwise every submitted CESM job will send its updates to my email.

Lastly, with regards to software modules loaded in (see ```config_machines.xml```), the current modules loaded for running CESM are sourced from Niagara's 2018a default software stack (```NiaEnv/2018a```). This software stack is outdated, and when loaded will echo a statement to reflect that the current default stack, which was preloaded when you sign in, has been swapped out. This print statement will causes errors during the CESM configuration process. To get around this, you need to modify your ```.modulesrc``` file in your ```$HOME``` to automatically swap out the current software stack for ```NiaEnv/2018a```. Open up that file and add:

```
module-version NiaEnv/2018a default
```

This should prevent issues when CESM needs to be built, setup, and ran. It will also remove any issues with running CESM when Scinet decides to change the default software stack.

# Running the Model (Quickstart version)
Running the model consists of four mandatory steps, with an number of options in between to modify a given case with your own desired specifications. Steps as follows are:

```
./create_newcase
./case.setup
./case.build
./case.submit
```

### Creating a new case

```cd``` into ```cesm2_1_3/cime/scripts/``` and you'll see an executable file, ```create_newcase```. Execute this with some arguments to initiate a particular CESM experiment. A few mandatory ones are:

```
--case
```

Specific location of where your case will be created. I have two folders for this, one in my home directory and one in my scratch directory. Regardless of where you put it, the .xml files we're using are configured to automatically file all compiling, archiving, and setup output into your scratch directory. I suggest putting newly created cases in your scratch directory for now, because submitted batch jobs using SLURM refuse to write into your home directory (home directory is read only from the persepctive of a compute node). You might get some issues if a log file is created during your run and it happens to be sitting in your ```$HOME```.

Do all your building, compiling, running, and everything else out of scratch. When you're all finished, move the case directory you made back to your home to prevent it from being deleted due to inactivity.

```
--res
```

Specifies the resolution of the components being used in your build. What goes into this command depends on what component set you're picking. You can find a list of supported grids for CESM here: http://www.cesm.ucar.edu/models/cesm2/config/compsets.html. You can also use the  ```query_config``` tool in the same directory to view all grids available:

```
./query_config --grids
```

This tool can also be used to query available 'out of the box' component sets. Just change the grid arguement to compset.

```
--compset
```

Specifies the components going into your build. This option is actually typically used as a shortcut. Compsets that are more common have 'short names' that'll save you from typing out which specific CAM, CLM, POP, etc models you'd like to include here. You can find a list of supported CESM2 compsets here: http://www.cesm.ucar.edu/models/cesm2/cesm/compsets.html. Some component sets haven't been scientifically validated by NCAR yet; get around this by adding ```--run-unsupported``` to the end of the line.

```
--mach
```

Specifies the machine you're running on so CESM knows where to get its modules, compilers, and figure out what batch system we're working with. For us, this is always ```niagara```.

```
--user-mods-dir
```

Some presets for specific experiments (i.e. compsets) have issues with available input data. An Example: The B-compset (fully coupled) historical experiment (BHIST) with a 2 degree atmosphere grid specifies a nitrogen deposition .nc file for use with CLM that will break the model at runtime. To get around this, you have to modify the list of input data files your experiment will use. Most of the time this is done during the setup process, but you can also create a user modification directory that is filled with specific changes for a given compset to expedite the process. During the case creation, specify this 'user-mods' directory with the command above and it'll pull all the files from it and add them to your ```$CASEROOT```. I've taken the liberty of creating user modifications for a few compsets and added the files here. By default, the usermods-dir with CESM2 is located in ```$HOME/cesm2_1_3/cime_config/```.


Here's a quick example of a test case I setup and ran:

```
./create_newcase --case $SCRATCH/CESM_Cases/b.e21.B1850.f19_g17.JGV.TestCase.1 --res f19_g17 --compset B1850 --mach niagara
```
The nomenclature I used for the case directory name follows the accepted conventions from NCAR's website: http://www.cesm.ucar.edu/models/cesm1.0/casename_conventions_cesm.html

### Pre Case Setup
Prior to setting up your case after its creation, you'll want to make any load balancing (modifying node and CPU allocations to individual model componenets) changes, or any changes to the model source code. Modification of nodes and CPU allocation to individual model components is done within ```env_mach_pes.xml``` file. Additionally, making modifications to the individual CESM components is done in the ```SourceMods/``` directory. 

### Setup the new case
Head on into the case directory you just made and take a look at all the newly created files. The next step is to setup your case. Execute this option to set up your run directory (which should be in your ```$SCRATCH```). It will also give you a bunch of user-changeable namelist files, where you can specify the modified and new variables that you want the model to output. There's a single namelist file for each model component, and they have naming syntax like ```user_nl_xxx```. Where the `xxx` is replaced with a given model. Lastly, this command also creates hidden files that specify batch information for SLURM You can make your changes to the .xml files we're about to talk about either before or after you run the case setup. If you've specified a user modification during the case creation, the ```user_nl_xxx``` files will already exist in your ```$CASEROOT```.

### Build the new case
A lot of case-specific changes will be made just before you build your case:

- [ ] All additions to your namelist variables - ```user_nl_$model```, will be made here. I'll include more information on modifying these below, but it's not important for the (not-so) quick start version.
- [ ] Changes to batch submission options.
- [ ] Changes to run length and run history time-steps.
- [ ] Changes to physics, chemistry, and parameterization schemes.

A few important things to note:
- A lot of the batch submission, run length, and run options are configured in the .xml files that are sitting in your case directory. Now, you can go into each one and manually change things. But NCAR advises against that because the chance of error goes up. Their work around is to include to executable files to make your life easier- ```./xmlchange``` and ```./xmlquery```.
- You can ```./xmlquery``` a variable in ANY .xml file in the directory, and it'll return its value/string.
- You can ```./xmlchange``` any of these variables by specifying the name and what you're changing it to.

There are a few variables you'll find you'll be changing pretty much any time you run the model, listed below:
- STOP_OPTION: Indicates timestep for restart files. Alternatively defined, It's the time units of your run length. This variable is located within ```env_run.xml```
  - ```ndays```,```nmonths```,```nyears```.
- STOP_N: Integer for the number of STOP_OPTION steps to run the model for. Default for this is ```5```, with the default STOP_OPTION is ```ndays```. As such, Running the model from default only takes 5 days. This variable is located in ```env_run.xml```
  - ```int```
- JOB_WALLCLOCK_TIME: Indicates how long your run will compute on the nodes you've allocated. The model will default to the max amount of time allowed on Niagara, which is 24 hours. This'll throw you a warning, though. Format for the string is ```Hours:Minutes:Seconds```. This variable is located in ```env_batch.xml```.
  - ```H:M:S``` (e.g.```5:00:00``` is 5 hours of runtime)
- RESUBMIT: Sets the number of times to resubmit the run. Since Niagara only allows 24 hours per job, you have to set the model to resubmit and initialize from a restart file whenever the job's allocated time ends.
  - ```int```
- CONTINUE_RUN: This is a boolean value that indicates whether or not to continue the run from some initialized case that you never finished. Note that if you start a run from the beginning and set the resubmit to some arbitrary number, ```CONTINUE_RUN``` will automatically swap from ```FALSE``` to ```TRUE``` after the first resubmission.
  - ```FALSE``` or ```TRUE```
- RUN_TYPE: Indicates the type of run being executed. Options reflect running from scratch and running from some reference point. The differences and guides for each of these run types can be found in the Basic_Mods slide deck in the NCAR tutorial.
  - ```startup```, ```hybrid```, and ```branch```

There's many more; open the the ```env``` files to get a full look. One other thing to note: The default model output is set to spit out monthly data, so if you run a case from the default configuration (5 days), it won't give you any model output. If you want it to give you daily data, you need to do this on a per variable basis through the namelist files.

time to run  ```./case.build``` !

This not only compiles the model, but generates namelists and places them in the ```Buildconf``` directory, and then checks to see if the necessary input data is available. You can do both of these tasks separately if you like to ensure you have the data you need beforehand (since building takes a while). Use ```./preview_namelists``` to generate namelists and ```user_nl_xxx``` files, and use ```./check_input_data --download``` to download any missing data.

### Submitting the new case
Once you're ready to submit, you can execute the ```./case.submit``` command, for which it'll give you all the SLURM batch specifics. This executable file is just a wrapper for the hidden file ```.case.run```, which is the actual shell script that submits via slurm. Note that, while you could open the .run file and make changes to slurm directives, it's not advised to make changes to the number of nodes or tasks, as these would then conflict with the node distribution for each model component specified in ```env_mach_pes.xml```, which is generated during the case creation. If you want to modify the processor allocation, do so before ```./case.setup```.

# Input Data
The full input dataset for CESM2 is over 20 Terabytes in size. As a result of this size, individual cases you create will only download what's necessary to successfully run the simulation. Moreover, the ```config_machines.xml``` file from here specifies the location of all input data. In order to preserve space, I've hardcoded my specific ```$SCRATCH``` directory (```/scratch/c/cgf/jgvirgin/cesm2_1_3/inputdata/```) to avoid duplicates of data downloading.

# Namelist Modifications
To be updated.