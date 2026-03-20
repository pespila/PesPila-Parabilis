# Update the league input field in the league data tab. Copyright by Michael Bauer.
#
# Functions available:
# 	- UpdateLeagueT(session, country)

Updateteam <- function(session, country = "Germany", league = "1. Bundesliga", season = "15/16") {
	# Get seasons in a given country for a given league.
	#
	#	session: The shiny sesssion variable.
	#	country: A selected country (string).
	#
	#	Return: No return value.

  teams <- GetTeams(country = country, league = league, season = season)
  updateSelectInput(session = session, inputId = "home",
                    choices = teams,
                    selected = teams[1])
  updateSelectInput(session = session, inputId = "team",
                    choices = teams,
                    selected = teams[1])
  updateSelectInput(session = session, inputId = "fHome",
                    choices = teams,
                    selected = teams[1])
  updateSelectInput(session = session, inputId = "away",
                    choices = teams,
                    selected = teams[2])
  updateSelectInput(session = session, inputId = "fAway",
                    choices = teams,
                    selected = teams[2])

}  # END UpdateLeagueT