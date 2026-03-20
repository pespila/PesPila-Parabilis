require(shiny)
require(shinydashboard)
require(hash)
require(DT)
require(ggplot2)
require(RSQLite)
require(reshape2)

source("InitDB.R")
source("LoadPreferences.R")
source("GetCountry.R")
source("GetLeagues.R")
source("GetSeasons.R")
source("GetTeams.R")
source("GetLeagueTable.R")
source("GetHomeVsAway.R")
source("GetTableOfSeason.R")
source("Updateleague.R")
source("Updateseason.R")
source("Updateteam.R")
source("StatsTeamData.R")
source("Poisson.R")
source("ZeroInflatedPoisson.R")
source("Uniform.R")
source("Geometric.R")
source("NegativeBinomial.R")
source("WinDrawLost.R")

seasons <- rev(GetSeasons())
country <- GetCountry()
leagues <- GetLeagues()

header <- dashboardHeader(title = "PesPila")

sidebar <- dashboardSidebar(

  tags$link(rel = "stylesheet", type = "text/css", href = "/css/styles.css"),

  sidebarMenu(id = "tabs",
    menuItem("Home", tabName = "home", icon = icon("bank")),
    menuItem("Get Home vs. Away", tabName = "getCompare", icon = icon("binoculars"),
      menuSubItem(icon = NULL,
        fluidRow(
          selectInput(inputId = "home", label = "Choose a Home Team", choices = "", selected = ""),
          selectInput(inputId = "away", label = "Choose a Away Team", choices = "", selected = ""),
          p(class = "text-center",
            actionButton(inputId = "getVS", label = "Get Comparison")
          )
        )
      )
    ),
    menuItem("Get Distributions", tabName = "getDist", icon = icon("binoculars"),
      menuSubItem(icon = NULL,
        fluidRow(
          selectInput(inputId = "team", label = "Choose a Team", choices = ""),
          p(class = "text-center",
            actionButton(inputId = "getDistributions", label = "Get Distributions")
          )
        )
      )
    ),
    menuItem("Get Forecast", tabName = "getFore", icon = icon("binoculars"),
      menuSubItem(icon = NULL,
        fluidRow(
          selectInput(inputId = "fHome", label = "Choose a Home Team", choices = "", selected = ""),
          selectInput(inputId = "fAway", label = "Choose a Away Team", choices = "", selected = ""),
          p(class = "text-center",
            actionButton(inputId = "getForecast", label = "Get Forecast")
          )
        )
      )
    ),
    menuItem("Dashboard", tabName = "overview", icon = icon("dashboard")),
    menuItem("Tables", tabName = "tables", icon = icon("table")),
    menuItem("Distributions", tabName = "distributions", icon = icon("line-chart")),
    menuItem("Forecast", tabName = "forecast", icon = icon("money"))
  )

)

