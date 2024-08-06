/*
Cleaning Data in SQL Queries

We need to be aware of SQL_SAFE_UPDATES when modifying tables to ensure we do not accidentally make unintended changes
*/

-- Display all records from the NashvilleHousing table
SELECT * FROM data_analysis.NashvilleHousing;


-- STANDARDIZE THE FORMAT OF SALEDATE BY CONVERTING IT TO A DATE TYPE

-- Display the converted SaleDate and the result of the conversion
SELECT SaleDateConverted, STR_TO_DATE(SaleDate, '%M %d, %Y')
FROM data_analysis.NashvilleHousing;

-- Update SaleDate with the standardized date format
UPDATE NashvilleHousing
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

-- Add a new column for the standardized SaleDate
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

-- Disable safe updates to allow updates on tables without a key
SET SQL_SAFE_UPDATES = 0;

-- Populate the new SaleDateConverted column with the standardized date format
UPDATE NashvilleHousing
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%M %d, %Y');

-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;


-- POPULATE PROPERTY ADDRESS DATA

-- Display all records ordered by ParcelID to review the data
SELECT *
FROM data_analysis.NashvilleHousing
ORDER BY ParcelID;

-- Identify records where PropertyAddress is NULL and attempt to fill it from other records with the same ParcelID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM data_analysis.NashvilleHousing a
JOIN data_analysis.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Disable safe updates to allow updates on tables without a key
SET SQL_SAFE_UPDATES = 0;

-- Update PropertyAddress with values from other records with the same ParcelID if the address is NULL
UPDATE data_analysis.NashvilleHousing a
JOIN data_analysis.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;


-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

-- Display PropertyAddress to review its format
SELECT PropertyAddress
FROM data_analysis.NashvilleHousing;

-- Extract Address and City from PropertyAddress
SELECT
SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address,
SUBSTRING_INDEX(PropertyAddress, ',', -1) AS City
FROM data_analysis.NashvilleHousing;

-- Disable safe updates to allow updates on tables without a key
SET SQL_SAFE_UPDATES = 0;

-- Add a new column for the extracted address
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress VARCHAR(255);

-- Update the new column with the extracted address part
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

-- Add a new column for the extracted city
ALTER TABLE NashvilleHousing
ADD PropertySplitCity VARCHAR(255);

-- Update the new column with the extracted city part
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1);

-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;

-- Display all records to verify changes
SELECT *
FROM data_analysis.NashvilleHousing;

-- Display OwnerAddress to review its format
SELECT OwnerAddress
FROM data_analysis.NashvilleHousing;

-- Extract Address, City, and State from OwnerAddress
SELECT
SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City,
SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State
FROM data_analysis.NashvilleHousing;

-- Disable safe updates to allow updates on tables without a key
SET SQL_SAFE_UPDATES = 0;

-- Add new columns for the extracted address, city, and state
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress VARCHAR(255);

-- Update the new column with the extracted address part
UPDATE NashvilleHousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

-- Add a new column for the extracted city
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity VARCHAR(255);

-- Update the new column with the extracted city part
UPDATE NashvilleHousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

-- Add a new column for the extracted state
ALTER TABLE NashvilleHousing
ADD OwnerSplitState VARCHAR(255);

-- Update the new column with the extracted state part
UPDATE NashvilleHousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;


-- CHANGE 'Y' AND 'N' TO 'YES' AND 'NO' IN THE "SOLD AS VACANT" FIELD

-- Display distinct values and their counts for SoldAsVacant to review the data
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM data_analysis.NashvilleHousing
GROUP BY 1
ORDER BY 2;

-- Show how the "SoldAsVacant" field will be updated
SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' 
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM data_analysis.NashvilleHousing;

-- Disable safe updates to allow updates on tables without a key
SET SQL_SAFE_UPDATES = 0;

-- Update the "SoldAsVacant" field to use 'Yes' and 'No' instead of 'Y' and 'N'
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' 
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END;

-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;


-- REMOVE DUPLICATES (NOTE: IT IS NOT A GOOD PRACTICE TO DELETE DUPLICATES DIRECTLY FROM RAW DATA)

-- Disable safe updates to allow deletion of records without a key
SET SQL_SAFE_UPDATES = 0;

-- Delete duplicate records based on unique IDs while keeping one instance of each
DELETE FROM data_analysis.NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID,
            ROW_NUMBER() OVER(
                PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
                ORDER BY UniqueID
            ) AS RowNum
        FROM data_analysis.NashvilleHousing
    ) AS RowNumCTE
    WHERE RowNum > 1);

-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;

-- VERIFY IF THERE ARE NO MORE DUPLICATED VALUES (RE-CHECK FOR ANY REMAINING DUPLICATES)

DELETE FROM data_analysis.NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID,
            ROW_NUMBER() OVER(
                PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
                ORDER BY UniqueID
            ) AS RowNum
        FROM data_analysis.NashvilleHousing
    ) AS RowNumCTE
    WHERE RowNum > 1);


-- DELETE UNUSED COLUMNS (NOTE: THIS OPERATION SHOULD BE DONE CAUTIOUSLY TO AVOID AFFECTING RAW DATA)

-- Remove columns that are no longer needed from the table
ALTER TABLE data_analysis.NashvilleHousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;

-- Remove SaleDate column from the table
ALTER TABLE data_analysis.NashvilleHousing
DROP COLUMN SaleDate;
