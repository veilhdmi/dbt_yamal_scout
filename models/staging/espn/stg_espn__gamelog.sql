with source as (

    select
        *,
        cast(split(score, '-')[safe_offset(0)] as int64) as score_first,
        cast(split(score, '-')[safe_offset(1)] as int64) as score_second
    from {{ source('espn', 'raw_espn_gamelog') }}

),

renamed as (

    select
        -- ids
        cast(event_id as string) as event_id,
        opponent_id,

        -- when
        game_date,
        date(game_date, 'Europe/Madrid') as match_date,
        season,

        -- context
        -- no "else": an unknown team_id must become null and fail the
        -- not_null test, instead of silently being labelled Barcelona
        case team_id
            when '83'  then 'Barcelona'
            when '164' then 'Spain'
        end as team,
        opponent_name as opponent,
        home_away,
        home_away = 'home' as is_home,
        -- ESPN writes the score winner-first, so in a defeat it reads "3-2" for a 2-3 loss.
        -- team_goals / opponent_goals put Lamine's team first, whatever the result.
        case when result = 'L' then score_second else score_first end as team_goals,
        case when result = 'L' then score_first else score_second end as opponent_goals,
        format(
            '%d-%d',
            case when result = 'L' then score_second else score_first end,
            case when result = 'L' then score_first else score_second end
        ) as score,
        result,
        league_slug,
        league_name as competition,
        case
            when league_slug = 'esp.1' then 'league'
            when league_slug like 'uefa.champions%' then 'champions_league'
            when league_slug in ('esp.copa_del_rey', 'esp.super_cup') then 'domestic_cup'
            when team_id = '164' and league_slug not like '%friendly%' then 'national_team'
            else 'friendly'
        end as competition_type,
        stage,

        -- stats
        goals,
        assists,
        shots,
        shots_on_target,
        fouls_suffered,
        fouls_committed,
        offsides,
        yellow_cards,
        red_cards,

        -- metadata
        ingested_at

    from source

)

select * from renamed
