{{ config(severity='warn') }}

-- A competition with real shots but zero shots on target means the source
-- does not track SOG there (this is how we found the friendlies issue).
select
    competition,
    count(*)             as matches,
    sum(shots)           as shots,
    sum(shots_on_target) as shots_on_target
from {{ ref('stg_espn__gamelog') }}
group by competition
having sum(shots) >= 5 and sum(shots_on_target) = 0