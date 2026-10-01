{{ config(materialized='view') }}

select
    cast(json_value(payload, '$.id') as int64) as pokemon_id
    , trim(json_value(payload, '$.name')) as pokemon_name

    , initcap(trim(json_value(payload, '$.type_1'))) as primary_type

    , nullif(
            initcap(trim(json_value(payload, '$.type_2'))),
            ''
        ) as secondary_type

    , cast(json_value(payload, '$.total') as int64) as total_stats
    , cast(json_value(payload, '$.hp') as int64) as hp
    , cast(json_value(payload, '$.attack') as int64) as attack
    , cast(json_value(payload, '$.defense') as int64) as defense
    , cast(json_value(payload, '$.sp_atk') as int64) as special_attack
    , cast(json_value(payload, '$.sp_def') as int64) as special_defense
    , cast(json_value(payload, '$.speed') as int64) as speed
    , cast(json_value(payload, '$.generation') as int64) as generation

    , case lower(trim(json_value(payload, '$.legendary')))
        when 'true' then true
        when 'false' then false
        else null
    end as is_legendary

from {{ source('pokemon_raw', 'source_a') }}