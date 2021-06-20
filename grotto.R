# Executive script to read downloaded data files

# Housekeeping
library(tidyverse)
library(plotly)

# get_data ----------------------------------------------------------------
# --> eventually replace this seciton with a data read statement that gets
#     data ouput from vent specific script

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
        
        # Read the data file
        file_to_read %>%
            readRDS() %>% 
            mutate(date_range)
        
    }) %>% 
    bind_rows()

data %>% saveRDS("output/grotto_app_data_bars.rds")

# Adjustable Parameters ---------------------------------------------------

# Individual data set to load. --------------------------------------------
# NOTE: Using discrete data sets improves speed (I think) (exclusive radio button)
date_range_var <- unique(data$date_range)[8]

# Get file date bounds
# NOTE: This will help with resricting time window to speed up plotting
date_range_bounds <- date_range_var %>% 
    str_split("_") %>% 
    unlist()

# Re-sampling -------------------------------------------------------------
# NOTE: sampling is one sample every 20 seconds, so 3 data points per minute
#       so keeping every third row, gives about 1 data point per minute, 
#       either slide or manual input (probably single slider)
keep_every_n_row <- 3 

# Re-sample data to make it more manageable (only if non-default value)
# NOTE: done by data_range tag to make sure original data sets are treated
#       equally regardless of number of data points
if(keep_every_n_row != 1) {
    data <- data %>% 
        group_by(date_range) %>%
        mutate(rowid = row_number()) %>% 
        slice(which(rowid %% keep_every_n_row == 1)) %>% 
        ungroup()
}

# Time window -------------------------------------------------------------
# Maximum number of days to display, more results in slower plot generation 
max_window_days <- 7

# Time boundaries ---------------------------------------------------------
# NOTE: defaults to start date in individual dataset data_range tag
#       and 7 days after
t1 <- ymd(date_range_bounds[1], tz = "GMT")
t2 <- min(ymd(date_range_bounds[2], tz = "GMT"), t1 + days(max_window_days))

# Data Prep ---------------------------------------------------------------
# Melt the relevant columns
data_long <- data %>% 
    gather(key = data_type, 
           value = data_val,
           Ref_V,
           Ref_T,
           Hi_V,
           Hi_T)

# Counts for diagnostic purposes
# data_long %>% count(date_range) 

# units and location
# Might be easier to keep type and unit together
data_long <- data_long %>% 
    separate(data_type, 
             into = c("loc", "unit"), 
             sep = "_", 
             remove = FALSE)

# Filter to time range
data_long_chunk <- data_long %>% 
    select(time_stamp,
           data_val,
           loc,
           unit, 
           data_type) %>% 
    filter(time_stamp >= t1,
           time_stamp <= t2)

# Plotting ----------------------------------------------------------------
# Make time series plot with plotly
voltage_temp_time_series <- data_long_chunk %>% 
    mutate(data_type = factor(data_type, levels = c("Hi_T", "Ref_T", "Hi_V", "Ref_V"))) %>% 
    mutate_at(vars(c("loc", "unit")), factor) %>% 
    group_by(data_type) %>% 
    # sample_n(20) %>% # Helps with development so graphics generate more quickly
    do(p = plot_ly(., 
                   x = ~time_stamp, 
                   y = ~data_val, 
                   color = ~data_type,
                   colors = "Dark2",
                   symbol = ~unit, 
                   symbols = c("circle", "square"),
                   type = "scatter", 
                   mode = "markers")) %>% 
    subplot(nrows = 2, shareX = TRUE) %>% 
    layout(
        annotations = list(
            list(x = 0.2 , y = 1, text = "Hi_T", showarrow = F, xref='paper', yref='paper'),
            list(x = 0.8 , y = 1, text = "Ref_T", showarrow = F, xref='paper', yref='paper'),
            list(x = 0.2 , y = 0.5, text = "Hi_V", showarrow = F, xref='paper', yref='paper'),
            list(x = 0.8 , y = 0.5, text = "Ref_V", showarrow = F, xref='paper', yref='paper')),
        
        # Y-axis custom labels
        yaxis = list(title = "A"),
        yaxis2 = list(title = "B"),
        yaxis3 = list(title = "C"),
        yaxis4 = list(title = "D"))
voltage_temp_time_series

# generate plot using ggplotly
# NOTE: code is more elegant but method is otherwise much slower.
# p <- data_long_chunk %>%
#     group_by(loc, unit) %>% # use if creating ggplot
#     ggplot(aes(x = time_stamp,
#                y = data_val)) +
#     geom_point() +
#     facet_wrap(~unit + loc,
#                nrow = 2,
#                scales = "free")
# p <- p %>% ggplotly()
# p
    
    