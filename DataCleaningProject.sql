/*

Data Cleaning Project 

*/

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing


-------------------------------------------------

--Standardize date Format

SELECT SaleDate
FROM PortfolioProject2.dbo.NashvilleHousing

	--create a new column
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

	--add converted date into newly added column
UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

SELECT SaleDate, SaleDateConverted
FROM PortfolioProject2.dbo.NashvilleHousing

---------------------------------------------------

--Populate Property Address Data

	-- nulls exists in PropertyAddress

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

	--some ParcelIDs are repeated, hence address can be copied if 
	--ParcelID is same

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing
ORDER BY ParcelID

	--Shows the number of repeatedParcelIDs

SELECT ParcelID, COUNT(*) AS RepeatedParcelID
FROM PortfolioProject2.dbo.NashvilleHousing
GROUP BY ParcelID
ORDER BY RepeatedParcelID DESC

	--for example
SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing
WHERE ParcelID = '034 07 0B 015.00'
--unique ids are 45329, 46919, 50623, 25069

	--Copying addresses from address entries which have same ParcelID.
	--Each property has a fixed parcel ID but different unique IDs
	--(after program is run, wont show results, since null addresses were copied already)
	
SELECT a.ParcelID, b.ParcelID , a.PropertyAddress, b.PropertyAddress, a.UniqueID as UniqueID_a, b.UniqueID as UniqueID_b, ISNULL(a.PropertyAddress,b.PropertyAddress) AS UpdatedPropertyAddress
FROM PortfolioProject2.dbo.NashvilleHousing a
JOIN PortfolioProject2.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID		-- ParcelID is unique to a property
	AND a.[UniqueID ]<>b.[UniqueID ] --UniqueID is unique to a property owner
WHERE  a.PropertyAddress IS NULL 

	--Creating new column to store copied Addresses

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject2.dbo.NashvilleHousing a
JOIN PortfolioProject2.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID		-- ParcelID is unique to a property
	AND a.[UniqueID ]<>b.[UniqueID ] --UniqueID is unique to a property owner
WHERE  a.PropertyAddress IS NULL 

-----------------------------------------------------------------------------------

--	Breaking address into indivisual columns (Address, City, State)


SELECT PropertyAddress
FROM PortfolioProject2.dbo.NashvilleHousing

SELECT
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address, -- SUBSTRING(column,start,end)
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City
FROM PortfolioProject2.dbo.NashvilleHousing


--Creating and updating new address column

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
Add PropertyAddressSplit Nvarchar(255);

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET PropertyAddressSplit = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)



--Creating and updating new city column

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
Add PropertyCitySplit Nvarchar(255);

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET PropertyCitySplit = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

SELECT PropertyAddress, PropertyAddressSplit, PropertyCitySplit
FROM PortfolioProject2.dbo.NashvilleHousing

-----------------------------------------------------------------------------------

-- Splitting Owner address (different method)

SELECT OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS OwnerAdressSplit,
	PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS OwnerCitySplit,
	PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS OwnerStateSplit
	--replace ',' with '.' to use parsename 
	--example: SELECT PARSENAME('Homer.dbo.Music.Artists', 4) AS Result; result=Homer
FROM PortfolioProject2.dbo.NashvilleHousing

--Creating and updating new OwnerAddress column

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
Add OwnerAdressSplit Nvarchar(255);

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET OwnerAdressSplit = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

--Creating and updating new OwnerCity column

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
Add OwnerCitySplit Nvarchar(255);

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET OwnerCitySplit = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

--Creating and updating new OwnerState column

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
Add OwnerStateSplit Nvarchar(255);

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET OwnerStateSplit = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT OwnerAddress, OwnerAdressSplit, OwnerCitySplit, OwnerStateSplit
FROM PortfolioProject2.dbo.NashvilleHousing


-------------------------------------------------------------------------------------------


--Changing 'Y' TO 'Yes' and 'N' TO 'No'

SELECT SoldAsVacant
FROM PortfolioProject2.dbo.NashvilleHousing


SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant)      ----shows all distinct values (N,No,Y,Yes), +count                 
FROM PortfolioProject2.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Changing y,n to yes, no using CASE Statement

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProject2.dbo.NashvilleHousing

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END

------------------------------------------------------------------------------------------

-- Deleting Duplicates
		/*

			Syntax :  ROW_NUMBER ( )   
			--			OVER ( [ PARTITION BY value_expression , ... [ n ] ] order_by_clause ) 
			--The ROW_NUMBER() is a window function that assigns a sequential integer to each row within the partition of a result set.

		*/

--Create CTE/temp table to sort by new column
WITH RowNumCTE AS(
SELECT * ,
		ROW_NUMBER()
			OVER(
					PARTITION BY ParcelID,
								PropertyAddress,
								SaleDate,
								SalePrice,
								LegalReference
					ORDER BY ParcelID
				) AS row_num
				
FROM PortfolioProject2.dbo.NashvilleHousing

				)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY [UniqueID ]


-- to delete duplicate rows (row_num >1)

WITH RowNumCTE AS(
SELECT * ,
		ROW_NUMBER()
			OVER(
					PARTITION BY ParcelID,
								PropertyAddress,
								SaleDate,
								SalePrice,
								LegalReference
					ORDER BY ParcelID
				) AS row_num
				
FROM PortfolioProject2.dbo.NashvilleHousing

				)
DELETE 
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY [UniqueID ]

--------------------------------------------------------------------

-- Delete Unused Columns

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, SaleDate, TaxDistrict