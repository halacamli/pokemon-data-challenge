{{ config(materialized='table') }}

with pokemon as (

    select *
    from {{ ref('stg_pokemon_consolidated') }}

),

pokemon_reference as (

    select
        pokemon_id,
        default_name
    from {{ source('pokemon_reference', 'pokemon_species') }}

),

name_parts as (

    select
        p.*,
        r.default_name,

        case
            when starts_with(
                lower(p.pokemon_name),
                lower(r.default_name)
            )
            then nullif(
                trim(
                    substr(
                        p.pokemon_name,
                        length(r.default_name) + 1
                    )
                ),
                ''
            )
        end as extracted_form

    from pokemon p

    left join pokemon_reference r
        on p.pokemon_id = r.pokemon_id

),

final as (

    select
        pokemon_id,

        case
            when extracted_form is not null
                then substr(
                    pokemon_name,
                    1,
                    length(default_name)
                )
            else pokemon_name
        end as pokemon_name,

        coalesce(extracted_form, 'Default') as pokemon_form,

        count(*) over (
            partition by pokemon_id
        ) as variant_count,

        primary_type,
        secondary_type,
        total_stats,
        hp,
        attack,
        defense,
        special_attack,
        special_defense,
        speed,
        generation,
        is_legendary,
        seen_in_source_a,
        seen_in_source_b

    from name_parts

)

select *
from final
order by pokemon_id, pokemon_form