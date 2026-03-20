# All possible seasons are selected from the database for a country and leage. Copyright by Michael Bauer.
#
# Functions available:
# 	- ZIP(country, league)

dzipois <- function(x, lambda, phi) {
	zip <- c()
	if (lambda < 0) {
		return (rep(x = NaN, times = length(x)))
	}
	if (phi < 0 || phi > 1) {
		return (rep(x = NaN, times = length(x)))
	}
	index <- which(x == 0)
	if (length(index) > 0) {
		zip <- c(zip, (1-phi)+phi*dpois(x[index], lambda = lambda))
		x <- x[-index]
	}
	zip <- c(zip, phi*dpois(x, lambda = lambda))

	return (zip)
}

OptParsZIP <- function(pars, A, B, C, D) {
	E <- sum(A*B*(dzipois(x = C, lambda = pars[1], phi = pars[2])-D)^2)
	return (E)
}

ZIP <- function(country = "Germany", team = "Bayern Munich", season = '15/16', against = FALSE) {
	# Get seasons in a given country for a given league.
	#
	#	country: A selected counrty (string).
	#	league: The selected league (string).
	# season: A selected season.
	#
	#	Return: Returns a vector with all possible seasons to select.

	lambda <- 2
	phi <- 0.5
	pars <- c(lambda = lambda, phi = phi)
	data <- data.frame("Goals" = 0:5, "Freq" = rep(x = 0, times = 6))

	InitDB()

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

	dbDisconnect(conn = ppConn)

	# data$Freq <- c(8, 4, 0, 3, 1, 0)
	# data$Freq <- round(data$Freq/sum(data$Freq), 5)

	data$RelFreq <- round(data$Freq/sum(data$Freq), 5)

	data$Probs <- round(dzipois(x = data$Goals, lambda = lambda, phi = phi), 5)

	data$FreqWeight <- rep(x = 0, times = 6)
	index <- which(data$RelFreq != 0)
	data$FreqWeight[index] <- round(1.0/(data$RelFreq[index]*(1.0 - data$RelFreq[index])), 5)
	
	data$SquareDev <- round((data$Probs - data$RelFreq)^2, 5)
	data$WeightedSquareDev <- round(data$Freq*data$FreqWeight*data$SquareDev, 5)
	
	Opt <- optim(pars, OptParsZIP, A = data$Freq, B = data$FreqWeight, C = data$Goals, D = data$RelFreq)
	lambda <- Opt$par[1]
	phi <- Opt$par[2]

	data$NewProbs <- round(dzipois(x = data$Goals, lambda = lambda, phi = phi), 5)
	data$Predicted <- round(data$NewProbs*sum(data$Freq), 5)

	# data$NewProbs[6] <- data$NewProbs[6] + (1 - sum(data$NewProbs))
	# test <- chisq.test(x = data$Freq, p = data$NewProbs, simulate.p.value = TRUE)
	sum <- 1 - sum(data$NewProbs)
	test <- chisq.test(x = c(data$Freq, 0), p = c(data$NewProbs, sum), simulate.p.value = TRUE)

	# comp <- 1 - sum(data$NewProbs)
	# test <- chisq.test(x = c(data$Freq, 0), p = c(data$NewProbs, comp), simulate.p.value = TRUE)

	# print(test)

	output <- list("Table" = data, "ChiSquare" = test, "Normal" = as.numeric(data$Freq/sum(data$Freq)), "lambda" = lambda, "phi" = phi)

	return (output)

}  # END ZIP