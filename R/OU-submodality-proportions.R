library(data.table)

source("R/get-utla-codes.R")

calculate_ou_submodality_proportions <- function(
  sir_file = "data/SIR_table_for_VfM_linked.csv",
  main_file = "data/K3anon_FullDataset_for_VfM.csv",
  output_file = "data/OU-submodality-proportions-by-area.csv",
  target_year = 2024
) {
  dt <- data.table::fread(sir_file)

  submod <-
    dt[, .SD, .SDcols = c(
      "client_random_id",
      "n_jy",
      "submoddt",
      grep("_any", names(dt), value = TRUE)
    )]

  submod[, yr := data.table::year(submoddt)]

  submod <- submod[yr == target_year, ]

  submod <- submod[submoddt == max(submod[["submoddt"]]), ]

  main_dt <-
    data.table::fread(main_file)

  main_dt <-
    main_dt[, .(client_random_id, n_jy, utla23cd)]


  data.table::setkey(submod, client_random_id, n_jy)
  data.table::setkey(main_dt, client_random_id, n_jy)


  dt <- main_dt[submod, on = .(client_random_id, n_jy)]
  dt <- unique(dt)

  dt <-
    dt[,
      lapply(.SD, sum),
      by = utla23cd,
      .SDcols = c(
        "phbudi_any",
        "phbupren_any",
        "phmeth_any"
      )
    ]

  dt[, total := phbudi_any + phbupren_any + phmeth_any, ]

  utla_codes <- get_utla_codes()


  # Optimize second join
  data.table::setkey(dt, utla23cd)
  data.table::setkey(utla_codes, utlacd)

  dt <- utla_codes[dt, on = .(utlacd = utla23cd)]

  dt <- dt[, .(utla23cd = utlacd, utlanm, phbudi_any, phbupren_any, phmeth_any, total)]

  dt[, `:=`(
    phbudi_percent = phbudi_any / total,
    phbupren_percent = phbupren_any / total,
    phmeth_percent = phmeth_any / total
  )]

  dt_proportions <-
    dt[, .SD, .SDcols = c(
      "utla23cd",
      "utlanm",
      grep("percent", names(dt), value = TRUE)
    )]

  data.table::fwrite(
    dt_proportions,
    output_file
  )

  return(dt_proportions)
}
