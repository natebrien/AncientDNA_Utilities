#! /usr/bin/bash
## Copyright (C) 2026 by Natassja Brien, McMaster University, Canada
set -euo pipefail

## Script for generating edit distance plots for mapped bam files
## SCript usage

echo "Usage: ./generate_edit_distance_plots.sh <input_bam_file> <reference_genome>"
echo "Generating edit distance plots for mapped bam files..."

#Script variable definitions - remember to not have spaces around the equal sign when defining variables in bash!
bam=$1
ref=$2
prefix=$(basename ${bam%%.*})

## Checking variables
echo "Input BAM file: $bam"
echo "Reference genome: $ref"  

## First we need to make sure NM tags are present in the bam files. If not, we will add them using samtools calmd.

if [[ -z "$(samtools view "$bam" | head -n 20 | grep -m1 'NM:i:' || true)" ]]; then
    echo "BAM file does not contain NM tags. Adding NM tags using samtools calmd..."
    samtools calmd -b $bam $ref > ${prefix}_calmd.bam
    bam_md="${prefix}_calmd.bam"
    samtools view $bam_md | awk '{for(i=12;i<=NF;i++) if($i ~ /^NM:i:/) print substr($i,6)}' > ${prefix}_edit_distances.txt
    else
    echo "BAM file contains NM tags. Extracting edit distance values..."
    samtools view $bam | awk '{for(i=12;i<=NF;i++) if($i ~ /^NM:i:/) print substr($i,6)}' > ${prefix}_edit_distances.txt
fi

## Plotting edit distance distributions for each bam file using R.
```
/usr/bin/Rscript -e "
library(tidyverse)
library(ggplot2)
library(viridis)

# Read edit distance values from the text file

edit_distances <- read.table('${prefix}_edit_distances.txt', header = FALSE)
colnames(edit_distances) <- c('EditDistance')

# Create a histogram of edit distances
p <- ggplot(edit_distances, aes(x = EditDistance, fill = factor(EditDistance))) +
    geom_bar() +
    theme_minimal() +
    scale_fill_viridis(discrete = TRUE) +
    labs(title = 'Edit Distance Distribution for ${prefix}', x = 'Edit Distance', y = 'Frequency')    

# print the plot to a PDF file
ggsave('${prefix}_edit_distance_plot.pdf', plot = p, width = 8, height = 6)
"
    
```
## Aggregating plots into a single PDF file for easier visualization and comparison.
eval "$(conda shell.bash hook)"
if ! conda env list | grep -q '^pdfunite '; then
    conda create -n pdfunite -c conda-forge poppler -y
fi
conda activate pdfunite
pdfunite *_edit_distance_plot.pdf All_edit_distance_plot_aggregated.pdf
