# All possible seasons are selected from the database for a country and leage. Copyright by Michael Bauer.
#
# Functions available:
# 	- GetSeasons(country, league)

GetSeasons <- function(country = "Germany", league = "1. Bundesliga") {
	# Get seasons in a given country for a given league.
	#
	#	country: A selected counrty (string).
	#	league: The selected league (string).
	#
	#	Return: Returns a vector with all possible seasons to select.

	InitDB()
  
	query <- paste0("select distinct Season from ", country, " where Div = '", league, "'")

	if (league == "All") {query <- paste0("select distinct Season from ", country)}
	
	data <- dbGetQuery(conn = ppConn, statement = query)

	dbDisconnect(conn = ppConn)

	return (as.character(data[, "Season"]))

}  # END GetSeasons