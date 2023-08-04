#########################################################################
# R-Script for Figures
# Author: Christoph Janietz, University of Amsterdam
# Project: Temporary Employment and Wage Inequality over the Life Course
# Date: 29-07-2023
#########################################################################

library(haven)
library(ggplot2)
library(readxl)
library(tidyverse)
library(scales)
library(ggpubr)
library(ggridges)

# Color palette
kandinsky <- c("#3b7c70", "#898e9f", "#ce9642", "#3b3a3e")


#################################################################
# Figure 1 - Average Wages by education over the life course
#################################################################

# Load average wages by education group
wgs_ed <- read_excel("C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/data/descr_avg_wages_allempl.xlsx")
wgs_ed$ed <- ordered(wgs_ed$edtc, levels = c(1, 2, 3), labels = c("ISCED 1-2", "ISCED 3-4", "ISCED 5-8"))

wgs_ed <- filter(wgs_ed, YEAR != 2020)

wgs_ed$Age <- wgs_ed$YEAR-1979

# Load average wages by education group
wgs_ed_full <- read_excel("C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/data/descr_avg_wages_full.xlsx")
wgs_ed_full$ed <- ordered(wgs_ed_full$edtc, levels = c(1, 2, 3), labels = c("ISCED 1-2", "ISCED 3-4", "ISCED 5-8"))

wgs_ed_full <- filter(wgs_ed_full, YEAR != 2020)

wgs_ed_full$Age <- wgs_ed_full$YEAR-1979

# GRAPH - COMBINED
ggplot(wgs_ed, aes(y = avg_wage, x = Age)) +
  geom_line(aes(colour = edtc), linewidth = 0.5) +
  geom_line(data=wgs_ed_full, aes(colour = edtc), size = 0.4, alpha=.5, linetype=2) +
  geom_point(aes(colour = edtc), size = 2) +
  geom_point(data=wgs_ed_full, aes(colour = edtc), size = 2, alpha=.4, shape=2) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up, fill = edtc), alpha=.6, linetype=0, size=2) +
  geom_text(aes(label = sprintf("%0.2f", round(after_stat(y), digits = 2))), 
            size = 3.5, vjust = -0.5, hjust = 0.75) +
  scale_x_continuous(breaks = seq(28,40,1), limits = c(28,40),
                     sec.axis = sec_axis(trans=~.+1979, name="Year", breaks = seq(2007,2019,1))) +
  scale_y_continuous(breaks = seq(12.5,27.5,2.5), limits = c(12,27.52), 
                     labels = label_number(accuracy = 0.01, suffix = "€")) +  
  scale_fill_manual(name = "Education", values = kandinsky) +
  scale_colour_manual(name = "Education", values = kandinsky) +
  labs(x = "Age",  y = "Average Real Hourly Wage", caption = "Source: (S)POLIS, 2007-2019") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Fig1_avg_wages_bygrp_combined.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", useDingbats = FALSE)

ggplot(wgs_ed, aes(y = avg_wage, x = Age)) +
  geom_line(aes(colour = edtc), linewidth = 0.5) +
  geom_line(data=wgs_ed_full, aes(colour = edtc), size = 0.4, alpha=.5, linetype=2) +
  geom_point(aes(colour = edtc), size = 2) +
  geom_point(data=wgs_ed_full, aes(colour = edtc), size = 2, alpha=.4, shape=2) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_up, fill = edtc), alpha=.6, linetype=0, size=2) +
  geom_text(aes(label = sprintf("%0.2f", round(after_stat(y), digits = 2))), 
            size = 3.5, vjust = -0.5, hjust = 0.75) +
  scale_x_continuous(breaks = seq(28,40,1), limits = c(28,40),
                     sec.axis = sec_axis(trans=~.+1979, name="Year", breaks = seq(2007,2019,1))) +
  scale_y_continuous(breaks = seq(12.5,27.5,2.5), limits = c(12,27.52), 
                     labels = label_number(accuracy = 0.01, suffix = "€")) +  
  scale_fill_grey(name = "Education") +
  scale_colour_grey(name = "Education") +
  labs(x = "Age",  y = "Average Real Hourly Wage", caption = "Source: (S)POLIS, 2007-2019") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Fig1BW_avg_wages_bygrp_combined.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", useDingbats = FALSE)

#################################################################
# Figure 2 - Wage distributions by education over the life course
#################################################################

# Figure 2 was created within the CBS environment due to export restrictions.
# Here only the code for the plot is displayed.

# GRAPH
a <- ggplot(data_2007, aes(x = real_hwage_rbst, y=edtc, fill = edtc)) +
  stat_density_ridges(quantile_lines = TRUE, quantiles = 2) +
  scale_x_continuous(breaks = seq(0,50,10), limits = c(0,55),
                     labels = label_number(accuracy = 0.01, suffix = "€")) +
  scale_fill_manual(name = "", values = kandinsky) +
  labs(x="Real Hourly Wage", y = "Education", caption = "Source: (S)POLIS, 2007") +
  theme_ridges(center_axis_labels = TRUE)

