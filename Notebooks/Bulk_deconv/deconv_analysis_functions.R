default_deconv_cell_sets <- function() {
  list(
    immune_cell_names = c(
      "Naive B", "CD8_Naive", "CD4_Naive", "CD8_CM", "CD4_CM", "CD4_EM",
      "CD8_EM", "Plasmacytoid Dendritic", "gdT", "Treg", "CD8_TEMRA",
      "Macrophages", "Basophils", "Neutrophils", "MAIT", "Plasma B",
      "Myeloid Dendritic"
    ),
    t_cell_names = c(
      "CD8_Naive", "CD4_Naive", "CD8_CM", "CD4_CM", "CD4_EM", "CD8_EM",
      "gdT", "Treg", "CD8_TEMRA", "MAIT"
    ),
    t_cell_subtypes = list(
      naive_t_cells = c("CD8_Naive", "CD4_Naive"),
      CD8_memory = c("CD8_CM", "CD8_EM", "CD8_TEMRA"),
      CD4_helper = c("CD4_CM", "CD4_EM"),
      T_Innate_like = c("gdT", "MAIT")
    )
  )
}

calculate_deconv_fractions <- function(
  deconv_matrix,
  immune_cell_names = NULL,
  t_cell_names = NULL,
  t_cell_subtypes = NULL,
  luminal_columns = c("Luminal", "Myo"),
  include_original_columns = TRUE
) {
  if (!is.data.frame(deconv_matrix)) {
    stop("deconv_matrix must be a data.frame or data.table.")
  }

  cell_sets <- default_deconv_cell_sets()
  if (is.null(immune_cell_names)) {
    immune_cell_names <- cell_sets$immune_cell_names
  }
  if (is.null(t_cell_names)) {
    t_cell_names <- cell_sets$t_cell_names
  }
  if (is.null(t_cell_subtypes)) {
    t_cell_subtypes <- cell_sets$t_cell_subtypes
  }

  missing_immune_cells <- setdiff(immune_cell_names, names(deconv_matrix))
  immune_cell_names <- intersect(immune_cell_names, names(deconv_matrix))
  if (length(immune_cell_names) == 0) {
    stop("None of the requested immune-cell columns are present.")
  }

  result_columns <- unique(c(immune_cell_names, luminal_columns))
  result <- if (include_original_columns) {
    deconv_matrix
  } else {
    deconv_matrix[, intersect(result_columns, names(deconv_matrix)), drop = FALSE]
  }

  result$immune_cell_score <- rowSums(
    result[, immune_cell_names, drop = FALSE],
    na.rm = FALSE
  )

  available_t_cells <- intersect(t_cell_names, names(result))
  if (length(available_t_cells) == 0) {
    stop("None of the requested T-cell columns are present.")
  }
  result$t_cell_score <- rowSums(
    result[, available_t_cells, drop = FALSE],
    na.rm = FALSE
  )

  fraction_denominator <- result$immune_cell_score
  for (subtype_name in names(t_cell_subtypes)) {
    subtype_columns <- intersect(t_cell_subtypes[[subtype_name]], names(result))
    if (length(subtype_columns) == 0) {
      warning(sprintf("Skipping '%s': no matching columns are present.", subtype_name))
      next
    }
    result[[paste0(subtype_name, "_fraction")]] <-
      rowSums(result[, subtype_columns, drop = FALSE], na.rm = FALSE) /
      fraction_denominator
  }

  if ("Treg" %in% names(result)) {
    result$treg_fraction <- result$Treg / fraction_denominator
  }

  if (length(luminal_columns) != 2 ||
      !all(luminal_columns %in% names(result))) {
    warning("Luminal fraction was not calculated because the Luminal/Myo columns are unavailable.")
  } else {
    result$luminal_fraction <-
      result[[luminal_columns[[1]]]] /
      (result[[luminal_columns[[1]]]] + result[[luminal_columns[[2]]]])
  }

  attr(result, "missing_immune_cells") <- missing_immune_cells
  result
}

calculate_correlation_matrix <- function(
  deconv_matrix,
  columns = NULL,
  method = "pearson",
  use = "pairwise.complete.obs"
) {
  if (!is.data.frame(deconv_matrix)) {
    stop("deconv_matrix must be a data.frame or data.table.")
  }

  if (is.null(columns)) {
    columns <- names(deconv_matrix)[
      vapply(deconv_matrix, is.numeric, logical(1))
    ]
  }
  missing_columns <- setdiff(columns, names(deconv_matrix))
  if (length(missing_columns) > 0) {
    stop("Missing correlation columns: ", paste(missing_columns, collapse = ", "))
  }
  if (length(columns) < 2) {
    stop("At least two numeric columns are required for correlation.")
  }

  non_numeric_columns <- columns[
    !vapply(deconv_matrix[, columns, drop = FALSE], is.numeric, logical(1))
  ]
  if (length(non_numeric_columns) > 0) {
    stop("Correlation columns must be numeric: ",
         paste(non_numeric_columns, collapse = ", "))
  }

  cor(deconv_matrix[, columns, drop = FALSE], method = method, use = use)
}

