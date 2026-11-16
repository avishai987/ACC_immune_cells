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

pipeline[["caf_subtypes"]] = list(
  input = list(
    script = "./Notebooks/CAF_subtypes.Rmd",
    caf = pipeline$cell_types$output$caf,
    caf_signatures = "./input_data/NIHMS1678398-supplement-2.xlsx"
  ),
  output = list(
    report = "./Reports/CAF_subtypes/CAF_subtypes.html",
    caf_with_subtypes = "./Reports/CAF_subtypes/caf_with_subtypes.RDS"
  )
)

pipeline[["umap_clustering"]] = list(
  input = list(
    script = "./Notebooks/05_UMAP_clustering.Rmd",
    acc_immune = pipeline$pre_process$output$acc_immune,
    acc_cancer_pri = pipeline$cell_types$output$acc_cancer_pri,
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types,
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    caf_with_subtypes = pipeline$caf_subtypes$output$caf_with_subtypes,
    caf_signatures = "./input_data/NIHMS1678398-supplement-2.xlsx"
  ),
  output = list(
    report = "./Reports/05_UMAP_clustering/05_UMAP_clustering.html"
  )
)

####################################### immune markers in ACC cancer cells ####################################################

pipeline[["cancer_pathway_analysis"]] = list(
  input = list(
    script = "./Notebooks/06_immune_markers_ACC.Rmd",
    acc_cancer_pri = pipeline$cell_types$output$acc_cancer_pri,
    immmune_genes = "input_data/all_direct_and_indirect_annotations_to_GO_immune_system_process.txt"
  ),
  output = list(
    report = "./Reports/06_immune_markers_ACC/06_immune_markers_ACC.html",
    signif_deg = "./Reports/06_immune_markers_ACC/signif_deg.rds"
    )
)


######################################## LIANA+Nichenet ###############################################
# pipeline[["run_liana"]] = list(
#   input = list(
#     script = "./Notebooks/ccc_analysis/run_LIANA.Rmd",
#     t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
#     cancer = pipeline$cell_types$output$cancer,
#     caf = pipeline$cell_types$output$caf,
#     caf_signatures = "./input_data/NIHMS1678398-supplement-2.xlsx",
#     immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types),
#   output = list(
#     report = "Reports/ccc_analysis/run_LIANA/run_LIANA.html",
#     liana_result = "Reports/ccc_analysis/run_LIANA/liana_result.RDS"
#   )
# )


# pipeline[["liana"]] = list(
#   input = list(
#     script = "./Notebooks/ccc_analysis/Liana.Rmd",
#     liana_result = pipeline$run_liana$output$liana_result
#   ),
#   output = list(
#     report = "Reports/ccc_analysis/Liana/Liana.html"
#   )
# )


# run with --cpus-per-task=4 --mem=45G 
pipeline[["run_liana_per_patient"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/run_LIANA_per_patient.Rmd",
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    cancer = pipeline$cell_types$output$cancer,
    caf_with_subtypes = pipeline$caf_subtypes$output$caf_with_subtypes,
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types),

  params = list(
    debug = F,
    split_naive = T
  )
)
  if(pipeline$run_liana_per_patient$params$split_naive){split_naive_str = "split_naive"}else{split_naive_str = "keep_naive"}
  pipeline[["run_liana_per_patient"]]$output = list(
    liana_result_CD45_caf = paste0("Reports/ccc_analysis/run_LIANA_per_patient/",split_naive_str,"/liana_result_CD45-caf.RDS"),
    liana_result_CD45_cancer = paste0("Reports/ccc_analysis/run_LIANA_per_patient/",split_naive_str,"/liana_result_CD45-cancer.RDS"),
    liana_result_CD45_lum_myo = paste0("Reports/ccc_analysis/run_LIANA_per_patient/",split_naive_str,"/liana_result_CD45-lum-myo.RDS"),
    report = paste0("Reports/ccc_analysis/run_LIANA_per_patient/",split_naive_str,"/run_LIANA_per_patient",".html") 
  )

