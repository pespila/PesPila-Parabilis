GetSeasons <- function() {
    return (c("9394", "9495", "9596", "9697",
                 "9798", "9899", "9900", "0001",
                 "0102", "0203", "0304", "0405",
                 "0506", "0607", "0708", "0809",
                 "0910", "1011", "1112", "1213",
                 "1314", "1415"))
}

GetCountries <- function() {
    return (c("Belgium", "England", "France", "Germany",
                 "Greece", "Italy", "Netherlands", "Portugal",
                 "Scotland", "Spain", "Turkey"))
}

GetMultipleCountrySet <- function() {
    return (c("Belgium", "Germany", "Germany", "England",
                 "England", "England", "England", "England",
                 "France", "France", "Greece", "Italy", "Italy",
                 "Netherlands", "Portugal", "Scotland", "Scotland",
                 "Scotland", "Scotland", "Spain", "Spain", "Turkey"))
}

GetFilenames <- function() {
    return (c("B1.csv", "D1.csv", "D2.csv", "E0.csv",
                "E1.csv", "E2.csv", "E3.csv", "EC.csv",
                "F1.csv", "F2.csv", "G1.csv", "I1.csv",
                "I2.csv", "N1.csv", "P1.csv", "SC0.csv",
                "SC1.csv", "SC2.csv", "SC3.csv", "SP1.csv",
                "SP2.csv", "T1.csv"))
}

GetLeagues <- function() {
    return (c("JupilerLeague.csv", "Bundesliga1.csv", "Bundesliga2.csv",
                "PremierLeague.csv", "Championship.csv",
                "League1.csv", "League2.csv", "Conference.csv",
                "LeChampionnat.csv", "Division2.csv", "EthnikiKatigoria.csv",
                "SerieA.csv", "SerieB.csv", "Eredivisie.csv", "Liga1.csv",
                "PremierLeague.csv", "Division1.csv", "Division2.csv",
                "Division3.csv", "LaLigaPrimeraDivision.csv",
                "LaLigaSegundaDivision.csv", "FutbolLigi1.csv"))
}

GetCountryFilenameHashTable <- function() {
    return (hash(keys = GetFilenames(), values = GetMultipleCountrySet()))
}

GetLeaguesFilenameHashTable <- function() {
    return (hash(keys = GetFilenames(), values = GetLeagues()))
}

GetFilenamesLeaugesHashTable <- function() {
    return (hash(keys = strsplit(x = GetLeagues(), split = ".csv"), values = GetFilenames()))
}

CreateTempDir <- function(path = "Data") {
    temp.dir <- paste(path, "Temp", sep = "/")
    dir.create(temp.dir)
    return (temp.dir)
}

DownloadFiles <- function(path = "Data", seasons = "",
                        url = "http://www.football-data.co.uk/mmz4281",
                        filename = "data.zip") {
    for (season in seasons) {
        download.file(paste(url, season, filename, sep = "/"),
                      destfile = paste(path, "/", season, ".zip", sep = ""))
    }
}

CreateDirectories <- function(path = "Data", seasons = "", warnings = FALSE) {
    for (season in seasons) {
        dir.create(paste(path, season, sep = "/"), showWarnings = warnings)
    }
}

Unzip2Dir <- function(path = "Data", seasons = "") {
    for (season in seasons) {
        unzip(zipfile = paste(path, "/", season, ".zip", sep = ""),
            exdir = paste(path, season, sep = "/"))
    }
}

# CopyData <- function(path = "Data", temp.dir = "Data/Temp", seasons = "") {
#     for (season in seasons) {
#         files <- list.files(paste(temp.dir, season, sep = "/"))
#         for (file in files) {
#             dataset <- read.csv(paste(temp.dir, season, file, sep = "/"))
#             dataset.rows <- nrow(dataset)
#             new.dataset <- data.frame(matrix(data = 0, nrow = dataset.rows, ncol = dataset.cols))
#             colnames(new.dataset) <- column.names
#             for (name in column.names) {
#                 if (name %in% colnames(dataset)) {
#                     new.dataset[, name] <- dataset[, name]
#                 } else {
#                     new.dataset[, name] <- 0
#                 }
#             }
#             new.dataset <- subset(new.dataset, Div != "")
#             write.csv(new.dataset, paste(temp.dir, season, file, sep = "/"), row.names = FALSE)
#         }
#     }
# }

