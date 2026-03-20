WinDrawLost <- function(output, team, season, country, stat, plot, head) {
  InitDB()
  query <- ""
  if (stat == "All") {
    query <- paste0("select A.Win, A.Draw, A.Lost from Scored A, Countries B, Seasons C, Teams D where D.Team = '", team, "' and A.Team_ID = D.Team_ID and C.Season = '", season, "' and A.Season_ID = C.Season_ID and B.Country = '", country, "' and A.Country_ID = B.Country_ID")
  } else if (stat == "Home") {
    query <- paste0("select A.Win_Home as Win, A.Draw_Home as Draw, A.Lost_Home as Lost from Scored A, Countries B, Seasons C, Teams D where D.Team = '", team, "' and A.Team_ID = D.Team_ID and C.Season = '", season, "' and A.Season_ID = C.Season_ID and B.Country = '", country, "' and A.Country_ID = B.Country_ID")
  } else {
    query <- paste0("select (A.Win-A.Win_Home) as Win, (A.Draw-A.Draw_Home) as Draw, (A.Lost-A.Lost_Home) as Lost from Scored A, Countries B, Seasons C, Teams D where D.Team = '", team, "' and A.Team_ID = D.Team_ID and C.Season = '", season, "' and A.Season_ID = C.Season_ID and B.Country = '", country, "' and A.Country_ID = B.Country_ID")
  }
  data <- as.matrix(dbGetQuery(conn = ppConn, statement = query))
  dbDisconnect(conn = ppConn)
  output[[plot]] <- renderPlot({
    barplot(data[1,], ylab = "Number of games", col = c("#00AA00", "#8CA3B1", "#FF0000"), ylim = c(0, max(data)+5))
  })
  header <- paste0(stat, " Games of ", team, " ", season)
  output[[head]] <- renderText({header})
}