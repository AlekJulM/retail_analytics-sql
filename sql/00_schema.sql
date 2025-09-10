-- Retail Analytics Platform Database Schema
-- Author: Alexander Jamin Julon Mayta
-- Description: Complete schema for retail analytics platform with audit, activity tracking, and notifications

CREATE DATABASE retail_analytics;
USE retail_analytics;

-- Table: Addresses
CREATE TABLE Addresses (
    AddressID INT AUTO_INCREMENT PRIMARY KEY,
    Street VARCHAR(255) NOT NULL,
    County VARCHAR(100) NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table: Clients
CREATE TABLE Clients (
    ClientID VARCHAR(20) PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    ContactNumber BIGINT NOT NULL,
    AddressID INT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (AddressID) REFERENCES Addresses(AddressID) ON DELETE RESTRICT
);

-- Table: Employees
CREATE TABLE Employees (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    AddressID INT NOT NULL,
    Position VARCHAR(50) DEFAULT 'Sales Associate',
    Salary DECIMAL(10,2) DEFAULT 0.00,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (AddressID) REFERENCES Addresses(AddressID) ON DELETE RESTRICT
);

-- Table: Products
CREATE TABLE Products (
    ProductID VARCHAR(20) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    BuyPrice DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    SellPrice DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    NumberOfItems INT NOT NULL DEFAULT 0,
    Category VARCHAR(50) DEFAULT 'General',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_prices CHECK (SellPrice >= BuyPrice AND BuyPrice >= 0),
    CONSTRAINT chk_items CHECK (NumberOfItems >= 0)
);

-- Table: Orders
CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID VARCHAR(20) NOT NULL,
    ClientID VARCHAR(20) NOT NULL,
    EmployeeID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1,
    Cost DECIMAL(10,2) NOT NULL,
    Date DATE NOT NULL DEFAULT (CURRENT_DATE),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE RESTRICT,
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE RESTRICT,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE RESTRICT,
    CONSTRAINT chk_quantity CHECK (Quantity > 0),
    CONSTRAINT chk_cost CHECK (Cost >= 0)
);

-- Table: Activity (for tracking customer behavior)
CREATE TABLE Activity (
    ActivityID INT AUTO_INCREMENT PRIMARY KEY,
    ClientID VARCHAR(20),
    ProductID VARCHAR(20),
    Properties JSON,
    ActivityType ENUM('view', 'browse', 'search', 'cart_add', 'cart_remove') DEFAULT 'view',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE
);

-- Table: Audit (for order tracking)
CREATE TABLE Audit (
    AuditID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    Action ENUM('INSERT', 'UPDATE', 'DELETE') DEFAULT 'INSERT',
    OldValues JSON,
    NewValues JSON,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE
);

-- Table: Notifications
CREATE TABLE Notifications (
    NotificationID INT AUTO_INCREMENT PRIMARY KEY,
    ClientID VARCHAR(20) NOT NULL,
    Message TEXT NOT NULL,
    Type ENUM('promotion', 'order_update', 'system', 'marketing') DEFAULT 'system',
    IsRead BOOLEAN DEFAULT FALSE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ClientID) REFERENCES Clients(ClientID) ON DELETE CASCADE
);

-- Create indexes for better performance (basic ones, more in 30_indexes.sql)
CREATE INDEX idx_orders_date ON Orders(Date);
CREATE INDEX idx_orders_client ON Orders(ClientID);
CREATE INDEX idx_activity_client ON Activity(ClientID);
CREATE INDEX idx_activity_created ON Activity(CreatedAt);