DeleteTempDirectory <- function(path = "Data") {
    unlink(x = paste(path), recursive = TRUE)
}

ExtractData <- function(path = "Data", temp.dir = "Data/Temp",
                        statistics = "Statistics.csv") {
    seasons <- GetSeasons()
    column.names <- scan(file = paste(path, statistics, sep = "/"), what = "character")
    dataset.cols <- length(column.names)
    
    for (season in seasons) {
        files <- list.files(paste(temp.dir, season, sep = "/"))
        for (file in files) {
            dataset <- read.csv(paste(temp.dir, season, file, sep = "/"))
            dataset.rows <- nrow(dataset)
            new.dataset <- data.frame(matrix(data = 0, nrow = dataset.rows, ncol = dataset.cols))
            colnames(new.dataset) <- column.names
            for (name in column.names) {
                if (name %in% colnames(dataset)) {
                    new.dataset[, name] <- dataset[, name]
                } else {
                    new.dataset[, name] <- 0
                }
            }
            new.dataset <- subset(new.dataset, Div != "")
            write.csv(new.dataset, paste(temp.dir, season, file, sep = "/"), row.names = FALSE)
        }
    }
}

SetData <- function(path = "Data", temp.dir = "Data/Temp", statistics = "Statistics.csv") {
    folders <- GetSeasons()
    files <- GetFilenames()
    hash.table <- GetCountryFilenameHashTable()

    column.names <- scan(file = paste(path, statistics, sep = "/"), what = "character")
    length.column.names <- length(column.names)

    for (file in files) {
        dataset <- data.frame(matrix(data = 0, nrow = 0, ncol = length.column.names))
        colnames(dataset) <- column.names
        for (folder in folders) {
            tmp.files <- list.files(paste(temp.dir, folder, sep = "/"))
            if (file %in% tmp.files) {
                tmp <- read.csv(paste(temp.dir, folder, file, sep = "/"))
                dataset <- rbind(dataset, tmp)
            }
        }
        write.csv(dataset, paste(path, hash.table[[file]], file, sep = "/"), row.names = FALSE)
    }
}

RenameFiles <- function(path = "Data") {
    folders <- GetCountries()
    to.new.filename <- GetLeaguesFilenameHashTable()
    for (folder in folders) {
        tmp.files <- list.files(paste(path, folder, sep = "/"))
        for (tmp in tmp.files) {
            file.rename(from = paste(path, folder, tmp, sep = "/"), to = paste(path, folder, to.new.filename[[paste(tmp)]], sep = "/"))
        }
    }
}

ExtractAllTeams <- function(filename, path = "Data", country = "") {
    dataset <- read.csv(file = paste(path, country, filename, sep = "/"))
    teams <- as.character(dataset[, "AwayTeam"])
    teams <- c(teams, as.character(dataset[, "AwayTeam"]))
    teams <- unique(teams)
    return (teams)
}

Initialize <- function(path = "Data") {
    country <- GetCountries()
    for (c in country) {
        dir.create(paste(path, c, sep = "/"))
    }
    seasons <- GetSeasons()
    temp.dir <- CreateTempDir(path)
    DownloadFiles(temp.dir, seasons)
    CreateDirectories(temp.dir, seasons)
    Unzip2Dir(temp.dir, seasons)
    ExtractData(path, temp.dir)
    SetData(path, temp.dir)
    CopyData(path, temp.dir)
    DeleteTempDirectory(temp.dir)
    RenameFiles(path)
    for (c in country) {
        files <- list.files(path = paste(path, c, sep = "/"), pattern = ".csv")
        dataset <- data.frame(matrix(0, nrow = 0, ncol = 27))
        for (file in files) {
            teams <- ExtractAllTeams(file, path, c)
            for (team in teams) {
                dir.create(paste(path, c, team, sep = "/"))
            }
            tmp <- read.csv(file = paste(path, c, file, sep = "/"))
            dataset <- rbind(dataset, tmp)
        }
        write.csv(dataset, paste(path, c, "Synopsis.csv", sep = "/"), row.names = FALSE)
    }
}
# ---------------------------------------------------------------------------------------------------------------------------------------
FolderStructure <- function(path = "Data", pattern = NULL, all.dirs = FALSE, full.names = FALSE, ignore.case = FALSE) {
    all <- list.files(path, pattern, all.dirs, full.names = TRUE, recursive = FALSE, ignore.case)
    dirs <- all[file.info(all)$isdir]
    if(isTRUE(full.names)) {
        return(dirs)
    }
    else {
        return(basename(dirs))
    }
}

