library(data.table)
source("R/get-utla-codes.R")

process_lof_tx_data <- function(input_file = "data/LOF-2025-05-31.csv",
                                output_file = "data/LOF-number-in-treatment.csv") {
  dt <- data.table::fread(input_file)

  data.table::setnames(dt, janitor::make_clean_names)

  dt <- dt[, .(local_authority, number_of_adults_in_treatment)]

  dt <-
    dt[,
      lapply(.SD, \(x) sum(as.integer(x), na.rm = TRUE)),
      by = local_authority,
      .SDcols = "number_of_adults_in_treatment"
    ]

  utlacodes <- get_utla_codes()

  # Set keys for efficient join
  data.table::setkey(dt, local_authority)
  data.table::setkey(utlacodes, utlanm)

  # Use data.table join syntax for better performance
  dt <- utlacodes[dt, on = .(utlanm = local_authority)]

  dt <- dt[, .(utlacd, utlanm, number_of_adults_in_treatment)]
  data.table::setnames(dt, "utlanm", "local_authority")

  data.table::fwrite(dt, output_file)

  return(dt)
}
