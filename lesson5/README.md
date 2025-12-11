## What You'll Learn

- Setting up a Spark cluster with Docker Compose using official Apache images
- Configuring multi-worker distributed processing
- Mounting volumes for data persistence

## Prerequisites

- Docker Engine installed
- Docker Compose installed
- Basic understanding of Apache Spark concepts
- Familiarity with command line operations

## Single-Node Spark Cluster

```bash
docker compose -f single-node.compose.yml up -d
```

Verify the setup:

```bash
docker ps
```

Open your browser and navigate to: http://localhost:8080
You should see the Spark Master UI showing:

- 1 worker connected
- 2 cores available
- 2GB memory available

Submit a test application:

```bash
docker exec -it spark-master /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  /opt/spark-apps/word_count.py
```

## Multi-Worker Setup for Distributed Processing

```bash
docker compose -f multi-worker.compose.yml up -d
```

Submit a test application:

```bash
docker exec -it spark-master /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  --executor-memory 2G \
  --total-executor-cores 6 \
  /opt/spark-apps/parallel_processing.py
```

## Working with Data: File Handling

```bash
docker exec -it spark-master /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  /opt/spark-apps/sales_analysis.py
```

Check results:

```bash
ls -la spark-data/output/
cat spark-data/output/product_sales/part-*.csv
```

## Exercise

Perform analyses on the heart.csv data:

1. What is the most common chest pain type by age group?
2. Explore the effect of diabetes on heart disease.
3. Explore the effect of hypertension on heart disease.
4. Build a machine learning model for heart disease prediction.
