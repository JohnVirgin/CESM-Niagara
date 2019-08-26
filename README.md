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

Pop into ```cesm2_1_0/cime/scripts/``` and you'll see an executable file, ```create_newcase```. Execute this with some parameters to initiate a particular CESM experiment. A few mandatory options:

```
--case
```

Specific location of where your case will be created. I have two folders for this, one in my home directory and one in my scratch directory. Regardless of where you put it, the .xml files we're using are configured to automatically file all compiling, archiving, and setup output into your scratch directory. My advice? Put newly created cases in your scratch directory for now, because submitted batch jobs using SLURM refuse to write into your home directory (i.e. the home directory is read-only from the eyes of a compute node on niagara). You might get some issues if a log file is created during your run and it happens to be sitting in your $HOME.

Do all your building, compiling, running, and everything else out of scratch. When you're all finished, move the case directory you made back to your home to prevent it from being deleted due to inactivity.

```
--res
```

Specifies the resolution of the components being used in your build. What goes into this command depends on what component set you're picking. You can find a list of supported grids for CESM here: http://www.cesm.ucar.edu/models/cesm1.0/cesm/cesm_doc_1_0_4/a3714.html (I know, it's CESM1, but the majority of these are the same for CESM2).

```
--compset
```

Specifies the components going into your build. This option is actually typically used as a shortcut. Compsets that are more common have 'short names' that'll save you from typing out which specific CAM, CLM, POP, etc models you'd like to include here. You can find a list of supported CESM2 compsets here: http://www.cesm.ucar.edu/models/cesm2/cesm/compsets.html. One of the caveats of using CESM2 is that there isn't actually that many scientifically validated compsets that exist yet. The lack of testing can sometimes result in linux throwing you an error, because it won't allow you to create a case that hasn't been validated. Get around this by adding ```--run-unsupported``` to the end of the line.

```
--machine
```

Pretty straightforward; specifies the machine you're running on so CESM knows where to get its modules, compilers, and figure out what batch system we're working with. For us, this is always ```niagara```.

Here's a quick example of a test case I setup and ran:

```
./create_newcase --case $SCRATCH/CESM_Cases/b.e21.B1850.f19_g17.JGV.TestCase.001 --res f19_g17 --compset B1850 -machine niagara
```
The nomenclature I used for the case directory name follows the accepted conventions from NCAR's website: http://www.cesm.ucar.edu/models/cesm1.0/casename_conventions_cesm.html

### Setup the new case
Head on into the case directory you just made and take a look at all the goodies in there. The next step (if you want) is to setup your case. Execute this option to set up your run directory (which should be in your $SCRATCH). It will also give you a bunch of user-changeable namelist files, where you can specify the modified and new variables that you want the model to output. There's a single namelist file for each model component, and they have naming syntax like ```user_nl_xxx```. Where the `xxx` is replaced with a given model. Lastly, this command also creates hidden files that specify batch information for SLURM. I typically run ```./case.setup``` immediately after I create a new case. You can make your changes to the .xml files we're about to talk about either before or after you run the command.

### Build the new case
A lot of case-specific changes will be made just before you build your case:

- [ ] All additions to your namelist variables - ```user_nl_$model```, will be made here. I'll include more information on modifying these below, but it's not important for the (not-so) quick start version.
- [ ] Changes to batch submission options.
- [ ] Changes to run length and run history time-steps.
- [ ] Changes to physics, chemistry, and parameterization schemes.

I won't dive into a lot of these right now, but a few important things to note:
- A lot of the batch submission, run length, and run options are configured in the .xml files that are sitting in your case directory. Now, you can go into each one and manually change things. But NCAR advises against that because the chance of error goes up. Their work around is to include to executable files to make your life easier- ```./xmlchange``` and ```./xmlquery```.
- You can ```./xmlquery``` a variable in ANY .xml file in the directory, and it'll return its value/string.
- You can ```./xmlchange``` any of these variables by specify the name and what you're changing it to.

There are a few variables you'll find you'll be changing pretty much any time you run the model, listed below:
- STOP_OPTION: Indicates timestep for restart files. Alternatively defined, It's the time units of your run length
  - ```ndays```,```nmonths```,```nyears```.
- STOP_N: Integer for the number of STOP_OPTION steps to run the model for. Default for this is ```5```, with the default STOP_OPTION is ```ndays```. As such, Running the model from default only takes 5 days.
  - ```int```
- JOB_WALLCLOCK_TIME: Indicates how long your run will compute on the nodes you've allocated. The model will default to the max amount of time allowed on Niagara, which is 24 hours. This'll throw you a warning, though. Format for the string is ```Hours:Minutes:Seconds```.
  - ```H:M:S``` (e.g.```5:00:00``` is 5 hours of runtime)
- RESUBMIT: Sets the number of times to resubmit the run. Since Niagara only allows 24 hours per job, you have to set the model to resubmit and initialize from a restart file whenever the job's allocated time ends.
  - ```int```
- CONTINUE_RUN: This is a boolean value that indicates whether or not to continue the run from some initialized case that you never finished. Note that if you start a run from the beginning and set the resubmit to some arbitrary number, ```CONTINUE_RUN``` will automatically swap from ```FALSE``` to ```TRUE``` after the first resubmission.
  - ```FALSE``` or ```TRUE```
- RUN_TYPE: Indicates the type of run being executed. Options reflect running from scratch and running from some reference point. The differences and guides for each of these run types can be found in the Basic_Mods slide deck in the NCAR tutorial.
  - ```startup```, ```hybrid```, and ```branch```
