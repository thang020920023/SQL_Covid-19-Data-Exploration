SELECT *
FROM Portfolio_Project..CovidDeaths
ORDER BY 3, 4


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in Vietnam

SELECT continent, location, date, total_cases, cast(total_deaths as int), (cast(total_deaths as int)/total_cases)*100 AS DeathsPercentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
AND location LIKE '%Vietnam%'
ORDER BY location, date

-- Percentage of population infected in each country
SELECT location, date, population, total_cases, (total_cases/population)*100 AS Country_PopulationInfected_Percentage
FROM Portfolio_Project..CovidDeaths
--WHERE location LIKE '%Vietnam%'
ORDER BY 1,2 DESC

-- Showing Countries with highest Percentage of people infected with COVID-19 compared to population

SELECT location, population, max(total_cases) AS max_total_case, max(total_cases/population)*100 AS Country_PopulationInfected_Percentage
FROM Portfolio_Project..CovidDeaths
--WHERE location LIKE '%Vietnam%'
GROUP BY location, population
ORDER BY Country_PopulationInfected_Percentage DESC

-- Showing countries with highest Death by COVID-19 compared to population

SELECT location, population, max(cast(total_deaths as int)) AS max_total_deaths, max(cast(total_deaths as int)/population)*100 AS Infected_Population_Percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Infected_Population_Percentage DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, population, max(total_cases) AS max_total_case, max(total_cases/population)*100 AS Continent_PopulationInfected_Percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, population
ORDER BY Continent_PopulationInfected_Percentage DESC

-- GLOBAL NUMBER

SELECT date, SUM(total_cases) AS global_total_case, SUM(cast(total_deaths as int)) AS total_deaths,
(SUM(cast(total_deaths as int))/SUM(total_cases))*100 AS DeathLikelihood
FROM Portfolio_Project..CovidDeaths
GROUP BY date
ORDER BY date

-- Total Population vs Vaccinations
-- Show percentage of population that has received at least one Covid Vaccine

SELECT *
FROM Portfolio_Project..CovidVaccinations

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, cast(Vac.new_vaccinations as int), cast(Vac.total_vaccinations as int)
FROM Portfolio_Project..CovidDeaths Dea
JOIN Portfolio_Project..CovidVaccinations Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL
ORDER BY 2, 3

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, cast(Vac.new_vaccinations as int),
SUM(cast(Vac.new_vaccinations as int)) over(PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) as RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths Dea
JOIN Portfolio_Project..CovidVaccinations Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
where dea.continent is not null 
ORDER BY 2, 3

--

WITH Vaccinated_population_percentage (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, cast(Vac.new_vaccinations as int),
SUM(cast(Vac.new_vaccinations as int)) over(PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) as RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths Dea
JOIN Portfolio_Project..CovidVaccinations Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
where dea.continent is not null 
--ORDER BY 2, 3
)

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM Vaccinated_population_percentage

-----------

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
