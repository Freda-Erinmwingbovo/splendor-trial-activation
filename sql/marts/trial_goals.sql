-- ============================================================
-- Model:      trial_goals
-- Layer:      Marts
-- Author:     Freda Erinmwingbovo
-- Description:
--   Tracks whether each trialling organisation has completed
--   each of the three defined trial goals.
--
--   Goal 1 — Core Scheduling Activation:
--     Organisation creates 5+ shifts within the first 14 days.
--     Rationale: Early shift creation signals genuine product
--     adoption, not just exploratory sign-up behaviour.
--
--   Goal 2 — Multi-Module Engagement:
--     Organisation uses activities from 2+ distinct product
--     modules (Scheduling, Time Tracking, Approvals, Comms).
--     Rationale: Cross-module usage signals the organisation
--     is embedding the platform into real workflows.
--
--   Goal 3 — End-to-End Workflow Completion:
--     Organisation creates at least one shift AND completes
--     a downstream action (approval, punch-in, or schedule view).
--     Rationale: Completing a full workflow loop demonstrates
--     the organisation has experienced the core product value.
--
--   Grain: One row per organisation.
--   Source: stg_events
-- ============================================================

WITH org_base AS (

    -- One row per organisation with core trial metadata
    SELECT
        organization_id,
        MAX(CAST(converted AS INTEGER))     AS converted,
        MIN(trial_start)                    AS trial_start,
        MIN(trial_end)                      AS trial_end,
        MIN(converted_at)                   AS converted_at,
        MIN(days_to_convert)                AS days_to_convert,
        COUNT(*)                            AS total_events,
        COUNT(DISTINCT activity_name)       AS unique_activities,
        COUNT(DISTINCT days_into_trial)     AS active_days

    FROM stg_events
    GROUP BY organization_id

),

-- ── GOAL 1: Core Scheduling Activation ──
-- Count shifts created in first 14 days per org
goal_1 AS (

    SELECT
        organization_id,
        SUM(
            CASE
                WHEN activity_name = 'Scheduling.Shift.Created'
                 AND is_early_trial = 1
                THEN 1 ELSE 0
            END
        )                                   AS shifts_in_first_14_days,

        CASE
            WHEN SUM(
                CASE
                    WHEN activity_name = 'Scheduling.Shift.Created'
                     AND is_early_trial = 1
                    THEN 1 ELSE 0
                END
            ) >= 5
            THEN 1 ELSE 0
        END                                 AS goal_1_met

    FROM stg_events
    GROUP BY organization_id

),

-- ── GOAL 2: Multi-Module Engagement ──
-- Count distinct modules used per org
goal_2 AS (

    SELECT
        organization_id,

        -- Module flags
        MAX(CASE
            WHEN activity_name IN (
                'Scheduling.Shift.Created',
                'Scheduling.Shift.AssignmentChanged',
                'Scheduling.Template.ApplyModal.Applied',
                'Scheduling.OpenShiftRequest.Created',
                'Scheduling.Availability.Set',
                'Mobile.Schedule.Loaded'
            ) THEN 1 ELSE 0
        END)                                AS used_scheduling,

        MAX(CASE
            WHEN activity_name IN (
                'PunchClock.PunchedIn',
                'PunchClock.PunchedOut',
                'PunchClock.Entry.Edited',
                'Break.Activate.Started',
                'Break.Activate.Finished'
            ) THEN 1 ELSE 0
        END)                                AS used_time_tracking,

        MAX(CASE
            WHEN activity_name IN (
                'Scheduling.Shift.Approved',
                'Timesheets.BulkApprove.Confirmed',
                'Absence.Request.Approved',
                'Absence.Request.Rejected'
            ) THEN 1 ELSE 0
        END)                                AS used_approvals,

        MAX(CASE
            WHEN activity_name IN (
                'Communication.Message.Created'
            ) THEN 1 ELSE 0
        END)                                AS used_communications

    FROM stg_events
    GROUP BY organization_id

),

goal_2_scored AS (

    SELECT
        organization_id,
        used_scheduling,
        used_time_tracking,
        used_approvals,
        used_communications,

        -- Total modules used
        (   used_scheduling +
            used_time_tracking +
            used_approvals +
            used_communications
        )                                   AS modules_used,

        -- Goal met if 2 or more modules used
        CASE
            WHEN (
                used_scheduling +
                used_time_tracking +
                used_approvals +
                used_communications
            ) >= 2
            THEN 1 ELSE 0
        END                                 AS goal_2_met

    FROM goal_2

),

-- ── GOAL 3: End-to-End Workflow Completion ──
-- Created a shift AND completed a downstream action
goal_3 AS (

    SELECT
        organization_id,

        MAX(CASE
            WHEN activity_name = 'Scheduling.Shift.Created'
            THEN 1 ELSE 0
        END)                                AS created_shift,

        MAX(CASE
            WHEN activity_name IN (
                'Scheduling.Shift.Approved',
                'PunchClock.PunchedIn',
                'Mobile.Schedule.Loaded'
            ) THEN 1 ELSE 0
        END)                                AS completed_downstream,

        CASE
            WHEN MAX(CASE
                WHEN activity_name = 'Scheduling.Shift.Created'
                THEN 1 ELSE 0 END) = 1
            AND  MAX(CASE
                WHEN activity_name IN (
                    'Scheduling.Shift.Approved',
                    'PunchClock.PunchedIn',
                    'Mobile.Schedule.Loaded'
                ) THEN 1 ELSE 0 END) = 1
            THEN 1 ELSE 0
        END                                 AS goal_3_met

    FROM stg_events
    GROUP BY organization_id

)

-- ── FINAL MART: One row per organisation ──
SELECT
    b.organization_id,
    b.converted,
    b.trial_start,
    b.trial_end,
    b.converted_at,
    b.days_to_convert,
    b.total_events,
    b.unique_activities,
    b.active_days,

    -- Goal 1 details
    g1.shifts_in_first_14_days,
    g1.goal_1_met,

    -- Goal 2 details
    g2.used_scheduling,
    g2.used_time_tracking,
    g2.used_approvals,
    g2.used_communications,
    g2.modules_used,
    g2.goal_2_met,

    -- Goal 3 details
    g3.created_shift,
    g3.completed_downstream,
    g3.goal_3_met,

    -- Goals summary
    (g1.goal_1_met + g2.goal_2_met + g3.goal_3_met) AS goals_completed

FROM org_base          b
LEFT JOIN goal_1       g1 ON b.organization_id = g1.organization_id
LEFT JOIN goal_2_scored g2 ON b.organization_id = g2.organization_id
LEFT JOIN goal_3       g3 ON b.organization_id = g3.organization_id

ORDER BY b.organization_id