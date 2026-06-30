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



####################################### cellphoneDB per patient ######################################################

# pipeline[["cpdb_create_data_per_patient"]] = list(
#   input = list(
#     script = "./Notebooks/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/01_create_data_for_cellphoneDB.Rmd",
#     t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
#     cancer = pipeline$cell_types$output$cancer,
#     caf = pipeline$cell_types$output$caf,
#     caf_signatures = "./input_data/NIHMS1678398-supplement-2.xlsx",
#     immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types
#   ),
#   output = list(
#     report = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/01_create_data_for_cellphoneDB/01_create_data_for_cellphoneDB.html",
#     acc_cancer_Tcells_caf = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/01_create_data_for_cellphoneDB/acc_cancer_Tcells_caf.RDS",
#     acc_cancer_immune_caf = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/01_create_data_for_cellphoneDB/acc_cancer_immune_caf.RDS"
#   )
# )

# pipeline[["run_cpdb_per_patient"]] = list(
#   input = list(
#     script = "./Notebooks/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB.Rmd",
#     create_data_report = pipeline$cpdb_create_data_per_patient$output$report
#   ),
#   output = list(
#     report = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB/02_run_cellphoneDB.html"
#   ),
#   params = list(
#     cpdb_conda_env = "/sci/labs/yotamd/lab_share/avishai.wizel/python_envs/miniconda/envs/cpdb",
#     cpdb_target_dir = "Reports/ccc_analysis/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB/cpdb_data/",
#     cpbd_all_immune_output_dir = "Reports/ccc_analysis/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB/cpdb_out_immune/",
#     cpbd_t_cells_output_dir = "Reports/ccc_analysis/06_V2_cellphoneDB_per_patient/02_run_cellphoneDB/cpdb_out_T_cells/"
    
#   )
# )

# pipeline[["cpdb_analysis_per_patient"]] = list(
#   input = list(
#     script = "./Notebooks/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/03_celphoneDB_analysis.Rmd",
#     create_data_report = pipeline$cpdb_create_data_per_patient$output$report,
#     run_cpdb_per_patient_report = pipeline$run_cpdb_per_patient$output$report,
#     acc_cancer_Tcells_caf = pipeline$cpdb_create_data_per_patient$output$acc_cancer_Tcells_caf,
#     acc_cancer_immune_caf = pipeline$cpdb_create_data_per_patient$output$acc_cancer_immune_caf

#   ),
#   output = list(
#     report = "Reports/ccc_analysis/cpdb/06_V2_cellphoneDB_per_patient/03_celphoneDB_analysis/03_celphoneDB_analysis.html"
#   )
# )
######################################## LIANA+Nichenet ###############################################
pipeline[["run_liana"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/run_LIANA.Rmd",
    t_cells_labled = pipeline$Tcells_types$output$t_cells_labled,
    cancer = pipeline$cell_types$output$cancer,
    caf = pipeline$cell_types$output$caf,
    caf_signatures = "./input_data/NIHMS1678398-supplement-2.xlsx",
    immune_with_cell_types = pipeline$immune_identity$output$immune_with_cell_types),
  output = list(
    report = "Reports/ccc_analysis/run_LIANA/run_LIANA.html",
    liana_result = "Reports/ccc_analysis/run_LIANA/liana_result.RDS"
  )
)


pipeline[["liana"]] = list(
  input = list(
    script = "./Notebooks/ccc_analysis/Liana.Rmd",
    liana_result = pipeline$run_liana$output$liana_result
  ),
  output = list(
    report = "Reports/ccc_analysis/Liana/Liana.html"
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
    cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job23_Results_dou_all_10Kvargenes_relative_bBatchcorrection.csv"
  ),
  output = list(
    report = "Reports/Bulk_deconv/Dou_CIBERSORT_analsyis/Dou_CIBERSORT_analsyis.html"
  )
)