ReadPreferences <- function(path = "Data", filename = "Preferences.csv") {
    preferences <- read.csv(file = paste(path, filename, sep = "/"))
    if (nrow(preferences) != 0) {
        preferences <- as.character(preferences[, 1])
    } else {
        preferences <- c()
    }
    return (preferences)
}

SetPreferences <- function(country, division, team, path = "Data", filename = "Preferences.csv") {
    Preferences <- c(country, division, team)
    write.preferences <- data.frame(Preferences)
    write.csv(write.preferences, paste(path, filename, sep = "/"), row.names = FALSE)
}
# ---------------------------------------------------------------------------------------------------------------------------------------
LoadCountryData <- function(path = "Data", country = "Germany", filename = "Bundesliga1.csv") {
    return (read.csv(file = paste(path, country, filename, sep = "/")))
}

Wins <- function(path = "Data", country = "Germany") {
    divisions <- list.files(path = paste(path, country, sep = "/"), pattern = ".csv")
    length.divisions <- length(divisions)
    row.names <- c()
    column.names <- c("Division", "HWin", "Draw", "AWin", "FTHG", "FTAG", "HTHG", "HTAG")
    cum.data <- data.frame(matrix(0, length.divisions, 8))
    for (i in 1:length.divisions) {
        dataset <- LoadCountryData(path, country, divisions[i])
        sum <- c(0, 0, 0, 0, sum(dataset[, "FTHG"]), sum(dataset[, "FTAG"]), sum(dataset[, "HTHG"]), sum(dataset[, "HTAG"]))
        for (value in as.vector(dataset[, "FTR"])) {
            if (value == "H") {
                sum[2] <- sum[2] + 1
            } else if (value == "D") {
                sum[3] <- sum[3] + 1
            } else {
                sum[4] <- sum[4] + 1
            }
        }
        row.names <- c(row.names, strsplit(x = divisions[i], split = ".csv")[[1]])
        cum.data[i, ] <- sum
    }
    rownames(cum.data) <- row.names
    colnames(cum.data) <- column.names
    cum.data[, 1] <- row.names
    return (cum.data)
}

GoalDifferences <- function(path = "Data", country = "Germany") {
    divisions <- list.files(path = paste(path, country, sep = "/"), pattern = ".csv")
    length.divisions <- length(divisions)
    row.names <- c()
    column.names <- c("League", 0:9)
    cum.data <- data.frame(matrix(0, length.divisions, 11))
    for (i in 1:length.divisions) {
        dataset <- LoadCountryData(path, country, divisions[i])
        home <- dataset[, "FTHG"]
        away <- dataset[, "FTAG"]
        for (j in 1:length(home)) {
            difference <- abs(home[j] - away[j])
            cum.data[i, difference + 2] <- cum.data[i, difference + 2] + 1
        }
        row.names <- c(row.names, strsplit(x = divisions[i], split = ".csv")[[1]])
    }
    rownames(cum.data) <- row.names
    colnames(cum.data) <- column.names
    cum.data[, 1] <- row.names
    return (cum.data)
}

GSPM <- function(path = "Data", country = "Germany") {
    divisions <- list.files(path = paste(path, country, sep = "/"), pattern = ".csv")
    length.divisions <- length(divisions)
    row.names <- c()
    column.names <- c("League", 0:13)
    cum.data <- data.frame(matrix(0, length.divisions, 15))
    for (i in 1:length.divisions) {
        # filename <- paste(divisions[i], ".csv", sep = "")
        dataset <- LoadCountryData(path, country, divisions[i])
        home <- dataset[, "FTHG"]
        away <- dataset[, "FTAG"]
        for (j in 1:length(home)) {
            gspm <- home[j] + away[j]
            if (gspm > 13) {
                next
            }
            cum.data[i, gspm + 2] <- cum.data[i, gspm + 2] + 1
        }
        row.names <- c(row.names, strsplit(x = divisions[i], split = ".csv")[[1]])
    }
    rownames(cum.data) <- row.names
    colnames(cum.data) <- column.names
    cum.data[, 1] <- row.names
    return (cum.data)
}

