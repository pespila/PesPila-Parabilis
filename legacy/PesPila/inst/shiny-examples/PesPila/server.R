# OptParsZIP <- function(pars, A, B, C, D) {
#   E <- sum(A*B*(dzipois(x = C, lambda = pars[1], phi = pars[2])-D)^2)
#   return (E)
# }
# Opt <- optim(pars, OptParsZIP, A = data$Freq, B = data$FreqWeight, C = data$Goals, D = data$RelFreq)

# OptParsLambda <- function(pars, THG, TAG, HG, AG) {
#   F <- pars[1] * (THG - HG - (TAG - AG))
#   return (F)
# }

# TestPredict <- function(session, input, output, homeTable, awayTable, table) {
#   hParm <- ""
#   aParm <- ""
#   hProb <- rep(x = 0, times = 6)
#   aProb <- rep(x = 0, times = 6)
#   goals <- 0:5
#   ngoal <- length(goals)
#   mat <- data.frame(matrix(data = 0, nrow = ngoal, ncol = ngoal))
#   colnames(mat) <- 0:5
#   rownames(mat) <- 0:5
#   hWin <- 0
#   aWin <- 0
#   draw <- 0
#   tMax <- 0
#   tInd <- c()

#   InitDB()
  
#   home <- paste0("select A.Dist from ", homeTable, " A, Seasons B, Teams C, Countries D where B.Season = '", input$season, "' and A.Season_ID = B.Season_ID and C.Team = '", input$fHome, "' and A.Team_ID = C.Team_ID and D.Country = '", input$country, "' and A.Country_ID = D.Country_ID")
#   home <- as.character(dbGetQuery(conn = ppConn, statement = home)[1, "Dist"])
#   hStr <- strsplit(home, split = "_")[[1]]

#   if (hStr[1] == "Poisson") {
#     hParm <- paste0(hStr[1], "_Lambda")
#   } else if (hStr[1] == "ZIP") {
#     hParm <- paste0(hStr[1], c("_Phi", "_Lambda"))
#   } else if (hStr[1] == "Uniform") {
#     hParm <- paste0(hStr[1], c("_A", "_B"))
#   } else if (hStr[1] == "Geometric") {
#     hParm <- paste0(hStr[1], "_P")
#   } else if (hStr[1] == "NBD") {
#     hParm <- paste0(hStr[1], c("_K", "_P"))
#   }

#   query <- paste0("select ", paste0("A.", home), ", ", paste("A.", hParm, collapse = ","), " from ", homeTable, " A, Seasons B, Teams C, Countries D where B.Season = '", input$season, "' and A.Season_ID = B.Season_ID and C.Team = '", input$fHome, "' and A.Team_ID = C.Team_ID and D.Country = '", input$country, "' and A.Country_ID = D.Country_ID")
#   home <- dbGetQuery(conn = ppConn, statement = query)[1, ]
  
#   away <- paste0("select A.Dist from ", awayTable, " A, Seasons B, Teams C, Countries D where B.Season = '", input$season, "' and A.Season_ID = B.Season_ID and C.Team = '", input$fAway, "' and A.Team_ID = C.Team_ID and D.Country = '", input$country, "' and A.Country_ID = D.Country_ID")
#   away <- as.character(dbGetQuery(conn = ppConn, statement = away)[1, "Dist"])
#   aStr <- strsplit(away, split = "_")[[1]]
  
#   if (aStr[1] == "Poisson") {
#     aParm <- paste0(aStr[1], "_Lambda")
#   } else if (aStr[1] == "ZIP") {
#     aParm <- paste0(aStr[1], c("_Phi", "_Lambda"))
#   } else if (aStr[1] == "Uniform") {
#     aParm <- paste0(aStr[1], c("_A", "_B"))
#   } else if (aStr[1] == "Geometric") {
#     aParm <- paste0(aStr[1], "_P")
#   } else if (aStr[1] == "NBD") {
#     aParm <- paste0(aStr[1], c("_K", "_P"))
#   }

