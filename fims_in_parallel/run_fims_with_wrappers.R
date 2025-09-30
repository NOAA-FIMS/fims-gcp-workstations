setup_and_run_FIMS_with_wrappers <- function(iter_id,
                                             om_input_list,
                                             om_output_list,
                                             em_input_list,
                                             estimation_mode = TRUE,
                                             map = list()) {
  # Load operating model data for the current iteration
  om_input <- om_input_list[[iter_id]]
  om_output <- om_output_list[[iter_id]]
  em_input <- em_input_list[[iter_id]]

  # Clear any previous FIMS settings
  clear()

  data <- FIMS::FIMSFrame(data1)

  # Set up default parameters
  fleets <- list(
    fleet1 = list(
      selectivity = list(form = "LogisticSelectivity"),
      data_distribution = c(
        Index = "DlnormDistribution",
        AgeComp = "DmultinomDistribution",
        LengthComp = "DmultinomDistribution"
      )
    ),
    survey1 = list(
      selectivity = list(form = "LogisticSelectivity"),
      data_distribution = c(
        Index = "DlnormDistribution",
        AgeComp = "DmultinomDistribution",
        LengthComp = "DmultinomDistribution"
      )
    )
  )

  default_parameters <- data |>
    create_default_parameters(
      fleets = fleets,
      recruitment = list(
        form = "BevertonHoltRecruitment",
        process_distribution = c(log_devs = "DnormDistribution")
      ),
      growth = list(form = "EWAAgrowth"),
      maturity = list(form = "LogisticMaturity")
    )

  # Modify parameters
  modified_parameters <- list(
    fleet1 = list(
      LogisticSelectivity.inflection_point.value = om_input[["sel_fleet"]][["fleet1"]][["A50.sel1"]],
      LogisticSelectivity.slope.value = om_input[["sel_fleet"]][["fleet1"]][["slope.sel1"]],
      Fleet.log_Fmort.value = log(om_output[["f"]])
    ),
    survey1 = list(
      LogisticSelectivity.inflection_point.value = om_input[["sel_survey"]][["survey1"]][["A50.sel1"]],
      LogisticSelectivity.slope.value = om_input[["sel_survey"]][["survey1"]][["slope.sel1"]],
      Fleet.log_q.value = log(om_output[["survey_q"]][["survey1"]])
    ),
    recruitment = list(
      BevertonHoltRecruitment.log_rzero.value = log(om_input[["R0"]]),
      BevertonHoltRecruitment.log_devs.value = om_input[["logR.resid"]][-1],
      BevertonHoltRecruitment.log_devs.estimated = FALSE,
      DnormDistribution.log_sd.value = om_input[["logR_sd"]]
    ),
    maturity = list(
      LogisticMaturity.inflection_point.value = om_input[["A50.mat"]],
      LogisticMaturity.inflection_point.estimated = FALSE,
      LogisticMaturity.slope.value = om_input[["slope.mat"]],
      LogisticMaturity.slope.estimated = FALSE
    ),
    population = list(
      Population.log_init_naa.value = log(om_output[["N.age"]][1, ])
    )
  )

  parameters <- default_parameters |>
    update_parameters(
      modified_parameters = modified_parameters
    )

  parameter_list <- initialize_fims(
    parameters = parameters,
    data = data
  )

  fit <- fit_fims(parameter_list, optimize = estimation_mode)

  clear()
  # Return the results as a list
  return(fit)
}