GSPS <- function(path = "Data", folder = "Seasons", division = "Bundesliga1") {
    row.names <- GetSeasons()
    col.names <- c("Season / Summary", "Home Goals", "Away Goals", "All Goals", "Goals per game")
    len.col.names <- length(col.names)
    len.row.names <- length(row.names)
    data <- data.frame(matrix(ncol = len.col.names, nrow = len.row.names, 0))
    colnames(data) <- col.names
    rownames(data) <- row.names
    # data[, 1] <- row.names
    look.up <- paste(path, folder, sep = "/")
    # print(GetFilenamesLeaugesHashTable()[division])
    for (row in row.names) {
        dataset <- read.csv(file = paste(look.up, row, GetFilenamesLeaugesHashTable()[[division]], sep = "/"))
        print(dataset)
        # print(paste(look.up, row, GetFilenamesLeaugesHashTable()[[division]], sep = "/"))
    }
    return (data)
    # divisions <- list.files(path = paste(path, country, sep = "/"), pattern = ".csv")
    # length.divisions <- length(divisions)
    # row.names <- c()
    # column.names <- c("League", 0:13)
    # cum.data <- data.frame(matrix(0, length.divisions, 15))
    # for (i in 1:length.divisions) {
    #     # filename <- paste(divisions[i], ".csv", sep = "")
    #     dataset <- LoadCountryData(path, country, divisions[i])
    #     home <- dataset[, "FTHG"]
    #     away <- dataset[, "FTAG"]
    #     for (j in 1:length(home)) {
    #         gspm <- home[j] + away[j]
    #         if (gspm > 13) {
    #             next
    #         }
    #         cum.data[i, gspm + 2] <- cum.data[i, gspm + 2] + 1
    #     }
    #     row.names <- c(row.names, strsplit(x = divisions[i], split = ".csv")[[1]])
    # }
    # rownames(cum.data) <- row.names
    # colnames(cum.data) <- column.names
    # cum.data[, 1] <- row.names
    # return (cum.data)
}

ResultsComparison <- function(path = "Data", country = "Germany", division = "Bundesliga1") {
    dataset <- LoadCountryData(path, country, paste(division, ".csv", sep = ""))
    column.names <- c("H\\A", 0:11)
    row.names <- 0:11
    cum.data <- data.frame(matrix(0, 12, 13))
    home <- dataset[, "FTHG"]
    away <- dataset[, "FTAG"]
    for (i in 1:length(home)) {
        cum.data[home[i] + 1, away[i] + 2] <- cum.data[home[i] + 1, away[i] + 2] + 1
    }
    # cum.data <- cbind(data.frame(0:11), cum.data)
    rownames(cum.data) <- row.names
    colnames(cum.data) <- column.names
    cum.data[, 1] <- row.names
    return (cum.data)
}

OneTeamsData <- function(team, kind = "B", path = "Data", country = "Germany", filename = "Synopsis.csv") {
    dataset <- read.csv(file = paste(path, country, filename, sep = "/"))
    home <- subset(dataset, HomeTeam == team)
    away <- subset(dataset, AwayTeam == team)
    if (kind == "B") {
        return (rbind(home, away))
    } else if (kind == "H") {
        return (home)
    } else {
        return (away)
    }
}

MatchesByDivision <- function(team, path = "Data", country = "Germany", division = "Bundesliga1", filename = "Synopsis.csv") {
    dataset <- read.csv(file = paste(path, country, filename, sep = "/"))
    home <- subset(dataset, HomeTeam == team)
    away <- subset(dataset, AwayTeam == team)
    dataset <- rbind(home, away)
    hash.table <- GetFilenamesLeaugesHashTable()
    hash <- strsplit(x = hash.table[[division]], split = ".csv")
    return (subset(dataset, Div == hash))
}

