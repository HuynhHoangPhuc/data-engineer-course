from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as _sum, avg, count, round as _round
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, DateType

spark = SparkSession.builder \
    .appName("SalesAnalysis") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

# Define schema for better performance
schema = StructType([
    StructField("date", DateType(), True),
    StructField("product", StringType(), True),
    StructField("category", StringType(), True),
    StructField("quantity", IntegerType(), True),
    StructField("price", DoubleType(), True)
])

# Read CSV data
print("Reading sales data...")
sales_df = spark.read \
    .option("header", "true") \
    .option("dateFormat", "yyyy-MM-dd") \
    .schema(schema) \
    .csv("/opt/spark-data/input/sales_data.csv")

# Calculate total revenue per product
sales_df = sales_df.withColumn("revenue", col("quantity") * col("price"))

print("\\n=== TOTAL SALES BY PRODUCT ===")
product_sales = sales_df.groupBy("product") \
    .agg(
        _sum("quantity").alias("total_quantity"),
        _round(_sum("revenue"), 2).alias("total_revenue")
    ) \
    .orderBy(col("total_revenue").desc())

product_sales.show()

# Category analysis
print("\\n=== SALES BY CATEGORY ===")
category_sales = sales_df.groupBy("category") \
    .agg(
        count("*").alias("transactions"),
        _sum("quantity").alias("total_items"),
        _round(_sum("revenue"), 2).alias("total_revenue"),
        _round(avg("revenue"), 2).alias("avg_transaction_value")
    ) \
    .orderBy(col("total_revenue").desc())

category_sales.show()

# Save results
print("\\nSaving results to output directory...")
product_sales.coalesce(1).write \
    .mode("overwrite") \
    .option("header", "true") \
    .csv("/opt/spark-data/output/product_sales")

category_sales.coalesce(1).write \
    .mode("overwrite") \
    .option("header", "true") \
    .csv("/opt/spark-data/output/category_sales")

print("\\nAnalysis complete! Check spark-data/output/ directory for results.")

spark.stop()
