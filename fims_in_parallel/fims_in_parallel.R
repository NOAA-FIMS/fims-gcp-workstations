# Our user account doesn't have permission to install R packages into the main
# system-wide R folder. We need to create a personal package library in the home
# directory and tell R to use it.
# mkdir -p ~/R/bai-li-library/4.4
# echo 'R_LIBS_USER="~/R/bai-li-library/4.4"' >> ~/.Renviron

# install.packages("FIMS", repos = c("https://noaa-fims.r-universe.dev", "https://cloud.r-project.org"))
devtools::install_github(
  "NOAA-FIMS/FIMS",
  ref = "2338d23eda72676ba3ac79dc8007ecec600979a6"
)
# Create simulated data using operating model from model comparison project ----
check_ASSAMC <- function() {
  packages_all <- .packages(all.available = TRUE)
  if (!"ASSAMC" %in% packages_all) {
    remotes::install_github(
      "NOAA-FIMS/Age_Structured_Stock_Assessment_Model_Comparison"
    )
  }
  library("ASSAMC")
  return(TRUE)
}

check_ASSAMC()

library(FIMS)
library(dplyr)
library(snowfall)
library(parallel)
library(furrr)
library(future)

###############################################################################
# Simulate the data
###############################################################################
working_dir <- file.path(getwd(), "fims_in_parallel")

main_dir <- tempdir()

# Save the initial OM input using ASSAMC package (sigmaR = 0.4)
model_input <- ASSAMC::save_initial_input()

# Configure the input parameters for the simulation
sim_num <- 100
sim_input <- ASSAMC::save_initial_input(
  base_case = TRUE,
  input_list = model_input,
  maindir = main_dir,
  om_sim_num = sim_num,
  keep_sim_num = sim_num,
  figure_number = 1,
  seed_num = 9924,
  case_name = "sim_data"
)

# Run OM and generate om_input, om_output, and em_input
# using function from the model comparison project
ASSAMC::run_om(input_list = sim_input)

setwd(working_dir)

# Helper function to calculate length at age using the von Bertalanffy growth model
# a: current age
# Linf: asymptotic average length
# K: Growth coefficient
# a_0: Theoretical age at size zero
AtoL <- function(a, Linf, K, a_0) {
  L <- Linf * (1 - exp(-K * (a - a_0)))
}

# Initialize lists for operating model (OM) and estimation model (EM) inputs and outputs
om_input_list <- om_output_list <- em_input_list <-
  vector(mode = "list", length = sim_num)

# Loop through each simulation to generate length data
for (iter in 1:sim_num) {
  # Load the OM data for the current simulation
  load(file.path(main_dir, "sim_data", "output", "OM", paste0("OM", iter, ".RData")))

  # Extract von Bertalanffy growth model parameters from the OM input
  Linf <- om_input[["Linf"]]
  K <- om_input[["K"]]
  a0 <- om_input[["a0"]]
  amax <- max(om_input[["ages"]])
  # Define coefficient of variation for length-at-age
  cv <- 0.1
  # Extract length-weight coefficient from OM
  L2Wa <- om_input[["a.lw"]]
  # Extract length-weight exponent from OM
  L2Wb <- om_input[["b.lw"]]

  # Extract age bins from the OM input
  ages <- om_input[["ages"]]
  # Define length bins in intervals of 50
  len_bins <- seq(0, 1100, 50)

  # Create length at age conversion matrix and fill proportions using above
  # growth parameters
  age_to_length_conversion <- matrix(NA, nrow = length(ages), ncol = length(len_bins))
  for (age in seq_along(ages)) {
    # Calculate mean length at age to spread lengths around
    mean_length <- AtoL(ages[age], Linf, K, a0)
    # mean_length <- AtoLSchnute(ages[age],L1,L2,a1,a2,Ks)
    # Calculate the cumulative proportion shorter than each composition length
    temp_len_probs <- pnorm(q = len_bins, mean = mean_length, sd = mean_length * cv)
    # Reset the first length proportion to zero so the first bin includes all
    # density smaller than that bin
    temp_len_probs[1] <- 0
    # subtract the offset length probabilities to calculate the proportion in each
    # bin. For each length bin the proportion is how many fish are larger than this
    # length but shorter than the next bin length.
    temp_len_probs <- c(temp_len_probs[-1], 1) - temp_len_probs
    age_to_length_conversion[age, ] <- temp_len_probs
  }
  colnames(age_to_length_conversion) <- len_bins
  rownames(age_to_length_conversion) <- ages

  # Loop through each simulation to load the results from the corresponding
  # .RData files
  # Assign the conversion matrix and other information to the OM input
  om_input[["lengths"]] <- len_bins
  om_input[["nlengths"]] <- length(len_bins)
  om_input[["cv.length_at_age"]] <- cv
  om_input[["age_to_length_conversion"]] <- age_to_length_conversion

  om_output[["L.length"]] <- list()
  om_output[["survey_length_comp"]] <- list()
  om_output[["N.length"]] <- matrix(0, nrow = om_input[["nyr"]], ncol = length(len_bins))
  om_output[["L.length"]][["fleet1"]] <- matrix(0, nrow = om_input[["nyr"]], ncol = length(len_bins))
  om_output[["survey_length_comp"]][["survey1"]] <- matrix(0, nrow = om_input[["nyr"]], ncol = length(len_bins))

  em_input[["L.length.obs"]] <- list()
  em_input[["survey.length.obs"]] <- list()
  em_input[["L.length.obs"]][["fleet1"]] <- matrix(0, nrow = om_input[["nyr"]], ncol = length(len_bins))
  em_input[["survey.length.obs"]][["survey1"]] <- matrix(0, nrow = om_input[["nyr"]], ncol = length(len_bins))

  em_input[["lengths"]] <- len_bins
  em_input[["nlengths"]] <- length(len_bins)
  em_input[["cv.length_at_age"]] <- cv
  em_input[["age_to_length_conversion"]] <- age_to_length_conversion
  em_input[["n.L.lengthcomp"]][["fleet1"]] <- em_input[["n.survey.lengthcomp"]][["survey1"]] <- 200

  # Populate length-based outputs for each year, length bin, and age
  for (i in seq_along(om_input[["year"]])) {
    for (j in seq_along(len_bins)) {
      for (k in seq_along(om_input[["ages"]])) {
        # Calculate numbers and landings at length for each fleet and survey
        om_output[["N.length"]][i, j] <- om_output[["N.length"]][i, j] +
          age_to_length_conversion[k, j] *
            om_output[["N.age"]][i, k]

        om_output[["L.length"]][[1]][i, j] <- om_output[["L.length"]][[1]][i, j] +
          age_to_length_conversion[k, j] *
            om_output[["L.age"]][[1]][i, k]

        om_output[["survey_length_comp"]][[1]][i, j] <- om_output[["survey_length_comp"]][[1]][i, j] +
          age_to_length_conversion[k, j] *
            om_output[["survey_age_comp"]][[1]][i, k]

        em_input[["L.length.obs"]][[1]][i, j] <- em_input[["L.length.obs"]][[1]][i, j] +
          age_to_length_conversion[k, j] *
            em_input[["L.age.obs"]][[1]][i, k]

        em_input[["survey.length.obs"]][[1]][i, j] <- em_input[["survey.length.obs"]][[1]][i, j] +
          age_to_length_conversion[k, j] *
            em_input[["survey.age.obs"]][[1]][i, k]
      }
    }
  }

  # Save updated inputs and outputs to file
  save(
    om_input, om_output, em_input,
    file = file.path(main_dir, "sim_data", "output", "OM", paste0("OM", iter, ".RData"))
  )
  # Store inputs and outputs in respective lists
  om_input_list[[iter]] <- om_input
  om_output_list[[iter]] <- om_output
  em_input_list[[iter]] <- em_input
}

