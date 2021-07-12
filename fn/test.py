import os
import pandas as pd
from google.cloud import storage

def fn():
    storage_client = storage.Client.from_service_account_json('/home/acamposc/claro/credentials/key.json')
    buckets_iter = storage_client.list_buckets()
    buckets_list = list(map(lambda x:x, buckets_iter))
    #return(print(buckets_list[0]))

    bucket = storage_client.get_bucket(buckets_list[0])
    #return(print(bucket))

    blobs = bucket.list_blobs()
    blob_list = list(map(lambda x:x, blobs))
    #return(print(blob_list[1]))

    blobw = bucket.get_blob(blob_list[1])
    #img = blob.time_created()
    #return(print(blobw))

    blob = bucket.blob(blob_list[1])
    blob.download_as_bytes()

   


    

fn()
