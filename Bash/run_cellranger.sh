# Define directories for input FASTQ files, output results, and reference genome index
FASTQ_DIR="/path/samples/"          # Directory containing sample FASTQ files
OUT_DIR="/path/output"              # Output directory for Cell Ranger results
REF_DIR="/path/cellranger_index/"   # Directory containing the reference transcriptome for Cell Ranger
PROJECT_NAME="project"              # Project name for job submission

# Define an array of sample names to process
SAMPLES=("sample1" "sample2" "sample3")

# Ensure the output directory exists, create if it doesn't
mkdir -p $OUT_DIR

# Iterate over each sample in the list
for SAMPLE in "${SAMPLES[@]}"; do

    # Define the directory containing FASTQ files for the current sample
    SAMPLE_FASTQ_DIR="$FASTQ_DIR/$SAMPLE"

    # Define the name of the job script for this sample
    JOB_SCRIPT="${SAMPLE}_cellranger_count.sh"

    # Create a job script for the current sample
    echo "#!/bin/bash" > $JOB_SCRIPT
    echo "#$ -cwd" >> $JOB_SCRIPT                        # Run the job from the current working directory
    echo "#$ -N ${SAMPLE}_count" >> $JOB_SCRIPT          # Name of the job
    echo "#$ -o ${SAMPLE}_count.out" >> $JOB_SCRIPT      # Standard output file
    echo "#$ -e ${SAMPLE}_count.err" >> $JOB_SCRIPT      # Standard error file
    echo "#$ -pe omp 32" >> $JOB_SCRIPT                 # Request 32 CPU cores
    echo "#$ -l mem_free=64G" >> $JOB_SCRIPT            # Request 64GB of memory
    echo "#$ -l h_rt=24:00:00" >> $JOB_SCRIPT           # Set maximum runtime of 24 hours
    echo "#$ -P $PROJECT_NAME" >> $JOB_SCRIPT           # Assign job to the specified project

    # Load required modules for the job
    echo "module load bcl2fastq" >> "$JOB_SCRIPT"       # Load the bcl2fastq module
    echo "module load cellranger" >> "$JOB_SCRIPT"      # Load the Cell Ranger module

    # Change to the output directory before running the analysis
    echo "cd $OUT_DIR" >> $JOB_SCRIPT

    # Command to run Cell Ranger count for the current sample
    echo "cellranger count --id=${SAMPLE} \\" >> $JOB_SCRIPT
    echo "                --transcriptome=$REF_DIR \\" >> $JOB_SCRIPT  # Specify reference transcriptome
    echo "                --create-bam=true \\" >> $JOB_SCRIPT         # Generate BAM file
    echo "                --fastqs=$SAMPLE_FASTQ_DIR \\" >> $JOB_SCRIPT # Provide directory containing FASTQ files
    echo "                --sample=$SAMPLE \\" >> $JOB_SCRIPT          # Specify sample name
    echo "                --localmem=128 \\" >> $JOB_SCRIPT            # Allocate 128GB memory for Cell Ranger
    echo "                --localcores=16" >> $JOB_SCRIPT               # Use 16 CPU cores

    # Submit the job script to the cluster
    qsub $JOB_SCRIPT 

done
