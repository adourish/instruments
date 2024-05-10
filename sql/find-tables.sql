-- search all tables in all databases
-- create detailed and summary views
IF OBJECT_ID('tempdb..#TableNames') IS NOT NULL
    DROP TABLE #TableNames

IF OBJECT_ID('tempdb..#TempResult') IS NOT NULL
    DROP TABLE #TempResult


CREATE TABLE #TableNames (TableName NVARCHAR(128))
DECLARE @columnFilter NVARCHAR(MAX)
DECLARE @columnFilter2 NVARCHAR(MAX)
DECLARE @columnFilter3 NVARCHAR(MAX)
DECLARE @columnFilter4 NVARCHAR(MAX)
DECLARE @columnFilter5 NVARCHAR(MAX)
DECLARE @includeStoredProcs BIT


INSERT INTO #TableNames (TableName) VALUES 
-- Terms and Conditions
('%ConsolidatedTerms%'), ('%ConditionTrackingTermActual%'), ('%GrantTermActuals%'), 
-- OCC
('%OCM_OffCycleMemoTermActual_P%'), ('%OCM_OffCycleMemo_P%'), ('%OCM_OffCycleMemo_P%'),
-- STAR
('%LU_STAR_ComplianceElement%'), ('%LU_STAR_ProgramRequirement%'), ('%LU_STAR_ProgramRequirement_LU_STAR_ComplianceElement_R%'), ('%STAR_FormComplianceHandbookMappingConfiguration%'), ('%PostAward_TATS_STAR_Compliance%'),
-- ESV
('%ESV_SiteVisitReportTermActual_P%'), ('%LU_CMN_ProgramRequirementConsolidatedTermDetail%')

SET @columnFilter = '%Term%'
SET @columnFilter2 = '%Condition%'
SET @columnFilter3 = '%TermTitle%'
SET @columnFilter4 = '%DisplayText%'
SET @columnFilter5 = '%DisplayText%'
SET @includeStoredProcs = 1

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
    FOREIGN_KEY_NAME NVARCHAR(MAX)
)

EXEC sp_MSforeachdb '
USE [?];
IF DB_ID(''?'') > 4 AND DB_NAME() NOT IN (''ReleaseManagement'',''EHBAdmin'')
BEGIN

    INSERT INTO #TempResult
        SELECT DISTINCT
            ''?'' AS DATABASE_NAME,
            s.name AS SCHEMA_NAME,
            o.name AS OBJECT_NAME,            
            c.name AS COLUMN_NAME,
			o.type_desc AS OBJECT_TYPE,
            tp.name AS DATA_TYPE,
            c.is_nullable,
            ind.name AS INDEX_NAME,
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


    INSERT INTO #TempResult (DATABASE_NAME, SCHEMA_NAME, OBJECT_TYPE, OBJECT_NAME, COLUMN_NAME, DATA_TYPE)
    SELECT DISTINCT
        DB_NAME() as DATABASE_NAME,
		''NA'' as SCHEMA_NAME,
		r.ROUTINE_DEFINITION as OBJECT_TYPE,
        r.ROUTINE_NAME as OBJECT_NAME,
        r.ROUTINE_TYPE as COLUMN_NAME,
        r.ROUTINE_DEFINITION as DATA_TYPE
    FROM 
        INFORMATION_SCHEMA.ROUTINES r
		INNER JOIN
            #TableNames tn ON r.ROUTINE_DEFINITION LIKE tn.TableName



END
'

SELECT * FROM #TempResult

;WITH CTE AS 
(
  SELECT DATABASE_NAME, SCHEMA_NAME, OBJECT_NAME, COLUMN_NAME,
  STRING_AGG(OBJECT_TYPE, ', ') AS Indexed_Foreign_Key_Columns,
  'SELECT top 5 * FROM [' + DATABASE_NAME + '].[' + SCHEMA_NAME + '].[' + OBJECT_NAME + ']' AS SelectStar
  FROM #TempResult
  WHERE (INDEX_NAME IS NOT NULL OR 
  FOREIGN_KEY_NAME IS NOT NULL OR
  (OBJECT_TYPE LIKE @columnFilter  OR
  OBJECT_TYPE LIKE @columnFilter2  OR
  OBJECT_TYPE LIKE  @columnFilter3  OR
  OBJECT_TYPE LIKE @columnFilter4 OR
  OBJECT_TYPE LIKE @columnFilter5))
  GROUP BY DATABASE_NAME, SCHEMA_NAME, OBJECT_NAME, COLUMN_NAME
)
SELECT * FROM CTE
WHERE (Indexed_Foreign_Key_Columns LIKE  @columnFilter  OR 
Indexed_Foreign_Key_Columns LIKE @columnFilter2  OR 
Indexed_Foreign_Key_Columns LIKE  @columnFilter3 OR
Indexed_Foreign_Key_Columns LIKE  @columnFilter4 OR
Indexed_Foreign_Key_Columns LIKE  @columnFilter5) AND
(COLUMN_NAME != 'PROCEDURE' AND COLUMN_NAME != 'FUNCTION')

IF OBJECT_ID('tempdb..#TempResult') IS NOT NULL
    DROP TABLE #TempResult

IF OBJECT_ID('tempdb..#TableNames') IS NOT NULL
    DROP TABLE #TableNames