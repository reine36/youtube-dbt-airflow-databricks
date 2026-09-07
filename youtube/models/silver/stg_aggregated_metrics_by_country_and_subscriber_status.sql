{{ 
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = ['external_video_id', 'country_code', 'is_subscribed'],
        schema = 'rva_silver'
    ) 
}}

with source as (
    select * from {{ source('rva_bronze', 'aggregated_metrics_by_country_and_subscriber_status') }}
    {% if is_incremental() %}
    -- Only pull new records based on ingestion timestamp
    where _ingestion_time > (select max(_ingestion_time) from {{ this }})
    {% endif %}
),

sanitized as (
    select
        trim(video_title) as video_title,
        trim(external_video_id) as external_video_id,
        video_length,
        trim(thumbnail_link) as thumbnail_link,
        lower(trim(country_code)) as country_code,
        is_subscribed,
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
    where country_code is not null 
      and trim(country_code) != ''
),

deduplicated as (
    select *
    from sanitized
    qualify row_number() over (
        partition by external_video_id, country_code, is_subscribed 
        order by _ingestion_time desc
    ) = 1
)

select * from deduplicated