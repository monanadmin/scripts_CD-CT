# Instructions for running the real-case global MONAN simulation

## 1) First steps in EGEON
To start our exercise, we first need to log in into EGEON and set up a conda environment, which will be needed to execute some of the steps in running a MONAN simulation.

### 1.1) Log in

In your terminal, write
```
ssh -Y $USER@egeon.cptec.inpe.br
```
entering in `$USER` the username you received from the organization team. You will then be prompted to give your password, which you should have received as well.

### 1.2) Load the anaconda module

Once you are in, load the anaconda module by
```
module load anaconda3-2022.05-gcc-11.2.0-q74p53i
```

### 1.3) Configure shell to use conda
Start with the command
```
conda init
```
Then, do
```
source ~/.bashrc
```

### 1.3) Make sure you have access to our conda environment

Write the command
```
conda config --add envs_dirs /pesq/share/monan/curso_OMM_INPE_2025/.conda/envs
```

### 1.4) Test if you can activate our conda environment

Write the command
```
conda activate vtx_env
```

If you see "(vtx_env)" in front of your username in the terminal, you're all set to start!

## 2) Cloning scripts repository
Our second step is to clone the repository `scripts_CD-CT`, which contains all the code needed to run a MONAN simulation.

### 2.1) Go to your work directory:
```
cd /mnt/beegfs/$USER
```
### 2.2) Clone the scripts repository:

```
git clone -b feature/scripts-849-NF https://github.com/guilhermeltm/scripts_CD-CT
```

## 3) Installing and compiling MONAN
Once you have cloned the repository, we can install and compile the model.

### 3.1) In your work directory, go to scripts_CD-CT/scripts:

```
cd scripts_CD-CT/scripts
```

### 3.2) Edit 0.run_all.bash:
The general script `0.run_all.bash` orchestrates all steps needed to run a simulation with MONAN. The first of these steps is the installation and compilation of the model. To execute it, open `0.run_all.bash` with the text editor vi:
```
vi 0.run_all.bash
```
### 3.3) Then, make sure the first code line in STEP 1 is not commented out:
```
time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
```
### 3.4) Now, make sure all the following code lines in STEP 1, 2, 3, 4, 5 are commented out:
```
#exit

# STEP 2: Generating mesh. Preparing all CI/CC files needed:
#time ${SCRIPTS}/2.create_mesh.bash
#exit

# STEP 3: Executing the pre-processing fase. Preparing all CI/CC files needed:time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} ${MESH}
#time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
#exit

# STEP 4: Executing the Model run:
#time ${SCRIPTS}/4.run_model.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES}
#exit

# STEP 5: Executing the Post of Model run:
#time ${SCRIPTS}/5.run_post.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES}
#$exit

#time ${SCRIPTS}/make_template.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
```
### 3.5) Now, save and exit the file in vi (command :wq), then run 0.run_all.bash to install and compile MONAN:
```
bash 0.run_all.bash
```

**Important**: When asked "Are you sure you are installing the right versions scripts x MONAN-Model ? [Y/n]", type Y!

## 4) Preparing your mesh

Now that you have installed and compiled the model, it's time to generate your mesh. This can be done by executing script 2.create_mesh.bash. But before doing that, we need to set up the  characteristics we want our mesh to have. This is done in mesh_input_file.txt, so we will start from there.


### 4.1) Edit mesh_input_file.txt:
```
vi mesh_input_file.txt
```

### 4.2) Substitute `$USER` by your username in the following places:
```
exp_dir=exp_dir=/mnt/beegfs/$USER/scripts_CD-CT/scripts
vtx_mpas_meshes_dir=/mnt/beegfs/$USER/scripts_CD-CT/sources/CGFD-USP-Create-Mesh/vtx-mpas-meshes
meshes_dir=/mnt/beegfs/$USER/scripts_CD-CT/datain/fixed
```

### 4.3) Set the mesh characteristics you'd like to have
```
## Coordinates of mesh center
lon=-55
lat=-35
## Inner and outer radius (km)
inner_radius=2000
outer_radius=2600
## Number of external layers for r > outer_radius
n_layers=8
## High resolution for r < inner_radius
high_res=50
## Low resolution for r > outer_radius
low_res=250
## Whether to cut regional mesh (y/n)
do_regional=n
## Grid type (doughnut/constant)
grid_type=doughnut
```

For our exercise, the relevant parameters are the following:

```
inner_radius=2000
outer_radius=2600
low_res=250
```
These parameters you can edit to create a personalized mesh. Please leave the remaining parameters as they are.

