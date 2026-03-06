import re
import pysam
import bisect
from config_loader import get

gtf_file = get('GTF_FILE')
bam_file = get('BAM_FILE')
output_file = get('READ_GENE_FILE')

print("Loading exons from GTF...")

exons = {}

with open(gtf_file) as gtf:
    for line in gtf:
        if line.startswith("#"):
            continue

        fields = line.strip().split("\t")

        if fields[2] != "exon":
            continue

        chrom = fields[0]
        start = int(fields[3])
        end = int(fields[4])

        match = re.search('gene_name "([^"]+)"', fields[8])
        if not match:
            continue

        gene_name = match.group(1)

        if chrom not in exons:
            exons[chrom] = []

        exons[chrom].append((start, end, gene_name))

# sort exons by start
for chrom in exons:
    exons[chrom].sort()
    
# create start position index
starts = {
    chrom: [e[0] for e in exons[chrom]]
    for chrom in exons
}

print("Finished loading GTF.")

print("Assigning genes (full dataset)...")

bam = pysam.AlignmentFile(bam_file, "rb")

with open(output_file, "w") as out:
    for read in bam.fetch(until_eof=True):

        if read.is_unmapped:
            continue

        if read.mapping_quality < 30:
            continue

        chrom = bam.get_reference_name(read.reference_id)

        if chrom not in exons:
            continue

        read_start = read.reference_start + 1
        read_end = read.reference_end

        exon_list = exons[chrom]
        start_list = starts[chrom]

        idx = bisect.bisect_left(start_list, read_start)

        # check nearby exons
        for i in range(max(0, idx-5), min(len(exon_list), idx+5)):
            exon_start, exon_end, gene_name = exon_list[i]
            if read_end >= exon_start and read_start <= exon_end:
                out.write(f"{read.query_name}\t{gene_name}\n")
                break

bam.close()

print("Gene assignment complete.")
