#Script to read in log files of BARS data and parse reults

#read_logs <- function(start_date = "2013-06-19", end_date = "2014-09-25") {

#Convert start and end date character strings to time variable
t0 <- as.Date("2013-06-19", "%Y-%m-%d")
tf <- as.Date("2014-09-25","%Y-%m-%d")

# t0 <- as.Date(start_date, "%Y-%m-%d")
# tf <- as.Date(end_date,"%Y-%m-%d")

#Create date vector spanning start and end time of data logs

t_vec <- seq.Date(from = t0, to = tf, by = "day")

#Initiate storage variable and counter for bad row storage
bars_data <- c()
bad_data_rows <- list(data_file = list(), row_idx = list())
k <- 1

#Specify BARS column headers
bars_cols <- c("Time","Rdiv5","Rx1","Rx5","Hdiv5","Hx1","Hx5","Eh"
               ,"Ref_V","Ref_T","Hi_V","Hi_T","Vbatt")

#Specify BARS column classes
bars_class <- c("character",rep("numeric",12))

#Loop over all files
#NOTE: 'seq'_along to index input instead of 'in' to directly assign loop
#       variable because direct assignment changes date class of input to
#       numeric
for(i in seq_along(t_vec)) {

    file_name <- paste0("OESUWBARS001_", format(t_vec[i], "%Y%m%d"),
                        "T000000.000Z.txt.gz")

    #Construct read command
    read_cmd_opt <- c(", stringsAsFactors = FALSE,"
                      , "col.names = bars_cols, colClasses = bars_class, "
                      , "fill = TRUE)")
    read_cmd_full <- c("read.table(gzfile(file_name)", read_cmd_opt)

    #Attempt to read in data. If mismatch with expected format occurs, go to
    #function, read_bad_data, to weed out bad rows line by line.
    log_data <- tryCatch(
        {
            eval(parse(text = read_cmd_full))
        },
        error = function(cond) {
            return(NA)
        },
        finally = {
            #Show progress
            message("Processed file: ",file_name)
        }
    )


    #If unsuccessful, go to read_bad_data and get any good data available
    if(anyNA(log_data)) {
        #Store results
        out_list <- read_bad_data(file_name, read_cmd_opt)
        log_data <- out_list$clean_data

        #Add to list containing list of rejected entries for each data_file
        bad_data_rows$data_file[k] = file_name
        bad_data_rows$row_idx[k] = list(out_list$reject)
        k <- k+1
    }

    #Concatenate local data to main data storage variable
    bars_data <- rbind(bars_data, log_data)
}
closeAllConnections()

#Get time out of date stored as text in first column
bars_time <- strptime(bars_data$Time, format = "%Y%m%dT%H%M%OS", tz = "GMT")

#Save .Rdata file
save(bars_cols, bars_data, bad_data_rows, file = "raw_bars_data.rdata")

#Remove first date column (which is stored as string) so Matlab can read in all
#numeric data
bars_data$Time <- NULL

#Add parsed time back to data frame as new columns
#Year starts from 1900
bars_data$year <- bars_time$year + 1900
#Months are indexed 0-11, so add 1 to get the correct number
bars_data$month <- bars_time$mon + 1
bars_data$day <- bars_time$mday
bars_data$hour <- bars_time$hour
bars_data$minute <- bars_time$min
bars_data$second <- bars_time$sec

# Write out results to csv for reading into Matlab
# setwd("C:/Users/ben/Dropbox/2015_EGU/calibration_data")
write.table(bars_data, file = "raw_bars_data.csv", sep = ","
            , col.names = TRUE, row.names = FALSE)
#}