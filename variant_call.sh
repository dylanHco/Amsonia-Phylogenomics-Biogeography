#!/bin/bash
set -eo pipefail  # Stop on errors and fail on pipeline errors

# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate extraction

# Usage: bash variantcall.sh reference.fasta /path/to/fastq/
# Arguments:
#   $1 - Reference genome (FASTA)
#   $2 - Directory containing FASTQ files

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <reference.fasta> <fastq_directory>"
    exit 1
fi

reference=$1
fastq_dir=$2
log_file="variantcall.log"

echo "Starting pipeline..." | tee "$log_file"

### --- Process Reference Only Once --- ###
if [ ! -f "${reference}.fai" ] || [ ! -f "${reference%.fasta}.dict" ]; then
    echo "Processing reference genome..." | tee -a "$log_file"
    gatk CreateSequenceDictionary -R "$reference"
    bwa index "$reference"
    samtools faidx "$reference"
else
    echo "Reference genome already indexed. Skipping..." | tee -a "$log_file"
fi

### --- Function to Process a Single Sample --- ###
process_sample() {
    local read1="$1"
    local read2="${read1/_R1_/_R2_}"  # Infer R2 filename
    local prefix=$(basename "$read1" | sed 's/_R1_*//')  # Extract sample name

    echo "Processing sample: $prefix" | tee -a "$log_file"

    # Align reads
    bwa mem "$reference" "$read1" "$read2" | samtools view -bS - | samtools sort - -o "$prefix.sorted.bam"

    # Convert FASTQ to BAM
    gatk FastqToSam -F1 "$read1" -F2 "$read2" -O "$prefix.unmapped.bam" -SM "$prefix"

    # Add read groups
    gatk AddOrReplaceReadGroups -I "$prefix.sorted.bam" -O "$prefix.sorted-RG.bam" -RGID 2 -RGLB lib1 -RGPL illumina -RGPU unit1 -RGSM "$prefix"
    gatk AddOrReplaceReadGroups -I "$prefix.unmapped.bam" -O "$prefix.unmapped-RG.bam" -RGID 2 -RGLB lib1 -RGPL illumina -RGPU unit1 -RGSM "$prefix"

    # Merge BAM files
    gatk MergeBamAlignment --ALIGNED_BAM "$prefix.sorted-RG.bam" --UNMAPPED_BAM "$prefix.unmapped-RG.bam" -O "$prefix.merged.bam" -R "$reference"

    # Remove duplicates
    gatk MarkDuplicates -I "$prefix.merged.bam" -O "$prefix.marked.bam" -M "$prefix.metrics.txt"
    samtools index "$prefix.marked.bam"

    # Call variants
    gatk HaplotypeCaller -I "$prefix.marked.bam" -O "$prefix-g.vcf" -ERC GVCF -R "$reference"

    # Cleanup intermediate files
    rm "$prefix.sorted.bam" "$prefix.unmapped.bam" "$prefix.merged.bam" "$prefix.unmapped-RG.bam" "$prefix.sorted-RG.bam"

    echo "Completed sample: $prefix" | tee -a "$log_file"
}

export -f process_sample  # Needed for parallel execution
export reference log_file  # Ensure variables are available in subshells

### --- Run for All Samples in Folder Using Parallel --- ###
find "$fastq_dir" -name '*_R1_paired.*fastq.gz' | sort | parallel -j 4 process_sample  # Adjust `-j` based on CPU core

echo "All samples processed successfully!" | tee -a "$log_file"
