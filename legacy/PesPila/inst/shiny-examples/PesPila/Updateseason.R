# Update the season input field in the league data tab. Copyright by Michael Bauer.
#
# Functions available:
# 	- UpdateLeagueS(session, country, league)

Updateseason <- function(session, country = "Germany", league = "1. Bundesliga", season = "15/16") {
	# Get seasons in a given country for a given league.
	#
	#	Return: No return value.

  seas <- rev(GetSeasons(country = country, league = league))
  if (season %in% seas) {
	  updateSelectInput(session = session, inputId = "season",
	                    choices = c("All", seas),
	                    selected = season)
	} else if (season == "All") {
		updateSelectInput(session = session, inputId = "season",
	                    choices = c("All", seas))
	} else {
		updateSelectInput(session = session, inputId = "season",
	                    choices = c("All", seas),
	                    selected = seas[1])
	}

}  # END UpdateLeagueS


	