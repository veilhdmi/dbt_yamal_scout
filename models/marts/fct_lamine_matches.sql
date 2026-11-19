with matches as (

    select * from {{ ref('stg_espn__gamelog') }}

)

select
    *,
    -- counts EVERY match, friendlies included (real-world experience);
    -- the features mart has its own competitive_match_number
    row_number() over (order by game_date)       as career_match_number,
    competition_type = 'friendly'                as is_friendly
from matches
