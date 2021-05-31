## R script for reading log files from  Ocean Networks Canada
This is a short R-script that reads the daily log files from the Benthic And Resistivity Sensors (BARS) instrument package installed on the underwater observatory run by Ocean Networks Canada. These log files contain the raw instrument output, and may include bad entries or instrument commands which are not easily read with R's standards data reading functions.

The files included in the repository are:

1. read_bars_logs.R - Main script, which reads complete files with no errors, and combines the data into a single storage array, which is written out to a csv file at the end.

2. read_bad_data.R - Handles files which contains entries that do not conform to the expected format. It uses a combination of the low level R function, readLines, and the try-catch feature to scavenge any good data available in the file. These entries are added to the main storage array. This function can be used for any file by adjusting read_cmd_opt input argument to the expected format of the data.

## Directions for Accssing log files

1. Start at Data Search Page: https://data.oceannetworks.ca/DataSearch

2. Find the Instrument of interest - https://data.oceannetworks.ca/DataSearch

3. Select the instrument of interest, this takes you to Data Product Selection 

4. Define date range

5. Select the log file check box

6. Checkout data product

7. Download data, will get 1 log file per day. This is what read_bars is designed to handle
