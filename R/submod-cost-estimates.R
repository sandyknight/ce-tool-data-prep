library(data.table)

calculate_submod_cost_estimates <- function(cost_file = "data/EPD-OST-UTLA-cost.csv",
                                            tx_file = "data/estimated-tx-submodalities.csv",
                                            output_file = "data/estimated-tx-submodality-costs.csv") {
  
  cost_submod <-
    data.table::fread(cost_file)
  
  data.table::setnames(cost_submod, janitor::make_clean_names)
  
  cost_submod[, submod := snakecase::to_snake_case(submod)]
  
  tx_submod <-
    data.table::fread(tx_file)
  
  tx_submod <-
    data.table::melt(
      tx_submod,
      id.vars = c("utlacd", "local_authority"),
      measure.vars = c(
        "depot_buprenorphine",
        "oral_buprenorphine",
        "oral_methadone"
      ),
      value.name = "number_in_tx",
      variable.name = "ost_submodality",
      variable.factor = FALSE
    )
  
  tx_submod[, ost_submodality := data.table::fifelse(
    ost_submodality == "oral_methadone",
    "methadone",
    ost_submodality
  )]
  
  # Set keys for efficient join
  data.table::setkey(tx_submod, utlacd, local_authority, ost_submodality)
  data.table::setkey(cost_submod, utla, utlanm, submod)
  
  # Use data.table join syntax for better performance
  dt <- cost_submod[tx_submod, on = .(utla = utlacd, utlanm = local_authority, submod = ost_submodality)]
  
  dt[, cost_per_person := total_cost / number_in_tx]
  
  data.table::fwrite(dt, output_file)
  
  return(dt)
}
