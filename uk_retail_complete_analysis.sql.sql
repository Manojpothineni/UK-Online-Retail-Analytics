-- overall Business Summary
SELECT 
    COUNT(*) AS TotalTransactions,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT StockCode) AS UniqueProducts,
    COUNT(DISTINCT Country) AS CountriesServed,
    CONCAT('£', FORMAT(SUM(TotalPrice), 2)) AS TotalRevenue,
    CONCAT('£', FORMAT(AVG(TotalPrice), 2)) AS AvgTransactionValue,
    CONCAT('£', FORMAT(SUM(TotalPrice) / COUNT(DISTINCT InvoiceNo), 2)) AS AvgOrderValue,
    FORMAT(SUM(Quantity), 0) AS TotalItemsSold
FROM sales_transactions;

-- Top 15 Revenue by Country
SELECT Country,TotalOrders,TotalCustomers,CONCAT('£', FORMAT(TotalRevenue, 2)) AS Revenue,
CONCAT('£', FORMAT(AvgOrderValue, 2)) AS AvgOrderValue,
CONCAT(ROUND(TotalRevenue * 100.0 / (SELECT SUM(TotalRevenue) FROM countries), 2), '%') AS RevenueShare
FROM countries
ORDER BY TotalRevenue DESC
LIMIT 15;

-- Monthly Sales Trends
SELECT Year,Month,MonthName,COUNT(DISTINCT InvoiceNo) AS Orders,CONCAT('£', FORMAT(SUM(TotalPrice),2)) AS Revenue,
format(SUM(Quantity),0) AS ItemsSold,COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM sales_transactions
GROUP BY Year, Month, MonthName
ORDER BY Year, Month;

-- Top 20 Best-Selling Products
SELECT StockCode,Description,CONCAT('£', FORMAT(TotalRevenue, 2)) AS Revenue,
FORMAT(TotalQuantitySold, 0) AS UnitsSold,TransactionCount AS TimesPurchased,
CONCAT('£', FORMAT(AvgUnitPrice, 2)) AS AvgPrice
FROM products
ORDER BY TotalRevenue DESC
LIMIT 20;

-- Top 20 VIP Customers
SELECT CustomerID,Country,TotalOrders,
CONCAT('£', FORMAT(TotalSpent, 2)) AS LifetimeValue,
CONCAT('£', FORMAT(AvgOrderValue, 2)) AS AvgOrderValue,FirstPurchaseDate,LastPurchaseDate,
DATEDIFF(LastPurchaseDate, FirstPurchaseDate) AS CustomerLifespanDays,
CASE 
	WHEN TotalSpent > 10000 THEN 'VIP Platinum'
	WHEN TotalSpent > 5000 THEN 'VIP Gold'
	WHEN TotalSpent > 2000 THEN 'VIP Silver'
	ELSE 'Regular'
    END AS CustomerTier
FROM customers
ORDER BY TotalSpent DESC
LIMIT 20;

-- UK vs International Comparison 

SELECT 
    CASE 
        WHEN Country = 'United Kingdom' THEN 'UK (Domestic)'
        ELSE 'International'
    END AS Market,
    COUNT(DISTINCT InvoiceNo) AS Orders,
    COUNT(DISTINCT CustomerID) AS Customers,
    CONCAT('£', FORMAT(SUM(TotalPrice), 2)) AS Revenue,
    CONCAT(ROUND(SUM(TotalPrice) * 100.0 / (SELECT SUM(TotalPrice) FROM sales_transactions), 2), '%') AS RevenueShare,
    CONCAT('£', FORMAT(AVG(TotalPrice), 2)) AS AvgTransactionValue
FROM sales_transactions
GROUP BY Market;

-- Sales by Day of Week
Select DayOfWeek,COUNT(DISTINCT InvoiceNo) AS Orders,CONCAT('£', FORMAT(SUM(TotalPrice), 2)) AS Revenue,
FORMAT(SUM(Quantity), 0) AS ItemsSold
FROM sales_transactions
GROUP BY DayOfWeek
ORDER BY 
    CASE DayOfWeek
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;
    

--  Month-over-Month Growth
Select Year,MonthName,CONCAT('£', FORMAT(Revenue, 2)) AS Revenue,
CONCAT('£', FORMAT(PreviousMonthRevenue, 2)) AS PreviousMonth,
    CASE 
        WHEN PreviousMonthRevenue IS NULL THEN 'N/A'
        ELSE CONCAT(
            CASE WHEN GrowthRate > 0 THEN '+' ELSE '' END,
            ROUND(GrowthRate, 2), '%'
        )
    END AS GrowthRate
FROM (
    SELECT Year,Month,MonthName,SUM(TotalPrice) AS Revenue,
	LAG(SUM(TotalPrice)) OVER (ORDER BY Year, Month) AS PreviousMonthRevenue,
	((SUM(TotalPrice) - LAG(SUM(TotalPrice)) OVER (ORDER BY Year, Month)) / 
	LAG(SUM(TotalPrice)) OVER (ORDER BY Year, Month)) * 100 AS GrowthRate
    FROM sales_transactions
    GROUP BY Year, Month, MonthName
) AS MonthlyGrowth
ORDER BY Year, Month; 

-- Weekend vs Weekday Sales

SELECT 
    CASE 
        WHEN IsWeekend = 1 THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,
    COUNT(DISTINCT InvoiceNo) AS Orders,
    CONCAT('£', FORMAT(SUM(TotalPrice), 2)) AS Revenue,
    FORMAT(SUM(Quantity), 0) AS ItemsSold,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM sales_transactions
GROUP BY DayType;   

-- Product Price Range Analysis
SELECT 
    CASE 
        WHEN AvgUnitPrice < 1 THEN '£0 - £1'
        WHEN AvgUnitPrice < 5 THEN '£1 - £5'
        WHEN AvgUnitPrice < 10 THEN '£5 - £10'
        WHEN AvgUnitPrice < 20 THEN '£10 - £20'
        WHEN AvgUnitPrice < 50 THEN '£20 - £50'
        ELSE '£50+'
    END AS PriceRange,
    COUNT(*) AS ProductCount,
    CONCAT('£', FORMAT(SUM(TotalRevenue), 2)) AS TotalRevenue,
    FORMAT(SUM(TotalQuantitySold), 0) AS TotalUnitsSold
FROM products
GROUP BY PriceRange
ORDER BY MIN(AvgUnitPrice);