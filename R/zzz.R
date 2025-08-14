options(repos = c(CRAN = "https://cloud.r-project.org"))

.onLoad <- function(libname, pkgname) {

  if (interactive()) {

    # Set a CRAN mirror for non-interactive installations just in case
    options(repos = c(CRAN = "https://cloud.r-project.org"))
    options(timeout = 600) # 10 minutes

  if (!requireNamespace("pacman", quietly = FALSE)) {
    utils::install.packages("pacman")
  }

  # List all required packages (CRAN or GitHub)
  required_cran <- c("leaflet", "cli", "shiny", "shinydashboardPlus",
                     "shinydashboard", "terra",
                     "sf", "lidR", "shinyjs", "cli",
                     "leaflet.extras", "h2o", "shinyWidgets")

  required_github <- c("fpirotti/CloudGeometry")

  # Load/install CRAN packages
  pacman::p_load(char = required_cran, install = TRUE)

  # Load/install GitHub packages if needed
  for (pkg in required_github) {
    pkg_name <- sub(".*/", "", pkg)
    if (!requireNamespace(pkg_name, quietly = TRUE)) {
      pacman::p_load_gh(pkg)
    }
  }
 }
}
