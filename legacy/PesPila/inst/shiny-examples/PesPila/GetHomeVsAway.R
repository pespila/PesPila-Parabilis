# Home vs. Away table. Copyright by Michael Bauer.
#
# Functions available:
# 	- GetHomeVsAway(input, country, home, away)

GetHomeVsAway <- function(country = "Germany", home = "Bayern Munich", away = "Dortmund") {
	# Get the conditioned data from the database.
	#
	#	input: Input fields of the UI.
	#	country: A selected country (string).
	#	home: Home Team.
	#	away: Away Team.
	#
	#	Return: Returns a data.frame() with the corresponding home vs. away data.
  
	InitDB()
	
	query <- paste0("select * from ", country, " where HomeTeam = '", home, "' and AwayTeam = '", away, "'")
	
	data <- dbGetQuery(conn = ppConn, statement = query)

	dbDisconnect(conn = ppConn)
	
	data[data == "NA"] <- NA
	data <- data[nrow(data):1, 3:ncol(data)]

	summary <- c("Overall", home, away,
							 round(mean(as.numeric(data[, "FTHG"]), na.rm = TRUE), 2),
							 round(mean(as.numeric(data[, "FTAG"]), na.rm = TRUE), 2),
							 paste0(length(which(data[, "FTR"] == "H")), "/", length(which(data[, "FTR"] == "D")), "/", length(which(data[, "FTR"] == "A"))),
				 			 round(mean(as.numeric(data[, "HTHG"]), na.rm = TRUE), 2),
				 			 round(mean(as.numeric(data[, "HTAG"]), na.rm = TRUE), 2),
				 			 paste0(length(which(data[, "FTR"] == "H")), "/", length(which(data[, "FTR"] == "D")), "/", length(which(data[, "FTR"] == "A")))
							)
	# summary <- paste0("<font size=4><b>", summary, "</b></font>", sep = "")

	data <- rbind(summary, data)

	return (data)

}  # END GetHomeVsAway