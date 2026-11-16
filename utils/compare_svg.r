
library(svglite)
library(digest)

compare_and_save_svg <- function(filename, new_svg_dir = params$data_out_dir, old_svg_dir = "./Figures/", interactive_force = FALSE) {
  if (interactive() && !interactive_force) {
    message("Running in interactive mode. Skipping SVG comparison and saving.")
    return(FALSE)
  }

  old_svg_path = file.path(old_svg_dir, filename)
  new_svg_path = file.path(new_svg_dir, filename)
  # Helper function to sanitize dynamic attributes (IDs, clip-paths, URLs) and whitespace
  # This prevents false positives in hash comparison caused by svglite re-indexing
  get_clean_hash <- function(f) {
    txt <- readLines(f, warn = FALSE)
    
    # 1. Clean dynamic ID definitions: id="glyph-1-2" -> id=""
    txt <- gsub('id="[^"]+"', '', txt)
    
    # 2. Clean dynamic URL/clip-path references: url(#cp123) -> url()
    txt <- gsub('url\\(#?[^)]+\\)', '', txt)
    
    # 3. Strip all whitespace and empty lines
    txt <- gsub('\\s+', '', txt)
    
    return(digest(txt, algo = "md5"))
  }
  
  is_identical <- FALSE
  
  # Compare new SVG hash against the existing SVG file if present
  if (file.exists(old_svg_path)) {
    new_hash <- get_clean_hash(new_svg_path)
    old_hash <- get_clean_hash(old_svg_path)
    is_identical <- (new_hash == old_hash)
  }
  
  # Overwrite the old SVG only if changes are detected or if the file doesn't exist
  if (!is_identical) {
    # Ensure destination directory structure exists
    dir.create(dirname(old_svg_path), recursive = TRUE, showWarnings = FALSE)
    file.copy(new_svg_path, old_svg_path, overwrite = TRUE)
    message(sprintf("SVG file updated! %s", old_svg_path))
  }
  
}
