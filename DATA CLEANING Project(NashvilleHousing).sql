--CLEANING DATA :

--Renaming the imported file
EXEC SP_RENAME [Nashville Housing], [Housing Details]

--showing the data being used
SELECT* FROM [Housing Details]

----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Standardizing date format
/*UPDATE [Nashville Housing]
SET SaleDate = CONVERT(DATE, SaleDate, 3)*/
ALTER TABLE [Housing Details]
ADD ConvertedSaleDate DATE;
UPDATE [Housing Details]
SET ConvertedSaleDate = CONVERT(DATE, SaleDate, 3);

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Populating Property Address data where NULLS
UPDATE Y
SET PropertyAddress = ISNULL(X.PropertyAddress, Y.PropertyAddress)
					  FROM [Housing Details] X
					  JOIN [Housing Details] Y
					  ON X.[UniqueID ] <> Y.[UniqueID ] AND X.ParcelID = Y.ParcelID
WHERE X.PropertyAddress IS NULL


--Splitting Property Address into individual columns
ALTER TABLE [Housing Details]
ADD ADDRESS VARCHAR(100), [CITY/STATE] VARCHAR(50)

UPDATE [Housing Details]
SET ADDRESS = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

UPDATE [Housing Details]
SET [CITY/STATE] = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));

--Renaming the new Property Adress columns
EXEC SP_RENAME  '[Housing Details].ADDRESS', 'PropertyLocation ADDRESS'
EXEC SP_RENAME  '[Housing Details].[CITY/STATE]', 'PropertyLocation  ne CITY'

-------------------------------------------------------------------------------------------------------------------------------------------------------------

--Splitting Owner Address into individual columns
ALTER TABLE [Housing Details]
ADD [OwnerLocation ADDRESS] VARCHAR(100), [OwnerLocation CITY] VARCHAR(50), [OwnerLocation STATE] VARCHAR(20)

UPDATE [Housing Details]
SET [OwnerLocation ADDRESS] =  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE [Housing Details]
SET [OwnerLocation CITY] =  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE [Housing Details]
SET [OwnerLocation STATE] =  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--Updating SoldAsVacant column such that it is Yes where it says Y and No where it says N
UPDATE [Housing Details]
SET SoldAsVacant = CASE
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--Removing Duplicates
WITH D_check AS (
SELECT  *, ROW_NUMBER() OVER 
		 (PARTITION BY ParcelID, SaleDate, LegalReference, OwnerName
		  ORDER BY UniqueID) ROWNUM
FROM [Housing Details]
ORDER BY ROWNUM DESC
)

DELETE
FROM D_check
WHERE ROWNUM  = 2

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Deleting redundant columns
ALTER TABLE [Housing Details]
DROP COLUMN SaleDate

ALTER TABLE [Housing Details]
DROP COLUMN PropertyAddress

ALTER TABLE [Housing Details]
DROP COLUMN OwnerAddress
