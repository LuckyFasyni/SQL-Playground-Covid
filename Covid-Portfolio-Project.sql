select * from coviddeath order by 3, 4;

-- show the likelihood of dying if you contract covid in Indonesia
select 
  location, 
  date, 
  total_cases, 
  total_deaths, 
  (total_deaths/total_cases)*100 DeathPercentage
from coviddeath
where location = 'Indonesia'
order by 1, 2;

-- Total Cases vs Population
-- show the percentage of population git covid
select 
  location, 
  date, 
  population, 
  total_cases, 
  (total_cases/population)*100 percentpopulationinfected
from coviddeath
where location = 'Indonesia'
order by 1, 2;

-- Looking at Countries with Highest Infection Rate
select 
  location, 
  population, 
  max(total_cases) HighestInfectionCount, 
  (max(total_cases)/population)*100 HighestInfectionPercentage
from coviddeath
group by location, population
having (max(total_cases)/population)*100 is not null
order by HighestInfectionPercentage desc;

-- Looking at Countries with Highest Death Rate
select 
  location, 
  population, 
  max(total_deaths) HighestDeathCount, 
  (max(total_deaths)/population)*100 HighestDeathPercentage
from coviddeath
where continent is not null 
group by location, population 
having (max(total_deaths)/population)*100 is not null 
order by HighestDeathPercentage desc;

-- Looking at Infection Rate based on Continent
select 
  location, 
  population, 
  max(total_deaths) HighestDeathCount, 
  (max(total_deaths)/population)*100 HighestDeathPercentage
from coviddeath
where continent is null 
group by location, population
having (max(total_deaths)/population)*100 is not null
order by HighestDeathPercentage desc;

-- Looking at Infection Rate based on Continent 2
with 
countries as (
select 
  continent, 
  location, 
  population, 
  max(total_deaths) HighestDeathCount, 
  (max(total_deaths)/population)*100 HighestDeathPercentage
from coviddeath
where continent is not null 
group by continent, location, population 
having (max(total_deaths)/population)*100 is not null
)

select 
  continent, 
  sum(population) population, 
  sum(HighestDeathCount) HighestDeathCount, 
  (sum(HighestDeathCount)/sum(population))*100 HighestDeathPercentage
from countries
group by continent 
order by HighestDeathPercentage desc;

-- Global Number Date by Date
select 
  date, 
  sum(new_cases) new_cases, 
  sum(new_deaths) new_deaths, 
  (sum(new_deaths)/sum(new_cases))*100 DeathPercentage
from coviddeath
where continent is not null
group by date
having (sum(new_deaths)/sum(new_cases))*100 is not null 
order by date;

-- Total Cases per Today
select 
  location, 
  sum(new_cases) total_cases, 
  sum(new_deaths) total_deaths
from coviddeath
where location = 'World'
group by location;

-- Accumulative Vaccination for each Country day to day
select 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations,
  sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) new_vaccinations_accumulative
from coviddeath dea
join covidvaccine vac 
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null
order by dea.location, dea.date;

-- Percentage of Vaccinated People day by day in Indonesia (use CTE)
with 
PopvsVac (continent, country, date, population, new_vaccinations, accumulative_vaccinations) as (
select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations,
  sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) new_vaccinations_accumulative
from coviddeath dea
join covidvaccine vac 
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null
order by dea.location, dea.date
)

select 
  *, 
  (accumulative_vaccinations/population)*100 PercentPopulationVaccinated
from PopvsVac;

-- Make TEMP Table
drop table if exists PercentPopulationVaccinated; 
create table PercentPopulationVaccinated (
	continent varchar(255),
	country varchar(255),
	date timestamp,
	population numeric,
	new_vaccinations numeric, 
	acc_vaccinations numeric, 
	percentpopulationvaccinated numeric
);

insert into PercentPopulationVaccinated (
with PopvsVac (continent, country, date, population, new_vaccinations, accumulative_vaccinations) as (
select 
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population, 
  vac.new_vaccinations,
  sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) new_vaccinations_accumulative
from coviddeath dea
join covidvaccine vac 
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null
order by dea.location, dea.date
)

select 
  *, 
  (accumulative_vaccinations/population)*100 PercentPopulationVaccinated
from PopvsVac
);


select * 
from PercentPopulationVaccinated;

-- Create View
create view VaccinationRate as (
select * 
from PercentPopulationVaccinated
);

create view GlobalCovidRate as (
select 
  date, 
  sum(new_cases) new_cases, 
  sum(new_deaths) new_deaths, 
  (sum(new_deaths)/sum(new_cases))*100 DeathPercentage
from coviddeath
where continent is not null
group by date
having (sum(new_deaths)/sum(new_cases))*100 is not null 
order by date
);
