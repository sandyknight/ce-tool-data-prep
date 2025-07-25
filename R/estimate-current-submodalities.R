library(data.table)

estimate_current_submodalities <- function(lof_file = "data/LOF-number-in-treatment.csv",
                                           submod_file = "data/OU-submodality-proportions-by-area.csv",
                                           output_file = "data/estimated-tx-submodalities.csv") {
  
  lof_dt <-
    data.table::fread(lof_file)
  
  submod_dt <-
    data.table::fread(submod_file)
  
  # Set keys for efficient join
  data.table::setkey(lof_dt, utlacd)
  data.table::setkey(submod_dt, utla23cd)
  
  # Use data.table join syntax for better performance
  dt <- submod_dt[lof_dt, on = .(utla23cd = utlacd)]
  
  dt <-
    dt[, .(
      utlacd = utla23cd,
      local_authority,
      depot_buprenorphine = number_of_adults_in_treatment * phbudi_percent,
      oral_buprenorphine = number_of_adults_in_treatment * phbupren_percent,
      oral_methadone = number_of_adults_in_treatment * phmeth_percent
    )]
  
  dt <-
    dt[, lapply(.SD, as.integer),
      by = .(utlacd, local_authority),
      .SDcols = c(
        "depot_buprenorphine",
        "oral_buprenorphine",
        "oral_methadone"
      )
    ]
  
  data.table::fwrite(dt, output_file)
  
  return(dt)
}
