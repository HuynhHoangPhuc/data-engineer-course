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

Data describe:

- "age" - The age of the patient
- "sex" - The gender of the patient
- "angina" - The chest pain experienced (0: Typical Angina, 1: Atypical Angina, 2: Non-Anginal Pain, 3: Asymptomatic)
- "systolic" - The patient's systolic blood pressure (mm Hg on admission to the hospital)
- "cholesterol" - The patient's cholesterol measurement in mg/dl
- "diabetes" - If the patient has diabetes (0: False, 1: True)
- "electrocardiogram" - Resting electrocardiogram results (0: Normal, 1: ST-T Wave Abnormality, 2: Left Ventricular Hypertrophy)
- "max_heart_rate" - The patient's maximum heart rate achieved
- "exercise_induced_angina" - Exercise induced angina (0: No, 1: Yes)
- "ST_depression" - ST depression induced by exercise relative to rest ('ST' relates to positions on the ECG plot)
- "ST_slope" - The slope of the peak exercise ST segment (0: Upsloping, 1: Flatsloping, 2: Downsloping)
- "number_of_major_vessels" - The number of major vessels (0-3)
- "thalassemia" - A blood disorder called thalassemia (0: Normal, 1: Fixed Defect, 2: Reversible Defect)
- "heart_disease" - Heart disease (0: No, 1: Yes)
