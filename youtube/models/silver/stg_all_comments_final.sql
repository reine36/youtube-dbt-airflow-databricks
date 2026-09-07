{{ 
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'comment_id',
        schema = 'rva_silver'
    ) 
}}

with source as (
    select * from {{ source('rva_bronze', 'all_comments_final') }}
    {% if is_incremental() %}
    where _ingestion_time > (select max(_ingestion_time) from {{ this }})
    {% endif %}
),

sanitized as (
    select
        trim(comments) as comment_text,
        trim(comment_id) as comment_id,
        try_cast(reply_count as int) as reply_count,
        try_cast(like_count as int) as like_count,
        try_to_date(date) as comment_date,
        trim(vidid) as external_video_id,
        trim(user_id) as user_id,
        _rescued_data,
        _ingestion_time,
        _source_file
    from source
    where comment_id is not null 
      and trim(comment_id) != ''
      and vidid is not null 
      and trim(vidid) != ''
),

deduplicated as (
    select *
    from sanitized
    qualify row_number() over (
        partition by comment_id 
        order by _ingestion_time desc
    ) = 1
)

select * from deduplicated