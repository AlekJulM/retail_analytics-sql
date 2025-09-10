-- Retail Analytics Platform CTE Queries
-- Author: Alexander Jamin Julon Mayta
-- Description: Common Table Expressions for complex analytics and reporting

USE retail_analytics;

-- =================================================================
-- CTE vs UNION Examples - Performance Comparison (P2 Analysis)
-- =================================================================

-- Example 1: Customer Sales Analysis - CTE Approach
WITH CustomerSalesData AS (
    SELECT 
        c.ClientID,
        c.FullName,
        COUNT(o.OrderID) as OrderCount,
        SUM(o.Cost) as TotalSpent,
        AVG(o.Cost) as AvgOrderValue,
        MAX(o.Date) as LastOrderDate
    FROM Clients c
    LEFT JOIN Orders o ON c.ClientID = o.ClientID
    GROUP BY c.ClientID, c.FullName
),
HighValueCustomers AS (
    SELECT *
    FROM CustomerSalesData
    WHERE TotalSpent > 100
),
LowValueCustomers AS (
    SELECT *
    FROM CustomerSalesData
    WHERE TotalSpent <= 100 OR TotalSpent IS NULL
)
SELECT 
    'High Value' as CustomerSegment,
    COUNT(*) as CustomerCount,
    AVG(TotalSpent) as AvgTotalSpent,
    AVG(OrderCount) as AvgOrderCount
FROM HighValueCustomers
UNION ALL
SELECT 
    'Low Value' as CustomerSegment,
    COUNT(*) as CustomerCount,
    AVG(COALESCE(TotalSpent, 0)) as AvgTotalSpent,
    AVG(COALESCE(OrderCount, 0)) as AvgOrderCount
FROM LowValueCustomers;

-- Same analysis using UNION (Traditional Approach)
-- Note: This approach is less efficient and harder to maintain
SELECT 
    'High Value' as CustomerSegment,
    COUNT(*) as CustomerCount,
    AVG(total_spent) as AvgTotalSpent,
    AVG(order_count) as AvgOrderCount
FROM (
    SELECT 
        c.ClientID,
        SUM(o.Cost) as total_spent,
        COUNT(o.OrderID) as order_count
    FROM Clients c
    LEFT JOIN Orders o ON c.ClientID = o.ClientID
    GROUP BY c.ClientID
    HAVING SUM(o.Cost) > 100
) high_value
UNION ALL
SELECT 
    'Low Value' as CustomerSegment,
    COUNT(*) as CustomerCount,
    AVG(COALESCE(total_spent, 0)) as AvgTotalSpent,
    AVG(COALESCE(order_count, 0)) as AvgOrderCount
FROM (
    SELECT 
        c.ClientID,
        SUM(o.Cost) as total_spent,
        COUNT(o.OrderID) as order_count
    FROM Clients c
    LEFT JOIN Orders o ON c.ClientID = o.ClientID
    GROUP BY c.ClientID
    HAVING SUM(o.Cost) <= 100 OR SUM(o.Cost) IS NULL
) low_value;

-- =================================================================
-- Data Summary 2022 - Advanced CTE Examples
-- =================================================================

-- Monthly Sales Summary with Running Totals
WITH MonthlySales AS (
    SELECT 
        DATE_FORMAT(Date, '%Y-%m') as SalesMonth,
        COUNT(OrderID) as OrderCount,
        SUM(Cost) as MonthlyRevenue,
        AVG(Cost) as AvgOrderValue,
        COUNT(DISTINCT ClientID) as UniqueCustomers
    FROM Orders
    WHERE YEAR(Date) = 2024  -- Using 2024 since our sample data is from 2024
    GROUP BY DATE_FORMAT(Date, '%Y-%m')
),
RunningTotals AS (
    SELECT 
        SalesMonth,
        OrderCount,
        MonthlyRevenue,
        AvgOrderValue,
        UniqueCustomers,
        SUM(MonthlyRevenue) OVER (ORDER BY SalesMonth) as RunningRevenue,
        LAG(MonthlyRevenue) OVER (ORDER BY SalesMonth) as PrevMonthRevenue,
        CASE 
            WHEN LAG(MonthlyRevenue) OVER (ORDER BY SalesMonth) IS NOT NULL 
            THEN ((MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY SalesMonth)) / LAG(MonthlyRevenue) OVER (ORDER BY SalesMonth)) * 100
            ELSE 0
        END as GrowthRate
    FROM MonthlySales
)
SELECT 
    SalesMonth,
    OrderCount,
    ROUND(MonthlyRevenue, 2) as MonthlyRevenue,
    ROUND(AvgOrderValue, 2) as AvgOrderValue,
    UniqueCustomers,
    ROUND(RunningRevenue, 2) as RunningRevenue,
    ROUND(GrowthRate, 2) as MonthlyGrowthPercent
FROM RunningTotals
ORDER BY SalesMonth;

