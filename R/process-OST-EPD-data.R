library(data.table)
source("R/get-utla-codes.R")

process_ost_epd_data <- function(
  ost_file = "data/OST-may-2025.csv",
  postcode_file = "data/ONS-postcodes-lookup.csv",
  output_file = "data/EPD-OST-UTLA-cost.csv"
) {

  dt <- data.table::fread(ost_file)

  dt <-
    dt[, .(
      YEAR_MONTH,
      POSTCODE = gsub(
        pattern = " ",
        replacement = "",
        POSTCODE
      ),
      CHEMICAL_SUBSTANCE_BNF_DESCR,
      BNF_DESCRIPTION,
      ACTUAL_COST,
      ITEMS,
      QUANTITY,
      TOTAL_QUANTITY
    )]

  dt <- dt[nchar(POSTCODE) > 5, ]

  postcode_lkp <-
    data.table::fread(postcode_file)


  data.table::setkey(dt, POSTCODE)
  data.table::setkey(postcode_lkp, pcd2)


  dt <- dt[postcode_lkp, on = .(POSTCODE = pcd2)]

  utla_codes <- get_utla_codes()
  data.table::setkey(dt, utla)
  data.table::setkey(utla_codes, utlacd)

  dt <- dt[utla_codes, on = .(utla = utlacd)]

  dt <-
    dt[, .(
      YEAR_MONTH,
      utla,
      utlanm,
      CHEMICAL_SUBSTANCE_BNF_DESCR,
      BNF_DESCRIPTION,
      ACTUAL_COST,
      ITEMS,
      QUANTITY,
      TOTAL_QUANTITY,
      TOTAL_COST = ITEMS * ACTUAL_COST
    )]

  dt[, submod := data.table::fcase(
    CHEMICAL_SUBSTANCE_BNF_DESCR == "Methadone hydrochloride",
    "Methadone",
    CHEMICAL_SUBSTANCE_BNF_DESCR == "Buprenorphine hydrochloride" & grepl(
      pattern = "sublingual|oral",
      BNF_DESCRIPTION,
      ignore.case = TRUE
    ),
    "Oral buprenorphine",
    CHEMICAL_SUBSTANCE_BNF_DESCR == "Buprenorphine hydrochloride" & grepl(
      pattern = "inj|prolonged|syringe|pfs",
      BNF_DESCRIPTION,
      ignore.case = TRUE
    ),
    "Depot buprenorphine"
  )]

  dt <-
    dt[, lapply(.SD, sum), by = .(utla, utlanm, submod), .SDcols = "TOTAL_COST"]

  data.table::fwrite(dt, output_file)

  dt
}
