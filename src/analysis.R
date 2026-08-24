# Data analysis

data <- read.csv("project.total.csv") summary(data) mean(data$admit/data$total_visit)

colSums(is.na(data))
data$o3[is.na(data$o3)] <- mean(data$o3, na.rm = TRUE)

corr.plot <- cor(data[, c("ard", "acs", "ahf", "stroke", "total_case", "total_visit", "admit", "death", "pm25", "pm10", "o3", "no2", "so2")])
corrplot(corr.plot, method = "number", order = "hclust") corrplot(corr.plot, method = "ellipse", order = "hclust")

#OLS Model

OLSmodel <- lm(total_visit ~ ard + acs + ahf + stroke + pm25 + pm10 + o3 + no2 + so2, data = data) summary(OLSmodel)
par(mfrow = c(2, 2)) plot(OLSmodel) vif(OLSmodel) bptest(OLSmodel) durbinWatsonTest(OLSmodel)

# Lagged model

healthvars <- c("ard", "acs", "ahf", "stroke", "total_case") for(var in healthvars) {
for(lag in 1:3) {
data <- slide(data, Var=var, NewVar=paste0(var, ".L", lag), slideBy=-lag)
}
}
envvars <- c("pm25", "pm10", "o3", "no2", "so2") for(var in envvars) {
for(lag in 1:3) {
data <- slide(data, Var=var, NewVar=paste0(var, ".L", lag), slideBy=-lag)
}
}

colSums(is.na(data))
 
data <- na.omit(data)

Lagmodel <- lm(total_case ~
pm25 + pm10 + o3 + no2 + so2 + pm25.L1 + pm25.L2 + pm25.L3 + pm10.L1 + pm10.L2 + pm10.L3 + o3.L1 + o3.L2 + o3.L3 +
no2.L1 + no2.L2 + no2.L3 + so2.L1 + so2.L2 + so2.L3 +
total_case.L1 + total_case.L2 + total_case.L3, data=data)
summary(Lagmodel)

# Stepwise selection

Stepmodel <- step(Lagmodel, direction="both") summary(Stepmodel)
vif(Stepmodel) bptest(Stepmodel) durbinWatsonTest(Stepmodel) par(mfrow=c(2,2)) plot(Stepmodel)

anova(Lagmodel, Stepmodel)
# Log transformation model data$log_total_case <- log(data$total_case)
data <- slide(data, Var="log_total_case", NewVar="log_total_case.L1", slideBy = -1) Logmodel <- lm(log_total_case ~ pm25 + pm10 + o3 + o3.L2 + log_total_case.L1,
data=data) summary(Logmodel) vif(Logmodel) bptest(Logmodel) durbinWatsonTest(Logmodel) par(mfrow=c(2,2)) plot(Logmodel)

# Center variables

data$pm25_c <- scale(data$pm25, center=TRUE, scale=FALSE) data$o3_c <- scale(data$o3, center=TRUE, scale=FALSE) data$pm10_c <- scale(data$pm10, center=TRUE, scale=FALSE) data$no2_c <- scale(data$no2, center=TRUE, scale=FALSE)
 
data$so2_c <- scale(data$so2, center=TRUE, scale=FALSE) data$ard_c <- scale(data$ard, center=TRUE, scale=FALSE) data$acs_c <- scale(data$acs, center=TRUE, scale=FALSE) data$ahf_c <- scale(data$ahf, center=TRUE, scale=FALSE) data$stroke_c <- scale(data$stroke, center=TRUE, scale=FALSE)

# Interactions model

Interactmodel <- lm(log_total_case ~
pm25_c + o3_c + pm10_c + no2_c + so2_c + ard_c + acs_c + ahf_c + stroke_c +
pm25_c:ard_c + pm25_c:acs_c + pm25_c:ahf_c + pm25_c:stroke_c + o3_c:ard_c + o3_c:acs_c + o3_c:ahf_c + o3_c:stroke_c + log_total_case.L1,
data=data) summary(Interactmodel) vif(Interactmodel) bptest(Interactmodel) durbinWatsonTest(Interactmodel) par(mfrow=c(2,2)) plot(Interactmodel)
# Simplified Interactions model Finalmodel <- lm(log_total_case ~
pm25_c + o3_c + pm10_c + no2_c + so2_c +
ard_c + acs_c + ahf_c + stroke_c +
pm25_c:ard_c + pm25_c:ahf_c + pm25_c:stroke_c + o3_c:ard_c + log_total_case.L1,
data = data)

summary(Finalmodel) vif(Finalmodel) bptest(Finalmodel) durbinWatsonTest(Finalmodel) par(mfrow=c(2,2)) plot(Finalmodel)

anova(Interactmodel, Finalmodel)
# Cross-validation test statistics library(caret)
set.seed(1)
 
data <- na.omit(data)
CVmodel <- train(log_total_case ~ pm25_c + o3_c + pm10_c + no2_c + so2_c + ard_c + acs_c + ahf_c + stroke_c +
pm25_c:ard_c + pm25_c:ahf_c + pm25_c:stroke_c + o3_c:ard_c + log_total_case.L1,
data = data, method = "lm")
summary(CVmodel) CVmodel
# Trying to correct curvilinear relationships Polymodel <- lm(log_total_case ~
pm25_c + I(pm25_c^2) +
o3_c + I(o3_c^2) + pm10_c + I(pm10_c^2) + no2_c + so2_c +
ard_c + acs_c + ahf_c + stroke_c +
pm25_c:ard_c + pm25_c:ahf_c + pm25_c:stroke_c + o3_c:ard_c + log_total_case.L1,
data = data) summary(Polymodel) vif(Polymodel) bptest(Polymodel) durbinWatsonTest(Polymodel) par(mfrow=c(2,2)) plot(Polymodel)

Splinesmodel <- lm(log_total_case ~
ns(pm25_c, df=3) + ns(o3_c, df=3) + ns(pm10_c, df=3) + no2_c + so2_c +
ard_c + acs_c + ahf_c + stroke_c +
pm25_c:ard_c + pm25_c:ahf_c + pm25_c:stroke_c + o3_c:ard_c + log_total_case.L1,
data = data) summary(Splinesmodel) vif(Splinesmodel) bptest(Splinesmodel) durbinWatsonTest(Splinesmodel) par(mfrow=c(2,2)) plot(Splinesmodel)
anova(Finalmodel, Polymodel, Splinesmodel)