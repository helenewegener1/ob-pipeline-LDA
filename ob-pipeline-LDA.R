## ============================================================
## 0. Install dependencies
## ============================================================
if (!require("flowCore")) install.packages("flowCore")
if (!require("MASS")) install.packages("MASS")
if (!require("devtools")) install.packages("devtools")

library(flowCore)
library(MASS)
library(devtools)
library(readr)

## ============================================================
## 1. Load CyTOF-Linear-Classifier functions from GitHub
## ============================================================
source_url("https://raw.githubusercontent.com/tabdelaal/CyTOF-Linear-Classifier/master/CyTOF_LDAtrain.R")
source_url("https://raw.githubusercontent.com/tabdelaal/CyTOF-Linear-Classifier/master/CyTOF_LDApredict.R")

## ============================================================
## 2. Specify paths to your data
##    Wrangle format at location to fit with the tool 
## ============================================================

train_x <- read.csv(file = "Documents/courses/Benchmarking/data/26_Levine/train_x.csv")
train_y <- read.csv(file = "Documents/courses/Benchmarking/data/26_Levine/train_y.csv")
test_x <- read.csv(file = "Documents/courses/Benchmarking/data/26_Levine/test_x.csv")
test_y <- read.csv(file = "Documents/courses/Benchmarking/data/26_Levine/test_y.csv")

RelevantMarkers_char <- colnames(train_x)
names(RelevantMarkers_char) <- 1:length(RelevantMarkers_char)
RelevantMarkers <- names(RelevantMarkers_char) %>% as.integer()

# Speficy paths 
TrainingSamplesExt <- "Documents/courses/Benchmarking/data/26_Levine/for_LDA/TrainingSamplesExt"
TrainingLabelsExt <- "Documents/courses/Benchmarking/data/26_Levine/for_LDA/TrainingLabelsExt"
TestingSamplesExt <- "Documents/courses/Benchmarking/data/26_Levine/for_LDA/TestingSamplesExt"
# TestingLabelsExt <- "Documents/courses/Benchmarking/data/26_Levine/for_LDA/TestingLabelsExt"

dirs <- c(TrainingSamplesExt, TrainingLabelsExt, TestingSamplesExt, TestingLabelsExt)

for (d in dirs) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    message("Created: ", d)
  } else {
    message("Exists: ", d)
  }
}

# Save without header
write_delim(
  x = train_x, 
  file = paste0(TrainingSamplesExt, "/train_x.csv"), 
  col_names = FALSE,
  delim = ","
)

write_delim(
  x = train_y, 
  file = paste0(TrainingLabelsExt, "/train_y.csv"), 
  col_names = FALSE,
  delim = ","
)

write_delim(
  x = test_x, 
  file = paste0(TestingSamplesExt, "/test_x.csv"), 
  col_names = FALSE,
  delim = ","
)

# list.files(path = "/Users/srz223/Documents/courses/Benchmarking/data/26_Levine/for_LDA/TrainingLabelsExt", pattern = '.csv',full.names = TRUE)

## ============================================================
## 4. Train LDA model
## ============================================================

cat("Training LDA model…\n")

LDAclassifier <- CyTOF_LDAtrain(
  TrainingSamplesExt = TrainingSamplesExt,
  TrainingLabelsExt = TrainingLabelsExt,
  mode = "CSV",
  RelevantMarkers = RelevantMarkers,
  # LabelIndex = FALSE,
  Transformation = FALSE
)

## ============================================================
## 5. Predict labels on test data
## ============================================================
cat("Predicting…\n")

RejectionThreshold <- 0.5 # set to something OR parameter

pred_labels_all <- CyTOF_LDApredict(
  Model = LDAclassifier,
  TestingSamplesExt = TestingSamplesExt,
  mode = "CSV",
  RejectionThreshold = RejectionThreshold
)


# Prep for eval
length(pred_labels_all[[1]])
test_y_char <- as.character(test_y$x)
length(test_y_char)

pred_labels <- pred_labels_all[[1]]
test_y_char

## ============================================================
## 6. Evaluate performance (if true labels available)
## ============================================================

cat("\nAccuracy:\n")
acc <- mean(pred_labels == test_y_char)
print(acc)

cat("\nConfusion matrix:\n")
print(table(Predicted = pred_labels, True = test_y_char))
