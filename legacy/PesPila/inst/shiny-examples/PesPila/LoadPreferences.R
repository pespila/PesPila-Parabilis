# Initialize the UI. Copyright by Michael Bauer.
#
# Functions available:
# 	- LoadPreferences()

LoadPreferences <- function() {
	# Main function to initialize the UI at first.
	#
	#	Return: No return value.

	InitDB()

	query <- "select name from sqlite_master where type='table'"
	data <- dbGetQuery(conn = ppConn, statement =  query)

	dbDisconnect(conn = etestconn)

	return (data)

}  # END InitDB