source("r/config.R")

# Import geographical information ####

geog_levels <- read_excel(paste0(data_dir, geog_file),
                          sheet = "Number of Geogs")

children <- read_excel(paste0(data_dir, geog_file), 
                       sheet = "ParentChild") %>%
  mutate(ChildName = case_when(grepl("_", ChildName) ~ ChildName,
                               TRUE ~ gsub(" And "," and ", str_to_title(ChildName)))) %>%
  rename(code = ChildCode,
         name = ChildName,
         parent_code = ParentCode) %>% 
  mutate(type = unlist(code_lookup[substr(code, 1, 3)])) %>% 
  filter(type != "dz")

grandparent_lookup <- children %>% 
  select(parent_code = code, grandparent_code = parent_code)

children <- left_join(
  children,
  grandparent_lookup,
  by = "parent_code"
)


map_bounds <- read_excel(paste0(data_dir, geog_file),
                         sheet = "MapBounds") %>%
  rename(geog = "...1") 


hectares <- read_excel(paste0(data_dir, geog_file),
                       sheet = "geog_areas")

dea_description <- read_excel(paste0(data_dir, geog_file),
                              sheet = "dea_description")

lgd_description <- read_excel(paste0(data_dir, geog_file),
                              sheet = "lgd_description")


# Import dummy data ####

nimdm <- read.csv("r/data/nimdm-2026-ranks-sdz-dummy-data.csv")

## LGD JSONs to contain ranks of all SDZ ####

LGDs <- children %>% 
  filter(type == "lgd") %>% 
  pull("code")

lgd_count <- geog_levels %>% 
  filter(geog_code == "lgd") %>% 
  pull("number")

for (lgd in LGDs) {
  
  cat("Processing Local Government District", lgd, "...", which(LGDs == lgd), "of", lgd_count, "\n\n")

  lgd_children <- list()
  
  child_rows <- children %>% 
    filter(parent_code == lgd)
  
  for (i in 1:nrow(child_rows)) {
    lgd_children[[i]] <- list(
      code = child_rows$code[i],
      name = child_rows$name[i],
      type = child_rows$type[[i]]
    )
  }
  
  lgd_bounds <- map_bounds %>% 
    filter(geog_code == lgd)
  
  lgd_data <- list(
    code = lgd,
    name = children$name[children$code == lgd],
    comment = "This json includes data for the MDM app.",
    type = "lgd",
    parents = list(
      list(code = "N92000002",
           name = "Northern Ireland",
           type = "ctry")
    ),
    children = lgd_children,
    bounds = c(
      c(lgd_bounds$long_max, lgd_bounds$lat_min),
      c(lgd_bounds$long_min, lgd_bounds$lat_max)
    ),
    data = list()
  )
  
  assign(paste0(lgd, "_data"), lgd_data)
  
}

## DEA JSONs to contain ranks of all SDZ ####

DEAs <- children %>% 
  filter(type == "dea") %>% 
  pull("code")

dea_count <- geog_levels %>% 
  filter(geog_code == "dea") %>% 
  pull("number")

for (dea in DEAs) {
  
  cat("Processing District Electoral Area", dea, "...", which(DEAs == dea), "of", dea_count, "\n\n")
  
  dea_info <- children %>% 
    filter(code == dea)
  
  dea_children <- list()
  
  child_rows <- children %>% 
    filter(parent_code == dea)
  
  for (i in 1:nrow(child_rows)) {
    dea_children[[i]] <- list(
      code = child_rows$code[i],
      name = child_rows$name[i],
      type = child_rows$type[[i]]
    )
  }
  
  dea_bounds <- map_bounds %>% 
    filter(geog_code == dea)
  
  dea_data <- list(
    code = dea,
    name = children$name[children$code == dea],
    comment = "This json includes data for the MDM app",
    type = "dea",
    count = dea_count,
    parents = list(
      list(code = dea_info$parent_code,
           name = children %>% 
             filter(code == dea_info$parent_code) %>% 
             pull("name"),
           type = "lgd"),
      list(code = "N92000002",
           name = "Northern Ireland",
           type = "ctry")
    ),
    children = dea_children,
    bounds = c(
      c(dea_bounds$long_max, dea_bounds$lat_min),
      c(dea_bounds$long_min, dea_bounds$lat_max)
    ),
    data = list()
  )
  
  assign(paste0(dea, "_data"), dea_data)
  
}

## SDZ JSONs to contain ranks of individual data ####

SDZs <- children %>% 
  filter(type == "sdz") %>% 
  pull("code")

sdz_count <- geog_levels %>% 
  filter(geog_code == "sdz") %>% 
  pull("number")


for (sdz in SDZs) {
  
  cat("Processing Super Data Zone:", sdz, "...", which(SDZs == sdz), "of", sdz_count, "\n\n")
  
  sdz_info <- children %>% 
    filter(code == sdz)
  
  sdz_bounds <- map_bounds %>% 
    filter(geog_code == sdz)
  
  sdz_ranks <- nimdm %>% 
    filter(sdz2021_code == sdz) %>% 
    mutate(stat = stat_lookup[statistic])
  
  sdz_data_values <- list()
  
  for (i in 1:nrow(sdz_ranks)) {
    sdz_data_values[sdz_ranks$stat[[i]]] <- sdz_ranks$value[i]
  }
  
  sdz_data <- list(
    code = sdz,
    name = sdz_info$name,
    comment = "This json includes data for the MDM app",
    type = "sdz",
    count = sdz_count,
    parents = list(
      list(code = sdz_info$parent_code,
           name = children %>% 
             filter(code == sdz_info$parent_code) %>% 
             pull("name"),
           type = "dea"),
      list(code = sdz_info$grandparent_code,
           name = children %>% 
             filter(code == sdz_info$grandparent_code) %>% 
             pull("name"),
           type = "lgd"),
      list(code = "N92000002",
           name = "Northern Ireland",
           type = "ctry")
    ),
    children = list(),
    bounds = c(
      c(sdz_bounds$long_max, sdz_bounds$lat_min),
      c(sdz_bounds$long_min, sdz_bounds$lat_max)
    ),
    data = sdz_data_values
  )
  
  write_json(sdz_data,
             paste0(output_dir, sdz, ".json"),
             auto_unbox = TRUE,
             pretty = TRUE)
  
  lgd_data <- get(paste0(sdz_info$grandparent_code, "_data"))
  dea_data <- get(paste0(sdz_info$parent_code, "_data"))
  
  lgd_data$data[[sdz]] <- sdz_data_values
  dea_data$data[[sdz]] <- sdz_data_values
  
  assign(paste0(sdz_info$grandparent_code, "_data"), lgd_data)
  assign(paste0(sdz_info$parent_code, "_data"), dea_data)
  
}

# Write out LGD and DEA JSONs ####

for (lgd in LGDs) {
  
  
  write_json(get(paste0(lgd, "_data")),
             paste0(output_dir, lgd, ".json"),
             auto_unbox = TRUE,
             pretty = TRUE)
  
cat("Writing data for Local Government District", lgd, "...", which(LGDs == lgd), "of", lgd_count, "\n\n")

}

for (dea in DEAs) {
  
  write_json(get(paste0(dea, "_data")),
             paste0(output_dir, dea, ".json"),
             auto_unbox = TRUE,
             pretty = TRUE)
  
  cat("Writing data for District Electoral Area", dea, "...", which(DEAs == dea), "of", dea_count, "\n\n")
  
}

