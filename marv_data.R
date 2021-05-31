# Executive script to read downloaded data files

# Source the functions
source("read_bars_logs.R")

# Call the function with the raw data directory
# Will save the good stuff, just to have a look at the bad
bad_data_rows <- read_bars_logs("raw_data/search20142943/")
