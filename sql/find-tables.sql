IF OBJECT_ID('tempdb..#TableNames') IS NOT NULL
    DROP TABLE #TableNames

CREATE TABLE #TableNames (TableName NVARCHAR(128))

INSERT INTO #TableNames (TableName)
VALUES ('%PostAwardConditionTracking%'), ('%GrantTermActuals%'), ('%Term%'), ('%Condition%')

CREATE TABLE #TempResult
(
    DATABASE_NAME NVARCHAR(MAX),
    SCHEMA_NAME NVARCHAR(MAX),
    OBJECT_NAME NVARCHAR(MAX),
    OBJECT_TYPE NVARCHAR(MAX),
    COLUMN_NAME NVARCHAR(MAX),
    DATA_TYPE NVARCHAR(MAX),
    IS_NULLABLE BIT,
    INDEX_NAME NVARCHAR(MAX),
    COLUMN_DESCRIPTION NVARCHAR(MAX),
    FOREIGN_KEY_NAME NVARCHAR(MAX)
)

EXEC sp_MSforeachdb '
USE [?];
IF DB_ID(''?'') > 4
BEGIN
    INSERT INTO #TempResult
        SELECT 
            ''?'' AS DATABASE_NAME,
            s.name AS SCHEMA_NAME,
            o.name AS OBJECT_NAME,            
            c.name AS COLUMN_NAME,
			o.type_desc AS OBJECT_TYPE,
            tp.name AS DATA_TYPE,
            c.is_nullable,
            ind.name AS INDEX_NAME,
			CONVERT(NVARCHAR(MAX), ep.value) AS COLUMN_DESCRIPTION,
			CONVERT(NVARCHAR(MAX), fk.name) AS FOREIGN_KEY_NAME
        FROM 
            sys.objects o
        INNER JOIN 
            sys.columns c ON o.object_id = c.object_id
        INNER JOIN 
            sys.types tp ON c.user_type_id = tp.user_type_id
        LEFT JOIN 
            sys.index_columns ic ON ic.object_id = o.object_id AND ic.column_id = c.column_id
        LEFT JOIN 
            sys.indexes ind ON ic.object_id = ind.object_id AND ic.index_id = ind.index_id
        LEFT JOIN 
            sys.extended_properties ep ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
        LEFT JOIN 
            sys.foreign_key_columns fkc ON fkc.parent_object_id = o.object_id AND fkc.parent_column_id = c.column_id
        LEFT JOIN 
            sys.foreign_keys fk ON fk.object_id = fkc.constraint_object_id
        INNER JOIN 
            sys.schemas s ON o.schema_id = s.schema_id
        INNER JOIN
            #TableNames tn ON o.name LIKE tn.TableName
        WHERE 
            o.type IN (''U'', ''V'') 
END
'

SELECT * FROM #TempResult

IF OBJECT_ID('tempdb..#TempResult') IS NOT NULL
    DROP TABLE #TempResult

IF OBJECT_ID('tempdb..#TableNames') IS NOT NULL
    DROP TABLE #TableNames