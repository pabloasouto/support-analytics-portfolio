-- ============================================================
-- FILE: 04_avg_resolution_time.sql
-- PURPOSE: SLA monitoring and resolution time analysis
-- CONTEXT: Fictional helpdesk database for a SaaS/EdTech company
-- ============================================================

-- TABLE REFERENCE:
--   tickets → id, user_id, category, status, priority, created_at, resolved_at
--   users   → id, name, email, plan


-- -------------------------------------------------------
-- 1. Average resolution time across all resolved tickets
--    (result in hours)
-- -------------------------------------------------------
SELECT
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
        )::NUMERIC, 2
    ) AS avg_resolution_hours
FROM tickets
WHERE status = 'resolved'
  AND resolved_at IS NOT NULL;


-- -------------------------------------------------------
-- 2. Average resolution time by category
--    Identifies which issue types take longest to solve
-- -------------------------------------------------------
SELECT
    category,
    COUNT(*)    AS resolved_tickets,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600)::NUMERIC, 1
    ) AS avg_hours_to_resolve
FROM tickets
WHERE status = 'resolved'
  AND resolved_at IS NOT NULL
GROUP BY category
ORDER BY avg_hours_to_resolve DESC;


-- -------------------------------------------------------
-- 3. Average resolution time by priority
--    Validates whether high-priority tickets are resolved faster
-- -------------------------------------------------------
SELECT
    priority,
    COUNT(*) AS resolved_count,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600)::NUMERIC, 1
    ) AS avg_hours_to_resolve
FROM tickets
WHERE status = 'resolved'
  AND resolved_at IS NOT NULL
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'urgent'  THEN 1
        WHEN 'high'    THEN 2
        WHEN 'medium'  THEN 3
        WHEN 'low'     THEN 4
    END;


-- -------------------------------------------------------
-- 4. SLA breach check — tickets open beyond expected time
--    SLA targets (example):
--      urgent → 4 hours
--      high   → 8 hours
--      medium → 24 hours
--      low    → 72 hours
-- -------------------------------------------------------
SELECT
    id            AS ticket_id,
    user_id,
    subject,
    priority,
    status,
    created_at,
    ROUND(
        EXTRACT(EPOCH FROM (NOW() - created_at)) / 3600
    ) AS hours_open,
    CASE
        WHEN priority = 'urgent' AND NOW() > created_at + INTERVAL '4 hours'   THEN 'BREACHED'
        WHEN priority = 'high'   AND NOW() > created_at + INTERVAL '8 hours'   THEN 'BREACHED'
        WHEN priority = 'medium' AND NOW() > created_at + INTERVAL '24 hours'  THEN 'BREACHED'
        WHEN priority = 'low'    AND NOW() > created_at + INTERVAL '72 hours'  THEN 'BREACHED'
        ELSE 'Within SLA'
    END AS sla_status
FROM tickets
WHERE status = 'open'
ORDER BY
    CASE priority
        WHEN 'urgent' THEN 1
        WHEN 'high'   THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low'    THEN 4
    END,
    created_at ASC;


-- -------------------------------------------------------
-- 5. Weekly resolution time trend
--    Tracks whether team performance is improving over time
-- -------------------------------------------------------
SELECT
    DATE_TRUNC('week', resolved_at)::DATE         AS week_start,
    COUNT(*)                                        AS resolved_tickets,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600)::NUMERIC, 1
    ) AS avg_hours_to_resolve
FROM tickets
WHERE status = 'resolved'
  AND resolved_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE_TRUNC('week', resolved_at)
ORDER BY week_start ASC;
