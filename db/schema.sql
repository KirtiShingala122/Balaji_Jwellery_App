-- Step 1: Create and select database
CREATE DATABASE IF NOT EXISTS balaji_imitation;
USE balaji_imitation;

-- Step 2: Drop existing tables if any
DROP TABLE IF EXISTS bill_items;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS admins;

-- Step 3: Create Admins Table
CREATE TABLE admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(150) UNIQUE,
  fullName VARCHAR(150) NOT NULL,
  phoneNumber VARCHAR(20),
  address VARCHAR(255),
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  lastLogin DATETIME
);

-- Step 4: Create Categories Table
CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255) NOT NULL,
  imagePath VARCHAR(255),
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Step 5: Create Products Table
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  uniqueCode VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  categoryId INT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  stockQuantity INT NOT NULL DEFAULT 0,
  imagePath VARCHAR(255),
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (categoryId) REFERENCES categories(id)
);

-- Step 6: Create Customers Table
CREATE TABLE customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phoneNumber VARCHAR(20) NOT NULL,
  address VARCHAR(255) NOT NULL,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Step 7: Create Bills Table
CREATE TABLE bills (
  id INT AUTO_INCREMENT PRIMARY KEY,
  billNumber VARCHAR(50) UNIQUE NOT NULL,
  customerId INT NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  taxAmount DECIMAL(10,2) NOT NULL,
  discountAmount DECIMAL(10,2) NOT NULL,
  totalAmount DECIMAL(10,2) NOT NULL,
  billDate DATETIME DEFAULT CURRENT_TIMESTAMP,
  paymentStatus VARCHAR(50) NOT NULL,
  notes TEXT,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customerId) REFERENCES customers(id)
);

-- Step 8: Create Bill Items Table
CREATE TABLE bill_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  billId INT NOT NULL,
  productId INT NOT NULL,
  quantity INT NOT NULL,
  unitPrice DECIMAL(10,2) NOT NULL,
  totalPrice DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (billId) REFERENCES bills(id),
  FOREIGN KEY (productId) REFERENCES products(id)
);

-- Step 9: Create Indexes
CREATE INDEX idx_products_category ON products (categoryId);
CREATE INDEX idx_bills_customer ON bills (customerId);
CREATE INDEX idx_bill_items_bill ON bill_items (billId);

-- Step 10: Insert Sample Data
INSERT INTO admins (username, password, email, fullName, phoneNumber, address)
VALUES ('admin', 'admin123', 'admin@balajiimitation.com', 'Admin User', NULL, NULL);

INSERT INTO categories (name, description) VALUES
('Rings', 'All types of imitation rings'),
('Necklaces', 'Designer imitation necklaces'),
('Bracelets', 'Fashionable imitation bracelets');

INSERT INTO products (uniqueCode, name, description, categoryId, price, stockQuantity) VALUES
('R001', 'Gold Ring', 'Imitation gold ring', 1, 499.99, 10),
('N001', 'Diamond Necklace', 'Beautiful imitation necklace', 2, 1299.50, 5),
('B001', 'Silver Bracelet', 'Classic imitation bracelet', 3, 699.00, 7);

INSERT INTO customers (name, email, phoneNumber, address) VALUES
('Disha Vadoliya', 'disha@example.com', '9876543210', 'Surat, Gujarat'),
('Riya Patel', 'riya@example.com', '9988776655', 'Ahmedabad, Gujarat');

INSERT INTO bills (billNumber, customerId, subtotal, taxAmount, discountAmount, totalAmount, paymentStatus) VALUES
('BILL001', 1, 2499.49, 125.00, 50.00, 2574.49, 'Paid');

INSERT INTO bill_items (billId, productId, quantity, unitPrice, totalPrice) VALUES
(1, 1, 2, 499.99, 999.98),
(1, 2, 1, 1299.50, 1299.50);