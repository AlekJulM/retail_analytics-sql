-- Retail Analytics Platform Triggers
-- Author: Alexander Jamin Julon Mayta
-- Description: Database triggers for audit, automation, and business rules

USE retail_analytics;

DELIMITER //

-- Trigger: UpdateAudit AFTER INSERT ON Orders
-- Description: Automatically create audit record when new order is inserted
CREATE TRIGGER UpdateAudit
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO Audit (OrderID, Action, NewValues, CreatedAt)
    VALUES (
        NEW.OrderID, 
        'INSERT',
        JSON_OBJECT(
            'OrderID', NEW.OrderID,
            'ProductID', NEW.ProductID,
            'ClientID', NEW.ClientID,
            'EmployeeID', NEW.EmployeeID,
            'Quantity', NEW.Quantity,
            'Cost', NEW.Cost,
            'Date', NEW.Date
        ),
        NOW()
    );
END //

-- Trigger: UpdateAuditOnUpdate AFTER UPDATE ON Orders
-- Description: Track changes to existing orders
CREATE TRIGGER UpdateAuditOnUpdate
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO Audit (OrderID, Action, OldValues, NewValues, CreatedAt)
    VALUES (
        NEW.OrderID,
        'UPDATE',
        JSON_OBJECT(
            'OrderID', OLD.OrderID,
            'ProductID', OLD.ProductID,
            'ClientID', OLD.ClientID,
            'EmployeeID', OLD.EmployeeID,
            'Quantity', OLD.Quantity,
            'Cost', OLD.Cost,
            'Date', OLD.Date
        ),
        JSON_OBJECT(
            'OrderID', NEW.OrderID,
            'ProductID', NEW.ProductID,
            'ClientID', NEW.ClientID,
            'EmployeeID', NEW.EmployeeID,
            'Quantity', NEW.Quantity,
            'Cost', NEW.Cost,
            'Date', NEW.Date
        ),
        NOW()
    );
END //

-- Trigger: UpdateAuditOnDelete AFTER DELETE ON Orders
-- Description: Track deleted orders
CREATE TRIGGER UpdateAuditOnDelete
AFTER DELETE ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO Audit (OrderID, Action, OldValues, CreatedAt)
    VALUES (
        OLD.OrderID,
        'DELETE',
        JSON_OBJECT(
            'OrderID', OLD.OrderID,
            'ProductID', OLD.ProductID,
            'ClientID', OLD.ClientID,
            'EmployeeID', OLD.EmployeeID,
            'Quantity', OLD.Quantity,
            'Cost', OLD.Cost,
            'Date', OLD.Date
        ),
        NOW()
    );
END //

-- Trigger: UpdateInventoryOnOrder AFTER INSERT ON Orders
-- Description: Automatically update product inventory when order is placed
CREATE TRIGGER UpdateInventoryOnOrder
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    UPDATE Products 
    SET NumberOfItems = NumberOfItems - NEW.Quantity
    WHERE ProductID = NEW.ProductID;
    
    -- Check if inventory is low and create notification
    IF (SELECT NumberOfItems FROM Products WHERE ProductID = NEW.ProductID) <= 10 THEN
        INSERT INTO Notifications (ClientID, Message, Type)
        SELECT DISTINCT 
            e.EmployeeID,
            CONCAT('Low inventory alert: Product ', NEW.ProductID, ' is running low (', 
                   (SELECT NumberOfItems FROM Products WHERE ProductID = NEW.ProductID), 
                   ' items remaining)'),
            'system'
        FROM Employees e
        WHERE e.Position IN ('Inventory Manager', 'Sales Manager')
        LIMIT 1;
    END IF;
END //

