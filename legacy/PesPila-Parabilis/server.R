library(shiny)

LoadPreferences <- function(output) {
    preferences <- ReadPreferences()
    output$myCountry <- renderText({preferences[1]})
    output$myDivision <- renderText({preferences[2]})
    output$myTeam <- renderText({preferences[3]})
    return (preferences)
}

LoadAndSetPreferenceChoice <- function(session, country = "Germany") {
    division <- strsplit(x = list.files(path = paste("Data", country, sep = "/"), pattern = ".csv"), split = ".csv")
    team <- FolderStructure(path = paste("Data", country, sep = "/"))

    updateSelectInput(session, "country", choices = GetCountries(), selected = country)
    updateSelectInput(session, "division", choices = division)
    updateSelectInput(session, "theTeam", choices = team)
}

LoadAndSetTeamDataChoice <- function(session, t = "Bayern Munich", div = "Bundesliga1", country = "Germany") {
    division <- strsplit(x = list.files(path = paste("Data", country, sep = "/"), pattern = ".csv"), split = ".csv")
    team <- FolderStructure(path = paste("Data", country, sep = "/"))

    updateSelectInput(session, "teamCountry", choices = GetCountries(), selected = country)
    updateSelectInput(session, "teamDivision", choices = division, selected = div)
    updateSelectInput(session, "teamChoice", choices = team, selected = t)
}

SetGeneralDataOverview <- function(session, preferences) {
    division <- strsplit(x = list.files(path = paste("Data", preferences[1], sep = "/"), pattern = ".csv"), split = ".csv")
    updateSelectInput(session, "countryOverview", choices = GetCountries(), selected = preferences[1])
    updateSelectInput(session, "leagueOverview", choices = division, selected = preferences[2])
}

GetSeasons <- function() {
    return (c("9394", "9495", "9596", "9697",
                 "9798", "9899", "9900", "0001",
                 "0102", "0203", "0304", "0405",
                 "0506", "0607", "0708", "0809",
                 "0910", "1011", "1112", "1213",
                 "1314", "1415", "1516"))
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

CreateSeasonDirectories <- function(path = "Data", seasons = "", warnings = FALSE) {
    for (season in seasons) {
        dir.create(paste(path, season, sep = "/"), showWarnings = warnings)
    }
}

Unzip2Dir <- function(zip.path = "Data", ex.path = "Data", seasons = "") {
    for (season in seasons) {
        unzip(zipfile = paste(zip.path, "/", season, ".zip", sep = ""),
            exdir = paste(ex.path, season, sep = "/"))
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
    
    country <- GetCountries()  # get all desired countries (c.f. function)

    for (c in country) {  # FOR
        dir.create(paste(path, c, sep = "/"))  # create a directory for each country (path = Data)
    }  # END FOR
    
    seasons <- GetSeasons()  # get all desired seasons (c.f. function)
    temp.dir <- CreateTempDir(path = path)  # create a temporary directory => Data/Temp
    DownloadFiles(path = temp.dir, seasons = seasons)  # download all seasons data files to Data/Temp
    CreateSeasonDirectories(path = temp.dir, seasons = seasons)  # create a directory for each season in Data/Temp
    
    for (c in country) {  # FOR
        dir <- paste("Data", c, sep = "/")  # create a dir name with Data/country_name...
        CreateSeasonDirectories(path = dir, seasons = c(seasons, "Teams"))  # create a directory for each season in each country's folder including a "Teams" folder
    }  # END FOR
    
    Unzip2Dir(zip.dir = temp.dir, ex.dir = temp.dir, seasons = seasons)  # unzip all seasons into the seasons folders in Data/Temp
    
    for (c in country) {  # FOR
        dir <- paste("Data", c, sep = "/")  # create a dir name with Data/country_name...
        Unzip2Dir(zip.path = temp.dir, ex.path = dir, seasons = seasons)  # unzip all seasons into every country's folder
    }  # END FOR

    for (c in country) {  # FOR
        for (season in seasons) {  # FOR
            files <- strsplit(x = list.files(path = paste("Data", c, season, sep = "/"), pattern = ".csv"), split = ".csv")
            print(files)
        }  # END FOR
    }  # END FOR


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
    column.names <- c("HWin", "Draw", "AWin", "FTHG", "FTAG", "HTHG", "HTAG")
    cum.data <- data.frame(matrix(0, length.divisions, 7))
    for (i in 1:length.divisions) {
        dataset <- LoadCountryData(path, country, divisions[i])
        sum <- c(0, 0, 0, sum(dataset[, "FTHG"]), sum(dataset[, "FTAG"]), sum(dataset[, "HTHG"]), sum(dataset[, "HTAG"]))
        for (value in as.vector(dataset[, "FTR"])) {
            if (value == "H") {
                sum[1] <- sum[1] + 1
            } else if (value == "D") {
                sum[2] <- sum[2] + 1
            } else {
                sum[3] <- sum[3] + 1
            }
        }
        row.names <- c(row.names, strsplit(x = divisions[i], split = ".csv")[[1]])
        cum.data[i, ] <- sum
    }
    rownames(cum.data) <- row.names
    colnames(cum.data) <- column.names
    # cum.data[, 1] <- row.names
    return (cum.data)
}

GoalsAndPointsPerMatch <- function(path = "Data", country = "Germany", filename = "Bundesliga1.csv") {
    country.data <- LoadCountryData(path, country, filename)
    gp.data <- list(points = rep(0, nrow(country.data)), goals = rep(0, nrow(country.data)))
    for (i in 1:nrow(country.data)) {
        if (country.data[, "FTR"] == "H") {
            gp.data$points[i] <- 3
            gp.data$goals[i] <- country.data[, "FTHG"]
        } else if (country.data[, "FTR"] == "A") {
            gp.data$points[i] <- 3
            gp.data$goals[i] <- country.data[, "FTAG"]
        } else if (country.data[, "FTR"] == "D") {
            gp.data$points[i] <- 1
            gp.data$goals[i] <- country.data[, "FTHG"]
        }
    }

    return (gp.data)
}

GoalDifferences <- function(path = "Data", country = "Germany") {
    divisions <- list.files(path = paste(path, country, sep = "/"), pattern = ".csv")
    length.divisions <- length(divisions)
    row.names <- c()
    column.names <- 0:9
    cum.data <- data.frame(matrix(0, length.divisions, 10))
    for (i in 1:length.divisions) {
        dataset <- LoadCountryData(path, country, divisions[i])
        home <- dataset[, "FTHG"]
        away <- dataset[, "FTAG"]
        for (j in 1:length(home)) {
            difference <- abs(home[j] - away[j])
            cum.data[i, difference + 1] <- cum.data[i, difference + 1] + 1
        }
        row.names <- c(row.names, strsplit(x = divisions[i], split = ".csv")[[1]])
    }
    rownames(cum.data) <- row.names
    colnames(cum.data) <- column.names
    # cum.data[, 1] <- row.names
    return (cum.data)
}

GSPM <- function(path = "Data", country = "Germany") {
    divisions <- list.files(path = paste(path, country, sep = "/"), pattern = ".csv")
    length.divisions <- length(divisions)
    row.names <- c()
    column.names <- 0:13
    cum.data <- data.frame(matrix(0, length.divisions, 14))
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
            cum.data[i, gspm + 1] <- cum.data[i, gspm + 1] + 1
        }
        row.names <- c(row.names, strsplit(x = divisions[i], split = ".csv")[[1]])
    }
    # rownames(cum.data) <- row.names
    colnames(cum.data) <- column.names
    rownames(cum.data) <- row.names
    # cum.data[, 1] <- row.names
    return (cum.data)
}

