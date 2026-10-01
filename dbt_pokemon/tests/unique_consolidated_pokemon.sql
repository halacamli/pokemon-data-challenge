select
    pokemon_id,
    pokemon_name,
    count(*) as row_count
from {{ ref('stg_pokemon_consolidated') }}
group by
    pokemon_id,
    pokemon_name
having count(*) > 1