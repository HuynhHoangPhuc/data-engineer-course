"""
03_silver_to_gold.py
====================
Create business-ready aggregations in Gold layer.

This job reads clean data from Silver layer and creates aggregated
datasets optimized for business analytics and reporting.

Usage:
    spark-submit --master spark://spark-master:7077 /opt/spark-jobs/03_silver_to_gold.py
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, sum, count, avg, max, min, round,
    year, month, dayofweek, date_format,
    current_timestamp, lit, dense_rank, percent_rank
)
from pyspark.sql.window import Window


def create_spark_session():
    """Create Spark session with MinIO configurations."""
    return SparkSession.builder \
        .appName("SilverToGold") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "minioadmin") \
        .config("spark.hadoop.fs.s3a.secret.key", "minioadmin") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.sql.adaptive.enabled", "true") \
        .getOrCreate()


def read_from_silver(spark, table_name):
    """Read table from Silver layer."""
    path = f"s3a://silver/{table_name}"
    return spark.read.parquet(path)


def write_to_gold(df, dataset_name, partition_cols=None):
    """Write DataFrame to Gold layer as Parquet."""
    output_path = f"s3a://gold/{dataset_name}"
    
    # Add metadata
    df_with_metadata = df \
        .withColumn("_aggregated_at", current_timestamp())
    
    writer = df_with_metadata.write \
        .format("parquet") \
        .mode("overwrite")
    
    if partition_cols:
        writer = writer.partitionBy(*partition_cols)
    
    writer.save(output_path)
    
    print(f"✅ Wrote {df_with_metadata.count()} records to {output_path}")
    return df_with_metadata.count()


def create_monthly_revenue(spark):
    """
    Create monthly revenue aggregation by film category.
    
    Business Question: What is the revenue trend by category over time?
    """
    print("\n📊 Creating Monthly Revenue by Category...")
    
    # Read required tables
    payment = read_from_silver(spark, "payment")
    rental = read_from_silver(spark, "rental")
    inventory = read_from_silver(spark, "inventory")
    film = read_from_silver(spark, "film")
    
    # Read category - needs to join via film_category
    # For simplicity, we'll aggregate by film rating instead
    
    # Join tables
    df = payment \
        .join(rental, "rental_id") \
        .join(inventory, "inventory_id") \
        .join(film, "film_id")
    
    # Aggregate by month and rating
    monthly_revenue = df \
        .withColumn("year", year(col("payment_date"))) \
        .withColumn("month", month(col("payment_date"))) \
        .groupBy("year", "month", "rating") \
        .agg(
            round(sum("amount"), 2).alias("total_revenue"),
            count("*").alias("transaction_count"),
            round(avg("amount"), 2).alias("avg_transaction")
        ) \
        .orderBy("year", "month", "rating")
    
    return write_to_gold(monthly_revenue, "monthly_revenue", ["year", "month"])


def create_customer_lifetime_value(spark):
    """
    Calculate Customer Lifetime Value (CLV).
    
    Business Question: Who are our most valuable customers?
    """
    print("\n👥 Creating Customer Lifetime Value...")
    
    customer = read_from_silver(spark, "customer")
    payment = read_from_silver(spark, "payment")
    rental = read_from_silver(spark, "rental")
    
    # Aggregate customer metrics
    customer_metrics = payment \
        .groupBy("customer_id") \
        .agg(
            round(sum("amount"), 2).alias("total_spent"),
            count("*").alias("total_transactions"),
            round(avg("amount"), 2).alias("avg_transaction_value"),
            max("payment_date").alias("last_payment_date"),
            min("payment_date").alias("first_payment_date")
        )
    
    # Calculate rental metrics
    rental_metrics = rental \
        .groupBy("customer_id") \
        .agg(
            count("*").alias("total_rentals"),
            max("rental_date").alias("last_rental_date")
        )
    
    # Join with customer info
    clv = customer \
        .join(customer_metrics, "customer_id", "left") \
        .join(rental_metrics, "customer_id", "left") \
        .select(
            col("customer_id"),
            col("first_name"),
            col("last_name"),
            col("email"),
            col("total_spent"),
            col("total_transactions"),
            col("total_rentals"),
            col("avg_transaction_value"),
            col("first_payment_date"),
            col("last_payment_date")
        )
    
    # Add CLV ranking
    window = Window.orderBy(col("total_spent").desc())
    clv_ranked = clv \
        .withColumn("clv_rank", dense_rank().over(window)) \
        .withColumn("clv_percentile", round(percent_rank().over(window) * 100, 2))
    
    return write_to_gold(clv_ranked, "customer_lifetime_value")


def create_film_performance(spark):
    """
    Analyze film rental performance.
    
    Business Question: Which films are most popular and profitable?
    """
    print("\n🎬 Creating Film Performance Metrics...")
    
    film = read_from_silver(spark, "film")
    inventory = read_from_silver(spark, "inventory")
    rental = read_from_silver(spark, "rental")
    payment = read_from_silver(spark, "payment")
    
    # Join tables to get film rental data
    film_rentals = rental \
        .join(inventory, "inventory_id") \
        .join(film, "film_id") \
        .join(payment, "rental_id", "left")
    
    # Aggregate by film
    film_performance = film_rentals \
        .groupBy("film_id", "title", "rating", "rental_rate", "replacement_cost") \
        .agg(
            count("rental_id").alias("total_rentals"),
            round(sum("amount"), 2).alias("total_revenue"),
            round(avg("amount"), 2).alias("avg_revenue_per_rental")
        )
    
    # Add ranking
    window = Window.orderBy(col("total_rentals").desc())
    film_ranked = film_performance \
        .withColumn("popularity_rank", dense_rank().over(window)) \
        .orderBy("popularity_rank")
    
    return write_to_gold(film_ranked, "film_performance")


def create_store_performance(spark):
    """
    Analyze store performance metrics.
    
    Business Question: How do our stores compare in performance?
    """
    print("\n🏪 Creating Store Performance Metrics...")
    
    rental = read_from_silver(spark, "rental")
    inventory = read_from_silver(spark, "inventory")
    payment = read_from_silver(spark, "payment")
    
    # Join to get store from inventory
    store_data = rental \
        .join(inventory, "inventory_id") \
        .join(payment, "rental_id", "left")
    
    # Aggregate by store and month
    store_performance = store_data \
        .withColumn("year", year(col("rental_date"))) \
        .withColumn("month", month(col("rental_date"))) \
        .groupBy("store_id", "year", "month") \
        .agg(
            count("rental_id").alias("total_rentals"),
            round(sum("amount"), 2).alias("total_revenue"),
            round(avg("amount"), 2).alias("avg_transaction")
        ) \
        .orderBy("store_id", "year", "month")
    
    return write_to_gold(store_performance, "store_performance", ["year", "month"])


def main():
    """Main aggregation pipeline: Silver -> Gold Layer."""
    print("=" * 60)
    print("Starting Silver to Gold Aggregation Pipeline")
    print("=" * 60)
    
    spark = create_spark_session()
    spark.sparkContext.setLogLevel("WARN")
    
    total_records = 0
    
    try:
        # Create business aggregations
        total_records += create_monthly_revenue(spark)
        total_records += create_customer_lifetime_value(spark)
        total_records += create_film_performance(spark)
        total_records += create_store_performance(spark)
        
    except Exception as e:
        print(f"❌ Error in aggregation: {str(e)}")
        raise
    
    print("\n" + "=" * 60)
    print(f"✅ Pipeline completed! Total aggregated records: {total_records}")
    print("=" * 60)
    
    spark.stop()


if __name__ == "__main__":
    main()
