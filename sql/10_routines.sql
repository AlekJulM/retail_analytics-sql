-- Retail Analytics Platform Stored Routines
-- Author: Alexander Julon Mayta
-- Description: Stored procedures and functions for business logic

USE retail_analytics;

DELIMITER //

-- Function: FindAverageCost
-- Description: Calculate average cost of orders for a specific product
CREATE FUNCTION FindAverageCost(productId VARCHAR(20))
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE avgCost DECIMAL(10,2) DEFAULT 0.00;
    
    SELECT COALESCE(AVG(Cost / Quantity), 0.00) INTO avgCost
    FROM Orders 
    WHERE ProductID = productId;
    
    RETURN avgCost;
END //

-- Function: GetProfit
-- Description: Calculate profit for a specific product or all products
CREATE FUNCTION GetProfit(productId VARCHAR(20))
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE totalProfit DECIMAL(10,2) DEFAULT 0.00;
    
    IF productId IS NULL OR productId = '' THEN
        -- Calculate total profit for all products
        SELECT COALESCE(SUM((p.SellPrice - p.BuyPrice) * o.Quantity), 0.00) INTO totalProfit
        FROM Orders o
        JOIN Products p ON o.ProductID = p.ProductID;
    ELSE
        -- Calculate profit for specific product
        SELECT COALESCE(SUM((p.SellPrice - p.BuyPrice) * o.Quantity), 0.00) INTO totalProfit
        FROM Orders o
        JOIN Products p ON o.ProductID = p.ProductID
        WHERE o.ProductID = productId;
    END IF;
    
    RETURN totalProfit;
END //

-- Procedure: EvaluateProduct
-- Description: Comprehensive product analysis including sales, profit, and inventory status
CREATE PROCEDURE EvaluateProduct(IN productId VARCHAR(20))
BEGIN
    DECLARE productExists INT DEFAULT 0;
    
    -- Check if product exists
    SELECT COUNT(*) INTO productExists FROM Products WHERE ProductID = productId;
    
    IF productExists = 0 THEN
        SELECT 'Product not found' AS Status, productId AS ProductID;
    ELSE
        -- Return comprehensive product evaluation
        SELECT 
            p.ProductID,
            p.ProductName,
            p.Category,
            p.BuyPrice,
            p.SellPrice,
            p.NumberOfItems AS CurrentStock,
            COALESCE(SUM(o.Quantity), 0) AS TotalSold,
            COALESCE(COUNT(DISTINCT o.OrderID), 0) AS TotalOrders,
            COALESCE(SUM(o.Cost), 0.00) AS TotalRevenue,
            GetProfit(p.ProductID) AS TotalProfit,
            FindAverageCost(p.ProductID) AS AvgOrderCost,
            CASE 
                WHEN p.NumberOfItems <= 10 THEN 'Low Stock'
                WHEN p.NumberOfItems <= 30 THEN 'Medium Stock'
                ELSE 'Good Stock'
            END AS StockStatus,
            CASE 
                WHEN GetProfit(p.ProductID) > 100 THEN 'High Performer'
                WHEN GetProfit(p.ProductID) > 50 THEN 'Medium Performer'
                ELSE 'Low Performer'
            END AS PerformanceCategory
        FROM Products p
        LEFT JOIN Orders o ON p.ProductID = o.ProductID
        WHERE p.ProductID = productId
        GROUP BY p.ProductID, p.ProductName, p.Category, p.BuyPrice, p.SellPrice, p.NumberOfItems;
    END IF;
END //

