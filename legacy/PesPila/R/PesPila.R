# Main file to execute the PesPila app. Copyright by Michael Bauer.
#
# Functions available:
# 	- PesPila(browser, port, ip)

PesPila <- function(browser = FALSE, port = 9090, ip = "127.0.0.1") {
	# Main function to start the app.
	#
	#	browser: Boolean, FALSE by default.
	#	port: Integer, the port number.
	#	ip: String, IP address.
	#
	#	Return: No return value.

	# appDir <- system.file("shiny-examples/PesPila/", package = "PesPila")
	appDir <- system.file("shiny-examples", "PesPila", package = "PesPila")

	if (appDir == "") {  # IF

	    stop("Could not find example directory. Try re-installing `PesPila`.", call. = FALSE)

	}  # END IF

	shiny::runApp(appDir = appDir, port = port, host = getOption("shiny.host", ip), launch.browser = browser)

}  # END PesPila