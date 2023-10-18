
-- check if the temporary tables already exist. If so, drop them.
IF OBJECT_ID('tempdb..#co2') IS NOT NULL
BEGIN
    DROP TABLE #co2;
END

IF OBJECT_ID('tempdb..#all_cols') IS NOT NULL
BEGIN
    DROP TABLE #all_cols;
END

IF OBJECT_ID('tempdb..#value_counts') IS NOT NULL
BEGIN
    DROP TABLE #value_counts;
END

IF OBJECT_ID('tempdb..#describe') IS NOT NULL
BEGIN
    DROP TABLE #describe;
END

IF OBJECT_ID('tempdb..#col_names_int') IS NOT NULL
BEGIN
    DROP TABLE #col_names_int;
END

IF OBJECT_ID('tempdb..#col_names_obj') IS NOT NULL
BEGIN
    DROP TABLE #col_names_obj;
END

IF OBJECT_ID('tempdb..#nulls') IS NOT NULL
BEGIN
    DROP TABLE #nulls;
END

-- Copy the original dataset into a staging table to make any modifications
select *
into #co2
from CO2_Emissions

--df.head()
select top 5* from #co2 

-- df.dtypes()
SELECT 
    COLUMN_NAME AS 'Column Name',
    DATA_TYPE AS 'Data Type'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CO2_Emissions';

--finding which columns are numerical
create table #col_names_int(id int identity, column_name varchar(50))
insert into #col_names_int
SELECT 
    COLUMN_NAME AS 'Column Name'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CO2_Emissions' AND DATA_TYPE in ('tinyint', 'smallint', 'int', 'float')

-- finding which columns are categorical
create table #col_names_obj(id int identity, column_name varchar(50))
insert into #col_names_obj
SELECT 
    COLUMN_NAME AS 'Column Name'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CO2_Emissions' AND DATA_TYPE not in ('tinyint', 'smallint', 'int', 'float')

--delete unwanted columns
--df.drop(['column_name'], axis=1)
delete from #col_names_obj where column_name='Model' 

-- df.select_dtypes(include='number').columns
select * from #col_names_int

-- df.select_dtypes(include='object').columns
select * from #col_names_obj

-- Count of numerical and categorical columns in the dataset
declare @i int, @total_obj_cols int, @total_int_cols int
declare @col varchar(50), @query nvarchar(max)
set @i=1
set @total_obj_cols = (select count(id) from #col_names_obj)
set @total_int_cols = (select count(id) from #col_names_int)

-- Count of unique values within categorical columns
--df.select_dtypes(include='object').unique()
while @i<=@total_obj_cols
begin
	
	set @col= (select column_name from #col_names_obj where id=@i)	
	set @query = 'select distinct (' + @col+  ') from #co2'
	exec sp_executesql @query 

set @i = @i+1
end

-- value_counts()
create table #all_cols(id int identity, cols varchar(50))

insert into #all_cols
select column_name from #col_names_int
union all
select column_name from #col_names_obj

declare @count int, @total_cols int
create table #value_counts(column_name varchar(50), counts int)

set @i=0
set @total_cols = (select max(id) from #all_cols)
while @i<=@total_cols
begin
	
	set @col= (select cols from #all_cols where id=@i)
	set @col = QUOTENAME(@col)
	set @query = N'
        declare @count INT
        exec sp_executesql 
            N''select @count = count(distinct ' + @col + N') from #co2'',
            N''@count INT OUTPUT'',
            @count OUTPUT

        insert into #value_counts (column_name, counts)
        values (''' + @col + N''', @count)';
	exec sp_executesql @query


set @i = @i+1
end

select * from #value_counts

-- Standard deviation, Mean, Median, Q1, Q3, Highest and Lowest value on each numerical column
-- df.describe()
create table #describe(column_name varchar(50), std float, mean float, q1 float, median float, q3 float, lowest float, highest float)
set @i=0
while @i<=@total_cols
begin
	
	set @col= (select column_name from #col_names_int where id=@i)
	set @col = QUOTENAME(@col)
	set @query = N'
        declare @std float, @mean float, @median float, @min float, @max float, @q1 float, @q3 float
        exec sp_executesql 
            N''select @std = round(STDEV(' + @col + N'),3) from #co2'',
            N''@std float OUTPUT'',
            @std OUTPUT
		exec sp_executesql 
            N''select @mean = round(avg(' + @col + N'),3) from #co2'',
            N''@mean float OUTPUT'',
            @mean OUTPUT
		exec sp_executesql 
            N''select @min = round(min(' + @col + N'),3) from #co2'',
            N''@min float OUTPUT'',
            @min OUTPUT
		exec sp_executesql 
            N''select @max = round(max(' + @col + N'),3) from #co2'',
            N''@max float OUTPUT'',
            @max OUTPUT
		exec sp_executesql 
            N''select @median = PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ' + @col + N') OVER () from #co2'',
            N''@median float OUTPUT'',
            @median OUTPUT
		exec sp_executesql 
            N''select @q1 = PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ' + @col + N') OVER () from #co2'',
            N''@q1 float OUTPUT'',
            @q1 OUTPUT
		exec sp_executesql 
            N''select @q3 = PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ' + @col + N') OVER () from #co2'',
            N''@q3 float OUTPUT'',
            @q3 OUTPUT
        insert into #describe (column_name, std, mean, q1, median, q3, lowest, highest)
        values (''' + @col + N''', @std, @mean, round(@q1,3), round(@median,3), round(@q3,3), @min, @max)';
	exec sp_executesql @query

set @i = @i+1
end

select * from #describe

-- show count of nulls in each column
-- df.isna().sum()
create table #nulls(column_name varchar(50), null_count int)
set @i=0
while @i<=@total_cols
begin

	set @col= (select cols from #all_cols where id=@i)
	set @col = QUOTENAME(@col)
	set @query = N'
        declare @count int
        exec sp_executesql 
            N''select @count = count(*) from #co2 where '+@col+' is null'',
            N''@count float OUTPUT'',
            @count OUTPUT
        insert into #nulls (column_name, null_count)
        values (''' + @col + N''', @count)';
	exec sp_executesql @query

set @i = @i+1
end

select * from #nulls

-- delete the null rows
-- df.dropna()
set @i=0
while @i<=@total_cols
begin

	set @col= (select cols from #all_cols where id=@i)
	set @col = QUOTENAME(@col)
	set @query = 'Delete from #co2 where '+@col+ ' is null'
	exec sp_executesql @query

set @i = @i+1
end


-- Outlier removal code
declare @lb float, @ub float
set @i=1
while @i <= (select max(id) from #col_names_int)
begin
    set @col = (select column_name from #col_names_int where id = @i)

    -- Calculate lower and upper bounds
    SET @lb = (SELECT round(lowest - (1.5 * (q3 - q1)), 3) FROM #describe WHERE column_name = @col);
    SET @ub = (SELECT round(highest + (1.5 * (q3 - q1)), 3) FROM #describe WHERE column_name = @col);

	if @col in (select column_name from #col_names_int)
	--begin
	--	update #co2
	--	set @col=NULL
	--	where @col<@lb or @col>@ub 
	--end
	set @i=@i+1
end

