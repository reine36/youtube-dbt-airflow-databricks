{{ 
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = ['external_video_id', 'performance_date'],
        schema = 'rva_silver'
    ) 
}}

with source as (
    select * from {{ source('rva_bronze', 'video_performance_over_time') }}
    {% if is_incremental() %}
    where _ingestion_time > (select max(_ingestion_time) from {{ this }})
    {% endif %}
),

sanitized as (
    select
        try_to_date(date, 'd MMM yyyy') as performance_date,
        trim(video_title) as video_title,
        trim(external_video_id) as external_video_id,
        try_cast(video_length as bigint) as video_length,
        trim(thumbnail_link) as thumbnail_link,
        try_cast(views as bigint) as views,
        try_cast(video_likes_added as bigint) as video_likes_added,
        try_cast(video_dislikes_added as bigint) as video_dislikes_added,
        try_cast(video_likes_removed as bigint) as video_likes_removed,
        try_cast(user_subscriptions_added as bigint) as user_subscriptions_added,
        try_cast(user_subscriptions_removed as bigint) as user_subscriptions_removed,
        try_cast(average_view_percentage as double) as average_view_percentage,
        try_cast(average_watch_time as int) as average_watch_time,
        try_cast(user_comments_added as bigint) as user_comments_added,
        _rescued_data,
        _ingestion_time,
        _source_file
    from source
    where date is not null 
      and trim(date) != ''
      and try_to_date(date, 'd MMM yyyy') is not null
),

deduplicated as (
    select *
    from sanitized
    qualify row_number() over (
        partition by external_video_id, performance_date 
        order by _ingestion_time desc
    ) = 1
)

select * from deduplicated