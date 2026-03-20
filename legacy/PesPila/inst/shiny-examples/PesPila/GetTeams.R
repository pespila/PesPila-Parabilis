# All possible teams from one country are selected from the database. Copyright by Michael Bauer.
#
# Functions available:
# 	- GetTeams(country)

GetTeams <- function(country = "Germany", league = "1. Bundesliga", season = "15/16") {
	# Get teams of a given country.
	#
	#	country: A selected country (string).
	#
	#	Return: Returns a vector with all possible teams in a country.

	InitDB()

	query <- ""

	if(league != "All" && season == "All") {
		query <- paste0("select distinct HomeTeam from ", country, " where Div = '", league, "'")
	} else if(season != "All" && league == "All") {
		query <- paste0("select distinct HomeTeam from ", country, " where Season = '", season, "'")
	} else if(league != "All" && season != "All") {
		query <- paste0("select distinct HomeTeam from ", country, " where Div = '", league, "' and Season = '", season, "'")
	} else {
		query <- paste0("select distinct HomeTeam from ", country)
	}
	
	data <- dbGetQuery(conn = ppConn, statement = query)

	dbDisconnect(conn = ppConn)

	return (as.character(data[, "HomeTeam"]))

}  # END GetTeams