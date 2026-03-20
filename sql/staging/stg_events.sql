-- ============================================================
-- Model:      stg_events
-- Layer:      Staging
-- Author:     Freda Erinmwingbovo
-- Description:
--   Cleans and standardises the raw event log.
--   Removes duplicate events, casts data types, and derives
--   trial-relative time fields used by all downstream models.
-- ============================================================

WITH raw AS (

    SELECT
        ORGANIZATION_ID                                         AS organization_id,
        ACTIVITY_NAME                                           AS activity_name,
        CAST(TIMESTAMP    AS TIMESTAMP)                         AS event_timestamp,
        CAST(TRIAL_START  AS TIMESTAMP)                         AS trial_start,
        CAST(TRIAL_END    AS TIMESTAMP)                         AS trial_end,
        CAST(CONVERTED    AS BOOLEAN)                           AS converted,
        CAST(CONVERTED_AT AS TIMESTAMP)                         AS converted_at

    FROM raw_events

),

deduplicated AS (

    -- Remove exact duplicate events (same org, activity, timestamp)
    SELECT DISTINCT
        organization_id,
        activity_name,
        event_timestamp,
        trial_start,
        trial_end,
        converted,
        converted_at

    FROM raw

),

with_derived AS (

    SELECT
        organization_id,
        activity_name,
        event_timestamp,
        trial_start,
        trial_end,
        converted,
        converted_at,

        -- Days elapsed from trial start to this event
        CAST(
            JULIANDAY(event_timestamp) - JULIANDAY(trial_start)
        AS INTEGER)                                             AS days_into_trial,

        -- Days from trial start to conversion (NULL if not converted)
        CASE
            WHEN converted_at IS NOT NULL
            THEN CAST(
                JULIANDAY(converted_at) - JULIANDAY(trial_start)
            AS INTEGER)
            ELSE NULL
        END                                                     AS days_to_convert,

        -- Trial duration in days (should always be 30)
        CAST(
            JULIANDAY(trial_end) - JULIANDAY(trial_start)
        AS INTEGER)                                             AS trial_duration_days,

        -- Flag: did this event occur in the first half of the trial?
        CASE
            WHEN CAST(
                JULIANDAY(event_timestamp) - JULIANDAY(trial_start)
            AS INTEGER) <= 14
            THEN 1 ELSE 0
        END                                                     AS is_early_trial

    FROM deduplicated

    -- Only include events within the valid trial window
    WHERE event_timestamp >= trial_start
      AND event_timestamp <= trial_end

)

SELECT * FROM with_derived