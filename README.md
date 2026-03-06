# Single-Cell RNA-seq Pipeline

NOTE: Basic script for understanding RNA-Seq pipeline to generate cells x genes matrix data. This script generated using an AI agent.

A custom implementation of a single-cell RNA-seq processing pipeline for 10x Genomics data, built from scratch to replicate core Cell Ranger functionality.

## Overview

This pipeline processes 10x Genomics single-cell RNA-seq data from raw FASTQ files through to a cell-by-gene expression matrix. It implements the essential steps of cell barcode extraction, UMI deduplication, read alignment, gene assignment, and cell calling.

## Requirements

### Software Dependencies
- STAR aligner (v2.7.11b or later)
- samtools
- Python 3.8+
- pigz (parallel gzip)
- GNU sort with large memory support

### Python Packages
- pysam
- scanpy (for validation)

### System Requirements
- 64GB RAM minimum (for sorting large files)
- 100GB+ disk space
- Multi-core CPU (16+ cores recommended)

## Directory Structure

```
mypipeline/
├── README.md                  # This file
├── scripts/
│   ├── config.sh             # Pipeline configuration
│   ├── config_loader.py      # Python config parser
│   ├── run_full_mcr_pipeline.sh  # Main pipeline script
│   ├── step6_extract_all_cb_umi.py
│   ├── step7_assign_gene_full.py
│   ├── step8_merge_cb_gene.py
│   ├── step10_collapse_umi.py
│   ├── step13_build_matrix.py
│   └── validate_matrix.py
├── fastqs/                   # Raw FASTQ files
│   └── gex/
├── mm10/                     # Reference genome
│   ├── mm10.fa
│   ├── gencode.vM25.annotation.gtf
│   └── star_2.7.11b/        # STAR index
└── out/                      # Pipeline outputs
```

## Configuration

Edit `scripts/config.sh` to customize pipeline parameters:

```bash
# Key parameters
THREADS=16              # Number of CPU threads
SORT_MEM=30G           # Memory for sort operations
CELL_THRESHOLD=1000    # Minimum UMI count for cell calling
START_FROM_STEP=6      # Skip completed steps
```

## Pipeline Steps

### STEP 1: Download 10x FASTQ Dataset
Downloads the 10k Mouse Neurons 3' multiplex FASTQ dataset from 10x Genomics.

### STEP 2: Download Genome (mm10)
Downloads the mouse reference genome (mm10) and GENCODE annotation (vM25).

### STEP 3: Build STAR Genome Index
Generates STAR genome index with splice junction database from the GTF annotation.

### STEP 4: Align R2 Reads
Aligns R2 reads (cDNA sequences) to the reference genome using STAR.
- Filters multi-mapped reads
- Outputs coordinate-sorted BAM

### STEP 5: Name-sort BAM
Sorts BAM file by read name for paired processing with R1 data.

### STEP 6: Extract Cell Barcodes + UMI
Extracts 16bp cell barcode (CB) and 12bp UMI from R1 reads, pairs with R2 read names.

**Input:** R1 FASTQ files, name-sorted BAM  
**Output:** `cb_umi_all.tsv`, `cb_umi_all_name_sorted.tsv`

### STEP 7: Assign Genes
Assigns genes to each aligned read based on GTF annotation using exon overlap.

**Input:** Name-sorted BAM, GTF file  
**Output:** `read_gene.tsv`, `read_gene_name_sorted.tsv`

### STEP 8: Merge CB + Gene
Joins cell barcode/UMI information with gene assignments by read name.

**Input:** `cb_umi_all_name_sorted.tsv`, `read_gene_name_sorted.tsv`  
**Output:** `cb_gene_umi.tsv`

### STEP 9: Sort by CB, Gene, UMI
Sorts merged data to prepare for UMI deduplication.

**Output:** `cb_gene_umi_sorted.tsv`

### STEP 10: Collapse UMI
Deduplicates UMIs accounting for sequencing errors (1-mismatch tolerance).

**Input:** `cb_gene_umi_sorted.tsv`  
**Output:** `cb_gene_counts.tsv`

### STEP 11: Barcode Rank & Cell Calling
Performs cell calling based on UMI count threshold (knee detection).

**Output:** 
- `barcode_total_counts.tsv`
- `barcode_ranked.tsv`
- `cell_whitelist.txt`

### STEP 12: Filter Real Cells
Filters expression matrix to include only called cells.

**Output:** `cb_gene_counts_filtered.tsv`

### STEP 13: Build 10x Matrix
Creates Matrix Market format files compatible with 10x Genomics standards.

**Output:**
- `barcodes.tsv` - Cell barcodes
- `features.tsv` - Gene IDs/names
- `matrix.mtx` - Expression matrix (sparse format)

### STEP 14: Gzip and Validate Matrix
Compresses matrix files and validates the output using scanpy.

**Final Output:**
- `matrix.mtx.gz`
- `barcodes.tsv.gz`
- `features.tsv.gz`

## Running the Pipeline

### Full Pipeline
```bash
cd BASE_Directory
bash scripts/run_full_mcr_pipeline.sh
```

### Resume from Specific Step
Edit `config.sh` to set `START_FROM_STEP`:
```bash
START_FROM_STEP=10  # Skip steps 1-9
```

### Activate Python Environment
```bash
source .mypipeline/bin/activate
```

## Output Format

The final output follows the 10x Genomics Matrix Market standard:

- **matrix.mtx.gz**: Sparse matrix in Matrix Market format (genes × cells)
- **barcodes.tsv.gz**: Cell barcode whitelist (one per line)
- **features.tsv.gz**: Gene information (gene_id, gene_name, feature_type)

These files can be loaded into downstream analysis tools like:
- Scanpy: `sc.read_10x_mtx()`
- Seurat: `Read10X()`
- Cell Ranger: Compatible with standard workflows

## Validation

The pipeline includes validation using scanpy:
```python
import scanpy as sc
adata = sc.read_10x_mtx('out/', var_names='gene_symbols')
print(adata)
```

Expected output shows:
- Number of cells (observations)
- Number of genes (variables)
- Matrix dimensions and sparsity

## Performance Notes

- **Step 6** (CB/UMI extraction): ~30-60 minutes
- **Step 7** (Gene assignment): ~2-4 hours
- **Step 9** (Large sort): ~1-2 hours, requires 30-50GB RAM
- **Total runtime**: 4-8 hours depending on hardware

## Troubleshooting

### KeyError in step13_build_matrix.py
Ensure gene names in `features.tsv` match those in `cb_gene_counts_filtered.tsv`. The script now correctly parses the first column from the 3-column features file.

### Memory Issues in Sorting
Increase `SORT_MEM` in `config.sh` or reduce the temporary file size by filtering earlier in the pipeline.

### STAR Alignment Fails
Check that the STAR index version matches your STAR executable version. Rebuild the index if necessary.

## Citation

This pipeline implements methods similar to:
- Zheng et al. (2017) "Massively parallel digital transcriptional profiling of single cells"
- Cell Ranger from 10x Genomics

## License

This is a custom implementation for educational and research purposes.
