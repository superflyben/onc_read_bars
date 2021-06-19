# Executive script to read downloaded data files

# Housekeeping
library(tidyverse)

# Source the functions
source("read_bars_logs.R")

# Test case
# Will save the good stuff, just want to have a look at the bad
# bad_data_rows <- read_bars_logs("raw_data/search20142943/")

# Build a data frame to match search results to time periods
data_dir_df <- c("raw_data/search20345483/", "2011_10_01", "2011_11_12",
                 "raw_data/search20345484/", "2014_01_01", "2014_09_25",
                 "raw_data/search20354743/", "2015_09_08", "2015_12_31",
                 "raw_data/search20354744/", "2016_08_25", "2016_08_27",
                 "raw_data/search20354745/", "2017_11_05", "2017_12_31",
                 "raw_data/search20354746/", "2018_07_01", "2018_07_23",
                 "raw_data/search20354747/", "2019_10_01", "2019_10_31",
                 "raw_data/search20354751/", "2021_01_01", "2021_03_07",
                 "raw_data/search20354752/", "2020_01_01", "2020_12_31") %>% 
    matrix(ncol = 3, byrow = TRUE) %>% 
    data.frame() %>% 
    rename(onc_search_id = X1,
           start_date = X2,
           end_date = X3)

# Check to see what has already been processed
rds_files <- system("ls -al output/bars_data*.rds", intern = TRUE) %>% 
    str_extract("output/.*rds$")

# Start mining data 
for(i in 1:nrow(data_dir_df)) {
    
    # Show progress
    writeLines(paste0("Processing contents of : ", data_dir_df$onc_search_id[i]))
    
    # Construct the data file name to look for
    expected_output_file <- paste0("output/bars_data_", 
                                   gsub("_", "", data_dir_df$start_date[i]),
                                   "_",
                                   gsub("_", "", data_dir_df$end_date[i]),
                                   ".rds")
    
    if(expected_output_file %in% rds_files) {
        writeLines("Output already exists, moving to next file...")
        next
    }
    
    # If folder not processed, do so now
    read_bars_logs(data_dir_df$onc_search_id[i])

}

# Bind together all rds files with good data, tag with the date range

data <- rds_files %>% 
    lapply(function(file_to_read) {
        
        date_range <- file_to_read %>% 
            str_match("output/bars_data_(.*).rds") %>% 
            {.[,2]}
        
        print(paste0("Processing: ", date_range))
        
        file_to_read %>%
            readRDS() %>% 
            mutate(date_range)
        
    }) %>% 
    bind_rows()

head(data)
summary(data)


# Melt the relevant columns
data_long <- data %>% 
    gather(key = data_type, 
           value = data_val,
           Ref_V,
           Ref_T,
           Hi_V,
           Hi_T)

# Running into memory issues, may need to break the data down into time periods 
# or look into increasing memory 

# For starters, count the data points by segment, to see if there are reasonable
# ways to break it down
data_long %>% count(date_range) 

# A year's data is just too much, maybe restrict to 90 days
# And also need to force Voltage to share an axis, switch unit and loc

# units and location
data_long <- data_long %>% 
    separate(data_type, 
             into = c("loc", "unit"), 
             sep = "_")

# Restrict data to avoid memory issues
# --> Loop over individual data sets 
date_range_var <- unique(data_long$date_range)[8]
date_range_bounds <- date_range_var %>% 
    str_split("_") %>% 
    unlist()

t1 <- ymd(date_range_bounds[1], tz = "GMT")
t2 <- min(ymd(date_range_bounds[2], tz = "GMT"), t1 + days(30))

# Filter to time range
data_long_chunk <- data_long %>% 
    select(time_stamp, data_val, loc, unit) %>% 
    filter(time_stamp >= t1,
           time_stamp <= t2)

# generate plot with 
p <- data_long_chunk %>% 
    ggplot(aes(x = time_stamp, 
               y = data_val)) +
    geom_point() + 
    facet_wrap(~loc + unit, 
               nrow = 2, 
               scales = "free")
p    