calculate_correlation_pvalues <- function(
  deconv_matrix,
  columns = NULL,
  method = "pearson",
  adjust_method = "fdr"
) {
  if (is.null(columns)) {
    columns <- names(deconv_matrix)[
      vapply(deconv_matrix, is.numeric, logical(1))
    ]
  }
  if (length(columns) < 2) {
    stop("At least two numeric columns are required for correlation.")
  }
  missing_columns <- setdiff(columns, names(deconv_matrix))
  if (length(missing_columns) > 0) {
    stop("Missing correlation columns: ", paste(missing_columns, collapse = ", "))
  }

  p_values <- matrix(
    NA_real_, nrow = length(columns), ncol = length(columns),
    dimnames = list(columns, columns)
  )
  for (i in seq_along(columns)) {
    for (j in seq_along(columns)) {
      complete_rows <- complete.cases(
        deconv_matrix[, c(columns[[i]], columns[[j]]), drop = FALSE]
      )
      values_i <- deconv_matrix[[columns[[i]]]][complete_rows]
      values_j <- deconv_matrix[[columns[[j]]]][complete_rows]
      if (sum(complete_rows) >= 3 &&
          length(unique(values_i)) > 1 && length(unique(values_j)) > 1) {
        p_values[i, j] <- cor.test(
          values_i,
          values_j,
          method = method
        )$p.value
      }
    }
  }

  p.adjust(as.vector(p_values), method = adjust_method) |>
    matrix(nrow = nrow(p_values), ncol = ncol(p_values), dimnames = dimnames(p_values))
}

plot_deconv_correlations <- function(
  correlation_data,
  columns = NULL,
  method = "pearson",
  adjust_method = "fdr",
  title = "Correlation",
  transpose = TRUE,
  colors = c("royalblue4", "white", "red"),
  show_legend = FALSE,
  text_size = 14
) {
  # Calculate the correlation matrix from the selected data columns.
  correlation_matrix <- calculate_correlation_matrix(
    deconv_matrix = correlation_data,
    columns = columns,
    method = method
  )

  # Calculate adjusted p-values for the same correlations.
  p_values <- calculate_correlation_pvalues(
    deconv_matrix = correlation_data,
    columns = colnames(correlation_matrix),
    method = method,
    adjust_method = adjust_method
  )

  # Build and return the heatmap, including significance labels.
  plot <- plot_deconv_correlation(
    correlation_matrix = correlation_matrix,
    p_values = p_values,
    title = title,
    transpose = transpose,
    colors = colors,
    show_legend = show_legend,
    text_size = text_size
  )

  plot
}

plot_deconv_correlation <- function(
  correlation_matrix,
  p_values = NULL,
  title = "Correlation",
  transpose = TRUE,
  colors = c("royalblue4", "white", "red"),
  show_legend = FALSE,
  text_size = 14
) {
  if (!is.matrix(correlation_matrix)) {
    correlation_matrix <- as.matrix(correlation_matrix)
  }
  if (!is.numeric(correlation_matrix)) {
    stop("correlation_matrix must contain numeric values.")
  }
  if (is.null(rownames(correlation_matrix)) ||
      is.null(colnames(correlation_matrix))) {
    stop("correlation_matrix must have row and column names.")
  }
  if (length(colors) != 3) {
    stop("colors must contain exactly three colors: low, middle, and high.")
  }

  significance_labels <- NULL
  if (!is.null(p_values)) {
    p_values <- as.matrix(p_values)
    if (!all(dim(p_values) == dim(correlation_matrix)) ||
        !identical(rownames(p_values), rownames(correlation_matrix)) ||
        !identical(colnames(p_values), colnames(correlation_matrix))) {
      stop("p_values must have the same dimensions and names as correlation_matrix.")
    }
    significance_labels <- matrix(
      symnum(
        p_values,
        corr = FALSE,
        na = FALSE,
        cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
        symbols = c("***", "**", "*", ".", " ")
      ),
      nrow = nrow(p_values),
      ncol = ncol(p_values),
      dimnames = dimnames(p_values)
    )
  }

  color_function <- circlize::colorRamp2(c(-1, 0, 1), colors)
  matrix_to_plot <- if (transpose) t(correlation_matrix) else correlation_matrix

  ComplexHeatmap::Heatmap(
    matrix_to_plot,
    name = title,
    col = color_function,
    show_heatmap_legend = show_legend,
    row_names_gp = grid::gpar(fontsize = text_size),
    column_names_gp = grid::gpar(fontsize = text_size),
    clustering_method_rows = "average",
    clustering_method_columns = "average",
    clustering_distance_rows = "euclidean",
    cell_fun = if (is.null(significance_labels)) {
      NULL
    } else {
      function(j, i, x, y, width, height, fill) {
        grid::grid.text(
          if (transpose) significance_labels[i, j] else significance_labels[j, i],
          x, y, gp = grid::gpar(fontsize = text_size)
        )
      }
    }
  )
}

print_deconv_correlation <- function(
  deconv_matrix,
  columns = NULL,
  digits = 3,
  method = "pearson"
) {
  correlation_matrix <- calculate_correlation_matrix(
    deconv_matrix = deconv_matrix, columns = columns, method = method
  )
  print(round(correlation_matrix, digits = digits))
  invisible(correlation_matrix)
}

