# **Data cleaning in SQL**
This project consists of queries written in SQL to clean a housing dataset. Data cleaning consists of fixing or removing incorrect, corrupted, incorrectly formatted, duplicate, or incomplete data within a dataset. This process is important because it allows us to remove data that might negatively impact our data-based decision-making. Also, it can be a necessary step when preparing the data for machine learning or deep learning algorithms.

The steps taken in this project are explained below.

## The dataset
As previously mentioned, the dataset consists of housing data from Nashville, Tennessee. It contains information on house sales, including details such as the sale price, the property address, the name of the owners, and the date the house was sold.
By running the query below, we can access all the information in the dataset, presented in tabular form.
```
SELECT *
FROM PortfolioProject..NashvilleHousing
```

![image](https://github.com/Daniel-De-la-Cruz-Vill/Data-Cleaning-in-SQL-with-a-Housing-Dataset/assets/157164355/8c8a4c2b-9482-4a17-b3ed-f0f31870521f)

The data contains some null values (some of which we can't fill, and others which we can), as well as some problematic columns. We will start by working on the sale date column-

## Sale date
The sale date column is in the wrong format because it contains the exact hour, minute, and even second in which the sale happened. The reality is that we don't have this information (nor do we need it), so those values are 00:00:00 for all rows. We can fix this with the code below:
```
ALTER TABLE PortfolioProject..NashvilleHousing
ALTER COLUMN SaleDate DATE
```
The following image shows the difference between the old and new formats.

![image](https://github.com/Daniel-De-la-Cruz-Vill/Data-Cleaning-in-SQL-with-a-Housing-Dataset/assets/157164355/6ecfc2d5-1f9a-45e4-aebe-794e88b7c88f)

## Property address
Some of the values in the property address column are null, which means we don't have that information. However, by observing the dataset, we can see that there is a relationship between the property address and ParcelID: the addresses are the same for houses that share the same ParcelID. The following image shows the rows that have null property addresses but share the same ParcelID with another row that does have a property address, giving us a value to fill those null rows.

![image](https://github.com/Daniel-De-la-Cruz-Vill/Data-Cleaning-in-SQL-with-a-Housing-Dataset/assets/157164355/6ae07586-8903-4b7a-a555-7f9ffb2d3465)

The code below fills the null values with the information found in the image above.
```
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND  a.[UniqueID ] <> b.[UniqueID ]
WHERE
a.PropertyAddress is null
```

Despite now having no null values, the property address column has another problem because it contains two pieces of information that should be separated, which are the actual address and the city. The image below shows the original property address column and the two columns we would obtain by separating those two pieces of information.

![image](https://github.com/Daniel-De-la-Cruz-Vill/Data-Cleaning-in-SQL-with-a-Housing-Dataset/assets/157164355/e6b924cb-f51b-4229-81e4-fb9609364b2b)

To make this separation, we would need to add those two columns to the database and then update them with the corresponding information. That can be done with the code below.
```
--Creating and updating the address column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD Address nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1)-1)

--Creating and updating the city column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD City nvarchar(255) 
```
## Owner address
The owner address column has a similar problem to the last one discussed for the property address column. It contains addresses, cities, and states that should be in their own columns.

![image](https://github.com/Daniel-De-la-Cruz-Vill/Data-Cleaning-in-SQL-with-a-Housing-Dataset/assets/157164355/f10867ae-1dc4-4bb6-840c-a2d1ca19e3c4)

We can do this with the code below.
```
--Altering the table
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerState nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
```
## Sold as vacant
This column contains some incorrectly input information. Some values are 'Y' or 'N' when they should be 'Yes' or 'No,' respectively. The image below shows the number of cases for each type of value in this column.

![image](https://github.com/Daniel-De-la-Cruz-Vill/Data-Cleaning-in-SQL-with-a-Housing-Dataset/assets/157164355/0c97eb97-3d60-48d2-b924-e0e46742b4a5)

This can be solved easily by using a CASE statement.
```
UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'  WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
```
## Duplicated rows
Some rows in the dataset are duplicated, which is problematic because it repeats information already contained in other rows, making it so that the dataset expands unnecessarily. To solve this, we will use a CTE that counts the number of rows that contain repeated parcel IDs, sale dates, and legal references. 
```
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE
From RowNumCTE
Where row_num > 1
```
The code above deletes 104 duplicated rows.

## Unused columns
Finally, we will remove the old columns that contain information that was split into two or more columns. We will also remove the OwnerState column because it only contains one possible value. This is done with the following code:
```
--These original columns are now redundant and must be deleted
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress
--We will also drop the OwnerState because it only contains one possible value: TN
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerState
```
