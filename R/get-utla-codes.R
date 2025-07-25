library(sgapi)
library(data.table)

get_utla_codes <-
  function() {
    lkp24 <-
      sgapi::get_table_link_lookup(
        lookup_table = "LAD24_CTYUA24_EW_LU",
        "CTYUA24NM",
        "LAD24NM",
        "CTYUA24CD",
        "LAD24CD"
      )


    data.table::setDT(lkp24)
    pull_utla_codes <- function(table_link) {
      data.table::setDT(table_link)

      table_link <- unique(table_link[, .(con_name_large, con_code_large)])

      table_link <- table_link[grep("^E", con_code_large), ]

      table_link
    }

    utla_codes <- pull_utla_codes(lkp24)

    data.table::setnames(utla_codes, c("utlanm", "utlacd"))

    utla_codes
  }