-- Procedure: GetCustomerSummary
-- Description: Get comprehensive customer activity and purchase summary
CREATE PROCEDURE GetCustomerSummary(IN clientId VARCHAR(20))
BEGIN
    DECLARE customerExists INT DEFAULT 0;
    
    -- Check if customer exists
    SELECT COUNT(*) INTO customerExists FROM Clients WHERE ClientID = clientId;
    
    IF customerExists = 0 THEN
        SELECT 'Customer not found' AS Status, clientId AS ClientID;
    ELSE
        -- Customer basic info and purchase summary
        SELECT 
            c.ClientID,
            c.FullName,
            c.ContactNumber,
            CONCAT(a.Street, ', ', a.County) AS Address,
            COALESCE(COUNT(DISTINCT o.OrderID), 0) AS TotalOrders,
            COALESCE(SUM(o.Quantity), 0) AS TotalItemsPurchased,
            COALESCE(SUM(o.Cost), 0.00) AS TotalSpent,
            COALESCE(AVG(o.Cost), 0.00) AS AvgOrderValue,
            COALESCE(MAX(o.Date), 'No orders') AS LastOrderDate,
            COALESCE(COUNT(DISTINCT act.ActivityID), 0) AS TotalActivities
        FROM Clients c
        JOIN Addresses a ON c.AddressID = a.AddressID
        LEFT JOIN Orders o ON c.ClientID = o.ClientID
        LEFT JOIN Activity act ON c.ClientID = act.ClientID
        WHERE c.ClientID = clientId
        GROUP BY c.ClientID, c.FullName, c.ContactNumber, a.Street, a.County;
        
        -- Customer's favorite products (top 3)
        SELECT 
            'Top Products' AS Section,
            p.ProductName,
            SUM(o.Quantity) AS QuantityPurchased,
            SUM(o.Cost) AS TotalSpent
        FROM Orders o
        JOIN Products p ON o.ProductID = p.ProductID
        WHERE o.ClientID = clientId
        GROUP BY p.ProductID, p.ProductName
        ORDER BY SUM(o.Quantity) DESC
        LIMIT 3;
    END IF;
END //

-- Function: CalculateEmployeeCommission
-- Description: Calculate commission for employee based on sales
CREATE FUNCTION CalculateEmployeeCommission(employeeId INT, commissionRate DECIMAL(5,4))
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE totalCommission DECIMAL(10,2) DEFAULT 0.00;
    DECLARE totalSales DECIMAL(10,2) DEFAULT 0.00;
    
    SELECT COALESCE(SUM(Cost), 0.00) INTO totalSales
    FROM Orders 
    WHERE EmployeeID = employeeId;
    
    SET totalCommission = totalSales * commissionRate;
    
    RETURN totalCommission;
END //

-- Procedure: GenerateInventoryReport
-- Description: Generate comprehensive inventory status report
CREATE PROCEDURE GenerateInventoryReport()
BEGIN
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        p.NumberOfItems AS CurrentStock,
        p.BuyPrice,
        p.SellPrice,
        (p.SellPrice - p.BuyPrice) AS ProfitPerUnit,
        COALESCE(SUM(o.Quantity), 0) AS TotalSold,
        CASE 
            WHEN p.NumberOfItems <= 10 THEN 'URGENT - Restock Needed'
            WHEN p.NumberOfItems <= 30 THEN 'LOW - Monitor Stock'
            WHEN p.NumberOfItems <= 50 THEN 'MEDIUM - Normal Stock'
            ELSE 'HIGH - Good Stock'
        END AS StockAlert,
        p.NumberOfItems * p.BuyPrice AS InventoryValue
    FROM Products p
    LEFT JOIN Orders o ON p.ProductID = o.ProductID
    GROUP BY p.ProductID, p.ProductName, p.Category, p.NumberOfItems, p.BuyPrice, p.SellPrice
    ORDER BY p.NumberOfItems ASC, p.Category;
END //

DELIMITER ;

-- Example usage demonstrations:
/*
-- Test the functions and procedures:
SELECT FindAverageCost('PRD001') AS AvgCost;
SELECT GetProfit('PRD001') AS ProductProfit;
SELECT GetProfit(NULL) AS TotalProfit;
CALL EvaluateProduct('PRD001');
CALL GetCustomerSummary('CLI001');
SELECT CalculateEmployeeCommission(1, 0.05) AS Commission;
CALL GenerateInventoryReport();
*/
