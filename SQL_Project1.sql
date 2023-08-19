
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths



-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location = 'Canada'
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (cast(total_cases as float)/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
order by 1,2


-- Countries with Highest Infection Rate compared to Population

select location, population, max(total_cases) as HighestInfectionCount, max((cast(total_cases as float)/population)*100) as PercentPopulationInfected
From PortfolioProject..CovidDeaths
group by location, population
order by PercentPopulationInfected desc


-- Countries with the highest death count per population

Select Location, population, max(cast(total_deaths as int)) as HighestDeathCount, max(((cast(total_deaths as float))/(cast(population as float)))*100) as HighestDeathRate
From PortfolioProject..CovidDeaths
Where continent is not null 
group by location, population
order by HighestDeathRate desc


-- List of Highest death count in Descending order
Select Location, population, max(cast(total_deaths as int)) as HighestDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
group by location, population
order by HighestDeathCount desc


-- Showing contintents with the highest death count per population

select continent, max(cast(total_deaths as int)) as HighestDeathCountContinent
From PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by 2 desc

--select location, max(cast(total_deaths as int)) as HighestDeathCountContinent
--From PortfolioProject..CovidDeaths
--where continent is null
--group by location
--order by 2 desc



-- GLOBAL NUMBERS
-- world death rate

Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, ((sum(cast(new_deaths as int)))/sum(new_cases)*100) as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- note: created Temp table because operations on values in newly created column cannot be done withing same table

select deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
        , sum(cast(vacc.new_vaccinations as bigint)) over (partition by deaths.location order by deaths.location, deaths.date) as TolalVaccinationsByCountry
		
from PortfolioProject..covidVaccinations vacc
Join PortfolioProject..CovidDeaths deaths
   on vacc.location = deaths.location
   and vacc.date = deaths.date
where deaths.continent is not null

--cte(common table expression) of above 

with TempTable (location, date, population, new_vaccinations, RollingVaccinationsByCountry)
as
(
select deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
        , sum(cast(vacc.new_vaccinations as bigint)) over (partition by deaths.location order by deaths.location, deaths.date) as RollingVaccinationsByCountry
		
from PortfolioProject..covidVaccinations vacc
Join PortfolioProject..CovidDeaths deaths
   on vacc.location = deaths.location
   and vacc.date = deaths.date
where deaths.continent is not null
)
select * , (RollingVaccinationsByCountry/population)*100 as vaccinationRateByCountry
from TempTable



-- Using Temp Table to perform Calculation on Partition By in previous query

drop table if exists #VaccinationRateByCountry
Create Table #VaccinationRateByCountry
(
location nvarchar(225),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinationsByCountry numeric
)
insert into #VaccinationRateByCountry
select deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
        , sum(cast(vacc.new_vaccinations as bigint)) over (partition by deaths.location order by deaths.location, deaths.date) as RollingVaccinationsByCountry
		
from PortfolioProject..covidVaccinations vacc
Join PortfolioProject..CovidDeaths deaths
   on vacc.location = deaths.location
   and vacc.date = deaths.date
where deaths.continent is not null

select*
from #VaccinationRateByCountry



-- Creating View to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated 
AS
select deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
        , sum(cast(vacc.new_vaccinations as bigint)) over (partition by deaths.location order by deaths.location, deaths.date) as TolalVaccinationsByCountry
		from PortfolioProject..covidVaccinations vacc
Join PortfolioProject..CovidDeaths deaths
   on vacc.location = deaths.location
   and vacc.date = deaths.date
where deaths.continent is not null

