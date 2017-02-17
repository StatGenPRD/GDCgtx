
## This script reads and processes the config.txt and associated files to setup and execute 
## the call to gtxpipe which is the main driver function of the gtx package

# Don't echo script to stdout
options(echo = FALSE)

# There is one expected argument, the working directory where input/config.txt is expected

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >=1) {
  work.dir <- args[1]
} else {
  stop("Please input [working directory]")
}
file.config = file.path(work.dir,"input/config.txt") 

# print strating time and config file path to stdout
message(Sys.time(), ": Loading ", file.config)

# Read config file as list of key-value pairs separated by =
config <- read.table(file.config, sep ="=", as.is = T, strip.white = TRUE,stringsAsFactors = FALSE, quote = "")
# Set rownames as key values (column1)
rownames(config) <- config[[1]]

# We are assuming the specified working directory with input/config is also where the log files and results should be.
# If a user wishes to "re-run" an existing input/config in a different working directory (i.e. to leave original results intact),
# they should setup their new working directory to have a symbolic link named "input" that points to the original input directory
# instead of trying to support the ability to separately specify an input path and workingdir / output path
setwd(work.dir)


## Options for project title, author name, author email
## (Note these are not used by the current pipeline code)
options(gtxpipe.project = config["project", 2])
options(gtxpipe.user = config["user", 2])
options(gtxpipe.email = config["email", 2])

options(gtxpipe.packages = c("gtx","ordinal", "survival", "MASS")) # added by Li Li


## Get location of gtx library and load
if (!is.null(config["gtxloc", 2]) & !is.na(config["gtxloc", 2])) {
  gtxloc = config["gtxloc",2]
} else {
  gtxloc = "/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages/x86_64-unknown-linux-gnu-library/3.0"
}
options(gtxpipe.libloc = gtxloc)

## If using Rstudio instead of local R3 where dependent packages are loaded, need to add library
#.libPaths("/GWD/appbase/projects/statgen/GXapp/R3.0.0/R-3.0.0/library")
.libPaths(gtxloc)
library(gtx, lib.loc = gtxloc)


## Get location of clinical data (.txt exports from SAS) it not the default input/
if (!is.null(config["clinical", 2]) & !is.na(config["clinical", 2])) {
  options(gtxpipe.clinical = config["clinical",2])
} else {
  options(gtxpipe.clinical = file.path(work.dir, "input"))
}


## Set the location of the genetic data
options(gtxpipe.genotypes = config["genotypes",2])


## Set the make command to use for executing the chunk analysis jobs

## To use distributed parallel make (SGE) with 400 threads on GSK systems,
options(gtxpipe.make = paste("/GWD/bioinfo/projects/lsf/SGE/6.2u5/bin/lx24-amd64/qmake -cwd -v PATH -v R_LIBS_USER=", gtxloc, " -l qname=dl580 -l arch=lx24-amd64 -l mt=20G -- -j 400", sep=""))
##options(gtxpipe.make = paste("/GWD/bioinfo/projects/lsf/SGE/6.2u5/bin/lx24-amd64/qmake -cwd -v PATH -v R_LIBS_USER=", gtxloc, " -l arch=lx24-amd64 -l mt=20G -- -j 400", sep=""))
## Same as above but an extra level of output for debugging
#options(gtxpipe.make = paste("/GWD/bioinfo/projects/lsf/SGE/6.2u5/bin/lx24-amd64/qmake -cwd -v PATH -v ", '-v SGE_DEBUG_LEVEL=\"3 0 0 0 0 0 0 0\"', " R_LIBS_USER=", gtxloc, " -l qname=dl580 -l arch=lx24-amd64 -l mt=3G -- -j 100", sep=""))
## explanation of SGE options
## -v PATH to inherit current PATH in each job
## -v R_LIBS_USER to specify where packages are
## -cwd to use current working dir as working dir for each job
## -l qname= to specify queue (unclear why using this queue - is it just carryover from use of this queue for imputation?)
## -l arch= to specify what types of machines (unclear if this is also just carryover from imputation where the minimac executable could only run on certain machines)
## -l mt=3G to specify 3GB memory required for each job (this is guesstimate based on prior tests of pipeline but may need to be increased for larger datasets)
## -- separates SGE options from options passed to make
## -j 400 max number of parallel jobs - a standard genome-wide imputation will have 406 chunks so there will be ~400 jobs per model/group. In theory, should be no problems maxing this out at a very high number as SGE will just "pend" any jobs over the current system/user capacity.
## -verbose 

