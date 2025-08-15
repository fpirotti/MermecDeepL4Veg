#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#asyn


options(shiny.maxRequestSize = 200*1024^2)

header <- shinydashboardPlus::dashboardHeader(
    title =   shiny::fluidRow(shiny::column(width = 4,
                           tags$img(style="width:150px",
                                    src = "images/clipboard-34019662.png") ),
                    shiny::column(width = 8, p("MONDO ROTAIA ") ) ),
    tags$li(

        a(
            href = "example/esempio.zip",
            target = "_blank",
            style = "font-size: large;",
            title  ="relazione",
            "📝 "
        ),
        class = "dropdown"
    ),
    tags$li(
        a(
            href = "manuale/relazione.pdf",
            target = "_blank",
            style = "font-size: large;",
            title  ="relazione",
            "📖 "
        ),
        class = "dropdown"
    ),

    titleWidth = 400
)

siderbar <- dashboardSidebar(

    sidebarMenu(

        div(style="margin-bottom: -40px;", title="Carica un file ZIP con i dati per nuovo progetto", shiny::fileInput("newProjectFiles",
                                       "Carica  progetto:"  ) ),

        shiny::selectInput("dataFolder",
                           "Scegli progetto",
                           choices= basename(list.dirs(rootProjects, recursive = F ) ) ),

        shiny::actionButton("deleteProject",
                            "Elimina progetto",icon = icon("trash") ) ,

        shiny::actionButton("deleteProjectCache",
                            "Elimina CACHE del progetto",icon = icon("trash") ) ,
        hr(),
        shiny::actionButton("runProcess01",
                            "Step 1 indici dataset" ) ,
        shiny::actionButton("runProcess02",
                            "Step 2 estrazione descrittori", disabled = TRUE ) ,
        # shiny::actionButton("runProcess03",
        #                     "Step 3a addestra modello", disabled = F ) ,


        shinyWidgets::pickerInput("selectModel",
                            "Seleziona modello", choices = models
                              ) ,
        shiny::actionButton("runProcess04",
                            "Step 3 applica AI", disabled = TRUE ) ,
        shiny::downloadButton("runProcess05",  "Step 4 Scarica risultati", class = "disabled-btn"  )

    )

)

body <- dashboardBody(
    tags$head(
        tags$script(src="myjs.js"),
        tags$link(rel = "stylesheet", type = "text/css", href = "styles.css?v=3ddf")
    ),
    useShinyjs(),
    tabBox(id = 'tabs',   width = 12,
           tabPanel("Input",
                    div(
                        div(title="Questa soglia evita di utilizzare un dato lidar inutilmente distante dalla infrastruttura che si vuole analizzare",
                            shiny::numericInput('distanza.max.intorno.infrastruttura',
                                            HTML('Distanza max intorno alla infrastruttura (m)<sup> ? </sup>'),
                                            min = 1, step = 1,
                                            value = 200,
                                            max = 50000) ),

                        div(title="Forza il sistema di riferimento - inserisci un codice EPGS o lascia vuoto per identificarlo automaticamente",
                            shiny::numericInput('crs', HTML(sprintf('%s<sup>[i]<sup>', 'Sistema di riferimento' )),
                                            min = 1, step = 1,
                                            value = NA,
                                            max = 99999)
                             ),
                        shiny::numericInput('resolution', 'Risoluzione griglia output (m)',
                                            min = 0.1, step = 0.1,
                                            value = 1,
                                            max = 10),
                        shiny::uiOutput("files2process")
                        ),

                    ),
           tabPanel("Mappa", div(
               shiny::actionButton("refreshmap", "Aggiorna"),
               leafletOutput("mymap")
               )
             ),
           tabPanel("Log Processi", div(id="logPanelContent",

                   checkboxGroupInput("checkGroupLog", "Visualizza Log Processi",
                                      choices = loglevels,
                                      selected = c('error','info','warning'),
                                      inline = TRUE) ,
                   div(id="log")
               )
             ),
           tabPanel("Log AI/DL",
                    fluidRow( shiny::column(6, selectInput("LogLevelAI", "Livello ",
                                       choices = loglevelsAI,
                                       selected = c('info') ) ),
                              shiny::column(6, numericInput("LogLevelAInLines",label = "Righe Log", min=1, value=100, max=10000, step=10)
                                  )
                              ),
                    verbatimTextOutput("logAI")
           ),
           tabPanel("Risultati",
                    shinyWidgets::addSpinner(plotOutput("rasterPlot1") ),
                    uiOutput("linkUI01")
                    )

    )
)

ui <- dashboardPage(header, siderbar, body, skin = "black")


# Define UI for application that draws a histogram
# fluidPage(
#
#     # Application title
#     titlePanel( shiny::fluidRow(shiny::column(width = 6,
#                                        tags$img(style="width:200px",
#                                                 src = "images/clipboard-34019662.png") ),
#                     shiny::column(width = 6,h2("MONDO ROTAIA ") ) ),
#                 windowTitle="MyPage"
#     ),
#     # Sidebar with a slider input for number of bins
#     sidebarLayout(
#         sidebarPanel(
#             div(title="", shiny::fileInput("newProjectFiles",
#                                "Carica ZIP con dati per nuovo progetto:"  ) ),
#             shiny::selectInput("dataFolder",
#                         "Scegli progetto",
#                         choices=dir(rootProjects,include.dirs = FALSE) ),
#
#             shiny::fluidRow(shiny::actionButton("runProcess01",
#                                "Step 1 " ) ),
#             shiny::fluidRow(shiny::actionButton("runProcessAI",
#                 "Step 2 AI", disabled = T ) ),
#             shiny::fluidRow(shiny::actionButton("runProcessAI2",
#             "Step 3 Validazione", disabled = T ) ),
#             shiny::fluidRow( shiny::actionButton("runProcessAI3",
#             "Step 4 Esporta", disabled = T ) )
#         ),
#
#         mainPanel(
#             tabsetPanel(
#                 tabPanel("Files",  shiny::uiOutput("files2process") ),
#                 tabPanel("Mappa", leafletOutput("mymap")),
#                 tabPanel("Log Processi", div(id="log", "Log processi") ),
#                 tabPanel("Risultati",  shiny::uiOutput("res") )
#             )
#         )
#     )
# )
