library(DBI)
library(RSQLite)

# Connect to SQLite database
con <- dbConnect(SQLite(), "metadata_lookup.sqlite")

# Remove old tables if they already exist
if ("patients" %in% dbListTables(con)) dbRemoveTable(con, "patients")
if ("encounters" %in% dbListTables(con)) dbRemoveTable(con, "encounters")
if ("samples" %in% dbListTables(con)) dbRemoveTable(con, "samples")
if ("genomic_metadata" %in% dbListTables(con)) dbRemoveTable(con, "genomic_metadata")

# Write tables into the database
dbWriteTable(con, "patients", patients, overwrite = TRUE)
dbWriteTable(con, "encounters", encounters, overwrite = TRUE)
dbWriteTable(con, "samples", samples, overwrite = TRUE)
dbWriteTable(con, "genomic_metadata", genomic_metadata, overwrite = TRUE)

# Check that the tables were created
dbListTables(con)

# Preview tables
head(dbReadTable(con, "patients"))
head(dbReadTable(con, "encounters"))
head(dbReadTable(con, "samples"))
head(dbReadTable(con, "genomic_metadata"))

# Close connection
dbDisconnect(con)