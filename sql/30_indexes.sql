-- Retail Analytics Platform Database Indexes
-- Author: Alexander Jamin Julon Mayta
-- Description: Optimized indexes for improved query performance

USE retail_analytics;

-- =================================================================
-- Primary Indexes Analysis and Recommendations
-- =================================================================

-- Drop existing basic indexes if they exist (to recreate optimized versions)
DROP INDEX IF EXISTS idx_orders_date ON Orders;
DROP INDEX IF EXISTS idx_orders_client ON Orders;
DROP INDEX IF EXISTS idx_activity_client ON Activity;
DROP INDEX IF EXISTS idx_activity_created ON Activity;

-- =================================================================
-- Orders Table Indexes - High Priority
-- =================================================================

-- Composite index for date-based queries with client filtering
-- Reason: Frequently used in sales reports, customer analysis, and time-series queries
CREATE INDEX idx_orders_date_client ON Orders(Date, ClientID);

-- Composite index for product analysis with date filtering
-- Reason: Product performance queries often filter by product and date range
CREATE INDEX idx_orders_product_date ON Orders(ProductID, Date);

-- Composite index for employee performance analysis
-- Reason: Sales reports by employee with date ranges
CREATE INDEX idx_orders_employee_date ON Orders(EmployeeID, Date);

-- Index for cost-based queries and aggregations
-- Reason: Profit calculations, revenue analysis, and order value filters
CREATE INDEX idx_orders_cost ON Orders(Cost);

-- Composite index for inventory management queries
-- Reason: Quantity analysis by product for stock management
CREATE INDEX idx_orders_product_quantity ON Orders(ProductID, Quantity);

-- =================================================================
-- Activity Table Indexes - Medium Priority
-- =================================================================

-- Composite index for customer activity analysis
-- Reason: Customer journey tracking and behavior analysis
CREATE INDEX idx_activity_client_type_date ON Activity(ClientID, ActivityType, CreatedAt);

-- Index for product activity tracking
-- Reason: Product popularity and browsing pattern analysis
CREATE INDEX idx_activity_product_type ON Activity(ProductID, ActivityType);

-- Index for time-based activity analysis
-- Reason: Daily/weekly activity reports and trend analysis
CREATE INDEX idx_activity_created_type ON Activity(CreatedAt, ActivityType);

-- Functional index for JSON property queries (MySQL 8.0+)
-- Reason: Queries filtering on specific JSON properties
-- Note: Only works in MySQL 8.0+, commented for compatibility
-- CREATE INDEX idx_activity_time_spent ON Activity((CAST(JSON_EXTRACT(Properties, '$.time_spent') AS UNSIGNED)));

-- =================================================================
-- Products Table Indexes - Medium Priority
-- =================================================================

-- Index for price-based queries and profit calculations
-- Reason: Profit margin analysis and pricing queries
CREATE INDEX idx_products_prices ON Products(BuyPrice, SellPrice);

-- Index for inventory management
-- Reason: Stock level monitoring and reorder alerts
CREATE INDEX idx_products_stock ON Products(NumberOfItems);

-- Index for category-based analysis
-- Reason: Category performance reports and product grouping
CREATE INDEX idx_products_category ON Products(Category);

-- Composite index for product search and filtering
-- Reason: Product listings with category and price filters
CREATE INDEX idx_products_category_price ON Products(Category, SellPrice);

-- =================================================================
-- Clients Table Indexes - Low Priority
-- =================================================================

-- Index for address-based queries
-- Reason: Geographic analysis and address lookups
CREATE INDEX idx_clients_address ON Clients(AddressID);

-- Index for contact-based searches
-- Reason: Customer lookup by phone number
CREATE INDEX idx_clients_contact ON Clients(ContactNumber);

-- =================================================================
-- Employees Table Indexes - Low Priority
-- =================================================================

-- Index for employee location analysis
-- Reason: Employee management and geographic distribution
CREATE INDEX idx_employees_address ON Employees(AddressID);

