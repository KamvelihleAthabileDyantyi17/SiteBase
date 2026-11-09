/* Describe a database (READ ONLY - changes nothing)
   1. Change the USE line to the database you want to describe.
   2. Press F5.
   3. Right-click the results grid > "Save Results As..." > CSV,
      save into Desktop\SiteBase\local\ (e.g. CA_DBase_SQL_structure.csv). */
USE [CA_DBase_SQL];
GO
SELECT  s.name AS SchemaName,
        o.name AS ObjectName,
        o.type_desc AS ObjectType,
        (SELECT SUM(p.rows) FROM sys.partitions p
          WHERE p.object_id = o.object_id AND p.index_id IN (0, 1)) AS TotalRows,
        (SELECT STRING_AGG(CAST(c.name + ' ' + ty.name +
                    CASE WHEN ty.name IN ('varchar','char','nvarchar','nchar')
                         THEN '(' + CASE WHEN c.max_length = -1 THEN 'max'
                                         WHEN ty.name LIKE 'n%' THEN CAST(c.max_length / 2 AS varchar(10))
                                         ELSE CAST(c.max_length AS varchar(10)) END + ')'
                         ELSE '' END +
                    CASE WHEN c.is_nullable = 1 THEN '' ELSE ' NOT NULL' END AS nvarchar(max)), ', ')
                WITHIN GROUP (ORDER BY c.column_id)
           FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id
          WHERE c.object_id = o.object_id) AS Columns,
        o.create_date AS Created,
        o.modify_date AS LastChanged
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U', 'V', 'P', 'FN', 'IF', 'TF', 'TR')   -- tables, views, procedures, functions, triggers
ORDER BY o.type_desc, s.name, o.name;