pipeline[["Liana_per_patient"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/LIANA_per_patient.Rmd",
    liana_result_CD45_caf = pipeline$run_liana_per_patient$output$liana_result_CD45_caf,
    liana_result_CD45_cancer = pipeline$run_liana_per_patient$output$liana_result_CD45_cancer,
    liana_result_CD45_lum_myo = pipeline$run_liana_per_patient$output$liana_result_CD45_lum_myo
  ),
  params = list(
    debug = F,
    threshold = 0.01
  )
)
  pipeline[["Liana_per_patient"]]$output = list(
    report = paste0("Reports/ccc_analysis/Liana_per_patient/",split_naive_str,"_", pipeline$Liana_per_patient$params$threshold, "/Liana_per_patient.html")
  )


pipeline[["pathways_for_Nichenet"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/pathways_for_Nichenet.Rmd",
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    caf_with_subtypes = pipeline$caf_subtypes$output$caf_with_subtypes,
    starCAT_pathways_metadata = "input_data/starCAT/starCAT_PMC11092745_Supplementary_Tables.xlsx"
  ),
  output = list(
    report = "Reports/ccc_analysis/pathways_for_Nichenet/pathways_for_Nichenet.html",
    T_pathways_for_Nichenet = "Reports/ccc_analysis/pathways_for_Nichenet/T_pathways_for_Nichenet.RDS"
  )
)
pipeline[["nichenet_analysis"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/Nichenet.Rmd",
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    cancer = pipeline$cell_types$output$cancer,
    caf_with_subtypes = pipeline$caf_subtypes$output$caf_with_subtypes,
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types,
    liana_result_CD45_caf = pipeline$run_liana_per_patient$output$liana_result_CD45_caf,
    liana_result_CD45_cancer = pipeline$run_liana_per_patient$output$liana_result_CD45_cancer,
    liana_result_CD45_lum_myo = pipeline$run_liana_per_patient$output$liana_result_CD45_lum_myo,
    T_pathways_for_Nichenet = pipeline$pathways_for_Nichenet$output$T_pathways_for_Nichenet,
    starCAT_pathways_metadata = "input_data/starCAT/starCAT_PMC11092745_Supplementary_Tables.xlsx"
  ),
  output = list(
    report = "Reports/ccc_analysis/Nichenet_analysis/Nichenet.html",
    all_significant_interactions = "Reports/ccc_analysis/Nichenet_analysis/all_significant_interactions.RDS"
  )
)

