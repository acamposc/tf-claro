import os
import pandas as pd
from google.cloud import storage
'''
parts = dask.delayed(pd.read_excel)("/home/acamposc/claro/ECOMMERCE_INK_VALIDACIONES_V2 - copia.xlsx", sheet_name=0)
df = dd.from_delayed(parts)

test = dask.compute(df)
print(test)

'''

'''
def upload_to_bucket(data, context):
    from google.cloud import storage
    client = storage.Client()
    bucket = storage.Bucket('claro-ecommerce-analitica-files_input', user_project='claro-ecommerce-analitica')
    all_blobs = list(client.list_blobs('claro-ecommerce-analitica-files_input'))
    tst = pd.DataFrame(all_blobs)
    data = tst.to_csv('./data.csv')
    blob = bucket.blob('claro-ecommerce-analitica-files_output/data.csv')
    blob.upload_from_filename('data.csv')

'''

def upload_to_bucket(data, context):
    from google.cloud import storage
    storage_client = storage.Client()
    buckets = storage_client.list_buckets()
    return print(buckets)

