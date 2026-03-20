# Get team statistics. Copyright by Michael Bauer.
#
# Functions available:
# 	- StatsTeamData(country, team, locus, season)

StatsTeamData <- function(country = "Germany", team = "Bayern Munich", locus = "HomeTeam", season = NA) {
	# Get seasons in a given country for a given league.
	#
	#	country: A selected country (string).
	#	team: The selected home/away team (string).
	# locus: Either HomeTeam or AwayTeam (string).
	#
	#	Return: No return value.

  InitDB()

  seas <- ""

  if (!is.na(season)) {  # IF

  	if (season != "All") {  # IF

  		seas <- paste0(" and season = '", season, "'")

  	}  # END IF

  }  # END IF

  query <- paste0("select count(FTR) from ", country, " where ", locus, " = '", team, "' and FTR = 'H'", seas)
  times <- as.numeric(dbGetQuery(conn = ppConn, statement = query)[1, 1])
  
  query <- paste0("select count(FTR) from ", country, " where ", locus, " = '", team, "' and FTR = 'D'", seas)
  times <- c(times, as.numeric(dbGetQuery(conn = ppConn, statement = query)[1, 1]))
  
  query <- paste0("select count(FTR) from ", country, " where ", locus, " = '", team, "' and FTR = 'A'", seas)
  times <- c(times, as.numeric(dbGetQuery(conn = ppConn, statement = query)[1, 1]))
  
  dbDisconnect(conn = ppConn)
  
  if (locus != "HomeTeam") {  # IF

    times <- rev(times)
  
  }  # END IF

  names(times) <- c("Win", "Draw", "Lost")

  return (times)

}  # END StatsTeamData