CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20)
);

-- Insert sample data
INSERT INTO customers (first_name, last_name, email, city, country) VALUES
('John', 'Doe', 'john.doe@email.com', 'New York', 'USA'),
('Jane', 'Smith', 'jane.smith@email.com', 'London', 'UK'),
('Carlos', 'Rodriguez', 'carlos.r@email.com', 'Madrid', 'Spain'),
('Yuki', 'Tanaka', 'yuki.t@email.com', 'Tokyo', 'Japan'),
('Emma', 'Brown', 'emma.b@email.com', 'Sydney', 'Australia');

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
(1, '2024-01-15', 1500.00, 'completed'),
(1, '2024-02-20', 750.50, 'completed'),
(2, '2024-01-10', 2200.00, 'completed'),
(3, '2024-02-05', 1100.75, 'pending'),
(4, '2024-01-25', 890.00, 'completed'),
(5, '2024-02-15', 1650.25, 'completed'),
(2, '2024-03-01', 3200.00, 'shipped');
