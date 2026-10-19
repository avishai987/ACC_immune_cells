args <- commandArgs(trailingOnly = TRUE)
source("./pipe.R")
library(devtools)
knitr::opts_knit$set(progress = TRUE, verbose = TRUE) #print commands when rendering


script = pipeline[[args[[1]]]]$input$script
report = pipeline[[args[[1]]]]$output$report
if (is.null(pipeline[[args[[1]]]]$params)) {
  set_params = list()
} else {
  set_params = pipeline[[args[[1]]]]$params
}

library(fs)
library(rmarkdown)

# Function to safely clean the output directory before rendering
safe_clean <- function(rmd_file, output_dir = "output") {
  sentinel_name <- ".safe_to_delete"
  sentinel_path <- path(output_dir, sentinel_name)

  # 1. Basic sanity checks on input path
  stopifnot(
    "output_dir is missing or empty" = !missing(output_dir) && nzchar(output_dir),
    "output_dir cannot be root (/)" = output_dir != "/",
    "output_dir cannot be current dir (.)" = output_dir != ".",
    "output_dir must be a relative path" = !is_absolute_path(output_dir)
  )

  # 2. Verify target directory and sentinel presence
  if (!dir_exists(output_dir)) {
    # Directory does not exist yet: safely create it and place the sentinel marker
    dir_create(output_dir)
    file_touch(sentinel_path)
  } else {
    # Directory exists: ensure sentinel file is present before touching anything
    if (!file_exists(sentinel_path)) {
      stop(
        sprintf(
          "Safety check failed: Sentinel '%s' missing in '%s'. Aborting cleanup to prevent accidental data loss!",
          sentinel_name, output_dir
        ),
        call. = FALSE
      )
    }

    # 3. Retrieve all items (including hidden files) and exclude the sentinel itself
    contents <- dir_ls(output_dir, all = TRUE)
    to_delete <- contents[path_file(contents) != sentinel_name]

    # Delete each item based on its type
    if (length(to_delete) > 0) {
      for (item in to_delete) {
        if (is_dir(item)) {
          dir_delete(item)
        } else {
          file_delete(item)
        }
      }
    }
  }


}

safe_clean(rmd_file = script, output_dir = dirname(report))

my_render <- function(script, report , set_params = list()){

  # if (dir.exists(dirname(report))) {
  #   unlink(dirname(report))
  # }
  set_params[["data_out_dir"]] = dirname(report) %s+% "/"
  message("Rendering to:")
  message(dirname(report))
  
  rmarkdown::render(
    input = script,
    output_format = "html_document",
    output_file = report,
    knit_root_dir = getwd(),
    output_dir = dirname(report),
    params = set_params
  )
  session_info_output <- capture.output(session_info())
  writeLines(session_info_output, dirname(report) %s+% "/session_info.txt")
}

my_render(script,report, set_params)