### 4.4) Generate the mesh
```
bash 2.create_mesh.bash
```
Note that in this section 4.4) we did not use the general script `0.run_all.bash`, which executes each of the MONAN simulation steps with their respective input arguments. We could have used it, but since `2.create_mesh.sh` has no input arguments (every input information is entered via `mesh_input_file.txt`), we can simply execute it directly via `bash 2.create_mesh.bash` as we do here.

### 4.5) Plot the generated mesh
We will now plot the generated mesh. To do that, first get the geographical files needed for the plot:

```
ln -s /pesq/share/monan/curso_OMM_INPE_2025/.local/share /home/$USER/.local/
```

Now, edit the file plot_mpas_grid.bash:
```
vi plot_mpas_grid.bash
```

In GFILEPATH, add the name of the mesh you just generated after ${DATAIN}/fixed/, for example:
```
## Grid file
GFILEPATH=${DATAIN}/fixed/lat_-35_lon_-55_oradius_2600_iradius_2000_margin_600_hres_50_lres_250.region.grid.nc
```

In POSTFILEPATH, add the directory you want to save the plot, for example:
```
## Output directory and filename to save plot
POSTFILEPATH=${DATAIN}/fixed/lat_-35_lon_-55_oradius_2600_iradius_2000_margin_600_hres_50_lres_250.region.grid.png
```

Save and exit (:wq) plot_mpas_grid.bash, then run the script:
```
bash plot_mpas_grid.bash
```

You may not be able to open the plot in EGEON. You can try by 

```
open /mnt/beegfs/$USER/scripts_CD-CT/datain/fixed/$MESH.grid.png
```
where in `$MESH` you use the name of your generated mesh (see `POSTFILEPATH` above).

If this does not work, you need to copy the plot to your local machine to then open it locally. This can be done by opening another terminal, then doing
```
scp $USER@egeon.cptec.inpe.br:/mnt/beegfs/$USER/scripts_CD-CT/datain/fixed/$MESH.grid.png .
```
where `$USER` is your username and `$MESH` the name of your mesh.

## 5) Preprocessing

Now it's time for preparing your simulation. This is done by 1) generating a "static file", which contains static fields to be used in the simulation (e.g. terrain height, vegetation characteristics, albedo); 2) processing real datasets to be used as initial conditions; 3) interpolating the initial conditions on the mesh and generating also a vertical grid. All of this is accomplished by script `3.pre_processing.bash`, so our goal in this section is to run that script, which is done again via the general script `0.run_all.bash`.

### 5.1) Edit 0.run_all.bash
We start by editing `0.run_all.bash`:
```
vi 0.run_all.bash
```

Here we will set the input variables for our simulation. In the section "Input variables" of the script, make sure the following is set:

```
github_link="https://github.com/monanadmin/MONAN-Model.git"
monan_branch=release/1.4.1-rc
convertmpas_branch=release/1.2.0
EXP=ERA5
YYYYMMDDHHi=2007062200
FCST=72
MESH=$MESH
RES=50 #3 # Minimum grid spacing (km)
```
where `$MESH` is the name of your mesh (**without the .grid.nc suffix!**)

For us the relevant variables are the following, for which we enter already the values as examples:
- EXP=ERA5, which is telling which dataset we will use for the simulation
- YYYYMMDDHHi=2007062200, which is telling the date and hour the simulation will start
- FCST=72, which is telling for how many hours we will run the simulation
- MESH=lat_-35_lon_-55_oradius_2600_iradius_2000_margin_600_hres_50_lres_250.region, which is the name of the mesh that will be used for the simulation (that we've just generated in step 4)
- RES=50, which is telling the minimum grid spacing used in this mesh (km)

After setting these variables, just comment out the code line from STEP 1 in the code:
```
#time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
```
uncomment the code line from STEP 3:
```
time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
```

Now, make sure all other code lines in STEP 1,2,3,4,5 are commented out:
```
# STEP 1: Installing and compiling the A-MONAN model and utility programs:
#time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
#exit

# STEP 2: Generating mesh. Preparing all CI/CC files needed:
#time ${SCRIPTS}/2.create_mesh.bash
#exit

# STEP 3: Executing the pre-processing fase. Preparing all CI/CC files needed:time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} ${MESH}
time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
#exit

# STEP 4: Executing the Model run:
#time ${SCRIPTS}/4.run_model.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES}
#exit

# STEP 5: Executing the Post of Model run:
#time ${SCRIPTS}/5.run_post.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES}
#$exit

#time ${SCRIPTS}/make_template.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
```

Save the file and exit it (:wq).

### 5.2) Run 0.run_all.bash
We can now finally execute the preprocessing by doing
```
bash 0.run_all.bash
```

The execution of this script may take a while -- this is the time you may want to grab a coffee and have some pão de queijo (I hope it's available). 

After the execution is completed, there are three files you should have generated (please check):

1) The static file referred to above, named `$MESH`.static.nc, within /mnt/beegfs/`$USER`/scripts_CD-CT/datain/fixed

2) An "intermediate file" containing preprocessed data from your real dataset, named `ERA5:2007-06-22_00`, within /mnt/beegfs/`$USER`/scripts_CD-CT/dataout/2007062200/Pre

