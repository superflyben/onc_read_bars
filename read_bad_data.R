#Script to try a read command, and if it fails, invoke read line by line,
#keeping the good ones in one variable and a record of the bad indices in a
#separate variable

read_bad_data <- function(file_name, read_cmd_opt) {
    #Read data in with low-level function

    con = gzfile(file_name)
    data_lines <- readLines(con)

    #Initiate local storage variables and indices
    good_read <- c()
    bad_idx <- c()

    #Loop over all lines
    for(i in seq_along(data_lines)) {
        #Construct read command
        read_cmd_full <- c("read.table(text = data_lines[i]", read_cmd_opt)

        #Attempt read command
        #NOTE: try portion returns last evaluated expression if successful,
        #   this means can't use a counter inside the try part: if before the
        #   expr., counter may be incremented even without success evaluating
        #   expr, if after the expr, tryCatch will return value of counter
        out <- tryCatch(
            {
                eval(parse(text = read_cmd_full))

            },
            error = function(cond) {
                return(NA)
            },
            finally = {
                #Show progress
                #message()
            }
        )
        if(!anyNA(out)) {
            #Bind successful read to storage variable
            good_read <- rbind(good_read,out)
        }
        else {
            #Add index of bad entry to storage variable
            bad_idx <- c(bad_idx,i)
        }
    }
    close(con)
    #Store all output in list for transfer to calling function
    out_list <- list(clean_data = good_read, reject = bad_idx)
}

