--Showing all the data we have
SELECT location FROM [COVID19 CASES] ;
SELECT* FROM [COVID19 VACCINATIONS];
SELECT * FROM [COVID19 PSD];

--Showing the likelihood of Dying from Covid In Ghana (Total Cases vs Total Deaths)
SELECT location, date, total_cases, total_deaths, (CONVERT(NUMERIC, total_deaths)/CONVERT(NUMERIC, total_cases))*100  AS Death_Percentage
FROM [COVID19 CASES]
WHERE location = 'Ghana' AND total_cases IS NOT NULL
ORDER BY location, date;

--Showing the percentage of Ghanaians infected (Total cases VS Population)
SELECT [COVID19 CASES].location,  [COVID19 CASES].date,  [COVID19 CASES].total_cases, [COVID19 PSD].population, 
	   (CONVERT(NUMERIC, total_cases)/CONVERT(NUMERIC, population))*100 AS [% Population Infected]
FROM [COVID19 CASES]
JOIN [COVID19 PSD]
ON [COVID19 CASES].location = [COVID19 PSD].location
WHERE [COVID19 CASES].location = 'Ghana' AND [COVID19 CASES].total_cases IS NOT NULL
ORDER BY 1, 2;

--Which Countries have the higest infection rate compared to their population
SELECT [COVID19 CASES].location, [COVID19 PSD].population, MAX(CAST([COVID19 CASES].total_cases AS INT)) AS Higest_Recorded_Cases,
	  (MAX(CAST([COVID19 CASES].total_cases AS INT)) / [COVID19 PSD].population)*100 AS [% Population Infected]
FROM [COVID19 CASES]
JOIN [COVID19 PSD]
ON [COVID19 CASES].location = [COVID19 PSD].location
WHERE [COVID19 CASES].location <> [COVID19 CASES].continent --Excluding continents in the location column
GROUP BY [COVID19 CASES].location, [COVID19 PSD].population
ORDER BY 4 DESC;

--Showing countries that were not affected at all by the virus
SELECT location, ISNULL(CONVERT(NVARCHAR(25), MAX(CAST(total_cases AS INT))), 'None Recorded') AS Higest_Recorded_Cases
FROM [COVID19 CASES]
WHERE [COVID19 CASES].location <> [COVID19 CASES].continent /*Excluding continents in the location column*/
GROUP BY [COVID19 CASES].location
HAVING MAX(CAST([COVID19 CASES].total_cases AS INT)) IS NULL;

--Which countries have the higest death count per population
SELECT [COVID19 CASES].location, [COVID19 PSD].population, MAX(CAST([COVID19 CASES].total_deaths AS INT)) AS Higest_Recorded_deaths,
	  (MAX(CAST([COVID19 CASES].total_deaths AS INT)) / [COVID19 PSD].population)*100 AS [% Population Deceased]
FROM [COVID19 CASES]
JOIN [COVID19 PSD]
ON [COVID19 CASES].location = [COVID19 PSD].location
WHERE [COVID19 CASES].location <> [COVID19 CASES].continent --Excluding continents in the location column
GROUP BY [COVID19 CASES].location, [COVID19 PSD].population
ORDER BY 4 DESC;

--Showing all countries with recorded cases yet no deaths
SELECT [COVID19 CASES].location, MAX(CAST([COVID19 CASES].total_cases AS INT)) AS Higest_Recorded_Cases, 
	   ISNULL(CONVERT(NVARCHAR(25), MAX(CAST([COVID19 CASES].total_deaths AS INT))), 'No Death Recorded') AS Higest_Recorded_deaths
FROM [COVID19 CASES]
JOIN [COVID19 PSD]
ON [COVID19 CASES].location = [COVID19 PSD].location
WHERE [COVID19 CASES].location <> [COVID19 CASES].continent --Excluding continents in the location column
GROUP BY [COVID19 CASES].location
HAVING MAX(CAST([COVID19 CASES].total_cases AS INT)) IS NOT NULL AND MAX(CAST([COVID19 CASES].total_deaths AS INT)) IS NULL
ORDER BY 2 DESC;


--Showing accurate figures for the total recorded deaths in all continents
SELECT location, MAX(CAST(total_deaths AS INT)) AS Higest_Recorded_deaths
FROM [COVID19 CASES]
WHERE continent IS NULL--Excluding countries in the continent column
AND location IN (SELECT DISTINCT(continent) FROM [COVID19 CASES] WHERE continent IS NOT NULL)--Ensuring only unique continents show
GROUP BY [COVID19 CASES].location
ORDER BY 2 DESC;


