use AdventureWorks2025
-- Ejercicio 1
--La siguiente consulta lo que hace es obtener el nombre del producto, la cantidad ordenada, la fecha del pedido y 
--el nombre del cliente para los pedidos realizados en el año 2014 donde el precio de lista del producto es mayor a 1000. 
 -- Activar estadísticas y planes
SET STATISTICS IO ON;
SET STATISTICS TIME ON;


-- Consulta original
SELECT p.Name AS Producto, sod.OrderQty, soh.OrderDate, c.Name AS Cliente
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
WHERE YEAR(soh.OrderDate) = 2014 AND p.ListPrice > 1000;


-- Activar estadísticas
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Consulta optimizada: rango explícito en lugar de función sobre columna
SELECT
    p.Name        AS Producto,
    sod.OrderQty,
    soh.OrderDate,
    c.AccountNumber AS Cliente          
FROM Production.Product        p
JOIN Sales.SalesOrderDetail    sod ON p.ProductID        = sod.ProductID
JOIN Sales.SalesOrderHeader    soh ON sod.SalesOrderID   = soh.SalesOrderID
JOIN Sales.Customer            c   ON soh.CustomerID     = c.CustomerID
WHERE soh.OrderDate >= '2014-01-01'    -- SARGable: el índice puede hacer Seek
  AND soh.OrderDate <  '2015-01-01'    -- cubre todo el año sin función
  AND p.ListPrice > 1000;



--------------------------------------------------------------- 2
--Ejercicio 2

 SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT e.NationalIDNumber, p.FirstName, p.LastName, edh.DepartmentID,
       (SELECT AVG(rh.Rate) FROM HumanResources.EmployeePayHistory rh 
        WHERE rh.BusinessEntityID = e.BusinessEntityID) as PromedioSalario
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
WHERE edh.EndDate IS NULL;
-------------------------------------------------------------------
--Optimizada con CTE para evitar subconsulta correlacionada
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- CTE
WITH SalariosPromedio AS (
    SELECT
        BusinessEntityID,
        AVG(Rate) AS PromedioSalario
    FROM HumanResources.EmployeePayHistory
    GROUP BY BusinessEntityID          -- agrega una sola vez
)
SELECT
    e.NationalIDNumber,
    p.FirstName,
    p.LastName,
    edh.DepartmentID,
    sp.PromedioSalario
FROM HumanResources.Employee e
JOIN Person.Person                              p   ON e.BusinessEntityID = p.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory  edh ON e.BusinessEntityID = edh.BusinessEntityID
JOIN SalariosPromedio                          sp  ON e.BusinessEntityID = sp.BusinessEntityID
WHERE edh.EndDate IS NULL;




-- ---------------------------------------------------
--Ejercicio 3
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT sod.SalesOrderID, p.ProductID, p.Name
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.CategoryID = 1 OR p.CategoryID = 2 OR p.CategoryID = 3 OR p.ListPrice > 500;


--------------------------------------------------Optimizada con IN() y eliminando columna inexistente
SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    sod.SalesOrderID,
    p.ProductID,
    p.Name                      AS Producto
FROM Sales.SalesOrderDetail           sod
JOIN Production.Product               p   ON sod.ProductID          = p.ProductID
JOIN Production.ProductSubcategory    ps  ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory       pc  ON ps.ProductCategoryID   = pc.ProductCategoryID
WHERE pc.ProductCategoryID IN (1, 2, 3)  -- IN() en lugar de OR repetido
                                          -- columna correcta: pc.ProductCategoryID
