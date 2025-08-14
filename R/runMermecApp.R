#' runMermecApp
#'
#' @param ... parametri di input, ma possono essere lasciati vuoti
#'
#' @description
#' Esegue il software, vedi esempio
#'
#' @export
#' @examples
#' # runMermecApp()
runMermecApp <- function(...) {
  app_dir <- system.file("app", package = "MermecDeepL4Veg")
  shiny::runApp(app_dir, ...)
}
