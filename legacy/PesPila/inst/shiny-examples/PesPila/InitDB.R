# Establish a database connection. Copyright by Michael Bauer.
#
# Functions available:
# 	- InitDB()

InitDB <- function() {
	# Main function to start the app.
	#
	#	sqlitePath: String, where the SQLite DB is stored
	#
	#	Return: No return value. Assigning DB connection to global environment.

	assign(x = "ppConn",
				 dbConnect(SQLite(), "data/PesPilaDB.db"),
				 envir = .GlobalEnv)

}  # END InitDB