#!/bin/bash
# download-jars.sh
# ================
# Download required JAR files for Spark and Kafka Connect

set -e

JARS_DIR="$(dirname "$0")/../jars"
PLUGINS_DIR="$(dirname "$0")/../plugins"

mkdir -p "$JARS_DIR"
mkdir -p "$PLUGINS_DIR"

echo "📦 Downloading JAR dependencies..."

# PostgreSQL JDBC Driver
POSTGRES_JAR="postgresql-42.7.3.jar"
if [ ! -f "$JARS_DIR/$POSTGRES_JAR" ]; then
    echo "   Downloading PostgreSQL JDBC driver..."
    curl -L -o "$JARS_DIR/$POSTGRES_JAR" \
        "https://jdbc.postgresql.org/download/$POSTGRES_JAR"
fi

# AWS SDK Bundle for S3A (MinIO)
AWS_JAR="aws-java-sdk-bundle-1.12.262.jar"
if [ ! -f "$JARS_DIR/$AWS_JAR" ]; then
    echo "   Downloading AWS SDK Bundle..."
    curl -L -o "$JARS_DIR/$AWS_JAR" \
        "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/$AWS_JAR"
fi

# Hadoop AWS for S3A
HADOOP_AWS_JAR="hadoop-aws-3.3.4.jar"
if [ ! -f "$JARS_DIR/$HADOOP_AWS_JAR" ]; then
    echo "   Downloading Hadoop AWS..."
    curl -L -o "$JARS_DIR/$HADOOP_AWS_JAR" \
        "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/$HADOOP_AWS_JAR"
fi

# Spark SQL Kafka (for Kafka integration)
SPARK_KAFKA_JAR="spark-sql-kafka-0-10_2.12-3.5.0.jar"
if [ ! -f "$JARS_DIR/$SPARK_KAFKA_JAR" ]; then
    echo "   Downloading Spark Kafka..."
    curl -L -o "$JARS_DIR/$SPARK_KAFKA_JAR" \
        "https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.5.0/$SPARK_KAFKA_JAR"
fi

# Kafka Clients
KAFKA_CLIENTS_JAR="kafka-clients-3.6.0.jar"
if [ ! -f "$JARS_DIR/$KAFKA_CLIENTS_JAR" ]; then
    echo "   Downloading Kafka Clients..."
    curl -L -o "$JARS_DIR/$KAFKA_CLIENTS_JAR" \
        "https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.6.0/$KAFKA_CLIENTS_JAR"
fi

echo ""
echo "📦 Downloading Kafka Connect plugins..."

# Download JDBC Connector
JDBC_CONNECTOR_VERSION="10.7.4"
JDBC_CONNECTOR_ZIP="confluentinc-kafka-connect-jdbc-$JDBC_CONNECTOR_VERSION.zip"
if [ ! -d "$PLUGINS_DIR/kafka-connect-jdbc" ]; then
    echo "   Downloading Kafka Connect JDBC..."
    curl -L -o "/tmp/$JDBC_CONNECTOR_ZIP" \
        "https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-jdbc/versions/$JDBC_CONNECTOR_VERSION/confluentinc-kafka-connect-jdbc-$JDBC_CONNECTOR_VERSION.zip"
    unzip -q "/tmp/$JDBC_CONNECTOR_ZIP" -d "$PLUGINS_DIR"
    mv "$PLUGINS_DIR/confluentinc-kafka-connect-jdbc-$JDBC_CONNECTOR_VERSION" "$PLUGINS_DIR/kafka-connect-jdbc"
    rm "/tmp/$JDBC_CONNECTOR_ZIP"
fi

# Copy PostgreSQL driver to Kafka Connect plugins
cp "$JARS_DIR/$POSTGRES_JAR" "$PLUGINS_DIR/kafka-connect-jdbc/" 2>/dev/null || true

echo ""
echo "✅ All dependencies downloaded!"
echo ""
echo "Downloaded JARs:"
ls -la "$JARS_DIR"
echo ""
echo "Kafka Connect Plugins:"
ls -la "$PLUGINS_DIR"
