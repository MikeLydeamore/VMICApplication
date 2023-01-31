library(readr)
library(data.table)
library(dplyr)
library(tidyr)

population <- read_csv("montagu_data/202212rfp-1_dds-202208_int_pop_both.csv")
life_expectancy <- read_csv("montagu_data/202212rfp-1_dds-202208_lx0_both.csv") %>%
    rename(expectancy = value, birth_year = year) %>%
    select(birth_year, expectancy)

add_dalys <- function(.data) {
    .data %>%
        mutate(
            symptoms_no_hosp = total_symptomatic_infections - total_admissions,
            admissions_no_icu = total_admissions - total_ICU_admissions,
            birth_year = year - age
        ) %>%
        left_join(life_expectancy, by = "birth_year") %>%
        replace_na(list(expectancy = min(life_expectancy$expectancy))) %>%
        mutate(
            yll = pmax(expectancy - age, 0) * total_deaths,
            yld = 0.051 * symptoms_no_hosp + 0.133 * admissions_no_icu + 0.675 * total_ICU_admissions,
            dalys = yll + yld
        ) %>%
        filter(birth_year > 1900 & birth_year < 2030) %>%
        select(
            -symptoms_no_hosp,
            -admissions_no_icu,
            -birth_year,
            -yll,
            -yld,
            -expectancy
        )
}

target_years <- 2000:2100

stochastic_outputs_vaccination <- lapply(target_years, function(input_year) {
    target_population_number <- population %>%
        filter(year == input_year) %>%
        summarise(sum(value)) %>%
        pull()

    sim <- read_csv(paste0("~/cm37_scratch/VIMC/vaccination_year_", input_year, "_VIMC_outputs_0.33333     0.33333     0.16667     0.16667    0.066667    0.066667.csv"))
    sim %>%
        mutate(
            disease = "COVID",
            run_id = 1,
            year = input_year,
            age = age,
            country = "RFP",
            country_name = "Request for Proposal",
            cohort_size = target_population_number,
            cases = round(total_infections * (target_population_number / 100000)),
            deaths = round(total_deaths * (target_population_number / 100000))
        ) %>%
        add_dalys() %>%
        select(
            disease,
            run_id,
            year,
            age,
            country,
            country_name,
            cohort_size,
            cases,
            dalys,
            deaths
        ) %>%
        arrange(
            year, age, run_id
        )
}) %>% bind_rows()

stochastic_outputs_vaccination_high <- lapply(target_years, function(input_year) {
    target_population_number <- population %>%
        filter(year == input_year) %>%
        summarise(sum(value)) %>%
        pull()

    sim <- read_csv(paste0("~/cm37_scratch/VIMC/vaccination_year_high_", input_year, "_VIMC_outputs_0.33333     0.33333     0.16667     0.16667    0.066667    0.066667.csv"))
    sim %>%
        mutate(
            disease = "COVID",
            run_id = 2,
            year = input_year,
            age = age,
            country = "RFP",
            country_name = "Request for Proposal",
            cohort_size = target_population_number,
            cases = round(total_infections * (target_population_number / 100000)),
            deaths = round(total_deaths * (target_population_number / 100000))
        ) %>%
        add_dalys() %>%
        select(
            disease,
            run_id,
            year,
            age,
            country,
            country_name,
            cohort_size,
            cases,
            dalys,
            deaths
        ) %>%
        arrange(
            year, age, run_id
        )
}) %>% bind_rows()

stochastic_outputs_vaccination_combined <- rbind(stochastic_outputs_vaccination, stochastic_outputs_vaccination_high)

write_csv(
    file = "stochastic_burden_est.202212rfp-1-McVernon_COVID-default.csv",
    x = stochastic_outputs_vaccination_combined
)

write_csv(
    file = "stochastic_burden_est.202212rfp-1-McVernon_COVID-default.csv",
    x = stochastic_outputs_vaccination_combined %>%
        group_by(disease, run_id, year, age, country, country_name) %>%
        summarise(
            cohort_size = median(cohort_size),
            cases = median(cases),
            dalys = median(dalys),
            deaths = median(deaths)
        )
)