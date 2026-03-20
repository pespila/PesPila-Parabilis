# Conditioned table for the league data site. Copyright by Michael Bauer.
#
# Functions available:
# 	- GetLeagueTable(country, league, season)

TestPredict <- function(country, season, fHome, fAway, homeTable, awayTable, table) {
  hParm <- ""
  aParm <- ""
  hProb <- rep(x = 0, times = 6)
  aProb <- rep(x = 0, times = 6)
  goals <- 0:5
  ngoal <- length(goals)
  mat <- data.frame(matrix(data = 0, nrow = ngoal, ncol = ngoal))
  colnames(mat) <- 0:5
  rownames(mat) <- 0:5
  hWin <- 0
  aWin <- 0
  draw <- 0
  tMax <- 0
  tInd <- c()

  InitDB()
  
  home <- paste0("select A.Dist from ", homeTable, " A, Seasons B, Teams C, Countries D where B.Season = '", season, "' and A.Season_ID = B.Season_ID and C.Team = '", fHome, "' and A.Team_ID = C.Team_ID and D.Country = '", country, "' and A.Country_ID = D.Country_ID")
  home <- as.character(dbGetQuery(conn = ppConn, statement = home)[1, "Dist"])
  hStr <- strsplit(home, split = "_")[[1]]

  if (hStr[1] == "Poisson") {
    hParm <- paste0(hStr[1], "_Lambda")
  } else if (hStr[1] == "ZIP") {
    hParm <- paste0(hStr[1], c("_Phi", "_Lambda"))
  } else if (hStr[1] == "Uniform") {
    hParm <- paste0(hStr[1], c("_A", "_B"))
  } else if (hStr[1] == "Geometric") {
    hParm <- paste0(hStr[1], "_P")
  } else if (hStr[1] == "NBD") {
    hParm <- paste0(hStr[1], c("_K", "_P"))
  }

  query <- paste0("select ", paste0("A.", home), ", ", paste("A.", hParm, collapse = ","), " from ", homeTable, " A, Seasons B, Teams C, Countries D where B.Season = '", season, "' and A.Season_ID = B.Season_ID and C.Team = '", fHome, "' and A.Team_ID = C.Team_ID and D.Country = '", country, "' and A.Country_ID = D.Country_ID")
  home <- dbGetQuery(conn = ppConn, statement = query)[1, ]
  
  away <- paste0("select A.Dist from ", awayTable, " A, Seasons B, Teams C, Countries D where B.Season = '", season, "' and A.Season_ID = B.Season_ID and C.Team = '", fAway, "' and A.Team_ID = C.Team_ID and D.Country = '", country, "' and A.Country_ID = D.Country_ID")
  away <- as.character(dbGetQuery(conn = ppConn, statement = away)[1, "Dist"])
  aStr <- strsplit(away, split = "_")[[1]]
  
  if (aStr[1] == "Poisson") {
    aParm <- paste0(aStr[1], "_Lambda")
  } else if (aStr[1] == "ZIP") {
    aParm <- paste0(aStr[1], c("_Phi", "_Lambda"))
  } else if (aStr[1] == "Uniform") {
    aParm <- paste0(aStr[1], c("_A", "_B"))
  } else if (aStr[1] == "Geometric") {
    aParm <- paste0(aStr[1], "_P")
  } else if (aStr[1] == "NBD") {
    aParm <- paste0(aStr[1], c("_K", "_P"))
  }

  query <- paste0("select ", paste0("A.", away), ", ", paste("A.", aParm, collapse = ","), " from ", awayTable, " A, Seasons B, Teams C, Countries D where B.Season = '", season, "' and A.Season_ID = B.Season_ID and C.Team = '", fAway, "' and A.Team_ID = C.Team_ID and D.Country = '", country, "' and A.Country_ID = D.Country_ID")
  away <- dbGetQuery(conn = ppConn, statement = query)[1, ]

  dbDisconnect(conn = ppConn)

  if (hStr[1] == "Poisson") {
    hProb <- dpois(x = goals, lambda = home[1, "Poisson_Lambda"])
  } else if (hStr[1] == "ZIP") {
    hProb <- dzipois(x = goals, lambda = home[1, "ZIP_Lambda"], phi = home[1, "ZIP_Phi"])
  } else if (hStr[1] == "Uniform") {
    hProb[which(goals <= home[1, "Uniform_B"])] <- 1/(home[1, "Uniform_B"] - home[1, "Uniform_A"] + 1)
  } else if (hStr[1] == "Geometric") {
    hProb <- dgeom(x = goals, prob = home[1, "Geometric_P"])
  } else if (hStr[1] == "NBD") {
    hProb <- dnbinom(x = goals, mu = home[1, "NBD_K"], size = home[1, "NBD_P"])
  }

  if (aStr[1] == "Poisson") {
    aProb <- dpois(x = goals, lambda = away[1, "Poisson_Lambda"])
  } else if (aStr[1] == "ZIP") {
    aProb <- dzipois(x = goals, lambda = away[1, "ZIP_Lambda"], phi = away[1, "ZIP_Phi"])
  } else if (aStr[1] == "Uniform") {
    aProb[which(goals <= away[1, "Uniform_B"])] <- 1/(away[1, "Uniform_B"] - away[1, "Uniform_A"] + 1)
  } else if (aStr[1] == "Geometric") {
    aProb <- dgeom(x = goals, prob = away[1, "Geometric_P"])
  } else if (aStr[1] == "NBD") {
    aProb <- dnbinom(x = goals, mu = away[1, "NBD_K"], size = away[1, "NBD_P"])
  }

  # xHome <- which(hProb == max(hProb)) - 1
  # xAway <- which(aProb == max(aProb)) - 1
  # tInd <- c(xHome, xAway)

  for (i in 1:ngoal) {
    for (j in 1:ngoal) {
      mat[i, j] <- hProb[i] * aProb[j]
      if (i == j) {
        draw <- draw + mat[i, j] * 100
      } else if (j > i) {
        aWin <- aWin + mat[i, j] * 100
      } else {
        hWin <- hWin + mat[i, j] * 100
      }
    }
  }

  win <- "H"
  if (aWin > hWin && aWin > draw) {
  	win <- "A"
  }
  if (draw > aWin && draw > hWin) {
  	win <- "D"
  }

  for (i in 1:ngoal) {
    for (j in 1:ngoal) {
      if (mat[i, j] >= tMax) {
      	tInd <- c(i-1, j-1)
      	if (hWin > 40) {
      		tInd[1] <- tInd[1] + 1
      	}
      	if (aWin > 40) {
      		tInd[2] <- tInd[2] + 1
      	}
      	tMax <- mat[i, j]
      }
    }
  }

  # if (draw > 25 && hWin > 40) {
  # if (draw > 20 && hWin > 30) {
  #   for (i in 1:ngoal) {
  #     for (j in 1:i) {
  #       if (mat[i, j] >= tMax) {
  #         # tInd <- c(i, j)
  #         tInd <- c(i-1, j-1)
  #         tMax <- mat[i, j]
  #       }
  #     }
  #   }
  # # } else if (draw > 25 && aWin > 40) {
  # } else if (draw > 20 && aWin > 30) {
  # 	win <- "A"
  #   for (i in 1:ngoal) {
  #     for (j in i:ngoal) {
  #       if (mat[i, j] >= tMax) {
  #         # tInd <- c(i, j)
  #         tInd <- c(i-1, j-1)
  #         tMax <- mat[i, j]
  #       }
  #     }
  #   }
  # } else if (hWin > 35 && draw <= 20) {
  # if (hWin > 40) {
  #   for (i in 2:ngoal) {
  #     for (j in 1:(i-1)) {
  #       if (mat[i, j] >= tMax) {
  #         tInd <- c(i-1, j-1)
  #         tMax <- mat[i, j]
  #       }
  #     }
  #   }
  # }

  # if (aWin > 40) {
  # 	win <- "A"
  #   for (i in 2:ngoal) {
  #     for (j in (i-1):ngoal) {
  #       if (mat[i, j] >= tMax) {
  #         tInd <- c(i-1, j-1)
  #         tMax <- mat[i, j]
  #       }
  #     }
  #   }
  # }

  # if (draw > 40) {
  # 	win <- "D"
  #   for (i in 1:ngoal) {
  #     if (mat[i, i] >= tMax) {
  #       tInd <- c(i-1, i-1)
  #       tMax <- mat[i, i]
  #     }
  #   }
  # }

  # if (hWin <= 40 && draw <= 40 && aWin <= 40) {
  #   if (hWin >= aWin && hWin >= draw) {
  #     for (i in 1:ngoal) {
  #       for (j in 1:(i-1)) {
  #         if (mat[i, j] >= tMax) {
  #           tInd <- c(i-1, j-1)
  #           tMax <- mat[i, j]
  #         }
  #       }
  #     }
  #   }
  #   if (aWin >= hWin && aWin >= draw) {
  #   	win <- "A"
  #     for (i in 1:ngoal) {
  #       for (j in (i-1):ngoal) {
  #         if (mat[i, j] >= tMax) {
  #           tInd <- c(i-1, j-1)
  #           tMax <- mat[i, j]
  #         }
  #       }
  #     }
  #   }
  #   if (draw >= hWin && draw >= aWin) {
  #   	win <- "D"
  #     for (i in 1:ngoal) {
  #       if (mat[i, i] >= tMax) {
  #         tInd <- c(i-1, i-1)
  #         tMax <- mat[i, i]
  #       }
  #     }
  #   }
  # }

  homeOdd <- if ((100/hWin) - 1 < 1) {1.0} else {(100/hWin) - 1}
  drawOdd <- if ((100/draw) - 1 < 1) {1.0} else {(100/draw) - 1}
  awayOdd <- if ((100/aWin) - 1 < 1) {1.0} else {(100/aWin) - 1}

  out <- data.frame("hWin" = hWin, "draw" = draw, "aWin" = aWin, "homeOdd" = homeOdd, "drawOdd" = drawOdd,
                    "awayOdd" = awayOdd, "FTHG" = tInd[1], "FTAG" = tInd[2], "WIN" = win)#, "SWIN" = sWin)#, "WIN" = win, "sWIN" = sWin)

  # rownames(mat) <- 0:5
  # output[[table]] <- DT::renderDataTable({datatable(round(mat, 4), rownames = TRUE, escape = FALSE)})
  print(out)
  return (out)
}

