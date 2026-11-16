save_pipeline_graph <-function(makefile = "Makefile", output_file = "pipeline_interactive.html") {
  suppressPackageStartupMessages(library(igraph))
  library(visNetwork)

  # 1. קריאת קובץ ה-Makefile וה-Parser (הקוד המקורי שלך ללא שינוי)
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
    stop("No dependencies found.")
  }

  # 2. הכנת הנתונים עבור visNetwork
  relations_table <- unique(data.frame(from = from_nodes, to = to_nodes, stringsAsFactors = FALSE))
  all_unique_nodes <- unique(c(relations_table$from, relations_table$to))

  nodes <- data.frame(
    id = all_unique_nodes,
    label = all_unique_nodes,
    shape = "box",
    color = list(
      background = "#F4F7FA",
      border = "#1A365D",
      highlight = list(background = "#FFEAA7", border = "#D63031"),
      hover = list(background = "#E8EEF5", border = "#0984E3")
    ),
    font = list(face = "Helvetica", size = 16, color = "#1A365D"),
    margin = 10,
    shadow = TRUE
  )

  edges <- data.frame(
    from = relations_table$from,
    to = relations_table$to,
    arrows = "to",
    color = list(color = "#B2BEC3", highlight = "#0984E3", hover = "#0984E3"),
    smooth = list(enabled = TRUE, type = "cubicBezier", roundness = 0.5)
  )

  # 3. בניית הגרף האינטראקטיבי
  network <- visNetwork(nodes, edges, main = "Clean Pipeline Architecture", submain = "Hover/Click to highlight dependencies") %>%
    # היררכיה מסודרת מלמעלה למטה (או משמאל לימין) בדומה ל-Sugiyama
    visHierarchicalLayout(
      direction = "LR", # שנה ל-"UD" אם אתה מעדיף זרימה מלמעלה למטה
      levelSeparation = 180,
      nodeSpacing = 120
    ) %>%
    # הדגשת תלויות בלחיצה או מעבר עכבר
    visOptions(
      highlightNearest = list(
        enabled = TRUE,
        degree = 2,            # עומק השרשרת (כמה רמות קדימה/אחורה להאיר)
        hover = TRUE,           # מפעיל את ההארה גם במעבר עכבר (Hover)
        algorithm = "hierarchical" # מבדיל בין כיווני הזרימה
      ),
      nodesIdSelection = TRUE # מאפשר גם תיבת חיפוש/בחירה בחלק העליון
    ) %>%
    visInteraction(
      hover = TRUE,
      navigationButtons = TRUE, # כפתורי זום וניווט
      zoomView = TRUE
    )

  # 4. שמירה לקובץ HTML עצמאי
  htmlwidgets::saveWidget(network, file = "pipeline_interactive.html", selfcontained = TRUE)
  message("קובץ pipeline_interactive.html נוצר בהצלחה!")

}