#!/bin/bash

cd /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update

rm -f gtx.tar.gz install_central3.Rout
rm -fR gtx

git clone https://github.com/tobyjohnson/gtx.git

R --vanilla <<EOF
gtx.version <- system("/GWD/bioinfo/tools/bin/git --git-dir=/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update/gtx/.git \
                       log -1 --pretty=\"commit %H%nAuthor: %an <%ae>%nDate:   %ad\"",
                 intern = TRUE)
save(gtx.version, file = "/GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update/gtx/data/gtx.version.RData")
EOF

tar -czf gtx.tar.gz gtx

/GWD/appbase/projects/statgen/R3.0.0/R-3.0.0/bin/R CMD BATCH --vanilla /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/GDCgtx/package_update/install_central3.R

chmod -R 775 /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages
chgrp -R gxappdev /GWD/appbase/projects/statgen/GXapp/G-P_assoc_pipeline/R-packages
