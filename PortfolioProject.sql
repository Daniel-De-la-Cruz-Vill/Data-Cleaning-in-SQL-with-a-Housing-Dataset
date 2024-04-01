----DATA CLEANING PROJECT


------------------------------------------------------------------------------------------------------------------------------------------------------
---Observing the data 
SELECT *
FROM PortfolioProject..NashvilleHousing


------------------------------------------------------------------------------------------------------------------------------------------------------
---Standardizing the date format
SELECT SaleDate, CONVERT(DATE,SaleDate)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ALTER COLUMN SaleDate DATE

SELECT SaleDate
FROM PortfolioProject..NashvilleHousing


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Working with the Property Address data
-- There are 29 null values in this column
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is null

-- There is a relationship between ParcelID and PropertyAddress
-- The addresses are the same when they share ParcelIDs
SELECT ParcelID, PropertyAddress
FROM PortfolioProject..NashvilleHousing
ORDER BY 1

--Finding the rows with the same ParcelIDs but with different UniqueIDs (different prpoerty)
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND  a.[UniqueID ] <> b.[UniqueID ]
WHERE
a.PropertyAddress is null

--Updating the table to fill the missing values
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND  a.[UniqueID ] <> b.[UniqueID ]
WHERE
a.PropertyAddress is null

--Confirming that there are no missing values
Select PropertyAddress
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is null


------------------------------------------------------------------------------------------------------------------------------------------------------
---Splitting the address column
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

--We will separate the address from the name of the city
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress, 1)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

--Creating and updating the address column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD Address nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1)-1)

--Creating and updating the city column
ALTER TABLE PortfolioProject..NashvilleHousing
ADD City nvarchar(255) 

UPDATE PortfolioProject..NashvilleHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress, 1)+1, LEN(PropertyAddress))

--Visualizing the new columns
SELECT Address, City
FROM PortfolioProject..NashvilleHousing


------------------------------------------------------------------------------------------------------------------------------------------------------
---Splitting the OwnerAddress column
-- This column contains addresses, cities, and states separated by commas
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

--This time we will use the PARSENAME function
--However, because PARSENAME only looks for periods, we must replace the commas with periods
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) OwnerSplitAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) OwnerState
FROM PortfolioProject..NashvilleHousing

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

--Visualizing the Changes
SELECT OwnerSplitAddress, OwnerCity, OwnerState
FROM PortfolioProject..NashvilleHousing


------------------------------------------------------------------------------------------------------------------------------------------------------
--- Fixing the SoldAsVacant column values
-- Some of the values were incorrectly input 
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) Number_of_cases
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC

--Using a CASE statement for this
SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'  WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM PortfolioProject..NashvilleHousing

--Updating the table
UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'  WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END


------------------------------------------------------------------------------------------------------------------------------------------------------
--Removing duplicates
--We will create a cte that contains the rows where certain values are repeated in other rows.
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
Where row_num > 1 --Repeated rows

--there were 56477 rows, and now there are 56373
SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY UniqueID


------------------------------------------------------------------------------------------------------------------------------------------------------
--Removing the unused columns
--We created various columns that serve the same function as some original columns
--These original columns are now redundant and must be deleted
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress
--We will also drop the OwnerState because it only contains one possible value: TN
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerState

SELECT *
FROM PortfolioProject..NashvilleHousing