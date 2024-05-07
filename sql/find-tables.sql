-- Tool to loop through all known databases in a connection and find matching table names
CREATE TABLE #TableNames (TableName NVARCHAR(128))

INSERT INTO #TableNames (TableName)
VALUES ('%PostAwardConditionTracking%'), ('%GrantTermActuals%'), ('%ThirdTable%')

CREATE TABLE #TempResult
(
    DATABASE_NAME NVARCHAR(128),
    TABLE_NAME NVARCHAR(128),
    COLUMN_NAME NVARCHAR(128),
    DATA_TYPE NVARCHAR(60),
    IS_NULLABLE BIT,
    INDEX_NAME NVARCHAR(128),
    COLUMN_DESCRIPTION NVARCHAR(MAX),
    FOREIGN_KEY_NAME NVARCHAR(128)
)

EXEC sp_MSforeachdb '
USE [?];
IF DB_ID(''?'') > 4
BEGIN
    INSERT INTO #TempResult
        SELECT 
            ''?'' AS DATABASE_NAME,
            t.name AS TABLE_NAME,
            c.name AS COLUMN_NAME,
            tp.name AS DATA_TYPE,
            c.is_nullable,
            ind.name AS INDEX_NAME,
	    CONVERT(NVARCHAR(MAX), ep.value) AS COLUMN_DESCRIPTION,
	    CONVERT(NVARCHAR(MAX), fk.name) AS FOREIGN_KEY_NAME
        FROM 
            sys.tables t
        INNER JOIN 
            sys.columns c ON t.object_id = c.object_id
        INNER JOIN 
            sys.types tp ON c.user_type_id = tp.user_type_id
        LEFT JOIN 
            sys.index_columns ic ON ic.object_id = t.object_id AND ic.column_id = c.column_id
        LEFT JOIN 
            sys.indexes ind ON ic.object_id = ind.object_id AND ic.index_id = ind.index_id
        LEFT JOIN 
            sys.extended_properties ep ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
        LEFT JOIN 
            sys.foreign_key_columns fkc ON fkc.parent_object_id = t.object_id AND fkc.parent_column_id = c.column_id
        LEFT JOIN 
            sys.foreign_keys fk ON fk.object_id = fkc.constraint_object_id
        INNER JOIN
            #TableNames tn ON t.name LIKE tn.TableName
END
'

SELECT * FROM #TempResult

DROP TABLE #TempResult
DROP TABLE #TableNames