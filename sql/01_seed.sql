-- Retail Analytics Platform Sample Data
-- Author: Alexander Jamin Julon Mayta
-- Description: Sample data for testing and development

USE retail_analytics;

-- Insert sample addresses
INSERT INTO Addresses (Street, County) VALUES
('123 Main St', 'Downtown'),
('456 Oak Ave', 'Westside'),
('789 Pine Rd', 'Eastside'),
('321 Elm St', 'Northside'),
('654 Maple Dr', 'Southside'),
('987 Cedar Ln', 'Central'),
('147 Birch Way', 'Downtown'),
('258 Willow Ct', 'Westside');

-- Insert sample clients
INSERT INTO Clients (ClientID, FullName, ContactNumber, AddressID) VALUES
('CLI001', 'John Smith', 5551234567, 1),
('CLI002', 'Maria Garcia', 5552345678, 2),
('CLI003', 'Robert Johnson', 5553456789, 3),
('CLI004', 'Emily Davis', 5554567890, 4),
('CLI005', 'Michael Brown', 5555678901, 5),
('CLI006', 'Sarah Wilson', 5556789012, 6),
('CLI007', 'David Martinez', 5557890123, 7),
('CLI008', 'Lisa Anderson', 5558901234, 8);

-- Insert sample employees
INSERT INTO Employees (FullName, AddressID, Position, Salary) VALUES
('Alice Cooper', 1, 'Sales Manager', 55000.00),
('Bob Thompson', 2, 'Sales Associate', 35000.00),
('Carol White', 3, 'Inventory Manager', 48000.00),
('Daniel Green', 4, 'Sales Associate', 32000.00),
('Eva Martinez', 5, 'Customer Service', 38000.00);

-- Insert sample products
INSERT INTO Products (ProductID, ProductName, BuyPrice, SellPrice, NumberOfItems, Category) VALUES
('PRD001', 'Wireless Headphones', 45.00, 89.99, 50, 'Electronics'),
('PRD002', 'Coffee Maker', 35.00, 79.99, 25, 'Appliances'),
('PRD003', 'Running Shoes', 25.00, 59.99, 40, 'Sports'),
('PRD004', 'Desk Lamp', 15.00, 34.99, 30, 'Home'),
('PRD005', 'Smartphone Case', 8.00, 19.99, 100, 'Electronics'),
('PRD006', 'Yoga Mat', 12.00, 29.99, 35, 'Sports'),
('PRD007', 'Book - Programming', 18.00, 39.99, 20, 'Books'),
('PRD008', 'Water Bottle', 6.00, 14.99, 75, 'Sports'),
('PRD009', 'Bluetooth Speaker', 28.00, 69.99, 45, 'Electronics'),
('PRD010', 'Notebook Set', 4.00, 12.99, 60, 'Office');

-- Insert sample orders
INSERT INTO Orders (ProductID, ClientID, EmployeeID, Quantity, Cost, Date) VALUES
('PRD001', 'CLI001', 1, 2, 179.98, '2024-01-15'),
('PRD002', 'CLI002', 2, 1, 79.99, '2024-01-16'),
('PRD003', 'CLI003', 1, 1, 59.99, '2024-01-17'),
('PRD004', 'CLI001', 3, 3, 104.97, '2024-01-18'),
('PRD005', 'CLI004', 2, 5, 99.95, '2024-01-19'),
('PRD006', 'CLI005', 4, 2, 59.98, '2024-01-20'),
('PRD007', 'CLI006', 1, 1, 39.99, '2024-01-21'),
('PRD008', 'CLI007', 5, 4, 59.96, '2024-01-22'),
('PRD009', 'CLI008', 2, 1, 69.99, '2024-01-23'),
('PRD010', 'CLI002', 3, 10, 129.90, '2024-01-24'),
('PRD001', 'CLI003', 1, 1, 89.99, '2024-02-01'),
('PRD002', 'CLI005', 4, 2, 159.98, '2024-02-02'),
('PRD003', 'CLI007', 2, 3, 179.97, '2024-02-03');

-- Insert sample activity data
INSERT INTO Activity (ClientID, ProductID, Properties, ActivityType) VALUES
('CLI001', 'PRD001', '{"page": "product_detail", "time_spent": 120}', 'view'),
('CLI001', 'PRD002', '{"page": "product_list", "time_spent": 45}', 'browse'),
('CLI002', 'PRD003', '{"search_term": "running shoes", "results_shown": 15}', 'search'),
('CLI003', 'PRD001', '{"quantity": 1, "price": 89.99}', 'cart_add'),
('CLI004', 'PRD005', '{"page": "product_detail", "time_spent": 90}', 'view'),
('CLI005', 'PRD006', '{"comparison_products": ["PRD008", "PRD003"]}', 'browse'),
('CLI006', 'PRD007', '{"page": "product_detail", "time_spent": 200}', 'view'),
('CLI007', 'PRD008', '{"quantity": 2, "price": 29.98}', 'cart_add'),
('CLI008', 'PRD009', '{"page": "product_detail", "time_spent": 75}', 'view');

-- Insert sample notifications
INSERT INTO Notifications (ClientID, Message, Type) VALUES
('CLI001', 'Your order #1 has been shipped!', 'order_update'),
('CLI002', 'New coffee makers on sale - 20% off!', 'promotion'),
('CLI003', 'Thank you for your purchase of Running Shoes', 'order_update'),
('CLI004', 'Weekly deals: Electronics up to 30% off', 'promotion'),
('CLI005', 'Your order #6 is being processed', 'order_update'),
('CLI006', 'New programming books available', 'marketing'),
('CLI007', 'System maintenance scheduled for tonight', 'system'),
('CLI008', 'Special offer: Buy 2 speakers, get 1 free!', 'promotion');

-- Update statistics
SELECT 'Data insertion completed successfully' AS Status;
SELECT 
    'Addresses' AS TableName, COUNT(*) AS RecordCount FROM Addresses
UNION ALL
SELECT 'Clients', COUNT(*) FROM Clients
UNION ALL
SELECT 'Employees', COUNT(*) FROM Employees
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL
SELECT 'Activity', COUNT(*) FROM Activity
UNION ALL
SELECT 'Notifications', COUNT(*) FROM Notifications;
