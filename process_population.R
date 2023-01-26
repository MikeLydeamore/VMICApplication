library(tidyverse)

age_bands <- tibble(
    age = seq(0, 80, by = 5)
) |>
    mutate(age_band = 1:n())

population <- read_csv("montagu_data/202212rfp-1_dds-202208_int_pop_both.csv") |>
    mutate(
        lower_age = if_else(
            age_from <= 80, age_from, 80
        ),
        lower_age = floor(lower_age / 5)*5
    ) |>
    group_by(
        country_code_numeric, country_code, country, year, gender, lower_age
    ) |>
    summarise(
        value = sum(value)
    ) |>
    group_by(
        year, country_code_numeric, country_code
    ) |>
    mutate(
        proportion = value / sum(value)
    )

# We want to set up the number of people of a given age in a given year, but
# only over the reporting years (2000-2100)

output_years <- seq(2000, 2100, by=1)

ages_by_year <- lapply(output_years, function(current_year) {
    population |>
        filter(year == current_year) |>
        mutate(proportion = value / sum(value))
}) |>
    bind_rows() |>
    left_join(age_bands, by=c("lower_age"="age"))

population_number <- 5000000
# No vax scenario: everyone is in NA
abm_input_vaccintion <- ages_by_year |>
    ungroup() |>
    select(
        age_band_id = age_band,
        num_people = proportion,
        year
    ) |>
    mutate(
        num_people = round(num_people * population_number),
        vaccine = NA,
        vaccine_dose_3 = NA,
        time_dose_1 = NA,
        time_dose_2 = NA,
        time_dose_3 = NA,
        time_dose_4 = NA
    ) |>
    relocate(
        num_people,
        .after = everything()
    )

lapply(split(abm_input_vaccintion, abm_input_vaccintion$year), function(df) {
    output_year <- unique(df$year)
    fname = here::here("abm_inputs", paste0("vmic_rollout_", output_year, ".csv"))
    write_csv(x = df |> select(-year), file = fname)
})
