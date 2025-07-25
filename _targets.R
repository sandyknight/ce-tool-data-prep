# LAB CE Tool data pipeline

# Load packages required to define the pipeline:
library(targets)
library(crew)

# Set target options:
tar_option_set(
  packages = c(
    "data.table",
    "jsonlite",
    "sgapi",
    "janitor",
    "snakecase",
    "dplyr",
    "qs"
  ),
  format = "qs",
  controller = crew::crew_controller_local(workers = 4, seconds_idle = 60)
)

# Load functions
tar_source()

# Define the pipeline:
list(
  # Fetch EPD data from API
  tar_target(
    name = epd_data,
    command = get_epd_data(month_year = "202412")
  ),

  # Process LOF treatment data
  tar_target(
    name = lof_treatment_data,
    command = process_lof_tx_data(
      input_file = "data/LOF-2025-05-31.csv",
      output_file = "data/LOF-number-in-treatment.csv"
    )
  ),

  # Calculate OU submodality proportions
  tar_target(
    name = ou_submodality_proportions,
    command = calculate_ou_submodality_proportions(
      sir_file = "data/SIR_table_for_VfM_linked.csv",
      main_file = "data/K3anon_FullDataset_for_VfM.csv",
      output_file = "data/OU-submodality-proportions-by-area.csv",
      target_year = 2024
    )
  ),

  # Process OST EPD data
  tar_target(
    name = ost_epd_processed,
    command = {
      epd_data
      process_ost_epd_data(
        ost_file = "data/OST-may-2025.csv",
        postcode_file = "data/ONS-postcodes-lookup.csv",
        output_file = "data/EPD-OST-UTLA-cost.csv"
      )
    }
  ),

  # Estimate current submodalities
  tar_target(
    name = estimated_submodalities,
    command = {
      lof_treatment_data
      ou_submodality_proportions
      estimate_current_submodalities(
        lof_file = "data/LOF-number-in-treatment.csv",
        submod_file = "data/OU-submodality-proportions-by-area.csv",
        output_file = "data/estimated-tx-submodalities.csv"
      )
    }
  ),

  # Calculate final cost estimates
  tar_target(
    name = submod_cost_estimates,
    command = {
      ost_epd_processed
      estimated_submodalities
      calculate_submod_cost_estimates(
        cost_file = "data/EPD-OST-UTLA-cost.csv",
        tx_file = "data/estimated-tx-submodalities.csv",
        output_file = "data/estimated-tx-submodality-costs.csv"
      )
    }
  )
)