-- Trigger: ValidateOrderCost BEFORE INSERT ON Orders
-- Description: Ensure order cost matches product price and quantity
CREATE TRIGGER ValidateOrderCost
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
    DECLARE expectedCost DECIMAL(10,2);
    DECLARE availableStock INT;
    
    -- Get expected cost based on product sell price
    SELECT SellPrice INTO expectedCost FROM Products WHERE ProductID = NEW.ProductID;
    SET expectedCost = expectedCost * NEW.Quantity;
    
    -- Check if enough stock is available
    SELECT NumberOfItems INTO availableStock FROM Products WHERE ProductID = NEW.ProductID;
    
    -- Validate stock availability
    IF availableStock < NEW.Quantity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Insufficient inventory for this order';
    END IF;
    
    -- Auto-correct cost if it doesn't match expected (within 1% tolerance)
    IF ABS(NEW.Cost - expectedCost) / expectedCost > 0.01 THEN
        SET NEW.Cost = expectedCost;
    END IF;
END //

-- Trigger: LogActivityOnProductView AFTER INSERT ON Activity
-- Description: Enhanced activity logging with automatic categorization
CREATE TRIGGER LogActivityOnProductView
AFTER INSERT ON Activity
FOR EACH ROW
BEGIN
    DECLARE productPrice DECIMAL(10,2);
    DECLARE clientOrderCount INT;
    
    -- Get product price for analysis
    SELECT SellPrice INTO productPrice FROM Products WHERE ProductID = NEW.ProductID;
    
    -- Get client's order history count
    SELECT COUNT(*) INTO clientOrderCount FROM Orders WHERE ClientID = NEW.ClientID;
    
    -- Create targeted notifications based on activity patterns
    IF NEW.ActivityType = 'view' AND productPrice > 50 AND clientOrderCount > 3 THEN
        -- High-value customer viewing expensive product
        INSERT INTO Notifications (ClientID, Message, Type)
        VALUES (
            NEW.ClientID,
            CONCAT('Special offer on ', (SELECT ProductName FROM Products WHERE ProductID = NEW.ProductID), ' - 10% off for valued customers!'),
            'promotion'
        );
    END IF;
    
    IF NEW.ActivityType = 'cart_add' THEN
        -- Product added to cart - send follow-up reminder
        INSERT INTO Notifications (ClientID, Message, Type)
        VALUES (
            NEW.ClientID,
            'Don\'t forget about the items in your cart! Complete your purchase today.',
            'marketing' 
        );
    END IF;
END //

-- Trigger: UpdateProductRating AFTER INSERT ON Orders
-- Description: Update product performance metrics based on sales
        
CREATE TRIGGER UpdateProductRating
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    DECLARE totalOrders INT;
    DECLARE avgOrderValue DECIMAL(10,2);
    
    -- Calculate metrics for the product
    SELECT 
        COUNT(*),
        AVG(Cost/Quantity)
    INTO totalOrders, avgOrderValue
    FROM Orders 
    WHERE ProductID = NEW.ProductID;
    
    -- Update product properties with calculated metrics (if we had a rating field)
    -- For demonstration, we'll log this as an activity instead
    INSERT INTO Activity (ClientID, ProductID, Properties, ActivityType)
    VALUES (
        NULL,
        NEW.ProductID,
        JSON_OBJECT(
            'total_orders', totalOrders,
            'avg_order_value', avgOrderValue,
            'last_order_date', NEW.Date,
            'metric_update', 'automatic'
        ),
        'view'
    );
END //

DELIMITER ;

-- Test trigger functionality (commented out for production)
/*
-- Example: Insert a test order to see triggers in action
INSERT INTO Orders (ProductID, ClientID, EmployeeID, Quantity, Cost, Date) 
VALUES ('PRD001', 'CLI001', 1, 2, 179.98, CURDATE());

-- Check audit table
SELECT * FROM Audit ORDER BY CreatedAt DESC LIMIT 5;

-- Check notifications
SELECT * FROM Notifications ORDER BY CreatedAt DESC LIMIT 5;

-- Check product inventory
SELECT ProductID, ProductName, NumberOfItems FROM Products WHERE ProductID = 'PRD001';
*/
