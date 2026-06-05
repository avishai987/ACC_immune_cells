install.packages("MakefileR")
devtools::install_github("avishai987/print.rmd.tabs")
devtools::install_github("avishai987/SourceFromGithub")
devtools::install_github('zktuong/ktplots@1bd30b5', dependencies = F)
devtools::install_github("montilab/hypeR@e407bf1", dependencies = F) # cannot install with conda due to https://github.com/montilab/hypeR/issues/58
remotes::install_github("saezlab/liana@6cab46c",  upgrade = "never")
pak::pkg_install("saeyslab/nichenetr@2d5c1ab", upgrade = FALSE,ask = T) # run from terminal
pak::pkg_install("gdiff", upgrade = FALSE,ask = T) # run from terminal


