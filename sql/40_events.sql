-- Retail Analytics Platform Event Scheduler
-- Author: Alexander Jamin Julon Mayta
-- Description: Automated maintenance tasks and scheduled events

USE retail_analytics;

-- =================================================================
-- Event Scheduler Configuration
-- =================================================================

-- Enable event scheduler (if not already enabled)
SET GLOBAL event_scheduler = ON;

-- =================================================================
-- Daily Maintenance Events
-- =================================================================

-- Daily Inventory Check Event
-- Runs every day at 2:00 AM to check low inventory and create alerts
DELIMITER //

CREATE EVENT IF NOT EXISTS daily_inventory_check
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 2 HOUR
COMMENT 'Daily inventory monitoring and low stock alerts'
DO
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE prod_id VARCHAR(20);
    DECLARE prod_name VARCHAR(100);
    DECLARE current_stock INT;
    DECLARE mgr_found INT DEFAULT 0;
    
    -- Cursor to find products with low inventory
    DECLARE inventory_cursor CURSOR FOR
        SELECT ProductID, ProductName, NumberOfItems
        FROM Products
        WHERE NumberOfItems <= 10;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Check if there's an inventory manager to notify
    SELECT COUNT(*) INTO mgr_found 
    FROM Employees 
    WHERE Position = 'Inventory Manager';
    
    OPEN inventory_cursor;
    
    inventory_loop: LOOP
        FETCH inventory_cursor INTO prod_id, prod_name, current_stock;
        IF done THEN
            LEAVE inventory_loop;
        END IF;
        
        -- Create notification for inventory manager or sales manager
        IF mgr_found > 0 THEN
            INSERT INTO Notifications (ClientID, Message, Type)
            SELECT 
                CONCAT('EMP', EmployeeID),
                CONCAT('DAILY ALERT: Low inventory for ', prod_name, ' (', prod_id, ') - Only ', current_stock, ' items remaining'),
                'system'
            FROM Employees 
            WHERE Position IN ('Inventory Manager', 'Sales Manager')
            LIMIT 1;
        END IF;
        
    END LOOP;
    
    CLOSE inventory_cursor;
    
    -- Log maintenance activity
    INSERT INTO Activity (ClientID, ProductID, Properties, ActivityType)
    VALUES (
        NULL,
        NULL,
        JSON_OBJECT(
            'event_type', 'daily_inventory_check',
            'timestamp', NOW(),
            'low_stock_products', (SELECT COUNT(*) FROM Products WHERE NumberOfItems <= 10)
        ),
        'view'
    );
END //

DELIMITER ;

-- =================================================================
-- Weekly Maintenance Events
-- =================================================================

-- Weekly Sales Summary Event
-- Runs every Sunday at 6:00 AM to generate weekly sales reports
DELIMITER //

CREATE EVENT IF NOT EXISTS weekly_sales_summary
ON SCHEDULE EVERY 1 WEEK
STARTS DATE_ADD(DATE_ADD(CURDATE(), INTERVAL (7 - DAYOFWEEK(CURDATE())) DAY), INTERVAL 6 HOUR)
COMMENT 'Weekly sales performance summary and reporting'
DO
BEGIN
    DECLARE total_weekly_sales DECIMAL(10,2) DEFAULT 0.00;
    DECLARE total_weekly_orders INT DEFAULT 0;
    DECLARE top_product VARCHAR(20);
    DECLARE top_customer VARCHAR(20);
    
    -- Calculate weekly metrics
    SELECT 
        COALESCE(SUM(Cost), 0),
        COUNT(*)
    INTO total_weekly_sales, total_weekly_orders
    FROM Orders
    WHERE Date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
    
    -- Find top performing product this week
    SELECT ProductID INTO top_product
    FROM Orders
    WHERE Date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY ProductID
    ORDER BY SUM(Cost) DESC
    LIMIT 1;
    
    -- Find top customer this week
    SELECT ClientID INTO top_customer
    FROM Orders
    WHERE Date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY ClientID
    ORDER BY SUM(Cost) DESC
    LIMIT 1;
    
    -- Send summary notification to managers
    INSERT INTO Notifications (ClientID, Message, Type)
    SELECT 
        CONCAT('EMP', EmployeeID),
        CONCAT('WEEKLY SUMMARY: Sales: $', total_weekly_sales, 
               ', Orders: ', total_weekly_orders,
               ', Top Product: ', COALESCE(top_product, 'None'),
               ', Top Customer: ', COALESCE(top_customer, 'None')),
        'system'
    FROM Employees
    WHERE Position IN ('Sales Manager', 'Inventory Manager');
    
    -- Log the summary generation
    INSERT INTO Activity (ClientID, ProductID, Properties, ActivityType)
    VALUES (
        NULL,
        top_product,
        JSON_OBJECT(
            'event_type', 'weekly_sales_summary',
            'total_sales', total_weekly_sales,
            'total_orders', total_weekly_orders,
            'top_customer', top_customer,
            'timestamp', NOW()
        ),
        'view'
    );
