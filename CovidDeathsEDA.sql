/*
    Project Name: Covid 19 Data Exploration

    Description:
    This project involves exploring and analyzing COVID-19 data to gain insights into various aspects of the pandemic. The analysis includes examining total cases versus total deaths, infection rates, and vaccination progress across different regions. The project utilizes a range of SQL techniques including joins, Common Table Expressions (CTEs), temporary tables, window functions, aggregate functions, and view creation.

    Skills Used:
    - Joins: Combining data from multiple tables to perform comprehensive analysis.
    - CTEs: Using Common Table Expressions for modular and readable queries.
    - Temp Tables: Creating temporary tables for intermediate calculations and analysis.
    - Window Functions: Calculating rolling sums and percentages within partitions of data.
    - Aggregate Functions: Summarizing data to derive insights such as total cases and death percentages.
    - Creating Views: Storing complex queries for future use and visualization.
    - Converting Data Types: Ensuring data types are appropriate for calculations and comparisons.

    Queries Included:
    1. Selecting initial data for exploration.
    2. Comparing total cases and deaths to understand the likelihood of death.
    3. Analyzing infection rates relative to population.
    4. Identifying countries with the highest infection rates and death counts.
    5. Breaking down death counts by continent.
    6. Aggregating global numbers for new cases and deaths.
    7. Comparing total population with vaccination data.
    8. Using CTEs and temporary tables to calculate and visualize vaccination percentages.
    9. Creating a view to store rolling vaccination data for future analysis.

    The queries are designed to provide a comprehensive view of the COVID-19 impact across different regions and time periods.
*/

USE data_analysis;

-- Select initial data for exploration
-- Retrieve all records from the CovidDeaths table where continent is not null, ordered by date
SELECT
  *
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country
SELECT
  Location,
  date,
  total_cases,
  new_cases,
  total_deaths,
  population
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Total Cases vs Population
-- Shows the percentage of the population infected with Covid
SELECT
  Location, 
  date, 
  total_cases,
  total_deaths, 
  (total_deaths/NULLIF(total_cases, 0)) AS DeathPercentage
FROM data_analysis.CovidDeaths
WHERE location LIKE '%rgentina%'  -- Note: check if this filter is correct
AND continent IS NOT NULL
ORDER BY 1, 2;

-- Countries with Highest Infection Rate compared to Population
-- Shows countries with the highest percentage of the population infected
SELECT
  Location,  
  Population, 
  MAX(total_cases) AS HighestInfectionCount,  
  MAX((total_cases/population)) AS PercentPopulationInfected
FROM data_analysis.CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
-- Shows countries with the highest total death count
SELECT
  Location, 
  MAX(Total_deaths) AS TotalDeathCount
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Breaking Down by Continent
-- Shows continents with the highest death count per population
SELECT
  continent, 
  MAX(Total_deaths) AS TotalDeathCount
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers
-- Shows total new cases, total new deaths, and the death percentage globally
SELECT
  SUM(new_cases) AS total_cases, 
  SUM(new_deaths) AS total_deaths, 
  SUM(new_deaths)/NULLIF(SUM(new_cases), 0) AS DeathPercentage
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL;

-- Total Population vs Vaccinations
-- Shows the percentage of the population that has received at least one Covid vaccine
SELECT 
  continent, 
  location, 
  date, 
  population, 
  new_vaccinations, 
  SUM(new_vaccinations) OVER (PARTITION BY Location ORDER BY location, Date) AS RollingPeopleVaccinated
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 2, 3;

-- Using CTE to perform Calculation on Partition By in previous query
-- Calculates the percentage of the population vaccinated using a Common Table Expression (CTE)
WITH PopvsVac AS
(
  SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    SUM(new_vaccinations) OVER (PARTITION BY Location ORDER BY location, Date) AS RollingPeopleVaccinated
  FROM data_analysis.CovidDeaths
  WHERE continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePeopleVaccinated
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query
-- Creates a temporary table to calculate the rolling people vaccinated and the percentage of the population vaccinated
DROP TEMPORARY TABLE IF EXISTS t_PercentPopulationVaccinated;

CREATE TEMPORARY TABLE t_PercentPopulationVaccinated
(
  Continent NVARCHAR(255),
  Location NVARCHAR(255),
  Date DATETIME,
  Population NUMERIC,
  New_vaccinations NUMERIC,
  RollingPeopleVaccinated NUMERIC
);

INSERT INTO t_PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT 
  continent, 
  location, 
  date, 
  population, 
  new_vaccinations, 
  SUM(new_vaccinations) OVER (PARTITION BY Location ORDER BY location, Date) AS RollingPeopleVaccinated
FROM data_analysis.CovidDeaths;

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePeopleVaccinated
FROM t_PercentPopulationVaccinated;

-- Creating View to store data for later visualizations
-- Creates a view to store rolling vaccination data for future use
CREATE VIEW t_PercentPopulationVaccinated AS
SELECT
  continent, 
  location, 
  date, 
  population, 
  new_vaccinations, 
  SUM(new_vaccinations) OVER (PARTITION BY Location ORDER BY location, Date) AS RollingPeopleVaccinated
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL;
