
-- 1. Ingresos totales                                  
SELECT SUM(total_price) AS Total_Revenue FROM pizza_sales;

-- 2. Valor promedio del pedido                        
SELECT (SUM(total_price) / COUNT(DISTINCT order_id)) AS Avg_order_Value FROM pizza_sales;

-- 3. Total de pizzas vendidas                          
SELECT SUM(quantity) AS Total_pizza_sold FROM pizza_sales;

-- 4. Total de pedidos                                  
SELECT COUNT(DISTINCT order_id) AS Total_Orders FROM pizza_sales;

-- 5. Promedio de pizzas por pedido                    
SELECT CAST(CAST(SUM(quantity) AS DECIMAL(10,2)) /
            CAST(COUNT(DISTINCT order_id) AS DECIMAL(10,2)) AS DECIMAL(10,2)) AS Avg_Pizzas_per_order
FROM pizza_sales;

-- B. Tendencia diaria de pedidos --
SELECT DATENAME(DW, order_date) AS order_day, COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales
GROUP BY DATENAME(DW, order_date);

-- C. Tendencia mensual de pedidos --
SELECT DATENAME(MONTH, order_date) AS Month_Name, COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY DATENAME(MONTH, order_date);

-- D. % de ventas por categoría --
SELECT pizza_category,
       CAST(SUM(total_price) AS DECIMAL(10,2)) AS total_revenue,
       CAST(SUM(total_price) * 100 / (SELECT SUM(total_price) FROM pizza_sales) AS DECIMAL(10,2)) AS PCT
FROM pizza_sales
GROUP BY pizza_category;

-- E. % de ventas por tamaño --
SELECT pizza_size,
       CAST(SUM(total_price) AS DECIMAL(10,2)) AS total_revenue,
       CAST(SUM(total_price) * 100 / (SELECT SUM(total_price) FROM pizza_sales) AS DECIMAL(10,2)) AS PCT
FROM pizza_sales
GROUP BY pizza_size
ORDER BY pizza_size;

--F. Pizzas vendidas por categoría (solo febrero) --
SELECT pizza_category, SUM(quantity) AS Total_Quantity_Sold
FROM pizza_sales
WHERE MONTH(order_date) = 2
GROUP BY pizza_category
ORDER BY Total_Quantity_Sold DESC;

-- G. Top 5 pizzas por ingresos --
SELECT TOP 5 pizza_name, SUM(total_price) AS Total_Revenue
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Revenue DESC;

-- H. Bottom 5 pizzas por ingresos --
SELECT TOP 5 pizza_name, SUM(total_price) AS Total_Revenue
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Revenue ASC;

-- I. Top 5 pizzas por cantidad --
SELECT TOP 5 pizza_name, SUM(quantity) AS Total_Pizza_Sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Pizza_Sold DESC;

-- J. Bottom 5 pizzas por cantidad --
SELECT TOP 5 pizza_name, SUM(quantity) AS Total_Pizza_Sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Pizza_Sold ASC;

-- K. Top 5 pizzas por número de pedidos --
SELECT TOP 5 pizza_name, COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Orders DESC;

-- L. Bottom 5 pizzas por número de pedidos --
SELECT TOP 5 pizza_name, COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Orders ASC;


-- ¿Cuáles son las 3 pizzas con más ingresos dentro de cada categoría?
WITH ventas AS (
    SELECT pizza_category, pizza_name, SUM(total_price) AS ingresos
    FROM pizza_sales
    GROUP BY pizza_category, pizza_name
),
ranking AS (
    SELECT pizza_category, pizza_name, ingresos,
           RANK() OVER (PARTITION BY pizza_category ORDER BY ingresos DESC) AS posicion
    FROM ventas
)
SELECT pizza_category, pizza_name, CAST(ingresos AS DECIMAL(10,2)) AS ingresos, posicion
FROM ranking
WHERE posicion <= 3
ORDER BY pizza_category, posicion;
                    

-- ¿Cuántas pizzas concentran el 80% de los ingresos? (análisis de Pareto)
--     
WITH ventas AS (
    SELECT pizza_name, SUM(total_price) AS ingresos
    FROM pizza_sales
    GROUP BY pizza_name
),
acumulado AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY ingresos DESC, pizza_name)                           AS posicion,
        pizza_name,
        ingresos,
        SUM(ingresos) OVER (ORDER BY ingresos DESC, pizza_name ROWS UNBOUNDED PRECEDING) AS ingresos_acumulados,
        SUM(ingresos) OVER ()                                                            AS ingresos_totales
    FROM ventas
)
SELECT
    posicion,
    pizza_name,
    CAST(ingresos AS DECIMAL(10,2))                                      AS ingresos,
    CAST(ingresos_acumulados * 100.0 / ingresos_totales AS DECIMAL(5,2)) AS pct_acumulado,
    CASE WHEN (ingresos_acumulados - ingresos) * 1.0 / ingresos_totales < 0.8
         THEN 'Si' ELSE 'No' END                                         AS dentro_del_80
FROM acumulado
ORDER BY posicion;                         


-- ¿Cuántas pizzas pide la gente por pedido?
WITH pedido AS (
    SELECT order_id, SUM(quantity) AS pizzas, SUM(total_price) AS total
    FROM pizza_sales
    GROUP BY order_id
)
SELECT
    pizzas,
    COUNT(*)                                                       AS pedidos,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct_pedidos,
    CAST(AVG(total) AS DECIMAL(10,2))                              AS valor_promedio_pedido
FROM pedido
GROUP BY pizzas
ORDER BY pizzas;

--  ¿Cuáles son los ingredientes más presentes en lo que se vende?

SELECT TOP (10) WITH TIES
    LTRIM(RTRIM(s.value)) AS ingrediente,
    SUM(v.quantity)       AS unidades_vendidas
FROM pizza_sales AS v
CROSS APPLY STRING_SPLIT(v.pizza_ingredients, ',') AS s
GROUP BY LTRIM(RTRIM(s.value))
ORDER BY SUM(v.quantity) DESC;             