--Looking at total world numbers(Global Numbers)
--Showing Overall cases and deaths
SELECT /*date,*/ SUM(CONVERT(NUMERIC, new_cases)) AS Cases_Recorded, SUM(CONVERT(NUMERIC, new_deaths)) AS Deaths_Recorded,
		SUM(CONVERT(NUMERIC, new_deaths))/SUM(CONVERT(NUMERIC, new_cases)) AS [%OverAll_Deaths]
FROM [COVID19 CASES]
--WHERE new_cases <> 0 
--GROUP BY date
--ORDER BY date


--Looking at dates vaccinations started and total vaccinations per day in various locations
SELECT C_V.continent, C_V.location, C_V.date, CAST(C_V.new_vaccinations AS INT) AS New_Vaccinations
FROM [COVID19 VACCINATIONS] C_V
JOIN [COVID19 PSD] C_P
ON C_V.location = C_P.location AND C_V.date = C_P.date
WHERE C_V.continent IS NOT NULL AND CAST(C_V.new_vaccinations AS INT) IS NOT NULL
ORDER BY 2, 3

--Looking at a rolling count of day by day vaccinations
SELECT C_V.continent, C_V.location, C_V.date, C_P.population, CAST(C_V.new_vaccinations AS INT) AS New_Vaccinations, 
	   SUM(CONVERT(NUMERIC, C_V.new_vaccinations)) OVER (PARTITION BY C_V.location ORDER BY C_V.location, C_V.date) AS ALL_Currently_Vaccinated
FROM [COVID19 VACCINATIONS] C_V
JOIN [COVID19 PSD] C_P
ON C_V.location = C_P.location AND C_V.date = C_P.date
WHERE C_V.continent IS NOT NULL AND C_V.new_vaccinations  IS NOT NULL
ORDER BY 2, 3

--Looking at Total Population VS Vaccination
WITH VperP AS
(
SELECT C_V.continent, C_V.location, C_V.date, C_P.population, CAST(C_V.new_vaccinations AS INT) AS New_Vaccinations, 
	   SUM(CONVERT(NUMERIC, C_V.new_vaccinations)) OVER (PARTITION BY C_V.location ORDER BY C_V.location, C_V.date) AS ALL_Currently_Vaccinated
FROM [COVID19 VACCINATIONS] C_V
JOIN [COVID19 PSD] C_P
ON C_V.location = C_P.location AND C_V.date = C_P.date
WHERE C_V.continent IS NOT NULL AND C_V.new_vaccinations  IS NOT NULL
)
SELECT location, population , (MAX(ALL_Currently_Vaccinated)/population)*100 AS [% Population Vaccinated]
FROM VperP
GROUP BY location, population
ORDER BY 1,2
/*NB : This data would not be accurate with the % population vaccinated figures,
		as data recorded for new vacciations includes multiple boosters taken by same individuals counted each
		as individual vaccinations*/

--The accurate representation of total vaccinations per population would be to use the 'people vccinated' column rather than 'new vaccinations' 
WITH VperP2 AS
(
SELECT C_V.continent, C_V.location, C_V.date, C_P.population, CAST(C_V.people_vaccinated AS INT) AS People_Vaccinated
FROM [COVID19 VACCINATIONS] C_V
JOIN [COVID19 PSD] C_P
ON C_V.location = C_P.location AND C_V.date = C_P.date
WHERE C_V.continent IS NOT NULL
)
SELECT location, population , MAX(People_Vaccinated/population)*100 AS [% Population Vaccinated]
FROM VperP2
GROUP BY location, population
ORDER BY 1,2


--Creating a view for deaths recorded in continents
DROP VIEW DeathsRecordedInContinents;
CREATE VIEW DeathsRecordedInContinents AS
SELECT location, MAX(CAST(total_deaths AS INT)) AS Higest_Recorded_deaths
FROM [COVID19 CASES]
WHERE continent IS NULL--Excluding countries in the continent column
AND location IN (SELECT DISTINCT(continent) FROM [COVID19 CASES] WHERE continent IS NOT NULL)--Ensuring only unique continents show
GROUP BY [COVID19 CASES].location
--ORDER BY 2 DESC;
