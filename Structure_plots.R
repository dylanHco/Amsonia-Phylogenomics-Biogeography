#### Load libraries to make plots
library(ggplot2)
library(tidyr)
library(dplyr)
library(tidyverse)

getwd()
# Working Directory: "/Users/dcohen/Desktop/Amsonia/Amo_working"
setwd("/Users/dcohen/Desktop/Amsonia/Amo_working")
#Import the Admixture files

# lets import K=7 for plots

admix_data_west <- read.table("ADMIXTURE/cleaned_data.label.7.5.Q", header=FALSE)
admix_data_east <- read.table("ADMIXTURE/admixture_K7EASTERN.txt", header=FALSE)

#Name the Columns for adding labels later
colnames(admix_data_west) <- c("Sample", "Cluster1", "Cluster2", "Cluster3","Cluster4", "Cluster5","Cluster6","Cluster7")

cluster_labels <- c("Cluster1" = "Amsonia_ciliata", 
                    "Cluster2" = "A.jonesii-1", 
                    "Cluster3" = "A.tabernaemontana", 
                    "Cluster4" = "A.rigida-illustris-tabernaemontana-repens", 
                    "Cluster5" = "A.jonesii-2",
                    "Cluster6" = "A.hubrichtii-illustris-salcifolia",
                    "Cluster7" = "A.ludoviciana-tabernaemontana-salcifolia")

cluster_labels <- c("Cluster1" = "A.tharpii-fugatei", 
                    "Cluster2" = "A.arenaria-tomentosa_tomentosa", 
                    "Cluster3" = "A.peeblesii", 
                    "Cluster4" = "A.tomentosa_stenophylla", 
                    "Cluster5" = "A.longiflora-grandiflora",
                    "Cluster6" = "A.palmeri",
                    "Cluster7" = "A.kearneyana-plameri")


##############################################################################

# Convert to long format
admix_long <- pivot_longer(admix_data_west, cols = starts_with("Cluster"), 
                           names_to = "Cluster", values_to = "Ancestry")

# Determine the primary cluster for each sample (where they have the highest ancestry proportion)
admix_summary <- admix_long %>%
  group_by(Sample) %>%
  summarize(MainCluster = Cluster[which.max(Ancestry)],  # Find the dominant cluster
            MaxAncestry = max(Ancestry))                # Store the highest ancestry proportion

# Order samples within each main cluster from least to most admixed (low MaxAncestry first)
admix_summary <- admix_summary %>%
  arrange(MainCluster, desc(MaxAncestry))  # Reverse the order using `desc()`

# Update factor levels for Sample to reflect new order
admix_long$Sample <- factor(admix_long$Sample, levels = admix_summary$Sample)




ggplot(admix_long, aes(x = Sample, y = Ancestry, fill = Cluster)) +
  geom_bar(stat = "identity", width = 1, color = "black") +  # Add black border
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 90, hjust = 1, size = 12, color = "black"),
    axis.text.y = element_text(color = "black"),
    axis.ticks = element_line(color = "black"),
    legend.text = element_text(size = 14),        # Increase legend text size
    legend.title = element_text(size = 16),       # Increase legend title size
    legend.key.size = unit(1, "cm") 
  ) +
  scale_fill_manual(values = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFFF33",
                               "#A65628", "#F781BF", "#999999", "#017517", "#9932CC"), 
                    labels = cluster_labels, name = "Cluster") +
  labs(title = "ADMIXTURE Eastern Species(K=7)", y = "Ancestry Proportion")

ggsave("EasternK7_2.png", width = 20, height = 12, dpi = 500)


ggplot(admix_long, aes(x = Sample, y = Ancestry, fill = Cluster)) +
  geom_bar(stat = "identity", width = 1, color = "black") +  # Add black border
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 90, hjust = 1, size = 12, color = "black"),
    axis.text.y = element_text(color = "black"),
    axis.ticks = element_line(color = "black"),
    legend.text = element_text(size = 14),        # Increase legend text size
    legend.title = element_text(size = 16),       # Increase legend title size
    legend.key.size = unit(1, "cm")               # Increase size of color boxes
  ) +
  scale_fill_manual(values = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFFF33",
                               "#A65628", "#F781BF", "#999999", "#017517", "#9932CC"), 
                    labels = cluster_labels, name = "Cluster") +
  labs(title = "ADMIXTURE Western Species(K=7)", y = "Ancestry Proportion")

ggsave("WesternK7_2.png", width = 20, height = 12, dpi = 500)


dev.off()
