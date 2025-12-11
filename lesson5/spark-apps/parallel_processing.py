from pyspark.sql import SparkSession
from pyspark.sql.functions import col, rand
import time

spark = SparkSession.builder \
    .appName("ParallelProcessing") \
    .master("spark://spark-master:7077") \
    .config("spark.executor.instances", "3") \
    .config("spark.executor.cores", "2") \
    .config("spark.executor.memory", "2g") \
    .getOrCreate()

# Create large dataset
print("Creating dataset with 10 million rows...")
df = spark.range(0, 10000000).withColumn("random_value", rand())

# Repartition to ensure work is distributed
df = df.repartition(12)  # 3 workers * 2 cores * 2 tasks per core

# Perform computation
print("Starting distributed computation...")
start_time = time.time()

result = df.groupBy((col("id") % 100).alias("partition")) \
    .agg({"random_value": "avg", "id": "count"}) \
    .orderBy("partition")

# Trigger action
count = result.count()
end_time = time.time()

print(f"\\nProcessed {count} partitions in {end_time - start_time:.2f} seconds")
print("\\nSample results:")
result.show(10)

# Check partition distribution
print("\\nNumber of partitions:", df.rdd.getNumPartitions())

spark.stop()
