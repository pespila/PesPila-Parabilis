# All possible seasons are selected from the database for a country and leage. Copyright by Michael Bauer.
#
# Functions available:
# 	- Uniform(country, league)

Uniform <- function(country = "Germany", team = "Bayern Munich", season = '15/16', against = FALSE) {
	# Get seasons in a given country for a given league.
	#
	#	country: A selected counrty (string).
	#	league: The selected league (string).
	# 	season: A selected season.
	#
	#	Return: Returns a vector with all possible seasons to select.

	InitDB()

	data <- data.frame("Goals" = 0:5, "Freq" = rep(x = 0, times = 6), "NewProbs" = rep(x = 0, times = 6))

	for (i in 0:5) {

#SELECT `_rowid_`,* FROM `Germany` WHERE `Season` LIKE '%93/94%' AND `HomeTeam` LIKE '%RW Essen%' AND `FTHG` LIKE '%0%' ORDER BY `_rowid_` ASC LIMIT 0, 50000;
#SELECT `_rowid_`,* FROM `Germany` WHERE `Season` LIKE '%93/94%' AND `HomeTeam` LIKE '%RW Essen%' AND `FTHG` > 0  ORDER BY `_rowid_` ASC LIMIT 0, 50000;
#SELECT `_rowid_`,* FROM `Germany` WHERE `Season` LIKE '%93/94%' ESCAPE '\' AND `HomeTeam` LIKE '%RW Essen%' ESCAPE '\' AND `FTHG` > 5  ORDER BY `_rowid_` ASC LIMIT 0, 50000;

		# home <- paste0("(select count(FTHG) from `", country, "` where `Season` like '%", season, "%' and `HomeTeam` like '%", team, "%' and `FTHG` like '%", i, "%') + ")
		# away <- paste0("(select count(FTAG) from `", country, "` where `Season` like '%", season, "%' and `AwayTeam` like '%", team, "%' and `FTAG` like '%", i, "%')")
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

			# home <- paste0("(select count(FTHG) from `", country, "` where `Season` like '%", season, "%' and `HomeTeam` like '%", team, "%' and `FTHG` >= '%", i, "%') + ")
			# away <- paste0("(select count(FTAG) from `", country, "` where `Season` like '%", season, "%' and `AwayTeam` like '%", team, "%' and `FTAG` >= '%", i, "%')")
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

	dbDisconnect(conn = ppConn)

	# data$Freq <- c(6, 4, 4, 2, 0, 0)
	# data$Freq <- round(data$Freq/sum(data$Freq), 5)

	lambda <- (sum(data$Goals*data$Freq))/sum(data$Freq)
	a <- 0
	b <- round(2*lambda, 0)
	ba <- b-a+1

	data$NewProbs[which(data$Goals <= b)] <- 1/ba
	data$Predicted <- round(data$NewProbs*sum(data$Freq), 5)

	index <- which(data$Predicted != 0)

	if (length(index) == 0) {

		return (list("Table" = data, "ChiSquare" = 0, "Normal" = rep(x = 0, times = nrow(data)), "a" = 0, "b" = 0))

	}

	# data$NewProbs[6] <- data$NewProbs[6] + (1 - sum(data$NewProbs))
	# test <- chisq.test(x = data$Freq[index], p = data$NewProbs[index], simulate.p.value = TRUE)
	# sum <- 1 - sum(data$NewProbs)
	# test <- chisq.test(x = c(data$Freq, 0), p = c(data$NewProbs, sum), simulate.p.value = TRUE)
	# comp <- 1 - sum(data$NewProbs[index])
	# test <- chisq.test(x = c(data$Freq[index], 0), p = c(data$NewProbs[index], comp), simulate.p.value = TRUE)

	chi <- sum((data$Freq[index]-data$Predicted[index])^2 / data$Predicted[index])
	pval <- 1 - pchisq(chi, df = length(index) - 1)
	test <- list("p.value" = pval)

	# print(test)

	output <- list("Table" = data, "ChiSquare" = test, "Normal" = as.numeric(data$Freq/sum(data$Freq)), "a" = a, "b" = b)
	# output <- list("Table" = data, "ChiSquare" = pval, "Normal" = as.numeric(data$Freq/sum(data$Freq)), "a" = a, "b" = b)

	return (output)

}  # END Uniform