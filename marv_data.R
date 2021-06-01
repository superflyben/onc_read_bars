# Executive script to read downloaded data files

# Source the functions
source("read_bars_logs.R")

# Test case
# Will save the good stuff, just want to have a look at the bad
bad_data_rows <- read_bars_logs("raw_data/search20142943/")

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

# Start mining data 
for(data_dir_var in data_dir_df[8:9,'onc_search_id']) {
    read_bars_logs(data_dir_var)
}

