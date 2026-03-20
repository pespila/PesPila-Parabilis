# All possible countries are selected from the database. Copyright by Michael Bauer.
#
# Functions available:
# 	- GetLeagues(country)

GetLeagues <- function(country = "Germany") {
	# Get leagues in a given country.
	#
	#	country: A selected country (string).
	#
	#	Return: Returns a vector with all possible countries to select.

	InitDB()
  
	query <- paste0("select Div1, Div2, Div3, Div4, Div5 from cData where Country = '", country, "'")
	data <- dbGetQuery(conn = ppConn, statement = query)

	dbDisconnect(conn = ppConn)

	return (as.character(data[1, ]))

}  # END GetLeagues