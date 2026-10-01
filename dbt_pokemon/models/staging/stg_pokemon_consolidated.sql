{{ config(materialized='table') }}

with combined_sources as (

    select
        *
        , 'source_a' as source
    from {{ ref('stg_pokemon_source_a') }}

    union all

    select
        *
        , 'source_b' as source
    from {{ ref('stg_pokemon_source_b') }}

),

source_presence as (

    select
        pokemon_id
        , pokemon_name
        , logical_or(source = 'source_a') as seen_in_source_a
        , logical_or(source = 'source_b') as seen_in_source_b
    from combined_sources
    group by 1,2 
        

),

deduplicated as (

    select
        *
        , row_number() over (
                partition by pokemon_id, pokemon_name
                order by source
            ) as row_num
    from combined_sources

)
select
    d.pokemon_id
    , d.pokemon_name
    , d.primary_type
    , d.secondary_type
    , d.total_stats
    , d.hp
    , d.attack
    , d.defense
    , d.special_attack
    , d.special_defense
    , d.speed
    , d.generation
    , d.is_legendary
    , s.seen_in_source_a
    , s.seen_in_source_b

from deduplicated d

left join source_presence s
    on d.pokemon_id = s.pokemon_id
    and d.pokemon_name = s.pokemon_name

where d.row_num = 1
order by pokemon_id