END //

DELIMITER ;

-- =================================================================
-- Monthly Maintenance Events
-- =================================================================

-- Monthly Database Cleanup Event
-- Runs on the 1st of every month at 3:00 AM
DELIMITER //

CREATE EVENT IF NOT EXISTS monthly_cleanup
ON SCHEDULE EVERY 1 MONTH
STARTS DATE_ADD(DATE_ADD(LAST_DAY(CURDATE()), INTERVAL 1 DAY), INTERVAL 3 HOUR)
COMMENT 'Monthly database cleanup and optimization'
DO
BEGIN
    -- Archive old audit records (older than 1 year)
    DELETE FROM Audit 
    WHERE CreatedAt < DATE_SUB(NOW(), INTERVAL 1 YEAR);
    
    -- Clean up old activity records (older than 6 months)
    DELETE FROM Activity 
    WHERE CreatedAt < DATE_SUB(NOW(), INTERVAL 6 MONTH)
    AND Properties IS NULL;
    
    -- Mark old notifications as read and clean up system notifications older than 3 months
    UPDATE Notifications 
    SET IsRead = TRUE 
    WHERE CreatedAt < DATE_SUB(NOW(), INTERVAL 3 MONTH)
    AND Type = 'system';
    
    DELETE FROM Notifications
    WHERE CreatedAt < DATE_SUB(NOW(), INTERVAL 6 MONTH)
    AND Type = 'system'
    AND IsRead = TRUE;
    
    -- Update table statistics
    -- Note: ANALYZE TABLE statements would go here in production
    
    -- Log cleanup activity
    INSERT INTO Activity (ClientID, ProductID, Properties, ActivityType)
    VALUES (
        NULL,
        NULL,
        JSON_OBJECT(
            'event_type', 'monthly_cleanup',
            'timestamp', NOW(),
            'cleanup_completed', TRUE
        ),
        'view'
    );
    
    -- Notify administrators
    INSERT INTO Notifications (ClientID, Message, Type)
    SELECT 
        CONCAT('EMP', EmployeeID),
        'Monthly database cleanup completed successfully.',
        'system'
    FROM Employees
    WHERE Position = 'Sales Manager'
    LIMIT 1;
END //

DELIMITER ;

-- =================================================================
-- Performance Monitoring Events
-- =================================================================

-- Daily Performance Monitor Event
-- Runs every day at 11:59 PM to collect performance metrics
DELIMITER //

CREATE EVENT IF NOT EXISTS daily_performance_monitor
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY - INTERVAL 1 MINUTE
COMMENT 'Daily performance metrics collection'
DO
BEGIN
    DECLARE slow_queries INT DEFAULT 0;
    DECLARE total_orders_today INT DEFAULT 0;
    DECLARE total_activities_today INT DEFAULT 0;
    
    -- Count today's orders
    SELECT COUNT(*) INTO total_orders_today
    FROM Orders
    WHERE Date = CURDATE();
    
    -- Count today's activities
    SELECT COUNT(*) INTO total_activities_today
    FROM Activity
    WHERE DATE(CreatedAt) = CURDATE();
    
    -- Log daily metrics
    INSERT INTO Activity (ClientID, ProductID, Properties, ActivityType)
    VALUES (
        NULL,
        NULL,
        JSON_OBJECT(
            'event_type', 'daily_performance_monitor',
            'date', CURDATE(),
            'orders_count', total_orders_today,
            'activities_count', total_activities_today,
            'timestamp', NOW()
        ),
        'view'
    );
    
    -- Alert if no orders today (potential issue)
    IF total_orders_today = 0 THEN
        INSERT INTO Notifications (ClientID, Message, Type)
        SELECT 
            CONCAT('EMP', EmployeeID),
            CONCAT('ALERT: No orders recorded today (', CURDATE(), '). Please verify system status.'),
            'system'
        FROM Employees
        WHERE Position = 'Sales Manager'
        LIMIT 1;
    END IF;
