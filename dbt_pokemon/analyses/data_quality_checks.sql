-- Data quality checks across the two staged sources

with consolidated_data as (
    select *
      , 'source_a' as source 
    from {{ ref('stg_pokemon_source_a') }}
    union all 
    select *
      , 'source_b' as source
    from {{ ref('stg_pokemon_source_b') }} 
)

-- Row counts and dataset grain
, row_count_check as (

    select
        count(*) as total_rows
        , count(distinct pokemon_id) as distinct_pokemon_ids
        , count(
            distinct concat(
                cast(pokemon_id as string),
                '|',
                pokemon_name
            )
        ) as distinct_pokemon_forms
    from consolidated_data

)

-- Validate total_stats calculation
-- Expected result: 0 rows
, stat_consistency as ( 
    select *
    from consolidated_data
    where total_stats != (
        hp
        + attack
        + defense
        + special_attack
        + special_defense
        + speed
    )
)

-- Identify duplicate business keys
, duplicate_keys as (
    select 
          pokemon_id
        , pokemon_name
        , count(*) as row_count
        , string_agg(source order by source) as sources
    from consolidated_data
    group by
        pokemon_id,
        pokemon_name
    having count(*) > 1
),

-- Compare non-key attributes across duplicate business keys
duplicate_validation as (
    select 
        pokemon_id
        , pokemon_name
        , string_agg(source order by source) as sources
        , count(distinct primary_type) as primary_type_values
        , count(distinct coalesce(secondary_type, '__NULL__')) as secondary_type_values
        , count(distinct total_stats) as total_stats_values
        , count(distinct hp) as hp_values
        , count(distinct attack) as attack_values
        , count(distinct defense) as defense_values
        , count(distinct special_attack) as special_attack_values
        , count(distinct special_defense) as special_defense_values
        , count(distinct speed) as speed_values
        , count(distinct generation) as generation_values
        , count(distinct is_legendary) as legendary_values
    from consolidated_data
    group by
        pokemon_id,
        pokemon_name
    having count(*) > 1
    order by pokemon_id
)

-- Validate that duplicate business keys do not contain conflicting values
-- Expected result: 0 rows
, duplicate_check as (
    select
        *
    from duplicate_validation
    where primary_type_values > 1
      or secondary_type_values > 1
      or total_stats_values > 1
      or hp_values > 1
      or attack_values > 1
      or defense_values > 1
      or special_attack_values > 1
      or special_defense_values > 1
      or speed_values > 1
      or generation_values > 1
      or legendary_values > 1
    order by
        pokemon_id,
        pokemon_name
)
-- Validate basic numeric ranges
-- Expected result: 0 rows

, range_sanity_check as (
    select *
    from consolidated_data
    where pokemon_id <= 0
      or hp < 0
      or attack < 0
      or defense < 0
      or special_attack < 0
      or special_defense < 0
      or speed < 0
      or generation <= 0
   )

-- Identify Pokemon IDs associated with multiple forms/names
, pokemon_form_check as (
    select
        pokemon_id
        , count(distinct pokemon_name) as name_count
        , string_agg(distinct pokemon_name order by pokemon_name) as names
    from consolidated_data
    group by pokemon_id
    having count(distinct pokemon_name) > 1
)

-- Select the check you want to inspect:
-- select * from stat_consistency;
-- select * from duplicate_keys order by pokemon_id, pokemon_name;
-- select * from duplicate_validation order by pokemon_id, pokemon_name;
-- select * from duplicate_check order by pokemon_id, pokemon_name;
-- select * from pokemon_form_check; 
select * from range_sanity_check;

