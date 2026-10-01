-- Profile JSON field types across both raw sources.

select
    'source_a' as source_name,
    key as field_name,
    json_type(payload[key]) as json_type,
    count(*) as row_count
from {{ source('pokemon_raw', 'source_a') }},
unnest(json_keys(payload)) as key
group by 1, 2, 3

union all

select
    'source_b' as source_name,
    key as field_name,
    json_type(payload[key]) as json_type,
    count(*) as row_count
from {{ source('pokemon_raw', 'source_b') }},
unnest(json_keys(payload)) as key
group by 1, 2, 3

order by 1, 2, 3