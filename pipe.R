knitr::opts_knit$set(progress = TRUE, verbose = TRUE)
library(magrittr)
library(stringr)

pipeline = list()

####################################### pre process ####################################################


pipeline[["pre_process"]] = list(
  input = list(
    script = "./Notebooks/01_pre-process.Rmd",
    feb24_1 = "./input_data/raw_counts/Feb24_1",
    feb24_2 = "./input_data/raw_counts/Feb24_2",
    SN0276364 = "./input_data/raw_counts/SN0276364",
    SN0276892 = "./input_data/raw_counts/SN0276892",
    acc_cancer =  "./input_data/raw_counts/GSE210171_acc_scrnaseq_counts.txt"
  ),
  output = list(
    report ="./Reports/01_pre-process/01_pre-process.html",
    acc_immune = "./Reports/01_pre-process/acc_immune.RDS"
  )
)

pipeline[["cell_types"]] = list(
  input = list(
    script = "./Notebooks/02_cell_type_assignment.Rmd",
    acc_immune = pipeline$pre_process$output$acc_immune,
    kaye_acc_genes = "input_data/oncotarget-05-12528-s001_acchigh.txt"
  ),
  output = list(
    report = "./Reports/02_cell_type_assignment/02_cell_type_assignment.html",
    immune = "./Reports/02_cell_type_assignment/immune.RDS",
    cancer = "./Reports/02_cell_type_assignment/cancer.RDS",
    acc_cancer_pri = "./Reports/02_cell_type_assignment/acc_cancer_pri.RDS",
    caf = "./Reports/02_cell_type_assignment/caf.RDS"
  )
)

pipeline[["immune_identity"]] = list(
  input = list(
    script = "./Notebooks/03_immune_cell_types.Rmd",
    immune = pipeline$cell_types$output$immune
  ),
  output = list(
    report = "./Reports/03_immune_cell_types/03_immune_cell_types.html",
    immune_with_cell_types = "./Reports/03_immune_cell_types/immune_with_cell_types.RDS"
  )
)


pipeline[["umap_clustering"]] = list(
  input = list(
    script = "./Notebooks/03.1_UMAP_clustering.Rmd",
    acc_immune = pipeline$pre_process$output$acc_immune
    
  ),
  output = list(
    report = "./Reports/03.1_UMAP_clustering/03.1_UMAP_clustering.html"
  )
)

####################################### immune markers ####################################################

pipeline[["immune_markers_ACC"]] = list(
  input = list(
    script = "./Notebooks/04_immune_markers_ACC.Rmd",
    acc_cancer_pri = pipeline$cell_types$output$acc_cancer_pri,
    immmune_genes = "input_data/all_direct_and_indirect_annotations_to_GO_immune_system_process.txt"
  ),
  output = list(
    report = "./Reports/04_immune_markers_ACC/04_immune_markers_ACC.html",
    signif_deg = "./Reports/04_immune_markers_ACC/signif_deg.rds"
    )
)


####################################### cellphoneDB ######################################################

pipeline[["cpdb_create_data"]] = list(
  input = list(
    script = "./Notebooks/05_cellphoneDB/01_create_data_for_cellphoneDB.Rmd",
    immune = pipeline$immune_identity$output$immune_with_cell_types,
    cancer = pipeline$cell_types$output$cancer,
    caf = pipeline$cell_types$output$caf
  ),
  output = list(
    report = "Reports/05_cellphoneDB/01_create_data_for_cellphoneDB/01_create_data_for_cellphoneDB.html",
    cells_identity = "Reports/05_cellphoneDB/01_create_data_for_cellphoneDB/cells_identity.tsv",
    cells_environment = "Reports/05_cellphoneDB/01_create_data_for_cellphoneDB/cells_environment.tsv",
    counts = "Reports/05_cellphoneDB/01_create_data_for_cellphoneDB/counts.txt",
    acc_cancer_cd45_caf = "Reports/05_cellphoneDB/01_create_data_for_cellphoneDB/acc_cancer_cd45_caf.RDS"
    )
)

pipeline[["run_cpdb"]] = list(
  input = list(
    script = "./Notebooks/05_cellphoneDB/02_run_cellphoneDB.Rmd",
    cells_identity = pipeline$cpdb_create_data$output$cells_identity,
    cells_environment =  pipeline$cpdb_create_data$output$cells_environment,
    counts =  pipeline$cpdb_create_data$output$counts
  ),
  output = list(
    report = "Reports/05_cellphoneDB/02_run_cellphoneDB/02_run_cellphoneDB.html"
  ),
  params = list(
    cpdb_conda_env = "/sci/labs/yotamd/lab_share/avishai.wizel/python_envs/miniconda/envs/cpdb",
    cpdb_target_dir = "Reports/05_cellphoneDB/02_run_cellphoneDB/cpdb_data/",
    cpbd_output_dir = "Reports/05_cellphoneDB/02_run_cellphoneDB/cpdb_out/"
  )
)

