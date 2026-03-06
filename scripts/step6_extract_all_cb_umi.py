import gzip
from config_loader import get

r1_files = [
    get('R1_L001'),
    get('R1_L002'),
    get('R1_L003'),
    get('R1_L004'),
]

output_file = get('CB_UMI_FILE')

with open(output_file, "w") as out:

    for r1_file in r1_files:
        print(f"Processing {r1_file}")

        with gzip.open(r1_file, "rt") as f:
            while True:
                header = f.readline()
                if not header:
                    break

                seq = f.readline().strip()
                f.readline()
                f.readline()

                read_id = header.split()[0][1:]
                cb = seq[:16]
                ub = seq[16:28]

                out.write(f"{read_id}\t{cb}\t{ub}\n")

print("Finished extracting all CB/UMI.")
