SELECT * 
FROM covid_deaths
ORDER BY 3, 4

SELECT * 
FROM covid_vaccinations
ORDER BY 3, 4

SELECT Location, date, total_cases, new_cases, total_deaths, population, new_deaths_per_million, new_cases_per_million 
FROM covid_deaths
ORDER BY 1, 2

--Looking at Total Cases vs Total Deaths: Percent of deaths based on total cases.
--Shows liklihood of dying if you contract covid in your country. 
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE Location = 'India'
ORDER BY 1, 2
--1.18% Death Rate

--Looking at Total Cases vs Population: Percent of Population that got covid. 
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS CaseRate
FROM covid_deaths
WHERE Location = 'India'
ORDER BY 1, 2
--3.18% Case/Infection Rate
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS CaseRate
FROM covid_deaths
WHERE Location = 'United States'
ORDER BY 1, 2
--30.58% Case/Infection Rate

-- Looking at countries with Highest Infection Rate compared to Population 
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS CaseRate --MAX HAS to be applied to both total cases and population because population is multiple numbers and max total cases is one number. 
	--Even though you are interested only in total cases highest count. 
FROM covid_deaths
GROUP BY Location, Population
ORDER BY 4 DESC
--San Marino had 73% infection rate but that makes sense based on their low population of 33k, 
--based on population density and similar conditions in other country-specific areas around the world could have also had a 73% infection rate, if accounting for diagnosis/reporting errors. 

--Showing Countries with Highest Death Count per Population (country)
SELECT Location, MAX(Cast(total_deaths as int)) as TotalDeathCount
FROM covid_deaths
WHERE continent is not null 
GROUP BY Location 
Order by TotalDeathCount DESC
--Showing Countries with Highest Death Count per Continent Population 
SELECT location, MAX(Cast(total_deaths as int)) as TotalDeathCount
FROM covid_deaths
WHERE continent is null 
GROUP BY location
Order by TotalDeathCount DESC
--Europe>Asia>NA>SA>Africa>OCEANIA  

--GLOBAL NUMBERS 
SELECT date, SUM(new_cases) AS total_infection, SUM(new_deaths) AS total_mortality, SUM(new_deaths)/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM covid_deaths
--WHERE Location = 'India'
WHERE continent is not null
GROUP BY date
HAVING SUM(new_cases) <> 0
ORDER BY 1, 2
--when looking at multiple rows, cannot group by just one row without using AGGREGATE functions (on everything else) 
SELECT SUM(new_cases) AS total_infection, SUM(new_deaths) AS total_mortality, SUM(new_deaths)/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM covid_deaths
--WHERE Location = 'India'
WHERE continent is not null
--GROUP BY date
HAVING SUM(new_cases) <> 0
--Total Global Death Rate .90 % 





--TOTAL POPULATION vs VACCINATIONS  
SELECT *
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated--we need to do it by location, when the location is done we want the AGGREGATE function to start over
--And it shows each step of aggregation
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
Order by 2, 3 

WITH CTE_Rollingvacc (Continent, Location, Date, Population, NewVacc, RollingVaccinated) AS (SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null)
SELECT *, (RollingVaccinated/population)*100 AS PercentVaccinated
FROM CTE_Rollingvacc
--GROUP BY location
--ORDER BY 2 DESC

--TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, NewVacc numeric, RollingVacc numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--Order by 2, 3 

