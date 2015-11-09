This document provides instructions for a first time user to setup his/her environment and test by running an example analysis.

**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Setup environment (one-time)](#SetupEnv)
	- [bash shell](#bash)
	- [SGE](#SGE)
	- [tabix](#tabix)
- [Example Analysis](#Example)
	- [Check workspace](#Check)
	- [Run test](#Run)
	- [Review results](#Review)
	- [Reset workspace](#Reset)


# <a name="SetupEnv">Setup environment (one-time)</a>
Depending on your current environment setup, you may need to make the following changes before proceeding. Start by logging into ```us1us0168.corpnet2.com``` with the terminal client of your choice (e.g. putty or exceed).

## <a name="bash">bash shell</a>
You need to use the bash shell. To determine your current shell, run ```ps -p $$``` and the shell will be listed under ```CMD```. If it isn't bash, you can change your default shell at https://hbu080.corpnet2.com/ChangeShell and then start a new session.

## <a name="SGE">SGE</a>
Ensure you have the SGE commands in your path by trying ```qhost```. If you get an error indicating the command is not found then add this line:
```
. /GWD/bioinfo/projects/lsf/SGE/6.2/default/common/settings.sh
```
to the end of the ```my.bashrc``` file in your home directory (if you don't have this file, create a text file and name it ```my.bashrc```) and then start a new session.

## <a name="tabix">tabix</a>
Ensure you have tabix in your path by trying ```tabix```. If you get an error indicating the command is not found then add this line:
```
export PATH=$PATH:/GWD/bioinfo/apps/bin
```
to the end of the ```my.bashrc``` file in your home directory.



# <a name="Example">Example Analysis </a>
Note, this is a toy dataset derived from HapMap subjects so there are no concerns over security of personally-identifiable information. Further, GSK indicated in research use applications to Coriell that the samples would be used to generate whole-genome data and this data would be used for system testing so there is no expiration associated with this use of the data. All of the clinical data is simulated.

## <a name="Check">Check workspace</a>
Check to confirm the directory structure looks like this:
```
> tree /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/ABC123456  /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/input
/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/ABC123456
|-- Analysis
|   `-- input -> /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/input
`-- AnalysisReadyData
    |-- genotypes
    |   |-- ABC123456-pca.eigenvec
    |   `-- ABC123456-pca.eigenvec.all10
    `-- imputed-20120314
        |-- Imputed_HLAalleles_AllSubjects_Additive.dose.gz
        |-- Imputed_HLAalleles_AllSubjects_Additive.info.gz
        |-- chr21chunk3.dose.gz
        |-- chr21chunk3.info.gz
        |-- chr22chunk3.dose.gz
        |-- chr22chunk3.info.gz
        |-- chr22chunk4.dose.gz
        `-- chr22chunk4.info.gz
/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/input
|-- Pheno.txt
|-- config.txt
|-- cvlist.txt
|-- demo.txt
|-- groups.txt
|-- models.txt
|-- pop.txt
`-- variables.txt

5 directories, 18 files
```
If there are extra files, then either another user is currently testing or completed testing but failed to reset the workspace. Check the owner of the files and follow up with that user.

If there are missing files, please check with an administrator to restore these from the GitHub repository.

## <a name="Run">Run test</a>
Submit this command to run the test
```
/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/qsub.sh Example Email /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/ABC123456/Analysis
```
Replacing ```Email``` with your e-mail address. This example is small so analysis should finish within a few minutes, no need to monitor progress.

## <a name="Review">Review results</a>
You will know the analysis is complete when you receive an e-mail from root [root@gsk.com] with the subject ```Job NNNNNN (Example) Complete```. The exit status in this e-mail should be 0. Also run the following to check results are as expected:
```
diff /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/ABC123456/Analysis/outputs/report-short.html /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/Expected_report-short.html
```
If either of these conditions is not met, please consult an administrator for support.


## <a name="Reset">Reset workspace</a>
Once complete, please restore the workspace by deleting your output as follows:
```
/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/reset_workspace.sh
```
