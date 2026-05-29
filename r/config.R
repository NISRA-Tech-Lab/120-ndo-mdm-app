library("dplyr")
library("readxl")
library("stringr")
library("jsonlite")

data_dir <- "r/data/"
output_dir <- "mdm_jsons/"
search_dir <- "search_data/"

geog_file <- "geog_data_withdz_and_area2.xlsx"
template_file <- "template - main_no_data.json"
latest_cpd_file <- "CPD_LIGHT_Jan26_quoted.csv"
search_data_filename <- "postcode_JAN2026.csv"

code_lookup <- list(
  "N92" = "ctry",
  "N09" = "lgd",  
  "N10" = "dea",  
  "N20" = "dz",   
  "N21" = "sdz"
)

stat_lookup <- list(
  "Multiple Deprivation Measure (Rank)" = "mdm",
  "Income Domain (Rank)" = "income",
  "Proportion of the population living in households whose equivalised income is below 60 per cent of the NI median" = "below60",
  "Employment Domain (18-64 years) (Rank)" = "employment",
  "Proportion of the working age population who are employment deprived" = "emprop",
  "Health Deprivation and Disability Domain (Rank)" = "health",
  "Education, Skills and Training Domain (Rank)" = "education",
  "Access to Services Domain (Rank)" = "services"
)
