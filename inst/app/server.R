#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#


# Define server logic required to draw a histogram
function(input, output, session) {

    # currentProjectFiles <- reactiveVal(NULL)
    currentProjectRootDir <- NULL
    cache <- NULL
    cacheDir <- NULL
    risultatoDir <- NULL
    lidar <- NULL
    dat <- reactiveVal(NULL)
    myselectedModel <- NULL
    PRODOTTI <- reactiveVal(NULL)
    # Reactive value to hold the future object
    model_future <- reactiveVal(NULL)

    if(!sum(file.exists(h2o.log.files))>1){
        logIt(session=session, "Non trovato il file di log dell'infrastruttura AI utilizzata...", type="warning")
    }



    output$logAI <- renderText({
        req(input$LogLevelAI)
        req(input$LogLevelAInLines)

        ll <-system( sprintf("tail -n %d %s",input$LogLevelAInLines,  grep(sprintf("-%s.log$",input$LogLevelAI), h2o.log.files, value = T )), intern = TRUE)
        paste(ll, collapse = "\n")
      })
    ## RISULTATI TAB -----

    ## RESULTS LINK -----
    output$linkUI01 <- renderUI({
      req(input$dataFolder)
      req(dir.exists(risultatoDir) )
      tags$a(href=sprintf("https://www.cirgeo.unipd.it/archivio/R/shared/mermec/fase02/MermecDeepL4Veg/%s/", risultatoDir ),
               "Scarica dataset",
               target="_blank")
    })
    ## RESULTS PLOT -----
    output$rasterPlot1 <- shiny::renderPlot({

        req(input$dataFolder)
        fp <- file.path(risultatoDir, "stack.tif" )

        req(file.exists(fp) )
        dta <- terra::rast(fp)
        req(dta$hazard)

        req(dta$slope)
        req(dta$aspect)
        hillshade <- shade(dta$slope, dta$aspect, angle = 45, direction = 315)

        plot(hillshade, main="Mappa pericolo", col=gray.colors(100, start=0, end=1),   legend=F )

        if(file.exists(file.path(risultatoDir, "treeHazardDL.tif" ))){
          dd <- terra::rast(file.path(risultatoDir, "treeHazardDL.tif" ))
          terra::plot(dd ,  col= viridis::turbo(20), alpha=0.9, add=T)
        } else {
          terra::plot( dta$hazard ,  col= viridis::turbo(20), alpha=0.9, add=T)
        }
        # plot(dta$dtm, col=terrain.colors(100),  legend=F)

        # plot(dta$chm, col= viridis::turbo(20), alpha=0.25, add=TRUE, legend=F)
       # terra::plot( dta$hazard ,  col= viridis::turbo(20), alpha=0.55, legend=F, add=TRUE)

    })


    ### MODEL LOAD --------
    observeEvent(input$selectModel, {
      req(cache)
      req(input$selectModel)
      logIt( "Carico il modello... attendere", type = "warning", session=session)
      myselectedModel <- h2o.loadModel(input$selectModel)
      logIt( "Modello caricato.", session=session)

    })

    ## CACHE SAVE WHEN CHANGED -----
    observeEvent(dat(), {
        req(cache)
        dt.data<-dat()
        logIt("Salvo Cache...")
        save(dt.data, file=cache)
    })

    ## LOG TYPE CHANGE ----
    observeEvent(input$checkGroupLog, {
        for(lev in loglevels){
            if(is.element(lev, input$checkGroupLog)){
                shinyjs::runjs( sprintf("$('.%s').show()  ",
                                        lev  ) )
            } else {
                shinyjs::runjs( sprintf("$('.%s').hide()  ",
                                        lev  ) )
            }
        }
    })


    ## input descriptors --------
    output$files2process <- shiny::renderUI({

      lapply(names(AI.variables), function(name) {

        div(title=AI.variables[[name]], selectInput(inputId = paste0("select_", name),
                    label =   HTML(sprintf('%s<sup>[i]<sup>', name )),
                    choices = NULL,
                    selected = NULL)
        )

      })
    })
    ## files 2 process --------
    # output$files2process <- shiny::renderUI({
    observeEvent(input$dataFolder, {
      req(input$dataFolder)
      if(file.exists( file.path(rootProjects, input$dataFolder, "params.rda") )){
        load( file.path(rootProjects, input$dataFolder, "params.rda") )
      }
      ll <- list.files(file.path(rootProjects, input$dataFolder),
                       pattern = "las$|laz$|tif$|gpkg$|shp$",
                       recursive = F)

        ll2 <- file.path(rootProjects, input$dataFolder, ll)
        names(ll2) <- ll
        ll2 <- as.list(ll2)
        # currentProjectFiles(ll2)

        # logIt("Files trovati nella cartella con estensione LAS/LAZ/TIF: ", ll)

        currentProjectRootDir <<- file.path(rootProjects, input$dataFolder)

        cache <<- file.path(currentProjectRootDir, "cache", "cache.rda")
        cacheDir <<- file.path(currentProjectRootDir, "cache" )
        risultatoDir <<- file.path(currentProjectRootDir, "risultati" )

        if(!dir.exists(risultatoDir)){
            dir.create(risultatoDir)
        }
        if(!dir.exists(cacheDir)){
            dir.create(cacheDir)
        }

        if(length(ll)>0){
           if(file.exists(cache)){
               logIt("<b>cache   esiste  </b> ",   session=session)
               load(cache)
               dat(dt.data)
           }else {
               logIt("cache non esiste vai a STEP 1 ", type = 'warning', session=session)
           }
        } else {
            logIt("Nessun file TIF o LAS/Z trovato nella cartella!", type = 'error', session=session)
        }

        lapply(names(AI.variables), function(name) {
            logIt("Aggiungo elemento ", name)
            sel = grep(name,
                 names(ll2),
                 ignore.case = T,
                 value = T)

            if(length(sel)>0) {
                sel <- ll2[[ sel[[1]] ]]
                } else {
                    sel <- NULL
                }

            if(exists("filesAndAttributes")){
              sel <- filesAndAttributes[[paste0("select_", name)]]
            }
            updateSelectInput(inputId = paste0("select_", name),
                                                        choices = c(FALSE,ll2),
                                                        selected = sel)

        })


        if(exists("filesAndAttributes")){
          updateNumericInput(inputId = "distanza.max.intorno.infrastruttura",
                             value = filesAndAttributes[["distanza.max.intorno.infrastruttura"]])
          updateNumericInput(inputId = "resolution",
                             value = filesAndAttributes[["resolution"]])
          updateNumericInput(inputId = "crs",
                             value = filesAndAttributes[["crs"]])

        }

    })

    ## change file attribution ------
    observe({
      filesAndAttributes <- list()
      for(name in names(AI.variables)){
        listid <- paste0("select_", name)
        req(input[[listid]])
        filesAndAttributes[[listid]] <- input[[listid]]
      }
      filesAndAttributes[["distanza.max.intorno.infrastruttura"]] <- input[["distanza.max.intorno.infrastruttura"]]
      filesAndAttributes[["resolution"]] <- input[["resolution"]]
      filesAndAttributes[["crs"]] <- input[["crs"]]

      save(filesAndAttributes, file= file.path(rootProjects, input$dataFolder, "params.rda") )


    })
    ## step 1 --------
    observeEvent(input$runProcess01, {
        minx <- 99999999
        miny <- 99999999
        maxx <- -99999999
        maxy <- -99999999
        # leafletProxy("mymap" ) %>%
        #     clearShapes()
        # ff<-currentProjectFiles()
        dd<-(isolate(dat()))

        vars  <- names(AI.variables)
        vars.length <- length(vars)
        if(is.null(dd) || is.null(dd$lidar)){
            logIt(sprintf("STEP 1 - verifico %d file - ", vars.length)
            )
        } else {
            logIt(type = "warning", sprintf("STEP 1:  %d file presenti in cache, passa   allo step 2 oppure elimina la cache", vars.length
                                            ), session=session )
            # updateTabsetPanel(session, "tabs", selected = "Log Processi")
            return(NULL)
        }


        # progress <- AsyncProgress$new(session, min=1, max=vars.length,
        #                               message=sprintf("Inizio l'elaborazione di %d files",
        #                                               vars.length ))



        lidar <- NA
        hascrs <- NA
       # future({
       resProg <- withProgress(message = "Calcolo...", value = 0, {
            bboxes <- list()
            crs = list()
            vars  <- names(AI.variables)
            vars.length <- length(vars)
            for(i in 1:vars.length ){

                # progress$set(value = i,
                #              message=sprintf("%d/%d", i, vars.length ) )

                incProgress(i/vars.length,
                            detail=sprintf("%d/%d", i, vars.length ) )

                i2 <- i
                iname <- isolate({
                  input[[ paste0("select_", vars[[i]]) ]]
                })

                if(!isTruthy(iname)) {
                  logIt(session = session, type="warn", "Nessun file per " , vars[[i]], " trovato")
                  next
                }
                bi <- basename(iname)

                ext <- tools::file_ext(iname)
                rf <-  iname
                if(identical(iname, gsub(currentProjectRootDir,"", iname))){
                    rf <- file.path(currentProjectRootDir,iname)
                }

                # progress$set(  message=sprintf("elaboro file %s", bi ) )
                incProgress(((i-1)*vars.length)/(vars.length*3),
                            detail=sprintf("elaboro file %s", bi ) )

                if(tolower(ext)=="tif") {
                    r <- terra::rast(rf)
                    crs[[iname]] = st_crs(terra::crs(r), proj=T)$wkt
                    logIt(session = session, crs[[iname]])
                    b <- sf::st_bbox(r)
                }
                if(tolower(ext)=="gpkg" || tolower(ext)=="shp") {
                    infrastruttura = rf
                    r <- terra::vect(rf)
                    crs[['infrastruttura']] = st_crs(terra::crs(r, proj=T))$wkt
                    b <- sf::st_bbox(r)
                }

                if(tolower(ext)=="las" || tolower(ext)=="laz") {

                    lidar <- rf
                    ll <- lidR::readLASheader(rf)
                    crs[['LAS']] <- st_crs(lidR::crs(ll))$wkt

                    if(isTruthy(input$crs) ) {
                      logIt(
                        type="warning",
                        "Sto forzando il sistema di riferimento del dato lidar a EPGS=",
                        input$crs,
                        " - se non è una cosa voluta, togliere il valore dal campo in input -sistema di riferimento.",
                        session=session)

                      lidR::crs(ll) <- input$crs
                    }
                    crs[['LAS']] <- st_crs(lidR::crs(ll))$wkt
                    if(is.na(crs[['LAS']]) && !isTruthy(input$crs) ){
                      logIt(
                            type="warning",
paste0("Non è codificato un sistema di riferimento nel
 dato LAS/LAZ, il file è corrotto o non è stato esportato
 correttamente. Inseriscilo nel campo  -Sistema di riferimento-  manualmente.
<br>I dati del lasheader sono:<br>coordinate centrali:<br> - X=", ll$`X offset`,
"<br> - Y=", ll$`Y offset`),  session=session)

                      return(NULL)

                    }

                    b<-lidR::st_bbox(ll)
                }

                # progress$set(  message=sprintf("finito elaborazione file %s", bi ) )
                incProgress(((i-1)*vars.length+1)/(vars.length*3),
                            detail=sprintf("finito elaborazione file %s", bi ) )

                bb <- sf::st_as_sfc( b)
                bbc <- sf::st_centroid(bb)
                bbll <- sf::st_transform( bb, crs = 4326)
                bll <- sf::st_bbox(bbll)
                bbcll <- sf::st_coordinates(sf::st_transform(bbc, crs=4326))

                bboxes[[iname]]<-data.frame(
                    file = iname,
                    geom = bbll,
                    centerll = bbcll
                )

                if(bll[["xmin"]] < minx) minx <- bll[["xmin"]]
                if(bll[["ymin"]] < miny) miny <- bll[["ymin"]]
                if(bll[["xmax"]] > maxx) maxx <- bll[["xmax"]]
                if(bll[["ymax"]] > maxy) maxy <- bll[["ymax"]]

                incProgress(((i-1)*vars.length+2)/(vars.length*3),
                            detail=sprintf("finito elaborazione file %s", bi ) )


            }

        return(TRUE)

        }) #%...>% dat
       if(is.null(resProg)) {
         logIt(session = session, type="warning",  "Step 1 non completo")
         return(NULL)
       }
       if(!exists("infrastruttura") && exists("lidar") ) {
         logIt(session = session, type="warning", alert = T,
               "Nessun file vettoriale che rappresenta l'infrastruttura nel progetto,
                    non è possibile proseguire. Assicurati di aver caricato un progetto con
tutti i file, almeno lidar e infrastruttura (vedi manuale)")
         return(NULL)
       }

       if(!exists("infrastruttura") || !exists("lidar")) {
         logIt(session = session, type="warning", alert = T,
               "Nessun file per infrastruttura e lidar trovato nella selezione,
                    non è possibile proseguire. Assicurati di aver assegnato
                    correttamente gli input nella sezione corrispondente")
         return(NULL)

       }

         dat( list(bb=list(lng1 =minx,lat1 = miny,lng2 = maxx,lat2 = maxy),
                   lidar=lidar,
                   infrastruttura=infrastruttura,
                   data = bboxes,
                   crss=crs) )

     })

    # Handle submission of CRS feedback
    observeEvent(input$crs_submit_feedback, {
      removeModal()
      showNotification("Grazie - CRS registrato", type = "message")
      ff <- dat()

      browser()
    })


    ## step 2 --------
    observeEvent(input$runProcess02, {

        dd<-(isolate(dat()))

        if(is.null(dd) || is.null(dd$lidar)){
            logIt(sprintf("Cache non pronta, ri-esegui STEP 1!"  ),alert = T)
            return(NULL)
        }
        descrittori <- list()
        stackDescrittori <- list()
        if(!file.exists(dd$lidar)){
            logIt(
                sprintf("File LIDAR %s non trovato nel progetto!", dd$lidar ),alert = T)
            return(NULL)
        }


        chm.name <- file.path(currentProjectRootDir, "cache",
                              sprintf("%s.CHM_%dcm.tif", basename(dd$lidar),
                                      as.integer(input$resolution*100) ) )

        dtm.name <- file.path(currentProjectRootDir, "cache", sprintf("%s.DTM_%dcm.tif", basename(dd$lidar),
                                                                      as.integer(input$resolution*100) ) )

        ll.norm.name <- file.path(currentProjectRootDir, "cache", sprintf("%s.norm.laz", basename(dd$lidar) ) )

        crown.polygons.name <- file.path(risultatoDir,  sprintf("vegetazione.gpkg" ) )


        progress <- Progress$new(session, min=1, max=100)

        progress$set(value = 2, message = "Leggo il dato infrastruttura")
        infrastructure <- sf::read_sf(dd$infrastruttura)


        if(!file.exists(ll.norm.name)){
          ## se non c'è las normalizzato vuol dire che non c'è DTM e CHM
          progress$set(value = 5, message = "Leggo il dato lidar")
          ll <- lidR::readLAS(dd$lidar)

          infrastructure <- sf::st_transform(infrastructure, dd$crss$LAS )

          progress$set(value = 6, message = "Ritaglio il dato lidar START")
          infrastructure.harmonized.buf <- sf::st_buffer(infrastructure,
                                                         isolate(input$distanza.max.intorno.infrastruttura))
          if(is.na(lidR::crs(ll)) && isTruthy(input$crs) ){
            lidR::crs(ll) <- input$crs
          }
          las.clip <- lidR::clip_roi(ll, sf::st_union(infrastructure.harmonized.buf))
          ll <- las.clip
          rm(las.clip)

          progress$set(value = 8, message = "Ritaglio il dato lidar END")

          table.class <- table(ll$Classification)
          if (is.null(table.class[["2"]]) ||
              table.class[["2"]] == 0) {
            progress$set(value = 10, message = "Classifico dati lidar...START")
            ll <- lidR::classify_ground(ll, algorithm = csf())
            table.class2 <- table(ll$Classification)
            progress$set(value = 14, message = "Classifico dati lidar... END")
          }
          progress$set(value = 12, message = "Filtro ground e applico maschera...START")
          ll.g <- ll |> lidR::filter_ground()
          ll.conc <- lidR::st_concave_hull(ll.g)
          progress$set(value = 14, message = "Filtro ground e applico maschera... END")

          progress$set(value = 16, message = "Rasterizzo terreno DTM...START")
          dtm <-   rasterize_terrain(ll, res = isolate(input$resolution), algorithm = tin())
          dtm <- terra::mask(dtm, infrastructure.harmonized.buf)
          dtm <- terra::mask(dtm, vect(ll.conc) )

          progress$set(value = 16, message = "Rasterizzo terreno DTM.... END")

          progress$set(value = 18, message = "Normalizzo LiDAR...START")
          ll.norm <- lidR::normalize_height(ll, tin(), dtm = dtm)
          progress$set(value = 20, message = "Normalizzo LiDAR... END")

          progress$set(value = 26, message = "Rasterizzo elementi sopra il terreno...START")
          chm <-  rasterize_canopy(ll.norm, res = isolate(input$resolution),
                                   pitfree(max_edge = c(0, isolate(input$resolution) *  2.5)))

          chm <- mask(chm, dtm)

          progress$set(value = 27, message = "Rasterizzo elementi sopra il terreno... END")

          progress$set(value = 28, message = "Scrivo files in cache...")

          ccrrss <- st_crs(ll.norm)

          terra::crs(chm) <- ccrrss$wkt
          terra::crs(dtm) <- ccrrss$wkt


          progress$set(value = 35, message = "Identifico alberature sopra 1 m...")


          ttops <- locate_trees(ll.norm, lmf(window.size.function) )

          progress$set(value = 40, message = "Allineo i CRS...")
          ### CHIOME limiti  -----

          cc = st_crs(ttops)
          terra::crs(chm)<-  cc$wkt
          st_crs(ttops) <-    cc$wkt
          chms <- stars::st_as_stars(chm)
          st_crs(chms)<-  cc$wkt
          algo <- dalponte2016( chms, ttops)
          progress$set(value = 41, message = "Segmentazione alberi ...")
          las.trees <- segment_trees(ll.norm, algo)
          class(las.trees$treeID)<- "integer"

          progress$set(value = 41, message = "Calcolo metriche alberi...")

          crowns <- crown_metrics(las.trees, func = .stdtreemetrics,
                                  geom = "convex")


          progress$set(value = 42, message = "Salvo i dati su...")

          writeRaster(chm, chm.name, overwrite = T)
          writeRaster(dtm, dtm.name, overwrite = T)
          lidR::writeLAS(ll.norm, ll.norm.name, index = T)
          dd$nlidar  <- ll.norm.name
          file.remove(crown.polygons.name)
          sf::write_sf(crowns, crown.polygons.name)

        } else {

          ll.norm <- lidR::readLAS(ll.norm.name)
          dd$nlidar  <- ll.norm.name
          chm <- terra::rast(chm.name )
          dtm <- terra::rast(dtm.name )
          infrastructure <- sf::st_transform(infrastructure, st_crs(ll.norm) )
          crowns <- sf::read_sf(crown.polygons.name)

        }

############
        descrittori[["chm"]] <- chm
        descrittori[["dtm"]] <- dtm
        # descrittori[["ll.norm"]] <- ll.norm

        crowns <- crowns |> dplyr::filter(convhull_area > input$resolution*10)

        # descrittori[["crowns"]] <- crowns

        progress$set(value = 42, message = "Calcolo pendenze e esposizione terreno...")
        descrittori[["slope"]] <- terrain( dtm, "slope", unit="radians")
        descrittori[["aspect"]] <- terrain( dtm, "aspect", unit="radians")


        ####  distanze ----
        progress$set(value = 45, message = "Identifico distanze ...")
        pointsAlongLineAll <- st_line_sample(infrastructure,
                                          density = input$resolution/2)

        pointsAlongLine <- pointsAlongLineAll %>% st_coordinates()

        pointsAlongLine[,3] <- terra::extract(dtm, pointsAlongLine[,1:2] )[[1]]
        pointsAlongLine  <- na.omit(pointsAlongLine)
        chm[is.na(chm)] <- 0


        r_line <- rasterize(infrastructure, dtm, field=1)
        r_crowns <- rasterize(crowns, dtm, field=crowns$treeID)
        chmt <- chm
        chmt[is.na(r_crowns)] <- 0
        # plot(chmt)
        dsm <-  dtm+chmt
        # plot(dtm+chm)
        # plot(dsm)
        # plot(dtm)

        # plot(r_crowns)
        #
        # # Step 4: Compute the distance raster
        dist_raster2d <- distance(r_line)
        dist_raster2d <- mask(dist_raster2d, dtm)
        descrittori[["dist_raster2d"]] <- dist_raster2d

        dd$cells <- terra::cells(dtm)
        dd$matrix <- dist_raster2d[dd$cells]
        names(dd$matrix) <- "dist_raster2d"
        matrixXY <- as.data.frame(terra::xyFromCell(dist_raster2d, dd$cells ))
        matrixXY$z  <- dsm[dd$cells][[1]]

        matrixMatch <- nabor::knn( pointsAlongLine[,1:3], matrixXY,  k=1)
        dd$matrix$dist_raster3d  <- matrixMatch$nn.dists

        haz <- dtm
        haz[dd$cells] <- dd$matrix$dist_raster3d
        haz[haz[] < exp(1) ] <- exp(1)
        # plot(haz)
        descrittori[["dist_raster3d"]] <- haz
        # haz[dd$cells] <- dd$matrix$dist_raster3d - dd$matrix$dist_raster2d
        # haz[haz[]>5] <- NA
        # plot(log10(haz))
        haz[dd$cells] <-  dd$matrix$dist_raster2d / dd$matrix$dist_raster3d
        haz[haz[]>1] <- 1
        haz[ descrittori[["dist_raster2d"]]<1.5 ] <- 1

        haz[dd$cells] <-  cos(haz[dd$cells])
        # plot(haz)
        descrittori[["tree_slope"]] <- haz
        # ttops.coords <- as.data.frame(st_coordinates(ttops) )
        # dists3ddd <- terra::zonal(descrittori[["dist_raster3d"]], r_crowns)
        # crowns$hazard_dist <- 0
        # crowns$hazard_dist  <- 1/log(dists3ddd)
        descrittori[["hazard_dist"]]  <- 1/log(descrittori[["dist_raster3d"]])
        descrittori[["hazard_dist"]] <- mask(descrittori[["hazard_dist"]], r_crowns)
        descrittori[["hazard_slope"]] <- mask(descrittori[["tree_slope"]], r_crowns)

        progress$set(value = 50, message = "Leggo NDVI e Termico ...")
        if(!is.null(descrittori$crowns$NDVI)){
            logIt("NDVI medio per chioma già calcolato",
                  type = "info", session=session)
        } else {
            logIt("NDVI mediana per chioma ...calcolo...",
                  type = "info", session=session)

            if(!file.exists(input[["select_NDVI"]]) ) {
              logIt("NDVI non trovato, inserisco valori costanti",
                    type = "warning", session=session)
              r1 <- terra::rast(chmt)
              r1[] <- 0.05
              r1[chmt[]>0] <- 0.5
            } else {
              r1 <- terra::rast(input[["select_NDVI"]])
            }
            descrittori[["NDVI"]] <- resample(r1, dtm, method = "bilinear")

            descrittori[["NDVI"]]  <- mask(descrittori[["NDVI"]] , dtm)
            # crowns.sf.NDVIs  <- terra::extract( descrittori[["NDVI"]], descrittori$crowns, fun=median )
            # crowns$NDVI <-  crowns.sf.NDVIs[,2]
            # crowns$hazard_ndvi  <- 1 - (descrittori$crowns$NDVI / max(descrittori$crowns$NDVI, na.rm = T))
            values <- values(descrittori[["NDVI"]], na.rm = TRUE)
            q95 <- quantile(values, probs = 0.98, na.rm = TRUE)
            descrittori[["hazard_ndvi"]] <-  descrittori[["NDVI"]] / q95
            descrittori[["hazard_ndvi"]][ descrittori[["hazard_ndvi"]][]>q95  ] <- 1
            descrittori[["hazard_ndvi"]]  <- 1 - descrittori[["hazard_ndvi"]]
            descrittori[["hazard_ndvi"]] <- mask(descrittori[["hazard_ndvi"]], r_crowns)

        }


        progress$set(value = 60, message = "Metriche Termico  ...")

        if(!is.null(descrittori$crowns$Temperature)){
            logIt("Emissione termica medio per chioma già calcolato",
                  type = "info", session=session)
        } else {

          if(!file.exists(input[["select_Termico"]]) ) {
            logIt("NDVI non trovato, inserisco valori costanti",
                  type = "warning", session=session)
            r1 <- terra::rast(chmt)
            r1[] <- 15
          } else {
            r1 <- terra::rast(input[["select_Termico"]])
          }

            logIt("TERMICO mediana per chioma ...calcolo...",
                  type = "info", session=session)


            descrittori[["Termico"]] <- resample(r1, dtm, method = "bilinear")
            descrittori[["Termico"]]  <- mask(descrittori[["Termico"]] , dtm)

            values <- values(descrittori[["Termico"]], na.rm = TRUE)
            q95 <- quantile(values, probs = 0.98, na.rm = TRUE)
            q05 <- quantile(values, probs = 0.02, na.rm = TRUE)
            descrittori[["hazard_temperature"]] <-  (descrittori[["Termico"]] - q05) / (q95 - q05)
            gt <- descrittori[["hazard_temperature"]][] > 1
            lt <- descrittori[["hazard_temperature"]][] < 0
            descrittori[["hazard_temperature"]][gt] <- 1
            descrittori[["hazard_temperature"]][lt] <- 0
            descrittori[["hazard_temperature"]] <- mask(descrittori[["hazard_temperature"]], r_crowns)

          }

        descrittori[["crowns"]] <- r_crowns
        descrittori[["crowns"]][!is.na(r_crowns)] <- 1
        descrittori[["crowns"]][is.na(r_crowns)] <- 0
        descrittori[["crowns"]]  <- terra::mask(descrittori[["crowns"]], dtm)


        descrittori[["hazard"]] <- (descrittori$hazard_temperature^2 +
                                      descrittori$hazard_ndvi^2 +
                                      descrittori$hazard_dist^2) / 3

        descrittori[["hazard"]] <- mask(descrittori[["hazard"]], r_crowns)
        stack <- terra::rast(descrittori )
        writeRaster(stack,file.path(risultatoDir, "stack.tif" ), overwrite=T  )
        crowns.ext <- terra::zonal(stack, r_crowns)
        crownsb <- cbind(crowns, crowns.ext)

        file.remove(crown.polygons.name)
        sf::write_sf(crownsb, crown.polygons.name)

        progress$set(value = 65, message = "Metriche 3D nuvola punti  ...")

        ####  GEOMETRY  ----
        # descrittori[["ll.norm.metriche3d"]] <- CloudGeometry::calcGF(descrittori[["ll.norm"]]@data[,1:3],
        #                                                              rk = 1/(lidR::density(descrittori[["ll.norm"]])/average.points.for.3dmetrics) )



        PRODOTTI(descrittori)

        dd$crowns <- crownsb
        dat(dd)
        progress$close()


    })


    ## step 3 train --------
    observeEvent(input$runProcess03, {

      VALS <-isolate(dat())
      if(!isTruthy(VALS)){
        logIt(session=session, type="warning", alert=T, "Nessun dato caricato, hai scelto un progetto ed eseguito gli step precedenti?")
      }
      if(!isTruthy(VALS$crowns)){
        logIt(session=session, type="warning", alert=T, "Nessun elemento vegetazione caricato, hai scelto un progetto ed eseguito lo step precedenti?")
      }


      req(VALS$crowns)

      withProgress(message = "Addestro AI, aggiorna i log per i dettagli...", value = 0, {


      })

      # data <- as.h2o(iris)
      #
      #   # Launch future
      #   fut <- future({
      #       h2o.gbm(x = 1:4, y = 5, training_frame = data, ntrees = 10000)
      #   })
      #
      #   model_future(fut)  # Save the future object
      #   updateTabsetPanel(session, "tabs", selected = "Risultati")

    })
    ## step 4 --------
    observeEvent(input$confirm_step4, {

      removeModal()

      if(file.exists( file.path(risultatoDir, "AIout.laz" ) ) ){
        file.remove( file.path(risultatoDir, "AIout.laz" ) )
      }
      req(!file.exists( file.path(risultatoDir, "AIout.laz" ) ) )


      req(VALS)

      browser()
      progress <- Progress$new(session, min=1, max=100)

      progress$set(value = 2, message = "Carico il modello")



      if(!exists("myselectedModel")) {
        logIt(alert=T, "Modello addestrato non trovato.")
        return(NULL)
      }

      progress$set(value = 2, message = "Leggo il dato lidar")
      test2 <- readLAS(VALS$nlidar)
      progress$set(value = 6, message = "Estraggo i dati dal dato lidar")
      test <- test2@data[,1:7]
      names(test)<-c("x","y","z", "gpstime", "int","return","returns" )

      progress$set(value = 18, message = "calcolo descrittori geometrici distanza 1 dal  dato lidar")
      features.test2a <- CloudGeometry::calcGF(test[,1:3])
      progress$set(value = 22, message = "calcolo descrittori geometrici  distanza 2 dal  dato lidar")
      features.test2b <- CloudGeometry::calcGF(test[,1:3],2, verbose =T)

      progress$set(value = 16, message = "calcolo descrittori geometrici  distanza 3 dal  dato lidar")
      features.test2c <- CloudGeometry::calcGF(test[,1:3],4, verbose = T, threads = 14)
      progress$set(value = 41, message = "Unisco descrittori geometrici   dato lidar")
      features.test2 <- cbind(features.test2a, features.test2b, features.test2c)

      test.data<-cbind(test[,-c(1:3)], features.test2)
      progress$set(value = 58, message = "Creo dataset per modello AI da dare al cluster")
      df.test <- h2o::as.h2o(test.data)


      ### RANDOM FOREST AND DEEP LEARNING ----


      progress$set(value = 61, message = "Applico il modello ai dati")
      df.pred <- h2o.predict(myselectedModel, newdata = df.test)

      progress$set(value = 72, message = "Dataframe ...")
      df.pred.df<-as.data.frame(df.pred)

      progress$set(value = 82, message = "converto ...")

      test2$Classification <- as.integer(df.pred.df$predict)
      progress$set(value = 92, message = "Scrivo laz ...")
      lidR::writeLAS(test2, file.path(risultatoDir, "AIout.laz" ) )

      # test2 <- lidR::readLAS( file.path(risultatoDir, "AIout.laz" ) )
      test3 <- test2 |> lidR::filter_poi(Classification < 3L)

      dtm <- terra::rast(file.path(risultatoDir, "stack.tif" ) )
      tt <- lidR::rasterize_density(test3, dtm$dtm)
      dtm$hazard[tt[]>0] <- 0
      writeRaster(dtm$hazard,file.path(risultatoDir, "treeHazardDL.tif" ), overwrite=T )
      progress$close()


    })


    observeEvent(input$runProcess04, {

      if(file.exists( file.path(risultatoDir, "AIout.laz" ) ) ){

        showModal(modalDialog(
          title = "Conferma",
          HTML(sprintf("File elaborato <a href='%s' >AIout.laz</a> già esistente, vuoi sovrascriverlo?", file.path(risultatoDir, "AIout.laz" ) ) ),
          easyClose = FALSE,
          footer = tagList(
            modalButton("No"),
            actionButton("confirm_step4", "Si")
          )
        ))

      } else {
        VALS <-isolate(dat())
        if(!isTruthy(VALS)){
          logIt(session=session, type="warning", alert=T, "Nessun dato caricato, hai scelto un progetto ed eseguito gli step precedenti?")
          return(NULL)
        }
        if(!isTruthy(VALS$crowns)){
          logIt(session=session, type="warning", alert=T, "Nessun elemento vegetazione caricato, hai scelto un progetto ed eseguito lo step precedenti?")
          return(NULL)
        }
        showModal(modalDialog(
          title = "Conferma",
          "Confermi l'elaborazione? Ci potrebbe volere un po' di tempo, alla fine verifica i log della AI",
          easyClose = FALSE,
          footer = tagList(
            modalButton("No"),
            actionButton("confirm_step4", "Si")
          )
        ))
      }

    })
    ## step 5 zip e scarica --------
    output$runProcess05 <- downloadHandler(

      filename = function() {
        paste0("files_", Sys.Date(), ".zip")
      },
      content = function(file) {
        # Cartella da comprimere
        folder_path <- risultatoDir  # deve esistere ed essere accessibile

        # Ottieni tutti i file (escludi sottocartelle se necessario)
        files <- list.files(folder_path, full.names = TRUE)
        if(length(files)<2){
          logIt(session=session, type="warning", alert=T, "Nessun file di risultati presente, verifica di aver eseguito tutti gli step" )
          file.create(file)  # optional; creates an empty zip (which will be invalid)
          return(NULL)
        }
        # Comprimi i file nella cartella temporanea
        zip(zipfile = file, files = files, flags = "-j")  # -j per non includere sottodirectory
      },
      contentType = "application/zip"
    )

    ## render leafelet -----
    output$mymap <- renderLeaflet({


        ll <- leaflet( ) %>%
            addProviderTiles(providers$CartoDB.Positron,
                             options = providerTileOptions(noWrap = TRUE),
                             group = "CartoDB"
            ) %>%
        addBingTiles(apikey = bing.apikey, imagerySet = "Aerial", group = "Bing Aerial")%>%
            addBingTiles(apikey = bing.apikey, imagerySet = "Road", group = "Bing Road")%>%
            addBingTiles(apikey = bing.apikey, imagerySet = "CanvasDark", group = "Bing Canvas")


        req(input$refreshmap)

        for(i in names(AI.variables) ){
            ii <- input[[paste0("select_", i)]]
            ext <- tools::file_ext(ii)
            if(tolower(ext)=="las" || tolower(ext)=="laz") {
                lidar <- rf
                llidar <- lidR::readLASheader(ii)
                bbox<-lidR::st_bbox(llidar)  |>
                    sf::st_as_sfc()  |>
                    sf::st_transform(  crs=4326)
            } else if(tolower(ext)=="tif"  ) {
                r <- terra::rast(ii)
                bbox <- sf::st_bbox(r) |>
                    sf::st_as_sfc()  |>
                    sf::st_transform(  crs=4326)
            } else{

                ii <- sf::read_sf(ii)

                bbox <- sf::st_bbox(ii) |>
                    sf::st_as_sfc()  |>
                    sf::st_transform(  crs=4326)
            }


            bbcll <- bbox |>
                sf::st_centroid()

            ll <- ll %>% addMarkers(data=bbcll, group = i,
                                    popup = sprintf("Nome: %s;<br>Data caricamento: %s",
                                                    i, as.character(Sys.Date()) )   ) %>%
                 addPolygons(data=bbox, group = i  )


        }

        dta <- dat()

        if(!is.null(dta) && !is.null(dta[["crowns"]]) ) {

            dati <- dta[["crowns"]] |>
                sf::st_transform(4326)

            pal <- colorNumeric(palette = viridis::inferno(12), domain = dati$hazard)

            ll <- ll %>% addPolygons(data= dati,
                                     group = "HAZARD",

                                     fillColor = ~pal(hazard),  # Scala colori
                                     color = "black",  # Bordo dei poligoni
                                     weight = .1,
                                     fillOpacity = 0.7,
                                     popup  = ~sprintf("Livello di rischio: %.2f<br>Alt. Albero: %.1f m", hazard, Z )   )
        }

        bbox <- sf::st_bbox(bbox)
        ll <- ll %>%  addLayersControl(
            baseGroups = c("CartoDB", "Bing Aerial",  "Bing Road",  "Bing Canvas"),
            overlayGroups = c(names(AI.variables), "HAZARD") ,
                      options = layersControlOptions(collapsed = FALSE)) %>%
            fitBounds( bbox$xmin[[1]],  bbox$ymin[[1]],
                       bbox$xmax[[1]],  bbox$ymax[[1]])





        ll

    })

    # delete project CACHE  --------
    observeEvent(input$deleteProjectCache, {
      showModal(modalDialog(
        title = "Conferma",
        "Vuoi veramente eliminare la cache del progetto attuale? Dovrai rielaborare dallo step 1",
        easyClose = FALSE,
        footer = tagList(
          modalButton("No"),
          actionButton("confirm_delete_cache", "Si, elimina")
        )
      ))
    })
    observeEvent(input$confirm_delete_cache, {
      removeModal()
      # Your real action happens here
      file.remove(list.files(cacheDir, recursive = TRUE,full.names = TRUE))
      dat(NULL)
      PRODOTTI(NULL)
    })

    # delete project  --------
    observeEvent(input$deleteProject, {
        showModal(modalDialog(
            title = "Conferma",
            "Vuoi veramente eliminare il progetto attuale?",
            easyClose = FALSE,
            footer = tagList(
                modalButton("No!"),
                actionButton("confirm_delete", "Si, elimina")
            )
        ))
    })
    observeEvent(input$confirm_delete, {
        removeModal()
        # Your real action happens here
        unlink(currentProjectRootDir, recursive = TRUE)
        updateSelectInput(session = session, inputId = "dataFolder", choices= basename(list.dirs(rootProjects, recursive = F ) ))
    })
    # add project   --------
    observe({
        req(input$newProjectFiles)  # Wait until a file is uploaded

        # Path to the uploaded zip file
        zip_path <- input$newProjectFiles$datapath

        projPath <- file.path(rootProjects,
                              tools::file_path_sans_ext(basename(input$newProjectFiles$name)))
        # Create (or clean) a folder for extraction
        unzip_dir <- projPath
        if (dir.exists(unzip_dir)) unlink(unzip_dir, recursive = TRUE)
        dir.create(unzip_dir)

        # Unzip immediately
        unzip(zipfile = zip_path, exdir = unzip_dir)
        updateSelectInput(session = session, , inputId = "dataFolder", choices= basename(list.dirs(rootProjects, recursive = F ) ))


    })

}
