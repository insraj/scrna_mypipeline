import scanpy as sc
from config_loader import get

adata = sc.read_10x_mtx(
    get('OUT'),
    var_names='gene_symbols',
    cache=False
)

print(adata)