#   query <- paste0("select ", paste0("A.", away), ", ", paste("A.", aParm, collapse = ","), " from ", awayTable, " A, Seasons B, Teams C, Countries D where B.Season = '", input$season, "' and A.Season_ID = B.Season_ID and C.Team = '", input$fAway, "' and A.Team_ID = C.Team_ID and D.Country = '", input$country, "' and A.Country_ID = D.Country_ID")
#   away <- dbGetQuery(conn = ppConn, statement = query)[1, ]

#   dbDisconnect(conn = ppConn)

#   if (hStr[1] == "Poisson") {
#     hProb <- dpois(x = goals, lambda = home[1, "Poisson_Lambda"])
#   } else if (hStr[1] == "ZIP") {
#     hProb <- dzipois(x = goals, lambda = home[1, "ZIP_Lambda"], phi = home[1, "ZIP_Phi"])
#   } else if (hStr[1] == "Uniform") {
#     hProb[which(goals <= home[1, "Uniform_B"])] <- 1/(home[1, "Uniform_B"] - home[1, "Uniform_A"] + 1)
#   } else if (hStr[1] == "Geometric") {
#     hProb <- dgeom(x = goals, prob = home[1, "Geometric_P"])
#   } else if (hStr[1] == "NBD") {
#     hProb <- dnbinom(x = goals, mu = home[1, "NBD_K"], size = home[1, "NBD_P"])
#   }

#   if (aStr[1] == "Poisson") {
#     aProb <- dpois(x = goals, lambda = away[, "Poisson_Lambda"])
#   } else if (aStr[1] == "ZIP") {
#     aProb <- dzipois(x = goals, lambda = away[1, "ZIP_Lambda"], phi = away[1, "ZIP_Phi"])
#   } else if (aStr[1] == "Uniform") {
#     aProb[which(goals <= away[1, "Uniform_B"])] <- 1/(away[1, "Uniform_B"] - away[1, "Uniform_A"] + 1)
#   } else if (aStr[1] == "Geometric") {
#     aProb <- dgeom(x = goals, prob = away[1, "Geometric_P"])
#   } else if (aStr[1] == "NBD") {
#     aProb <- dnbinom(x = goals, mu = away[1, "NBD_K"], size = away[1, "NBD_P"])
#   }

#   for (i in 1:ngoal) {
#     for (j in 1:ngoal) {
#       mat[i, j] <- hProb[i] * aProb[j]
#       if (i == j) {
#         draw <- draw + mat[i, j] * 100
#       } else if (j > i) {
#         aWin <- aWin + mat[i, j] * 100
#       } else {
#         hWin <- hWin + mat[i, j] * 100
#       }
#     }
#   }


#   if (draw > 25 && hWin > 40) {
#     for (i in 1:ngoal) {
#       for (j in 1:i) {
#         if (mat[i, j] >= tMax) {
#           tInd <- c(i-1, j-1)
#           tMax <- mat[i, j]
#         }
#       }
#     }
#   } else if (draw > 25 && aWin > 40) {
#     for (i in 1:ngoal) {
#       for (j in i:ngoal) {
#         if (mat[i, j] >= tMax) {
#           tInd <- c(i-1, j-1)
#           tMax <- mat[i, j]
#         }
#       }
#     }
#   } else if (hWin > 40) {
#     for (i in 2:ngoal) {
#       for (j in 1:(i-1)) {
#         if (mat[i, j] >= tMax) {
#           tInd <- c(i-1, j-1)
#           tMax <- mat[i, j]
#         }
#       }
#     }
#   } else if (aWin > 40) {
#     for (i in 2:ngoal) {
#       for (j in (i-1):ngoal) {
#         if (mat[i, j] >= tMax) {
#           tInd <- c(i-1, j-1)
#           tMax <- mat[i, j]
#         }
#       }
#     }
#   } else {
#     if (hWin >= aWin && hWin >= draw) {
#       for (i in 2:ngoal) {
#         for (j in 1:(i-1)) {
#           if (mat[i, j] >= tMax) {
#             tInd <- c(i-1, j-1)
#             tMax <- mat[i, j]
#           }
#         }
#       }
#     } else if (aWin >= hWin && aWin >= draw) {
#       for (i in 2:ngoal) {
#         for (j in (i-1):ngoal) {
#           if (mat[i, j] >= tMax) {
#             tInd <- c(i-1, j-1)
#             tMax <- mat[i, j]
#           }
#         }
#       }
#     } else if (draw >= hWin && draw >= aWin) {
#       for (i in 1:ngoal) {
#         if (mat[i, i] >= tMax) {
#           tInd <- c(i-1, i-1)
#           tMax <- mat[i, i]
#         }
#       }
#     }
#   }

