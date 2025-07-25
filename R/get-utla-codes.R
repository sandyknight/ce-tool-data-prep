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

    lkp25 <-
      sgapi::get_table_link_lookup(
        lookup_table = "LAD25_CTYUA25_EW_LU_v2",
        "CTYUA25NM",
        "LAD25NM",
        "CTYUA25CD",
        "LAD25CD"
      )

    data.table::setDT(lkp24)
    data.table::setDT(lkp25)

    pull_utla_codes <- function(table_link) {
      data.table::setDT(table_link)

      table_link <- unique(table_link[, .(con_name_large, con_code_large)])

      table_link <- table_link[grep("^E", con_code_large), ]

      table_link
    }

    utla_codes24 <- pull_utla_codes(lkp24)
    utla_codes25 <- pull_utla_codes(lkp25)

    utla_codes <-
      data.table::rbindlist(l = list(
        utla_codes24,
        utla_codes25
      ))

    data.table::setnames(utla_codes, c("utlanm", "utlacd"))

    utla_codes <- unique(utla_codes)
  }


utla_codes <- get_utla_codes()

utla_codes
