library(jsonlite)
library(data.table)

get_epd_data <- function(month_year, cache_hours = 24, use_cache = TRUE) {
  
  if (missing(month_year)) {
    stop("month_year parameter is required. Format: 'YYYYMM' (e.g., '202412')")
  }
  
  if (!grepl("^\\d{6}$", month_year)) {
    stop("month_year must be in format 'YYYYMM' (e.g., '202412')")
  }
  
  # Set up caching
  cache_dir <- "cache"
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  
  cache_file <- file.path(cache_dir, paste0("epd_data_", month_year, ".qs"))
  
  # Check if cached data exists and is recent enough
  if (use_cache && file.exists(cache_file)) {
    cache_age_hours <- as.numeric(difftime(Sys.time(), file.info(cache_file)$mtime, units = "hours"))
    if (cache_age_hours < cache_hours) {
      message("Using cached EPD data for ", month_year, " (", round(cache_age_hours, 1), " hours old)")
      return(qs::qread(cache_file))
    }
  }
  
  base_endpoint <- "https://opendata.nhsbsa.net/api/3/action/"
  action_method <- "datastore_search_sql?"
  
  resource_name <- paste0("EPD_", month_year)
  
  bnf_chemical_substances <- c(
    "0410030C0", # Methadone hydrochloride
    "0410030A0"  # Buprenorphine hydrochloride
  )
  
  get_substance_data <- function(substance_code) {
    query <- paste0(
      "SELECT * FROM `", resource_name, "` WHERE bnf_chemical_substance = '", substance_code, "'"
    )
    
    api_call <- paste0(
      base_endpoint,
      action_method,
      "resource_id=", resource_name,
      "&sql=", URLencode(query)
    )
    
    response <- jsonlite::fromJSON(api_call)
    return(response$result$result$records)
  }
  
  message("Fetching EPD data from API for ", month_year)
  methadone_df <- get_substance_data(bnf_chemical_substances[1])
  buprenorphine_df <- get_substance_data(bnf_chemical_substances[2])
  
  combined_dt <- data.table::rbindlist(list(methadone_df, buprenorphine_df))
  
  # Cache the result
  if (use_cache) {
    message("Caching EPD data for ", month_year)
    qs::qsave(combined_dt, cache_file)
  }
  
  return(combined_dt)
}
