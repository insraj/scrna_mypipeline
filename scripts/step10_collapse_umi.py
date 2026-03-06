from config_loader import get

input_file = get('CB_GENE_UMI_SORTED')
output_file = get('CB_GENE_COUNTS')

print("Starting UMI collapsing...")

with open(input_file) as infile, open(output_file, "w") as out:

    prev_cb = None
    prev_gene = None
    prev_umi = None

    umi_count = 0

    for line in infile:
        cb, gene, umi = line.strip().split("\t")

        # new (CB, GENE) group
        if cb != prev_cb or gene != prev_gene:

            if prev_cb is not None:
                out.write(f"{prev_cb}\t{prev_gene}\t{umi_count}\n")

            prev_cb = cb
            prev_gene = gene
            prev_umi = umi
            umi_count = 1

        else:
            # same CB + GENE
            if umi != prev_umi:
                umi_count += 1
                prev_umi = umi

    # write last group
    if prev_cb is not None:
        out.write(f"{prev_cb}\t{prev_gene}\t{umi_count}\n")

print("UMI collapsing complete.")
