DROP TABLE dbo.Clientes_Limpio

CREATE TABLE dbo.Clientes_Limpio (
    id INT NOT NULL PRIMARY KEY,

    edad INT NOT NULL,
    edad_grupo VARCHAR(20) NOT NULL,

    genero CHAR(1) NOT NULL, -- M / F

    producto_comprado VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,

    monto_compra DECIMAL(10,2) NOT NULL,

    ubicacion VARCHAR(100) NOT NULL,
    talla VARCHAR(10) NULL,
    color VARCHAR(30) NULL,
    temporada VARCHAR(20) NOT NULL,

    calificacion DECIMAL(3,2) NULL, -- ej: 4.75

    estado_suscripcion BIT NOT NULL, -- 0 / 1

    tipo_envio VARCHAR(30) NOT NULL,

    descuento BIT NOT NULL,

    compras_previas INT NOT NULL,

    metodo_pago VARCHAR(30) NOT NULL,

    frecuencia_compras VARCHAR(30) NOT NULL,
    frecuencia_compras_dias SMALLINT NOT NULL
);

EXEC sp_help 'dbo.Clientes_Limpio';

ALTER TABLE dbo.Clientes_Limpio
ALTER COLUMN genero VARCHAR(10);

ALTER TABLE dbo.Clientes_Limpio
ALTER COLUMN estado_suscripcion VARCHAR(3);

ALTER TABLE dbo.Clientes_Limpio
ALTER COLUMN descuento VARCHAR(3);

SELECT TOP 5 * FROM Clientes_Limpio ;

--¿Cuál es el ingreso total (revenue) generado por clientes hombres vs. mujeres?

select genero, sum(monto_compra) as gasto_total
from Clientes_Limpio
group by genero;

--¿Qué clientes usaron descuento pero aun así gastaron más que el monto promedio de compra?

DECLARE @promedio DECIMAL(10,2);

-- Calcula el promedio primero
SELECT @promedio = AVG(monto_compra) FROM Clientes_Limpio;

-- Luego usa la variable
SELECT
    COUNT(CASE 
            WHEN descuento = 'Yes' AND monto_compra >= @promedio
            THEN 1
          END) AS Personas_Descuento_Gasto_Mayor,
    COUNT(CASE 
            WHEN descuento = 'Yes'
            THEN 1
          END) AS Usaron_Descuento,

	COUNT(id) as Clientes_totales

FROM Clientes_Limpio;

--¿Cuáles son los 5 productos con la calificación promedio (review rating) más alta?

select top 5 producto_comprado, avg(calificacion) as promedio_calificacion
from Clientes_Limpio
group by producto_comprado
order by avg(calificacion) desc;


--Compara el monto promedio de compra entre envío estándar y envío express.

select tipo_envio, ROUND( AVG(monto_compra), 2) as promedio_compra
from Clientes_Limpio
where tipo_envio in ('Standard', 'Express')
group by tipo_envio;


--¿Los clientes suscritos gastan más?
--Compara el gasto promedio y el ingreso total entre clientes suscritos y no suscritos.

select estado_suscripcion, COUNT(id) as Clientes,
ROUND(avg(monto_compra),2) as promedio_gastos,
SUM(monto_compra) as suma_gastos 
from Clientes_Limpio
group by estado_suscripcion
order by suma_gastos, promedio_gastos asc;

--¿Qué 5 productos tienen el mayor porcentaje de compras con descuento aplicado?

select top 5 producto_comprado, convert(decimal(5,2), SUM(case when descuento = 'Yes' then 1 end) * 1.0 / COUNT(*) * 100) as porcentaje_descuento
from Clientes_Limpio
group by producto_comprado
order by porcentaje_descuento;


--Segmenta a los clientes en:
--Nuevos
--Recurrentes
--Leales
--Basado en el total de compras previas, y muestra cuántos clientes hay en cada segmento.
WITH tipo_cliente AS (
    SELECT 
        id, 
        compras_previas,
        CASE 
            WHEN compras_previas = 1 THEN 'Nuevos'
            WHEN compras_previas BETWEEN 2 AND 10 THEN 'Recurrentes'
            ELSE 'Leales'
        END AS Segmento_cliente
    FROM Clientes_Limpio
)
select segmento_cliente, COUNT(*) as 'Nuemro de cliente'
from tipo_cliente
group by segmento_cliente;


--¿Cuáles son los 3 productos más comprados dentro de cada categoría?

with articulos as (
	select categoria, 
		producto_comprado,
		COUNT(id) as total_clientes,
		row_number() over( partition by categoria order by count(id) desc) as rango_articulos
	from Clientes_Limpio
	group by categoria, producto_comprado
	)
select rango_articulos, categoria, producto_comprado, total_clientes
from articulos 
where rango_articulos <=3

--¿Los clientes que son compradores recurrentes (más de 5 compras previas) también tienden a suscribirse?

select count(id), estado_suscripcion
from Clientes_Limpio
where compras_previas > 5
group by estado_suscripcion

--¿Cuál es la contribución de ingresos (revenue) de cada grupo de edad?

select edad_grupo, sum(monto_compra) as total_compras 
from Clientes_Limpio
group by edad_grupo
order by total_compras
