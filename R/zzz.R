options(repos = c(CRAN = "https://cloud.r-project.org"))

.onLoad <- function(libname, pkgname) {

  if (interactive()) {
    packageStartupMessage(
      "\u2705 Verifico installazione dipendenze..."
    )
    if (!requireNamespace("cli", quietly = FALSE)) {

      packageStartupMessage(
        "\u2705  Installo funzionalit\u00E0 cli"
      )
      utils::install.packages("cli")
    }
    if (!requireNamespace("utils", quietly = FALSE)) {

      packageStartupMessage(
        "\u2705  Installo funzionalit\u00E0 utils"
      )
      utils::install.packages("utils")
    }

    if (!requireNamespace("h2o", quietly = FALSE)) {
      packageStartupMessage(
        "\u2705  Installo funzionalit\u00E0 H2O"
      )
      utils::install.packages("h2o", type = "source", repos = "http://h2o-release.s3.amazonaws.com/h2o/rel-3.44.0/3/R")
    }

    packageStartupMessage(
      "\u2705 Verifico opzioni..."
    )

    # Set a CRAN mirror for non-interactive installations just in case
    options(repos = c(CRAN = "https://cloud.r-project.org"))
    options(timeout = 600) # 10 minutes

    if (!requireNamespace("pacman", quietly = FALSE)) {
      packageStartupMessage(  "\u2705  Installo funzionalit\u00E0 pacman..." )
      utils::install.packages("pacman")
    }

    packageStartupMessage(
    "\u2705 Verifico ulteriori dipendenze..."
    )

  # List all required packages (CRAN or GitHub)
  required_cran <- c("leaflet", "cli", "shiny", "shinydashboardPlus",
                     "shinydashboard", "terra", "dplyr",
                     "sf", "lidR", "shinyjs", "cli",
                     "leaflet.extras",  "shinyWidgets")

  required_github <- c("fpirotti/CloudGeometry")
  availabl<- vapply(required_cran, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
  required_cran2 <-  ifelse(availabl, "\n\u2705", "\n\u274C")

  packageStartupMessage(cli::col_green("Verifico elementi mancanti...."),
    sprintf("%s %s ",
            required_cran2, required_cran)
  )

  if(any(!availabl)){
    packageStartupMessage(
      cli::col_red("Installo i seguenti elementi mancanti, potrebbe richiedere qualche minuto...."),
                          sprintf("%s %s ",
                                  required_cran2[!availabl],
                                  required_cran[!availabl])
                          )

  }
  pacman::p_load(char = required_cran, install = TRUE)

  # Load/install GitHub packages if needed
  for (pkg in required_github) {
    pkg_name <- sub(".*/", "", pkg)
    if (!requireNamespace(pkg_name, quietly = TRUE)) {
      pacman::p_load_gh(pkg)
    }
  }
  packageStartupMessage(cli::col_green(
    cli::style_bold("\n===> Esegui la app con il comando seguente: ")) ,
    cli::code_highlight("runMermecApp()") )
 }
}
