This document describes the installation of the routine PGx analysis pipeline (gtx R package) in GSK’s Global Data Center (GDC). It includes details on how the installation is configured and is intended primarily for administrators but may also be a useful reference for users.

## Code
The pipeline is implemented as an R package with source code maintained on GitHub:
https://github.com/tobyjohnson/gtx (may be moved in future from Toby’s account to StatGenPRD – check there if this link is dead). Use of GitHub is well documented on the [site](https://help.github.com/) and GSK's installation of git is well documented on the [internal wikis](https://connect.gsk.com/sites/genetics/GeneticsWIKI/Wiki%20Pages/Software%20-%20git.aspx).



## Setup in GSK's Global Data Center Linux Environment
Access to the GDC Linux environment is primarily through ```us1us0168.corpnet2.com```.  A controlled instance of the package is installed at
```
GDC: /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages/x86_64-unknown-linux-gnu-library/3.0/gtx
```
By controlled instance, we mean edit access is restricted to the ```gxappdev``` group.  Anyone attempting to change this instance should be fully aware of the potential downstream consequences (e.g. an upgrade of the package may require re-validation). Additionally, any changes should be followed by a confirmation / resetting of the permissions such that only the ```gxappdev``` group has edit access. Changes should never happen while a user is running an analysis. Assuming all users are following the [instructions on running](https://github.com/StatGenPRD/GDCgtx/blob/master/HowToRun.md), they should be using SGE and you can check if any jobs are in progres by running
```
qstat –u "*"
```


### GTX Package Updates
When an administrator does wish to update the controlled instance, this script can be used to build and install from GitHub and reset the permissions
```
/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update/build_install.sh >/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update/build_install.out 2>/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update/build_install.err
```


### R Dependencies
The gtx pipeline requires several R packages and will optionally use others as available.  These are currently not controlled but instead installed in the "local" R3 instance at 
```
GDC: /GWD/appbase/projects/statgen/R3.0.0/R-3.0.0
```
In lieu of controlling these, we will report the versions used in the log of each run.
