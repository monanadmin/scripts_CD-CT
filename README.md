# MONAN - Model for Ocean-laNd-Atmosphere PredictioN

### *Continuous Deployment & Continuous Testing (CD-CT) for MONAN at Egeon*

This folder aims to create a version for testing MONAN with GFS at Egeon.

## History: ##

**1.0.0**
- Add copy configs files from convert_mpas to dataout/YYYYMMDDHH/Post/logs (MODEL config files and VERSION.txt also).
- fix in config_len_disp in script 3.run_model.bash .
- modifications in datain/namelists/namelist.atmosphere.TEMPLATE and 3.run_model.bash from Saulo's PR 8 .
 
**0.2.2**
- Fixed the value of config_bucket_update in namelist.atmosphere.
- Fixed module load in opengrads in setenv.

**0.2.1**
- Switch of configs (CONFIG_DT, CONFIG_LEN_DISP, target_domain, etc.) 120 and 24 km.
- Clean temporary outputs files option add in the 3.run_model.bash script.
- Verification if all the output files were created ok from model phase.

**0.2.0**
- Including copy of the GF_ConvPar_nml from model source to scripts folder.
- Changing physics suite to mesoscale_reference_monan.
- Changing the output model interval to 3h adjusting the post processing.
- Changing the radtlw and radtsw interval to 30m, and conv interval to 15m.

**0.1.1**
- Fixing bug on pressure levels description in post files
- Fixing variables name in post files

**0.1.0**
- Used parameterization to select the date for execution.
- Created cron script for daily executions.
- Post-processing is with the new version of convert_mpas, enabling the use of grads.
- Grouping all variables with one pressure level to only one variable with all levels.
- Defined default version of MONAN-Model (0.5.0) and convert_mpas (0.1.0) in the installation step.

### Implementation at Egeon:

**Getting the scritps:**

Cloning this repo: `git clone https://github.com/monanadmin/scripts_CD-CT.git`
you will get this directories:
~~~
datain/namelists
scripts
~~~

- The `datain/namelists` directory contains all versioned namelists needded for run and compile all phases of model;
- The `scripts` directory is the most important folder that contains all the scripts that you will need to install, compile, run, and produce produtcs of the A-MONAN model.


You will need to execute only 6 steps scripts, so you can run the Atmospheric MONAN Model:


**1. Install the model:**

- First you need to get a **fork repository** in your github account of a MONAN oficial repo: `https://github.com/monanadmin/MONAN-Model`. Attention! Uncheck "Copy the main branch only" in the fork creation step to copy all branches. 
- The you can install the model in your work directory by running:

~~~
./1.install_monan.bash <https://github.com/MYUSER/MONAN-Model-My-Fork.git> <OPTIONAL_tag_or_branch_name_MONAN-Model-My-Fork> <OPTIONAL_tag_or_branch_namer_Convert-MPAS>
~~~

Default values:
~~~
<OPTIONAL_tag_or_branch_name_MONAN-Model> = "1.0.0"
<OPTIONAL_tag_or_branch_name_Convert-MPAS> = "1.0.0"
~~~

- This first step will create a standart diretories structures for work:
~~~
scripts_CD-CT/
       scripts
       sources
       execs
       datain
       dataout
~~~

Where:
- `scripts` folder will contain all scripts produced to run all steps of the model;
- `sources` folder will contain all codes of any processes that uses compiled programming languages, such as MONAN model sources, convert_mpas sources, etc.
- `execs` folder will contain all the executables needed;
- `datain` folder will contain all the input data that the model need to run;
- `dataout` folder will contain all the output files generated of running of the MONAN, such as:
     - `dataout\Pre\<YYYYMMDDHH>` will contain all the output files from the pre-processing phase, mostly are all the initial condition for run the MONAN;
     - `dataout\Model\<YYYYMMDDHH>` will contain all the output files from the MONAN model;
     - `dataout\Post\<YYYYMMDDHH>` will contain all the output files from the post-processing phase of the MONAN;
     - `dataout\Prods\<YYYYMMDDHH>` will contain all the output files from the products generated, graphics, derivated variables, peace of domain, etc.

After running the first step, it will clone the MONAN model from your fork repo in a `source` diretory.


**2. Prepare the Initial Conditions for the model:**

- Just run the second script as follows:

~~~
2.pre_processing.bash EXP_NAME RESOLUTION LABELI FCST

EXP_NAME    :: Forcing: GFS
            :: Others options to be added later...
RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)
LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100
FCST        :: Forecast hours, e.g.: 24 or 36, etc.

24 hour forcast example:
./2.pre_processing.bash GFS 1024002 2024010100 24
~~~

**3. Run the model:**

- Execute the 3rd step script:

~~~
3.run_model.bash EXP_NAME RESOLUTION LABELI FCST

EXP_NAME    :: Forcing: GFS
            :: Others options to be added later...
RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)
LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100
FCST        :: Forecast hours, e.g.: 24 or 36, etc.

24 hour forcast example:
./3.run_model.bash GFS 1024002 2024010100 24
~~~

**4. Run the post-processing model:**

- Execute the 4th step script:

~~~
4.run_post.bash EXP_NAME RESOLUTION LABELI FCST

EXP_NAME    :: Forcing: GFS
            :: Others options to be added later...
RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)
LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100
FCST        :: Forecast hours, e.g.: 24 or 36, etc.

24 hour forcast example:
./4.run_post.bash GFS 1024002 2024010100 24
~~~