pipeline[["ferrarotto_CIBERSORT_analysis"]] = list(
  input = list(
    script = "./Notebooks/Bulk_deconv/Ferrarotto_CIBERSORT_analsyis.Rmd",
    cs_result = "./input_data/CIBERSORTx_result/CIBERSORTx_Job30_Results.csv",
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
    cs_result = "input_data/CIBERSORTx_result/CIBERSORTx_Job28_Results_brayer_10Kvargenes_relative_bBatchCorrection.csv"
  ),
  output = list(
    report = "Reports/Bulk_deconv/brayer_CIBERSORT_analsyis/brayer_CIBERSORT_analsyis.html"
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
    script = "./Notebooks/Pathway_analysis/10_sipsic_analysis.qmd",
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


library(gdiff)

save_pdf_if_changed <- function(plot_expr, target_path, width = 7, height = 5, force = F) {
  if (force) {
    # If force is TRUE, skip the comparison and directly save the plot
    pdf(target_path, width = width, height = height)
    if (inherits(plot_expr, "ggplot")) {
      print(plot_expr)
    } else {
      force(plot_expr) 
    }
    dev.off()
    message("Plot saved without comparison due to force = TRUE.")
    return(TRUE)
  }
  # 1. Create a path for a temporary file in the system
  temp_file <- tempfile(fileext = ".pdf")
  
  # 2. Open the PDF device with dynamic dimensions and save the plot
  pdf(temp_file, width = width, height = height)
  
  # Check if the plot is a ggplot object (which requires the print() function to render)
  if (inherits(plot_expr, "ggplot")) {
    print(plot_expr)
  } else {
    # Force evaluation of the plot code for Base R graphics
    force(plot_expr) 
  }
  
  # Close the PDF device to finalize the temporary file write
  dev.off()
  
  # 3. Check if the target file already exists
  if (file.exists(target_path)) {
    # samePDF() compares the two PDFs byte-by-byte but automatically
    # ignores volatile metadata like CreationDate, ModDate, and PDF IDs
    if (samePDF(temp_file, target_path)) {
      message("The plot has not changed (ignoring PDF metadata). Existing file kept.")
      unlink(temp_file) # Clean up the temporary file
      return(FALSE)    # Exit the function without modifying the disk
    }
  }
  
  # 4. If the file does not exist, or visual content/dimensions differ -> copy and overwrite
  file.copy(temp_file, target_path, overwrite = TRUE)
  unlink(temp_file) # Clean up the temporary file
  
  message("The plot or dimensions changed (or file did not exist). The PDF file was successfully updated!")
  return(TRUE)
}


#plot graph


library(igraph)
library(ggraph)
library(ggplot2)

# 1. קריאת קובץ ה-Makefile וה-Parser
makefile_path <- "Makefile"
if (!file.exists(makefile_path)) {
  stop("קובץ Makefile לא נמצא בתיקיית העבודה הנוכחית!")
}
makefile_lines <- readLines(makefile_path)

from_nodes <- c()
to_nodes <- c()
file_to_step <- new.env(parent = emptyenv())
raw_rules <- list()

for (line in makefile_lines) {
  line <- trimws(line)
  if (line == "" || grepl("^#", line) || grepl("^\\.PHONY", line) || grepl("^all:", line)) next
  if (grepl("^\\s*@", line) || grepl("^Rscript", line)) next
  
  if (grepl(":", line)) {
    parts <- strsplit(line, ":")[[1]]
    targets <- gsub("&", "", trimws(parts[1]))
    deps <- if (length(parts) > 1) trimws(parts[2]) else ""
    
    split_targets <- strsplit(targets, "\\s+")[[1]]
    split_deps <- strsplit(deps, "\\s+")[[1]]
    
    if (length(split_targets) == 1 && !grepl("/", targets) && !grepl("\\.", targets)) {
      current_clean_target <- targets
      for (dep in split_deps) {
        if (grepl("/", dep) || grepl("\\.", dep)) {
          file_to_step[[dep]] <- current_clean_target
        }
      }
    } else {
      raw_rules[[length(raw_rules) + 1]] <- list(targets = split_targets, deps = split_deps)
    }
  }
}

for (rule in raw_rules) {
  associated_target_step <- NULL
  for (t in rule$targets) {
    if (exists(t, envir = file_to_step)) {
      associated_target_step <- file_to_step[[t]]
      break
    }
  }
  if (!is.null(associated_target_step)) {
    for (d in rule$deps) {
      if (exists(d, envir = file_to_step)) {
        source_step <- file_to_step[[d]]
        if (source_step != associated_target_step) {
          from_nodes <- c(from_nodes, source_step)
          to_nodes <- c(to_nodes, associated_target_step)
        }
      }
    }
  }
}

if (length(from_nodes) == 0) {
  stop("לא נמצאו קשרי תלויות.")
}

# 2. בניית הגרף
relations_table <- unique(data.frame(from = from_nodes, to = to_nodes, stringsAsFactors = FALSE))
pipeline_graph <- graph_from_data_frame(relations_table, directed = TRUE)

# 3. ציור מתקדם ומרווח בעזרת ggraph (פריסת עץ Sugiyama קלאסית)
# תיקון: הסרת ה-layers=max_edges הבעייתי
g <- ggraph(pipeline_graph, layout = 'sugiyama') + 
  # ציור החצים (עם מרווח ביטחון כדי שלא ייכנסו לתוך תיבות הטקסט)
  geom_edge_diagonal(
    aes(start_cap = label_rect(node1.name), end_cap = label_rect(node2.name)),
    arrow = arrow(length = unit(2.5, 'mm'), type = 'closed'),
    color = 'gray60', alpha = 0.8, width = 0.6
  ) +
  # ציור תיבות הטקסט של השלבים (מתאימות את עצמן אוטומטית לאורך המילה)
  geom_node_label(
    aes(label = name), 
    fill = "#F4F7FA", 
    color = "#1A365D",
    fontface = "bold", 
    size = 3.2, 
    label.padding = unit(0.3, "lines"),
    label.size = 0.4
  ) +
  # הגדרות עיצוב מסביב
  labs(title = "Clean Pipeline Architecture", subtitle = "Automated view from Makefile") +
  theme_void() + 
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5, color = "#1A365D"),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40", margin = margin(b = 20)),
    plot.margin = margin(20, 40, 20, 40)
  )

# 4. שמירה ישירה לקובץ PDF רחב כדי למנוע דחיסה של הטקסט
svglite::svglite("pipeline_graph.svg", width = 14, height = 10)
print(g)
dev.off()

#delete all grpah related objects to clean the environment
rm(list = c("from_nodes", "to_nodes", "file_to_step", "raw_rules", "relations_table", "pipeline_graph", "g", "makefile_lines", "makefile_path", "line", "parts", "targets", "deps", "split_targets", "split_deps", "current_clean_target", "associated_target_step", "source_step"))