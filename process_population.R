library(tidyverse)

population <- read_csv("montagu_data/202212rfp-1_dds-202208_qq_pop_both.csv") |>
    mutate(
        lower_age = if_else(
            age_from <= 90, age_from, 90
        )
    ) |>
    group_by(
        country_code_numeric, country_code, country, year, gender, lower_age, value
    ) |>
    summarise(
        value = sum(value)
    )

# We want to set up the number of people of a given age in a given year, but
# only over the reporting years (2000-2100)

output_years <- seq(2000, 2100, by=1)

ages_by_year <- lapply(output_years, function(current_year) {
    population |>
        mutate(age = current_year - year) |>
        filter(age > 0) |>
        mutate(current_year = current_year)
}) %>%
    do.call(rbind, .)

population %>%
    filter(year %% 10 == 0) %>%
    filter(year >= 2000 & year <= 2100) %>%
    ggplot(aes(x = lower_age, y = value, colour = as.factor(year))) +
    geom_col() +
    facet_wrap(~year) + 
    guides(colour = "none")
