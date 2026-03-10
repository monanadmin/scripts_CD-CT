# Tutorial for running an idealized global MONAN simulation

## 1) First steps in EGEON
To start our exercise, we first need to log in into EGEON and set up a conda environment, which will be needed to execute some of the steps in running a MONAN simulation.

### 1.1) Log in

In your terminal, write
```
ssh -Y $USER@egeon-login.cptec.inpe.br
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

### 1.4) Make sure you have access to our conda environment

Write the command
```
conda config --add envs_dirs /pesq/share/monan/curso_OMM_INPE_2025/.conda/envs
```

### 1.5) Test if you can activate our conda environment

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

**If you already have cloned the repository in tutorial 1, skip step 2.2)!**

### 2.2) Clone the scripts repository: 

```
git clone -b feature/scripts-849-NF-idealized-regional https://github.com/CGFD-USP/scripts_CD-CT
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

## 4) Meshes

After script `0.run_all.bash` finishes running, you have MONAN installed and compiled. The next step would be to generate the global mesh with which you will run your simulation. Since in tutorial 1 we have already generated two global meshes, one without refinement and one with refinement, we will use those generated meshes for our simulation.

To do this, we split the class into two groups:

##### <span style="color: red;">Group 1: mesh without refinement</span> 

##### <span style="color: red;">Group 2: mesh with refinement</span> 

Depending on the group you're, in you will follow when indicated below the steps specific for the mesh without refinement (group 1) or for the mesh with refinement (group 2). 

**If you could not generate the mesh you needed in the previous tutorial, do not worry: we will leave an option for you to download a pre-prepared mesh from NCAR so that you can follow the exercise as well. That mesh doesn't have refinement and has very similar characteristics to the mesh group 1 will use, so you will belong as well to group 1.**

## 5) Preprocessing

Now it's time for preparing your simulation. In this idealized test case, this is done by taking the mesh and generating from it an "init" file that contains the idealized initial conditions needed for our test case and also the vertical grid. This is accomplished by script `3.pre_processing.bash`, so our goal in this section is to run that script. This will be done again via the general script `0.run_all.bash`.

### 5.1) Edit 0.run_all.bash
We start by editing `0.run_all.bash`:
```
vi 0.run_all.bash
```

Here we will set the input variables for our simulation. In the section "Input variables" of the script, make sure the following is set, depending on your group:

#### <span style="color: red;">Group 1: mesh without refinement</span> 

##### Using mesh generated in tutorial 1
If you're from group 1 and could finish the mesh without refinement in the previous tutorial, set the "Input variables" as follows:

```
github_link="https://github.com/monanadmin/MONAN-Model.git"
monan_branch=release/1.4.1-rc
convertmpas_branch=release/1.2.0
EXP=IDEALIZED2
YYYYMMDDHHi=2025111800
FCST=360
MESH=lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_240_lres_600.region
RES=240 #3 # Minimum grid spacing (km)
REGIONAL=N   # Whether to run reigonal simulation
LBCINT=21600 # Interval (seconds) for updating lateral boundary conditions (when regional)
```
##### Using mesh to be downloaded from NCAR
If you're from group 1 and could not finish the mesh without refinement in the previous tutorial, set the "Input variables" as follows:
```
github_link="https://github.com/monanadmin/MONAN-Model.git"
monan_branch=release/1.4.1-rc
convertmpas_branch=release/1.2.0
EXP=IDEALIZED2
YYYYMMDDHHi=2025111800
FCST=360
MESH=x1.10242
RES=240 #3 # Minimum grid spacing (km)
REGIONAL=N   # Whether to run reigonal simulation
LBCINT=21600 # Interval (seconds) for updating lateral boundary conditions (when regional)
```

#### <span style="color: red;">Group 2: mesh with refinement</span> 

