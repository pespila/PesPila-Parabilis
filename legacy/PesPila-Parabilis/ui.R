library(shiny)
library(hash)
# library(ggplot2)
library(DT)

# options(warn=-1)

# source("global.R")

shinyUI(

    navbarPage("PesPila-Parabilis",

        tabPanel("home",

          div(class = "col-sm-10 col-sm-offset-1 jumbotron text-center",
            tabsetPanel(
              tabPanel("Home", 
                  tags$h1("PesPila-Parabilis"),
                  tags$h3("A tool to predict the outcome of football matches.")
              ),
              tabPanel("Preferences",
                tags$h2("Your preferences are"),
                fluidRow(
                  column(2, offset = 3,
                    helpText("Country:"),
                    textOutput("myCountry")
                  ),
                  column(2,
                    helpText("Division:"),
                    textOutput("myDivision")
                  ),
                  column(2,
                    helpText("Team:"),
                    textOutput("myTeam")
                  )
                ),
                tags$br(),
                tags$h2("Set new preferences"),
                fluidRow(
                  column(4,
                    selectInput("country", label = "Choose country", choices = "", selected = "")
                  ),
                  column(4,
                    selectInput("division", label = "Choose division", choices = "", selected = "")
                  ),
                  column(4,
                    selectInput("theTeam", label = "Choose favorite team", choices = "", selected = "")
                  )
                ),
                div(class = "text-center",
                  actionButton("setPreferences", "Set new Preferences")
                )
              ),
              # tabPanel("Update data sources", actionButton("reload", "Update the data sets.")),
              tabPanel("Data sources and literature",

                tags$h2("Source of the datasets"),
                div(class = "text-center", 

                  "Please visit: ", tags$a(href = "http://www.football-data.co.uk", "Football-Data.co.uk", target = "blank")

                )

              )
            )
          )
        ),
        tabPanel("league data",

          fluidRow(
              column(3, offset = 1,
                  sidebarPanel(width = 12,
                          
                          selectInput("countryOverview", 
                                      label = "Choose a country",
                                      choices = GetCountries(),
                                      selected = ReadPreferences()[1]),
                          selectInput("leagueOverview", 
                                      label = "Choose a league (for Results table)",
                                      choices = strsplit(x = list.files(path = paste("Data", "Germany", sep = "/"), pattern = ".csv"), split = ".csv"),
                                      selected = ReadPreferences()[2])
                  ),
                  sidebarPanel(width = 12, id = "legend",
                      div("Description of the shortcuts:", id = "header"),
                      br(),
                      div("FTHG = Full Time Home Goals"),
                      div("FTAG = Full Time Away Goals"),
                      div("FTR = Full Time Result"),
                      div("HTHG = Half Time Home Goals"),
                      div("HTAG = Half Time Away Goals"),
                      div("HTR = Half Time Result")
                  )
              ),
              column(7,
                  tabsetPanel(
                      tabPanel("Match results", {

                        tabsetPanel(

                          tabPanel("Absolute", DT::dataTableOutput("results")),
                          tabPanel("in %", DT::dataTableOutput("resultsPercent"))

                        )

                      }),
                      tabPanel("Wins", {

                        tabsetPanel(

                          tabPanel("Absolute", DT::dataTableOutput("wins")),
                          tabPanel("in %", DT::dataTableOutput("winsPercent"))

                        )

                      }),
                      # tabPanel("Wins", DT::dataTableOutput("wins")),
                      # tabPanel("GPPM", plotOutput("gpPerMatch")),
                      # tabPanel("Goal Differences", DT::dataTableOutput("goalDifferences")),
                      tabPanel("Goal Differences", {

                        tabsetPanel(

                          tabPanel("Absolute", DT::dataTableOutput("goalDifferences")),
                          tabPanel("in %", DT::dataTableOutput("goalDifferencesPercent"))

                        )

                      }),
                      tabPanel("Goal Sums", {

                        tabsetPanel(

                          tabPanel("Per Match (GSPM)", DT::dataTableOutput("gspm")),
                          tabPanel("Per Season (GSPS)", DT::dataTableOutput("gsps")),
                          tabPanel("Plot GSPM", plotOutput("gspmPlot")),
                          tabPanel("Plot GSPS", plotOutput("gspsPlot"))

                        )

                      }),
                      tabPanel("All Matches", DT::dataTableOutput("all"))
                        # tabsetPanel(
                        #   tabPanel("Specific Division", DT::dataTableOutput("specAll"))
                        # )

                      # })
                  )
              )
          )
        ),
        tabPanel("team data",

          fluidRow(
              column(3,
                  sidebarPanel(width = 12,

                          selectInput("teamCountry",
                                      label = "Select country",
                                      choices = GetCountries(),
                                      selected = ReadPreferences()[1]),
                          selectInput("teamDivision",
                                      label = "Select league",
                                      choices = strsplit(x = list.files(path = paste("Data", ReadPreferences()[1], sep = "/"), pattern = ".csv"), split = ".csv"),
                                      selected = ReadPreferences()[2]),
                          selectInput("teamChoice",
                                      label = "Select team",
                                      choices = team <- FolderStructure(path = paste("Data", ReadPreferences()[1], sep = "/")),
                                      selected = ReadPreferences()[3])
                  ),

                  sidebarPanel(width = 12, id = "legend",
                      div("Description of the shortcuts:", id = "header"),
                      br(),
                      div("FTHG = Full Time Home Goals"),
                      div("FTAG = Full Time Away Goals"),
                      div("FTR = Full Time Result"),
                      div("HTHG = Half Time Home Goals"),
                      div("HTAG = Half Time Away Goals"),
                      div("HTR = Half Time Result")
                  )
              ),
              column(8,
                  tabsetPanel(
                      tabPanel("All Matches",
                          tabsetPanel(
                            tabPanel("Data Table", DT::dataTableOutput("allMatches")),
                            tabPanel("Trend Plot", plotOutput("allMatchesTrend")),
                            tabPanel("Box Plot", plotOutput("allMatchesBoxPlot"))
                          )
                      ),
                      # tabPanel("All Matches", DT::dataTableOutput("allMatches")),
                      tabPanel("Home Matches",
                          tabsetPanel(
                            tabPanel("Data Table", DT::dataTableOutput("homeMatches")),
                            tabPanel("Trend Plot", plotOutput("homeMatchesTrend")),
                            tabPanel("Box Plot", plotOutput("homeMatchesBoxPlot"))
                          )
                      ),
                      tabPanel("Away Matches",
                          tabsetPanel(
                            tabPanel("Data Table", DT::dataTableOutput("awayMatches")),
                            tabPanel("Trend Plot", plotOutput("awayMatchesTrend")),
                            tabPanel("Box Plot", plotOutput("awayMatchesBoxPlot"))
                          )
                      ),
                      # tabPanel("Away Matches", DT::dataTableOutput("awayMatches")),
                      tabPanel("By Division", DT::dataTableOutput("divisionMatches")),
                      tabPanel("Last 2", DT::dataTableOutput("last2")),
                      tabPanel("Last 5", DT::dataTableOutput("last5")),
                      tabPanel("Last 10", DT::dataTableOutput("last10")),
                      # tabPanel("Overview", DT::dataTableOutput("overviewMatches"))
                      tabPanel("Overview",
                          tabsetPanel(
                            tabPanel("Absolute", DT::dataTableOutput("overviewMatches")),
                            tabPanel("in %", DT::dataTableOutput("overviewMatchesPercent"))
                          )
                      )
                  )
              )
          )
        ),
        tabPanel("home vs. away",

          fluidRow(
              column(3,
                  sidebarPanel(width = 12,

                          selectInput("home",
                                      label = "Choose a home team",
                                      choices = team <- FolderStructure(path = paste("Data", ReadPreferences()[1], sep = "/")),
                                      selected = "Bayern Munich"),

                          selectInput("away",
                                      label = "Choose a home team",
                                      choices = team <- FolderStructure(path = paste("Data", ReadPreferences()[1], sep = "/")),
                                      selected = "Dortmund")
                  ),
                  sidebarPanel(width = 12, id = "legend",
                      div("Description of the shortcuts:", id = "header"),
                      br(),
                      div("FTHG = Full Time Home Goals"),
                      div("FTAG = Full Time Away Goals"),
                      div("FTR = Full Time Result"),
                      div("HTHG = Half Time Home Goals"),
                      div("HTAG = Half Time Away Goals"),
                      div("HTR = Half Time Result")
                  )
              ),
              column(8,
                  tabsetPanel(
                      tabPanel("Home vs. Away", {
                        tabsetPanel(
                          tabPanel("Data Table", DT::dataTableOutput("compare")),
                          tabPanel("Box Plot", plotOutput("hvaBoxPlot")),
                          tabPanel("Hist Plot", plotOutput("hvaHistPlot")),
                          tabPanel("Summary", DT::dataTableOutput("overview")),
                          tabPanel("Test", DT::dataTableOutput("test"))
                        )
                      }),
                      tabPanel("All matches", {
                        tabsetPanel(
                          tabPanel("All outcomes of the two teams", DT::dataTableOutput("compareAll")),
                          tabPanel("Box Plot", plotOutput("hvaAllBoxPlot"))
                          # tabPanel("Summary", DT::dataTableOutput("overview"))
                        )
                      }),
                      tabPanel("Overview: All outcomes", DT::dataTableOutput("overviewAll")),
                      tabPanel("LM Plot", plotOutput("lmTest"))
                  )
              )
          )
        ),
        
        tags$head(
            tags$link(rel = "stylesheet", type = "text/css", href = "/css/bootstrap.min.css"),
            tags$link(rel = "stylesheet", type = "text/css", href = "/css/styles.css"),
            tags$script(src = "/js/scripts.js")
        )
    )
)