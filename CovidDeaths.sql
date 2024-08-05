/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

USE data_analysis;

  -- Select Data that we are going to be starting with

SELECT
  *
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

  -- Total Cases vs Total Deaths
  -- Shows likelihood of dying if you contract covid in your country

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
  -- Shows what percentage of population infected with Covid

SELECT
  Location, 
  date, 
  total_cases,
  total_deaths, 
  (total_deaths/NULLIF(total_cases, 0)) as DeathPercentage
FROM data_analysis.CovidDeaths
WHERE location LIKE '%rgentina%'
AND continent IS NOT NULL
ORDER BY 1,2;

  -- Countries with Highest Infection Rate compared to Population

SELECT
  Location,  
  Population, 
  MAX(total_cases) as HighestInfectionCount,  
  Max((total_cases/population)) AS PercentPopulationInfected
FROM data_analysis.CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

  -- Countries with Highest Death Count per Population

SELECT
  Location, 
  MAX(Total_deaths) AS TotalDeathCount
FROM data_analysis.CovidDeaths
Where continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

  -- BREAKING THINGS DOWN BY CONTINENT
  -- Showing contintents with the highest death count per population

SELECT
  continent, 
  MAX(Total_deaths) AS TotalDeathCount
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

  -- Golab Numbers

SELECT
  SUM(new_cases) AS total_cases, 
  SUM(new_deaths) AS total_deaths, 
  SUM(new_deaths)/SUM(New_Cases) AS DeathPercentage
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;
  
  -- Total Population vs Vaccinations
  -- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
  continent, 
  location, 
  date, 
  population, 
  new_vaccinations, 
  SUM(new_vaccinations) OVER (PARTITION BY Location ORDER BY location, Date) AS RollingPeopleVaccinated
FROM data_analysis.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 2,3;

  -- Using CTE to perform Calculation on Partition By in previous query

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
  -- order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePeopleVaccinated
FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TEMPORARY TABLE IF EXISTS t_PercentPopulationVaccinated;

CREATE TEMPORARY TABLE t_PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
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

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM t_PercentPopulationVaccinated;

-- Creating View to store data for later visualizations

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