pipeline[["Nichenet_targets_GSEA"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/Nichenet_targets_GSEA.Rmd",
    acc_cancer_pri = pipeline$cell_types$output$acc_cancer_pri,
    acc_caf_cells = pipeline$cell_types$output$caf,
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    caf_with_subtypes = pipeline$caf_subtypes$output$caf_with_subtypes,
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types,
    liana_result_CD45_lum_myo = pipeline$run_liana_per_patient$output$liana_result_CD45_lum_myo,
    T_pathways_for_Nichenet = pipeline$pathways_for_Nichenet$output$T_pathways_for_Nichenet,
    starCAT_pathways_metadata = "input_data/starCAT/starCAT_PMC11092745_Supplementary_Tables.xlsx"
  ),
  params = list(
    threshold = pipeline$Liana_per_patient$params$threshold,
    split_naive = pipeline$run_liana_per_patient$params$split_naive
    )
  )

  pipeline[["Nichenet_targets_GSEA"]]$output = list(
  report = paste0("Reports/ccc_analysis/Nichenet_targets_GSEA/", pipeline[["Nichenet_targets_GSEA"]]$params$threshold,"_",split_naive_str,"/Nichenet_targets_GSEA.html")
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
pipeline[["create_brayer_matrix"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/create_Brayer_TPM.Rmd",
    TX_counts = "input_data/Brayer_PMC10000625_and_PMC5800907/TX_All_Genes_Data.csv",
    DK_counts = "input_data/Brayer_PMC10000625_and_PMC5800907/DK_All_Genes_Data.csv"
      ),
  output = list(
    brayer_exprs = "Reports/Bulk_deconv/create_brayer_matrix/brayer_TPM.tsv",
    report = "Reports/Bulk_deconv/create_brayer_matrix/Create_brayer_TPM.html"
  )
)

pipeline[["Dou_CIBERSORT_analysis"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Dou_CIBERSORT_analsyis.Rmd",
    dou_acc_survival = "input_data/Dou_PMC8450584/PMC8450584_DataSheet_2.xlsx",
    cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job16_Results_dou_all_withMarkers_relative_bBatchcorrect_2025_09_29.csv"
  ),
  output = list(
    report = "Reports/Bulk_deconv/Dou_CIBERSORT_analsyis/Dou_CIBERSORT_analsyis.html"
  )
)


pipeline[["ferrarotto_CIBERSORT_analysis"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Ferrarotto_CIBERSORT_analsyis.Rmd",
    cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job25_Results_ferrarotto_withMarkers_relative_bBatchcorrect.csv",
    ferra_clinical = "input_data/Ferrarotto_PMC7854509/CCR2020_Clinical.xlsx"
  ),
  output = list(
    report = "Reports/Bulk_deconv/ferrarotto_CIBERSORT_analysis/ferrarotto_CIBERSORT_analysis.html"
  )
)

pipeline[["Brayer_CIBERSORT_analysis"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Brayer_CIBERSORT_analysis.Rmd",
    DK_clinical = "./input_data/Brayer_PMC10000625_and_PMC5800907/DK_sample_data_table2.csv",
    TX_clinical = "./input_data/Brayer_PMC10000625_and_PMC5800907/TX_sample_data_table2.csv",
    cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job31_Results.csv"
  ),
  output = list(
    report = "Reports/Bulk_deconv/brayer_CIBERSORT_analsyis/brayer_CIBERSORT_analsyis.html"
  )
)

pipeline[["Comm_analysis_bulk"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Comm_analysis_bulk.qmd",
    cs_result_dou = "input_data/CIBERSORTx_result/CIBERSORTx_Job16_Results_dou_all_withMarkers_relative_bBatchcorrect_2025_09_29.csv",
    cs_result_ferrarotto = "input_data/CIBERSORTx_result/CIBERSORTx_Job25_Results_ferrarotto_withMarkers_relative_bBatchcorrect.csv",
    cs_result_brayer = "input_data/CIBERSORTx_result/CIBERSORTx_Job31_Results.csv",
    dou_exprs = pipeline$create_dou_matrix$output$dou_exprs,
    ferra_exprs = pipeline$create_ferrarotto_matrix$output$ferra_exprs,
    brayer_exprs = pipeline$create_brayer_matrix$output$brayer_exprs,
    liana_result_CD45_lum_myo = pipeline$run_liana_per_patient$output$liana_result_CD45_lum_myo
  ),
  output = list(
    report = "Reports/Bulk_deconv/Comm_analysis_bulk/Comm_analysis_bulk.html"
  )
)

pipeline[["Survival_analysis"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Survival.Qmd",
    dou_exprs = pipeline$create_dou_matrix$output$dou_exprs,
    ferra_exprs = pipeline$create_ferrarotto_matrix$output$ferra_exprs,
    brayer_exprs = pipeline$create_brayer_matrix$output$brayer_exprs,
    dou_acc_survival = "input_data/Dou_PMC8450584/PMC8450584_DataSheet_2.xlsx",
    ferra_clinical = "input_data/Ferrarotto_PMC7854509/CCR2020_Clinical.xlsx",
    DK_clinical = "./input_data/Brayer_PMC10000625_and_PMC5800907/DK_sample_data_table2.csv",
    TX_clinical = "./input_data/Brayer_PMC10000625_and_PMC5800907/TX_sample_data_table2.csv",
    cs_result_dou = "input_data/CIBERSORTx_result/CIBERSORTx_Job16_Results_dou_all_withMarkers_relative_bBatchcorrect_2025_09_29.csv",
    cs_result_ferrarotto = "input_data/CIBERSORTx_result/CIBERSORTx_Job25_Results_ferrarotto_withMarkers_relative_bBatchcorrect.csv",
    cs_result_brayer = "input_data/CIBERSORTx_result/CIBERSORTx_Job31_Results.csv"


  ),
  output = list(
    report = "Reports/Bulk_deconv/Survival/Survival.html"
  )
)


######################################## Pathway_analysis ###############################################


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
    script = "./Notebooks/Pathway_analysis/10_sipsic_analysis.qmd",
    acc_cancer_pri = pipeline$cell_types$output$acc_cancer_pri,
    sipsic_matrix = pipeline$sipsic_run$output$sipsic_matrix
  ),
  output = list(
    report = "Reports/Pathway_analysis/10_sipsic_analysis/10_sipsic_analysis.html"
  )
)




source("utils/write_makefile.r")
write_makefile_with_pipeline(pipeline, file_name = "Makefile")

source("utils/save_pipeline_graph.r")
save_pipeline_graph(makefile = "Makefile", output_file = "pipeline_interactive.html")

