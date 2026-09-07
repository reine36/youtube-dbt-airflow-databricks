{{ 
    config(
        materialized = 'table',
        schema = 'rva_gold'
    ) 
}}

with country_metrics as (
    select * from {{ ref('stg_aggregated_metrics_by_country_and_subscriber_status') }}
)

select
    external_video_id,
    video_title,
    country_code,
    is_subscribed,
    sum(views) as total_views,
    sum(video_likes_added) as total_likes_added,
    sum(video_dislikes_added) as total_dislikes_added,
    sum(user_subscriptions_added) as total_subscriptions_added,
    sum(user_subscriptions_removed) as total_subscriptions_removed,
    avg(average_view_percentage) as avg_view_percentage,
    avg(average_watch_time) as avg_watch_time,
    sum(user_comments_added) as total_comments_added
from country_metrics
group by 1, 2, 3, 4