TrendPlot <- function(team, kind = "B", path = "Data", country = "Germany", filename = "Synopsis.csv") {
    if (kind == "B") {
        dataset <- read.csv(file = paste(path, country, filename, sep = "/"))
        dataset <- subset(dataset, HomeTeam == team | AwayTeam == team)
        trend.points <- rep(x = 0, times = nrow(dataset))
        box.points <- rep(x = 0, times = nrow(dataset)+1)
        for (i in 2:(nrow(dataset)+1)) {
            if (dataset[, "HomeTeam"] == team && dataset[i-1, "FTR"] == "H") {
                trend.points[i-1] <- 1
                box.points[i] <- box.points[i-1] + 3
            } else if (dataset[, "AwayTeam"] == team && dataset[i-1, "FTR"] == "A") {
                trend.points[i-1] <- 1
                box.points[i] <- box.points[i-1] + 3
            } else if (dataset[i-1, "FTR"] == "D") {
                trend.points[i-1] <- 0
                box.points[i] <- box.points[i-1] + 1
            } else {
                trend.points[i-1] <- -1
                box.points[i] <- box.points[i-1] + 0
            }
        }
        return (list(1:nrow(dataset), trend.points, as.character(dataset[, "Date"]), box.points))
    } else {
        dataset <- OneTeamsData(team, kind, path, country, filename)
        trend.points <- rep(x = 0, times = nrow(dataset))
        box.points <- rep(x = 0, times = nrow(dataset)+1)
        for (i in 2:(nrow(dataset)+1)) {
            if (dataset[i-1, "FTR"] == kind) {
                trend.points[i-1] <- 1
                box.points[i] <- box.points[i-1] + 3
            } else if (dataset[i-1, "FTR"] == "D") {
                trend.points[i-1] <- 0
                box.points[i] <- box.points[i-1] + 1
            } else {
                trend.points[i-1] <- -1
                box.points[i] <- box.points[i-1] + 0
            }
        }
        return (list(1:nrow(dataset), trend.points, as.character(dataset[, "Date"]), box.points))
    }
}

Trend <- function(home, away) {
    data <- AllGamesComparison(home, away)
    print(data)
    hBox.Trend <- rep(x = 0, times = nrow(data))
    aBox.Trend <- rep(x = 0, times = nrow(data))
    for (i in 1:nrow(dataset)) {
        if (data[, "HomeTeam"] == team && data[i, "FTR"] == "H") {
            hBox.Trend[i] <- hBox.Trend[i] + 3
        } else if (data[, "HomeTeam"] == away && data[i, "FTR"] == "H") {
            aBox.Trend[i] <- aBox.Trend[i] + 3
        } else if (data[, "HomeTeam"] == team && data[i, "FTR"] == "D") {
            hBox.Trend[i] <- hBox.Trend[i] + 1
            aBox.Trend[i] <- hBox.Trend[i] + 1
        }
    }
    return (list(hBox.Trend, aBox.Trend))
}

TeamOverview <- function(team, path = "Data", country = "Germany", filename = "Synopsis.csv") {
    header <- c("\\", "Win", "Draw", "Lost", "FTG", "HTG", "FTG against", "HTG against")
    rows <- c("Home", "Away", "Overall")
    dataset <- read.csv(file = paste(path, country, filename, sep = "/"))
    new.data <- data.frame(matrix(0, 3, 8))
    home <- subset(dataset, HomeTeam == team)
    away <- subset(dataset, AwayTeam == team)
    new.data[1, 2] <- nrow(subset(home, FTR == "H"))
    new.data[1, 3] <- nrow(subset(home, FTR == "D"))
    new.data[1, 4] <- nrow(subset(home, FTR == "A"))
    new.data[2, 2] <- nrow(subset(away, FTR == "A"))
    new.data[2, 3] <- nrow(subset(away, FTR == "D"))
    new.data[2, 4] <- nrow(subset(away, FTR == "H"))
    new.data[1, 5] <- sum(home[, "FTHG"])
    new.data[1, 6] <- sum(home[, "HTHG"])
    new.data[1, 7] <- sum(home[, "FTAG"])
    new.data[1, 8] <- sum(home[, "HTAG"])
    new.data[2, 5] <- sum(away[, "FTAG"])
    new.data[2, 6] <- sum(away[, "HTAG"])
    new.data[2, 7] <- sum(away[, "FTHG"])
    new.data[2, 8] <- sum(away[, "HTHG"])
    for (i in 2:ncol(new.data)) {
        new.data[3, i] <- new.data[1, i] + new.data[2, i]
    }
    rownames(new.data) <- rows
    new.data[, 1] <- rows
    colnames(new.data) <- header
    return (new.data)
}