## Parallel make with 4 threads on the current host:
## Note, this approach has not been fully tested and configured (e.g. specifying R_LIBS_USER)
#options(gtxpipe.make = "make -j 4")


## Set marker filter thresholds
options(gtxpipe.threshold.MAF = as.numeric(as.character(config["threshold.MAF", 2])))
options(gtxpipe.threshold.Rsq = as.numeric(as.character(config["threshold.Rsq", 2])))

## Set PC numbers as default covariates
no.pcs<- as.numeric(as.character(config["No.PCs", 2]))
options(gtxpipe.no.PCs = ifelse(is.na(no.pcs), 0, no.pcs))

## Some standard derivations and descriptors are provided by a data object within the gtx package (demo and pop)
data(derivations.standard.IDSL,lib.loc =gtxloc) # provides derivations.standard.IDSL and descriptors.standard.IDSL

## All other variables need to be defined & derived - read from tab-delimited table
if(!is.null(config["varfile", 2]) & !is.na(config["varfile", 2])) {
  vartable = file.path(getOption("gtxpipe.clinical"), config["varfile",2])
} else {
  vartable = file.path(getOption("gtxpipe.clinical"), "variables.txt")
}
message(Sys.time(), ": Loading ", vartable)
vars <- read.table(vartable, sep = "\t", as.is = T, header = T, strip.white = TRUE, quote = "")
## Add descriptors for project specific variables.  Note this is
## encoded in an option, not an argument to gtxpipe(), 
## because this is used by all pipeline functions to prettify output
descriptors.list = list()
for (i in 1:nrow(vars)) {
  descriptors.list = c(descriptors.list, vars$descriptor[i])
}
names(descriptors.list) = vars$variable
options(clinical.descriptors = c(descriptors.standard.IDSL, descriptors.list))


derivs<- vars[!names(vars) %in% "descriptor"]
names(derivs)<- gsub("variable", "targets", names(derivs))
derivs$deps <-unlist(lapply(derivs$targets, function(str){
  return (unlist(strsplit(str, ".", fixed = T))[1])}))
## By default, use valuesof function to use the clinical data as-is
## Need to amend so will apply whenever fun value is empty instead of only when fun column is missing
if(!"fun" %in% names(derivs)) derivs$fun <- NA
derivs$fun[is.na(derivs$fun)| nchar(derivs$fun)==0] <- paste("valuesof(", unlist(lapply(derivs$targets[is.na(derivs$fun)| nchar(derivs$fun)==0], function(str){
  return (paste(unlist(strsplit(str, ".", fixed = T))[-1], collapse = ".", sep = ""))})), ")", sep = "")
options(gtxpipe.derivations=rbind(derivs, derivations.standard.IDSL))

## Read group definitions from a table in a file
## Assumes tab-delimited
if(!is.null(config["groupfile", 2]) & !is.na(config["groupfile", 2])) {
  grouptable = file.path(getOption("gtxpipe.clinical"), config["groupfile",2])
} else {
  grouptable = file.path(getOption("gtxpipe.clinical"), "groups.txt")
}
message(Sys.time(), ": Loading ", grouptable)
groups <- read.table(grouptable,sep = "\t", 
                     as.is = T, header = T, strip.white = TRUE, quote = "")
options(gtxpipe.groups = groups)

## Read model definitions from a table in a file
## Assumes tab-delimited
if(!is.null(config["modelfile", 2]) & !is.na(config["modelfile", 2])) {
  modeltable = file.path(getOption("gtxpipe.clinical"), config["modelfile",2])
} else {
  modeltable = file.path(getOption("gtxpipe.clinical"), "models.txt")
}
message(Sys.time(), ": Loading ", modeltable)
models <- read.table(modeltable, 
                     na.strings=c('NA',''),colClasses="character", sep = "\t", 
                     as.is = T, header = T, strip.white = TRUE, quote = "", fill = TRUE)
if(!all(c("analysis",  "model") %in% names(models))) stop(paste("Please include analysis model groups in", modeltable))
for(m in c("analysis",  "model"))
  if(any(is.na(models[[m]])) | any(nchar(models[[m]])==0)) stop(paste("Please specify", m, "in", modeltable))
