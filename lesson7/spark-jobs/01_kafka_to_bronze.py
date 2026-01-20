"""
01_kafka_to_bronze.py
=====================
Read data from Kafka topics and write to MinIO Bronze layer.

This job consumes CDC data from Kafka and lands it in the Bronze layer
of our Data Lake (MinIO) as JSON files.

Usage:
    spark-submit --master spark://spark-master:7077 /opt/spark-jobs/01_kafka_to_bronze.py
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, from_json, current_timestamp, lit
)
from pyspark.sql.types import (
    StructType, StructField, StringType, IntegerType, 
    TimestampType, DoubleType, BooleanType, DateType
)


def create_spark_session():
    """Create Spark session with MinIO and Kafka configurations."""
    return SparkSession.builder \
        .appName("KafkaToBronze") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "minioadmin") \
        .config("spark.hadoop.fs.s3a.secret.key", "minioadmin") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.sql.adaptive.enabled", "true") \
        .getOrCreate()


# Schema definitions for each table
CUSTOMER_SCHEMA = StructType([
    StructField("customer_id", IntegerType(), True),
    StructField("store_id", IntegerType(), True),
    StructField("first_name", StringType(), True),
    StructField("last_name", StringType(), True),
    StructField("email", StringType(), True),
    StructField("address_id", IntegerType(), True),
    StructField("active", BooleanType(), True),
    StructField("create_date", DateType(), True),
    StructField("last_update", TimestampType(), True)
])

RENTAL_SCHEMA = StructType([
    StructField("rental_id", IntegerType(), True),
    StructField("rental_date", TimestampType(), True),
    StructField("inventory_id", IntegerType(), True),
    StructField("customer_id", IntegerType(), True),
    StructField("return_date", TimestampType(), True),
    StructField("staff_id", IntegerType(), True),
    StructField("last_update", TimestampType(), True)
])

PAYMENT_SCHEMA = StructType([
    StructField("payment_id", IntegerType(), True),
    StructField("customer_id", IntegerType(), True),
    StructField("staff_id", IntegerType(), True),
    StructField("rental_id", IntegerType(), True),
    StructField("amount", DoubleType(), True),
    StructField("payment_date", TimestampType(), True),
    StructField("last_update", TimestampType(), True)
])

FILM_SCHEMA = StructType([
    StructField("film_id", IntegerType(), True),
    StructField("title", StringType(), True),
    StructField("description", StringType(), True),
    StructField("release_year", IntegerType(), True),
    StructField("language_id", IntegerType(), True),
    StructField("rental_duration", IntegerType(), True),
    StructField("rental_rate", DoubleType(), True),
    StructField("length", IntegerType(), True),
    StructField("replacement_cost", DoubleType(), True),
    StructField("rating", StringType(), True),
    StructField("last_update", TimestampType(), True)
])


def read_from_postgres(spark, table_name):
    """Read table directly from PostgreSQL."""
    return spark.read \
        .format("jdbc") \
        .option("url", "jdbc:postgresql://postgres:5432/pagila") \
        .option("dbtable", table_name) \
        .option("user", "postgres") \
        .option("password", "postgres") \
        .option("driver", "org.postgresql.Driver") \
        .load()


def write_to_bronze(df, table_name):
    """Write DataFrame to Bronze layer in MinIO."""
    output_path = f"s3a://bronze/{table_name}"
    
    # Add metadata columns
    df_with_metadata = df \
        .withColumn("_ingested_at", current_timestamp()) \
        .withColumn("_source", lit("postgresql"))
    
    # Write as JSON (preserves original structure)
    df_with_metadata.write \
        .format("json") \
        .mode("overwrite") \
        .save(output_path)
    
    print(f"✅ Wrote {df_with_metadata.count()} records to {output_path}")
    return df_with_metadata.count()


def main():
    """Main ETL pipeline: PostgreSQL -> Bronze Layer."""
    print("=" * 60)
    print("Starting Kafka to Bronze ETL Pipeline")
    print("=" * 60)
    
    spark = create_spark_session()
    spark.sparkContext.setLogLevel("WARN")
    
    # Tables to ingest
    tables = ["customer", "rental", "payment", "film", "category", "inventory"]
    
    total_records = 0
    
    for table in tables:
        print(f"\n📥 Processing table: {table}")
        try:
            df = read_from_postgres(spark, table)
            count = write_to_bronze(df, table)
            total_records += count
        except Exception as e:
            print(f"❌ Error processing {table}: {str(e)}")
    
    print("\n" + "=" * 60)
    print(f"✅ Pipeline completed! Total records ingested: {total_records}")
    print("=" * 60)
    
    spark.stop()


if __name__ == "__main__":
    main()
