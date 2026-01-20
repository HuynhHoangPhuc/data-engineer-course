# Deep Dive: Big Data System Architecture

This document provides a detailed explanation of the architecture implemented in Lesson 7.

## Table of Contents

1. [Architecture Patterns](#architecture-patterns)
2. [Medallion Architecture](#medallion-architecture)
3. [Component Details](#component-details)
4. [Data Flow](#data-flow)
5. [Design Decisions](#design-decisions)

---

## Architecture Patterns

### Lambda Architecture

The Lambda Architecture is a data processing pattern designed to handle massive quantities of data by taking advantage of both **batch** and **stream processing** methods.

```
                    ┌──────────────────────────────────────┐
                    │           Speed Layer                │
                    │     (Real-time Processing)           │
                    │         Kafka Streams                │
                    └──────────────┬───────────────────────┘
                                   │
┌───────────────┐                  ▼
│  Data Source  │ ─────────▶ ┌───────────────┐
│  (PostgreSQL) │            │ Serving Layer │ ──▶ Queries
└───────────────┘            │   (Trino)     │
        │                    └───────────────┘
        │                          ▲
        ▼                          │
┌──────────────────────────────────┴───────────────────────┐
│                    Batch Layer                           │
│              (Spark + MinIO Data Lake)                   │
│                                                          │
│   Bronze ──▶ Silver ──▶ Gold                             │
└──────────────────────────────────────────────────────────┘
```

**Key Components:**

| Layer | Purpose | Technology |
|-------|---------|------------|
| Batch Layer | Historical processing | Spark + MinIO |
| Speed Layer | Real-time processing | Kafka |
| Serving Layer | Query interface | Trino |

### Why Lambda Architecture?

1. **Fault Tolerance**: Batch layer recomputes from immutable data
2. **Low Latency**: Speed layer provides real-time updates
3. **Accuracy**: Batch layer ensures eventual consistency

---

## Medallion Architecture

The **Medallion Architecture** (Bronze/Silver/Gold) organizes data in the lake into layers of increasing quality and refinement.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           MinIO Data Lake                               │
│                                                                         │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐             │
│  │   BRONZE    │      │   SILVER    │      │    GOLD     │             │
│  │             │      │             │      │             │             │
│  │ • Raw data  │ ───▶ │ • Cleaned   │ ───▶ │ • Aggregated│             │
│  │ • As-is     │      │ • Validated │      │ • Business  │             │
│  │ • Append    │      │ • Deduped   │      │   ready     │             │
│  │   only      │      │ • Typed     │      │ • Optimized │             │
│  │             │      │             │      │             │             │
│  │ Format:     │      │ Format:     │      │ Format:     │             │
│  │ JSON/Avro   │      │ Parquet     │      │ Parquet     │             │
│  └─────────────┘      └─────────────┘      └─────────────┘             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Layer Details

#### Bronze Layer (Raw)
- **Purpose**: Land data exactly as received
- **Format**: JSON (preserves original structure)
- **Retention**: Long-term (years)
- **Schema**: Schema-on-read
- **Operations**: Append-only

```python
# Example: Writing to Bronze
df.write \
    .format("json") \
    .mode("append") \
    .save("s3a://bronze/customers/")
```

#### Silver Layer (Cleaned)
- **Purpose**: Clean, validate, deduplicate
- **Format**: Parquet (optimized for analytics)
- **Retention**: Medium-term (months)
- **Schema**: Enforced schema
- **Operations**: Merge/Upsert

```python
# Example: Bronze to Silver transformation
df_bronze = spark.read.json("s3a://bronze/customers/")
df_silver = df_bronze \
    .dropDuplicates(["customer_id"]) \
    .filter(col("email").isNotNull()) \
    .withColumn("processed_at", current_timestamp())
df_silver.write.parquet("s3a://silver/customers/")
```

#### Gold Layer (Business)
- **Purpose**: Business-ready aggregations
- **Format**: Parquet (partitioned)
- **Retention**: Short-term (refreshed frequently)
- **Schema**: Star/Snowflake schema
- **Operations**: Full refresh or incremental

```python
# Example: Silver to Gold aggregation
df_gold = df_silver \
    .groupBy("country", "month") \
    .agg(
        count("*").alias("customer_count"),
        sum("total_spent").alias("revenue")
    )
df_gold.write.partitionBy("month").parquet("s3a://gold/revenue_by_country/")
```

---

## Component Details

### PostgreSQL (Data Source)

The **Pagila** database is a sample database based on the DVD rental store domain.

**Key Tables:**
- `customer` - Customer information
- `rental` - Rental transactions
- `payment` - Payment records
- `film` - Film catalog
- `inventory` - Store inventory
- `category` - Film categories

**Configuration for CDC:**
```sql
-- Enable logical replication
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_replication_slots = 4;
ALTER SYSTEM SET max_wal_senders = 4;
```

### Apache Kafka (Message Broker)

**KRaft Mode** (Kafka Raft) eliminates the need for ZooKeeper, simplifying deployment.

```
┌─────────────────────────────────────────────────────────┐
│                    Kafka Topics                          │
│                                                          │
│  pagila.public.customer    pagila.public.rental         │
│  pagila.public.payment     pagila.public.film           │
│  pagila.public.inventory   pagila.public.category       │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Topic Naming Convention**: `{database}.{schema}.{table}`

### Kafka Connect JDBC Source

Polls PostgreSQL for changes using a timestamp or incrementing column.

**Modes:**
- `incrementing` - Uses auto-incrementing ID column
- `timestamp` - Uses timestamp column for updates
- `timestamp+incrementing` - Combines both (recommended)

```json
{
  "name": "pagila-source",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
    "connection.url": "jdbc:postgresql://postgres:5432/pagila",
    "mode": "timestamp+incrementing",
    "incrementing.column.name": "customer_id",
    "timestamp.column.name": "last_update"
  }
}
```

### MinIO (Object Storage)

S3-compatible object storage for the data lake.

**Bucket Structure:**
```
minio/
├── bronze/           # Raw data from Kafka
│   ├── customers/
│   ├── rentals/
│   └── payments/
├── silver/           # Cleaned data
│   ├── customers/
│   ├── rentals/
│   └── payments/
├── gold/             # Business aggregations
│   ├── revenue_by_month/
│   ├── customer_segments/
│   └── film_popularity/
└── checkpoints/      # Spark streaming checkpoints
```

### Apache Spark (Processing Engine)

**Spark Configuration for MinIO:**
```conf
spark.hadoop.fs.s3a.endpoint=http://minio:9000
spark.hadoop.fs.s3a.access.key=minioadmin
spark.hadoop.fs.s3a.secret.key=minioadmin
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
```

### Trino (Query Engine)

Distributed SQL query engine that can query multiple data sources.

**Catalogs:**
- `postgres` - Direct PostgreSQL access
- `minio` - Query Parquet files in MinIO

```sql
-- Query across catalogs
SELECT 
    p.first_name,
    m.total_rentals
FROM postgres.public.customer p
JOIN minio.gold.customer_metrics m 
    ON p.customer_id = m.customer_id;
```

---

## Data Flow

### End-to-End Pipeline

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  App    │───▶│ Postgres│───▶│ Kafka   │───▶│ Spark   │───▶│ MinIO   │
│ Changes │    │ INSERT/ │    │ Connect │    │ Batch   │    │ Bronze  │
│         │    │ UPDATE  │    │ CDC     │    │ Job     │    │ Layer   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
                                                                  │
                ┌────────────────────────────────────────────────┘
                │
                ▼
          ┌─────────┐    ┌─────────┐    ┌─────────┐
          │ Spark   │───▶│ MinIO   │───▶│ Trino   │
          │ Clean   │    │ Silver  │    │ Query   │
          │ Job     │    │ Layer   │    │         │
          └─────────┘    └─────────┘    └─────────┘
                              │
                              ▼
                        ┌─────────┐    ┌─────────┐
                        │ Spark   │───▶│ MinIO   │
                        │ Agg     │    │ Gold    │
                        │ Job     │    │ Layer   │
                        └─────────┘    └─────────┘
```

### Timing

| Step | Frequency | Latency |
|------|-----------|---------|
| PostgreSQL → Kafka | Every 5 seconds (polling) | ~5s |
| Kafka → Bronze | On-demand batch | Minutes |
| Bronze → Silver | Scheduled batch | Minutes |
| Silver → Gold | Scheduled batch | Minutes |

---

## Design Decisions

### Why Kafka Connect JDBC vs Debezium?

| Aspect | Kafka Connect JDBC | Debezium |
|--------|-------------------|----------|
| CDC Method | Polling (timestamp) | Log-based (WAL) |
| Latency | Seconds | Milliseconds |
| Resource Usage | Lower | Higher |
| Complexity | Simple | Complex |
| ARM64 Support | ✅ Native | ⚠️ Limited |
| Deletes Capture | ❌ No | ✅ Yes |

**Decision**: JDBC Connector chosen for simplicity and ARM64 compatibility.

### Why MinIO vs Local HDFS?

| Aspect | MinIO | HDFS |
|--------|-------|------|
| Setup | Single container | Multiple containers |
| API | S3-compatible | HDFS protocol |
| Memory | ~200MB | ~2GB+ |
| Industry Adoption | Growing (S3 standard) | Declining |

**Decision**: MinIO chosen for simplicity and S3 API compatibility.

### Why Trino vs Spark SQL?

| Aspect | Trino | Spark SQL |
|--------|-------|-----------|
| Query Type | Federated | Local |
| Latency | Low (seconds) | Higher (batch) |
| Use Case | Interactive | ETL |
| Multi-source | ✅ Native | Requires config |

**Decision**: Both included - Trino for interactive queries, Spark for ETL.

---

## Performance Tuning

### Spark Job Optimization

```python
# Partition data appropriately
spark.conf.set("spark.sql.shuffle.partitions", 10)  # Reduce for small data

# Enable adaptive query execution
spark.conf.set("spark.sql.adaptive.enabled", "true")

# Cache frequently accessed data
df.cache()
```

### MinIO Optimization

```python
# Use Parquet with compression
df.write \
    .option("compression", "snappy") \
    .parquet("s3a://silver/data/")

# Partition large datasets
df.write \
    .partitionBy("year", "month") \
    .parquet("s3a://gold/data/")
```

### Trino Query Optimization

```sql
-- Use partitioned columns in WHERE
SELECT * FROM minio.gold.revenue 
WHERE year = 2024 AND month = 1;

-- Limit data scanning
SELECT * FROM minio.bronze.events 
LIMIT 1000;
```
