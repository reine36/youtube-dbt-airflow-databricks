{{ 
    config(
        materialized = 'table',
        schema = 'rva_gold'
    ) 
}}

with performance as (
    select * from {{ ref('stg_video_performance_over_time') }}
),

daily_comments as (
    select 
        external_video_id,
        comment_date,
        count(comment_id) as daily_comment_count,
        sum(like_count) as daily_comment_likes
    from {{ ref('stg_all_comments_final') }}
    group by 1, 2
)

select
    p.performance_date,
    p.external_video_id,
    p.video_title,
    p.thumbnail_link,
    p.video_length,
    p.views,
    p.video_likes_added,
    p.video_dislikes_added,
    p.average_view_percentage,
    p.average_watch_time,
    coalesce(c.daily_comment_count, 0) as daily_comment_count,
    coalesce(c.daily_comment_likes, 0) as daily_comment_likes
from performance p
left join daily_comments c
    on p.external_video_id = c.external_video_id
    and p.performance_date = c.comment_date