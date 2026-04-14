knitr::opts_knit$set(progress = TRUE, verbose = TRUE)
library(magrittr)
library(stringi)

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
    immune_with_cell_types = "./Reports/03_immune_cell_types/immune_with_cell_types.RDS",
    starCAT_counts = "./Reports/03_immune_cell_types/starCAT_input/matrix.mtx.gz",
    starCAT_barcodes = "./Reports/03_immune_cell_types/starCAT_input/barcodes.tsv.gz",
    starCAT_features = "./Reports/03_immune_cell_types/starCAT_input/features.tsv.gz"
  )
)

pipeline[["starCAT"]] = list(
  input = list(
    starCAT_counts = pipeline$immune_identity$output$starCAT_counts
  ),
  output = list(
    usage  = "./Reports/04_starCAT/ACC.rf_usage_normalized.txt",
    score = "./Reports/04_starCAT/ACC.scores.txt"
  )
); pipeline[["starCAT"]]$shell = glue::glue(
  'mkdir -p {dirname(pipeline$starCAT$output$usage)}; \\
  starcat --reference "TCAT.V1" \\
  --counts {pipeline$starCAT$input$starCAT_counts} \\
  --output-dir {dirname(pipeline$starCAT$output$usage)} --name "ACC"'
)

pipeline[["Tcells_types"]] = list(
  input = list(
    script =  "./Notebooks/04_Tcells_types.Rmd",
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types,
    starCAT_usage = pipeline$starCAT$output$usage,
    starCat_score = pipeline$starCAT$output$score
  ),
  output = list(
    report = "./Reports/04_Tcells_types/04_Tcells_types.html",
    t_cells_labled = "./Reports/04_Tcells_types/t_cells_labled.RDS",
    immune_with_Tcells = "./Reports/04_Tcells_types/immune_with_Tcells.RDS"
  )
)



pipeline[["umap_clustering"]] = list(
  input = list(
    script = "./Notebooks/04_UMAP_clustering.Rmd",
    acc_immune = pipeline$pre_process$output$acc_immune
    
  ),
  output = list(
    report = "./Reports/04_UMAP_clustering/04_UMAP_clustering.html"
  )
)

####################################### immune markers in ACC cancer cells ####################################################

pipeline[["immune_markers_ACC"]] = list(
  input = list(
    script = "./Notebooks/05_immune_markers_ACC.Rmd",
    acc_cancer_pri = pipeline$cell_types$output$acc_cancer_pri,
    immmune_genes = "input_data/all_direct_and_indirect_annotations_to_GO_immune_system_process.txt"
  ),
  output = list(
    report = "./Reports/05_immune_markers_ACC/05_immune_markers_ACC.html",
    signif_deg = "./Reports/05_immune_markers_ACC/signif_deg.rds"
    )
)



####################################### cellphoneDB per patient ######################################################

pipeline[["cpdb_create_data_per_patient"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/01_create_data_for_cellphoneDB.Rmd",
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    cancer = pipeline$cell_types$output$cancer,
    caf = pipeline$cell_types$output$caf,
    caf_signatures = "./input_data/NIHMS1678398-supplement-2.xlsx",
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types
  ),
  output = list(
    report = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/01_create_data_for_cellphoneDB/01_create_data_for_cellphoneDB.html",
    acc_cancer_Tcells_caf = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/01_create_data_for_cellphoneDB/acc_cancer_Tcells_caf.RDS",
    acc_cancer_immune_caf = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/01_create_data_for_cellphoneDB/acc_cancer_immune_caf.RDS"
  )
)

pipeline[["run_cpdb_per_patient"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB.Rmd",
    create_data_report = pipeline$cpdb_create_data_per_patient$output$report
  ),
  output = list(
    report = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB/02_run_cellphoneDB.html"
  ),
  params = list(
    cpdb_conda_env = "/sci/labs/yotamd/lab_share/avishai.wizel/python_envs/miniconda/envs/cpdb",
    cpdb_target_dir = "Reports/ccc_analysis/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB/cpdb_data/",
    cpbd_all_immune_output_dir = "Reports/ccc_analysis/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB/cpdb_out_immune/",
    cpbd_t_cells_output_dir = "Reports/ccc_analysis/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB/cpdb_out_T_cells/"
    
  )
)

pipeline[["cpdb_analysis_per_patient"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/03_celphoneDB_analysis.Rmd",
    create_data_report = pipeline$cpdb_create_data_per_patient$output$report,
    run_cpdb_per_patient_report = pipeline$run_cpdb_per_patient$output$report,
    acc_cancer_Tcells_caf = pipeline$cpdb_create_data_per_patient$output$acc_cancer_Tcells_caf,
    acc_cancer_immune_caf = pipeline$cpdb_create_data_per_patient$output$acc_cancer_immune_caf

  ),
  output = list(
    report = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/03_celphoneDB_analysis/03_celphoneDB_analysis.html"
  )
)
######################################## LIANA+Nichenet ###############################################
pipeline[["liana"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/Liana.Rmd",
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    cancer = pipeline$cell_types$output$cancer,
    caf = pipeline$cell_types$output$caf,
    caf_signatures = "./input_data/NIHMS1678398-supplement-2.xlsx",
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types),
  output = list(
    report = "Reports/07_Liana_Nichenet/07_Liana_Nichenet.html"
  )
)




