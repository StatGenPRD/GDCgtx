options(echo = FALSE)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) >=1) {
  work.dir <- args[1]
} else {
  stop("Please input [working directory]")
}
file.config = file.path(work.dir,"input/config.txt")
print (paste(Sys.time(), "Loading", file.config))

config <- read.table(file.config, sep ="=", as.is = T, strip.white = TRUE,stringsAsFactors = FALSE, quote = "")
rownames(config) <- config[[1]]

setwd(work.dir)

## Options for project title, author name, author email
## (Note these are not used by the current pipeline code)
options(gtxpipe.project = config["project", 2])
options(gtxpipe.user = config["user", 2])
options(gtxpipe.email = config["email", 2])


## Set location of gtx library
if (!is.null(config["gtxloc", 2]) & !is.na(config["gtxloc", 2])) {
  gtxloc = config["gtxloc",2]
} else {
  gtxloc = "/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages/x86_64-unknown-linux-gnu-library/3.0"
}

.libPaths(gtxloc)

library(gtx)

## Clinical data (.txt exports from SAS) are in the default location
## "workingdir/input".  If in a different location, this should be specified
## with an option like:
if (!is.null(config["clinical", 2]) & !is.na(config["clinical", 2])) {
  options(gtxpipe.clinical = config["clinical",2])
} else {
  options(gtxpipe.clinical = file.path(getwd(), "input"))
}

## Default location for genotype data (.dose.gz and .into.gz from
## minimac) are not in the default location "genotypes", hence need to
## specify the location with an option:
options(gtxpipe.genotypes = config["genotypes",2])

## System specific command to run make must be specified with an
## option.  Parallel make with 4 threads on the current host:
#options(gtxpipe.make = "make -j 4")
## To use distributed parallel make with 64 threads on GSK systems,
## use the following option instead:
#options(gtxpipe.make = "qmake -cwd -v PATH -v R_LIBS_USER=/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages/x86_64-unknown-linux-gnu-library/3.0 -l qname=dl580 -l arch=lx24-amd64 -- -j 400")
#options(gtxpipe.make = "qmake -cwd -v SGE_DEBUG_LEVEL=\"3 0 0 0 0 0 0 0\" -v PATH -v R_LIBS_USER=/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages/x86_64-unknown-linux-gnu-library/3.0 -l qname=dl580 -l arch=lx24-amd64 -- -j 400")
options(gtxpipe.make = paste("/GWD/bioinfo/projects/lsf/SGE/6.2u5/bin/lx24-amd64/qmake -cwd -v PATH -v R_LIBS_USER=", gtxloc, " -l qname=dl580 -l arch=lx24-amd64 -l mt=3G -- -j 100", sep=""))


options(gtxpipe.threshold.MAF = as.numeric(as.character(config["threshold.MAF", 2])))
options(gtxpipe.threshold.Rsq = as.numeric(as.character(config["threshold.Rsq", 2])))

## Some standard derivations and descriptors are provided by a data object within the 'gtx' package (demo and pop)
data(derivations.standard.IDSL) # provides derivations.standard.IDSL and descriptors.standard.IDSL

## All other variables need to be defined & derived - read from table
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

#Read derivations from a table in a file
#Assumes tab-delimited (e.g. saved from Excel)
deriv<- vars[!names(vars) %in% "descriptor"]
names(deriv)<- gsub("variable", "targets", names(deriv))
deriv$deps <-unlist(lapply(deriv$targets, function(str){
                    return (unlist(strsplit(str, ".", fixed = T))[1])}))
if(!"fun" %in% names(deriv))
  deriv$fun <- paste("valuesof(", 
                     unlist(lapply(deriv$targets, function(str){
                            return (paste(unlist(strsplit(str, ".", fixed = T))[-1], collapse = ".", sep = ""))})), 
                    ")", sep = "")

#Read group definitions from a table in a file
#Assumes tab-delimited (e.g. saved from Excel)
if(!is.null(config["groupfile", 2]) & !is.na(config["groupfile", 2])) {
  grouptable = file.path(getOption("gtxpipe.clinical"), config["groupfile",2])
} else {
  grouptable = file.path(getOption("gtxpipe.clinical"), "groups.txt")
}

groups <- read.table(grouptable,sep = "\t", 
                     as.is = T, header = T, strip.white = TRUE, quote = "")

#Read model definitions from a table in a file
#Assumes tab-delimited (e.g. saved from Excel)
if(!is.null(config["modelfile", 2]) & !is.na(config["modelfile", 2])) {
  modeltable = file.path(getOption("gtxpipe.clinical"), config["modelfile",2])
} else {
  modeltable = file.path(getOption("gtxpipe.clinical"), "models.txt")
}

models <- read.table(modeltable, 
                     na.strings=c('NA',''),colClasses="character", sep = "\t", 
                     as.is = T, header = T, strip.white = TRUE, quote = "", fill = TRUE)
models$deps <- unlist(lapply(models$model, function(str){
                      s1<- unlist(strsplit(str, split="[(~+,)]"))
                      return (paste(s1[grep(".", s1, fixed = T)], collapse = " ", sep =""))}))
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
models <- models[c("analysis","deps",  "model",	"groups",	"contrasts","cvlist")]
names(models) <- c("model", "deps", "fun", "groups", "contrasts","cvlist")


## Determine if user has specified stop.before.make
if(!is.null(config["stop.before.make", 2]) & !is.na(config["stop.before.make", 2])) {
  stop.before.make = config["stop.before.make", 2]
} else {
  stop.before.make = FALSE
}


gtxpipe(gtxpipe.derivations = rbind(derivations.standard.IDSL, deriv),
        gtxpipe.groups = groups,
        gtxpipe.models = models, 
        gtxpipe.eigenvec = config["eigenvec",2],
        stop.before.make = stop.before.make)
