library(shiny)
library(DBI)
library(RSQLite)
library(DT)

ui <- fluidPage(
  titlePanel("Metadata Lookup App"),
  
  sidebarLayout(
    sidebarPanel(
      p("Search by Patient ID or Sample ID"),
      textInput("patient_id", "Enter Patient ID:"),
      textInput("sample_id", "Enter Sample ID:"),
      actionButton("search_btn", "Search"),
      br(), br()
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Patient Info", DTOutput("patient_table")),
        tabPanel("Encounters", DTOutput("encounter_table")),
        tabPanel("Samples", DTOutput("sample_table")),
        tabPanel("Genomic Metadata", DTOutput("genomic_table"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  con <- dbConnect(SQLite(), "metadata_lookup.sqlite")
  
  results <- eventReactive(input$search_btn, {
    patient_id <- trimws(input$patient_id)
    sample_id <- trimws(input$sample_id)
    
    patient_result <- data.frame()
    encounter_result <- data.frame()
    sample_result <- data.frame()
    genomic_result <- data.frame()
    
    if (patient_id != "") {
      patient_result <- dbGetQuery(
        con,
        sprintf("SELECT * FROM patients WHERE patient_id = '%s'", patient_id)
      )
      
      encounter_result <- dbGetQuery(
        con,
        sprintf("SELECT * FROM encounters WHERE patient_id = '%s'", patient_id)
      )
      
      sample_result <- dbGetQuery(
        con,
        sprintf(
          "SELECT s.* 
           FROM samples s
           JOIN encounters e ON s.encounter_id = e.encounter_id
           WHERE e.patient_id = '%s'",
          patient_id
        )
      )
      
      genomic_result <- dbGetQuery(
        con,
        sprintf(
          "SELECT g.*
           FROM genomic_metadata g
           JOIN samples s ON g.sample_id = s.sample_id
           JOIN encounters e ON s.encounter_id = e.encounter_id
           WHERE e.patient_id = '%s'",
          patient_id
        )
      )
      
    } else if (sample_id != "") {
      sample_result <- dbGetQuery(
        con,
        sprintf("SELECT * FROM samples WHERE sample_id = '%s'", sample_id)
      )
      
      genomic_result <- dbGetQuery(
        con,
        sprintf("SELECT * FROM genomic_metadata WHERE sample_id = '%s'", sample_id)
      )
    }
    
    list(
      patient_result = patient_result,
      encounter_result = encounter_result,
      sample_result = sample_result,
      genomic_result = genomic_result
    )
  })
  
  output$patient_table <- renderDT({
    req(results())
    datatable(results()$patient_result)
  })
  
  output$encounter_table <- renderDT({
    req(results())
    datatable(results()$encounter_result)
  })
  
  output$sample_table <- renderDT({
    req(results())
    datatable(results()$sample_result)
  })
  
  output$genomic_table <- renderDT({
    req(results())
    datatable(results()$genomic_result)
  })
  
  session$onSessionEnded(function() {
    dbDisconnect(con)
  })
}

shinyApp(ui = ui, server = server)