LastMatches <- function(team, no = 2, path = "Data", country = "Germany", filename = "Synopsis.csv") {
    dataset <- read.csv(file = paste(path, country, filename, sep = "/"))
    new.data <- data.frame(matrix(0, no, ncol(dataset)))
    colnames(new.data) <- colnames(dataset)
    count <- 1
    for (i in nrow(dataset):1) {
        if (dataset[i, "HomeTeam"] == team || dataset[i, "AwayTeam"] == team) {
            for (j in 1:ncol(dataset)) {
                new.data[count, j] <- as.character(dataset[i, j])
            }
            # new.data[count, ] <- as.character(dataset[i, ])
            count <- count + 1
        }
        if (count > no) {
            break
        }
    }
    # home <- subset(dataset, HomeTeam == team)
    # away <- subset(dataset, AwayTeam == team)
    # dataset <- rbind(home, away)
    # return (dataset[(nrow(dataset) - no + 1):nrow(dataset),])
    return (new.data)
}

AllGamesComparison <- function(home = "", away = "") {
    data <- loadAllContent()
    compareTable <- data[which(data$HomeTeam == home
                               & data$AwayTeam == away), ]
    compareTable <- rbind(compareTable, data[which(data$HomeTeam == away
                               & data$AwayTeam == home), ])
    return (compareTable)
}

TeamComparison <- function(home = "", away = "") {
    data <- loadAllContent()
    compareTable <- data[which(data$HomeTeam == home
                               & data$AwayTeam == away), ]
    return (compareTable)
}

SumUpComparison <- function(home = "", away = "") {
    specData <- teamComparison(home, away)
    # column.names <- colnames(specData)
    colNames <- c("Home Team", "Away Team", "Home Win in %", "Draw in %", "Away Win in %",
                  "Sum of home goals", "Sum of away goals", "Average home goals",
                  "Average away goals")
    sumUpData <- c(home, away, 0, 0, 0, 0, 0, 0, 0)
    len <- dim(specData)[1]
    for (i in 1:len) {
        if (specData[i, "FTR"] == "H") {
            sumUpData[3] <- as.integer(sumUpData[3]) + 1
        } else if (specData[i, "FTR"] == "D") {
            sumUpData[4] <- as.integer(sumUpData[4]) + 1
        } else {
            sumUpData[5] <- as.integer(sumUpData[5]) + 1
        }
    }
    sumUpData[6] <- sum(specData[, "FTHG"])
    sumUpData[7] <- sum(specData[, "FTAG"])
    sumUpData <- matrix(sumUpData)
    sumUpData <- t(sumUpData)
    colnames(sumUpData) <- colNames
    # colnames(sumUpData) <- column.names
    
    return (sumUpData)
}

OverviewAll <- function(home = "", away = "") {
    home.away <- sumUpComparison(home, away)
    away.home <- sumUpComparison(away, home)
    data <- rbind(home.away, away.home)
    return (data)
}

# ---------------------------------------------------------------------------------------------------------------------------------------

loadAllContent <- function(path = "Data", league = "Germany", filename = "Synopsis.csv") {
    return (read.csv(file = paste(path, league, filename, sep = "/")))
}

loadLeagueContent <- function(path = "Data", league = "Germany", filename = "Bundesliga1.csv") {
    return (read.csv(file = paste(path, league, filename, sep = "/")))
}

loadTeams <- function(path = "Data", filename = "teams.csv") {
    return (scan(file = paste(path, filename, sep = "/"), what = "character", sep = "\n"))
}

loadPreferedStatistics <- function(path = "Data", filename = "Statistics.csv") {
    return (scan(file = paste(path, filename, sep = "/"), what = "character", sep = "\n"))
}

