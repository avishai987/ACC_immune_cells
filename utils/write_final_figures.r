source("utils/compare_svg.r")
#check compare function exists
if (is.null(compare_and_save_svg)) {
  stop("Failed to source compare_svg.r")
}
#define paths
all_files = c(
  umap_all_cells = "Reports/05_UMAP_clustering/umap_all_cell_types.svg",
  umap_t_cells_subtypes = "Reports/05_UMAP_clustering/umap_with_t_cell_subtypes.svg",
  violin_caf_scores = "Reports/05_UMAP_clustering/vlnplot_caf_subtypes_scores.svg",
  bulk_cor_brayer = "Reports/Bulk_deconv/brayer_CIBERSORT_analsyis/brayer_cibersort_heatmap.svg",
  bulk_cor_ferrarotto = "Reports/Bulk_deconv/ferrarotto_CIBERSORT_analysis/ferrarotto_cibersort_heatmap.svg",
  bulk_cor_dou = "Reports/Bulk_deconv/Dou_CIBERSORT_analsyis/dou_cibersort_heatmap.svg"
)

final_figures_dir = "final_figures"
if (!dir.exists(final_figures_dir)) {
  dir.create(final_figures_dir)
}

# check if files exist
for (file in all_files) {
  if (!file.exists(file)) {
    stop(sprintf("File does not exist: %s", file))
  }
}

#for each file, check if name exists, if not, copy it to final_figures_dir. if it exists, compare and overwrite if different
for (file in all_files) {
  filename = basename(file)
  new_svg_path = file.path(final_figures_dir, filename)
  if (!file.exists(new_svg_path)) {
    file.copy(file, new_svg_path)
    message(sprintf("SVG file copied! %s", new_svg_path))
  } else {
    compare_and_save_svg(filename, new_svg_dir = final_figures_dir, old_svg_dir = final_figures_dir, interactive_force = TRUE)
  }
}

#remove old files -
#loop over existing files in final_figures_dir and check if they are in all_files, if not, delete them
existing_files = list.files(final_figures_dir, full.names = TRUE)
for (existing_file in existing_files) {
  if (!existing_file %in% file.path(final_figures_dir, basename(all_files))) {
    file.remove(existing_file)
    message(sprintf("SVG file removed! %s", existing_file))
  }
}