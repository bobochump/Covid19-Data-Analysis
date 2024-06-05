/*

Queries to build visualizations off of for Tableau

*/

-- 1. Cases, deaths, death percentage for world
SELECT SUM(CAST(new_cases as INT)) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths,
(SUM(CONVERT(FLOAT, new_deaths)) / SUM(NULLIF(CONVERT(FLOAT, new_cases), 0))) *100 AS DeathPercentage
FROM PortfolioProjDataExpl..CovidDeaths
WHERE continent != ''
ORDER BY total_cases, total_deaths


-- 2. Total Death Count for Regions
SELECT Location, SUM(CAST(new_deaths as INT)) as TotalDeathCount
FROM PortfolioProjDataExpl..CovidDeaths
WHERE continent = ''
and Location not in ('World', 'European Union', 'International')
GROUP BY Location
ORDER BY TotalDeathCount desc

-- 3. Percent of population that has been infected per country
SELECT Location, Population, MAX(CAST(totaL_cases as INT)) as HighestInfectionCount,
MAX(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) *100 AS PercentPopulationInfected
FROM PortfolioProjDataExpl..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc

-- 4. 
SELECT Location, Population, date, MAX(CAST(totaL_cases as INT)) as HighestInfectionCount,
MAX(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) *100 AS PercentPopulationInfected
FROM PortfolioProjDataExpl..CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected desc



/*

Performing Data Analysis

*/
-- Looking at Total Cases vs Total Deaths
-- Shows chance of dying per country if you contract covid
SELECT Location, date, total_cases, total_deaths,
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) *100 AS DeathPercentage
FROM PortfolioProjDataExpl..CovidDeaths
WHERE continent != ''
ORDER BY Location, date



-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT Location, date, total_cases, population,
(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) *100 AS PercentPopulationInfected
FROM PortfolioProjDataExpl..CovidDeaths
WHERE continent != ''
--WHERE location like '%states%'
ORDER BY Location, date



-- Looking at countries with Highest Infection Rate compared to Pop
SELECT Location, MAX(total_cases) as HighestInfectionCount, population,
MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))) *100 AS PercentPopulationInfected
FROM PortfolioProjDataExpl..CovidDeaths
WHERE continent != ''
--WHERE location like '%states%'
GROUP BY Location, population
ORDER BY PercentPopulationInfected desc



-- Looking at countries with Highest Death Count
SELECT Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProjDataExpl..CovidDeaths
WHERE continent != ''
GROUP BY Location
ORDER BY TotalDeathCount desc


-- Looking at continents now

-- Looking at continents with Highest Death Count
SELECT continent, SUM(CAST(new_deaths as int)) as TotalDeaths
FROM PortfolioProjDataExpl..CovidDeaths
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeaths desc

-- Global Numbers

-- Global percentage of death if you contract covid
SELECT SUM(CAST(new_cases as int)) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths,
(CONVERT(float, SUM(CAST(new_deaths as int))) / NULLIF(CONVERT(float, SUM(CAST(new_cases as int))), 0)) *100 AS DeathPercentage
FROM PortfolioProjDataExpl..CovidDeaths
WHERE continent != ''
--GROUP BY date
ORDER BY TotalCases, TotalDeaths

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProjDataExpl..CovidDeaths dea
JOIN PortfolioProjDataExpl..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
ORDER BY location, date;


-- Using CTE
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProjDataExpl..CovidDeaths dea
JOIN PortfolioProjDataExpl..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
)
Select *,
(CONVERT(float, RollingPeopleVaccinated) / NULLIF(CONVERT(float, Population), 0)) *100 AS VaccinationPercentage
From PopVsVac
ORDER BY location, date


-- Using Temp Table
DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date nvarchar(255),
Population nvarchar(255),
New_Vaccinations nvarchar(255),
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProjDataExpl..CovidDeaths dea
JOIN PortfolioProjDataExpl..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
SELECT *,
(CONVERT(float, RollingPeopleVaccinated) / NULLIF(CONVERT(float, Population), 0)) *100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated
ORDER BY location, date


-- Creating View to store data for Tableau visualization
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProjDataExpl..CovidDeaths dea
JOIN PortfolioProjDataExpl..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''

SELECT *,
(CONVERT(float, RollingPeopleVaccinated) / NULLIF(CONVERT(float, Population), 0)) *100 AS VaccinationPercentage
FROM PercentPopulationVaccinated
ORDER BY location, date