b <- ggplot(data_2019, aes(x = real_hwage_rbst, y=edtc, fill = edtc)) +
  stat_density_ridges(quantile_lines = TRUE, quantiles = 2) +
  scale_x_continuous(breaks = seq(0,50,10), limits = c(0,55),
                     labels = label_number(accuracy = 0.01, suffix = "€")) +
  scale_fill_manual(name = "", values = kandinsky) +
  coord_cartesian(clip = "off") +
  labs(x="Real Hourly Wage", y = "Education", caption = "Source: (S)POLIS, 2019") +
  theme_ridges(center_axis_labels = TRUE)

figure_density_allempl <- ggarrange(a, b,
                                    labels = c("2007 (Age 28)", "2019 (Age 40)"),
                                    ncol = 1, nrow = 2)
figure_density_allempl

ggsave("Fig2_wages_density_bygrp_allempl.pdf", path = "H:/Christoph/art2/05_figures", useDingbats = FALSE)

c <- ggplot(data_2007, aes(x = real_hwage_rbst, y=edtc, fill = edtc)) +
  stat_density_ridges(quantile_lines = TRUE, quantiles = 2) +
  scale_x_continuous(breaks = seq(0,50,10), limits = c(0,55),
                     labels = label_number(accuracy = 0.01, suffix = "€")) +
  scale_fill_grey(name = "") +
  labs(x="Real Hourly Wage", y = "Education", caption = "Source: (S)POLIS, 2007") +
  theme_ridges(center_axis_labels = TRUE)

d <- ggplot(data_2019, aes(x = real_hwage_rbst, y=edtc, fill = edtc)) +
  stat_density_ridges(quantile_lines = TRUE, quantiles = 2) +
  scale_x_continuous(breaks = seq(0,50,10), limits = c(0,55),
                     labels = label_number(accuracy = 0.01, suffix = "€")) +
  scale_fill_grey(name = "") +
  coord_cartesian(clip = "off") +
  labs(x="Real Hourly Wage", y = "Education", caption = "Source: (S)POLIS, 2019") +
  theme_ridges(center_axis_labels = TRUE)

figure_density_allempl <- ggarrange(c, d,
                                    labels = c("2007 (Age 28)", "2019 (Age 40)"),
                                    ncol = 1, nrow = 2)
figure_density_allempl

ggsave("Fig2BW_wages_density_bygrp_allempl.pdf", path = "H:/Christoph/art2/05_figures", useDingbats = FALSE)

#################################################################
# Figure 3 - Risk estimates
#################################################################

# Load data
risk <- read_excel("C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/data/margins_risk_allempl.xlsx")

# Load data
risk_full <- read_excel("C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/data/margins_risk_full.xlsx")

# Graph - Combined
risk_low_1 <- filter(risk, edtc=="ISCED 1-2" & Age<=35)
risk_high_1 <- filter(risk, edtc=="ISCED 5-8" & Age<=35)
risk_low_2 <- filter(risk, edtc=="ISCED 1-2" & Age>35)
risk_high_2 <- filter(risk, edtc=="ISCED 5-8" & Age>35)

ggplot(risk, aes(y = b, x = Age)) +
  geom_line(data=risk_full, aes(colour = edtc), size = 0.5, alpha=.4, linetype=2) +
  geom_line(aes(colour = edtc), size = 0.5) +
  geom_point(aes(colour = edtc), size = 2) +
  geom_point(data=risk_full, aes(colour = edtc), size = 2, alpha=.4, shape=2) +
  geom_ribbon(aes(ymin = ll, ymax = ul, fill = edtc), alpha=.6, linetype=0, size=2) +
  geom_text(data = risk_low_1, aes(label = percent(b, accuracy=0.1)), size = 3, vjust = 1.5) +
  geom_text(data = risk_high_1, aes(label = percent(b, accuracy=0.1)), size = 3, vjust = -1.5) +
  geom_text(data = risk_low_2, aes(label = percent(b, accuracy=0.1)), size = 3, vjust = -1.5) +
  geom_text(data = risk_high_2, aes(label = percent(b, accuracy=0.1)), size = 3, vjust = 1.5) +
  scale_x_continuous(breaks = seq(28,40,1), limits = c(28,40),
                     sec.axis = sec_axis(trans=~.+1979, name="Year", breaks = seq(2007,2019,1))) +
  scale_y_continuous(breaks = seq(0,1,0.05), limits = c(0,0.45),
                     labels = scales::percent) +
  scale_fill_manual(name = "Education", values = kandinsky) +
  scale_colour_manual(name = "Education", values = kandinsky) +
  labs(X = "Age ", y="Predicted Probability of \nTemporary Employment",
       caption = "Source: (S)POLIS 2006-2019") +
  theme_minimal() +
  theme(legend.position = "bottom")