extractOneTeam <- function(myTeam, path = "Data", league = "Germany", filename = "data.csv") {
    # teams <- loadTeams()
    data <- loadAllContent()
    # for (team in teams) {
        home <- subset(data, HomeTeam == myTeam)
        away <- subset(data, AwayTeam == myTeam)
        output <- rbind(home, away)
        # write.csv(output, paste(path, league, team, filename, sep = "/"), row.names = FALSE)
    # }
    return (output)
}

sumUpOneTeam <- function(myTeam, path = "Data", league = "Germany", filename = "data.csv") {
    # teams <- loadTeams()
    data <- loadAllContent()
    # for (team in teams) {
        home <- subset(data, HomeTeam == myTeam)
        output <- c(myTeam)
        # away <- subset(data, AwayTeam == myTeam)
        # whole <- rbind(home, away)
        for (i in 4:ncol(home)) {
            output <- c(output, sum(as.numeric(home[, i])))
        }
        # output <- sum(home[, 5:14])
        # write.csv(whole, paste(path, league, team, filename, sep = "/"), row.names = FALSE)
    # }
    return (output)
}

overallData <- function(path = "Data") {
    data <- loadLeagueContent()
    results <- matrix(0, 10, 10)
    vec <- as.vector(data[, "FTR"])
    sums <- c(0, 0, 0)
    for (val in vec) {
        if (val == "H") {
            sums[1] <- sums[1] + 1
        } else if (val == "D") {
            sums[2] <- sums[2] + 1
        } else {
            sums[3] <- sums[3] + 1
        }
    }
    sums <- c(sums, sum(data[, "FTHG"]))
    sums <- c(sums, sum(data[, "FTAG"]))
    sums <- matrix(sums)
    
    outcomes <- 0:9
    rownames(results) <- outcomes
    colnames(results) <- outcomes
    home <- as.character(data[, "FTHG"])
    away <- as.character(data[, "FTAG"])
    for (i in 1:length(home)) {
        results[home[i], away[i]] <- results[home[i], away[i]] + 1
    }
    
    difference <- matrix(0, 1, 9)
    colnames(difference) <- as.character(0:8)
    
    home <- data[, "FTHG"]
    away <- data[, "FTAG"]
    for (i in 1:length(home)) {
        diff <- as.character(abs(home[i]-away[i]))
        difference[1, diff] <- difference[1, diff] + 1
    }
    
    goalSumsPerMatch <- matrix(0, 12, 1)
    rownames(goalSumsPerMatch) <- as.character(0:11)
    
    for (i in 1:length(home)) {
        gspmSums <- as.character(home[i] + away[i])
        goalSumsPerMatch[gspmSums, 1] <- goalSumsPerMatch[gspmSums, 1] + 1
    }
    
    # print(results)
    first <- data.frame(0:9)
    colnames(first) <- "H\\A"
    # results <- cbind(first, results)
    out <- list(sums, results, difference, goalSumsPerMatch)
    print(out)
    return (out)
}

allGamesComparison <- function(home = "", away = "") {
    data <- loadAllContent()
    compareTable <- data[which(data$HomeTeam == home
                               & data$AwayTeam == away), ]
    compareTable <- rbind(compareTable, data[which(data$HomeTeam == away
                               & data$AwayTeam == home), ])
    return (compareTable)
}

teamComparison <- function(home = "", away = "") {
    data <- loadAllContent()
    compareTable <- data[which(data$HomeTeam == home
                               & data$AwayTeam == away), ]
    return (compareTable)
}

sumUpComparison <- function(home = "", away = "") {
    specData <- teamComparison(home, away)
    # column.names <- colnames(specData)
    colNames <- c("Home Team", "Away Team", "Home Win in %", "Draw in %", "Away Win in %",
                  "Sum of home goals", "Sum of away goals", "Average home goals",
                  "Average away goals")
    sumUpData <- c(home, away, 0, 0, 0, 0, 0, 0, 0)
    len <- dim(specData)[1]
    for (i in 1:len) {
        if (specData[i, "FTR"] == "H") {
            sumUpData[3] <- as.integer(sumUpData[3]) + 1
        } else if (specData[i, "FTR"] == "D") {
            sumUpData[4] <- as.integer(sumUpData[4]) + 1
        } else {
            sumUpData[5] <- as.integer(sumUpData[5]) + 1
        }
    }
    sumUpData[6] <- sum(specData[, "FTHG"])
    sumUpData[7] <- sum(specData[, "FTAG"])
    sumUpData <- matrix(sumUpData)
    sumUpData <- t(sumUpData)
    colnames(sumUpData) <- colNames
    # colnames(sumUpData) <- column.names
    
    return (sumUpData)
}