pipeline[["cpdb_analysis"]] = list(
  input = list(
    script = "./Notebooks/05_cellphoneDB/03_celphoneDB_analysis.Rmd",
    pvals = pipeline$run_cpdb$params$cpbd_output_dir %s+% "statistical_analysis_pvalues_.txt",
    means =   pipeline$run_cpdb$params$cpbd_output_dir %s+% "statistical_analysis_means_.txt",
    acc_cancer_cd45_caf = pipeline$cpdb_create_data$output$acc_cancer_cd45_caf,
    signif_deg = pipeline$immune_markers_ACC$output$signif_deg
    ),
  output = list(
    report = "Reports/05_cellphoneDB/03_celphoneDB_analysis/03_celphoneDB_analysis.html"
  )
)

######################################## Dou et al CIBERSORT ###############################################

pipeline[["create_data_for_CIBERSORT"]] = list(
  input = list(
    script = "./Notebooks/06_create_data_for_CIBERSORT.Rmd",
    acc_cancer_cd45_caf = pipeline$cpdb_create_data$output$acc_cancer_cd45_caf,
    dou_acc = "input_data/Dou_PMC8450584/PMC8450584_DataSheet_1.xlsx"
  ),
  output = list(
    report = "Reports/06_create_data_for_CIBERSORT.Rmd/06_Dou_CIBERSORT.html"
  )
)

# run CIBERSORTx at cibersortx.stanford.edu

pipeline[["Dou_CIBERSORT_analysis"]] = list(
  input = list(
    script = "./Notebooks/07_Dou_CIBERSORT_analsyis.Rmd",
    dou_acc_survival = "input_data/Dou_PMC8450584/PMC8450584_DataSheet_2.xlsx",
    cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job9_Results_07_27_25-16_46.csv"
  ),
  output = list(
    report = "Reports/07_Dou_CIBERSORT_analsyis/07_Dou_CIBERSORT_analsyis.html"
  )
)


######################################## make ###############################################
library(MakefileR)
mkfile = makefile() 
all_rules = c()
mkfile = mkfile + make_rule(".Phony", "all")
for (i in 1:length(pipeline)) {
  all_rules = c(all_rules,  names(pipeline)[[i]])
}
mkfile = mkfile + make_rule("all", all_rules)

for (i in 1:length(pipeline)) {
  mkfile = mkfile +   make_comment(c("============", names(pipeline)[[i]], "============")) + # comment
    make_rule(names(pipeline)[[i]], unlist(pipeline[[i]]$output), paste("@echo  $@ is up to date") ) #define rule output
  if(is.null(pipeline[[i]]$shell)){
    mkfile = mkfile + make_rule(targets = unlist(pipeline[[i]]$output), deps = unlist(pipeline[[i]]$input), #run rscript, add & for grouped tagets
                                script =paste("Rscript render.R",
                                              names(pipeline)[[i]]
                                ))
  }else{
    mkfile = mkfile + make_rule(targets = unlist(pipeline[[i]]$output), deps = unlist(pipeline[[i]]$input),
                                script = eval(pipeline[[i]]$shell))
  }
  
}


write_makefile(makefile = mkfile,file_name = "Makefile")

#################################### makepipe ####################################################################

# 
# library(makepipe)
# makepipe::reset_pipeline()
# makepipe_pipe <- get_pipeline()
# 
# 
# script = pipeline[[1]]$input$script
# make_with_recipe(
#   recipe = my_render(notebook_path =pipeline[[1]]$input$script),
#   targets = unlist(get_output(script)),
#   dependencies = unlist(get_input(script)),
#   label = get_label(script),build = F
# )
# 
# script = pipeline[[2]]$input$script
# make_with_recipe(
#   recipe = my_render(notebook_path =pipeline[[2]]$input$script),
#   targets = unlist(get_output(script)),
#   dependencies = unlist(get_input(script)),
#   label = get_label(script),build = F
# )
# 
# script = pipeline[[3]]$input$script
# make_with_recipe(
#   recipe = my_render(notebook_path =pipeline[[3]]$input$script),
#   targets = unlist(get_output(script)),
#   dependencies = unlist(get_input(script)),
#   label = get_label(script),build = F
# )
# 
# script = pipeline[[4]]$input$script
# make_with_recipe(
#   recipe = my_render(notebook_path =pipeline[[4]]$input$script),
#   targets = unlist(get_output(script)),
#   dependencies = unlist(get_input(script)),
#   label = get_label(script),build = F
# )

# script = pipeline[[5]]$input$script
# make_with_recipe(
#   recipe = my_render(notebook_path =pipeline[[5]]$input$script),
#   targets = unlist(get_output(script)),
#   dependencies = unlist(get_input(script)),
#   label = get_label(script),build = F
# )
# 
# script = pipeline[[6]]$input$script
# make_with_recipe(
#   recipe = my_render(notebook_path =pipeline[[6]]$input$script),
#   targets = unlist(get_output(script)),
#   dependencies = unlist(get_input(script)),
#   label = get_label(script),build = F
# )
# 
# script = pipeline[[7]]$input$script
# make_with_recipe(
#   recipe = my_render(notebook_path =pipeline[[7]]$input$script),
#   targets = unlist(get_output(script)),
#   dependencies = unlist(get_input(script)),
#   label = get_label(script),build = F
# )