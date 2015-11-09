This document provides instructions on how to run the routine PGx analysis pipeline (gtx R package) installed in GSK’s Global Data Center (GDC). Details of the installation can be found [here](https://github.com/StatGenPRD/GDCgtx/blob/master/InstallationConfig.md). Before proceeding, be sure you have run the [example analysis](https://github.com/StatGenPRD/GDCgtx/blob/master/Example.md) to confirm your compute environment is setup correctly.

**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Create workspace](#workspace)
- [Prepare genetic data](#GeneticData)
	- Non-standard genetic data
		- [SNP name uniqueness](#SNPnames)
		- [Missingness](#Missing)
		- [Subject IDs](#SubjectIDs)
- [Prepare clinical data & configure analyses](#ClinicalData)
	- [pop.txt](#pop)
	- [demo.txt](#demo)
	- [Pheno.txt](#pheno)
	- [variables.txt](#variables)
	- [groups.txt](#groups)
	- [cvlist.txt](#cvlist)
	- [models.txt](#models)
	- [config.txt](#config)
- [Run analyses](#Run)
- [Monitoring progress](#Monitor)
- [Review results](#Review)
	- [Analysis/Group results](#GroupResults)
	- [Outputs](#Outputs)
- [Re-running](#Rerun)
	- [Failed jobs](#FailedJobs)
	- [Edited analysis configuration](#EditConfig)
		- [New configurations](#NewConfig)
		- [Changed configurations](#ChangeConfig)
	- [Killing jobs in progress](#Kill)


	
## <a name="workspace">Create workspace</a>
You will need a directory on a file share in the GDC with sufficient space for the analysis output. Ideally (if space allows), use the same directory where the data scientist has delivered the data so you will have a directory structure like
```
> tree /path/to/share/StudyID
|-- Analysis
`-- AnalysisReadyData
    |-- Phase_Impute.sh
    |-- Pre-imputation_QC.sh
    |-- aligned-hg19
    |-- doc
    |-- genotypes
    |-- imputed-20120314
    |-- phased-mach-hg19
    `-- phenotypes
 ```
where ```AnalysisReadyData``` is from the data scientist and contains both the genetic and clinical data. If there is not enough space here, then create a "sister" directory on another share and cross-link so you will have
```
> tree /path/to/share/StudyID
|-- Analysis -> /path/to/another_share/StudyID/Analysis
`-- AnalysisReadyData
    |-- Phase_Impute.sh
    |-- Pre-imputation_QC.sh
    |-- aligned-hg19
    |-- doc
    |-- genotypes
    |-- imputed-20120314
    |-- phased-mach-hg19
    `-- phenotypes
> tree /path/to/another_share/StudyID
|-- Analysis
`-- AnalysisReadyData -> /path/to/share/StudyID/AnalysisReadyData
```


## <a name="GeneticData">Prepare genetic data</a>
There isn't much you need to do for the genetic data assuming it is coming from our standardized imputation pipeline. The analysis pipeline expects genetic data to be in a series of gzip'ed minimac dose/info file pairs, all in the same directory. This will typically be the ```imputed-20120314``` directory with the exception of HIBAG results which should be in a separate directory. Add links to the HIBAG results in the ```imputed-20120314``` directory as follows

```
cd imputed-20120314
ln -s /path/to/HIBAG/Results_ImputedHLAAlleles_Converted/Imputed_HLAalleles_AllSubjects_Additive.dose.gz Imputed_HLAalleles_AllSubjects_Additive.dose.gz
ln -s /path/to/HIBAG/Results_ImputedHLAAlleles_Converted/Imputed_HLAalleles_AllSubjects_Additive.info.gz Imputed_HLAalleles_AllSubjects_Additive.info.gz
```
Note, your delightful data scientist may have already done this for you.

### Non-standard genetic data
If you have additional genetic data that did not come from our imputation workflow then you will need to ensure it follows the same format as that produced by the imputation workflow.

#### <a name="SNPnames">SNP name uniqueness</a>
The ```SNP``` in the info file must be of the form ```chr:position:details``` where ```:details``` is optional but must be specified when there is more than one instance of a given ```chr:position``` across the entire dataset (not just the file) to ensure uniqueness.

The most common example would be an SNV and indel with the same coordinate where the alleles are usually used to distinguish like ```1:1000:G_T``` and ```1:1000:G_GA```.

Another example would be if you have standard imputed data for ```SNP``` ```1:1000``` in ```chr1chunk1.info.gz``` and are creating ```chr1assayed.info.gz``` to capture assayed genotypes where the ```SNP``` value for the variant at position 1000 should be something like ```1:1000:assayed```.

#### <a name ="Missing">Missingness</a>
Currently the pipeline does not handle missing doses.

#### <a name="SubjectIDs">Subject IDs</a>
Subject IDs (first column of dose file) should be of the form ```USUBJID->USUBJID``` where USUBJID is the same value specified in the clinical data (see Prepare clincal data below). Order does not matter.



## <a name="ClinicalData">Prepare clinical data & configure analyses</a>

The analysis pipeline expects analysis-ready clinical data to be in tab-delimited text files named like ```dataset.txt``` (e.g. ```pop.txt``` and ```demo.txt``` for IDSL AR or ```ADDM.txt``` for CDISC ADaM) with variable names in the column headers. Expect your data scientist to deliver SAS exports in this format.

Multiple analyses and contrasts can be executed simultaneously using the gtx package with a single driver script that defines or derives all required options, subgroups, endpoints, covariates, and models based on the analysis-ready clinical data exports. However, this requires familiarity with R syntax so instead we have devised an approach that allows you to prepare your endpoints & covariates and specify the attributes of your subgroups, models, and contrasts in tables that can be fed into a standard "gtx driver" script. All these files are tab delimited and expected to be in a directory named ```input```. All files can have ```#``` prefixed comment lines and with the exception of ```config.txt``` and ```cvlist.txt```, there are no restrictions on column ordering and extra unused columns are allowed. Be careful if using Excel to create these files as it may introduce unexpected quotes.


###  <a name="pop">pop.txt</a>
This file is based on the IDSL AR pop dataset and must contain at least the following variables:
```
STUDYID  TRTGRP  ATRTGRP  PNITT  USUBJID
```
If your data scientist has delivered an IDSL AR pop dataset with the AnalysisReadyData, you can either add a symbolic link in the input directory to the file. If it is a CDISC ADaM dataset, use the following variables, respectively:
```
ADSL.STUDYID  ADSL.TRTP  ADSL.TRTA  ADSL.ITTFL  ADSL.USUBJID
```

See the example file [here](https://github.com/StatGenPRD/GDCgtx/blob/master/input/pop.txt).

### <a name="demo">demo.txt</a>
This file is based on the IDSL AR demo dataset and must contain at least the following variables:
```
SEX  AGE  RACE  ETHNIC  USUBJID
```
If your data scientist has delivered an IDSL AR demo dataset with the AnalysisReadyData, you can either add a symbolic link in the input directory to the file . If it is a CDISC ADaM dataset, use the following variables, respectively:
```
ADDM.SEX  ADDM.AGE  ADDM.RACE  ADDM.ETHNIC  ADDM.USUBJID
```

See the example file [here](https://github.com/StatGenPRD/GDCgtx/blob/master/input/demo.txt).

### <a name="pheno">Pheno.txt</a>
This file contains all the remaining subject-level values that will be used as covariates or endpoints in your model statements. These values will be read as-is so, any derivations or transformations should occur before they are put in this file unless you are comfortable with R syntax and can define using the ```fun``` column in [variables.txt](#variables). It must contain ```USUBJID```.

See the example file [here](https://github.com/StatGenPRD/GDCgtx/blob/master/input/Pheno.txt).


### <a name="variables">variables.txt</a>
This file is used to define endpoints, covariates, and variables used to define subgroups. The required variables from [pop.txt](#pop) and [demo.txt](#demo) are defined by default. Eigenvectors also do no need to be specified here.

```variable``` : The label of the variable which will be used in reports. It should be a succinct alphanumeric value and follow the convention of DataSetName.VariableName like ```Pheno.maxalt```. The default definition of the required variables from [pop.txt](#pop) and [demo.txt](#demo) will follow this convention (e.g. ```demo.AGE```) and can be referenced as such in [groups.txt](#groups) and [models.txt](#models).

```descriptor``` : A longer description of the variable.

```types``` : The type of variable (```character``` ```integer``` ```double``` ```factor```).

```data``` : The dataset or subset to consider, usually just ```Pheno``` since most values will come from ```Pheno.txt``` but may also be a function defining a subset like ```subset(Pheno, subset = INVID!=7)```)

```fun``` : This optional column defines the function used to calculate the variable. If blank, ```valuesof(X)```  will be used by default to extract the values as they are where X is the value of ```variable``` (i.e. if ```variable``` does not follow the DataSetName.VariableName convention, this default behavior will fail and you should instead specify ```valuesof(DatasetName.Variable)``` here).

See the example file [here](https://github.com/StatGenPRD/GDCgtx/blob/master/input/variables.txt).


### <a name="groups">groups.txt</a>
This file is used to define subgroups.

```group``` : The label of the group which will be used in reports, directories, and filenames. It should be a succinct alphanumeric value.

```fun``` : The function used to determine which subjects are in the group. Note, pop.PNITT is derived from Y/N to a logical T/F.

```deps``` : Space separated list of variables used in ```fun```. These variables must be defined in either ```pop.txt```, ```demo.txt```, or ```Pheno.txt```.

See the example file [here](https://github.com/StatGenPRD/GDCgtx/blob/master/input/groups.txt).


### <a name="cvlist">cvlist.txt</a>
This optional file lists the candidate variants which will be considered under a separate multiple-test corrected significance threshold than the genome-wide analysis. Only the first column will be read and is expected to match the ```SNP``` value from the minimac info files. Be careful to ensure these values are present in the data as the multiple-testing correction factor is based on the length of this list so, inclusion of variants that are missing in the data will unnecessarily inflate the correction factor.

Since these values are of the form ```chr:position```, you may include additional columns with other labels or comments (e.g. the second column could be rsID and the third a categorization of why the variant was selected). You may include a ```#``` prefixed header line. See the example [here](https://github.com/StatGenPRD/GDCgtx/blob/master/input/cvlist.txt).

If you wish to consider a different list of candidate variants for each analysis, you may have multiple files in which case the file names will need to be unique and ideally describe which analysis they will be used for (see the reference in below in [models.txt](#models)).


### <a name="models">models.txt</a>
This file is used to define the model for each analysis and optional contrasts.

```analysis``` : The label of the analysis which will be used in reports, directories, and filenames. It should be a succinct alphanumeric value.

```model``` : The model statement.

```groups``` : The label(s) of the group(s) in which this analysis should be conducted as defined in ```groups.txt```.

```cvlist``` : Optional, the name of the candidate variant list used for this analysis. Usually ```cvlist.txt```.

```contrasts``` : Optional, the contrasts to consider of the form ```group1/group2``` where the ```group1``` and ```group2``` are labels defined in ```groups.txt```.

See the example [here](https://github.com/StatGenPRD/GDCgtx/blob/master/input/models.txt).


### <a name="config">config.txt</a>
This file contains all the high-level (cross-analysis) key-value options. Comment lines can be pre-fixed with ```#```. All other non-blank lines will be interpretted as a tab separated key-value pair like: 
```
#filtering criteria
threshold.MAF	0.05
threshold.Rsq	0.5
```
See the example [here](https://github.com/StatGenPRD/GDCgtx/blob/master/input/config.txt) for a full listing of accepted options.



## <a name="Run">Run analyses</a>

Once everything has been configured, you can start your analyses by submitting the following command
```
/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/qsub.sh Label Email Workspace
```
where ```Label``` is a short job label that will be used to monitor progress, ```Email``` is the e-mail address at which you want to receive notification of job completion (e.g. First.Last@PAREXEL.com), and ```Workspace``` is the absolute path to the workspace created [above](#workspace) like ```/path/to/share/StudyID/Analysis``` (assumes ```input/config.txt``` exists here). You should receive a message like
```
Your job NNNNNNN ("Label") has been submitted
```
where NNNNNN is the job ID.



## <a name="Monitor">Monitoring progress</a>
You will know the analyses are complete when you receive an e-mail from root [root@gsk.com] with the subject ```Job NNNNNN (Label) Complete``` where ```Label``` is  what you specified [above](#Run) and ```NNNNNN``` is the job ID returned when you ran the command [above](#Run) to start the analysis.

Until this happens, it is a good idea to check the SGE queue periodically to confirm that your jobs are running at the rate expected (ideally 100 jobs at a time). Use the following command:
```
qstat -u mudID
```
where ```mudID``` is your user ID. State of r indicates running, q or T indicates queued. E indicates something is wrong, check with an administrator.

If it appears too many of your jobs are queued and not enough running, check to see how busy the queue is:
```
qstat -u "*"
```
If there aren't a lot of running jobs from other users, then the queues may be in error state and require resetting, check
```
> qhost -q | grep 'dl580'
   dl580                BIP   0/0/16
   dl580                BIP   0/0/16
   dl580                BIP   0/0/16
   dl580                BIP   0/0/18
   dl580                BIP   0/0/18
   dl580                BIP   0/0/18
   dl580                BIP   0/0/18
   dl580                BIP   0/0/18
   dl580                BIP   0/0/12
   dl580                BIP   0/0/12
```
Where the lack of E afer the N/N/N indicates the queues are fine. If several are in E state, e-mail the <a href="mailto:R&D_IT_Infra_Services@gsk.com">Linux admins</a> and ask to reset. Be sure to include a screen cap of what you have observed and note that you are on the us1us0168 server.



## <a name="Review">Review results</a>
The exit status in the notification e-mail should be 0, any non-zero status indicates something went wrong and you should review the *.out and *.err files in the ```Analysis``` directory.

A good place to start in the review is the "final" report 
```
Analysis\outputs\report-short.hmtl
```
The first thing to check is that this file exists and contains 3 tables (groups, subjects, analysis results). You can open this file in Word to edit towards the final CSR insert and/or convert to PDF.

If anything seems wrong with the contents of this report but the exit status was 0, then it will require some investigation as the cause is likely in the source data / analysis setup.

### <a name="GroupResults">Analysis/Group results</a>
If everything executed as expected, then you should find the following files in each analysis/group directory:

```ALL.out.txt.gz```: Results for all variants passing the MAF and Rsq filtering criteria and all candidate variants.

```ALL.out.txt.gz.tbi```: This is a tabix index file which enables fast querying / subsetting.

```CV.out.txt.gz```: Results for all candidate variants +/- 500kb - useful for region plots.

```CV.bed```: This contains all the candidate variants +/- 500kb and is used to subset ```CV.out.txt.gz``` from ```ALL.out.txt.gz```.

```*.done```: Each pair of ```*.dose.gz``` and ```*.info.gz``` files should have a corresponding ```*.done``` file indicating the analysis of that "chunk" completed.

```analysis-dataset.csv```: The relevant configuration for this analysis/group including model statement, candidate variant list, endpoint, and covariates.

```options.R```: File used to pass configuration options from the main pipeline run to each chunk sub-job.


### <a name="Outputs">Outputs</a>
If everything executed as expected, then you should find the following files in the outputs directory:

```*.[csv|pdf]```: Four tables in both CSV and PDF format which should match what is observed in the ```report-short.html```.

```*[QQ|Manhattan]*.png```: A QQ and Manhattan plot for each analysis/group.

```lela_metadata```: CSV file describing each of the files here (PDF and PNG) as potential displays, formatted as required for LeLa.

```report-short.*```: Files associated with the summary report.

```subject_analysis_dataset.csv```: Results of the package processing the clinical data per ```variables.txt```.


## <a name="Rerun">Re-running</a>
Below are some tips for re-running under different scenarios:

### <a name="FailedJobs">Failed jobs</a>
If any of the chunk child-jobs were interrupted for any reason (e.g. server goes down), you can resume the analysis where it left off by ... BE SURE TO ADDRESS OVERWRITING OF OUT/ERR/LOG Files

### <a name="EditConfig">Edited analysis configuration</a>
If you have decided to change the analysis configuration, the type of change will dictate how to proceed. 

#### <a name="NewConfig">New configurations</a>
If you only added new configurations (variables, groups, models, contrasts) and did not change any existing data or settings, then you can follow the instructions for a [failed job](#FailedJobs). The pipeline will  detect that the chunk results for the new analysis/group(s) are missing and analyze those while leaving the existing results intact. Contrasts are the exception - you may change contrasts and still take this approach as the contrasts do not affect how the chunk analyses are conducted, they are calculated during results tabulation which is always re-run.

#### <a name="ChangeConfig">Changed configurations</a>
If you changed any of the data or settings, then the existing chunk analysis results need to be discarded so the pipeline knows to re-run the analyses under the new conditions. **_With caution_**, you can "target" this discarding to only the analyis/group(s) that are affected by the changes but it is safest to discard all. To "target", delete the relevant ```analyses/analysis/group``` directory and the QQ and Manhattan plots. The safe approach is to delete everything in the ```Analysis``` directory except for your ```input``` directory.

### <a name="Kill">Killing jobs in progress</a>
If you realize there is something wrong with your setup while the pipeline is running, you can kill all of your jobs with this command
```
qdel -u mudID
```
where ```mudID``` is your user ID. Note, this will terminate all SGE jobs you have running including those not associated with this run of the pipeline (e.g. phasing/imputation or another run of the pipeline). Consult an administrator if you need to target kill the jobs associated with a specific run of the pipeline. The jobs should die relatively quickly and you will receive an e-mail from root [root@gsk.com] indicating your parent job was aborted. Assuming you didn't kill the jobs for the fun of it, follow the instructions for re-running after [changing the configuration](#ChangeConfig).





