#!/bin/bash
# verify-pipeline.sh
# ==================
# Verify the entire big data pipeline is working

set -e

echo "🔍 Verifying Big Data Pipeline..."
echo "================================="
echo ""

# Check Docker containers
echo "1️⃣  Checking Docker containers..."
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check PostgreSQL
echo "2️⃣  Checking PostgreSQL..."
docker exec postgres psql -U postgres -d pagila -c "SELECT COUNT(*) as customer_count FROM customer;" 2>/dev/null || echo "   ❌ PostgreSQL not ready"
echo ""

# Check Kafka
echo "3️⃣  Checking Kafka topics..."
docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null || echo "   ❌ Kafka not ready"
echo ""

# Check Kafka Connect
echo "4️⃣  Checking Kafka Connect connectors..."
curl -s http://localhost:8083/connectors 2>/dev/null | jq . || echo "   ❌ Kafka Connect not ready"
echo ""

# Check MinIO buckets
echo "5️⃣  Checking MinIO buckets..."
docker exec minio-init mc ls myminio/ 2>/dev/null || echo "   ❌ MinIO not ready"
echo ""

# Check Trino
echo "6️⃣  Checking Trino catalogs..."
docker exec trino trino --execute "SHOW CATALOGS" 2>/dev/null || echo "   ❌ Trino not ready"
echo ""

# Check Spark
echo "7️⃣  Checking Spark Master..."
curl -s http://localhost:8080/json/ 2>/dev/null | jq '.workers | length' | xargs echo "   Workers connected:" || echo "   ❌ Spark not ready"
echo ""

echo "================================="
echo "✅ Pipeline verification complete!"
echo ""
echo "Access Web UIs:"
echo "   • Spark Master:   http://localhost:8080"
echo "   • MinIO Console:  http://localhost:9001 (minioadmin/minioadmin)"
echo "   • Trino UI:       http://localhost:8090"
echo "   • JupyterLab:     http://localhost:8888 (token: bigdata)"
echo "   • Kafka Connect:  http://localhost:8083"
