{{ config(materialized='view') }}

select
    cast(json_value(payload, '$.pokemonId') as int64) as pokemon_id
    , trim(json_value(payload, '$.pokemonName')) as pokemon_name

    , initcap(trim(json_value(payload, '$.primaryType'))) as primary_type

    , nullif(
            initcap(trim(json_value(payload, '$.secondaryType'))),
            ''
        ) as secondary_type

    , cast(json_value(payload, '$.totalStats') as int64) as total_stats
    , cast(json_value(payload, '$.hp') as int64) as hp
    , cast(json_value(payload, '$.attack') as int64) as attack
    , cast(json_value(payload, '$.defense') as int64) as defense
    , cast(json_value(payload, '$.specialAttack') as int64) as special_attack
    , cast(json_value(payload, '$.specialDefense') as int64) as special_defense
    , cast(json_value(payload, '$.speed') as int64) as speed
    , cast(json_value(payload, '$.generation') as int64) as generation
    , cast(json_value(payload, '$.isLegendary') as bool) as is_legendary

from {{ source('pokemon_raw', 'source_b') }}