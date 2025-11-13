# Advanced Import Techniques

## Prerequisite

- Setup Hadoop and Sqoop in your machine
- Basic Unix knowledge
- Basic SQL knowledge

## Controlling the import

### Filtering Rows

The `--where` argument: import a subset of rows based on a condition

```bash
sqoop import \
--connect jdbc:mysql://mariadb:3306/classicmodels \
--username root \
--password rootpass \
--table orders \
--where "shippedDate > '2003-04-03'" \
--target-dir /user/root/newdata/ \
-m 1
```

### Filtering Columns

The `--columns` argument: select specific columns

```bash
sqoop import \
--connect jdbc:mysql://mariadb:3306/classicmodels \
--username root \
--password rootpass \
--table orders \
--where "shippedDate > '2003-04-03'" \
--columns "orderDate,shippedDate"
--target-dir /user/root/newdata/ \
-m 1
```

### Handling NULL Values

Databases have a true NULL type, but text files in HDFS do not. Sqoop defaults to storing NULL as the string "null"

`--null-string <value>`: Represents a NULL in a string column with `<value>`

```bash
sqoop import \
--connect jdbc:mysql://mariadb:3306/classicmodels \
--username root \
--password rootpass \
--table orders \
--where "shippedDate > '2003-04-03'" \
--target-dir /user/root/newdata/ \
--null-string "Empty description" \
-m 1
```

`--null-non-string <value>`: Represents a NULL in a non-string (e.g., integer, date) column with `<value>`

```bash
sqoop import \
--connect jdbc:mysql://mariadb:3306/classicmodels \
--username root \
--password rootpass \
--table employees \
--target-dir /user/root/newdata/ \
--null-non-string 999999 \
-m 1
```

## Import all tables

Use `sqoop import-all-tables` command as a convenient way to import every table from a database schema

```bash
sqoop import-all-tables \
--connect jdbc:mysql://mariadb:3306/classicmodels
--username root \
--password rootpass \
-m 1 # Use 1 mapreduce for avoiding split column
```

## Incremental Imports

Relying on a "full refresh" (re-importing an entire massive table) just to add new records is incredibly inefficient. This method wastes time, consumes significant system resources, and increases costs.

A much better practice is an "incremental load," which intelligently fetches only the new or updated records (the "delta"). This approach is faster, cheaper, and puts less strain on the database, allowing for much fresher, near-real-time data.

- **Append Mode**: Used when new rows are added to the source table, and rows are identified by an auto-incrementing key

```bash
sqoop import \
--connect jdbc:mysql://mariadb:3306/classicmodels \
--username root \
--password rootpass \
--table employees \
--target-dir /user/root/newdata/ \
--incremental append \
--check-column employeeNumber \
--last-value 1702 \
-m 1
```

- **Last Modified Mode:** Used when existing rows can be updated, based on a timestamp column

```bash
sqoop import \
--connect jdbc:mysql://mariadb:3306/classicmodels \
--username root \
--password rootpass \
--table orders \
--target-dir /user/root/newdata/ \
--incremental lastmodified \
--check-column shippedDate \
--last-value "2005-05-27" \
--merge-key orderNumber \
-m 1
```

## Exercise

Using sakila database (download [sakila database](https://dev.mysql.com/doc/index-other.html)) or provided sql file in this repository

- [sakila-schema.sql](./sakila-schema.sql)
- [sakila-data.sql](./sakila-data.sql)

Using Sqoop to solve:

- Import all data into HDFS.
- Import film table into another folder but only has film released in 2008 or later.
- Add some record to film table, update all table has changed into HDFS

## Notes

- Execute sql into database in Docker:

```bash
docker exec -i lesson2-mariadb-1 mariadb -uroot -prootpass mydatabase < ./mysqlsampledatabase.sql
```

Replace `lesson2-mariadb-1` with your container name and `./mysqlsampledatabase.sql` with your sql file path.
