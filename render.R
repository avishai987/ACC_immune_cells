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