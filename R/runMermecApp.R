#' runMermecApp
#'
#' @param forceH2Oriavvio se valore è VERO (TRUE) allora all'avvio viene
#' forzato il riavvio dell'engine AI di H2O
#'
#' @description
#' Esegue il software, vedi esempio.
#'
#' @export
#' @examples
#' # runMermecApp()
#' # Scarica il file di esempio cliccando in alto a destra
runMermecApp <- function(forceH2Oriavvio=FALSE) {
  app_dir <- system.file("app", package = "MermecDeepL4Veg")
  options(forceH2Oriavvio = forceH2Oriavvio)

  # source("global.R", local = TRUE)
  shiny::runApp(app_dir)
}
