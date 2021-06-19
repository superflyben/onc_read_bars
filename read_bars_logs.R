# Function to read in log files of BARS data and parse reults

library(lubridate)
library(tidyverse)

read_bars_logs <- function(data_dir) {
    
    # Get all zipped file names in the data directory 
    data_files <- data_dir %>% 
        paste0("ls -l ./", .) %>% 
        system(intern = TRUE) %>% 
        str_extract("\\S+.txt.gz$") %>% 
        .[which(!is.na(.))]
    
    # Extract the dates 
    file_dates <- data_files %>% 
        str_split("_") %>% 
        sapply(function(x) x[2]) %>% 
        str_extract("[[:digit:]]{8}") %>% 
        unique()
    
    #Initiate storage variable and counter for bad row storage
    bars_data <- c()
    bad_data_rows <- list(data_file = list(), row_idx = list())
    
    # Initiate the bad row storage index, only increments if file has bad data 
    k <- 1
    
    #Specify BARS column headers
    bars_cols <- c("Time",
                   "Rdiv5",
                   "Rx1",
                   "Rx5",
                   "Hdiv5",
                   "Hx1",
                   "Hx5",
                   "Eh",
                   "Ref_V",
                   "Ref_T",
                   "Hi_V",
                   "Hi_T",
                   "Vbatt")
    
    #Specify BARS column classes
    bars_class <- c("character",rep("numeric",12))
    
    #Loop over all files
    #NOTE: 'seq'_along to index input instead of 'in' to directly assign loop
    #       variable because direct assignment changes date class of input to
    #       numeric
    for(dat_file in data_files) {
        
        # Show progress
        writeLines(paste0("read_bars_logs: processing ", dat_file))
        
        # Extract the instrument id 
        instrument_id_cur <- dat_file %>% 
            str_split("_") %>% 
            unlist() %>% 
            .[1]
        
        # Connect to zip file in data directory 
        file_con <- gzfile(paste0(data_dir, dat_file))
        
        # Try reading the entire file 
        log_data <- tryCatch(
            {
                # Call function to read data 
                file_con %>% 
                    read.table(file = .,
                               col.names = bars_cols, 
                               colClasses = bars_class, 
                               stringsAsFactors = FALSE,
                               fill = TRUE)
            },
            error = function(cond) {
                message(paste0(cond, "\n"))
                return(NA)
            },
            finally = {
                # Show progress
                writeLines(paste0("Processed file: ",dat_file))
            }
        )
        
        # remove the connection object (read.table closed it)
        rm(file_con)
        
        # If any missing data records, go to read_bad_data and get any good data
        # available
        if(anyNA(log_data)) {
            
            writeLines(paste0("read_bars_logs: Found bad entries, ",
                              "calling read_bad_data for ", dat_file))
            
            # Source the read_bad_data function from the local environment so 
            # it uses variables created from within the function 
            source("read_bad_data.R", local = TRUE)
            
            # Call the function 
            out_list <- dat_file %>% read_bad_data()
            # Extract the good data
            log_data <- out_list$clean_data
            
            # Add filename to list of bad files
            bad_data_rows$data_file[k] = dat_file
            #  Add rejected rows to list of rejected entries for current data_file
            bad_data_rows$row_idx[k] = list(out_list$reject)
            
            # Increment the index for the reject list 
            k <- k+1
            
        }
        
        # Concatenate local data to main data storage variable
        bars_data <- bind_rows(bars_data, log_data)
        
        # Add instrument id
        bars_data <- bars_data %>% mutate(instrument_id = instrument_id_cur)
    }
    
    # Clean up
    closeAllConnections()
    
    #Get time out of date stored as text in first column
    bars_data <- bars_data %>% 
        mutate(time_stamp = strptime(Time,
                                     format = "%Y%m%dT%H%M%OS",
                                     tz = "GMT"))
    
    # Export 
    
    # Construct a date tag
    date_tag <- paste0(min(file_dates), "_", max(file_dates))
    # save processed data
    saveRDS(bars_data, 
            paste0("output/bars_data_", date_tag, ".rds"))
    # save rejected entry indices
    saveRDS(bad_data_rows, 
            paste0("output/rejected_rows_", date_tag, ".rds"))
    
    return(bad_data_rows)
    
}