GetLeagueTable <- function(country = "Germany", league = "1. Bundesliga", season = "15/16") {
	# Get the conditioned data from the database.
	#
	#	country: A selected country (string).
	#	league: The selected league (string).
	#	season: The selected season (string).
	#
	#	Return: Returns a data.frame() with the corresponding league data.
  
	InitDB()
	
	query <- paste0("select * from ", country, " where Div = '", league, "' and Season = '", season, "'")
	
	if (league == "All" && season != "All") {query <- paste0("select * from ", country, " where Season = '", season, "'")}
	if (season == "All" && league != "All") {query <- paste0("select * from ", country, " where Div = '", league, "'")}
	if (league == "All" && season == "All") {query <- paste0("select * from ", country)}
	
	data <- dbGetQuery(conn = ppConn, statement = query)
	
	dbDisconnect(conn = ppConn)

	fFTHG <- rep(x = 0, times = nrow(data))
	fFTAG <- rep(x = 0, times = nrow(data))
	fFTR <- rep(x = 0, times = nrow(data))
	fG <- rep(x = 0, times = nrow(data))
	fR <- rep(x = 0, times = nrow(data))
	win <- rep(x = 0, times = nrow(data))
	# SCwin <- rep(x = "NULL", times = nrow(data))
	# COwin <- rep(x = "NULL", times = nrow(data))
	s <- c(data[, "FTHG"], data[, "FTAG"])
	s <- sum(s)
	# h <- sum(data[, "FTHG"])/nrow(data)
	# a <- sum(data[, "FTAG"])/nrow(data)
	h <- sum(data[, "FTHG"])/s
	a <- sum(data[, "FTAG"])/s

	# print(c("mean", mean(s), "sd" = sd(s)))
	# print(c("mean", mean(data[, "FTHG"]), "sd" = sd(data[, "FTHG"])))
	# print(c("mean", mean(data[, "FTAG"]), "sd" = sd(data[, "FTAG"])))
	# s <- mean(s)



	for (i in 1:nrow(data)) {

		test <- GetHomeVsAway(country = country, home = data[i, "HomeTeam"], away = data[i, "AwayTeam"])
	  SvS <- TestPredict(country = country, season = season, fHome = data[i, "HomeTeam"], fAway = data[i, "AwayTeam"], homeTable = "Scored", awayTable = "Scored", table = "SvS")
	  CvC <- TestPredict(country = country, season = season, fHome = data[i, "HomeTeam"], fAway = data[i, "AwayTeam"], homeTable = "Conceded", awayTable = "Conceded", table = "CvC")

	  s <- as.numeric(test[1, "FTHG"]) + as.numeric(test[1, "FTAG"])
	  if (s == 0) {s <- 1}
	  # H <- (SvS[1, "FTHG"] + CvC[1, "FTHG"]) * (as.numeric(test[1, "FTHG"]) / s)
	  # A <- (SvS[1, "FTAG"] + CvC[1, "FTAG"]) * (as.numeric(test[1, "FTAG"]) / s)
	  H <- (SvS[1, "FTHG"] + CvC[1, "FTAG"]) * as.numeric(test[1, "FTHG"])/3# - 3*sd(data[, "FTHG"])# + h)# * (as.numeric(test[1, "FTHG"]) / s)
	  A <- (SvS[1, "FTAG"] + CvC[1, "FTHG"]) * as.numeric(test[1, "FTAG"])/3# - 3*sd(data[, "FTAG"])# + a)# * (as.numeric(test[1, "FTAG"]) / s)
	  # H <- (SvS[1, "FTHG"] + CvC[1, "FTAG"] + as.numeric(test[1, "FTHG"]) - mean(data[, "FTHG"]) + h)# * (as.numeric(test[1, "FTHG"]) / s)
	  # A <- (SvS[1, "FTAG"] + CvC[1, "FTHG"] + as.numeric(test[1, "FTAG"]) - mean(data[, "FTAG"]) + a)# * (as.numeric(test[1, "FTAG"]) / s)
	  # H <- (SvS[1, "FTHG"] + CvC[1, "FTHG"]) * (sum(data[, "FTHG"])/sum(s))
	  # A <- (SvS[1, "FTAG"] + CvC[1, "FTAG"]) * (sum(data[, "FTAG"])/sum(s))
	  # H <- (SvS[1, "FTHG"] + CvC[1, "FTHG"] * as.numeric(test[2, "FTHG"])) / 3
	  # A <- (SvS[1, "FTAG"] + CvC[1, "FTAG"] * as.numeric(test[2, "FTAG"])) / 3
	  # H <- (SvS[1, "FTHG"] + CvC[1, "FTHG"] + as.numeric(test[1, "FTHG"])) / 3
	  # A <- (SvS[1, "FTAG"] + CvC[1, "FTAG"] + as.numeric(test[1, "FTAG"])) / 3
	  
	  H <- round(H, 0)
	  A <- round(A, 0)
	  fFTHG[i] <- H
	  fFTAG[i] <- A
	  # fFTHG[i] <- round(H, 0)
	  # fFTAG[i] <- round(A, 0)

	  if (H > A) {
	  	fFTR[i] <- "H"
	  }
	  if (H == A) {
	  	fFTR[i] <- "D"
	  }
	  if (A > H) {
	  	fFTR[i] <- "A"
	  }

	  if (H == data[i, "FTHG"] && A == data[i, "FTAG"]) {
	  	fG[i] <- TRUE
	  } else {
	  	fG[i] <- FALSE
	  }


	  if (fFTR[i] == data[i, "FTR"]) {
	  	fR[i] <- TRUE
	  } else {
	  	fR[i] <- FALSE
	  }

	  if (SvS[1, "WIN"] == data[i, "FTR"]) {
	  	win[i] <- TRUE
	  } else {
	  	win[i] <- FALSE
	  }

	  fG[i] <- SvS[1, "hWin"]
	  fR[i] <- SvS[1, "draw"]
	  win[i] <- SvS[1, "aWin"]
	}

	data <- cbind(data[, c("HomeTeam", "AwayTeam", "FTHG", "FTAG", "FTR")], "Home" = fG, "Draw" = fR, "Away" = win)#, "SCwin" = SCwin, "COwin" = COwin)#, "WIN" = win, "sWIN" = sWin)
	# data <- cbind(data[, c("HomeTeam", "AwayTeam", "FTHG", "FTAG")], "fFTHG" = fFTHG, "fFTAG" = fFTAG, "FTR" = data[, "FTR"], "fFTR" = fFTR, "fG" = fG, "fR" = fR, "WIN" = win)#, "SCwin" = SCwin, "COwin" = COwin)#, "WIN" = win, "sWIN" = sWin)

	# data <- rbind(data[1, ], data)
	# a <- as.character(length(which(data[2:nrow(data), "fG"] == TRUE)))
	# a1 <- as.character(length(which((data$fFTR == "A" & data$FTR == "D") | (data$fFTR == "D" & data$FTR == "A"))))
	# a2 <- as.character(length(which((data$fFTR == "H" & data$FTR == "D") | (data$fFTR == "D" & data$FTR == "H"))))
	# a3 <- as.character(length(which((data$fFTR == "A" & data$FTR == "H") | (data$fFTR == "H" & data$FTR == "A"))))
	# b <- as.character(length(which(data[2:nrow(data), "fR"] == TRUE)))
	# c <- as.character(length(which(data[2:nrow(data), "WIN"] == TRUE)))

	# print(c(a1, a2, a3))

	# data[1, "FTR"] <- a1
	# data[1, "fFTR"] <- a2
	# data[1, "fG"] <- a
	# data[1, "fR"] <- b
	# data[1, "WIN"] <- c

	return (data)

}  # END GetLeagueTable