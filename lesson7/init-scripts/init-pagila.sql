-- Pagila Sample Database (Simplified Version)
-- Based on the DVD Rental database

-- Create tables
CREATE TABLE IF NOT EXISTS category (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(25) NOT NULL,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS language (
    language_id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS film (
    film_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    release_year INTEGER,
    language_id INTEGER REFERENCES language(language_id),
    rental_duration INTEGER DEFAULT 3,
    rental_rate NUMERIC(4,2) DEFAULT 4.99,
    length INTEGER,
    replacement_cost NUMERIC(5,2) DEFAULT 19.99,
    rating VARCHAR(10) DEFAULT 'G',
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS film_category (
    film_id INTEGER REFERENCES film(film_id),
    category_id INTEGER REFERENCES category(category_id),
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (film_id, category_id)
);

CREATE TABLE IF NOT EXISTS actor (
    actor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS address (
    address_id SERIAL PRIMARY KEY,
    address VARCHAR(50) NOT NULL,
    address2 VARCHAR(50),
    district VARCHAR(20) NOT NULL,
    city_id INTEGER,
    postal_code VARCHAR(10),
    phone VARCHAR(20),
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS city (
    city_id SERIAL PRIMARY KEY,
    city VARCHAR(50) NOT NULL,
    country_id INTEGER,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS country (
    country_id SERIAL PRIMARY KEY,
    country VARCHAR(50) NOT NULL,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS store (
    store_id SERIAL PRIMARY KEY,
    manager_staff_id INTEGER,
    address_id INTEGER REFERENCES address(address_id),
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staff (
    staff_id SERIAL PRIMARY KEY,
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    address_id INTEGER REFERENCES address(address_id),
    email VARCHAR(50),
    store_id INTEGER,
    active BOOLEAN DEFAULT TRUE,
    username VARCHAR(16),
    password VARCHAR(40),
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customer (
    customer_id SERIAL PRIMARY KEY,
    store_id INTEGER REFERENCES store(store_id),
    first_name VARCHAR(45) NOT NULL,
    last_name VARCHAR(45) NOT NULL,
    email VARCHAR(50),
    address_id INTEGER REFERENCES address(address_id),
    active BOOLEAN DEFAULT TRUE,
    create_date DATE DEFAULT CURRENT_DATE,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS inventory (
    inventory_id SERIAL PRIMARY KEY,
    film_id INTEGER REFERENCES film(film_id),
    store_id INTEGER REFERENCES store(store_id),
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rental (
    rental_id SERIAL PRIMARY KEY,
    rental_date TIMESTAMP NOT NULL,
    inventory_id INTEGER REFERENCES inventory(inventory_id),
    customer_id INTEGER REFERENCES customer(customer_id),
    return_date TIMESTAMP,
    staff_id INTEGER REFERENCES staff(staff_id),
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment (
    payment_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customer(customer_id),
    staff_id INTEGER REFERENCES staff(staff_id),
    rental_id INTEGER REFERENCES rental(rental_id),
    amount NUMERIC(5,2) NOT NULL,
    payment_date TIMESTAMP NOT NULL,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data

-- Countries
INSERT INTO country (country) VALUES 
('United States'), ('Canada'), ('United Kingdom'), ('Australia'), ('Germany'),
('France'), ('Japan'), ('Brazil'), ('Mexico'), ('India');

-- Cities
INSERT INTO city (city, country_id) VALUES 
('New York', 1), ('Los Angeles', 1), ('Toronto', 2), ('London', 3), ('Sydney', 4),
('Berlin', 5), ('Paris', 6), ('Tokyo', 7), ('Sao Paulo', 8), ('Mumbai', 10);

-- Addresses
INSERT INTO address (address, district, city_id, postal_code, phone) VALUES 
('123 Main St', 'Manhattan', 1, '10001', '555-0101'),
('456 Oak Ave', 'Hollywood', 2, '90028', '555-0102'),
('789 Maple Dr', 'Downtown', 3, 'M5V 1J1', '555-0103'),
('321 Pine Rd', 'Westminster', 4, 'SW1A 1AA', '555-0104'),
('654 Cedar Ln', 'CBD', 5, '2000', '555-0105'),
('987 Birch St', 'Mitte', 6, '10115', '555-0106'),
('147 Elm Way', 'Marais', 7, '75004', '555-0107'),
('258 Spruce Ct', 'Shibuya', 8, '150-0001', '555-0108'),
('369 Willow Pl', 'Centro', 9, '01310-100', '555-0109'),
('741 Ash Blvd', 'South Mumbai', 10, '400001', '555-0110');

-- Stores
INSERT INTO store (manager_staff_id, address_id) VALUES 
(1, 1), (2, 2);

-- Staff
INSERT INTO staff (first_name, last_name, address_id, email, store_id, username, password) VALUES 
('Mike', 'Hillyer', 1, 'mike.hillyer@store.com', 1, 'mike', 'password'),
('Jon', 'Stephens', 2, 'jon.stephens@store.com', 2, 'jon', 'password');

-- Languages
INSERT INTO language (name) VALUES 
('English'), ('Italian'), ('Japanese'), ('Mandarin'), ('French'), ('German');

-- Categories
INSERT INTO category (name) VALUES 
('Action'), ('Animation'), ('Children'), ('Classics'), ('Comedy'),
('Documentary'), ('Drama'), ('Family'), ('Foreign'), ('Games'),
('Horror'), ('Music'), ('New'), ('Sci-Fi'), ('Sports'), ('Travel');

-- Films
INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating) VALUES 
('Academy Dinosaur', 'A Epic Drama of a Feminist And a Mad Scientist', 2006, 1, 6, 0.99, 86, 20.99, 'PG'),
('Ace Goldfinger', 'A Astounding Epistle of a Database Administrator', 2006, 1, 3, 4.99, 48, 12.99, 'G'),
('Adaptation Holes', 'A Astounding Drama of a Lumberjack And a Car', 2006, 1, 7, 2.99, 50, 18.99, 'NC-17'),
('Affair Prejudice', 'A Fanciful Documentary of a Frisbee And a Lumberjack', 2006, 1, 5, 2.99, 117, 26.99, 'G'),
('African Egg', 'A Fast-Paced Documentary of a Pastry Chef', 2006, 1, 6, 2.99, 130, 22.99, 'G'),
('Agent Truman', 'A Intrepid Panorama of a Robot And a Boy', 2006, 1, 3, 2.99, 169, 17.99, 'PG'),
('Airplane Sierra', 'A Touching Saga of a Hunter And a Butler', 2006, 1, 6, 4.99, 62, 28.99, 'PG-13'),
('Airport Pollock', 'A Epic Tale of a Moose And a Girl', 2006, 1, 6, 4.99, 54, 15.99, 'R'),
('Alabama Devil', 'A Thoughtful Panorama of a Database Administrator', 2006, 1, 3, 2.99, 114, 21.99, 'PG-13'),
('Aladdin Calendar', 'A Action-Packed Tale of a Man And a Lumberjack', 2006, 1, 6, 4.99, 63, 24.99, 'NC-17');

-- Film Categories
INSERT INTO film_category (film_id, category_id) VALUES 
(1, 6), (2, 11), (3, 6), (4, 11), (5, 8),
(6, 9), (7, 5), (8, 6), (9, 11), (10, 15);

-- Actors
INSERT INTO actor (first_name, last_name) VALUES 
('Penelope', 'Guiness'), ('Nick', 'Wahlberg'), ('Ed', 'Chase'),
('Jennifer', 'Davis'), ('Johnny', 'Lollobrigida'), ('Bette', 'Nicholson'),
('Grace', 'Mostel'), ('Matthew', 'Johansson'), ('Joe', 'Swank'), ('Christian', 'Gable');

-- Customers
INSERT INTO customer (store_id, first_name, last_name, email, address_id, active) VALUES 
(1, 'Mary', 'Smith', 'mary.smith@email.com', 1, true),
(1, 'Patricia', 'Johnson', 'patricia.johnson@email.com', 2, true),
(1, 'Linda', 'Williams', 'linda.williams@email.com', 3, true),
(2, 'Barbara', 'Jones', 'barbara.jones@email.com', 4, true),
(2, 'Elizabeth', 'Brown', 'elizabeth.brown@email.com', 5, true),
(1, 'Jennifer', 'Davis', 'jennifer.davis@email.com', 6, true),
(2, 'Maria', 'Miller', 'maria.miller@email.com', 7, true),
(1, 'Susan', 'Wilson', 'susan.wilson@email.com', 8, true),
(2, 'Margaret', 'Moore', 'margaret.moore@email.com', 9, true),
(1, 'Dorothy', 'Taylor', 'dorothy.taylor@email.com', 10, true);

-- Inventory
INSERT INTO inventory (film_id, store_id) VALUES 
(1, 1), (1, 1), (1, 2), (2, 2), (2, 1),
(3, 2), (3, 1), (4, 1), (4, 2), (5, 1),
(5, 2), (6, 1), (6, 2), (7, 1), (7, 2),
(8, 1), (8, 2), (9, 1), (9, 2), (10, 1);

-- Rentals
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id) VALUES 
('2024-01-01 10:00:00', 1, 1, '2024-01-08 14:00:00', 1),
('2024-01-02 11:00:00', 2, 2, '2024-01-09 15:00:00', 1),
('2024-01-03 12:00:00', 3, 3, '2024-01-10 16:00:00', 2),
('2024-01-04 13:00:00', 4, 4, '2024-01-11 17:00:00', 2),
('2024-01-05 14:00:00', 5, 5, '2024-01-12 18:00:00', 1),
('2024-01-06 15:00:00', 6, 6, '2024-01-13 19:00:00', 2),
('2024-01-07 16:00:00', 7, 7, '2024-01-14 20:00:00', 1),
('2024-01-08 17:00:00', 8, 8, '2024-01-15 21:00:00', 2),
('2024-01-09 18:00:00', 9, 9, '2024-01-16 22:00:00', 1),
('2024-01-10 19:00:00', 10, 10, '2024-01-17 23:00:00', 2),
('2024-01-11 10:00:00', 11, 1, '2024-01-18 14:00:00', 1),
('2024-01-12 11:00:00', 12, 2, '2024-01-19 15:00:00', 2),
('2024-01-13 12:00:00', 13, 3, '2024-01-20 16:00:00', 1),
('2024-01-14 13:00:00', 14, 4, '2024-01-21 17:00:00', 2),
('2024-01-15 14:00:00', 15, 5, '2024-01-22 18:00:00', 1),
('2024-02-01 10:00:00', 16, 6, '2024-02-08 14:00:00', 2),
('2024-02-02 11:00:00', 17, 7, '2024-02-09 15:00:00', 1),
('2024-02-03 12:00:00', 18, 8, '2024-02-10 16:00:00', 2),
('2024-02-04 13:00:00', 19, 9, '2024-02-11 17:00:00', 1),
('2024-02-05 14:00:00', 20, 10, '2024-02-12 18:00:00', 2);

-- Payments
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date) VALUES 
(1, 1, 1, 0.99, '2024-01-01 10:05:00'),
(2, 1, 2, 4.99, '2024-01-02 11:05:00'),
(3, 2, 3, 2.99, '2024-01-03 12:05:00'),
(4, 2, 4, 2.99, '2024-01-04 13:05:00'),
(5, 1, 5, 4.99, '2024-01-05 14:05:00'),
(6, 2, 6, 2.99, '2024-01-06 15:05:00'),
(7, 1, 7, 2.99, '2024-01-07 16:05:00'),
(8, 2, 8, 4.99, '2024-01-08 17:05:00'),
(9, 1, 9, 4.99, '2024-01-09 18:05:00'),
(10, 2, 10, 2.99, '2024-01-10 19:05:00'),
(1, 1, 11, 2.99, '2024-01-11 10:05:00'),
(2, 2, 12, 2.99, '2024-01-12 11:05:00'),
(3, 1, 13, 4.99, '2024-01-13 12:05:00'),
(4, 2, 14, 4.99, '2024-01-14 13:05:00'),
(5, 1, 15, 4.99, '2024-01-15 14:05:00'),
(6, 2, 16, 4.99, '2024-02-01 10:05:00'),
(7, 1, 17, 4.99, '2024-02-02 11:05:00'),
(8, 2, 18, 2.99, '2024-02-03 12:05:00'),
(9, 1, 19, 2.99, '2024-02-04 13:05:00'),
(10, 2, 20, 4.99, '2024-02-05 14:05:00');

-- Create indexes for better performance
CREATE INDEX idx_rental_customer ON rental(customer_id);
CREATE INDEX idx_rental_inventory ON rental(inventory_id);
CREATE INDEX idx_payment_customer ON payment(customer_id);
CREATE INDEX idx_payment_rental ON payment(rental_id);
CREATE INDEX idx_inventory_film ON inventory(film_id);
CREATE INDEX idx_film_category_film ON film_category(film_id);

-- Grant privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
