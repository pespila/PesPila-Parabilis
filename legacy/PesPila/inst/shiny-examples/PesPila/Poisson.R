# All possible seasons are selected from the database for a country and leage. Copyright by Michael Bauer.
#
# Functions available:
# 	- Poisson(country, league)

Poisson <- function(country = "Germany", team = "Bayern Munich", season = '15/16', against = FALSE) {
	# Get seasons in a given country for a given league.
	#
	#	country: A selected counrty (string).
	#	league: The selected league (string).
	# season: A selected season.
	#
	#	Return: Returns a vector with all possible seasons to select.

	InitDB()

	data <- data.frame("Goals" = 0:5, "Freq" = rep(x = 0, times = 6))

	for (i in 0:5) {

		home <- paste0("(select count(FTHG) from ", country, " where HomeTeam = '", team, "' and FTHG = '", i, "' and Season = '", season, "') + ")
		away <- paste0("(select count(FTAG) from ", country, " where AwayTeam = '", team, "' and FTAG = '", i, "' and Season = '", season, "')")

		if (season == "All") {
			home <- paste0("(select count(FTHG) from ", country, " where HomeTeam = '", team, "' and FTHG = '", i, "') + ")
			away <- paste0("(select count(FTAG) from ", country, " where AwayTeam = '", team, "' and FTAG = '", i, "')")
		}

		if (against) {
			home <- paste0("(select count(FTAG) from ", country, " where HomeTeam = '", team, "' and FTAG = '", i, "' and Season = '", season, "') + ")
			away <- paste0("(select count(FTHG) from ", country, " where AwayTeam = '", team, "' and FTHG = '", i, "' and Season = '", season, "')")
		}
		
		if (i == 5) {  # IF

			home <- paste0("(select count(FTHG) from ", country, " where HomeTeam = '", team, "' and FTHG >= '", i, "' and Season = '", season, "') + ")
			away <- paste0("(select count(FTAG) from ", country, " where AwayTeam = '", team, "' and FTAG >= '", i, "' and Season = '", season, "')")

			if (season == "All") {
				home <- paste0("(select count(FTHG) from ", country, " where HomeTeam = '", team, "' and FTHG >= '", i, "') + ")
				away <- paste0("(select count(FTAG) from ", country, " where AwayTeam = '", team, "' and FTAG >= '", i, "')")
			}

			if (against) {
				home <- paste0("(select count(FTAG) from ", country, " where HomeTeam = '", team, "' and FTAG >= '", i, "' and Season = '", season, "') + ")
				away <- paste0("(select count(FTHG) from ", country, " where AwayTeam = '", team, "' and FTHG >= '", i, "' and Season = '", season, "')")
			}

		}  # END IF

		query <- paste0("select ", home, away, " as SumCount")
		data[i+1, "Freq"] <- as.numeric(dbGetQuery(conn = ppConn, statement = query)[1, "SumCount"])

	}

	# data$Freq <- c(0, 3, 6, 4, 0, 3)

	dbDisconnect(conn = ppConn)

	# data$Freq <- round(data$Freq/sum(data$Freq), 5)
	lambda <- (sum(data$Goals*data$Freq))/sum(data$Freq)
	
	data$NewProbs <- round(dpois(x = data$Goals, lambda = lambda), 5)
	data$Predicted <- round(data$NewProbs*sum(data$Freq), 5)

	# data$NewProbs[6] <- data$NewProbs[6] + (1 - sum(data$NewProbs))
	# data$NewProbs[6] <- data$NewProbs[6] + (1 - sum(data$NewProbs))
	sum <- 1 - sum(data$NewProbs)
	test <- chisq.test(x = c(data$Freq, 0), p = c(data$NewProbs, sum), simulate.p.value = TRUE)

	# comp <- 1 - sum(data$NewProbs)
	# test <- chisq.test(x = c(data$Freq, 0), p = c(data$NewProbs, comp), simulate.p.value = TRUE)

	# print(test)

	output <- list("Table" = data, "ChiSquare" = test, "Normal" = as.numeric(data$Freq/sum(data$Freq)))

	return (output)

}  # END Poisson