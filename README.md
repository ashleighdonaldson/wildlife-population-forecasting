# Wildlife Population Forecasting in R

## Overview

This project examines the use of time-series forecasting models to predict changes in desert rodent abundance using long-term ecological monitoring data from the Portal Project in Arizona, USA.

The analyses compare autoregressive integrated moving average (ARIMA) models with models incorporating rainfall (ARIMAX) and evaluate predictive performance using withheld observations and rolling forecast validation.

All analyses are contained in a single R script.

## Data

Rodent abundance and rainfall data are obtained from the Portal Project using the `portalr` R package.

Annual rodent abundance is represented by mean survey counts, while annual rainfall is calculated from monthly precipitation observations.

## Analyses

### Population abundance forecasting

ARIMA models are fitted to historical rodent abundance observations. The final five years are withheld for model validation, and forecast accuracy is assessed using root mean squared error (RMSE).

The model is subsequently fitted to the complete dataset to generate a five-year abundance forecast.

### Rolling forecast validation

Expanding-window validation is used to evaluate one-year-ahead forecasts across multiple years.

ARIMA and ARIMAX models are compared using RMSE and mean absolute error (MAE).

### Environmental forecasting

Annual rainfall from the preceding year is incorporated into ARIMAX models to investigate whether environmental information improves abundance predictions.

A final ARIMAX model is used to generate a one-year-ahead forecast using the latest available rainfall observation.

## Methods

The analyses use time-series modelling, autoregressive forecasting, environmental covariates, rolling forecast validation and residual diagnostics.

## R packages

- `portalr`
- `forecast`
- `dplyr`
- `ggplot2`

## Running the analysis

Install the required packages:

```r
install.packages(c("portalr", "forecast", "dplyr", "ggplot2"))
```

Run `wildlife_population_forecasting.R` in RStudio.

The script retrieves the Portal Project data and saves processed abundance records, forecast validation results and accuracy statistics.

## Limitations

Annual rodent abundance is represented by an index based on survey counts rather than absolute population estimates.

The analysis combines observations across rodent species and does not explicitly account for differences in detection probability or sampling effort.

The forecasting models are exploratory and rely on historical patterns remaining sufficiently informative about future population dynamics. The influence of rainfall may also depend on seasonal conditions and temporal lags.

## Data source

[Portal Project](https://portal.weecology.org/)

[portalr R package](https://weecology.github.io/portalr/)

The original dataset and package publications should be cited when using these data.
