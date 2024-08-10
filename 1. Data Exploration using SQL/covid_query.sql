-- Covid 19 Data Exploration Query 
-- Skills used: Beginner level queries, Converting Data Types, Joins, Common Table Expression, Temporary Tables, Windows Functions, Aggregate Functions, Creating Views

SELECT *  
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
order by 3,4

-- Select data that we are going to be using.
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
order by 1,2

-- Total Cases vs Total Deaths. Shows likelyhood of dying if you contract covid based on the country.
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProjectCOVID..CovidDeaths
WHERE location like '%Costa%'
order by 1,2

-- Total cases vs Population. Shows % of population with COVID per Day
SELECT location,date,total_cases,population,(total_cases/population)*100 as PercentPopulation
FROM PortfolioProjectCOVID..CovidDeaths
WHERE location like '%Costa%'
order by 1,2

-- Countries with highest infection rate compared to population 
SELECT continent,location,max(total_cases) as HighestInfectionCount,population,max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY continent,location,population
ORDER BY PercentPopulationInfected desc

-- Countries with highest death count per population
SELECT location,max(cast(total_deaths as int)) as Total_Death_Count
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY Total_Death_Count desc

-- Showing the continents with highest death count
SELECT continent,max(cast(total_deaths as int)) as Total_Death_Count
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY Total_Death_Count desc

-- Global Numbers
SELECT SUM(new_cases) as Total_Cases,SUM(cast(new_deaths as bigint)) as Total_Deaths,SUM(cast(new_deaths as bigint))/SUM(new_cases) * 100 as Death_Percentage
FROM PortfolioProjectCOVID..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


-- Total Population vs Vaccination. The query calculates the cumulative count of people vaccinated per day for each location.
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


--Utilizing CTE to calculate how many people were vaccinated per population
With PopvsVac (Continent,Location,Date,Population,New_Vaccinations,RollingPeopleVaccinated)
AS (
	SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
	FROM 
		PortfolioProjectCOVID..CovidDeaths dea
	JOIN 
		PortfolioProjectCOVID..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
)

SELECT *,(RollingPeopleVaccinated/Population)*100 AS Calculation --% of people vaccinated
FROM PopvsVac
ORDER BY Location,Date;

--Using temporary table to perform the same result as previous query but going for another approach -> Temporary Tables.
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
	SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
	FROM 
		PortfolioProjectCOVID..CovidDeaths dea
	JOIN 
		PortfolioProjectCOVID..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date

SELECT *,(RollingPeopleVaccinated/Population)*100 AS Calculation --% of people vaccinated
FROM #PercentPopulationVaccinated
ORDER BY Location,Date;


-- Creating View to store data for later visualizations
USE PortfolioProjectCOVID
GO

IF OBJECT_ID('dbo.PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW dbo.PercentPopulationVaccinated;
GO

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjectCOVID..CovidDeaths dea
JOIN PortfolioProjectCOVID..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL