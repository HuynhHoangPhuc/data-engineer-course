## What You'll Learn

- Connecting to databases (PostgreSQL, MySQL)
- Submitting and running PySpark applications
- Production deployment with monitoring and security

## Prerequisites

- Docker Engine installed
- Docker Compose installed
- Basic understanding of Apache Spark concepts
- Familiarity with command line operations

## Database Schema

![](./assets/schema.png)

## Exercise

1.  Using Spark, compute monthly revenue by film category.
2.  Define customer lifetime value (CLV) using Spark.
3.  Identify the top 1% of customers generating 80% of revenue.
4.  Propose a partitioning strategy for the payment table:

    - by date?

    - by store?

    - by customer?

    Explain trade-offs.

5.  The following join is very slow at scale:

    `payment -> rental -> inventory -> film -> film_category -> category`

    Propose:

    - join order optimization

    - indexing strategies

    - caching or materialized views
