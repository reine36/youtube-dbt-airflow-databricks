{{ 
    config(
        materialized = 'table',
        schema = 'rva_gold'
    ) 
}}

with video_metrics as (
    select
        video_id,
        video_title,
        video_publish_time,
        comments_added,
        shares,
        dislikes,
        likes,
        subscribers_lost,
        subscribers_gained,
        rpm_usd,
        cpm_usd,
        average_percentage_viewed,
        average_view_duration,
        views as total_views_by_video,
        watch_time_hours,
        subscribers,
        estimated_revenue_usd,
        impressions,
        impressions_click_through_rate
    from {{ ref('stg_aggregated_metrics_by_video') }}
),

performance as (
    select
        external_video_id,
        performance_date,
        video_title as performance_video_title,
        thumbnail_link,
        video_length,
        views as daily_views,
        video_likes_added as daily_likes_added,
        video_dislikes_added as daily_dislikes_added,
        user_subscriptions_added as daily_subscriptions_added,
        user_subscriptions_removed as daily_subscriptions_removed,
        average_view_percentage,
        average_watch_time,
        user_comments_added as daily_comments_added
    from {{ ref('stg_video_performance_over_time') }}
),

country_rollup as (
    select
        external_video_id,
        array_agg(
            struct(
                country_code,
                is_subscribed,
                video_title as country_video_title,
                video_length as country_video_length,
                thumbnail_link as country_thumbnail_link,
                views as country_views,
                video_likes_added as country_likes_added,
                video_dislikes_added as country_dislikes_added,
                video_likes_removed as country_likes_removed,
                user_subscriptions_added as country_subscriptions_added,
                user_subscriptions_removed as country_subscriptions_removed,
                average_view_percentage as country_average_view_percentage,
                average_watch_time as country_average_watch_time,
                user_comments_added as country_comments_added
            )
        ) as country_breakdown
    from {{ ref('stg_aggregated_metrics_by_country_and_subscriber_status') }}
    group by 1
),

daily_comments as (
    select
        external_video_id,
        comment_date,
        count(comment_id) as daily_comment_count,
        sum(like_count) as daily_comment_likes,
        sum(reply_count) as daily_comment_replies
    from {{ ref('stg_all_comments_final') }}
    group by 1, 2
),

final as (
    select
        p.external_video_id,
        v.video_id,
        p.performance_date,
        coalesce(p.performance_video_title, v.video_title) as video_title,
        v.video_publish_time,
        p.thumbnail_link,
        p.video_length,
        v.comments_added,
        v.shares,
        v.dislikes,
        v.likes,
        v.subscribers_lost,
        v.subscribers_gained,
        v.rpm_usd,
        v.cpm_usd,
        v.average_percentage_viewed,
        v.average_view_duration,
        v.total_views_by_video,
        v.watch_time_hours,
        v.subscribers,
        v.estimated_revenue_usd,
        v.impressions,
        v.impressions_click_through_rate,
        c.country_breakdown,
        coalesce(dc.daily_comment_count, 0) as daily_comment_count,
        coalesce(dc.daily_comment_likes, 0) as daily_comment_likes,
        coalesce(dc.daily_comment_replies, 0) as daily_comment_replies,
        p.daily_views,
        p.daily_likes_added,
        p.daily_dislikes_added,
        p.daily_subscriptions_added,
        p.daily_subscriptions_removed,
        p.average_view_percentage,
        p.average_watch_time,
        p.daily_comments_added
    from performance p
    left join video_metrics v
        on v.video_id = p.external_video_id
    left join country_rollup c
        on c.external_video_id = p.external_video_id
    left join daily_comments dc
        on dc.external_video_id = p.external_video_id
        and dc.comment_date = p.performance_date
)

select * from final
