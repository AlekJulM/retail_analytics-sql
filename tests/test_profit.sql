-- Retail Analytics Platform Profit Tests
-- Author: Alexander Jamin Julon Mayta
-- Description: Test suite for profit calculation functions and related business logic

USE retail_analytics;

-- =================================================================
-- Test Setup and Initialization
-- =================================================================

-- Create test results table for storing test outcomes
CREATE TABLE IF NOT EXISTS test_results (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    test_category VARCHAR(50) NOT NULL,
    expected_result DECIMAL(10,2),
    actual_result DECIMAL(10,2),
    test_status ENUM('PASS', 'FAIL', 'ERROR') NOT NULL,
    error_message TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clear previous test results
TRUNCATE TABLE test_results;

-- =================================================================
-- Test Data Setup
-- =================================================================

-- Insert test-specific data
INSERT INTO Products (ProductID, ProductName, BuyPrice, SellPrice, NumberOfItems, Category) VALUES
('TEST001', 'Test Product 1', 10.00, 20.00, 100, 'Test'),
('TEST002', 'Test Product 2', 50.00, 75.00, 50, 'Test'),
('TEST003', 'Test Product No Orders', 15.00, 30.00, 25, 'Test')
ON DUPLICATE KEY UPDATE ProductID=ProductID;

-- Insert test orders
INSERT INTO Orders (ProductID, ClientID, EmployeeID, Quantity, Cost, Date) VALUES
('TEST001', 'CLI001', 1, 5, 100.00, '2024-01-01'),
('TEST001', 'CLI002', 2, 3, 60.00, '2024-01-02'),
('TEST002', 'CLI003', 1, 2, 150.00, '2024-01-03'),
('TEST002', 'CLI001', 3, 1, 75.00, '2024-01-04');

-- =================================================================
-- Test Functions Definition
-- =================================================================

DELIMITER //

-- Test helper procedure to record results
CREATE PROCEDURE RecordTestResult(
    IN p_test_name VARCHAR(100),
    IN p_test_category VARCHAR(50),
    IN p_expected DECIMAL(10,2),
    IN p_actual DECIMAL(10,2),
    IN p_error_msg TEXT
)
BEGIN
    DECLARE test_status ENUM('PASS', 'FAIL', 'ERROR');
    
    IF p_error_msg IS NOT NULL THEN
        SET test_status = 'ERROR';
    ELSEIF ABS(p_expected - p_actual) < 0.01 THEN
        SET test_status = 'PASS';
    ELSE
        SET test_status = 'FAIL';
    END IF;
    
    INSERT INTO test_results (test_name, test_category, expected_result, actual_result, test_status, error_message)
    VALUES (p_test_name, p_test_category, p_expected, p_actual, test_status, p_error_msg);
END //

DELIMITER ;

-- =================================================================
-- GetProfit Function Tests
-- =================================================================

-- Test 1: GetProfit for specific product with orders
SET @test_name = 'GetProfit - TEST001 specific product';
SET @expected = (10.00 * 8); -- (20-10) * (5+3) = 80.00
SET @actual = GetProfit('TEST001');
CALL RecordTestResult(@test_name, 'GetProfit', @expected, @actual, NULL);

-- Test 2: GetProfit for product with different profit margin
SET @test_name = 'GetProfit - TEST002 specific product';
SET @expected = (25.00 * 3); -- (75-50) * (2+1) = 75.00
SET @actual = GetProfit('TEST002');
CALL RecordTestResult(@test_name, 'GetProfit', @expected, @actual, NULL);

-- Test 3: GetProfit for product with no orders
SET @test_name = 'GetProfit - TEST003 no orders';
SET @expected = 0.00;
SET @actual = GetProfit('TEST003');
CALL RecordTestResult(@test_name, 'GetProfit', @expected, @actual, NULL);

-- Test 4: GetProfit for non-existent product
SET @test_name = 'GetProfit - Non-existent product';
SET @expected = 0.00;
SET @actual = GetProfit('NONEXISTENT');
CALL RecordTestResult(@test_name, 'GetProfit', @expected, @actual, NULL);

-- Test 5: GetProfit for all products (NULL parameter)
SET @test_name = 'GetProfit - All products (NULL)';
-- Calculate expected: All test products + existing products
SELECT SUM((p.SellPrice - p.BuyPrice) * o.Quantity) INTO @expected
FROM Orders o
JOIN Products p ON o.ProductID = p.ProductID;
SET @actual = GetProfit(NULL);
CALL RecordTestResult(@test_name, 'GetProfit', @expected, @actual, NULL);

-- Test 6: GetProfit for all products (empty string)
SET @test_name = 'GetProfit - All products (empty string)';
SET @actual = GetProfit('');
CALL RecordTestResult(@test_name, 'GetProfit', @expected, @actual, NULL);

-- =================================================================
-- FindAverageCost Function Tests
-- =================================================================

-- Test 7: FindAverageCost for TEST001
SET @test_name = 'FindAverageCost - TEST001';
SET @expected = 20.00; -- (100/5 + 60/3) / 2 = (20 + 20) / 2 = 20.00
SET @actual = FindAverageCost('TEST001');
CALL RecordTestResult(@test_name, 'FindAverageCost', @expected, @actual, NULL);

-- Test 8: FindAverageCost for TEST002
SET @test_name = 'FindAverageCost - TEST002';
SET @expected = 75.00; -- (150/2 + 75/1) / 2 = (75 + 75) / 2 = 75.00
SET @actual = FindAverageCost('TEST002');
CALL RecordTestResult(@test_name, 'FindAverageCost', @expected, @actual, NULL);

-- Test 9: FindAverageCost for product with no orders
SET @test_name = 'FindAverageCost - No orders';
SET @expected = 0.00;
SET @actual = FindAverageCost('TEST003');
CALL RecordTestResult(@test_name, 'FindAverageCost', @expected, @actual, NULL);

-- Test 10: FindAverageCost for non-existent product
SET @test_name = 'FindAverageCost - Non-existent product';
SET @expected = 0.00;
SET @actual = FindAverageCost('NONEXISTENT');
CALL RecordTestResult(@test_name, 'FindAverageCost', @expected, @actual, NULL);

-- =================================================================
-- EvaluateProduct Procedure Tests
-- =================================================================

-- Test 11: EvaluateProduct for existing product
-- Note: This test checks if the procedure runs without error
-- The actual verification would require comparing result sets
DELIMITER //
CREATE PROCEDURE TestEvaluateProduct()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        CALL RecordTestResult('EvaluateProduct - TEST001', 'EvaluateProduct', 0, 0, 'Procedure execution failed');
    END;
    
    CALL EvaluateProduct('TEST001');
    CALL RecordTestResult('EvaluateProduct - TEST001', 'EvaluateProduct', 1, 1, NULL);
END //
DELIMITER ;

CALL TestEvaluateProduct();

-- Test 12: EvaluateProduct for non-existent product
DELIMITER //
CREATE PROCEDURE TestEvaluateProductNotFound()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        CALL RecordTestResult('EvaluateProduct - Not Found', 'EvaluateProduct', 0, 0, 'Procedure execution failed');
    END;
    
    CALL EvaluateProduct('NONEXISTENT');
    CALL RecordTestResult('EvaluateProduct - Not Found', 'EvaluateProduct', 1, 1, NULL);
END //
DELIMITER ;

CALL TestEvaluateProductNotFound();

-- =================================================================
-- Commission Calculation Tests
-- =================================================================

-- Test 13: CalculateEmployeeCommission with 5% rate
SET @test_name = 'CalculateEmployeeCommission - Employee 1';
-- Calculate expected commission for employee 1
SELECT SUM(Cost) * 0.05 INTO @expected FROM Orders WHERE EmployeeID = 1;
SET @actual = CalculateEmployeeCommission(1, 0.05);
CALL RecordTestResult(@test_name, 'Commission', @expected, @actual, NULL);

-- Test 14: CalculateEmployeeCommission with different rate
SET @test_name = 'CalculateEmployeeCommission - Employee 2 (3%)';
SELECT SUM(Cost) * 0.03 INTO @expected FROM Orders WHERE EmployeeID = 2;
SET @actual = CalculateEmployeeCommission(2, 0.03);
CALL RecordTestResult(@test_name, 'Commission', @expected, @actual, NULL);

-- Test 15: CalculateEmployeeCommission for employee with no sales
SET @test_name = 'CalculateEmployeeCommission - No sales';
SET @expected = 0.00;
SET @actual = CalculateEmployeeCommission(999, 0.05); -- Non-existent employee
CALL RecordTestResult(@test_name, 'Commission', @expected, @actual, NULL);

-- =================================================================
-- Edge Case Tests
-- =================================================================

-- Test 16: Zero quantity order (should not exist due to constraints, but test function behavior)
-- Insert edge case data temporarily
INSERT INTO Products (ProductID, ProductName, BuyPrice, SellPrice, NumberOfItems, Category) VALUES
('EDGE001', 'Edge Case Product', 0.00, 0.01, 1, 'Test')
ON DUPLICATE KEY UPDATE ProductID=ProductID;

-- This should fail due to quantity constraint, testing our validation
-- Test 17: Negative profit margin product
INSERT INTO Products (ProductID, ProductName, BuyPrice, SellPrice, NumberOfItems, Category) VALUES
('EDGE002', 'Loss Product', 100.00, 50.00, 10, 'Test')
ON DUPLICATE KEY UPDATE BuyPrice=100.00, SellPrice=50.00;

-- Add an order for the loss product
INSERT INTO Orders (ProductID, ClientID, EmployeeID, Quantity, Cost, Date) VALUES
('EDGE002', 'CLI001', 1, 1, 50.00, '2024-01-05');

SET @test_name = 'GetProfit - Negative margin product';
SET @expected = -50.00; -- (50-100) * 1 = -50.00
SET @actual = GetProfit('EDGE002');
CALL RecordTestResult(@test_name, 'GetProfit', @expected, @actual, NULL);

-- =================================================================
-- Performance Tests
-- =================================================================

-- Test 18: Performance test for GetProfit with multiple calls
SET @start_time = NOW(6);
SELECT GetProfit('TEST001') INTO @dummy;
SELECT GetProfit('TEST002') INTO @dummy;
SELECT GetProfit(NULL) INTO @dummy;
SET @end_time = NOW(6);
SET @execution_time = TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000; -- Convert to milliseconds

-- Record performance result (expected under 100ms for these simple queries)
CALL RecordTestResult('Performance - Multiple GetProfit calls', 'Performance', 100, @execution_time, 
    CASE WHEN @execution_time > 100 THEN 'Performance degraded' ELSE NULL END);

-- =================================================================
-- Data Integrity Tests
-- =================================================================

-- Test 19: Verify profit calculations match manual calculations
SELECT 
    SUM((p.SellPrice - p.BuyPrice) * o.Quantity) INTO @manual_calc
FROM Orders o
JOIN Products p ON o.ProductID = p.ProductID
WHERE o.ProductID IN ('TEST001', 'TEST002');

SET @function_calc = GetProfit('TEST001') + GetProfit('TEST002');
CALL RecordTestResult('Data Integrity - Manual vs Function', 'Integrity', @manual_calc, @function_calc, NULL);

-- =================================================================
-- Test Results Summary
-- =================================================================

-- Display test results summary
SELECT 
    test_category,
    COUNT(*) as total_tests,
    SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) as passed,
    SUM(CASE WHEN test_status = 'FAIL' THEN 1 ELSE 0 END) as failed,
    SUM(CASE WHEN test_status = 'ERROR' THEN 1 ELSE 0 END) as errors,
    ROUND(
        (SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) as pass_rate_percent
FROM test_results
GROUP BY test_category
ORDER BY test_category;

-- Display detailed results for failed tests
SELECT 
    test_name,
    test_category,
    expected_result,
    actual_result,
    test_status,
    error_message,
    executed_at
FROM test_results
WHERE test_status IN ('FAIL', 'ERROR')
ORDER BY executed_at;

-- Overall test summary
SELECT 
    COUNT(*) as total_tests,
    SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) as total_passed,
    SUM(CASE WHEN test_status = 'FAIL' THEN 1 ELSE 0 END) as total_failed,
    SUM(CASE WHEN test_status = 'ERROR' THEN 1 ELSE 0 END) as total_errors,
    ROUND(
        (SUM(CASE WHEN test_status = 'PASS' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 
        2
    ) as overall_pass_rate
FROM test_results;

-- =================================================================
-- Cleanup Test Data
-- =================================================================

-- Remove test-specific data
DELETE FROM Orders WHERE ProductID LIKE 'TEST%' OR ProductID LIKE 'EDGE%';
DELETE FROM Products WHERE ProductID LIKE 'TEST%' OR ProductID LIKE 'EDGE%';

-- Drop test procedures
DROP PROCEDURE IF EXISTS TestEvaluateProduct;
DROP PROCEDURE IF EXISTS TestEvaluateProductNotFound;
DROP PROCEDURE IF EXISTS RecordTestResult;

-- Keep test_results table for reference
-- DROP TABLE IF EXISTS test_results;