SELECT *, (RollingVacc/population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccinated

--VIEW 

Create View PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--Order by 2, 3 


--"Global Deaths"
SELECT location, total_deaths 
FROM covid_deaths
WHERE date = '20200324' AND continent is not null
--it will just take the highest BUT if you do SUM (new_deaths) what happens?

SELECT date, SUM(new_deaths)
FROM covid_deaths
WHERE date = '20200324' AND continent is not null
GROUP BY date


--"Continent death count"
SELECT location, MAX(Cast(total_deaths as int)) as TotalDeathCount
FROM covid_deaths
WHERE continent is null AND location not in ('world') AND SUBSTRING(Location, 6, 6) <> 'income' --damn you genius
GROUP BY location
Order by TotalDeathCount DESC

--"Showing Countries with Highest Death Count per Population" 
SELECT Location, population, MAX(total_deaths) as HighestDeathCount, MAX((total_deaths/population))*100 AS DeathPerPop
FROM covid_deaths
GROUP BY Location, Population
ORDER BY 4 DESC

--"Looking at countries with Highest Infection Rate compared to Population"
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS CaseRate
FROM covid_deaths
ORDER BY 5 DESC

--GROUP BY PARTITION BY issues comes with functions not naked calculations it seems.

WITH CTE_DeathPercent AS(
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths)
SELECT AVG(DeathPercentage) AS TotalDeathPercent
FROM CTE_DeathPercent
--Project Statement#1
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE Location like 'India'

WITH CTE_IndiaDeathPercent AS(
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE Location = 'India')
SELECT AVG(DeathPercentage) AS IndiaDeathPercent
FROM CTE_IndiaDeathPercent
--At the end of this year total recorded cases is 45 million and the 533395 death toll, gives a 1.19% death rate.
--However, based on fluctuating death tolls and cases over the last few years the average percentage of total_cases vs. total_deaths is actually 1.45%, 
--Although not the best estimate it speaks to the volatility and virulence of Covid and its variants varying across the 3-year span. 
WITH CTE_IndiaDeathPercent AS(
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE Location = 'India' AND date >= '20220101' AND date < '20221231') 
SELECT AVG(DeathPercentage) AS IndiaDeathPercent2022
FROM CTE_IndiaDeathPercent

WITH CTE_IndiaDeathPercent AS(
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE Location = 'India' AND date >= '20210101' AND date < '20211231') 
SELECT AVG(DeathPercentage) AS IndiaDeathPercent2021
FROM CTE_IndiaDeathPercent

WITH CTE_IndiaDeathPercent AS(
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE Location = 'India' AND date >= '20200101' AND date < '20201231') 
SELECT AVG(DeathPercentage) AS IndiaDeathPercent2020
FROM CTE_IndiaDeathPercent
--Year-based though you can see that fluctuation, considering 2020 is expected to be the worst and vaccines were rolling out in 2021. 
--2022 - 1.20% , 2021 - 1.32%, 2020 -2.18%; so the 1.45% skew against 1.18% comes mainly from 2020. 

SELECT Location, MAX(Cast(total_deaths as int)) as TotalDeathCount
FROM covid_deaths
WHERE Location like '%income'
GROUP BY Location 
Order by TotalDeathCount DESC
--Income-based
--High: 2919880
--UpperMiddle: 2667282
--LowerMiddle: 1340660
--LowIncome: 47999 

--Getting the date WHERE statement
SELECT location, date, total_deaths
FROM covid_deaths
WHERE Location = 'India' AND date >= '20220101' AND date < '20221225'

--Troubleshooting
SELECT CONVERT (int, total_cases)
FROM covid_deaths

CAST(total_cases AS int)
FROM covid_deaths ---none of these 2 methods worked. 
		---Just using SMSS to "Modify" Columns worked. 

--Checking statements for based on a specific country for applicability of functions on the data's structure and components
SELECT Location, date, 
SUM(new_cases_per_million) OVER (PARTITION BY new_cases_per_million) AS Afghan1Mcases, SUM(new_deaths_per_million) OVER (PARTITION BY new_deaths_per_million) AS Afghan1Mdeaths
FROM covid_deaths
WHERE Location = 'Afghanistan'

SELECT SUM(new_cases_per_million), SUM(new_deaths_per_million) 
FROM covid_deaths
WHERE Location = 'Afghanistan'

SELECT SUM(new_cases_per_million), SUM(new_deaths_per_million) 
FROM covid_deaths


SELECT Location, date, SUM(new_cases_per_million), SUM(new_deaths_per_million) 
FROM covid_deaths
WHERE Location = 'Afghanistan'
GROUP BY location, date

SELECT new_cases_per_million, new_deaths_per_million
FROM covid_deaths
WHERE Location = 'Afghanistan'
