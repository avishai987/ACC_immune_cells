library(MakefileR)
write_makefile_with_pipeline <- function(pipeline, file_name = "Makefile") {
  mkfile = makefile() 
  all_rules = c()
  mkfile = mkfile + make_rule(".Phony", "all")
  for (i in 1:length(pipeline)) {
    all_rules = c(all_rules,  names(pipeline)[[i]])
  }
  mkfile = mkfile + make_rule("all", all_rules)

  for (i in 1:length(pipeline)) {

    if(!is.null(pipeline[[i]]$params)){
      params_str = paste("with params:", paste(names(pipeline[[i]]$params), pipeline[[i]]$params, sep = " = ", collapse = ", "))
    }else{
      params_str = ""
    }

    mkfile = mkfile +   make_comment(c("============", names(pipeline)[[i]], "============")) + # comment  
      make_rule(names(pipeline)[[i]], unlist(pipeline[[i]]$output), paste("@echo  $@ is up to date", params_str )) #define rule output
    if(is.null(pipeline[[i]]$shell)){
      mkfile = mkfile + make_rule(targets = c(unlist(pipeline[[i]]$output),"&"), deps = unlist(pipeline[[i]]$input), #run rscript, add & for grouped tagets
                                  script =paste("Rscript ./utils/render.R",
                                                names(pipeline)[[i]]
                                  ))
      }else{
        mkfile = mkfile + make_rule(targets = unlist(pipeline[[i]]$output), deps = unlist(pipeline[[i]]$input),
                                    script = eval(pipeline[[i]]$shell))
      }
    
    }
  
write_makefile(makefile = mkfile,file_name = "Makefile")
}