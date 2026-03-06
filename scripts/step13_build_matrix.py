import sys
from config_loader import get

counts_file = get('CB_GENE_COUNTS_FILTERED')
barcode_file = f"{get('OUT')}/barcodes.tsv"
gene_file = f"{get('OUT')}/features.tsv"
matrix_file = f"{get('OUT')}/matrix.mtx"

print("Loading barcodes...")
barcodes = {}
with open(barcode_file) as f:
    for i, line in enumerate(f, 1):
        barcodes[line.strip()] = i

print("Loading genes...")
genes = {}
with open(gene_file) as f:
    for i, line in enumerate(f, 1):
        # features.tsv has 3 columns: gene_id, gene_name, Gene Expression
        # Use the first column (gene_id) as the key
        gene_id = line.strip().split('\t')[0]
        genes[gene_id] = i

print("Building matrix entries...")

entries = []

with open(counts_file) as f:
    for line in f:
        cb, gene, count = line.strip().split("\t")
        row = genes[gene]
        col = barcodes[cb]
        entries.append((row, col, count))

print("Writing Matrix Market file...")

with open(matrix_file, "w") as out:
    out.write("%%MatrixMarket matrix coordinate integer general\n")
    out.write(f"{len(genes)} {len(barcodes)} {len(entries)}\n")

    for row, col, count in entries:
        out.write(f"{row} {col} {count}\n")

print("Matrix build complete.")
