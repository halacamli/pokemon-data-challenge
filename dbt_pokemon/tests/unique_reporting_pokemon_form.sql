select
    pokemon_id,
    pokemon_form,
    count(*) as row_count
from {{ ref('pokemon_reporting') }}
group by
    pokemon_id,
    pokemon_form
having count(*) > 1