3) An "init file" containing the interpolated initial conditions from that intermediate file, named `$MESH`.init.nc, within /mnt/beegfs/`$USER`/scripts_CD-CT/dataout/2007062200/Pre

If all these files have been correctly generated, we are ready for running our global simulation!

## 6) Running the global simulation
After all the configurations set in the previous step, running the global simulation is a matter of executing script 4.run_model.bash, which is done once more by editing and running `0.run_all.bash`.

### 6.1) Edit 0.run_all.bash

```
vi 0.run_all.bash
```

Comment out code line in STEP 3:
```
#time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
```

Uncomment code line in STEP 4:
```
time ${SCRIPTS}/4.run_model.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES}
```

Make sure all other code lines in STEP 1,2,3,4,5 are commented out:
```
# STEP 1: Installing and compiling the A-MONAN model and utility programs:
#time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
#exit

# STEP 2: Generating mesh. Preparing all CI/CC files needed:
#time ${SCRIPTS}/2.create_mesh.bash
#exit

# STEP 3: Executing the pre-processing fase. Preparing all CI/CC files needed:time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} ${MESH}
#time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
#exit

# STEP 4: Executing the Model run:
time ${SCRIPTS}/4.run_model.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES}
#exit

# STEP 5: Executing the Post of Model run:
#time ${SCRIPTS}/5.run_post.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES}
#$exit

#time ${SCRIPTS}/make_template.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST}
```

Save and exit (:wq).

### 6.2) Run 0.run_all.bash
```
bash 0.run_all.bash
```

Running the simulation will probably take another while -- so maybe more coffee and pão de queijo?

While you enjoy your coffee break, you may check the status of your simulation by 

```
squeue -u $USER
```

Once the simulation is done, you should see many files starting with MONAN_DIAG_G_MOD* under /mnt/beegfs/`$USER`/test_wmo_course/scripts_CD-CT/dataout/2007062200/Model.

If the files are there, congratulations, you're ready to check the results!

## 7) Checking the results
To check the results we can plot fields on the native MPAS grid using 5.run_post_on_mpas_grid.bash.

### 7.1) Edit 5.run_post_on_mpas_grid.bash
```
vi 5.run_post_on_mpas_grid.bash
```

Here you will choose the parameters you'd like for your plot. You set them by editing the "Local variables":

```
# Local variables------------------------------------------------------
## Variable to plot
VAR=surface_pressure
## Latitude and longitude min/max values to plot
LAT_MIN=-60
LAT_MAX=-15
LON_MIN=-65
LON_MAX=-20
# Minimum and maximum values of variable for colorbar
V_MIN=90000
V_MAX=103000
# Input file from which variable should be extracted
FILENAME=MONAN_DIAG_G_MOD_ERA5_2007062200_2007062300.00.00.lat_-35_lon_-55_oradius_2600_iradius_2000_margin_600_hres_50_lres_250.regionL55
FILEPATH=${DATAOUT}/2007062200/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2007062200/Pre/lat_-35_lon_-55_oradius_2600_iradius_2000_margin_600_hres_50_lres_250.region.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2007062200/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------
```

After selecting the parameters you want, just exit and save the script (:wq).

### 7.2) Run 5.run_post_on_mpas_grid.bash
```
bash 5.run_post_on_mpas_grid.bash
```

After the plotting is done, you can find it in the `$POSTFILEDIR`directory you have set above.

As with the mesh, you may not be able to open your plot in EGEON. If you cannot open it using

```
open $POSTFILEPATH
```
where `$POSTFILEPATH` was defined above, you need to copy the plot to your local machine. This can be done by opening another terminal, then doing
```
scp $USER@egeon.cptec.inpe.br:$POSTFILEPATH .
```
After that, you can finally check your plot by opening it in your local machine.