GSPS <- function(path = "Data", folder = "Seasons", division = "Bundesliga1") {
    row.names <- GetSeasons()
    col.names <- c("Home Goals", "Away Goals", "All Goals", "Home goals per game", "Away goals per game", "Goals per game")
    len.col.names <- length(col.names)
    len.row.names <- length(row.names)
    data <- data.frame(matrix(ncol = len.col.names, nrow = len.row.names, 0))
    colnames(data) <- col.names
    look.up <- paste(path, folder, sep = "/")
    games <- 34 * 9
    # print(GetFilenamesLeaugesHashTable()[division])
    for (i in 1:len.row.names) {
        dataset <- read.csv(file = paste(look.up, row.names[i], GetFilenamesLeaugesHashTable()[[division]], sep = "/"))
        data[i, 1] <- sum(dataset[, "FTHG"])
        data[i, 2] <- sum(dataset[, "FTAG"])
        data[i, 3] <- data[i, 1] + data[i, 2]
        data[i, 4] <- round(data[i, 1] / games, 2)
        data[i, 5] <- round(data[i, 2] / games, 2)
        data[i, 6] <- round(data[i, 3] / games, 2)
        # print(paste(look.up, row, GetFilenamesLeaugesHashTable()[[division]], sep = "/"))
    }
    # row.names <- paste(c(paste0("0", 1:9, sep = ""), 10:22), row.names, sep = "_")
    rownames(data) <- row.names
    # data[, 1] <- row.names
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
    column.names <- 0:11
    row.names <- 0:11
    cum.data <- data.frame(matrix(0, 12, 12))
    home <- dataset[, "FTHG"]
    away <- dataset[, "FTAG"]
    for (i in 1:length(home)) {
        cum.data[home[i] + 1, away[i] + 1] <- cum.data[home[i] + 1, away[i] + 1] + 1
    }
    # cum.data <- cbind(data.frame(0:11), cum.data)
    rownames(cum.data) <- row.names
    colnames(cum.data) <- column.names
    # cum.data[, 1] <- row.names
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
    if (division == "Synopsis") {
        return (dataset)
    } else {
        hash.table <- GetFilenamesLeaugesHashTable()
        hash <- strsplit(x = hash.table[[division]], split = ".csv")
        return (subset(dataset, Div == hash))
    }
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
    header <- c("Win", "Draw", "Lost", "FTG", "HTG", "FTG against", "HTG against")
    rows <- c("Home", "Away", "Overall")
    dataset <- read.csv(file = paste(path, country, filename, sep = "/"))
    new.data <- data.frame(matrix(0, 3, 7))
    home <- subset(dataset, HomeTeam == team)
    away <- subset(dataset, AwayTeam == team)
    new.data[1, 1] <- nrow(subset(home, FTR == "H"))
    new.data[1, 2] <- nrow(subset(home, FTR == "D"))
    new.data[1, 3] <- nrow(subset(home, FTR == "A"))
    new.data[2, 1] <- nrow(subset(away, FTR == "A"))
    new.data[2, 2] <- nrow(subset(away, FTR == "D"))
    new.data[2, 3] <- nrow(subset(away, FTR == "H"))
    new.data[1, 4] <- sum(home[, "FTHG"])
    new.data[1, 5] <- sum(home[, "HTHG"])
    new.data[1, 6] <- sum(home[, "FTAG"])
    new.data[1, 7] <- sum(home[, "HTAG"])
    new.data[2, 4] <- sum(away[, "FTAG"])
    new.data[2, 5] <- sum(away[, "HTAG"])
    new.data[2, 6] <- sum(away[, "FTHG"])
    new.data[2, 7] <- sum(away[, "HTHG"])
    for (i in 1:ncol(new.data)) {
        new.data[3, i] <- new.data[1, i] + new.data[2, i]
    }
    rownames(new.data) <- rows
    # new.data[, 1] <- rows
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
    colNames <- c("Home Team", "Away Team", "Home Win", "Draw", "Away Win",
                  "Home Goals", "Away Goals", "Average Home Goals",
                  "Average Away Goals")
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
    sumUpData[8] <- sum(specData[, "FTHG"]) / nrow(specData)
    sumUpData[9] <- sum(specData[, "FTAG"]) / nrow(specData)
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

shinyServer(
    function(input, output, session) {
        country <- GetCountries()
        seasons <- GetSeasons()
        # temp.dir <- "Data/Temp"
        for (c in country) {  # FOR
            for (season in seasons) {  # FOR
                files <- strsplit(x = list.files(path = paste("Data", c, season, sep = "/"), pattern = ".csv"), split = ".csv")
                print(files)
            }  # END FOR
        }  # END FOR
        # for (c in country) {  # FOR
        #     dir <- paste("Data", c, sep = "/")  # create a dir name with Data/country_name...
        #     Unzip2Dir(zip.path = temp.dir, ex.path = dir, seasons = seasons)
        # }  # END FOR

        preferences <- LoadPreferences(output)

        observeEvent(input$country, {

            if (input$country == "") {
                LoadAndSetPreferenceChoice(session, preferences[1])
                LoadAndSetTeamDataChoice(session, preferences[3], preferences[2], preferences[1])
                SetGeneralDataOverview(session, preferences)
            } else {
                LoadAndSetPreferenceChoice(session, input$country)
                LoadAndSetTeamDataChoice(session, preferences[3], preferences[2], input$country)
                SetGeneralDataOverview(session, preferences)
            }

        })

        observeEvent(input$setPreferences, {

            SetPreferences(input$country, input$division, input$theTeam)
            preferences <- LoadPreferences(output)
            SetGeneralDataOverview(session, preferences)
            LoadAndSetTeamDataChoice(session, input$theTeam, input$division, input$country)
            SetGeneralDataOverview(session, preferences)

        })

        observeEvent(input$countryOverview, {

            division <- strsplit(x = list.files(path = paste("Data", country = input$countryOverview,
                                                sep = "/"), pattern = ".csv"), split = ".csv")

            if (input$countryOverview == preferences[1]) {
                updateSelectInput(session, "leagueOverview",
                            choices = division,
                            selected = preferences[2])
            } else {
                updateSelectInput(session, "leagueOverview",
                            choices = division,
                            selected = division[1])
            }

            output$wins <- DT::renderDataTable({

                data <- Wins(path = "Data", country = input$countryOverview)
                datatable(data,
                    rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })
            output$winsPercent <- DT::renderDataTable({

                data <- Wins(path = "Data", country = input$countryOverview)
                for (i in 1:nrow(data)) {
                    data[i, 1:3] <- round(data[i, 1:3] / sum(data[i, 1:3]) * 100, 2)
                    data[i, 4:5] <- round(data[i, 4:5] / sum(data[i, 4:5]) * 100, 2)
                    data[i, 6:7] <- round(data[i, 6:7] / sum(data[i, 6:7]) * 100, 2)
                }
                datatable(data,
                    rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })
            output$results <- DT::renderDataTable({

                data <- ResultsComparison(path = "Data", country = input$countryOverview, division = input$leagueOverview)
                new.row <- rep(0, times = ncol(data)+1)
                new.col <- rep(0, times = nrow(data))
                # new.row[1] <- "Sum"
                for (i in 1:ncol(data)) {
                    new.row[i] <- sum(data[, i])
                }
                for (i in 1:nrow(data)) {
                    new.col[i] <- sum(data[i, 1:ncol(data)])
                }

                data <- cbind(data, new.col)
                colnames(data)[ncol(data)] <- "Sum"
                data <- rbind(data, new.row)
                rownames(data) <- c(0:11, "Sum")
                datatable(data,
                    rownames = TRUE, escape = FALSE, caption = 'Vertical: home goals, Horizontal: away goals.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })

            output$resultsPercent <- DT::renderDataTable({

                data <- ResultsComparison(path = "Data", country = input$countryOverview, division = input$leagueOverview)
                sum.of.data <- sum(data)
                new.data <- round(data / sum.of.data * 100, 2)
                # new.data[, 1] <- 0:11
                new.row <- rep(0, times = ncol(new.data)+1)
                new.col <- rep(0, times = nrow(new.data))
                # new.row[1] <- "Sum"
                for (i in 1:ncol(new.data)) {
                    new.row[i] <- sum(new.data[, i])
                }
                for (i in 1:nrow(new.data)) {
                    new.col[i] <- sum(new.data[i, 1:ncol(new.data)])
                }

                new.data <- cbind(new.data, new.col)
                colnames(new.data)[ncol(new.data)] <- "Sum"
                new.data <- rbind(new.data, new.row)
                rownames(new.data) <- c(0:11, "Sum")

                # data <- ResultsComparison(path = "Data", country = input$countryOverview, division = input$leagueOverview)
                datatable(new.data,
                    rownames = TRUE, escape = FALSE, caption = 'Vertical: home goals, Horizontal: away goals.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })
            # output$wins <- DT::renderDataTable(Wins(path = "Data", country = input$countryOverview))
            # output$results <- DT::renderDataTable(ResultsComparison(path = "Data", country = input$countryOverview, division = input$leagueOverview))
            # output$resultsPercent <- DT::renderDataTable({

            #     data <- ResultsComparison(path = "Data", country = input$countryOverview, division = input$leagueOverview)
            #     sum.of.data <- sum(data[, 2:ncol(data)])
            #     new.data <- round(data / sum.of.data * 100, 2)
            #     new.data[, 1] <- 0:11
            #     new.row <- rep(0, times = ncol(new.data))
            #     new.col <- rep(0, times = nrow(new.data))
            #     new.row[1] <- "Sum"
            #     for (i in 2:ncol(new.data)) {
            #         new.row[i] <- sum(new.data[, i])
            #     }
            #     for (i in 1:nrow(new.data)) {
            #         new.col[i] <- sum(new.data[i, 2:ncol(new.data)])
            #     }

            #     new.data <- cbind(new.data, new.col)
            #     colnames(new.data)[ncol(new.data)] <- "Sum"
            #     new.data <- rbind(new.data, c(new.row, 0))

            #     return (new.data)
            
            # })
            output$goalDifferences <- DT::renderDataTable({

                data <- GoalDifferences(path = "Data", country = input$countryOverview)
                datatable(data,
                    rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })
            output$goalDifferencesPercent <- DT::renderDataTable({

                data <- GoalDifferences(path = "Data", country = input$countryOverview)
                for (i in 1:nrow(data)) {
                    data[i, ] <- round(data[i, ] / sum(data[i, ]) * 100, 2)
                }
                datatable(data,
                    rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })
            output$gspm <- DT::renderDataTable({

                data <- GSPM(path = "Data", country = input$countryOverview)
                datatable(data,
                    rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })
            # output$goalDifferences <- DT::renderDataTable(GoalDifferences(path = "Data", country = input$countryOverview))
            # output$gspm <- DT::renderDataTable(datatable(GSPM(path = "Data", country = input$countryOverview)))
            # output$gsps <- DT::renderDataTable(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))
            # print(datatable(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"),
            #         rownames = FALSE, caption = 'My first datatable try.',
            #         extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
            #         options = list(pageLength = -1,
            #             lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
            #             deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
            #             searchHighlight = TRUE,
            #             # initComplete = JS(
            #             #     "function(settings, json) {",
            #             #         "$(this).api().table().header()).css({'background-color' : '#000'})",
            #             #     "}"),
            #             dom = 'T<"clear">RCl<"clear">frtipS',
            #             colReorder = list(realtime = TRUE),
            #             TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
            #         )
            #     ))
            output$gsps <- DT::renderDataTable({

                data <- GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1")
                datatable(data,
                    rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })
            output$gspsPlot <- renderPlot({

                data <- GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1")
                print(head(data))
                plot(1:22, data[, 6], type = "l", xlim = c(1, 23), ylim = c(0.5, 3.5), col = "blue", lwd = 2, axes = FALSE)
                axis(side = 1, at = c(1, 5, 10, 15, 20, 22), label = rownames(data)[c(1, 5, 10, 15, 20, 22)])
                axis(2)
                lines(1:22, data[, 4], col = "magenta", lwd = 2)
                lines(1:22, data[, 5], col = "orange", lwd = 2)

            })
            output$gspmPlot <- renderPlot({

                progress <- Progress$new(session, min = 1, max = 4)
                on.exit(progress$close())
                progress$set(message = 'Calculation in progress', detail = 'Loading data...')

                progress$set(value = 1)

                progress$set(value = 2)
                data <- GSPM(path = "Data", country = input$countryOverview)
                plot(0:13, as.numeric(data[1, 1:14]), type = "l", col = "red", lwd = 2, ylim = c(0, 3500))
                lines(0:13, as.numeric(data[2, 1:14]), col = "blue", lwd = 2)
                lines(0:13, as.numeric(data[3, 1:14]), col = "black", lwd = 2, axes = FALSE)
                progress$set(value = 3)
                axis(side = 1, at = 0:13, label = 0:13)
                axis(2)
                progress$set(value = 4)
                # plot(1:22, data[, 7], type = "l", xlim = c(1, 23), ylim = c(0.5, 3.5), col = "blue", lwd = 2, axes = FALSE)
                # axis(side = 1, at = c(1, 5, 10, 15, 20, 22), label = data[c(1, 5, 10, 15, 20, 22), 1])
                # axis(2)
                # lines(1:22, data[, 5], col = "magenta", lwd = 2)
                # lines(1:22, data[, 6], col = "orange", lwd = 2)

            })
            output$all <- DT::renderDataTable({

                data <- LoadCountryData(path = "Data", country = input$countryOverview,
                                            filename = paste(c(input$leagueOverview, ".csv"), collapse = ""))[, 1:10]
                datatable(data,
                    rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                    extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                    options = list(pageLength = -1,
                        lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                        deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                        searchHighlight = TRUE,
                        # initComplete = JS(
                        #     "function(settings, json) {",
                        #         "$(this).api().table().header().css({'background' : '#000000'})",
                        #     "}"),
                        dom = 'T<"clear">RC<"clear">lfrtipS',
                        colReorder = list(realtime = TRUE),
                        TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                    )
                ) #%>%
                #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
                #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
                #                 fontWeight = 'bold'
                #     )
            })
            # output$all <- DT::renderDataTable(LoadCountryData(path = "Data", country = input$countryOverview,
            #                                 filename = paste(c(input$leagueOverview, ".csv"), collapse = ""))[, 1:10],
            #                                 options = list(pageLength = 100))
            # output$specAll <- DT::renderDataTable(LoadCountryData(path = "Data", country = input$countryOverview, filename = "Synopsis.csv")[, 1:10],
            #                                 options = list(pageLength = 100))

        })

        observeEvent(input$teamCountry, {

            # progress <- Progress$new(session, min = 1, max = 4)
            # on.exit(progress$close())
            # progress$set(message = 'Calculation in progress', detail = 'Loading data...')

            division <- strsplit(x = list.files(path = paste("Data", country = input$teamCountry,
                                                sep = "/"), pattern = ".csv"), split = ".csv")
            team <- FolderStructure(path = paste("Data", input$teamCountry, sep = "/"))

            if (input$teamCountry == preferences[1]) {
                updateSelectInput(session, "teamDivision",
                            choices = division,
                            selected = preferences[2])
            } else {
                updateSelectInput(session, "teamDivision",
                            choices = division,
                            selected = division[1])
            }

        })

        observeEvent(input$teamDivision, {

            team <- FolderStructure(path = paste("Data", input$teamCountry, sep = "/"))

            if (input$teamCountry == preferences[1]) {
                updateSelectInput(session, "teamChoice",
                            choices = team,
                            selected = preferences[3])
            } else {
                updateSelectInput(session, "teamChoice",
                            choices = team,
                            selected = team[1])
            }

        })

        # output$allMatches <- DT::renderDataTable(OneTeamsData(input$teamChoice, "B", "Data", input$teamCountry)[, 1:10],
        #                                 options = list(pageLength = 100))
        # output$homeMatches <- DT::renderDataTable(OneTeamsData(input$teamChoice, "H", "Data", input$teamCountry)[, 1:10],
        #                                 options = list(pageLength = 100))
        # output$awayMatches <- DT::renderDataTable(OneTeamsData(input$teamChoice, "A", "Data", input$teamCountry)[, 1:10],
        #                                 options = list(pageLength = 100))
        # output$divisionMatches <- DT::renderDataTable(MatchesByDivision(input$teamChoice, "Data", input$teamCountry, input$teamDivision)[, 1:10],
        #                                 options = list(pageLength = 100))
        # output$overviewMatches <- DT::renderDataTable(TeamOverview(input$teamChoice, "Data", input$teamCountry),
        #                                 options = list(pageLength = 100))
        # output$last2 <- DT::renderDataTable(LastMatches(input$teamChoice, 2, "Data", input$teamCountry)[, 1:10],
        #                                 options = list(pageLength = 100))
        # output$last5 <- DT::renderDataTable(LastMatches(input$teamChoice, 5, "Data", input$teamCountry)[, 1:10],
        #                                 options = list(pageLength = 100))
        # output$last10 <- DT::renderDataTable(LastMatches(input$teamChoice, 10, "Data", input$teamCountry)[, 1:10],
        #                                 options = list(pageLength = 100))

        output$allMatches <- DT::renderDataTable({

            data <- OneTeamsData(input$teamChoice, "B", "Data", input$teamCountry)[, 1:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$homeMatches <- DT::renderDataTable({

            data <- OneTeamsData(input$teamChoice, "H", "Data", input$teamCountry)[, 1:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$awayMatches <- DT::renderDataTable({

            data <- OneTeamsData(input$teamChoice, "A", "Data", input$teamCountry)[, 1:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$divisionMatches <- DT::renderDataTable({

            data <- MatchesByDivision(input$teamChoice, "Data", input$teamCountry, input$teamDivision)[, 1:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$overviewMatches <- DT::renderDataTable({

            data <- TeamOverview(input$teamChoice, "Data", input$teamCountry)

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$test <- DT::renderDataTable({

            dataAll <- TeamOverview(input$teamChoice, "Data", input$teamCountry)
            games <- rep(3, 0)
            hGoals <- rep(4, 0)
            aGoals <- rep(4, 0)
            for (i in 1:nrow(dataAll)) {
                games[i] <- sum(dataAll[i, c("Win", "Draw", "Lost")])
                hGoals[i] <- dataAll[i, "FTG"]/games[i]
                aGoals[i] <- dataAll[i, "FTG against"]/games[i]
            }

            dataSpec <- SumUpComparison(input$home, input$away)
            hGoals[4] <- dataSpec[1, "Average Home Goals"]
            aGoals[4] <- dataSpec[1, "Average Away Goals"]

            hg <- hGoals[1]*0.7
            print(hg)

            # print(c((hGoals[1]*0.7+hGoals[4]*1.3)/2, (aGoals[1]*0.7+aGoals[4]*1.3)/2))

            datatable(dataAll,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$overviewMatchesPercent <- DT::renderDataTable({

            data <- TeamOverview(input$teamChoice, "Data", input$teamCountry)
            for (i in 1:nrow(data)) {
                data[i, 1:3] <- round(data[i, 1:3] / sum(data[i, 1:3]) * 100, 2)
                data[i, 4:5] <- round(data[i, 4:5] / sum(data[i, 4:5]) * 100, 2)
                data[i, 6:7] <- round(data[i, 6:7] / sum(data[i, 6:7]) * 100, 2)
            }

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$last2 <- DT::renderDataTable({

            data <- LastMatches(input$teamChoice, 2, "Data", input$teamCountry)[, 1:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$last5 <- DT::renderDataTable({

            data <- LastMatches(input$teamChoice, 5, "Data", input$teamCountry)[, 1:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$last10 <- DT::renderDataTable({

            data <- LastMatches(input$teamChoice, 10, "Data", input$teamCountry)[, 1:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$gpPerMatch <- renderPlot({

            data <- GoalsAndPointsPerMatch(path = "Data", country = input$teamCountry, filename = paste(c(input$teamDivision, ".csv"), collapse = ""))
            print(data)
            plot(data$points, data$goals, type = "l")
        })
        output$allMatchesTrend <- renderPlot({
            data <- TrendPlot(input$teamChoice, "B", "Data", input$teamCountry)
            plot(data[[1]], data[[2]], type = "s", xlab = "Date", ylab = "Points", axes = FALSE)
            dat1 <- data[[1]]
            dat3 <- data[[3]]
            axis(1, at = c(dat1[1], dat1[seq(1, length(dat1), 34)], dat1[length(dat1)]),
                    labels = c(dat3[1], dat3[seq(1, length(dat3), 34)], dat3[length(dat3)]))
            axis(2)
        })
        output$homeMatchesTrend <- renderPlot({
            data <- TrendPlot(input$teamChoice, "H", "Data", input$teamCountry)
            plot(data[[1]], data[[2]], type = "s", xlab = "Date", ylab = "Points", axes = FALSE)
            dat1 <- data[[1]]
            dat3 <- data[[3]]
            axis(1, at = c(dat1[1], dat1[seq(1, length(dat1), 34)], dat1[length(dat1)]),
                    labels = c(dat3[1], dat3[seq(1, length(dat3), 34)], dat3[length(dat3)]))
            axis(2)
        })
        output$awayMatchesTrend <- renderPlot({
            data <- TrendPlot(input$teamChoice, "A", "Data", input$teamCountry)
            plot(data[[1]], data[[2]], type = "s", xlab = "Date", ylab = "Points", axes = FALSE)
            dat1 <- data[[1]]
            dat3 <- data[[3]]
            axis(1, at = c(dat1[1], dat1[seq(1, length(dat1), 34)], dat1[length(dat1)]),
                    labels = c(dat3[1], dat3[seq(1, length(dat3), 34)], dat3[length(dat3)]))
            axis(2)
        })

        output$allMatchesBoxPlot <- renderPlot({
            data <- TrendPlot(input$teamChoice, "B", "Data", input$teamCountry)
            boxplot(data[[4]]/length(data[[4]]), ylim = c(0, 3))
        })
        output$homeMatchesBoxPlot <- renderPlot({
            data <- TrendPlot(input$teamChoice, "H", "Data", input$teamCountry)
            boxplot(data[[4]]/length(data[[4]]), ylim = c(0, 3))
        })
        output$awayMatchesBoxPlot <- renderPlot({
            data <- TrendPlot(input$teamChoice, "A", "Data", input$teamCountry)
            boxplot(data[[4]]/length(data[[4]]), ylim = c(0, 3))
        })
        
        # output$compare <- DT::renderDataTable(TeamComparison(input$home, input$away)[, 2:10],
        #                                   options = list(pageLength = 100)
        # )

        # output$compareAll <- DT::renderDataTable(AllGamesComparison(input$home, input$away)[, 2:10],
        #                                      options = list(pageLength = 100)
        # )
        
        # output$overview <- DT::renderDataTable(SumUpComparison(input$home, input$away))

        # output$overviewAll <- DT::renderDataTable(OverviewAll(input$home, input$away))

        output$compare <- DT::renderDataTable({

            data <- TeamComparison(input$home, input$away)[, 2:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$compareAll <- DT::renderDataTable({

            data <- AllGamesComparison(input$home, input$away)[, 2:10]

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$overview <- DT::renderDataTable({

            data <- SumUpComparison(input$home, input$away)

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })
        output$overviewAll <- DT::renderDataTable({

            data <- OverviewAll(input$home, input$away)

            datatable(data,
                rownames = TRUE, escape = FALSE, caption = 'My first datatable try.',
                extensions = c('TableTools', 'ColReorder', 'ColVis', 'FixedColumns'),
                options = list(pageLength = -1,
                    lengthMenu = list(c(-1, 50, 100), list('All', '50', '150')),
                    deferRender = TRUE, colVis = list(exclude = c(0, 1), activate = 'mouseover'),
                    searchHighlight = TRUE,
                    # initComplete = JS(
                    #     "function(settings, json) {",
                    #         "$(this).api().table().header().css({'background' : '#000000'})",
                    #     "}"),
                    dom = 'T<"clear">RC<"clear">lfrtipS',
                    colReorder = list(realtime = TRUE),
                    TableTools = list(sSwfPath = copySWF('www', pdf = TRUE))
                )
            ) #%>%
            #     formatStyle(columns = colnames(GSPS(path = "Data", folder = "Seasons", division = "Bundesliga1"))[, 2:4],
            #                 color = styleInterval(c(400, 500), c('red', 'blue', 'green')),
            #                 fontWeight = 'bold'
            #     )
        })

        output$hvaBoxPlot <- renderPlot({
            data <- TeamComparison(input$home, input$away)[, 2:10]
            hData <- rep(0, nrow(data)+1)
            aData <- rep(0, nrow(data)+1)
            for (i in 1:nrow(data)) {
                if (data[i, "FTR"] == "H") {
                    hData[i+1] <- hData[i] + 3
                } else if (data[i, "FTR"] == "A") {
                    aData[i+1] <- aData[i] + 3
                } else {
                    hData[i+1] <- hData[i] + 1
                    aData[i+1] <- aData[i] + 1
                }
            }
            hData <- hData[-1]
            aData <- aData[-1]
            # hData <- TrendPlot(input$home, "H", "Data", input$teamCountry)
            # aData <- TrendPlot(input$away, "A", "Data", input$teamCountry)
            boxplot(hData/length(hData), aData/length(aData), ylim = c(0, 3))
            # boxplot(hData[[4]]/length(hData[[4]]), aData[[4]]/length(aData[[4]]), ylim = c(0, 3))
        })

        output$hvaHistPlot <- renderPlot({
            data <- TeamComparison(input$home, input$away)[, 2:10]
            hData <- rep(0, nrow(data))
            for (i in 1:nrow(data)) {
                if (data[i, "FTR"] == "H") {
                    hData[i] <- 0
                } else if (data[i, "FTR"] == "A") {
                    hData[i] <- 1
                } else {
                    hData[i] <- 2
                }
            }
            # hData <- TrendPlot(input$home, "H", "Data", input$teamCountry)
            # aData <- TrendPlot(input$away, "A", "Data", input$teamCountry)
            # hist(x, freq = FALSE, ylim = c(0, 0.2))
            hist(hData, breaks = 10, col = "cornflowerblue",
                        xlab = "Points", main = "Histogram: Points won by home team", axes = FALSE, ylim = c(0, nrow(data)))
            axis(side = 1, at = c(0, 1, 2), label = c("Home Win", "Draw", "Away Win"))
            axis(side = 2, at = c(0, nrow(data)), label = c(0, nrow(data)))
            # hist(hData, breaks = 10, col = "cornflowerblue", xlab = "Points", main = "Histogram: Points won by home team", xlim = c(0, 3))
            print(length(hData))
            # curve(rnorm(hData), col = 2, lty = 2, lwd = 2, add = TRUE)
            # curve(dchisq(hData), col = 2, lty = 2, lwd = 2, add = TRUE)
            # curve(dchisq(hData, df = 4), col = 2, lty = 2, lwd = 2, add = TRUE)
            # hist(-hData, col = "red", xlab = "Points", main = "Histogram: Points won by home team")
            # boxplot(hData[[4]]/length(hData[[4]]), aData[[4]]/length(aData[[4]]), ylim = c(0, 3))
        })

        output$hvaAllBoxPlot <- renderPlot({
            # hData <- OneTeamsData(input$home, "H", "Data", input$teamCountry)[, 1:10]
            # aData <- OneTeamsData(input$home, "A", "Data", input$teamCountry)[, 1:10]
            data <- Trend(input$home, input$away)
            # xData <- rep(0, times = nrow(hData)+nrow(aData))
            # yData <- rep(0, times = nrow(hData)+nrow(hData))
            # for (i in 1:nrow(hData)) {
            #     xData[i] <- hData[i, "FTHG"]
            #     yData[i] <- hData[i, "FTAG"]
            # }
            # for (i in 1:nrow(aData)) {
            #     xData[i+nrow(hData)] <- aData[i, "FTAG"]
            #     yData[i+nrow(hData)] <- aData[i, "FTHG"]
            # }
            # print(min(xData))
            # print(max(xData))
            # df <- as.data.frame(cbind(xData, yData))
            # a <- cor(xData, yData)

            # x <- lm(formula = xData~yData, data = df)
            # print(summary(x))
            # print(confint(x))
            # plot(x)
            # print(x)
            # plot(xData, yData, xlim = c(0, 10), ylim = c(0, 6))
            # abline(x)
            # lines(xData, a*xData)
            boxplot(data[[1]]/length(data[[1]]), data[[2]]/length(data[[2]]), ylim = c(0, 3))

        })

        output$lmTest <- renderPlot({
            data <- TeamComparison(input$home, input$away)[, 2:10]
            hData <- rep(0, nrow(data))
            aData <- rep(0, nrow(data))
            for (i in 1:nrow(data)) {
                if (data[i, 6] == "H") {
                    hData[i] <- 1
                    aData[i] <- -1
                } else if (data[i, 6] == "A") {
                    hData[i] <- -1
                    aData[i] <- 1
                }
            }
            # x <- c(hData[[4]], aData[[4]])
            # g <- factor(rep(2, length(x)),
            #             labels = c("Normal subjects",
            #                        "Subjects with asbestosis"))
            test <- cor(data.frame(hData, aData))
            print(symnum(test))
            # test <- cov(hData ~ aData)
            # print(length(x))
            # print(length(g))
            # test1 <- kruskal.test(hData ~ aData)
            # output$kruskal <- renderText({as.character(test1)})
            # test <- lm(hData[[4]] ~ aData[[4]])
            # plot(test)
            plot(test)
        })

        # output$sumTeamData <- DT::renderDataTable(SumUpOneTeam(input$teamChoice)[, 2:14],
        #                                    options = list(pageLength = 100))

        # observeEvent(input$reload,

        #     return({
        #       withProgress(session, min=1, max=2, {
        #         setProgress(message = 'Calculation in progress',
        #                     detail = 'This may take a while...')
        #         setProgress(value = 1)
        #         Initialize()
        #         setProgress(value = 2)
        #       })
        #     })

        # )
        
    }
)