## Identify which variables are required from model statements
if(!"deps" %in% names(models)) models$deps <- NA
models$deps <- unlist(lapply(1:nrow(models), function(idx){
                      s1<- unique(tokenise.whitespace(unlist(strsplit(models$model[idx], split="[-(~+,*^:/|)]"))))
                      s2<- unique(tokenise.whitespace(models$deps[idx]))
                      s1<-unique(c(s1[grep(".", s1, fixed = T)], s2[s2 %in% s1]))
                      s1<-s1[!is.na(s1) & !s1 %in% c("glm.nb")]
                      if(length(s1) == 0) stop(paste("Please check dependancy for", models$analysis[idx], "in", modeltable))
                      return (paste(s1, collapse = " ", sep =""))}))
## Read in cvlist values and convert missing to empty strings
for (i in 1:nrow(models)) {
  if (!is.na(models[i,"cvlist"])) {
    models[i,"cvlist"] = paste(read.table(file.path(getwd(), "input", models[i,"cvlist"]), stringsAsFactors = FALSE, fill = TRUE)[ , 1], collapse = " ")
  }
  #Need to convert NA values to empty strings else parse attempts in gtxpipe function will fail
  if (is.na(models[i,"contrasts"]) || is.null(models[i,"contrasts"])) {
    models[i,"contrasts"] = ""
  }
  if (is.na(models[i,"groups"]) || is.null(models[i,"groups"])) {
    models[i,"groups"] = ""
  }
}
## Reorder and re-label columns to match what expected by gtxpipe
models <- models[c("analysis", "deps", "model", "groups", "contrasts", "cvlist")]
names(models) <- c("model", "deps", "fun", "groups", "contrasts", "cvlist")
options(gtxpipe.models=models)

## Read transformations from a table in a file
## Assumes tab-delimited
if(!is.null(config["transformationfile", 2]) & !is.na(config["transformationfile", 2])) {
  transtable = file.path(getOption("gtxpipe.clinical"), config["transformationfile",2])
} else {
  transtable = file.path(getOption("gtxpipe.clinical"), "transformations.txt")
}
if(file.exists(transtable)) {
  message(Sys.time(), ": Loading ", transtable)
  transformations <- read.table(transtable, 
                     na.strings=c('NA',''),colClasses="character", sep = "\t", 
                     as.is = T, header = T, strip.white = TRUE, quote = "", fill = TRUE)
  if(!all(c("targets",  "fun") %in% names(transformations))) stop(paste("Please include [targets] [fun] in", transtable))
  if(!"deps" %in% names(transformations)) transformations$deps<- NA
  ## Identify which variables are required from fun statements
  transformations$deps <- unlist(lapply(1:nrow(transformations), function(idx){
      s1<- unique(tokenise.whitespace(unlist(strsplit(transformations$fun[idx], split="[-(~+,*^:/|)]"))))
      s2<- unique(tokenise.whitespace(transformations$deps[idx]))
      s1<-unique(c(s1[grep(".", s1, fixed = T)], s2[s2 %in% s1]))
      s1<-s1[!is.na(s1)]
      if(length(s1) == 0) stop(paste("Please check dependancy for", transformations$targets[idx], "in", transtable))
      return (paste(s1, collapse = " ", sep =""))}))
} else{transformations <- NULL }
options(gtxpipe.transformations = transformations)

## Determine if user has specified stop.before.make
if(!is.null(config["stop.before.make", 2]) & !is.na(config["stop.before.make", 2])) {
  stop.before.make = config["stop.before.make", 2]
} else {
  stop.before.make = FALSE
}


gtxpipe(gtxpipe.models = getOption("gtxpipe.models"),
        gtxpipe.groups = getOption("gtxpipe.groups", data.frame(group = 'ITT', deps = 'pop.PNITT', fun = 'pop.PNITT', stringsAsFactors = FALSE)),
        gtxpipe.derivations = getOption("gtxpipe.derivations",  derivations.standard.IDSL),
        gtxpipe.transformations = getOption("gtxpipe.transformations", data.frame(NULL)),
        gtxpipe.eigenvec = config["eigenvec",2],
        stop.before.make = stop.before.make)
