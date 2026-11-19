-- Recomputes sot_avg_prev5 using ONLY earlier matches (self-join) and
-- compares it with the mart. Any row returned = leakage or a broken window.
with f as (

    select event_id, game_date, competitive_match_number, sot_avg_prev5
    from {{ ref('fct_lamine_match_features') }}

),

previous_matches as (

    select
        f.event_id,
        f.sot_avg_prev5,
        p.shots_on_target,
        row_number() over (partition by f.event_id order by p.game_date desc) as recency
    from f
    join {{ ref('fct_lamine_match_features') }} as p
        on p.game_date < f.game_date

),

recomputed as (

    select
        event_id,
        any_value(sot_avg_prev5) as feature_value,
        avg(shots_on_target)     as expected_value
    from previous_matches
    where recency <= 5
    group by event_id

)

select event_id, feature_value, expected_value
from recomputed
where feature_value is null                        -- null with history = broken window
   or abs(feature_value - expected_value) > 1e-9

union all

-- the first competitive match has no history, so its feature must be null
select event_id, sot_avg_prev5, null
from f
where competitive_match_number = 1 and sot_avg_prev5 is not null