overviewAll <- function(home = "", away = "") {
    home.away <- sumUpComparison(home, away)
    away.home <- sumUpComparison(away, home)
    data <- rbind(home.away, away.home)
    return (data)
}

# ------------------------------------------------------------------------------------------------------------------------

createDirs <- function(path = "Data", league = "Germany", folders = "", warnings = FALSE) {
    dir.create(paste(path, league, sep = "/"), showWarnings = warnings)
    for (folder in folders) {
        dir.create(paste(path, league, folder, sep = "/"), showWarnings = warnings)
    }
}

downloadFiles <- function(url = "http://www.football-data.co.uk/mmz4281", league = "Germany",
                          path = "Data", folders = "", files = "") {
    for (folder in folders) {
        for (file in files) {
            download.file(paste(url, folder, file, sep = "/"),
                           destfile = paste(path, league, folder, file, sep = "/"))
        }
    }
}

extractData <- function(path = "Data", folders = "", files = "", league = "Germany",
                        analysisType = "Statistics.csv") {
    names <- scan(file = paste(path, analysisType, sep = "/"), what = "character")
    col <- length(names)
    
    for (folder in folders) {
        for (file in files) {
            mainData <- read.csv(paste(path, league, folder, file, sep = "/"))
            row <- dim(mainData)[1]
            cleanData <- data.frame(matrix(data = 0, nrow = row, ncol = col))
            colnames(cleanData) <- names
            for (name in names) {
                if (name %in% colnames(mainData)) {
                    cleanData[, name] <- mainData[, name]
                } else {
                    cleanData[, name] <- 0
                }
            }
            cleanData <- subset(cleanData, Div != "")
            write.csv(cleanData, paste(path, league, folder, file, sep = "/"),
                      row.names = FALSE)
        }
    }
}

combineAllData <- function(path = "Data", folders = "", files = "", league = "Germany",
                        filename = "Synopsis.csv", analysisType = "Statistics.csv") {
    names <- scan(file = paste(path, analysisType, sep = "/"), what = "character")
    col <- length(names)
    mainData <- data.frame(matrix(data = 0, nrow = 0, ncol = col))
    colnames(mainData) <- names
    for (folder in folders) {
        for (file in files) {
            tmp <- read.csv(paste(path, league, folder, file, sep = "/"))
            mainData <- rbind(mainData, tmp)
        }
    }
    D1 <- subset(mainData, Div == "D1")
    D2 <- subset(mainData, Div == "D2")
    write.csv(mainData, paste(path, league, filename, sep = "/"), row.names = FALSE)
    write.csv(D1, paste(path, league, "D1.csv", sep = "/"), row.names = FALSE)
    write.csv(D2, paste(path, league, "D2.csv", sep = "/"), row.names = FALSE)
}

createTeamFolder <- function(path = "Data", league = "Germany", filename = "teams.csv",
                             warnings = FALSE) {
    teams <- scan(file = paste(path, filename, sep = "/"), what = "character", sep = "\n")
    for (team in teams) {
        dir.create(paste(path, league, team, sep = "/"), showWarnings = warnings)
    }
}

init <- function(path = "Data", filename = "Synopsis.csv") {
    seasons <- c("9394", "9495", "9596", "9697",
                 "9798", "9899", "9900", "0001",
                 "0102", "0203", "0304", "0405",
                 "0506", "0607", "0708", "0809",
                 "0910", "1011", "1112", "1213",
                 "1314", "1415")
    divisions <- c("D1.csv", "D2.csv")
    createDirs(folders = seasons)
    downloadFiles(folders = seasons, files = divisions)
    extractData(folders = seasons, files = divisions)
    combineAllData(folders = seasons, files = divisions)
    createTeamFolder()
}