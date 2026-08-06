# Scripts CD-CT

Scripts for Continuos Deployment & Continuous Testing for MONAN (Model for Ocean-laNd-Atmosphere PredictioN).

## Get Started

**Getting the scritps:**

```
$ git clone https://github.com/monanadmin/scripts_CD-CT.git
$ cd scripts_CD-CT/scripts
```

### 1. Install the model and configuring the execution mode (Global or Regional):

- First, you need to fork the official MONAN repository into your GitHub account. For detailed instructions, see [Creating a MONAN‐Model Fork](https://github.com/monanadmin/MONAN-Model/wiki/Creating-a-MONAN%E2%80%90Model-Fork).
- Then, you can install the model in your working directory (lustre or beegfs) by running:

~~~
./1.install_monan.bash <https://github.com/MYUSER/MONAN-Model-My-Fork.git> <tag_or_branch_name_MONAN-Model> <tag_or_branch_name_Convert-MPAS>
~~~
Default values:
~~~
<tag_or_branch_name_MONAN-Model> = "2.0.0-rc"
<tag_or_branch_name_Convert-MPAS> = "1.2.0"
~~~

**Note:** To simply run the official version of the MONAN repository, you only need to enter the URL `https://github.com/monanadmin/MONAN-Model.git` instead of the URL of your fork.

Example:
~~~
$ ./1.install_monan.bash https://github.com/monanadmin/MONAN-Model.git 2.0.0-rc 1.2.0
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
- `scripts/namelists` directory contains all versioned namelists needded for run and compile all phases of model;
- `scripts/stools` directory contains template scripts for execution on SLURM and PBS, and scripts for the operation of the PBS_Intel, PBS_GNU, and PBS_Cray environments.
- `sources` folder will contain all codes of any processes that uses compiled programming languages, such as MONAN model sources, convert_mpas sources, etc.
- `execs` folder will contain all the executables needed;
- `datain` folder will contain all the input data that the model need to run;
- `dataout` folder will contain all the output files generated of running of the MONAN, such as:
     - `dataout\Pre\<YYYYMMDDHH>` will contain all the output files from the pre-processing phase, mostly are all the initial condition for run the MONAN;
     - `dataout\Model\<YYYYMMDDHH>` will contain all the output files from the MONAN model;
     - `dataout\Post\<YYYYMMDDHH>` will contain all the output files from the post-processing phase of the MONAN;

After running the first step, it will clone the MONAN model from your fork repo in a `sources` diretory.

**Configuring the execution mode (Global or Regional):**

The default execution mode is "Global", to set the execution mode to "Regional" (limited-area), follow these steps:

```
$ vi scripts/setenv.bash
(...)
MODERUN=R      | R=Regional simulation and G=Global simulation.
LBCINT=10800   | Option: nterval (seconds) for updating lateral boundary conditions (when regional mode).
```
After this change, you must specify the regional grid in the `RESOLUTION` parameter during the subsequent steps (2, 3, and 4) described below.

Currently, the available regional options are:

```
655362.REG.AMS_CAR    => 30 km for South America and the Caribbean
5898242.REG.AMS_CAR   => 10 km for South America and the Caribbean
23592962.REG.AMS_CAR  => 5 km for South America and the Caribbean
```
For these meshes, the Scripts_CD-CT are configured to automatically set the appropriate CONFIG_DT (time step), as well as the LAT and LON values used by Convert_MPAS.


**Using custom regional (limited-area) meshes:**

- If you wish to use your own regional mesh, you must copy the "x1.your_mesh_file.grid.nc" and "x1.your_mesh_file.graph.info" files to the `datain/fixed` folder and create an "if-block" for the automatic configuration of `CONFIG_DT` in script "3.run_model.bash" (line 114), as well as for the "LAT" and "LON" settings used by "Convert_MPAS" in script "4.run_post.bash" (line 160).

**Attention!** When using "your_mesh_file", do not use the same identifier (the "RESOLUTION" parameter) as an existing global mesh. If the identifier is already in use, you must rename your mesh files to match the new identifier and use the new identifier in the "RESOLUTION" parameter.

- In the `RESOLUTION` parameter, pass only "your_mesh_file", without the "x1." prefix and the ".grid.nc" or ".graph.info" extensions. But "your_mesh_file" (in datain/fixed) needs the format: "x1.your_mesh_file.grid.nc" and "x1.your_mesh_file.graph.info".

For example, for "your_mesh_file":
```
x1.5898242_BRASIL.grid.nc
x1.5898242_BRASIL.graph.info
```
The `RESOLUTION` parameter should be set to: `5898242_BRASIL`

**ERA5 Simulation**

- To perform simulations using ERA5 data, you must set the `EXP` parameter to `ERA` in steps 2, 3, and 4 below.

- We do not yet have a centralized location with regular dates or a standardized naming convention for ERA5 files, as we currently do for GFS data. Therefore, you will need to copy the `.pl` and `.sl` files to the `datain/ERA` folder and rename them according to the following pattern:

```
era5.pl.YYYYMMDDHH.grib
era5.sl.YYYYMMDDHH.grib
```
Where: `YYYY=year; MM=month; DD=day and HH=hour`

### 2. Prepare the Initial Conditions for the model:

Just run the second script as follows:

~~~
2.pre_processing.bash EXP RESOLUTION LABELI FCST

where:

EXP         :: Initial or lateral boundary condition dataset (GFS or ERA)
RESOLUTION  :: Number of horizontal grid cells (global) or regional mesh identifier (e.g., 1024002 for the ~24 km mesh)
LABELI      :: Forecast initialization date and time (YYYYMMDDHH), e.g., 2026080100
FCST        :: Forecast length in hours (e.g., 24, 36, 48, etc.)

~~~
Example of a 24-hour forecast:

~~~
./2.pre_processing.bash GFS 1024002 2026080100 24
~~~

**Note:** For regional runs, initial condition files must be available, along with the first forecast or analysis file. The remaining files required for the lateral boundary conditions are determined by the interval specified by LBCINT and the forecast length specified by FCST.

### 3. Run the model:

Execute the 3rd step script:

~~~
3.run_model.bash EXP RESOLUTION LABELI FCST

where:

EXP         :: Initial or lateral boundary condition dataset (GFS or ERA)
RESOLUTION  :: Number of horizontal grid cells (global) or regional mesh identifier (e.g., 1024002 for the ~24 km mesh)
LABELI      :: Forecast initialization date and time (YYYYMMDDHH), e.g., 2026080100
FCST        :: Forecast length in hours (e.g., 24, 36, 48, etc.)

~~~
Example of a 24-hour forecast:

~~~
$ ./3.run_model.bash GFS 1024002 2026080100 24
~~~

### 4. Run the post-processing model:

Execute the step 4 script:

~~~
./4.run_post.bash EXP RESOLUTION LABELI FCST

where:

EXP         :: Initial or lateral boundary condition dataset (GFS or ERA)
RESOLUTION  :: Number of horizontal grid cells (global) or regional mesh identifier (e.g., 1024002 for the ~24 km mesh)
LABELI      :: Forecast initialization date and time (YYYYMMDDHH), e.g., 2026080100
FCST        :: Forecast length in hours (e.g., 24, 36, 48, etc.)

~~~
Example of a 24-hour forecast:
~~~
$ ./4.run_post.bash GFS 1024002 2026080100 24
~~~

### Plus: The "0.run_all.bash" script

This script automates the steps required to run MONAN.

The logic consists of removing or adding comments at the corresponding steps, as needed.

```
$ cd scripts
$ vi 0.run_all.bash

(...)
# Input variables:-----------------------------------------------------
github_link="https://github.com/monanadmin/MONAN-Model.git"   # Switch to your fork when you need to make changes or develop the model.
monan_branch=2.0.0-rc
convertmpas_branch=1.2.0
EXP=GFS                    # Options: GFS or ERA
RES=1024002                # Options-Global: 40962=120km; 163842=60km; 655362=30Km; 1024002=24km; 2621442=15Km; 5898242=10Km
                           # Options-Regional: 655362.REG.AMS_CAR=30km; 5898242.REG.AMS_CAR=10km; 23592962.REG.AMS_CAR=5km
YYYYMMDDHHi=2026080100     # Check the available dates for the initial and boundary conditions (regional), especially for ERA5 data.
FCST=24
#----------------------------------------------------------------------

# STEP 1: Installing and compiling the A-MONAN model and utility programs:
time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
#exit

# STEP 2: Executing the pre-processing fase. Preparing all CI/CC files needed:
time ${SCRIPTS}/2.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 3: Executing the Model run:
time ${SCRIPTS}/3.run_model.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit

# STEP 4: Executing the Post of Model run:
time ${SCRIPTS}/4.run_post.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
#exit
```

Example:
```
./0.run_all.bash
```

## History

**1.6.0**

- Added support for MONAN regional (limited-area) simulations.
- Added support for initializing simulations from ERA5 data.

**1.5.0**
- Updated the workflow for full compatibility with MONAN 2.0.0, including support for the Noah-MP land surface model and the UGWP parameterization.
- Updated the pre-processing, execution, and post-processing scripts, including the required static files, streams, and namelist configurations.
- Added new diagnostic variables for accumulated surface fluxes and optimized the generation of the "MP_THOMPSON_*_DATA.DBL" tables by creating them only during the first pre-processing execution, while integrating the build_tables step into the workflow.
- Improved the compilation environment with support for the NVIDIA NVHPC compiler.

**1.4.1**
- Compatibility with MONAN 1.4.4, including support for the new cold-start flags in namelist.atmosphere.TEMPLATE: config_coldstart_substeps and config_coldstart_steps_to_substep.
- Updated config_smdiv to 0.15 in namelist.atmosphere.TEMPLATE.
- Adjusted permissions for log files and included the job ID in output filenames.
- Commented out the MPICH REPORT section in the stools files.
- Added support for the Cray compiler.

**1.4.0**
- Compatibility with MONAN 1.4.3-rc.
- Support for multi-environment: 'Jaci' supercomputer (intel and gnu compilers and PBS scheduler) and 'Egeon' cluster (gnu compiler and SLURM scheduler).

**1.3.0**
- This version was created to work in operational runs.
- Adjusted to run using 16 nodes and 1024 cores.
- Operational vars (cldfrac_tot_UPP, ter, landmask, and omega) table is also in this version.
- Add flags for ~10Km mesh resolution.

**1.2.0**
- This version should work only with MONAN-Model 1.3.1/ (3D native model variables)
- Was added some warnings to users regarding the choice of MONAN-Model versions versus scripts_CD-CT versions:
- scripts_CD-CT versions up to 1.1.0 run MONAN-Model only versions up to 1.3.0
- scripts_CD-CT versions 1.2.0 onwards run MONAN-Model only versions 1.3.1 onwards
- 
**1.1.0**
- Fixed `model.bash` script to check generated files with flexible output_interval field (no longer with constant 3h).
- Now it is possible to run all 4 phases with 00z, 06z, 12z and 18z.
- Namelist `namelist.atmosphere.TEMPLATE` was updated to work with MONAN-Model version 1.3.0/, especific `convection_permitting_monan` phisic suite.

**1.0.1**
- Fixing nIsobaricLev(22) in convert_mpas.nml and config_dt(15000) in run_model script.

**1.0.0**
- Changing integration method (3rd Rung-Kutta), time step (150s), nlat and nlon for post processing at 15km and minor adjustments.
- adding configurations for 15km.
- correction on logic of how many submiting will be computed if nfiles were little then maxpostpernodes.
- new parallel post.
- Target_domain values have been fixed.
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