body <- dashboardBody(

  tabItems(

    tabItem(tabName = "home",

      fluidRow(class = "text-center",
        
        h1("Welcome to PesPila"),

        column(width = 6, offset = 3,

          box(width = 12, title = "Select Country, League and Season", background = "light-blue",
              solidHeader = TRUE,

            fluidRow(

              column(width = 6, offset = 3,

                selectInput(inputId = "country", label = "Choose a Country", choices = country, selected = country[1]),
                p(class = "text-center",
                  actionButton(inputId = "getLeagues", label = "Update Leagues")
                ),
                selectInput(inputId = "league", label = "Choose a League", choices = leagues, selected = leagues[1]),
                p(class = "text-center",
                  actionButton(inputId = "getSeasons", label = "Update Seasons")
                ),
                selectInput(inputId = "season", label = "Choose a Season", choices = seasons, selected = seasons[1]),
                p(class = "text-center",
                  actionButton(inputId = "getSetting", label = "Submit Setting")
                )

              )

            )

          )

        )
      )
    ),

    tabItem(tabName = "overview",

      fluidRow(

        box(width = 4,
            title = textOutput("allGamesOfHome"),
            background = "light-blue",
            solidHeader = TRUE,
            collapsible = TRUE,
            plotOutput("allGamesOfHomeStat", height = 300)

        ),

        box(width = 4,
            title = textOutput("homeGamesOfHome"),
            background = "light-blue",
            solidHeader = TRUE,
            collapsible = TRUE,
            plotOutput("homeGamesOfHomeStat", height = 300)

        ),

        box(width = 4,
            title = textOutput("awayGamesOfHome"),
            background = "light-blue",
            solidHeader = TRUE,
            collapsible = TRUE,
            plotOutput("awayGamesOfHomeStat", height = 300)

        )

      ),

      fluidRow(

        box(width = 4,
            title = textOutput("allGamesOfAway"),
            background = "navy",
            solidHeader = TRUE,
            collapsible = TRUE,
            plotOutput("allGamesOfAwayStat", height = 300)

        ),

        box(width = 4,
              title = textOutput("homeGamesOfAway"),
              background = "navy",
              solidHeader = TRUE,
              collapsible = TRUE,
              plotOutput("homeGamesOfAwayStat", height = 300)

        ),

        box(width = 4,
              title = textOutput("awayGamesOfAway"),
              background = "navy",
              solidHeader = TRUE,
              collapsible = TRUE,
              plotOutput("awayGamesOfAwayStat", height = 300)

        )

      )

    ),

    tabItem(tabName = "tables",

      fluidRow(

        column(10, offset = 1,

          tabsetPanel(

            tabPanel("Season Tables",

              h1(class = "text-center",

                textOutput(outputId = "seasonHeader")

              ),
              DT::dataTableOutput("Tables")

            ),

            tabPanel("Season Games",

              h1(class = "text-center",

                textOutput(outputId = "gamesHeader")

              ),
              DT::dataTableOutput("Games")

            ),

            tabPanel("Home vs. Away",

              h1(class = "text-center",

                textOutput(outputId = "vsHeader")

              ),
              DT::dataTableOutput("vs")

            )

          )

        )

      )

    ),

    tabItem(tabName = "distributions",

      fluidRow(

        column(12,

          tabsetPanel(

            tabPanel("Goals Scored",

              fluidRow(

                h1(class = "text-center",

                  "Distributions"

                ),

                column(9,

                  plotOutput("goalScored", height = 500,
                    dblclick = "Scored_dblclick",
                    brush = brushOpts(
                      id = "Scored_brush",
                      resetOnNew = TRUE
                    )
                  )

                ),

                column(3,

                  DT::dataTableOutput("gScored")

                )

              )

            ),

            tabPanel("Goals Conceded",

              fluidRow(

                h1(class = "text-center",

                  "Distributions"

                ),

                column(9,

                  plotOutput("goalConceded", height = 500,
                    dblclick = "Coneded_dblclick",
                    brush = brushOpts(
                      id = "Coneded_brush",
                      resetOnNew = TRUE
                    )
                  )

                ),

                column(3,

                  DT::dataTableOutput("gConceded")

                )

              )

              # tabsetPanel(

              #   tabPanel("Poisson",

              #     h1(class = "text-center",

              #       "Poisson Distribution"

              #     ),

              #     h3(class = "text-center",

              #       textOutput(outputId = "pvaluePoissonA")

              #     ),

              #     plotOutput(outputId = "pDistPoissonA"),
              #     DT::dataTableOutput("PoissonA")

              #   ),

              #   tabPanel("Zero-Inflated-Poisson",

              #     h1(class = "text-center",

              #       "Zero-Inflated-Poisson Distribution"

              #     ),

              #     h3(class = "text-center",

              #       textOutput(outputId = "pvalueZIPA")

              #     ),

              #     plotOutput(outputId = "pDistZIPA"),
              #     DT::dataTableOutput("ZIPA")

              #   ),

              #   tabPanel("Uniform",

              #     h1(class = "text-center",

              #       "Uniform Distribution"

              #     ),

              #     h3(class = "text-center",

              #       textOutput(outputId = "pvalueUniformA")

              #     ),

              #     plotOutput(outputId = "pDistUniformA"),
              #     DT::dataTableOutput("UniformA")

              #   ),

              #   tabPanel("Geometric",

              #     h1(class = "text-center",

              #       "Geometric Distribution"

              #     ),

              #     h3(class = "text-center",

              #       textOutput(outputId = "pvalueGeometricA")

              #     ),

              #     plotOutput(outputId = "pDistGeometricA"),
              #     DT::dataTableOutput("GeometricA")

              #   ),

              #   tabPanel("Negative Binomial",

              #     h1(class = "text-center",

              #       "Negative Binomial Distribution"

              #     ),

              #     h3(class = "text-center",

              #       textOutput(outputId = "pvalueNegBinomA")

              #     ),

              #     plotOutput(outputId = "pDistNegBinomA"),
              #     DT::dataTableOutput("NegBinomA")

              #   )

              # )

            )

            # tabPanel("P-Value Prediction",

            #   fluidRow(

            #     h1(class = "text-center",

            #       "Poisson P-Value"

            #     ),

            #     column(9,

            #       plotOutput("poissonPval", height = 500,
            #         dblclick = "plot_dblclick",
            #         brush = brushOpts(
            #           id = "plot_brush",
            #           resetOnNew = TRUE
            #         )
            #       )

            #     ),

            #     column(3,

            #       DT::dataTableOutput("pPval")

            #     )

            #   )

            # )

          )

        )

      )

    ),

    tabItem(tabName = "forecast",

      fluidRow(

        column(8, offset = 2, class = "text-center",

          h1("Forecast"),
          # dataTableOutput("SvS"),
          # dataTableOutput("CvC"),
          # dataTableOutput("SvC"),
          # dataTableOutput("CvS"),
          fluidRow(
            p(class = "text-center",
             uiOutput("prediction")
            )
          )
        )

      )

    )
  
  )

)

shinyUI(

  dashboardPage(header, sidebar, body, skin = "blue")

)
