## this is global scope data - runs only once per session
## so it is useful for loading large datasets only once
if (!require("pacman")) {
  message(cli::col_green( " prima installazione della
 app MerMecDeepL4Veg per 'Mer Mec Engineering Srl' ...
 un po' di pazienza che vengono installate le
 dipendenze necessarie")  )
  install.packages("pacman")
}
options(timeout = 600) # 10 minutes
pacman::p_load( leaflet, shiny, shinydashboardPlus,
                shinydashboard, terra, cli,
                sf, lidR, shinyjs,
                leaflet.extras, h2o, shinyWidgets) #  tidyverse, bslib,
if(!require(CloudGeometry)){
  message(cli::col_green( "Non dovrebbe esserci qui")  )
  devtools::install_github("fpirotti/CloudGeometry")
  library(CloudGeometry)
}

## cartella con dentro modelli H2O
cartella.modelli <- "models"
## cartella dove verranno salvati i log
cartella.log.h2o <- "modelliH2O"
## cartella dove verranno salvati i progetti caricati
rootProjects <- "data"

## modelli disponibili
models <- c("", list.files(cartella.modelli, full.names = T))

names(models) <- basename(models)

if(!dir.exists(cartella.log.h2o)) { dir.create(cartella.log.h2o) }
is_h2o_alive <- function() {
  tryCatch({
    suppressMessages(h2o.clusterStatus())
    TRUE
  }, error = function(e) {
    FALSE
  })
}


# h2o.init( port = 54321, log_dir = cartella.log.h2o, log_level = "INFO")

isalive <- is_h2o_alive()[[1]] && !is.null(h2o.getConnection())
if(!isalive) {
  file.remove(list.files(cartella.log.h2o, full.names = TRUE))
  h2o.init(port = 54321, log_dir = cartella.log.h2o, log_level = "INFO")
} else {
  message(cli::col_green( "Spengo e riavvio l'engine di AI...")  )
  h2o.shutdown(prompt = F)

  file.remove(list.files(cartella.log.h2o, full.names = TRUE))
  Sys.sleep(3)
  message(cli::col_green( "Riavvio l'engine di AI...") )
  h2o.init(port = 54321, log_dir = cartella.log.h2o, log_level = "INFO")
  message(cli::col_green( "Engine di AI riavviata...") )
}
h2o.log.files <- list.files(cartella.log.h2o, full.names = TRUE)
options(shiny.maxRequestSize = 100*1024^2)

loglevels = c("Error" = "error",
              "Warning" = "warning",
              "Info" = "info")
loglevelsAI = c("Fatal" = "fatal",
                "Error" = "error",
              "Warning" = "warn",
              "Info" = "info",
              "Debug" = "debug")


## qui va sostituito con API mermec! -----
bing.apikey = 'AjvjPYuoA4IgNeooKvodDLcxbVL1F8RdIxXUeYsb6PgiVapURz_PbbWvOxVKmNps'

if(!dir.exists(rootProjects)) dir.create(rootProjects)

average.points.for.3dmetrics <- 20

AI.variables = list('Infrastruttura'= 'Shapefile o Geopackage con elementi vettoriali con infrastruttura',
  'LAS'='Nuvola di punti (lidar or fotogrammetria ecc...) in formato las o laz',
                  #   'DTM'='Modello digitale del terreno raster',
                  # 'DSM'='Modello digitale della superficie raster',
                  # 'nDSM'='Modello digitale della superficie normalizzata raster, carta delle altezze',
                  'Termico'='Mappa termica raster da volo drone',
                  'NDVI'='Indice normalizzato Rosso-IR vicino,  da volo drone'
                  )

logIt <- function(..., type="info", alert=F, session=NULL){

  msg = paste(..., collapse = " ")

    shinyjs::runjs( sprintf("$('#log').append('<p class=\"%s\" >%s&nbsp;-&nbsp;%s</p>');  ",
                            type, date(),  msg) )

  if(type!="info"){
    updateTabsetPanel(session, "tabs", selected = "Log Processi")
  }

  if(alert){
    shinyWidgets::show_alert(msg)
  }


}


window.size.function <- function(x) {
  y <- 2.6 * (-(exp(-0.08*(x-2)) - 1)) + 3
  y[x < 2] <- 3
  y[x > 20] <- 5
  return(y)
}