ggsave("Fig3_risk_combined.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", useDingbats = FALSE)

ggplot(risk, aes(y = b, x = Age)) +
  geom_line(data=risk_full, aes(colour = edtc), size = 0.5, alpha=.4, linetype=2) +
  geom_line(aes(colour = edtc), size = 0.5) +
  geom_point(aes(colour = edtc), size = 2) +
  geom_point(data=risk_full, aes(colour = edtc), size = 2, alpha=.4, shape=2) +
  geom_ribbon(aes(ymin = ll, ymax = ul, fill = edtc), alpha=.6, linetype=0, size=2) +
  geom_text(data = risk_low_1, aes(label = percent(b, accuracy=0.1)), size = 3, vjust = 1.5) +
  geom_text(data = risk_high_1, aes(label = percent(b, accuracy=0.1)), size = 3, vjust = -1.5) +
  geom_text(data = risk_low_2, aes(label = percent(b, accuracy=0.1)), size = 3, vjust = -1.5) +
  geom_text(data = risk_high_2, aes(label = percent(b, accuracy=0.1)), size = 3, vjust = 1.5) +
  scale_x_continuous(breaks = seq(28,40,1), limits = c(28,40),
                     sec.axis = sec_axis(trans=~.+1979, name="Year", breaks = seq(2007,2019,1))) +
  scale_y_continuous(breaks = seq(0,1,0.05), limits = c(0,0.45),
                     labels = scales::percent) +
  scale_fill_grey(name = "Education") +
  scale_colour_grey(name = "Education") +
  labs(X = "Age ", y="Predicted Probability of \nTemporary Employment",
       caption = "Source: (S)POLIS 2006-2019") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Fig3BW_risk_combined.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", useDingbats = FALSE)

#################################################################
# Figure 4&5 - Vulnerability estimates
#################################################################

# Load data
vuln <- read_excel("C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/data/vuln_feis_allempl.xlsx")
vuln_full <- read_excel("C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/data/vuln_feis_full.xlsx")

# Subset data
vuln_temp <- filter(vuln, estimate=="Temporary Employment (t)")
vuln_event <- filter(vuln, estimate=="TstayP" | estimate=="TstayT"
                     | estimate=="TswitchP" | estimate=="TswitchT")

vuln_temp_full <- filter(vuln_full, estimate=="Temporary Employment (t)")
vuln_event_full <- filter(vuln_full, estimate=="TstayP" | estimate=="TstayT"
                          | estimate=="TswitchP" | estimate=="TswitchT")

# Labelling Events
vuln_event <- vuln_event %>%
  mutate(estimate = recode(estimate, "TstayP"="Temporary Employment (t-1) \n & Job Stay \n & Permanent Employment (t)",
                           "TstayT"="Temporary Employment (t-1) \n & Job Stay \n & Temporary Employment (t)",
                            "TswitchP"="Temporary Employment (t-1) \n & Job Switch \n & Permanent Employment (t)",
                            "TswitchT"="Temporary Employment (t-1) \n & Job Switch \n & Temporary Employment (t)"))
vuln_event_full <- vuln_event_full %>%
  mutate(estimate = recode(estimate, "TstayP"="Temporary Employment (t-1) \n & Job Stay \n & Permanent Employment (t)",
                           "TstayT"="Temporary Employment (t-1) \n & Job Stay \n & Temporary Employment (t)",
                           "TswitchP"="Temporary Employment (t-1) \n & Job Switch \n & Permanent Employment (t)",
                           "TswitchT"="Temporary Employment (t-1) \n & Job Switch \n & Temporary Employment (t)"))

# Combined
# Graph - Temp Effect
ggplot(vuln_temp, aes(fill = edtc, y = b, x = estimate)) +
  geom_bar(position = "dodge", stat = "identity") +
  geom_errorbar(aes(ymin = lb, ymax = ub), width = .2, position = position_dodge(.9)) +
  geom_point(data=vuln_temp_full, size = 3, shape=2, position = position_dodge(.9)) +
  geom_hline(yintercept=0) +
  scale_fill_manual(name = "Education", values = kandinsky) +
  labs(x = "", y="Marginal Effect on Log Real Hourly Wage",
       caption = "Source: (S)POLIS 2006-2019") +
  guides(shape='none') +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Fig4_vuln_temp_combined.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", useDingbats = FALSE)

