
# Desert rodent abundance forecasting
# Portal Project, Arizona

# install.packages(c("portalr", "forecast", "dplyr", "ggplot2"))

library(portalr)
library(forecast)
library(dplyr)
library(ggplot2)

# Load Portal Project data
portalr::download_observations(".")

rodents <- portalr::abundance(
  path = ".",
  level = "site",
  time = "date",
  shape = "flat"
)

climate <- portalr::weather(
  path = ".",
  level = "monthly",
  fill = FALSE
)

head(rodents)
head(climate)


# Annual abundance index
population <- rodents %>%
  mutate(Year = as.integer(format(censusdate, "%Y"))) %>%
  group_by(censusdate, Year) %>%
  summarise(
    Count = sum(abundance, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(Year) %>%
  summarise(
    Count = mean(Count),
    Surveys = n(),
    .groups = "drop"
  ) %>%
  filter(Surveys >= 6, Count > 0) %>%
  arrange(Year)

# Keep the longest consecutive sequence of years
population <- population %>%
  mutate(
    Series = cumsum(c(1, diff(Year) != 1))
  )

series_lengths <- population %>%
  count(Series, name = "Years")

longest_series <- series_lengths$Series[
  which.max(series_lengths$Years)
]

population <- population %>%
  filter(Series == longest_series) %>%
  select(-Series)

stopifnot(nrow(population) >= 15)

head(population)


# Abundance time series
pop_ts <- ts(
  population$Count,
  start = min(population$Year),
  frequency = 1
)

autoplot(pop_ts) +
  theme_classic() +
  labs(
    title = "Annual desert rodent abundance",
    x = "Year",
    y = "Mean count per survey"
  )


# Training and validation data
n <- length(pop_ts)

train <- window(
  pop_ts,
  end = max(population$Year) - 5
)

test <- window(
  pop_ts,
  start = max(population$Year) - 4
)

# ARIMA model
model <- auto.arima(train)

summary(model)

test_forecast <- forecast(model, h = length(test))

accuracy(test_forecast, test)

rmse <- sqrt(mean(
  (as.numeric(test) -
     as.numeric(test_forecast$mean))^2
))

cat("Test RMSE:", round(rmse, 2), "\n")


# Forecast validation
autoplot(test_forecast) +
  autolayer(test, series = "Observed") +
  theme_classic() +
  labs(
    title = "ARIMA forecast validation",
    x = "Year",
    y = "Mean count per survey"
  )


# Residual diagnostics
checkresiduals(model)


# Five-year abundance forecast
final_model <- auto.arima(pop_ts)

future <- forecast(final_model, h = 5)

print(future)

autoplot(future) +
  theme_classic() +
  labs(
    title = "Five-year rodent abundance forecast",
    x = "Year",
    y = "Mean count per survey"
  )


# Rainfall data
rainfall <- climate %>%
  group_by(year) %>%
  summarise(
    Rainfall = if (
      n_distinct(month[!is.na(precipitation)]) == 12
    ) {
      sum(precipitation, na.rm = TRUE)
    } else {
      NA_real_
    },
    .groups = "drop"
  ) %>%
  rename(Year = year)

population_env <- population %>%
  left_join(rainfall, by = "Year") %>%
  arrange(Year)

# Restrict to consecutive years with rainfall observations
population_env <- population_env %>%
  filter(!is.na(Rainfall)) %>%
  mutate(
    Series = cumsum(c(1, diff(Year) != 1))
  )

series_lengths <- population_env %>%
  count(Series, name = "Years")

longest_series <- series_lengths$Series[
  which.max(series_lengths$Years)
]

population_env <- population_env %>%
  filter(Series == longest_series) %>%
  select(-Series)

stopifnot(nrow(population_env) >= 15)

head(population_env)


# Rolling forecast validation
years <- population_env$Year
counts <- population_env$Count
rain <- population_env$Rainfall

n <- length(counts)

results <- data.frame(
  Year = numeric(),
  Observed = numeric(),
  ARIMA = numeric(),
  ARIMAX = numeric()
)

# Rainfall in the preceding year is used as a predictor
# so that future rainfall is not required for validation

for (i in 10:(n - 1)) {
  
  train_pop <- counts[2:i]
  train_rain <- rain[1:(i - 1)]
  
  model_arima <- auto.arima(
    train_pop,
    seasonal = FALSE
  )
  
  model_arimax <- auto.arima(
    train_pop,
    xreg = train_rain,
    seasonal = FALSE
  )
  
  pred_arima <- forecast(
    model_arima,
    h = 1
  )$mean
  
  pred_arimax <- forecast(
    model_arimax,
    xreg = rain[i],
    h = 1
  )$mean
  
  results <- rbind(
    results,
    data.frame(
      Year = years[i + 1],
      Observed = counts[i + 1],
      ARIMA = as.numeric(pred_arima),
      ARIMAX = as.numeric(pred_arimax)
    )
  )
}


# Forecast accuracy
rmse_arima <- sqrt(mean(
  (results$Observed - results$ARIMA)^2
))

rmse_arimax <- sqrt(mean(
  (results$Observed - results$ARIMAX)^2
))

mae_arima <- mean(
  abs(results$Observed - results$ARIMA)
)

mae_arimax <- mean(
  abs(results$Observed - results$ARIMAX)
)

accuracy_results <- data.frame(
  Model = c("ARIMA", "ARIMAX"),
  RMSE = c(rmse_arima, rmse_arimax),
  MAE = c(mae_arima, mae_arimax)
)

print(accuracy_results)


# Rolling forecast performance
ggplot(results, aes(Year)) +
  geom_line(
    aes(y = Observed, colour = "Observed"),
    linewidth = 1
  ) +
  geom_line(
    aes(y = ARIMA, colour = "ARIMA")
  ) +
  geom_line(
    aes(y = ARIMAX, colour = "ARIMAX")
  ) +
  theme_classic() +
  labs(
    title = "Rolling forecast validation",
    x = "Year",
    y = "Mean count per survey",
    colour = "Series"
  )


# Final rainfall model
# Previous-year rainfall predicts current-year abundance

model_rainfall <- auto.arima(
  counts[-1],
  xreg = rain[-n],
  seasonal = FALSE
)

summary(model_rainfall)
checkresiduals(model_rainfall)

# One-year-ahead forecast using the latest observed rainfall
rainfall_forecast <- forecast(
  model_rainfall,
  xreg = tail(rain, 1),
  h = 1
)

print(rainfall_forecast)

autoplot(rainfall_forecast) +
  theme_classic() +
  labs(
    title = "Rodent abundance forecast with rainfall",
    x = "Year",
    y = "Mean count per survey"
  )


# Save results
dir.create("results", showWarnings = FALSE)

write.csv(
  population,
  "results/annual_rodent_abundance.csv",
  row.names = FALSE
)

write.csv(
  population_env,
  "results/abundance_rainfall.csv",
  row.names = FALSE
)

write.csv(
  results,
  "results/rolling_forecast_validation.csv",
  row.names = FALSE
)

write.csv(
  accuracy_results,
  "results/forecast_accuracy.csv",
  row.names = FALSE
)
