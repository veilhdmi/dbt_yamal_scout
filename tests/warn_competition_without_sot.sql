{{ config(severity='warn') }}

-- A competition with real shots but zero shots on target means the source
-- does not track SOG there (this is how we found the friendlies issue).
-- Aliases must NOT be "shots"/"shots_on_target": BigQuery resolves HAVING
-- names to the alias first, turning sum(shots) into sum(sum(shots)).
select
    competition,
    count(*)             as matches,
    sum(shots)           as total_shots,
    sum(shots_on_target) as total_sot
from {{ ref('stg_espn__gamelog') }}
group by competition
having sum(shots) >= 5 and sum(shots_on_target) = 0
