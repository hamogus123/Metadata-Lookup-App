library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(janitor)
library(lubridate)

# Read raw Excel file
raw_data <- read_excel("data/raw/08_genomic_metadata.xlsx") |>
  clean_names()

# Inspect data
glimpse(raw_data)
names(raw_data)
summary(raw_data)

# Standardize missing values
raw_data <- raw_data |>
  mutate(across(where(is.character), ~na_if(.x, ""))) |>
  mutate(across(where(is.character), ~na_if(.x, "NA"))) |>
  mutate(across(where(is.character), ~na_if(.x, "N/A")))

# Convert dates
raw_data <- raw_data |>
  mutate(
    dob = as.Date(dob),
    encounter_date = as.Date(encounter_date)
  )

# Clean coverage_mean
raw_data <- raw_data |>
  mutate(
    coverage_mean = str_remove(coverage_mean, "x"),
    coverage_mean = as.numeric(coverage_mean)
  )

# Clean text fields
raw_data <- raw_data |>
  mutate(
    sex = str_trim(sex),
    assay_type = str_trim(assay_type),
    tissue_type = str_trim(tissue_type),
    genome_build = str_trim(genome_build),
    ancestry = str_trim(ancestry)
  )

# Standardize sex values
raw_data <- raw_data |>
  mutate(
    sex = case_when(
      sex %in% c("Female", "F") ~ "F",
      sex %in% c("Male", "M") ~ "M",
      TRUE ~ sex
    )
  )

# Fill missing weight within same patient/encounter date
raw_data <- raw_data |>
  group_by(patient_id, encounter_date) |>
  fill(weight_kg, .direction = "downup") |>
  ungroup()

# Create patients table
patients <- raw_data |>
  select(patient_id, full_name, dob, sex, ancestry) |>
  distinct()

# Create encounters table
encounters <- raw_data |>
  select(patient_id, encounter_date, timepoint_relative, weight_kg) |>
  distinct() |>
  arrange(patient_id, encounter_date) |>
  mutate(encounter_id = row_number()) |>
  select(encounter_id, everything())

# Attach encounter IDs back to raw data
raw_with_encounter <- raw_data |>
  left_join(
    encounters |> select(encounter_id, patient_id, encounter_date),
    by = c("patient_id", "encounter_date")
  )

# Create samples table
samples <- raw_with_encounter |>
  select(sample_id, encounter_id, tissue_type, assay_type, file_path) |>
  distinct()

# Create genomic metadata table
genomic_metadata <- raw_with_encounter |>
  select(sample_id, genome_build, coverage_mean) |>
  distinct() |>
  filter(!is.na(genome_build) | !is.na(coverage_mean))

# Save processed CSV files
write.csv(patients, "data/processed/patients.csv", row.names = FALSE)
write.csv(encounters, "data/processed/encounters.csv", row.names = FALSE)
write.csv(samples, "data/processed/samples.csv", row.names = FALSE)
write.csv(genomic_metadata, "data/processed/genomic_metadata.csv", row.names = FALSE)