-- ============================================================
-- Model:      trial_activation
-- Layer:      Marts
-- Author:     Freda Erinmwingbovo
-- Description:
--   Tracks which organisations have achieved full Trial
--   Activation by completing all three trial goals.
--
--   Trial Activation is defined as:
--     Goal 1 AND Goal 2 AND Goal 3 all met.
--
--   This model is the single source of truth for activation
--   status. It is designed to be joined to any org-level
--   table for filtering, segmentation, or reporting.
--
--   Key metrics surfaced:
--     - activated:        Binary activation flag (1/0)
--     - goals_completed:  Count of goals met (0-3)
--     - activation_tier:  Descriptive tier label
--     - days_to_convert:  For converters, how long it took
--
--   Grain: One row per organisation.
--   Source: trial_goals (mart)
-- ============================================================

WITH activation_base AS (

    SELECT
        organization_id,
        converted,
        trial_start,
        trial_end,
        converted_at,
        days_to_convert,
        total_events,
        unique_activities,
        active_days,
        goals_completed,
        goal_1_met,
        goal_2_met,
        goal_3_met,

        -- Trial Activation flag
        CASE
            WHEN goal_1_met = 1
             AND goal_2_met = 1
             AND goal_3_met = 1
            THEN 1 ELSE 0
        END                             AS activated

    FROM trial_goals

),

with_tiers AS (

    SELECT
        *,

        -- Activation tier for product team reporting
        CASE
            WHEN activated = 1
                THEN 'Fully Activated'
            WHEN goals_completed = 2
                THEN 'Nearly Activated (2/3 Goals)'
            WHEN goals_completed = 1
                THEN 'Partially Activated (1/3 Goals)'
            ELSE
                'Not Activated (0/3 Goals)'
        END                             AS activation_tier,

        -- Conversion timing bucket
        CASE
            WHEN converted = 0
                THEN 'Not Converted'
            WHEN days_to_convert <= 7
                THEN 'Week 1'
            WHEN days_to_convert <= 14
                THEN 'Week 2'
            WHEN days_to_convert <= 21
                THEN 'Week 3'
            WHEN days_to_convert <= 30
                THEN 'Week 4'
            ELSE
                'Post-Trial'
        END                             AS conversion_timing_bucket,

        -- Engagement intensity bucket
        CASE
            WHEN active_days = 1
                THEN 'Single Day'
            WHEN active_days BETWEEN 2 AND 3
                THEN 'Early Dropout'
            WHEN active_days BETWEEN 4 AND 7
                THEN 'Moderate Engagement'
            ELSE
                'High Engagement'
        END                             AS engagement_bucket

    FROM activation_base

)

SELECT
    -- Identity
    organization_id,

    -- Activation status
    activated,
    activation_tier,
    goals_completed,
    goal_1_met,
    goal_2_met,
    goal_3_met,

    -- Conversion
    converted,
    converted_at,
    days_to_convert,
    conversion_timing_bucket,

    -- Trial metadata
    trial_start,
    trial_end,

    -- Engagement
    total_events,
    unique_activities,
    active_days,
    engagement_bucket

FROM with_tiers

ORDER BY
    activated       DESC,
    goals_completed DESC,
    organization_id ASC
