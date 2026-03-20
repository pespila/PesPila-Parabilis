# All possible countries are selected from the database. Copyright by Michael Bauer.
#
# Functions available:
# 	- GetCountry()

GetCountry <- function() {
	# Get countries possible in this app.
	#
	#	Return: Returns a vector with all possible countries to select.

	InitDB()

	query <- "select distinct Country from cData"
	data <- dbGetQuery(conn = ppConn, statement = query)

	dbDisconnect(conn = ppConn)

	return (as.character(data[, "Country"]))

}  # END GetCountry