
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
print (paste(Sys.time(), "Loading", file.config))

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


## Get location of gtx library and load
if (!is.null(config["gtxloc", 2]) & !is.na(config["gtxloc", 2])) {
  gtxloc = config["gtxloc",2]
} else {
  gtxloc = "/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages/x86_64-unknown-linux-gnu-library/3.0"
}

## If using Rstudio instead of local R3 where dependent packages are loaded, need to add library
#.libPaths("/GWD/appbase/projects/statgen/GXapp/R3.0.0/R-3.0.0/library")
.libPaths(gtxloc)
library(gtx)


## Get location of clinical data (.txt exports from SAS) it not the default input/
if (!is.null(config["clinical", 2]) & !is.na(config["clinical", 2])) {
  options(gtxpipe.clinical = config["clinical",2])
} else {
  options(gtxpipe.clinical = file.path(work.dir, "input"))
}


## Set the location of the genetic data
options(gtxpipe.genotypes = config["genotypes",2])


## Set the make command to use for executing the chunk analysis jobs

## To use distributed parallel make (SGE) with 100 threads on GSK systems,
options(gtxpipe.make = paste("/GWD/bioinfo/projects/lsf/SGE/6.2u5/bin/lx24-amd64/qmake -cwd -v PATH -v R_LIBS_USER=", gtxloc, " -l qname=dl580 -l arch=lx24-amd64 -l mt=3G -- -j 100", sep=""))
## Same as above but an extra level of output for debugging
#options(gtxpipe.make = paste("/GWD/bioinfo/projects/lsf/SGE/6.2u5/bin/lx24-amd64/qmake -cwd -v PATH -v ", '-v SGE_DEBUG_LEVEL=\"3 0 0 0 0 0 0 0\"', " R_LIBS_USER=", gtxloc, " -l qname=dl580 -l arch=lx24-amd64 -l mt=3G -- -j 100", sep=""))

## Parallel make with 4 threads on the current host:
## Note, this approach has not been fully tested and configured (e.g. specifying R_LIBS_USER)
#options(gtxpipe.make = "make -j 4")


## Set marker filter thresholds
options(gtxpipe.threshold.MAF = as.numeric(as.character(config["threshold.MAF", 2])))
options(gtxpipe.threshold.Rsq = as.numeric(as.character(config["threshold.Rsq", 2])))

## Some standard derivations and descriptors are provided by a data object within the gtx package (demo and pop)
data(derivations.standard.IDSL) # provides derivations.standard.IDSL and descriptors.standard.IDSL

## All other variables need to be defined & derived - read from tab-delimited table
if(!is.null(config["varfile", 2]) & !is.na(config["varfile", 2])) {
  vartable = file.path(getOption("gtxpipe.clinical"), config["varfile",2])
} else {
  vartable = file.path(getOption("gtxpipe.clinical"), "variables.txt")
}

vars <- read.table(vartable, sep = "\t", 
                   as.is = T, header = T, strip.white = TRUE, quote = "")

## Add descriptors for project specific variables.  Note this is
## encoded in an option, not an argument to gtxpipe(), 
## because this is used by all pipeline functions to prettify output
descriptors.list = list()
for (i in 1:nrow(vars)) {
  descriptors.list = c(descriptors.list, vars$descriptor[i])
}
names(descriptors.list) = vars$variable
options(clinical.descriptors =
          c(descriptors.standard.IDSL,
            descriptors.list))


derivs<- vars[!names(vars) %in% "descriptor"]
names(derivs)<- gsub("variable", "targets", names(derivs))
derivs$deps <-unlist(lapply(derivs$targets, function(str){
                    return (unlist(strsplit(str, ".", fixed = T))[1])}))
## By default, use valuesof function to use the clinical data as-is
## Need to amend so will apply whenever fun value is empty instead of only when fun column is missing
if(!"fun" %in% names(derivs))
  derivs$fun <- paste("valuesof(", 
                     unlist(lapply(derivs$targets, function(str){
                            return (paste(unlist(strsplit(str, ".", fixed = T))[-1], collapse = ".", sep = ""))})), 
                    ")", sep = "")

## Read group definitions from a table in a file
## Assumes tab-delimited
if(!is.null(config["groupfile", 2]) & !is.na(config["groupfile", 2])) {
  grouptable = file.path(getOption("gtxpipe.clinical"), config["groupfile",2])
} else {
  grouptable = file.path(getOption("gtxpipe.clinical"), "groups.txt")
}

groups <- read.table(grouptable,sep = "\t", 
                     as.is = T, header = T, strip.white = TRUE, quote = "")

## Read model definitions from a table in a file
## Assumes tab-delimited
if(!is.null(config["modelfile", 2]) & !is.na(config["modelfile", 2])) {
  modeltable = file.path(getOption("gtxpipe.clinical"), config["modelfile",2])
} else {
  modeltable = file.path(getOption("gtxpipe.clinical"), "models.txt")
}

models <- read.table(modeltable, 
                     na.strings=c('NA',''),colClasses="character", sep = "\t", 
                     as.is = T, header = T, strip.white = TRUE, quote = "", fill = TRUE)

## Identify which variables are required from model statements
models$deps <- unlist(lapply(models$model, function(str){
                      s1<- unlist(strsplit(str, split="[(~+,)]"))
                      return (paste(s1[grep(".", s1, fixed = T)], collapse = " ", sep =""))}))

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


## Determine if user has specified stop.before.make
if(!is.null(config["stop.before.make", 2]) & !is.na(config["stop.before.make", 2])) {
  stop.before.make = config["stop.before.make", 2]
} else {
  stop.before.make = FALSE
}


gtxpipe(gtxpipe.derivations = rbind(derivations.standard.IDSL, derivs),
        gtxpipe.groups = groups,
        gtxpipe.models = models, 
        gtxpipe.eigenvec = config["eigenvec",2],
        stop.before.make = stop.before.make)
