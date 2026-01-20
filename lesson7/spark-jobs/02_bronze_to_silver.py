"""
02_bronze_to_silver.py
======================
Transform Bronze layer data to Silver layer with cleaning and validation.

This job reads raw data from Bronze layer, applies data quality rules,
deduplicates records, and writes clean data to Silver layer as Parquet.

Usage:
    spark-submit --master spark://spark-master:7077 /opt/spark-jobs/02_bronze_to_silver.py
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, trim, lower, upper, when, coalesce, lit,
    current_timestamp, regexp_replace, to_date, to_timestamp
)
from pyspark.sql.types import IntegerType, DoubleType


def create_spark_session():
    """Create Spark session with MinIO configurations."""
    return SparkSession.builder \
        .appName("BronzeToSilver") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "minioadmin") \
        .config("spark.hadoop.fs.s3a.secret.key", "minioadmin") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.sql.adaptive.enabled", "true") \
        .getOrCreate()


def read_from_bronze(spark, table_name):
    """Read table from Bronze layer."""
    path = f"s3a://bronze/{table_name}"
    return spark.read.json(path)


def write_to_silver(df, table_name):
    """Write DataFrame to Silver layer as Parquet."""
    output_path = f"s3a://silver/{table_name}"
    
    # Add processing metadata
    df_with_metadata = df \
        .withColumn("_processed_at", current_timestamp()) \
        .withColumn("_quality_check", lit("passed"))
    
    # Write as Parquet (optimized for analytics)
    df_with_metadata.write \
        .format("parquet") \
        .mode("overwrite") \
        .save(output_path)
    
    print(f"✅ Wrote {df_with_metadata.count()} records to {output_path}")
    return df_with_metadata.count()


def clean_customer(df):
    """Clean and validate customer data."""
    return df \
        .dropDuplicates(["customer_id"]) \
        .filter(col("customer_id").isNotNull()) \
        .withColumn("first_name", trim(col("first_name"))) \
        .withColumn("last_name", trim(col("last_name"))) \
        .withColumn("email", lower(trim(col("email")))) \
        .withColumn("active", coalesce(col("active"), lit(True))) \
        .filter(col("email").rlike("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"))


def clean_rental(df):
    """Clean and validate rental data."""
    return df \
        .dropDuplicates(["rental_id"]) \
        .filter(col("rental_id").isNotNull()) \
        .filter(col("customer_id").isNotNull()) \
        .filter(col("rental_date").isNotNull()) \
        .withColumn("rental_duration_days", 
            when(col("return_date").isNotNull(),
                 (col("return_date").cast("long") - col("rental_date").cast("long")) / 86400
            ).otherwise(None))


def clean_payment(df):
    """Clean and validate payment data."""
    return df \
        .dropDuplicates(["payment_id"]) \
        .filter(col("payment_id").isNotNull()) \
        .filter(col("amount").isNotNull()) \
        .filter(col("amount") > 0) \
        .withColumn("amount", col("amount").cast(DoubleType()))


def clean_film(df):
    """Clean and validate film data."""
    return df \
        .dropDuplicates(["film_id"]) \
        .filter(col("film_id").isNotNull()) \
        .filter(col("title").isNotNull()) \
        .withColumn("title", trim(col("title"))) \
        .withColumn("rating", upper(trim(coalesce(col("rating"), lit("G")))))


def clean_category(df):
    """Clean and validate category data."""
    return df \
        .dropDuplicates(["category_id"]) \
        .filter(col("category_id").isNotNull()) \
        .withColumn("name", trim(col("name")))


def clean_inventory(df):
    """Clean and validate inventory data."""
    return df \
        .dropDuplicates(["inventory_id"]) \
        .filter(col("inventory_id").isNotNull()) \
        .filter(col("film_id").isNotNull())


# Mapping of tables to their cleaning functions
CLEANING_FUNCTIONS = {
    "customer": clean_customer,
    "rental": clean_rental,
    "payment": clean_payment,
    "film": clean_film,
    "category": clean_category,
    "inventory": clean_inventory
}


def main():
    """Main ETL pipeline: Bronze -> Silver Layer."""
    print("=" * 60)
    print("Starting Bronze to Silver ETL Pipeline")
    print("=" * 60)
    
    spark = create_spark_session()
    spark.sparkContext.setLogLevel("WARN")
    
    total_records = 0
    
    for table_name, clean_func in CLEANING_FUNCTIONS.items():
        print(f"\n🧹 Cleaning table: {table_name}")
        try:
            # Read from Bronze
            df_bronze = read_from_bronze(spark, table_name)
            bronze_count = df_bronze.count()
            print(f"   📊 Bronze records: {bronze_count}")
            
            # Apply cleaning transformations
            df_clean = clean_func(df_bronze)
            
            # Write to Silver
            silver_count = write_to_silver(df_clean, table_name)
            
            # Report data quality
            dropped = bronze_count - silver_count
            if dropped > 0:
                print(f"   ⚠️  Dropped {dropped} records due to quality issues")
            
            total_records += silver_count
            
        except Exception as e:
            print(f"❌ Error processing {table_name}: {str(e)}")
    
    print("\n" + "=" * 60)
    print(f"✅ Pipeline completed! Total clean records: {total_records}")
    print("=" * 60)
    
    spark.stop()


if __name__ == "__main__":
    main()
