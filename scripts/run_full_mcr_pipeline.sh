#!/usr/bin/env bash

############################################
# CONFIGURATION
############################################

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the configuration file
source "$SCRIPT_DIR/config.sh"

# Activate Python virtual environment
source ${PYENV}/bin/activate

echo "START_FROM_STEP=$START_FROM_STEP"

# Start overall pipeline timer
PIPELINE_START=$(date +%s)

mkdir -p $GENOME
mkdir -p $FASTQ_BASE
mkdir -p $OUT

############################################
echo "STEP 1: Download 10x FASTQ dataset"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 1"
if [ "$START_FROM_STEP" -le 1 ]; then
  cd $FASTQ_BASE

  wget -q https://s3-us-west-2.amazonaws.com/10x.files/samples/cell-exp/8.0.0/10k_Mouse_Neurons_3p_nextgem_Multiplex/10k_Mouse_Neurons_3p_nextgem_Multiplex_fastqs.tar > /dev/null

  echo "Extracting FASTQ tar"
  tar -xvf 10k_Mouse_Neurons_3p_nextgem_Multiplex_fastqs.tar

  echo "Listing FASTQ directory"
  ls 10k_Mouse_Neurons_3p_nextgem_fastqs/gex
else
  echo "Skipping STEP 1 (START_FROM_STEP=$START_FROM_STEP)"
fi

STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 1 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 2: Download genome (mm10)"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 2"
if [ "$START_FROM_STEP" -le 2 ]; then
  cd $GENOME

  if [ ! -f "$GENOME_FASTA" ]; then
    wget -q https://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz
    gunzip mm10.fa.gz
  fi

  if [ ! -f "$GTF_FILE" ]; then
    wget -q https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M25/gencode.vM25.annotation.gtf.gz
    gunzip gencode.vM25.annotation.gtf.gz
  fi
else
  echo "Skipping STEP 2 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 2 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 3: Build STAR genome"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 3"
if [ "$START_FROM_STEP" -le 3 ]; then
    STAR \
      --runMode genomeGenerate \
      --genomeDir $STAR_INDEX \
      --genomeFastaFiles $GENOME_FASTA \
      --sjdbGTFfile $GTF_FILE \
      --sjdbOverhang 100 \
      --runThreadN 4 \
      --limitGenomeGenerateRAM 24000000000
else
  echo "Skipping STEP 3 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 3 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 4: Align R2 reads"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 4"
if [ "$START_FROM_STEP" -le 4 ]; then
  cd $OUT

  STAR \
    --genomeDir $STAR_INDEX \
    --readFilesIn \
    $R2_L001,$R2_L002,$R2_L003,$R2_L004 \
    --readFilesCommand "pigz -dc -p 4" \
    --runThreadN $THREADS \
    --outSAMtype BAM SortedByCoordinate \
    --outSAMattributes NH HI AS nM \
    --outFilterMultimapNmax 1 \
    --outFilterMismatchNoverLmax 0.04 \
    --outFileNamePrefix sample1_
else
  echo "Skipping STEP 4 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 4 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 5: Name-sort BAM"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 5"
if [ "$START_FROM_STEP" -le 5 ]; then
  samtools sort -n \
    -o sample1_name_sorted.bam \
    sample1_Aligned.sortedByCoord.out.bam
else
  echo "Skipping STEP 5 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 5 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 6: Extract CB + UMI"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 6"
if [ "$START_FROM_STEP" -le 6 ]; then
  cd $OUT
  python3 $SCRIPT_DIR/step6_extract_all_cb_umi.py

  sort -k1,1 -T $OUT -S $SORT_MEM \
    cb_umi_all.tsv > cb_umi_all_name_sorted.tsv
  rm -f cb_umi_all.tsv # remove unsorted intermediate
else
  echo "Skipping STEP 6 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 6 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 7: Assign genes"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 7"
if [ "$START_FROM_STEP" -le 7 ]; then
  cd $OUT
  python3 $SCRIPT_DIR/step7_assign_gene_full.py

  sort -k1,1 -T $OUT -S $SORT_MEM \
    read_gene.tsv > read_gene_name_sorted.tsv
  rm -f read_gene.tsv # remove unsorted intermediate
