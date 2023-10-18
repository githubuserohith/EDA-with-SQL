
# SQL Based EDA (Exploratory data analysis)
Uncovering Insights through Data Exploration using procedures in SQL

#### Check and Drop Temporary Tables

* The code begins by checking if several temporary tables exist using the **IF OBJECT_ID** statement.

* If any of these temporary tables (#co2, #all_cols, #value_counts, #describe, #col_names_int, #col_names_obj, #nulls) exist, it drops them using the DROP TABLE statements. 

* This ensures a clean workspace before processing.

#### Copy Original Dataset into a Staging Table:

* The original dataset (CO2_Emissions) is copied into a staging table named #co2. This is done to make any modifications to the data without affecting the original dataset.

#### Display a Sample of the Data
* This is equivalent to df.head() in python pandas

* A SELECT TOP 5 * statement is used to retrieve the first 5 rows from the #co2 table, essentially displaying a sample of the data.

![alt text](https://imgur.com/LEJP5Y9.png)

#### Get Column Data Types
* This information is similar to the dtypes() function in pandas for displaying data types in a DataFrame.

* The query retrieves the column names and data types from the INFORMATION_SCHEMA.COLUMNS for the CO2_Emissions table.

![alt text](https://imgur.com/iMa20zP.png)

#### Identify Numerical Columns:

A temporary table #col_names_int is created to store the names of columns with numerical data types. These columns include integer, float, smallint, tinyint, int types.

![alt text](https://imgur.com/iMa20zP.png) 


#### Identify Categorical Columns:

* Another temporary table #col_names_obj is created to store the names of columns with non-numerical (categorical) data types. These columns are selected from the CO2_Emissions table.

![alt text](https://imgur.com/HYYOvu0.png)

#### Remove Unwanted Columns 
* This is similar to pandas function df.drop(['column_to_drop'], axis=1)

* The code deletes the row in #col_names_obj. This effectively removes the 'column_to_drop'  from the list of categorical columns.

#### Count of Unique Values in Categorical Columns
* The code uses dynamic SQL within a loop to count the distinct values in each categorical column and displays the unique values for each column.
* This is equivalent to (df.select_dtypes(include='object').unique()

![alt text](https://imgur.com/IRAny4u.png)

#### Calculate Value Counts for all Columns:

* A temporary table #all_cols is created to store the names of all columns (both numerical and categorical).

* The code then calculates and stores the count of distinct values in each column and stores them in the #value_counts table.

![alt text](https://imgur.com/tdc0w8R.png)

#### Calculate Descriptive Statistics 

* This is equivalent to df.describe() in pandas

* The code calculates descriptive statistics (standard deviation, mean, median, quartiles, minimum, maximum) for each numerical column and stores the results in the #describe table.

![alt text](https://imgur.com/F7KFa6Q.png)

#### Count of Null Values in Each Column 

* This is equivalent to df.isna().sum() in pandas

* A temporary table #nulls is created to store the count of null values in each column. The code counts the null values for each column and stores the results.

![alt text](https://imgur.com/wSa7MPF.png)

#### Delete Rows with Null Values 
* This is equivalent to df.dropna() in pandas

* The code uses dynamic SQL within a loop to delete rows in the #co2 table where a column has a null value.

#### Outlier Removal (Not Functional):

* There is an attempt to remove outliers using a dynamic sql. However, the code for outlier removal is commented out and currently not functional. It's intended to remove outliers from each numerical column in the #co2 table. This part is being worked upon currently and will be updated once completed.



