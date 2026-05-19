library(here)

nimdm <- read.csv(here("create_jsons/inputs/nimdm-2026-ranks-sdz-dummy-data.csv"))

df_data <- data.frame(
  geocode = nimdm$sdz2021_code,
  topic = "deprivation",
  year = 2017,
  category = case_when(
    nimdm$statistic == "Multiple Deprivation Measure (Rank)" ~ "mdm",
    nimdm$statistic == "Income Domain (Rank)" ~ "income",
    nimdm$statistic == "Proportion of the population living in households whose equivalised income is below 60 per cent of the NI median" ~ "below60",
    nimdm$statistic == "Employment Domain (18-64 years) (Rank)" ~ "employment",
    nimdm$statistic == "Proportion of the working age population who are employment deprived" ~ "emprop",
    nimdm$statistic == "Health Deprivation and Disability Domain (Rank)" ~ "health",
    nimdm$statistic == "Education, Skills and Training Domain (Rank)" ~ "education",
    nimdm$statistic == "Access to Services Domain (Rank)" ~ "services"
  ),
  count = NA,
  total = nimdm$value,
  perc = NA,
  value_rank = NA
)

area_profiles <- read.csv(here("create_jsons/inputs/area_profiles_long_table_dummy_withdz.csv")) %>% 
  select(geocode, geography) %>% 
  distinct()

df_data <- left_join(df_data, area_profiles, by = "geocode")

column_names <- colnames(df_data)

## get unique values of years and topics to loop around
for (i in 1:length(column_names)) {
  assign(paste0("v_", column_names[i]), unique(df_data[[i]]))
}