##### Using mesh generated in tutorial 1
If you're from group 2 and could finish the mesh with refinement in the previous tutorial, set the "Input variables" as follows:
```
github_link="https://github.com/monanadmin/MONAN-Model.git"
monan_branch=release/1.4.1-rc
convertmpas_branch=release/1.2.0
EXP=IDEALIZED2
YYYYMMDDHHi=2025111800
FCST=360
MESH=lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.global
RES=48 #3 # Minimum grid spacing (km)
REGIONAL=N   # Whether to run reigonal simulation
LBCINT=21600 # Interval (seconds) for updating lateral boundary conditions (when regional)
```

Otherwise, follow the instructions above for **Group 1  - Using mesh to be downloaded from NCAR**!

#### <span style="color: red;">Everyone</span> 

For us the relevant variables are the following:
- EXP=IDEALIZED2, which is telling the code which kind of experiment will be performed (IDEALIZED2 indicates that we take the idealized test case number 2, following the MPAS' User Guide https://www2.mmm.ucar.edu/projects/mpas/mpas_atmosphere_users_guide_8.2.0.pdf, section 7.1). Also possible here are options EXP=ERA5 and EXP=GFS, if one wants to perform real-data simulations (see our tutorial 3).
- YYYYMMDDHHi=2025111800, which is telling the date and hour the simulation will start (in this present idealized exercise, the date and hour don't really matter, so we can in principle leave any date and hour here)
- FCST=360, which is telling for how many hours we will run the simulation (15 days)
- MESH=`$MESH`, which is the name of the mesh that will be used for the simulation (here `$MESH`varies depending on which group you're in)
- RES=`$RES`, which is telling the minimum grid spacing in km used in this mesh (this also depends on your group)
- REGIONAL=N, which is telling that we do not want a regional simulation (we want a global simulation)

After setting these variables, just comment out the code line from STEP 1 in the code:
```
#time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
```
Uncomment the code line from STEP 3:
```
time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${REGIONAL} ${LBCINT}
```

Now, make sure all other code lines in STEP 1,2,3,4,5 are commented out:
```
# STEP 1: Installing and compiling the A-MONAN model and utility programs:
#time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
#exit

# STEP 2: Generating mesh. Preparing all CI/CC files needed:
#time ${SCRIPTS}/2.create_mesh.bash
#exit

# STEP 3: Executing the pre-processing phase. Preparing all CI/CC files needed:time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} ${MESH}
time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${REGIONAL} ${LBCINT}
#exit

# STEP 4: Executing the Model run:
#time ${SCRIPTS}/4.run_model.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES} ${REGIONAL} ${LBCINT}
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

After the execution is completed, the "init" file, named `$MESH`.init.nc, should have been generated under /mnt/beegfs/`$USER`/scripts_CD-CT/dataout/2025111800/Pre. Please check if it's there. If so, we are ready for running our global simulation!

## 6) Running the global simulation
After all the configurations set in the previous step, running the global simulation is a matter of executing script 4.run_model.bash, which is done once more by editing and running `0.run_all.bash`.

### 6.1) Edit 0.run_all.bash

```
vi 0.run_all.bash
```

Comment out code line in STEP 3:
```
#time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${REGIONAL} ${LBCINT}
```

Uncomment code line in STEP 4:
```
time ${SCRIPTS}/4.run_model.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES} ${REGIONAL} ${LBCINT}
```

Make sure all other code lines in STEP 1,2,3,4,5 are commented out:
```
# STEP 1: Installing and compiling the A-MONAN model and utility programs:
#time ${SCRIPTS}/1.install_monan.bash ${github_link} ${monan_branch} ${convertmpas_branch}
#exit

# STEP 2: Generating mesh. Preparing all CI/CC files needed:
#time ${SCRIPTS}/2.create_mesh.bash
#exit

# STEP 3: Executing the pre-processing phase. Preparing all CI/CC files needed:time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} ${MESH}
#time ${SCRIPTS}/3.pre_processing.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${REGIONAL} ${LBCINT}
#exit

# STEP 4: Executing the Model run:
time ${SCRIPTS}/4.run_model.bash ${EXP} ${MESH} ${YYYYMMDDHHi} ${FCST} ${RES} ${REGIONAL} ${LBCINT}
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

Once the simulation is done, you should see many files starting with MONAN_* under /mnt/beegfs/`$USER`/scripts_CD-CT/dataout/2025111800/Model.

If the files are there, congratulations, you're ready to check the results!

## 7) Checking the results
To check the results we can plot fields on the native MPAS mesh using 5.run_post_on_mpas_grid.bash.

For that, make sure you have the geographical files needed for the plot:

```
mkdir -p "/home/$USER/.local/share" && cp -r /pesq/share/monan/curso_OMM_INPE_2025/.local/share/cartopy "/home/$USER/.local/share/"
```

Now we can proceed to the plotting.

### 7.1) Pressure field

#### 7.1.1) Edit 5.run_post_on_mpas_grid.bash
```
vi 5.run_post_on_mpas_grid.bash
```

Here you will choose the parameters you'd like for your plot. You set them by editing the "Local variables", according to your group. We will start by plotting the pressure field, and then the vorticity field, both of them on day 13 of the simulation.

#### <span style="color: red;">Group 1: mesh without refinement</span> 

##### Using mesh generated in tutorial 1:
You can just copy and paste the code below into the appropriate "Local variables" section in `5.run_post_on_mpas_grid.bash`:
```
# Local variables------------------------------------------------------
## Variable to plot
VAR=pressure
# Input file from which variable should be extracted
FILENAME=MONAN_HIST_G_MOD_IDEALIZED2_2025111800_2025120100.00.00.lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_240_lres_600.regionL55
FILEPATH=${DATAOUT}/2025111800/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2025111800/Pre/lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_240_lres_600.region.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2025111800/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------
```

##### Using mesh downloaded from NCAR:
You can just copy and paste the code below into the appropriate "Local variables" section in `5.run_post_on_mpas_grid.bash`:
```
# Local variables------------------------------------------------------
## Variable to plot
VAR=pressure
# Input file from which variable should be extracted
FILENAME=MONAN_HIST_G_MOD_IDEALIZED2_2025111800_2025120100.00.00.x1.10242L55
FILEPATH=${DATAOUT}/2025111800/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2025111800/Pre/x1.10242.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2025111800/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------
```

#### <span style="color: red;">Group 2: mesh with refinement</span> 

##### Using mesh generated in tutorial 1:
You can just copy and paste the code below into the appropriate "Local variables" section in `5.run_post_on_mpas_grid.bash`:
```
# Local variables------------------------------------------------------
## Variable to plot
VAR=pressure
# Input file from which variable should be extracted
FILENAME=MONAN_HIST_G_MOD_IDEALIZED2_2025111800_2025120100.00.00.lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.globalL55
FILEPATH=${DATAOUT}/2025111800/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2025111800/Pre/lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.global.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2025111800/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------
```

#### <span style="color: red;"> Everyone </span> 

After selecting the parameters you want, just exit and save the script (:wq).

### 7.1.2) Run 5.run_post_on_mpas_grid.bash
```
bash 5.run_post_on_mpas_grid.bash
```

After the plotting is done, you can find it in the `$POSTFILEDIR`directory you have set above.

As with the mesh, you may not be able to open your plot in EGEON. If you cannot open it using

```
module load imagemagick-7.0.8-7-gcc-11.2.0-46pk2go
display $POSTFILEPATH
```
where `$POSTFILEPATH` was defined above, you need to copy the plot to your local machine. This can be done by opening another terminal, then doing
```
scp $USER@egeon.cptec.inpe.br:$POSTFILEPATH .
```
After that, you can finally check your plot by opening it in your local machine.

The resulting pressure field should look like the following:

##### Group 1 - mesh generated in tutorial 1

![Alt text](figs/pressure_group1_tut1.png)

##### Group 1 - mesh downloaded from NCAR

![Alt text](figs/pressure_group1_ncar.png)

##### Group 2 - mesh generated in tutorial 1 (note the detailed structure in the region of refinement)

![Alt text](figs/pressure_group2.png)

### 7.2) Vorticity field

#### 7.2.1) Edit 5.run_post_on_mpas_grid.bash
```
vi 5.run_post_on_mpas_grid.bash
```

#### <span style="color: red;">Group 1: mesh without refinement</span> 

##### Using mesh generated in tutorial 1:
You can just copy and paste the code below into the appropriate "Local variables" section in `5.run_post_on_mpas_grid.bash`:
```
# Local variables------------------------------------------------------
## Variable to plot
VAR=vorticity
# Minimum and maximum values of variable for colorbar
V_MIN=-0.000125
V_MAX=0.000125
# Input file from which variable should be extracted
FILENAME=MONAN_HIST_G_MOD_IDEALIZED2_2025111800_2025120100.00.00.lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_240_lres_600.regionL55
FILEPATH=${DATAOUT}/2025111800/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2025111800/Pre/lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_240_lres_600.region.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2025111800/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------
```

##### Using mesh downloaded from NCAR:
You can just copy and paste the code below into the appropriate "Local variables" section in `5.run_post_on_mpas_grid.bash`:
```
# Local variables------------------------------------------------------
## Variable to plot
VAR=vorticity
# Minimum and maximum values of variable for colorbar
V_MIN=-0.000125
V_MAX=0.000125
# Input file from which variable should be extracted
FILENAME=MONAN_HIST_G_MOD_IDEALIZED2_2025111800_2025120100.00.00.x1.10242L55
FILEPATH=${DATAOUT}/2025111800/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2025111800/Pre/x1.10242.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2025111800/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------
```

#### <span style="color: red;">Group 2: mesh with refinement</span> 

##### Using mesh generated in tutorial 1:
You can just copy and paste the code below into the appropriate "Local variables" section in `5.run_post_on_mpas_grid.bash`:
```
# Local variables------------------------------------------------------
## Variable to plot
VAR=vorticity
# Minimum and maximum values of variable for colorbar
V_MIN=-0.000125
V_MAX=0.000125
# Input file from which variable should be extracted
FILENAME=MONAN_HIST_G_MOD_IDEALIZED2_2025111800_2025120100.00.00.lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.globalL55
FILEPATH=${DATAOUT}/2025111800/Model/${FILENAME}.nc
# File from which grid characteristics should be extracted
GFILEPATH=${DATAOUT}/2025111800/Pre/lat_50_lon_-30_oradius_2800_iradius_2000_margin_800_hres_48_lres_240.global.init.nc
# Output directory and filename to save plot
POSTFILEDIR=${DATAOUT}/2025111800/Post
POSTFILEPATH=${POSTFILEDIR}/${VAR}_${FILENAME}.png
#---------------------------------------------------------------------
```

#### <span style="color: red;"> Everyone </span> 

After selecting the parameters you want, just exit and save the script (:wq).

### 7.2.2) Run 5.run_post_on_mpas_grid.bash
```
bash 5.run_post_on_mpas_grid.bash
```

After the plotting is done, you can find it in the `$POSTFILEDIR`directory you have set above.

As with the mesh, you may not be able to open your plot in EGEON. If you cannot open it using

```
module load imagemagick-7.0.8-7-gcc-11.2.0-46pk2go
display $POSTFILEPATH
```
where `$POSTFILEPATH` was defined above, you need to copy the plot to your local machine. This can be done by opening another terminal, then doing
```
scp $USER@egeon.cptec.inpe.br:$POSTFILEPATH .
```
After that, you can finally check your plot by opening it in your local machine.

The resulting pressure field should look like the following:

##### Group 1 - mesh generated in tutorial 1

![Alt text](figs/vorticity_group1_tut1.png)

##### Group 1 - mesh downloaded from NCAR

![Alt text](figs/vorticity_group1_ncar.png)

##### Group 2 - mesh generated in tutorial 1 (note the detailed structure in the region of refinement)

![Alt text](figs/vorticity_group2.png)