END //

DELIMITER ;

-- =================================================================
-- Customer Engagement Events
-- =================================================================

-- Weekly Customer Re-engagement Event
-- Runs every Tuesday at 10:00 AM to identify inactive customers
DELIMITER //

CREATE EVENT IF NOT EXISTS weekly_customer_reengagement
ON SCHEDULE EVERY 1 WEEK
STARTS DATE_ADD(DATE_ADD(CURDATE(), INTERVAL (3 - DAYOFWEEK(CURDATE()) + 7) % 7 DAY), INTERVAL 10 HOUR)
COMMENT 'Weekly customer re-engagement campaign for inactive customers'
DO
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE client_id VARCHAR(20);
    DECLARE client_name VARCHAR(100);
    DECLARE days_since_order INT;
    
    -- Cursor for inactive customers (no orders in last 30 days)
    DECLARE inactive_cursor CURSOR FOR
        SELECT 
            c.ClientID, 
            c.FullName,
            DATEDIFF(CURDATE(), MAX(o.Date)) as DaysSinceLastOrder
        FROM Clients c
        LEFT JOIN Orders o ON c.ClientID = o.ClientID
        GROUP BY c.ClientID, c.FullName
        HAVING MAX(o.Date) < DATE_SUB(CURDATE(), INTERVAL 30 DAY) 
           OR MAX(o.Date) IS NULL;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN inactive_cursor;
    
    reengagement_loop: LOOP
        FETCH inactive_cursor INTO client_id, client_name, days_since_order;
        IF done THEN
            LEAVE reengagement_loop;
        END IF;
        
        -- Create re-engagement notification
        INSERT INTO Notifications (ClientID, Message, Type)
        VALUES (
            client_id,
            CONCAT('We miss you, ', client_name, '! Check out our latest products and special offers just for you.'),
            'marketing'
        );
        
    END LOOP;
    
    CLOSE inactive_cursor;
    
    -- Log re-engagement activity
    INSERT INTO Activity (ClientID, ProductID, Properties, ActivityType)
    VALUES (
        NULL,
        NULL,
        JSON_OBJECT(
            'event_type', 'weekly_customer_reengagement',
            'timestamp', NOW(),
            'inactive_customers_contacted', (
                SELECT COUNT(DISTINCT c.ClientID)
                FROM Clients c
                LEFT JOIN Orders o ON c.ClientID = o.ClientID
                GROUP BY c.ClientID
                HAVING MAX(o.Date) < DATE_SUB(CURDATE(), INTERVAL 30 DAY) 
                   OR MAX(o.Date) IS NULL
            )
        ),
        'view'
    );
END //

DELIMITER ;

-- =================================================================
-- Event Management Queries
-- =================================================================

-- View all scheduled events
/*
SELECT 
    EVENT_NAME,
    EVENT_DEFINITION,
    INTERVAL_VALUE,
    INTERVAL_FIELD,
    STATUS,
    NEXT_EXECUTION_TIME,
    LAST_EXECUTED
FROM information_schema.EVENTS 
WHERE EVENT_SCHEMA = 'retail_analytics'
ORDER BY EVENT_NAME;
*/

-- =================================================================
-- Event Control Commands
-- =================================================================

-- Enable/Disable specific events
-- ALTER EVENT daily_inventory_check ENABLE;
-- ALTER EVENT daily_inventory_check DISABLE;

-- Drop events (use with caution)
-- DROP EVENT IF EXISTS daily_inventory_check;
-- DROP EVENT IF EXISTS weekly_sales_summary;
-- DROP EVENT IF EXISTS monthly_cleanup;
-- DROP EVENT IF EXISTS daily_performance_monitor;
-- DROP EVENT IF EXISTS weekly_customer_reengagement;

-- Check event scheduler status
-- SHOW VARIABLES LIKE 'event_scheduler';

-- =================================================================
-- Event Monitoring
-- =================================================================

/*
-- Monitor event execution
SELECT 
    EVENT_NAME,
    LAST_EXECUTED,
    STATUS
FROM information_schema.EVENTS 
WHERE EVENT_SCHEMA = 'retail_analytics';

-- Check for event-related errors in MySQL error log
-- This would typically be done at the system level:
-- tail -f /var/log/mysql/error.log | grep -i event
*/
