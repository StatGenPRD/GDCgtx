#cmd: /GWD/appbase/projects/statgen/GXapp/R3.0.0/R-3.0.0/bin/R --vanilla --args /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update/lili/config_postanalysis.txt </GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update/lili/runpostanalysis.r 2>test.log

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >=1) {
  configFile <- args[1]
} else {
  stop("Please input [config file with full path]")
}

library(gtx, lib.loc = "/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages/x86_64-unknown-linux-gnu-library/3.0")
postanalysis.pipeline(configFile)