# Save all simulations to a single file for {testthat} integration tests
save(
  om_input_list, om_output_list, em_input_list,
  file = file.path(working_dir, "integration_test_data.RData")
)

# Load the model comparison operating model data from the fixtures folder
load(file.path(working_dir, "integration_test_data.RData"))

source(file.path(getwd(), "run_fims_with_wrappers.R"))
sim_num <- 100
# Run FIMS ----
# Run the FIMS model in serial ----
cat("--- Starting Serial Execution ---\n")

# Capture the start time
start_time_serial <- Sys.time()
estimation_results_serial <- vector(mode = "list", length = sim_num)

for (i in 1:sim_num) {
  estimation_results_serial[[i]] <- setup_and_run_FIMS_with_wrappers(
    iter_id = i,
    om_input_list = om_input_list,
    om_output_list = om_output_list,
    em_input_list = em_input_list,
    estimation_mode = TRUE
  )
}
# Capture the end time
end_time_serial <- Sys.time()

# Calculate the difference
serial_duration <- end_time_serial - start_time_serial

cat("Serial execution finished.\n")
serial_duration

# Run FIMS in parallel with snowfall ----
cat("\n--- Starting Parallel Execution ---\n")

core_num <- parallel::detectCores()
snowfall::sfInit(parallel = TRUE, cpus = core_num/2)
# snowfall::sfInit(parallel = FALSE, cpus = core_num/2)

snowfall::sfLibrary(FIMS)
# Capture the start time
start_time_parallel <- Sys.time()

results_parallel <- snowfall::sfLapply(
  1:sim_num,
  setup_and_run_FIMS_with_wrappers,
  om_input_list,
  om_output_list,
  em_input_list,
  TRUE
)

# Capture the end time
end_time_parallel <- Sys.time()

snowfall::sfStop()

# Calculate the difference
parallel_duration <- end_time_parallel - start_time_parallel

cat("Parallel execution finished.\n")
parallel_duration


# Run FIMS in parallel with furrr ----
future::plan(multisession, workers = core_num / 2)
start_time_furrr <- Sys.time()
results_parallel <- future_map(
  .x = 1:sim_num,
  .f = setup_and_run_FIMS_with_wrappers,
  om_input_list = om_input_list,
  om_output_list = om_output_list,
  em_input_list = em_input_list,
  .options = furrr_options(seed = TRUE)
)
end_time_furrr <- Sys.time()
plan(sequential)
furrr_duration <- end_time_furrr - start_time_furrr
furrr_duration