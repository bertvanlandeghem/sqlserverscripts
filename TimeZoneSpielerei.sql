DECLARE @LocalTimeZone VARCHAR(50)
EXEC MASTER.dbo.xp_regread 'HKEY_LOCAL_MACHINE',
'SYSTEM\CurrentControlSet\Control\TimeZoneInformation',
'TimeZoneKeyName',@LocalTimeZone OUT

DECLARE @timezoneLocalOffset int
SELECT @timezoneLocalOffset = DATEPART(tz,SYSDATETIMEOFFSET())

DECLARE @timezoneCanada sysname = 'Canada Central Standard Time'
DECLARE @timezoneCanadaOffset char(6)
SELECT @timezoneCanadaOffset = current_utc_offset FROM sys.time_zone_info WHERE name = @timezoneCanada

SELECT 'LocalTimeZone'        = @LocalTimeZone
     , 'timezoneLocalOffset'  = @timezoneLocalOffset
     , 'timezoneCanada'       = @timezoneCanada
     , 'timezoneCanadaOffset' = @timezoneCanadaOffset

SELECT 'UTC' = SYSUTCDATETIME() 
     , 'local time' = SYSDATETIMEOFFSET()
     , 'Europe Local Time' = SWITCHOFFSET(SYSDATETIMEOFFSET(), @timezoneLocalOffset)

     , 'Canada' = SYSDATETIMEOFFSET() AT TIME ZONE @timezoneCanada
     , 'Canada2' = SWITCHOFFSET(SYSDATETIMEOFFSET(), @timezoneCanadaOffset)
     , 'CanadaLocal' = CAST( (SYSDATETIMEOFFSET() AT TIME ZONE @timezoneCanada) as Datetime2)
     , 'CanadaToUTC' = SWITCHOFFSET( (SYSDATETIMEOFFSET() AT TIME ZONE @timezoneCanada), '+00:00')

--SELECT * FROM sys.time_zone_info --


--DECLARE @MyDate DATETIMEOFFSET = SYSDATETIMEOFFSET(); -- UTC
--SELECT SYSDATETIMEOFFSET()
--SELECT CONVERT(DATETIME, SWITCHOFFSET(@MyDate, DATEPART(tz,SYSDATETIMEOFFSET()))); -- to local server time

