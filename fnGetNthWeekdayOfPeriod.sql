-- Does not (yet) contain any error handling

/*
-- Extended Get Nth Weekday of period | Peter Larsson Blog
-- https://weblogs.sqlteam.com/peterl/2009/06/18/extended-get-nth-weekday-of-period/

CREATE OR ALTER FUNCTION dbo.fnGetNthWeekdayOfPeriod_original
(
    @theDate DATETIME,
    @theWeekday TINYINT,
    @theNth SMALLINT,
    @theType CHAR(1)
)
RETURNS DATETIME
BEGIN
    RETURN (
                SELECT theDate
                FROM    (
                            SELECT DATEADD(DAY, theDelta +(@theWeekday + 6 - DATEDIFF(DAY, '17530101', theFirst) % 7) % 7, theFirst) AS theDate
                            FROM    (
                                        SELECT CASE UPPER(@theType)
                                                    WHEN 'M' THEN DATEADD(MONTH, DATEDIFF(MONTH, @theNth, @theDate), '19000101')
                                                    WHEN 'Q' THEN DATEADD(QUARTER, DATEDIFF(QUARTER, @theNth, @theDate), '19000101')
                                                    WHEN 'Y' THEN DATEADD(YEAR, DATEDIFF(YEAR, @theNth, @theDate), '19000101')
                                                END AS theFirst,
                                                CASE SIGN(@theNth)
                                                    WHEN -1 THEN 7 * @theNth
                                                    WHEN 1 THEN 7 * @theNth - 7
                                                END AS theDelta
                                        WHERE   @theWeekday BETWEEN 1 AND 7
                                                AND (
                                                        @theNth BETWEEN -5 AND 5
                                                        AND UPPER(@theType) = 'M'
                                                    OR
                                                        @theNth BETWEEN -14 AND 14
                                                        AND UPPER(@theType) = 'Q'
                                                    OR
                                                        @theNth BETWEEN -53 AND 53
                                                        AND UPPER(@theType) = 'Y'
                                                )
                                                AND @theNth <> 0
                                    ) AS d
                        ) AS d
                WHERE   CASE UPPER(@theType)
                            WHEN 'M' THEN DATEDIFF(MONTH, theDate, @theDate) 
                            WHEN 'Q' THEN DATEDIFF(QUARTER, theDate, @theDate) 
                            WHEN 'Y' THEN DATEDIFF(YEAR, theDate, @theDate) 
                        END = 0
            )
END
GO
*/
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Get the N-th occurence of @FullBackupWeekday during @theIntervalType in which @theDate occurs. E.g. The First Saturday of this month, 3rd Wednesday of the Quarter, ...
CREATE OR ALTER FUNCTION dbo.fnGetNthWeekdayOfPeriod
(
    @theDate DATETIME,
    @theWeekday TINYINT, -- ma=1 ... zo=7
    @theNth SMALLINT,
    @theIntervalType CHAR(1)
)
RETURNS DATETIME
BEGIN
    /* Examples

    DECLARE @theDate DATETIME        = '2020-02-29 00:00:00.000' -- Current or custom date to determine interval
          , @theNth SMALLINT         = 1
          , @theWeekday TINYINT      = 6   -- ma=1 ... zo=7
          , @theIntervalType CHAR(1) = 'Y' -- 'M(onth)', 'Q(uarter)', 'Y(ear)'

    SELECT master.dbo.fnGetNthWeekdayOfPeriod_original(@theDate, @theWeekday, @theNth, @theIntervalType) -- ma=1 ... zo=7
    SELECT master.dbo.fnGetNthWeekdayOfPeriod(@theDate, @theWeekday, @theNth, @theIntervalType) -- ma=1 ... zo=7

    */
    RETURN (
                SELECT theDate
                FROM    (
                            SELECT DATEADD(DAY, theDelta + (@theWeekday + 6 - DATEDIFF(DAY, '17530101', IntervalBegin) % 7) % 7, IntervalBegin) AS theDate
                            FROM    (
                                        SELECT [IntervalBegin] = CASE UPPER(@theIntervalType)
                                                                      WHEN 'M' THEN DATEADD(MONTH  , DATEDIFF(MONTH  , 0, @theDate), '19000101') -- \
                                                                      WHEN 'Q' THEN DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @theDate), '19000101') --  |- begin of interval
                                                                      WHEN 'Y' THEN DATEADD(YEAR   , DATEDIFF(YEAR   , 0, @theDate), '19000101') -- /
                                                                 END
                                             , [theDelta] = CASE SIGN(@theNth)                   -- de gezochte dagnr is groter dan deze
                                                                 WHEN -1 THEN 7 * @theNth
                                                                 WHEN 1 THEN 7 * @theNth - 7
                                                            END  
                                        WHERE   @theWeekday BETWEEN 1 AND 7                 -- \
                                                AND (                                       --  |
                                                        @theNth BETWEEN -5 AND 5            --  |
                                                        AND UPPER(@theIntervalType) = 'M'   --  |
                                                    OR                                      --  |
                                                        @theNth BETWEEN -14 AND 14          --  |- Error handling for parameters
                                                        AND UPPER(@theIntervalType) = 'Q'   --  |
                                                    OR                                      --  |
                                                        @theNth BETWEEN -53 AND 53          --  |
                                                        AND UPPER(@theIntervalType) = 'Y'   --  |
                                                )                                           --  |
                                                AND @theNth <> 0                            -- /
                                    ) AS d
                        ) AS d
               WHERE   CASE UPPER(@theIntervalType)                             -- \
                           WHEN 'M' THEN DATEDIFF(MONTH  , theDate, @theDate)   --  |
                           WHEN 'Q' THEN DATEDIFF(QUARTER, theDate, @theDate)   --  |- Avoid Month overflows (e.g. avoid 2019-06-01 as the 5th satureday of May)
                           WHEN 'Y' THEN DATEDIFF(YEAR   , theDate, @theDate)   --  |
                       END = 0                                                  -- /
            )
END
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

