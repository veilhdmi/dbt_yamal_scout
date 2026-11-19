with matches as (

    select * from {{ ref('stg_espn__gamelog') }}

)

select
    *,
    row_number() over (order by game_date)       as career_match_number,
    competition_type = 'friendly'                as is_friendly
from matches