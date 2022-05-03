library(tidycensus)
library(dplyr)
library(purrr)
library(ggplot2)
library(scales)
library(tidyverse)

# Get the API key from http://api.census.gov/data/key_signup.html
# census_api_key("you api key should be inserted here", install = "True")
years <- 2005:2019
names(years) <- years


mmdade_value <- map_dfr(years, ~{
  get_acs(
    geography = "county",
    variables = "B25077_001",
    state = "FL",
    county = "Miami-Dade",
    year = .x,
    survey = "acs1"
  )
}, .id = "year")

# view the head
head(mmdade_value)

# plot the data - time series

ggplot(mmdade_value, aes(x= year, y = estimate, group = 1)) +
  geom_line()+
  geom_point()

# produce a plot with the margin of error
ggplot(mmdade_value, aes(x = year, y = estimate, group = 1)) +
  geom_ribbon(aes(ymax = estimate + moe, ymin = estimate - moe),
              fill = "navy",
              alpha = 0.4) +
  geom_line(color = "navy") +
  geom_point(color = "navy", size = 2) +
  theme_minimal(base_size = 11) +
  scale_y_continuous(labels = label_dollar(scale = .001, suffix = "k")) +
  labs(title = "Median Home Value in Miami-Dade County, FL",
       x = "Year",
       y = "ACS estimate",
       caption = "Shaded area represents margin of error around the ACS estimates")

# Groupwise viz - lets pick the most populated counties in Florida and examine
# block group median house values AC5 five years estimates
housing_val <- get_acs(
  geography = "tract",
  variables = "B25077_001",
  state = "FL",
  county = c(
    "Miami-Dade",
    "Broward",
    "Palm Beach",
    "Hillsborough",
    "Orange",
    "Duval",
    "Pinellas"
    ),
  year = 2020,
  survey = "acs5"
  )
# view the data
head(housing_val)

# split to county state and tract
housing_val2 <- separate(
  housing_val, 
  NAME,
  into = c("tract", "county", "state"),
  sep = ","
)

# compute county level statistics

housing_val2 %>%
  group_by(county)%>%
  summarise(min = min(estimate, na.rm = TRUE),
            mean = mean(estimate, na.rm = TRUE),
            median = median(estimate, na.rm = TRUE),
            max = max(estimate, na.rm = TRUE))

# lets produce county level visualisation
ggplot(housing_val2, aes(x = estimate))+
  geom_density(fill = "darkblue", color = "darkblue", alpha = 0.5) +
  facet_wrap(~county)+
  scale_x_continuous(labels = dollar_format(scale = 0.000001,
                                            suffix = "m")) +
  theme_minimal(base_line_size = 14)+
  theme(axis.text.y = element_blank(),
        axis.text.x = element_text(angle = 45)) +
  labs(x = "ACS Estimate",
       y = "",
       title = "Median House Values by Census Tract, 2015 -2019 ACS")

# lets make Ridgeline plots - an option for visual comparision of the values
# using the ggridges package
library(ggridges)

ggplot(housing_val2, aes(x = estimate, y = county)) +
  geom_density_ridges()+
  theme_ridges()+
  labs(x = "Median house value: 2016-2020 ACS Estimate",
       y = "",
       title = "Median House Values by Census Tract, 2015 -2019 ACS") +
  scale_x_continuous(labels = dollar_format(scale = 0.000001, suffix = "m"),
                     breaks = c(0, 500000, 1000000))+
  theme(axis.text = element_text(angle = 45))


