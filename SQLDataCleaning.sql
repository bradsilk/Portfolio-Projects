/*

Cleaning Data in MySQL

*/

USE Portfolio3;

SELECT * FROM housing;

/* Update blank cells to NULLS (This was not acheived by the Table Data Import Wizard feature
in MySQL Workbench) */

SET SQL_SAFE_UPDATES = 0;

UPDATE housing
SET UniqueID = NULL 
WHERE UniqueID = '';

UPDATE housing
SET LandUse = NULL 
WHERE LandUse = '';

UPDATE housing
SET PropertyAddress = NULL 
WHERE PropertyAddress = '';

UPDATE housing
SET SaleDate = NULL 
WHERE SaleDate = '';

UPDATE housing
SET SalePrice = NULL 
WHERE SalePrice = '';

UPDATE housing
SET LegalReference = NULL 
WHERE LegalReference = '';

UPDATE housing
SET SoldAsVacant = NULL 
WHERE SoldAsVacant = '';

UPDATE housing
SET OwnerName = NULL 
WHERE OwnerName = '';

UPDATE housing
SET OwnerAddress = NULL 
WHERE OwnerAddress = '';

UPDATE housing
SET Acreage = NULL 
WHERE Acreage = '';

UPDATE housing
SET TaxDistrict = NULL 
WHERE TaxDistrict = '';


UPDATE housing
SET LandValue = NULL 
WHERE LandValue = '';


UPDATE housing
SET BuildingValue = NULL 
WHERE BuildingValue = '';

UPDATE housing
SET TotalValue = NULL 
WHERE TotalValue = '';

UPDATE housing
SET YearBuilt = NULL 
WHERE YearBuilt = '';

UPDATE housing
SET Bedrooms = NULL 
WHERE Bedrooms = '';

UPDATE housing
SET FullBath = NULL 
WHERE FullBath = '';

UPDATE housing
SET HalfBath = NULL 
WHERE HalfBath = '';


-- 1.) Standardize Date Format:

ALTER TABLE housing ADD (new_col DATE);

UPDATE housing SET new_col = STR_TO_DATE(SaleDate,'%M %d, %Y');

ALTER TABLE housing DROP COLUMN SaleDate;

ALTER TABLE housing RENAME COLUMN new_col TO SaleDate;

ALTER TABLE `Portfolio3`.`housing` 
CHANGE COLUMN `SaleDate` `SaleDate` DATE NULL DEFAULT NULL AFTER `PropertyAddress`; -- (done in Alter Table menu in Workbench)


-- 2.) Populate Property Address Data:

SELECT 
	a.ParcelID, 
    a.PropertyAddress,
    b.ParcelID, 
	b.PropertyAddress,
    IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID  -- Joining table to itself to show NULL addresses beside populated addresses where ParcelID is the same
WHERE a.PropertyAddress IS NULL;

UPDATE housing a
JOIN housing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL; 
	

-- 3a.) Breaking out PropertyAddress into Individual Columns (Street, City):

SELECT ProperyAddress FROM housing;

SELECT
	SUBSTRING(PropertyAddress, 1 , LOCATE(',', PropertyAddress) -1) As Street,
	SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1) AS City
FROM housing;


ALTER TABLE housing ADD (PropertySplitStreet VARCHAR(255));
UPDATE housing SET PropertySplitStreet =
	SUBSTRING(PropertyAddress, 1 , LOCATE(',', PropertyAddress) -1);

ALTER TABLE housing ADD (PropertySplitCity NVARCHAR(255));
UPDATE housing SET PropertySplitCity =
	SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1);

-- 3b.) Breaking out OwnerAddress and OwnerAddress into Individual Columns (Street, City, State):

SELECT
	SUBSTRING(OwnerAddress, 1 , LOCATE(',', OwnerAddress) -1) As OwnerStreet,
	SUBSTRING_INDEX(substring_index(OwnerAddress, ',', +2), ',', -1) AS OwnerCity,
	SUBSTRING_INDEX(OwnerAddress, ",", -1) AS OwnerState
FROM housing;


ALTER TABLE housing ADD (OwnerSplitStreet VARCHAR(255));
UPDATE housing SET OwnerSplitStreet =
	SUBSTRING(OwnerAddress, 1 , LOCATE(',', OwnerAddress) -1);

ALTER TABLE housing ADD (OwnerSplitCity VARCHAR(255));
UPDATE housing SET OwnerSplitCity =
	SUBSTRING_INDEX(substring_index(OwnerAddress, ',', +2), ',', -1);
    
ALTER TABLE housing ADD (OwnerSplitState VARCHAR(255));
UPDATE housing SET OwnerSplitState =
	SUBSTRING_INDEX(OwnerAddress, ",", -1);
    

-- 4.) Change Y and N to Yes and No in SoldAsVacant:
    

UPDATE housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N'THEN 'No'
    ELSE SoldAsVacant 
    END;
    

-- 5.) Remove Duplicates:


DELETE t1 FROM housing t1
INNER JOIN housing t2 
WHERE 
    t1.ParcelID < t2.ParcelID AND 
	t1.PropertyAddress = t2.PropertyAddress AND
	t1.SalePrice = t2.SalePrice AND
	t1.SaleDate = t2.SaleDate AND
    t1.LegalReference = t2.LegalReference;
    
    
-- Delete Unused Columns:

ALTER TABLE housing
DROP COLUMN OwnerAddress;

ALTER TABLE housing
DROP COLUMN TaxDistrict;

ALTER TABLE housing
DROP COLUMN PropertyAddress;




