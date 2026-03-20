# Home vs. Away table. Copyright by Michael Bauer.
#
# Functions available:
# 	- GetTableOfSeason(data)

GetTableOfSeason <- function(data) {
	# Get the conditioned data from the database.
	#
	#	data: A data.frame() containing all games of one season.
	#
	#	Return: Returns a data.frame() with the corresponding home vs. away data.
  
  teams <- unique(data[, "HomeTeam"])
  len <- length(teams)
  # games <- 2 * nrow(data) / len
  stats <- list("Team" = teams, "Games" = c(), "Won" = c(), "Draw" = c(), "Lost" = c(),
  							"Goals" = c(), "Diff" = c(), "Points" = c())

  for (team in teams) {  # FOR

    games <- length(which(data[, "HomeTeam"] == team | data[, "AwayTeam"] == team))
    stats$Games <- c(stats$Games, games)
  	won <- length(which((data[, "HomeTeam"] == team & data[, "FTR"] == "H") | (data[, "AwayTeam"] == team & data[, "FTR"] == "A")))
  	draw <- length(which((data[, "HomeTeam"] == team & data[, "FTR"] == "D") | (data[, "AwayTeam"] == team & data[, "FTR"] == "D")))
  	sGoal <- sum(as.numeric(data[which(data[, "HomeTeam"] == team), "FTHG"])) + sum(as.numeric(data[which(data[, "AwayTeam"] == team), "FTAG"]))
  	bGoal <- sum(as.numeric(data[which(data[, "HomeTeam"] == team), "FTAG"])) + sum(as.numeric(data[which(data[, "AwayTeam"] == team), "FTHG"]))
  	stats$Won <- c(stats$Won, won)
  	stats$Draw <- c(stats$Draw, draw)
  	stats$Lost <- c(stats$Lost, games - won - draw)
  	stats$Goals <- c(stats$Goals, paste0(sGoal, ":", bGoal))
  	stats$Diff <- c(stats$Diff, sGoal - bGoal)
  	stats$Points <- c(stats$Points, won*3+draw)

  }  # END FOR

  tab <- data.frame(stats)

	return (tab[order(-tab$Points), ])

}  # END GetTableOfSeason