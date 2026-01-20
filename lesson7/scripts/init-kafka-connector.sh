#!/bin/bash
# init-kafka-connector.sh
# =======================
# Register the PostgreSQL JDBC source connector with Kafka Connect

set -e

KAFKA_CONNECT_URL="http://localhost:8083"
CONNECTOR_CONFIG="$(dirname "$0")/../configs/kafka-connect/postgresql-source.json"

echo "🔌 Initializing Kafka Connect PostgreSQL Connector..."

# Wait for Kafka Connect to be ready
echo "   Waiting for Kafka Connect to be ready..."
until curl -s "$KAFKA_CONNECT_URL/connectors" > /dev/null 2>&1; do
    echo "   Kafka Connect not ready, waiting..."
    sleep 5
done

echo "   ✅ Kafka Connect is ready!"

# Check if connector already exists
CONNECTOR_NAME="pagila-jdbc-source"
if curl -s "$KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME" | grep -q "$CONNECTOR_NAME"; then
    echo "   Connector '$CONNECTOR_NAME' already exists. Updating..."
    curl -X PUT "$KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME/config" \
        -H "Content-Type: application/json" \
        -d @"$CONNECTOR_CONFIG" | jq .
else
    echo "   Creating connector '$CONNECTOR_NAME'..."
    curl -X POST "$KAFKA_CONNECT_URL/connectors" \
        -H "Content-Type: application/json" \
        -d @"$CONNECTOR_CONFIG" | jq .
fi

echo ""
echo "   Waiting for connector to start..."
sleep 10

# Check connector status
echo ""
echo "📊 Connector Status:"
curl -s "$KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME/status" | jq .

echo ""
echo "📋 Available Kafka Topics:"
docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null || echo "   (Run this after connector creates topics)"

echo ""
echo "✅ Kafka Connector initialization complete!"
echo ""
echo "To check connector status:"
echo "   curl http://localhost:8083/connectors/$CONNECTOR_NAME/status | jq"
echo ""
echo "To view Kafka topics:"
echo "   docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list"
