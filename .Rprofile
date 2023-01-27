#source("renv/activate.R")
Sys.setenv(TERM_PROGRAM = "vscode")
source(file.path(
    Sys.getenv(
        if (.Platform$OS.type == "windows") "USERPROFILE" else "HOME"
    ),
    ".vscode-R", "init.R"
))
options(vsc.rstudioapi = TRUE)
options(fnmate_quote_jump_regex = TRUE)