-- Index for salary and position analysis
-- Reason: HR reports and employee management
CREATE INDEX idx_employees_position_salary ON Employees(Position, Salary);

-- =================================================================
-- Audit Table Indexes - Medium Priority
-- =================================================================

-- Composite index for audit trail queries
-- Reason: Audit reports by order and time period
CREATE INDEX idx_audit_order_created ON Audit(OrderID, CreatedAt);

-- Index for action-based audit filtering
-- Reason: Filtering audit records by action type
CREATE INDEX idx_audit_action_created ON Audit(Action, CreatedAt);

-- =================================================================
-- Notifications Table Indexes - Low Priority
-- =================================================================

-- Composite index for client notification queries
-- Reason: User notification retrieval and management
CREATE INDEX idx_notifications_client_created ON Notifications(ClientID, CreatedAt);

-- Index for notification type analysis
-- Reason: Notification system analytics and type-based filtering
CREATE INDEX idx_notifications_type_read ON Notifications(Type, IsRead);

-- =================================================================
-- Addresses Table Indexes - Low Priority
-- =================================================================

-- Index for geographic analysis
-- Reason: Location-based reporting and analysis
CREATE INDEX idx_addresses_county ON Addresses(County);

-- =================================================================
-- Performance Analysis Queries
-- =================================================================

-- Query to analyze index usage (run after some operations)
/*
SHOW INDEX FROM Orders;
SHOW INDEX FROM Activity;
SHOW INDEX FROM Products;

-- Check index statistics
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    CARDINALITY,
    SUB_PART,
    NULLABLE
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'retail_analytics'
ORDER BY TABLE_NAME, INDEX_NAME;
*/

-- =================================================================
-- Index Maintenance Recommendations
-- =================================================================

/*
MAINTENANCE SCHEDULE RECOMMENDATIONS:

1. Weekly Index Statistics Update:
   - Run ANALYZE TABLE on all tables to update index statistics
   - Monitor index cardinality and effectiveness

2. Monthly Index Performance Review:
   - Check slow query log for missing indexes
   - Review EXPLAIN plans for main business queries
   - Monitor index usage statistics

3. Quarterly Index Optimization:
   - Identify unused indexes for potential removal
   - Consider new indexes based on query patterns
   - Optimize composite index column order

PERFORMANCE MONITORING QUERIES:

-- Check table sizes and index sizes
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Total Size (MB)',
    ROUND((data_length / 1024 / 1024), 2) AS 'Data Size (MB)',
    ROUND((index_length / 1024 / 1024), 2) AS 'Index Size (MB)'
FROM information_schema.tables 
WHERE table_schema = 'retail_analytics'
ORDER BY (data_length + index_length) DESC;

-- Monitor index usage (MySQL 5.7+)
SELECT 
    object_schema,
    object_name,
    index_name,
    count_read,
    count_insert,
    count_update,
    count_delete
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE object_schema = 'retail_analytics'
ORDER BY count_read DESC;
*/

-- =================================================================
-- Index Performance Testing
-- =================================================================

/*
TEST QUERIES TO VALIDATE INDEX EFFECTIVENESS:

-- Test Orders date-based queries
EXPLAIN SELECT * FROM Orders WHERE Date BETWEEN '2024-01-01' AND '2024-12-31';

-- Test product performance queries
EXPLAIN SELECT ProductID, SUM(Cost) FROM Orders GROUP BY ProductID;

-- Test customer activity queries
EXPLAIN SELECT ClientID, COUNT(*) FROM Activity WHERE CreatedAt >= DATE_SUB(NOW(), INTERVAL 30 DAY) GROUP BY ClientID;

-- Test composite index effectiveness
EXPLAIN SELECT * FROM Orders WHERE Date = '2024-01-15' AND ClientID = 'CLI001';

-- Test join performance
EXPLAIN SELECT c.FullName, SUM(o.Cost) 
FROM Clients c 
JOIN Orders o ON c.ClientID = o.ClientID 
WHERE o.Date >= '2024-01-01' 
GROUP BY c.ClientID;
*/
