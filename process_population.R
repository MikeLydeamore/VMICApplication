library(tibble)
library(readr)
library(dplyr)

age_bands <- tibble(
    age = seq(0, 80, by = 5)
) %>%
    mutate(age_band = 1:n())

population <- read_csv("montagu_data/202212rfp-1_dds-202208_int_pop_both.csv") %>%
    mutate(
        lower_age = if_else(
            age_from <= 80, age_from, 80
        ),
        lower_age = floor(lower_age / 5) * 5
    ) %>%
    group_by(
        country_code_numeric, country_code, country, year, gender, lower_age
    ) %>%
    summarise(
        value = sum(value)
    ) %>%
    group_by(
        year, country_code_numeric, country_code
    ) %>%
    mutate(
        proportion = value / sum(value)
    )

# We want to set up the number of people of a given age in a given year, but
# only over the reporting years (2000-2100)

output_years <- seq(2000, 2100, by = 1)

ages_by_year <- lapply(output_years, function(current_year) {
    population %>%
        filter(year == current_year) %>%
        mutate(proportion = value / sum(value))
}) %>%
    bind_rows() %>%
    left_join(age_bands, by = c("lower_age" = "age"))

population_number <- 100000
# No vax scenario: everyone is in NA
abm_input_vaccintion <- ages_by_year %>%
    ungroup() %>%
    select(
        age_band_id = age_band,
        num_people = proportion,
        year
    ) %>%
    mutate(
        num_people = round(num_people * population_number),
        vaccine = NA,
        vaccine_dose_3 = NA,
        time_dose_1 = NA,
        time_dose_2 = NA,
        time_dose_3 = NA,
        time_dose_4 = NA
    ) %>%
    relocate(
        num_people,
        .after = everything()
    )

lapply(split(abm_input_vaccintion, abm_input_vaccintion$year), function(df) {
    output_year <- unique(df$year)
    fname <- here::here("abm_inputs", paste0("vmic_rollout_", output_year, ".csv"))
    write_csv(x = df %>% select(-year), file = fname)
})

vaccine_data <- read_csv("montagu_data/coverage_202212rfp-1_covid-booster-default.csv")

vaccine_data <- vaccine_data %>%
    group_by(age_first, year) %>%
    mutate(
        coverage = sum(coverage)
    )

get_vacc_coverage <- function(input_year, input_age) {
    vaccine_info <- vaccine_data %>%
        filter(year == input_year & age_first <= input_age)

    if (nrow(vaccine_info) == 0) {
        return(0)
    } else {
        coverage <- sum(vaccine_info$coverage)

        return(coverage)
    }
}

with_coverage <- ages_by_year %>%
    rowwise() %>%
    mutate(
        coverage = get_vacc_coverage(year, lower_age)
    )

vaccinated_rows <- with_coverage %>%
    ungroup() %>%
    select(
        age_band_id = age_band,
        num_people = proportion,
        year,
        coverage
    ) %>%
    mutate(
        num_people = round(num_people * population_number * coverage),
        vaccine = 1,
        vaccine_dose_3 = 1,
        time_dose_1 = 1,
        time_dose_2 = 2,
        time_dose_3 = 3,
        time_dose_4 = 4
    ) %>%
    select(-coverage) %>%
    relocate(
        num_people,
        .after = everything()
    )

unvaccinated_rows <- with_coverage %>%
    ungroup() %>%
    select(
        age_band_id = age_band,
        num_people = proportion,
        year,
        coverage
    ) %>%
    mutate(
        num_people = round(num_people * population_number * (1 - coverage)),
        vaccine = NA,
        vaccine_dose_3 = NA,
        time_dose_1 = NA,
        time_dose_2 = NA,
        time_dose_3 = NA,
        time_dose_4 = NA
    ) %>%
    select(-coverage) %>%
    relocate(
        num_people,
        .after = everything()
    )

vaccine_pops <- bind_rows(vaccinated_rows, unvaccinated_rows) %>% filter(num_people > 0)
lapply(split(vaccine_pops, vaccine_pops$year), function(df) {
    output_year <- unique(df$year)
    fname <- here::here("abm_inputs", paste0("vmic_vaccination_rollout_", output_year, ".csv"))
    write_csv(x = df %>% select(-year), file = fname)
})
