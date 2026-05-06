---Task 1:Create table and import data from file
CREATE TABLE sales_dataset_rfm_prj
(
ORDERNUMBER	VARCHAR,
QUANTITYORDERED	VARCHAR,
PRICEEACH VARCHAR,	
ORDERLINENUMBER VARCHAR,	
SALES VARCHAR,	
ORDERDATE VARCHAR,	
STATUS VARCHAR,	
PRODUCTLINE VARCHAR,	
MSRP VARCHAR,	
PRODUCTCODE VARCHAR,	
CUSTOMERNAME VARCHAR,	
PHONE VARCHAR,	
ADDRESSLINE1 VARCHAR,	
ADDRESSLINE2 VARCHAR,	
CITY VARCHAR,	
STATE VARCHAR,	
POSTALCODE VARCHAR,	
COUNTRY VARCHAR,	
TERRITORY VARCHAR,	
CONTACTFULLNAME VARCHAR,	
DEALSIZE VARCHAR
);

---Task 2: Check and correct data type
---1. Change data type column odernumber from varchar to interger
Alter table public.sales_dataset_rfm_prj
Alter column ordernumber type int USING ordernumber::integer;
---2. Change data type column quantityordered from varchar to interger
Alter table public.sales_dataset_rfm_prj
Alter column quantityordered type int USING quantityordered::integer;
---3. Change data type column priceeach from varchar to interger
Alter table public.sales_dataset_rfm_prj
Alter column priceeach type numeric USING priceeach::numeric;
---4. Change data type column orderlinenumber from varchar to interger
Alter table public.sales_dataset_rfm_prj
Alter column orderlinenumber type int USING orderlinenumber::integer;
---5. Change data type column sales from varchar to interger
Alter table public.sales_dataset_rfm_prj
Alter column sales type numeric USING sales::numeric;
---6. Change data type column orderdate from varchar to interger
Alter table public.sales_dataset_rfm_prj
Alter column orderdate type TIMESTAMP USING orderdate::TIMESTAMP;
---7. Change data type column msrp from varchar to interger
Alter table public.sales_dataset_rfm_prj
Alter column msrp type int USING msrp::integer;


---Task 3: Check NULL/BLANK (‘’) : ORDERNUMBER, QUANTITYORDERED, PRICEEACH, ORDERLINENUMBER, SALES, ORDERDATE. 
SELECT *
FROM public.sales_dataset_rfm_prj
WHERE ordernumber IS NULL OR 
quantityordered IS NULL OR 
priceeach IS NULL OR 
orderlinenumber IS NULL OR 
sales IS NULL OR 
orderdate IS NULL 

---Task 4: Add new column CONTACTLASTNAME, CONTACTFIRSTNAME from CONTACTFULLNAME
---1. Add new column
Alter table public.sales_dataset_rfm_prj
ADD COLUMN CONTACTLASTNAME VARCHAR,
ADD COLUMN CONTACTFIRSTNAME VARCHAR;
---2. Find  and update CONTACTLASTNAME, CONTACTFIRSTNAME from CONTACTFULLNAME
Update public.sales_dataset_rfm_prj
SET
CONTACTLASTNAME = SUBSTRING (contactfullname FROM 1 FOR POSITION('-' IN contactfullname)-1  ),
CONTACTFIRSTNAME = SUBSTRING (contactfullname FROM POSITION('-' IN contactfullname) +1 )


---Update standardize the format: first letter uppercase, rest lowercase
Update public.sales_dataset_rfm_prj
Set 
contactlastname = initcap(lower(contactlastname)),
contactfirstname = initcap(lower(contactfirstname))

-
---Task 5: Add new columns QTR_ID, MONTH_ID, YEAR_ID from ORDERDATE 
---1. Add new columns QTR_ID, MONTH_ID, YEAR_ID
Alter table public.sales_dataset_rfm_prj
Add column QTR_ID INT,
Add column MONTH_ID INT,
Add column YEAR_ID INT;
---2. Find and update QTR_ID, MONTH_ID, YEAR_ID
UPDATE public.sales_dataset_rfm_prj
SET
qtr_id = EXTRACT (QUARTER FROM orderdate),
month_id = EXTRACT (MONTH FROM orderdate) ,
year_id = EXTRACT (YEAR FROM orderdate); 

---Task 6: Find outlier for QUANTITYORDERED
---Box plot method:Find Q1, Q3, IQR
WITH CTE_MIN_MAX AS
(
SELECT 
Q1,Q3,avg_qty,
(Q3-Q1) AS IQR,
Q1-1.5*(Q3-Q1) AS MIN_VALUE,
Q3+1.5*(Q3-Q1) AS MAX_VALUE
FROM
(SELECT 
AVG(quantityordered) AS avg_qty,
percentile_cont (0.25) within group (order by quantityordered) as Q1,
percentile_cont (0.75) within group (order by quantityordered) as Q3
from public.sales_dataset_rfm_prj))
---Find out min = 3, max= 67
SELECT * FROM public.sales_dataset_rfm_prj
WHERE quantityordered <(SELECT MIN_VALUE FROM CTE_MIN_MAX )
OR quantityordered >(SELECT MAX_VALUE FROM CTE_MIN_MAX )

--- Add new column clean_quantityordered
Alter table public.sales_dataset_rfm_prj
Add column clean_quantityordered int;

---Update outlier clean_quantityordered = avg of quantityordered

WITH CTE_MIN_MAX AS
(
SELECT 
Q1,Q3,avg_qty,
(Q3-Q1) AS IQR,
Q1-1.5*(Q3-Q1) AS MIN_VALUE,
Q3+1.5*(Q3-Q1) AS MAX_VALUE
FROM
(SELECT 
AVG(quantityordered) AS avg_qty,
percentile_cont (0.25) within group (order by quantityordered) as Q1,
percentile_cont (0.75) within group (order by quantityordered) as Q3
from public.sales_dataset_rfm_prj))

Update public.sales_dataset_rfm_prj
Set clean_quantityordered =
CASE
WHEN quantityordered < (SELECT min_value FROM CTE_MIN_MAX)
OR quantityordered > (SELECT max_value FROM CTE_MIN_MAX)
THEN ROUND((SELECT avg_qty FROM CTE_MIN_MAX))::INT
ELSE quantityordered
END
---CHECK clean_quantityordered
SELECT ordernumber,
clean_quantityordered,quantityordered
FROM public.sales_dataset_rfm_prj
WHERE (quantityordered-clean_quantityordered) <>0