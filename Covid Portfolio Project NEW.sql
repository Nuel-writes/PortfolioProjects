SELECT *
FROM CovidDeaths
ORDER BY 3, 4 DESC

-- SELECT DATA that we're going to be using

SELECT Location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM CovidDeaths
ORDER BY 1,2
;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in your country
SELECT Location
	, date
	, total_cases
	, total_deaths 
	, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE Location LIKE '%Nigeria' and continent IS NOT NULL
ORDER BY 1, 2 
;

--Looking at total cases vs population
--Shows what percentage of population has gotten Covid
SELECT Location
	, date
	, total_cases
	, population 
	, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE Location LIKE '%states' and continent IS NOT NULL
ORDER BY 1, 2 
;

-- Looking at countries with highest infection rate 
-- compared to population

SELECT Location
	, population
	, MAX(total_cases) AS HighestInfectionCount
	, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY Location, population
ORDER BY 4 DESC



-- Showing countries with highest death count 
-- per population

SELECT location
	, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
;

-- Let's break things down by continent
-- Showing continents with the highest death count per
-- population

SELECT location
	, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
;

-- Global Numbers

SELECT SUM(new_cases) 'New Cases'
	, SUM(CAST(new_deaths AS INT)) 'New Deaths'
	, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 
	AS DeathPercentage
--	, date
FROM CovidDeaths
WHERE continent IS NOT NULL 
--GROUP BY date
ORDER BY 1, 2
;



-- Looking at total population vs vaccinations

SELECT DEA.continent
	, DEA.location
	,  DEA.date
	, DEA.population
	, VAC.new_vaccinations
FROM PortfolioProject01..CovidDeaths DEA
	JOIN PortfolioProject01..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3
;

-- Using PARTITION BY

SELECT DEA.continent
	, DEA.location
	, DEA.date
	, DEA.population
	, VAC.new_vaccinations
	, SUM(CAST(VAC.new_vaccinations AS INT))
	OVER (PARTITION BY DEA.location ORDER BY DEA.location,
	DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject01..CovidDeaths DEA
	JOIN PortfolioProject01..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3
;

-- Use CTE to find the percentage of vaccinated population

WITH PopVsVac (Continent, Location, Date, Population 
	, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT DEA.continent
	, DEA.location
	, DEA.date
	, DEA.population
	, VAC.new_vaccinations
	, SUM(CAST(VAC.new_vaccinations AS INT))
	OVER (PARTITION BY DEA.location ORDER BY DEA.location,
	DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject01..CovidDeaths DEA
	JOIN PortfolioProject01..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, ((RollingPeopleVaccinated/Population)*100) VacRate
FROM PopVsVac
;


--Using a temp table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT DEA.continent
	, DEA.location
	,  DEA.date
	, DEA.population
	, VAC.new_vaccinations
	, SUM(CAST(VAC.new_vaccinations AS INT))
	OVER (PARTITION BY DEA.location ORDER BY DEA.location,
	DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject01..CovidDeaths DEA
	JOIN PortfolioProject01..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
--WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations

Create View PercentPopulationVaccinated AS
SELECT DEA.continent
	, DEA.location
	,  DEA.date
	, DEA.population
	, VAC.new_vaccinations
	, SUM(CAST(VAC.new_vaccinations AS INT))
	OVER (PARTITION BY DEA.location ORDER BY DEA.location,
	DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject01..CovidDeaths DEA
	JOIN PortfolioProject01..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
--WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3

--Creating View for highest infection rate

CREATE VIEW HighestInfectionRate AS
SELECT Location
	, population
	, MAX(total_cases) AS HighestInfectionCount
	, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY Location, population
--ORDER BY 4 DESC
;

--Creating view for highest death count

CREATE VIEW HighestDeathCount AS
SELECT location
	, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
--ORDER BY TotalDeathCount DESC
;

SELECT *
FROM HighestDeathCount