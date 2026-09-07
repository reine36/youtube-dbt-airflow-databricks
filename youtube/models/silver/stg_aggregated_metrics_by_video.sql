{{ 
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'video_id',
        schema = 'rva_silver'
    ) 
}}

with source as (
    select * from {{ source('rva_bronze', 'aggregated_metrics_by_video') }}
    {% if is_incremental() %}
    where _ingestion_time > (select max(_ingestion_time) from {{ this }})
    {% endif %}
),

sanitized as (
    select
        trim(video) as video_id,
        trim(video_title) as video_title,
        try_to_timestamp(video_pub_lish_time) as video_publish_time,
        try_cast(com_ments_ad_ded as bigint) as comments_added,
        try_cast(shares as bigint) as shares,
        try_cast(dis_likes as bigint) as dislikes,
        try_cast(likes as bigint) as likes,
        try_cast(sub_scribers_lost as bigint) as subscribers_lost,
        try_cast(sub_scribers_gained as bigint) as subscribers_gained,
        try_cast(rpm_usd as double) as rpm_usd,
        try_cast(cpm_usd as double) as cpm_usd,
        try_cast(av_er_age_per_cent_age_viewed as double) as average_percentage_viewed,
        av_er_age_view_dur_a_tion as average_view_duration,
        try_cast(views as bigint) as views,
        try_cast(watch_time_hours as double) as watch_time_hours,
        try_cast(sub_scribers as bigint) as subscribers,
        try_cast(your_es_tim_ated_rev_en_ue_usd as double) as estimated_revenue_usd,
        try_cast(im_pres_sions as bigint) as impressions,
        try_cast(im_pres_sions_click_through_rate as double) as impressions_click_through_rate,
        _rescued_data,
        _ingestion_time,
        _source_file
    from source
),

deduplicated as (
    select *
    from sanitized
    qualify row_number() over (
        partition by video_id 
        order by _ingestion_time desc
    ) = 1
)

select * from deduplicated