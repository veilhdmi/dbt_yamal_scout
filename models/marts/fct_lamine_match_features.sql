with matches as (

    select * from {{ ref('stg_espn__gamelog') }}
    where competition_type != 'friendly'   -- ESPN has no reliable SOG in friendlies

),

features as (

    select
        event_id,
        game_date,
        match_date,
        team,
        opponent,
        is_home,
        competition_type,

        -- targets (Y)
        shots_on_target,
        shots,
        goals,
        assists,

        -- features (X): ONLY matches BEFORE this one
        row_number() over w_order                    as competitive_match_number,
        count(*)             over w_prev5            as matches_in_prev5,
        avg(shots_on_target) over w_prev5            as sot_avg_prev5,
        avg(shots_on_target) over w_prev10           as sot_avg_prev10,
        avg(shots_on_target) over w_prev_all         as sot_career_avg_prev,
        avg(shots)           over w_prev5            as shots_avg_prev5,
        avg(shots)           over w_prev10           as shots_avg_prev10,
        avg(goals)           over w_prev5            as goals_avg_prev5

    from matches
    window
        w_order    as (order by game_date),
        w_prev5    as (order by game_date rows between 5 preceding and 1 preceding),
        w_prev10   as (order by game_date rows between 10 preceding and 1 preceding),
        w_prev_all as (order by game_date rows between unbounded preceding and 1 preceding)

)

select * from features