ggplot(vuln_temp, aes(fill = edtc, y = b, x = estimate)) +
  geom_bar(position = "dodge", stat = "identity") +
  geom_errorbar(aes(ymin = lb, ymax = ub), width = .2, position = position_dodge(.9)) +
  geom_point(data=vuln_temp_full, size = 3, shape=2, position = position_dodge(.9)) +
  geom_hline(yintercept=0) +
  scale_fill_grey(name = "Education") +
  labs(x = "", y="Marginal Effect on Log Real Hourly Wage",
       caption = "Source: (S)POLIS 2006-2019") +
  guides(shape='none') +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Fig4BW_vuln_temp_combined.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", useDingbats = FALSE)


# Graph - Temp Effect by Event
ggplot(vuln_event, aes(fill = edtc, y = b, x = estimate)) +
  geom_bar(position = "dodge", stat = "identity") +
  geom_errorbar(aes(ymin = lb, ymax = ub), width = .2, position = position_dodge(.9)) +
  geom_point(data=vuln_event_full, size = 3, shape=2, position = position_dodge(.9)) +
  geom_hline(yintercept=0) +
  scale_fill_manual(name = "Education", values = kandinsky) +
  labs(x = "", y="Marginal Effect on Log Real Hourly Wage \n(Contrast: Permanent Employment (t-1) & Job Stay & \nPermanent Employment (t))",
       caption = "Source: (S)POLIS 2006-2019") +
  guides(shape='none') +
  theme_minimal() +
  theme(legend.position = "bottom") 

ggsave("Fig5_vuln_event_combined.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", useDingbats = FALSE)

ggplot(vuln_event, aes(fill = edtc, y = b, x = estimate)) +
  geom_bar(position = "dodge", stat = "identity") +
  geom_errorbar(aes(ymin = lb, ymax = ub), width = .2, position = position_dodge(.9)) +
  geom_point(data=vuln_event_full, size = 3, shape=2, position = position_dodge(.9)) +
  geom_hline(yintercept=0) +
  scale_fill_grey(name = "Education") +
  labs(x = "", y="Marginal Effect on Log Real Hourly Wage \n(Contrast: Permanent Employment (t-1) & Job Stay & \nPermanent Employment (t))",
       caption = "Source: (S)POLIS 2006-2019") +
  guides(shape='none') +
  theme_minimal() +
  theme(legend.position = "bottom") 

ggsave("Fig5BW_vuln_event_combined.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", useDingbats = FALSE)


#################################################################
# Figure 6 - Decomposition of growth in wage gap
#################################################################

# Decomposition
dc <- read_excel("C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/data/decomp.xlsx")
dc_Y <- filter(dc, Scenario=="Y")
dc_RandV <- filter(dc, Scenario!="Y")
dc_RV <- filter(dc, Scenario=="RV")

dc_RandV$Scenario <- factor(dc_RandV$Scenario, levels = c("R", "V", "RV"), labels = c("ΔR", "ΔV", "ΔR+ΔV+ΔI"))

ggplot(dc_Y, aes(y = Y, x = Age)) +
  geom_line(size = 0.5) +
  geom_point(size = 2) +
  geom_line(data=dc_RandV, aes(colour = Scenario), size = 0.4, linetype=2) +
  geom_point(data=dc_RandV, aes(colour = Scenario, shape = Scenario), size = 1.5) +
  scale_x_continuous(breaks = seq(28,38,1), limits = c(28,38),
                     sec.axis = sec_axis(trans=~.+1979, name="Year", breaks = seq(2007,2017,1))) +
  geom_text(data = dc_RV, aes(label = percent(ratio, .01)), size = 3, vjust = 2) +
  labs(y = "Change in Wage Gap (ΔY)", caption = "Source: (S)POLIS, 2007-2017") +
  scale_colour_manual(name = "", values = kandinsky) +
  scale_shape_discrete(name = "") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Fig6_decomposition_allempl.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", 
       device = cairo_pdf)

ggplot(dc_Y, aes(y = Y, x = Age)) +
  geom_line(size = 0.5) +
  geom_point(size = 2) +
  geom_line(data=dc_RandV, aes(colour = Scenario), size = 0.4, linetype=2) +
  geom_point(data=dc_RandV, aes(colour = Scenario, shape = Scenario), size = 1.5) +
  scale_x_continuous(breaks = seq(28,38,1), limits = c(28,38),
                     sec.axis = sec_axis(trans=~.+1979, name="Year", breaks = seq(2007,2017,1))) +
  geom_text(data = dc_RV, aes(label = percent(ratio, .01)), size = 3, vjust = 2) +
  labs(y = "Change in Wage Gap (ΔY)", caption = "Source: (S)POLIS, 2007-2017") +
  scale_colour_grey(name = "") +
  scale_shape_discrete(name = "") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("Fig6BW_decomposition_allempl.pdf", path = "C:/Users/cjaniet11/OneDrive/Dokumente/PhD Amsterdam/art2/figures", 
       device = cairo_pdf)
