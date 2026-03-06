from config_loader import get

cb_file = get('CB_UMI_SORTED')
gene_file = get('READ_GENE_SORTED')
out_file = get('CB_GENE_UMI')

print("Starting streaming merge...")

with open(cb_file) as cb_fh, \
     open(gene_file) as gene_fh, \
     open(out_file, "w") as out:

    cb_line = cb_fh.readline()
    gene_line = gene_fh.readline()

    while cb_line and gene_line:

        cb_parts = cb_line.strip().split("\t")
        gene_parts = gene_line.strip().split("\t")

        cb_id = cb_parts[0]
        gene_id = gene_parts[0]

        if cb_id == gene_id:
            cell_barcode = cb_parts[1]
            umi = cb_parts[2]
            gene_name = gene_parts[1]

            out.write(f"{cell_barcode}\t{gene_name}\t{umi}\n")

            cb_line = cb_fh.readline()
            gene_line = gene_fh.readline()

        elif cb_id < gene_id:
            cb_line = cb_fh.readline()
        else:
            gene_line = gene_fh.readline()

print("Merge complete.")
