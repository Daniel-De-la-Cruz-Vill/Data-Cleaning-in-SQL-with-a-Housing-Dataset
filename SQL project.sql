SELECT *
FROM SQLProject..CovidDeath
WHERE continent is not Null
ORDER BY 3,4

SELECT *
FROM SQLProject..CovidVaccination
ORDER BY 3,4

--Selecting the data we are going to use

SELECT Location, date, total_cases, new_cases,
total_deaths, population
FROM SQLProject..CovidDeath
ORDER BY 1,2

--Selected data for the United States

SELECT Location, date, total_cases, new_cases,
total_deaths, population
FROM SQLProject..CovidDeath
WHERE Location LIKE '%states'
ORDER BY 1,2

--Total cases vs total deaths 

SELECT Location, date, total_cases, total_deaths, 
cast(total_deaths as float)/cast(total_cases as float)*100 death_percentage
FROM SQLProject..CovidDeath
WHERE Location LIKE '%states'
ORDER BY 1,2

-- Looking at total cases vs population
SELECT Location, date, population, total_cases, 
cast(total_cases as int)/cast(population as float)*100 case_percentage
FROM SQLProject..CovidDeath
WHERE Location LIKE '%states'
ORDER BY 1,2

-- Countries with highest infection rate compared to population 
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  
(Max(total_cases)/population)*100 as PercentPopulationInfected
FROM SQLProject..CovidDeath
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Showing countries with the highest death count per population
SELECT Location, Population, 
MAX(cast(total_deaths as int)) AS HighestDeathCount, 
(MAX(cast(total_deaths as int))/population)*100 DeadPopulationPercentage
FROM SQLProject..CovidDeath
WHERE continent is not null
GROUP BY Location, Population
ORDER BY HighestDeathCount DESC

--Breaking things down by continent
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM SQLProject..CovidDeath
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC

-- Global numbers
SELECT date, SUM(cast(total_cases as int)) total_cases, 
SUM(cast(total_deaths as int)) total_deaths, 
(SUM(cast(total_deaths as float))/SUM(cast(total_cases as float)))*100 DeathPercentage
FROM SQLProject..CovidDeath
WHERE continent is not null
GROUP BY date
ORDER BY 1


--NOW WORKING WITH VACCINATIONS

--Total population vs vaccination
WITH PopvsVacc (continent, location, date, population, new_vaccinations, RollingVaccinatedNumber) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.LOCATION order by dea.location, dea.date) RollingVaccinatedNumber
FROM SQLProject..CovidDeath dea
JOIN SQLProject..CovidVaccination vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 1,2,3 
)

--Using the CTE 
SELECT *, (RollingVaccinatedNumber/population)*100 PercentageOfVaccinated
FROM PopvsVacc


--Creating view to store data for visualizing later
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.LOCATION order by dea.location, dea.date) RollingVaccinatedNumber
FROM SQLProject..CovidDeath dea
JOIN SQLProject..CovidVaccination vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated