/*
Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
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