-- Product Performance Analysis with Recursive CTE for Category Hierarchy
WITH ProductPerformance AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        p.BuyPrice,
        p.SellPrice,
        COALESCE(SUM(o.Quantity), 0) as TotalSold,
        COALESCE(SUM(o.Cost), 0) as TotalRevenue,
        COALESCE(SUM((p.SellPrice - p.BuyPrice) * o.Quantity), 0) as TotalProfit,
        p.NumberOfItems as CurrentStock
    FROM Products p
    LEFT JOIN Orders o ON p.ProductID = o.ProductID
    GROUP BY p.ProductID, p.ProductName, p.Category, p.BuyPrice, p.SellPrice, p.NumberOfItems
),
CategorySummary AS (
    SELECT 
        Category,
        COUNT(*) as ProductCount,
        SUM(TotalSold) as CategoryTotalSold,
        SUM(TotalRevenue) as CategoryRevenue,
        SUM(TotalProfit) as CategoryProfit,
        AVG(TotalRevenue) as AvgProductRevenue,
        SUM(CurrentStock) as CategoryStock
    FROM ProductPerformance
    GROUP BY Category
),
PerformanceRanking AS (
    SELECT 
        pp.*,
        RANK() OVER (PARTITION BY pp.Category ORDER BY pp.TotalRevenue DESC) as RevenueRank,
        RANK() OVER (ORDER BY pp.TotalProfit DESC) as ProfitRank,
        cs.CategoryRevenue,
        cs.CategoryProfit,
        ROUND((pp.TotalRevenue / cs.CategoryRevenue) * 100, 2) as CategoryRevenuePercent
    FROM ProductPerformance pp
    JOIN CategorySummary cs ON pp.Category = cs.Category
)
SELECT 
    ProductID,
    ProductName,
    Category,
    TotalSold,
    ROUND(TotalRevenue, 2) as TotalRevenue,
    ROUND(TotalProfit, 2) as TotalProfit,
    RevenueRank as CategoryRank,
    ProfitRank as OverallProfitRank,
    CategoryRevenuePercent,
    CASE 
        WHEN CurrentStock <= 10 THEN 'Critical'
        WHEN CurrentStock <= 30 THEN 'Low'
        ELSE 'Good'
    END as StockStatus
FROM PerformanceRanking
ORDER BY TotalProfit DESC;

-- Customer Journey Analysis with Window Functions
WITH CustomerJourney AS (
    SELECT 
        c.ClientID,
        c.FullName,
        o.OrderID,
        o.Date as OrderDate,
        o.Cost as OrderValue,
        ROW_NUMBER() OVER (PARTITION BY c.ClientID ORDER BY o.Date) as OrderSequence,
        LAG(o.Date) OVER (PARTITION BY c.ClientID ORDER BY o.Date) as PrevOrderDate,
        DATEDIFF(o.Date, LAG(o.Date) OVER (PARTITION BY c.ClientID ORDER BY o.Date)) as DaysBetweenOrders,
        SUM(o.Cost) OVER (PARTITION BY c.ClientID ORDER BY o.Date) as RunningCustomerValue
    FROM Clients c
    JOIN Orders o ON c.ClientID = o.ClientID
),
CustomerBehavior AS (
    SELECT 
        ClientID,
        FullName,
        COUNT(*) as TotalOrders,
        MIN(OrderDate) as FirstOrderDate,
        MAX(OrderDate) as LastOrderDate,
        DATEDIFF(MAX(OrderDate), MIN(OrderDate)) as CustomerLifespanDays,
        AVG(DaysBetweenOrders) as AvgDaysBetweenOrders,
        MAX(RunningCustomerValue) as TotalCustomerValue,
        AVG(OrderValue) as AvgOrderValue,
        CASE 
            WHEN COUNT(*) >= 5 THEN 'Loyal'
            WHEN COUNT(*) >= 3 THEN 'Regular'
            WHEN COUNT(*) >= 2 THEN 'Returning'
            ELSE 'New'
        END as CustomerType
    FROM CustomerJourney
    GROUP BY ClientID, FullName
)
SELECT 
    CustomerType,
    COUNT(*) as CustomerCount,
    ROUND(AVG(TotalCustomerValue), 2) as AvgLifetimeValue,
    ROUND(AVG(AvgOrderValue), 2) as AvgOrderValue,
    ROUND(AVG(CustomerLifespanDays), 1) as AvgLifespanDays,
    ROUND(AVG(AvgDaysBetweenOrders), 1) as AvgDaysBetweenOrders
FROM CustomerBehavior
GROUP BY CustomerType
ORDER BY AvgLifetimeValue DESC;

-- Activity Analysis with JSON Processing
WITH ActivityAnalysis AS (
    SELECT 
        a.ClientID,
        a.ActivityType,
        COUNT(*) as ActivityCount,
        DATE_FORMAT(a.CreatedAt, '%Y-%m-%d') as ActivityDate,
        JSON_EXTRACT(a.Properties, '$.time_spent') as TimeSpent,
        JSON_EXTRACT(a.Properties, '$.page') as PageType
    FROM Activity a
    WHERE a.CreatedAt >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY a.ClientID, a.ActivityType, DATE_FORMAT(a.CreatedAt, '%Y-%m-%d'),
             JSON_EXTRACT(a.Properties, '$.time_spent'), JSON_EXTRACT(a.Properties, '$.page')
),
DailyEngagement AS (
    SELECT 
        ActivityDate,
        COUNT(DISTINCT ClientID) as ActiveUsers,
        SUM(ActivityCount) as TotalActivities,
        AVG(CAST(TimeSpent as UNSIGNED)) as AvgTimeSpent,
        COUNT(CASE WHEN ActivityType = 'view' THEN 1 END) as ViewActions,
        COUNT(CASE WHEN ActivityType = 'cart_add' THEN 1 END) as CartActions
    FROM ActivityAnalysis
    WHERE TimeSpent IS NOT NULL
    GROUP BY ActivityDate
)
SELECT 
    ActivityDate,
    ActiveUsers,
    TotalActivities,
    ROUND(AvgTimeSpent, 0) as AvgTimeSpentSeconds,
    ViewActions,
    CartActions,
    CASE 
        WHEN CartActions > 0 THEN ROUND((CartActions / ViewActions) * 100, 2)
        ELSE 0
    END as ConversionRate
FROM DailyEngagement
ORDER BY ActivityDate DESC;
