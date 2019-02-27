
-- Create Calendar
SET DATEFIRST 1;

DECLARE @startDate date = '2019-01-01' -- = CAST(SYSDATETIME() as date)
DECLARE @endDate   date = '2024-01-01' -- = CAST( DATEADD(YEAR, 5, SYSDATETIME() ) as date)
DECLARE @CalendarDays int = DATEDIFF(DAY, @startDate, @endDate) + 1

;WITH 
                L0 AS ( SELECT 1 AS c UNION ALL SELECT 1),
                L1 AS ( SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
                L2 AS ( SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
                L3 AS ( SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
                L4 AS ( SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
                L5 AS ( SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
           Numbers AS ( SELECT TOP (@CalendarDays) 
                               [Index] = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM L5  ),
     BasicCalendar AS ( SELECT TOP (DATEDIFF(DAY, @startDate, @endDate) + 1 )
                               [Index]
                             , [Date]  = DATEADD(DAY, [Index] - 1, @startDate )
                          FROM Numbers ),
  ExtendedCalendar AS (
                        SELECT [Index]
                             , [Date]        
                             , [Dayofyear]       = DATENAME(dayofyear, [Date])  
                             , [Year]            = DATENAME(YEAR, [Date]) 
                             , [Month]           = DATENAME(MONTH, [Date])
                             , [FirstDayOfMonth] = CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, [Date]), 0) as date)
                             , [LastDayOfMonth]  = EOMONTH([Date])
                             , [ISO_WEEK]        = DATEPART(ISO_WEEK, [Date])
                             , [WeekDay]         = DATEPART(WEEKDAY, [Date])
                             , [WeekDayName]     = DATENAME(WEEKDAY, date) 
                          FROM BasicCalendar )
SELECT *
FROM ExtendedCalendar
GO


-- Select Calendar into a temp table with a PK on the field(s) to which you want to join later.  
-- Not really important for small data sets, but can become