else
  echo "Skipping STEP 7 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 7 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 8: Merge CB + Gene"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 8"
if [ "$START_FROM_STEP" -le 8 ]; then
  cd $OUT
  python3 $SCRIPT_DIR/step8_merge_cb_gene.py
else
  echo "Skipping STEP 8 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 8 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 9: Sort by CB,GENE,UMI"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 9"
if [ "$START_FROM_STEP" -le 9 ]; then
  cd $OUT
  sort -k1,1 -k2,2 -k3,3 \
    -T $OUT -S 50G \
    cb_gene_umi.tsv > cb_gene_umi_sorted.tsv
  rm -f cb_gene_umi.tsv # remove unsorted intermediate
else
  echo "Skipping STEP 9 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 9 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 10: Collapse UMI"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 10"
if [ "$START_FROM_STEP" -le 10 ]; then
  cd $OUT
  python3 $SCRIPT_DIR/step10_collapse_umi.py
else
  echo "Skipping STEP 10 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 10 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 11: Barcode rank & cell calling"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 11"
if [ "$START_FROM_STEP" -le 11 ]; then
  cd $OUT
  awk '{sum[$1]+=$3} END {for (cb in sum) print cb"\t"sum[cb]}' \
  cb_gene_counts.tsv > barcode_total_counts.tsv

  sort -k2,2nr barcode_total_counts.tsv > barcode_ranked.tsv
  rm -f barcode_total_counts.tsv # remove intermediate
  awk -v thresh=$CELL_THRESHOLD \
  '$2>=thresh {print $1}' barcode_ranked.tsv \
  > cell_whitelist.txt
else
  echo "Skipping STEP 11 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 11 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 12: Filter real cells"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 12"
if [ "$START_FROM_STEP" -le 12 ]; then
  cd $OUT
  grep -F -f cell_whitelist.txt \
  cb_gene_counts.tsv > cb_gene_counts_filtered.tsv
else
  echo "Skipping STEP 12 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 12 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 13: Build 10x matrix"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 13"
if [ "$START_FROM_STEP" -le 13 ]; then
  cd $OUT
  cp cell_whitelist.txt barcodes.tsv

  cut -f2 cb_gene_counts_filtered.tsv \
  | sort | uniq > features.tsv

  awk '{print $1"\t"$1"\tGene Expression"}' \
  features.tsv > features_fixed.tsv

  mv features_fixed.tsv features.tsv

  python3 $SCRIPT_DIR/step13_build_matrix.py
else
  echo "Skipping STEP 13 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 13 completed in ${STEP_DURATION}s"
echo ""

############################################
echo "STEP 14: Gzip and validate matrix"
############################################
STEP_START=$(date +%s)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STEP 14"
if [ "$START_FROM_STEP" -le 14 ]; then
  cd $OUT
  
  echo "Gzipping matrix files..."
  gzip -f matrix.mtx
  gzip -f barcodes.tsv
  gzip -f features.tsv
  
  echo "Validating matrix with scanpy..."
  python3 $SCRIPT_DIR/validate_matrix.py
else
  echo "Skipping STEP 14 (START_FROM_STEP=$START_FROM_STEP)"
fi
STEP_END=$(date +%s)
STEP_DURATION=$((STEP_END - STEP_START))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP 14 completed in ${STEP_DURATION}s"
echo ""

PIPELINE_END=$(date +%s)
TOTAL_DURATION=$((PIPELINE_END - PIPELINE_START))
echo "============================================"
echo "Pipeline complete."
echo "Total time: ${TOTAL_DURATION}s ($(printf '%dh %dm %ds' $((TOTAL_DURATION/3600)) $((TOTAL_DURATION%3600/60)) $((TOTAL_DURATION%60))))"
echo "Final output:"
echo "  matrix.mtx.gz"
echo "  barcodes.tsv.gz"
echo "  features.tsv.gz"
