if exists (select * from tempdb.sys.all_objects where name like '%#Temp_load_DB_SIZE%')
drop table #Temp_load_DB_SIZE
CREATE TABLE #Temp_load_DB_SIZE(
	[DbName] [nvarchar](128) NULL,
	[type] [tinyint] NOT NULL,
	[Recovery_Model] [nvarchar](60) NULL,
	[State] [nvarchar](60) NULL,
	[DataFile_Size_MB] [numeric](9,2) NULL,
	[DataFile_SpaceUsed_MB] [numeric](9,2) NULL,
	[DataFile_FreeSpace_MB] [numeric](9,2) NULL,
)
if exists (select * from tempdb.sys.all_objects where name like '%#DB_SIZE%')
drop table #DB_SIZE
CREATE TABLE #DB_SIZE(
	[DbName] [nvarchar](128) NULL,
	[type] [tinyint] NOT NULL,
	[Recovery_Model] [nvarchar](60) NULL,
	[State] [nvarchar](60) NULL,
	[DataFile_Size_MB] [numeric](9, 2) NULL,
	[DataFile_SpaceUsed_MB] [numeric](9,2) NULL,
	[DataFile_FreeSpace_MB] [numeric](9,2) NULL,
	[LogFile_Size_MB] [numeric](9,2) NOT NULL,
	[LogFile_SpaceUsed_MB] [numeric](9,2) NOT NULL,
	[LogFile_FreeSpace_MB] [numeric](9,2) NOT NULL
)


insert into #Temp_load_DB_SIZE
exec sp_msforeachdb
'USE [?]
select 
	DB_NAME() AS DbName
	,dbf.type
	,(select DBS.recovery_model_desc from sys.databases as DBS where DBS.name =DB_NAME() )  as Recovery_Model
	,(select  DBS.state_desc from sys.databases as DBS where DBS.name = DB_NAME())  as [State]
	,sum(dbf.size)/128.0 AS DataFile_Size_MB
	,sum(CAST(FILEPROPERTY(dbf.name, ''SpaceUsed'') AS INT))/128.0 as DataFile_SpaceUsed_MB
	,SUM( dbf.size)/128.0 - sum(CAST(FILEPROPERTY(dbf.name,''SpaceUsed'') AS INT))/128.0 AS DataFile_FreeSpace_MB 
from sys.database_files  as DBF
group by dbf.type'

insert into #DB_SIZE
select DbName,0 as [type]
, (select DBS.recovery_model_desc from sys.databases as DBS where DBS.name =DbName ) as recovery_model_desc
, (select  DBS.state_desc from sys.databases as DBS where DBS.name = DbName) as [State]
,sum(DataFile_Size_MB),sum(DataFile_SpaceUsed_MB),sum(DataFile_FreeSpace_MB),0,0,0
from #Temp_load_DB_SIZE
where type=0
group by DbName

update #DB_SIZE
set [LogFile_Size_MB] = (#Temp_load_DB_SIZE.DataFile_Size_MB)
,[LogFile_SpaceUsed_MB] = (#Temp_load_DB_SIZE.DataFile_SpaceUsed_MB)
,[LogFile_FreeSpace_MB] = (#Temp_load_DB_SIZE.DataFile_FreeSpace_MB)
from #Temp_load_DB_SIZE
where #Temp_load_DB_SIZE.[type] = 1 and #DB_SIZE.DbName = #Temp_load_DB_SIZE.DbName

select * from #DB_SIZE