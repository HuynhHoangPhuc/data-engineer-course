#!/bin/bash
echo "Starting Lesson 7 environment..."

# Start all services
docker compose up -d

# Wait for postgres to be healthy
echo "Waiting for Postgres to be healthy..."
until docker exec lesson7-postgres-1 pg_isready -U postgres -d pagila > /dev/null 2>&1; do
    sleep 2
done

echo "Postgres is ready. Initializing database..."

# Copy and run init script
docker cp init-scripts/init-pagila.sql lesson7-postgres-1:/tmp/
docker exec lesson7-postgres-1 psql -U postgres -d pagila -f /tmp/init-pagila.sql

echo "Database initialized successfully!"
echo ""
echo "Access services at:"
echo "  - Jupyter: http://localhost:8888 (token: bigdata)"
echo "  - Spark Master: http://localhost:8080"
echo "  - MinIO: http://localhost:9001 (minioadmin/minioadmin)"
echo "  - Trino: http://localhost:8090"