######################################## Bulk deconvolution ###############################################

pipeline[["TPM_for_signature_matrix"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Creat_TPM_matrix_for_csx_signature.Rmd",
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    cancer = pipeline$cell_types$output$cancer,
    caf = pipeline$cell_types$output$caf,
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types
  ),
  output = list(
    report = "Reports/Bulk_deconv/Creat_TPM_matrix_for_csx_signature/Creat_TPM_matrix_for_csx_signature.html",
    tpm_matrix = "Reports/Bulk_deconv/Creat_TPM_matrix_for_csx_signature/acc_tpm_for_signature_matrix.txt"
  ),
  params = list(
    only_primary = F,
    top_var_genes = 10000
  )
)


pipeline[["create_dou_matrix"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/create_dou_matrix.Rmd",
    dou_acc = "input_data/Dou_PMC8450584/PMC8450584_DataSheet_1.xlsx",
    dou_clinical = "input_data/Dou_PMC8450584/PMC8450584_DataSheet_2.xlsx"
  ),
  output = list(
    dou_exprs = "Reports/Bulk_deconv/create_dou_matrix/dou_exprs.tsv",
    report = "Reports/Bulk_deconv/create_dou_matrix/create_dou_matrix.html"
  )
)

pipeline[["create_ferrarotto_matrix"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Create_Ferrarotto_TPM.Rmd",
    ferra_acc = "input_data/Ferrarotto_PMC7854509/ACC_RNAseq_PMC7854509_RPKM.xlsx"
    ),
  output = list(
    ferra_exprs = "Reports/Bulk_deconv/create_ferrarotto_matrix/ferrarotto_TPM.tsv",
    report = "Reports/Bulk_deconv/create_ferrarotto_matrix/Create_ferrarotto_TPM.html"
  )
)
# pipeline[["run_cibersortX_alert"]] = list(
#   input = list(
#     tpm_matrix = pipeline$create_data_for_CIBERSORT$output$tpm_matrix,
#     dou_exprs = pipeline$create_data_for_CIBERSORT$output$dou_exprs
#     
#   ),
#   output = list(
#     cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job9_Results_07_27_25-16_46.csv"
#     
#   )
# )

# run CIBERSORTx at cibersortx.stanford.edu

pipeline[["Dou_CIBERSORT_analysis"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Dou_CIBERSORT_analsyis.Rmd",
    dou_acc_survival = "input_data/Dou_PMC8450584/PMC8450584_DataSheet_2.xlsx",
    cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job21_Results_dou_pri_10Kvargenes_relative.csv"
  ),
  output = list(
    report = "Reports/Bulk_deconv/Dou_CIBERSORT_analsyis/Dou_CIBERSORT_analsyis.html"
  )
)

pipeline[["ferrarotto_CIBERSORT_analysis"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/ferrarotto_CIBERSORT_analysis.Rmd",
    cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job22_Results_ferrarotto_10Kvargenes_relative.csv",
    ferra_clinical = "input_data/Ferrarotto_PMC7854509/CCR2020_Clinical.xlsx"
  ),
  output = list(
    report = "Reports/Bulk_deconv/ferrarotto_CIBERSORT_analysis/ferrarotto_CIBERSORT_analysis.html"
  )
)
pipeline[["sipsic_run"]] = list(
  input = list(
    script = "./Notebooks/Pathway_analysis/09_sipsic_run.Rmd",
    acc_cancer_pri = pipeline$cell_types$output$acc_cancer_pri,
    canonical_pathways = "./input_data/h.all.v2025.1.Hs.symbols.gmt"
  ),
  output = list(
    report = "Reports/Pathway_analysis/09_sipsic_run/09_sipsic_run.html",
    sipsic_matrix = "Reports/Pathway_analysis/09_sipsic_run/sipsic_matrix.RDS"
  )
)

pipeline[["sipsic_analysis"]] = list(
  input = list(
    script = "./Notebooks/Pathway_analysis/10_sipsic_analysis.Rmd",
    acc_cancer_pri = pipeline$cell_types$output$acc_cancer_pri,
    sipsic_matrix = pipeline$sipsic_run$output$sipsic_matrix
  ),
  output = list(
    report = "Reports/Pathway_analysis/10_sipsic_analysis/10_sipsic_analysis.html"
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
    mkfile = mkfile + make_rule(targets = c(unlist(pipeline[[i]]$output),"&"), deps = unlist(pipeline[[i]]$input), #run rscript, add & for grouped tagets
                                script =paste("Rscript render.R",
                                              names(pipeline)[[i]]
                                ))
  }else{
    mkfile = mkfile + make_rule(targets = unlist(pipeline[[i]]$output), deps = unlist(pipeline[[i]]$input),
                                script = eval(pipeline[[i]]$shell))
  }
  
}


write_makefile(makefile = mkfile,file_name = "Makefile")

