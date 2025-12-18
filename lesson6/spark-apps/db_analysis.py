from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as _sum, count, avg, round as _round

# Database connection properties
db_properties = {
    "user": "spark_user",
    "password": "spark_password",
    "driver": "org.postgresql.Driver"
}

jdbc_url = "jdbc:postgresql://postgres-db:5432/analytics"

# Create Spark session
spark = SparkSession.builder \
    .appName("DatabaseAnalysis") \
    .master("spark://spark-master:7077") \
    .config("spark.jars", "/opt/spark/jars/postgresql-42.7.8.jar") \
    .getOrCreate()

print("\\n=== READING DATA FROM POSTGRESQL ===")

# Read customers table
customers_df = spark.read.jdbc(
    url=jdbc_url,
    table="customers",
    properties=db_properties
)

print(f"Total customers: {customers_df.count()}")
customers_df.show()

# Read orders table
orders_df = spark.read.jdbc(
    url=jdbc_url,
    table="orders",
    properties=db_properties
)

print(f"\\nTotal orders: {orders_df.count()}")
orders_df.show()

# Perform analysis: Customer order summary
print("\\n=== CUSTOMER ORDER SUMMARY ===")
customer_summary = customers_df.join(
    orders_df,
    customers_df.customer_id == orders_df.customer_id,
    "left"
).groupBy(
    customers_df.customer_id,
    "first_name",
    "last_name",
    "country"
).agg(
    count("order_id").alias("total_orders"),
    _round(_sum("total_amount"), 2).alias("total_spent"),
    _round(avg("total_amount"), 2).alias("avg_order_value")
).orderBy(col("total_spent").desc())

customer_summary.show()

# Analyze by country
print("\\n=== SALES BY COUNTRY ===")
country_sales = customers_df.join(
    orders_df,
    customers_df.customer_id == orders_df.customer_id
).groupBy("country").agg(
    count("order_id").alias("total_orders"),
    _round(_sum("total_amount"), 2).alias("total_revenue")
).orderBy(col("total_revenue").desc())

country_sales.show()

# Write results back to database
print("\\n=== WRITING RESULTS TO DATABASE ===")
customer_summary.write.jdbc(
    url=jdbc_url,
    table="customer_analytics",
    mode="overwrite",
    properties=db_properties
)

print("Analysis complete! Results saved to 'customer_analytics' table.")

spark.stop()