#   homeOdd <- if ((100/hWin) - 1 < 1) {1.0} else {(100/hWin) - 1}
#   drawOdd <- if ((100/draw) - 1 < 1) {1.0} else {(100/draw) - 1}
#   awayOdd <- if ((100/aWin) - 1 < 1) {1.0} else {(100/aWin) - 1}

#   out <- data.frame("hWin" = hWin, "draw" = draw, "aWin" = aWin, "homeOdd" = homeOdd, "drawOdd" = drawOdd,
#                     "awayOdd" = awayOdd, "FTHG" = tInd[1], "FTAG" = tInd[2])

#   # rownames(mat) <- 0:5
#   # output[[table]] <- DT::renderDataTable({datatable(round(mat, 4), rownames = TRUE, escape = FALSE)})

#   return (out)
# }

shinyServer(function(input, output, session) {

  observeEvent(eventExpr = input$getSetting, {
    withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {
      Updateteam(session = session, country = input$country, league = input$league, season = input$season)
    })
  })

  observeEvent(eventExpr = input$getLeagues, {
    withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {
      Updateleague(session = session, country = input$country, league = input$league)
    })
  })

  observeEvent(eventExpr = input$getSeasons, {
    withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {
      Updateseason(session = session, country = input$country, league = input$league, season = input$season)
    })
  })

  observeEvent(eventExpr = input$getDistributions, {
    withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {
      output$gScored <- DT::renderDataTable({

        withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {

          if (input$country != "" && input$season != "" && input$home != "" && input$league != "") {

            InitDB()
            query <- paste0("select A.* from Scored A, Seasons B, Teams C, Countries D where B.Season = '", input$season, "' and A.Season_ID = B.Season_ID and C.Team = '", input$team, "' and A.Team_ID = C.Team_ID and D.Country = '", input$country, "' and A.Country_ID = D.Country_ID")
            data <- dbGetQuery(conn = ppConn, statement = query)
            dbDisconnect(conn = ppConn)

            goals <- 0:5
            a <- data[1, "Uniform_A"]
            b <- data[1, "Uniform_B"]
            unif <- rep(x = 0, times = length(goals))
            unif[which(goals <= b)] <- 1/(b-a+1)

            df <- data.frame("Goals" = goals,
                             "Frequencies" = round(as.numeric(data[1, c("Zero", "One", "Two", "Three", "Four", "Five")]), 5),
                             "Poisson" = round(dpois(x = goals, lambda = data[1, "Poisson_Lambda"]), 5),
                             "Zero.Inflated.Poisson" = round(dzipois(x = goals, lambda = data[1, "ZIP_Lambda"], phi = data[1, "ZIP_Phi"]), 5),
                             "Uniform" = round(unif, 5),
                             "Geometric" = round(dgeom(x = goals, prob = data[1, "Geometric_P"]), 5),
                             "Negative.Binomial" = round(dnbinom(x = goals, mu = data[1, "NBD_K"], size = data[1, "NBD_P"]), 5),
                             "Model" = c("Poisson", "Zero-Inflated-Poisson", "Uniform", "Geometric", "Negative-Binomial", NA),
                             "Pval" = c(100*round(data[1, "Poisson_Pval"], 4), 100*round(data[1, "ZIP_Pval"], 4), 100*round(data[1, "Uniform_Pval"], 4), 100*round(data[1, "Geometric_Pval"], 4), 100*round(data[1, "NBD_Pval"], 4), NA)
            )

            output$goalScored <- renderPlot({

              ggplot(df, aes(x = Goals)) + 
                    geom_line(aes(y = Frequencies), colour = "red", size = 1.2) + 
                    geom_line(aes(y = Poisson), colour = "blue") + 
                    geom_line(aes(y = Zero.Inflated.Poisson), colour = "green") + 
                    geom_line(aes(y = Uniform), colour = "black") + 
                    geom_line(aes(y = Geometric), colour = "purple") + 
                    geom_line(aes(y = Negative.Binomial), colour = "orange") + 
                    geom_point(aes(y = Frequencies)) + 
                    geom_point(aes(y = Poisson)) + 
                    geom_point(aes(y = Zero.Inflated.Poisson)) + 
                    geom_point(aes(y = Uniform)) + 
                    geom_point(aes(y = Geometric)) + 
                    geom_point(aes(y = Negative.Binomial)) +
                    # coord_cartesian(xlim = rangesP$x, ylim = rangesP$y) + 
                    theme(axis.title.x = element_text(face="bold", colour="black", size=15), axis.title.y = element_text(face="bold", colour="black", size=15)) + 
                    ylab("Frequencies")# + 
                    # coord_cartesian(xlim = ranges$x, ylim = ranges$y)

            })

            datatable(df[1:5, c("Model", "Pval")],
                rownames = FALSE,
                escape = FALSE
            )

          }

        })
      
      })

      output$gConceded <- DT::renderDataTable({

        withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {

          if (input$country != "" && input$season != "" && input$home != "" && input$league != "") {

            InitDB()
            query <- paste0("select A.* from Conceded A, Seasons B, Teams C, Countries D where B.Season = '", input$season, "' and A.Season_ID = B.Season_ID and C.Team = '", input$team, "' and A.Team_ID = C.Team_ID and D.Country = '", input$country, "' and A.Country_ID = D.Country_ID")
            data <- dbGetQuery(conn = ppConn, statement = query)
            dbDisconnect(conn = ppConn)

            goals <- 0:5
            a <- data[1, "Uniform_A"]
            b <- data[1, "Uniform_B"]
            unif <- rep(x = 0, times = length(goals))
            unif[which(goals <= b)] <- 1/(b-a+1)

            df <- data.frame("Goals" = goals,
                             "Frequencies" = round(as.numeric(data[1, c("Zero", "One", "Two", "Three", "Four", "Five")]), 5),
                             "Poisson" = round(dpois(x = goals, lambda = data[1, "Poisson_Lambda"]), 5),
                             "Zero.Inflated.Poisson" = round(dzipois(x = goals, lambda = data[1, "ZIP_Lambda"], phi = data[1, "ZIP_Phi"]), 5),
                             "Uniform" = round(unif, 5),
                             "Geometric" = round(dgeom(x = goals, prob = data[1, "Geometric_P"]), 5),
                             "Negative.Binomial" = round(dnbinom(x = goals, mu = data[1, "NBD_K"], size = data[1, "NBD_P"]), 5),
                             "Model" = c("Poisson", "Zero-Inflated-Poisson", "Uniform", "Geometric", "Negative-Binomial", NA),
                             "Pval" = c(100*round(data[1, "Poisson_Pval"], 4), 100*round(data[1, "ZIP_Pval"], 4), 100*round(data[1, "Uniform_Pval"], 4), 100*round(data[1, "Geometric_Pval"], 4), 100*round(data[1, "NBD_Pval"], 4), NA)
            )

            output$goalConceded <- renderPlot({

              ggplot(df, aes(x = Goals)) + 
                    geom_line(aes(y = Frequencies), colour = "red", size = 1.2) + 
                    geom_line(aes(y = Poisson), colour = "blue") + 
                    geom_line(aes(y = Zero.Inflated.Poisson), colour = "green") + 
                    geom_line(aes(y = Uniform), colour = "black") + 
                    geom_line(aes(y = Geometric), colour = "purple") + 
                    geom_line(aes(y = Negative.Binomial), colour = "orange") + 
                    geom_point(aes(y = Frequencies)) + geom_point(aes(y = Poisson)) + 
                    geom_point(aes(y = Zero.Inflated.Poisson)) + 
                    geom_point(aes(y = Uniform)) + 
                    geom_point(aes(y = Geometric)) + 
                    geom_point(aes(y = Negative.Binomial)) + 
                    # coord_cartesian(xlim = rangesP$x, ylim = rangesP$y) + 
                    theme(axis.title.x = element_text(face="bold", colour="black", size=15), axis.title.y = element_text(face="bold", colour="black", size=15)) + 
                    ylab("Frequencies")# + 
                    # coord_cartesian(xlim = ranges$x, ylim = ranges$y)

            })

            datatable(df[1:5, c("Model", "Pval")],
                rownames = FALSE,
                escape = FALSE
            )

          }

        })
      
      })
    })
  })

  output$prediction <- renderUI({

    withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {


      test <- GetHomeVsAway(country = input$country, home = input$fHome, away = input$fAway)
      SvS <- TestPredict(session = session, input = input, output = output, homeTable = "Scored", awayTable = "Scored", table = "SvS")
      CvC <- TestPredict(session = session, input = input, output = output, homeTable = "Conceded", awayTable = "Conceded", table = "CvC")
      # SvC <- TestPredict(session = session, input = input, output = output, homeTable = "Scored", awayTable = "Conceded", table = "SvC")
      # CvS <- TestPredict(session = session, input = input, output = output, homeTable = "Conceded", awayTable = "Scored", table = "CvS")


      s <- as.numeric(test[1, "FTHG"]) + as.numeric(test[1, "FTAG"])
      if (s == 0) {s <- 1}
      H <- (SvS[1, "FTHG"] + CvC[1, "FTHG"]) * (as.numeric(test[2, "FTHG"]) / s)
      A <- (SvS[1, "FTAG"] + CvC[1, "FTAG"]) * (as.numeric(test[2, "FTAG"]) / s)
      # H <- (0.66 * SvS[1, "FTHG"] + 0.33 * CvC[1, "FTHG"])
      # A <- (0.66 * SvS[1, "FTAG"] + 0.33 * CvC[1, "FTAG"]) / 1.5
      # H <- (0.66 * SvS[1, "FTHG"] + 0.33 * CvC[1, "FTHG"] + as.numeric(test[1, "FTHG"]))
      # A <- (0.66 * SvS[1, "FTAG"] + 0.33 * CvC[1, "FTAG"] + as.numeric(test[1, "FTAG"])) / 2
      # H <- (SvS[1, "FTHG"] + CvC[1, "FTHG"] + SvC[1, "FTHG"] + CvS[1, "FTHG"] + as.numeric(test[1, "FTHG"])) / 4
      # A <- (SvS[1, "FTAG"] + CvC[1, "FTAG"] + SvC[1, "FTAG"] + CvS[1, "FTAG"] + as.numeric(test[1, "FTAG"])) / 5
      H <- round(H, 0)
      A <- round(A, 0)
      # pars <- c(lambda = 0.5)
      # Opt <- optim(pars, OptParsLambda, THG = H, TAG = A, HG = round(as.numeric(test[2, "FTHG"]), 0), AG = round(as.numeric(test[2, "FTAG"]), 0))

        HTML(
          paste(c(
              '<table style="font-size:20px;">
                <tr>
                  <td style="padding:5px;"><u>Actual</u></td>
                  <td style="padding:5px;"><b>', input$fHome, '</b></td>
                  <td style="padding:5px;">', round(as.numeric(test[2, "FTHG"]), 0), '</td>
                  <td style="padding:5px;">', round(as.numeric(test[2, "FTAG"]), 0), '</td>
                  <td style="padding:5px;"><b>', input$fAway, '</b></td>
                </tr>
                <tr>
                  <td style="padding:5px;"><u>Predict</u></td>
                  <td style="padding:5px;"><b>', input$fHome, '</b></td>
                  <td style="padding:5px;">', H, '</td>
                  <td style="padding:5px;">', A, '</td>
                  <td style="padding:5px;"><b>', input$fAway, '</b></td>
                </tr>
              </table>'
            )
          )
        )

    })

  })

  observeEvent(eventExpr = input$getVS, {
    withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {

      output$gamesHeader <- renderText({paste0("Games of ", input$league, " - Season ", input$season)})
      output$seasonHeader <- renderText({paste0("Table of ", input$league, " - Season ", input$season)})
      output$vsHeader <- renderText({paste0(input$home, " vs. ", input$away)})

      output$Games <- DT::renderDataTable({

        withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {

          data <- GetLeagueTable(country = input$country, league = input$league, season = input$season)

          datatable(data,
              rownames = FALSE, escape = FALSE,
              extensions = c('ColReorder', 'ColVis', 'Responsive'),
              options = list(pageLength = -1,
                  lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                  deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                  searchHighlight = TRUE,
                  dom = 'TRCSlfrtip<"clear">',
                  colReorder = list(realtime = TRUE)
              )
          )

        })

      })


      # output$Tables <- DT::renderDataTable({

      #   withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {

      #     data <- GetLeagueTable(country = input$country, league = input$league, season = input$season)
      #     table <- GetTableOfSeason(data = data)
      #     table <- cbind("Place" = 1:nrow(table), table)

      #     datatable(table,
      #         rownames = FALSE, escape = FALSE,
      #         extensions = c('ColReorder', 'ColVis', 'Responsive'),
      #         options = list(pageLength = -1,
      #             lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
      #             deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
      #             searchHighlight = TRUE,
      #             dom = 'TRCSlfrtip<"clear">',
      #             colReorder = list(realtime = TRUE)
      #         )
      #     )

      #   })

      # })

      output$vs <- DT::renderDataTable({

        withProgress(message = 'Calculation in progress', detail = 'This may take a while...', min = 0, max = 2, {

          data <- GetHomeVsAway(country = input$country, home = input$home, away = input$away)

          datatable(data,
              rownames = FALSE, escape = FALSE,
              extensions = c('ColReorder', 'ColVis', 'Responsive'),
              options = list(pageLength = -1,
                  lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                  deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                  searchHighlight = TRUE,
                  dom = 'TRCSlfrtip<"clear">',
                  colReorder = list(realtime = TRUE)
              )
          )

        })

      })

      WinDrawLost(output = output, team = input$home, season = input$season, country = input$country,
                  stat = "All", plot = "allGamesOfHomeStat", head = "allGamesOfHome")
      WinDrawLost(output = output, team = input$home, season = input$season, country = input$country,
                        stat = "Home", plot = "homeGamesOfHomeStat", head = "homeGamesOfHome")
      WinDrawLost(output = output, team = input$home, season = input$season, country = input$country,
                        stat = "Away", plot = "awayGamesOfHomeStat", head = "awayGamesOfHome")
      WinDrawLost(output = output, team = input$away, season = input$season, country = input$country,
                        stat = "All", plot = "allGamesOfAwayStat", head = "allGamesOfAway")
      WinDrawLost(output = output, team = input$away, season = input$season, country = input$country,
                        stat = "Home", plot = "homeGamesOfAwayStat", head = "homeGamesOfAway")
      WinDrawLost(output = output, team = input$away, season = input$season, country = input$country,
                        stat = "Away", plot = "awayGamesOfAwayStat", head = "awayGamesOfAway")

    })
  })

})