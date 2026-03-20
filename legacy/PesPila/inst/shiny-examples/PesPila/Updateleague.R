# Update the league input field in the league data tab. Copyright by Michael Bauer.
#
# Functions available:
# 	- UpdateLeagueL(session, country)

Updateleague <- function(session, country = "Germany", league = "1. Bundesliga") {
	# Get seasons in a given country for a given league.
	#
	#	session: The shiny session variable.
	#	country: A selected country (string).
	#
	#	Return: No return value.

  divs <- GetLeagues(country = country)
  if (league %in% divs) {
	  updateSelectInput(session = session, inputId = "league",
	                    choices = c("All", divs),
	                    selected = league)
	} else if (league == "All") {
		updateSelectInput(session = session, inputId = "league",
	                    choices = c("All", divs))
	} else {
		updateSelectInput(session = session, inputId = "league",
	                    choices = c("All", divs),
	                    selected = divs[1])
	}

}  # END UpdateLeagueL