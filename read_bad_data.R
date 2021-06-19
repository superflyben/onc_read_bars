# Function to read bad sections of data line by line, keeping the good ones in
# one variable and a record of the bad indices in a separate variable

read_bad_data <- function(file_w_bad_data) {
    
    # Connect to zip file in data directory 
    # NOTE: have to re-do this b/c even if read.table returns lines
    #       with NA, it will still close the connection, and even if it didn't
    #       file conneciton doesn't seem to survive the function call
    file_con <- gzfile(paste0(data_dir, "/", file_w_bad_data))
    
    # Read from connection with low-level function, and close the connection
    data_lines <- file_con %>% readLines()
    close(file_con)

    #Initiate local storage variables and indices
    good_read <- c()
    bad_idx <- c()

    #Loop over all lines
    for(i in seq_along(data_lines)) {
        
        # Show progress
        if(i == 1 | i %% 1000 == 0) {
            print(paste0("Row ", i, " of ", length(data_lines)))
        }
        
        # Attempt read command
        out <- tryCatch(
            
            {
                # Call function to read data 
                data_lines[i] %>% 
                    read.table(text = .,
                               col.names = bars_cols, 
                               colClasses = bars_class, 
                               stringsAsFactors = FALSE,
                               fill = TRUE)
            },
            error = function(cond) {
                return(NA)
            }
            
        )
        
        if(!anyNA(out)) {
            
            # Bind successful read to storage variable
            good_read <- bind_rows(good_read, out)
            
        } else {
            
            # If bad, add index of bad entry to storage variable
            bad_idx <- c(bad_idx,i)
            
        }
    }
    
    # Close connection and Store output in list for transfer to calling function
    out_list <- list(clean_data = good_read, 
                     reject = bad_idx)
}

