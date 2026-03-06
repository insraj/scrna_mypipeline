# Pipeline Configuration
# This file can be sourced by bash and parsed by Python

# Get BASE as parent directory of scripts directory
BASE=/home/phoenix/mypipeline

PYENV=${BASE}/.mypipeline
GENOME=${BASE}/mm10
FASTQ_BASE=${BASE}/fastqs
OUT=${BASE}/out

# Processing parameters
THREADS=16
SORT_MEM=30G
CELL_THRESHOLD=1000
START_FROM_STEP=1

# Genome files
GTF_FILE=${GENOME}/gencode.vM25.annotation.gtf
GENOME_FASTA=${GENOME}/mm10.fa
STAR_INDEX=${GENOME}/star_2.7.11b

# FASTQ directory
FASTQ_DIR=${FASTQ_BASE}/10k_Mouse_Neurons_3p_nextgem_fastqs/gex

# R1 FASTQ files
R1_L001=${FASTQ_DIR}/10k_Mouse_Neurons_3p_nextgem_gex_S1_L001_R1_001.fastq.gz
R1_L002=${FASTQ_DIR}/10k_Mouse_Neurons_3p_nextgem_gex_S1_L002_R1_001.fastq.gz
R1_L003=${FASTQ_DIR}/10k_Mouse_Neurons_3p_nextgem_gex_S1_L003_R1_001.fastq.gz
R1_L004=${FASTQ_DIR}/10k_Mouse_Neurons_3p_nextgem_gex_S1_L004_R1_001.fastq.gz

# R2 FASTQ files
R2_L001=${FASTQ_DIR}/10k_Mouse_Neurons_3p_nextgem_gex_S1_L001_R2_001.fastq.gz
R2_L002=${FASTQ_DIR}/10k_Mouse_Neurons_3p_nextgem_gex_S1_L002_R2_001.fastq.gz
R2_L003=${FASTQ_DIR}/10k_Mouse_Neurons_3p_nextgem_gex_S1_L003_R2_001.fastq.gz
R2_L004=${FASTQ_DIR}/10k_Mouse_Neurons_3p_nextgem_gex_S1_L004_R2_001.fastq.gz

# Output files
BAM_FILE=${OUT}/sample1_name_sorted.bam
CB_UMI_FILE=${OUT}/cb_umi_all.tsv
CB_UMI_SORTED=${OUT}/cb_umi_all_name_sorted.tsv
READ_GENE_FILE=${OUT}/read_gene.tsv
READ_GENE_SORTED=${OUT}/read_gene_name_sorted.tsv
CB_GENE_UMI=${OUT}/cb_gene_umi.tsv
CB_GENE_UMI_SORTED=${OUT}/cb_gene_umi_sorted.tsv
CB_GENE_COUNTS=${OUT}/cb_gene_counts.tsv
CB_GENE_COUNTS_FILTERED=${OUT}/cb_gene_counts_filtered.tsv
