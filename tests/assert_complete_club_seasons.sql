{{ config(severity='error', warn_if='>=1', error_if='>=3') }}

-- Finished Barcelona seasons with suspiciously few matches -> missing data.
select season, count(*) as matches
from {{ ref('stg_espn__gamelog') }}
where team = 'Barcelona'
  and season >= 2023
  and season < (select max(season) from {{ ref('stg_espn__gamelog') }})
group by season
having count(*) < 40