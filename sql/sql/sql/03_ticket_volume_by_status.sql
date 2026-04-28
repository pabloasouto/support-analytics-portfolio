-- ============================================================
-- FILE: 03_ticket_volume_by_status.sql
-- PURPOSE: Aggregations and ticket volume reporting
-- CONTEXT: Fictional helpdesk database for a SaaS/EdTech company
-- ============================================================

-- TABLE REFERENCE:
--   tickets → id, user_id, subject, category, status, priority, created_at, resolved_at


-- -------------------------------------------------------
-- 1. Count of tickets by status (snapshot of the queue)
-- -------------------------------------------------------
SELECT
    status,
    COUNT(*) AS total_tickets
FROM tickets
GROUP BY status
ORDER BY total_tickets DESC;


-- -------------------------------------------------------
-- 2. Ticket volume by category
--    Helps identify which topics generate the most demand
-- -------------------------------------------------------
SELECT
    category,
    COUNT(*) AS total_tickets,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM tickets
GROUP BY category
ORDER BY total_tickets DESC;


-- -------------------------------------------------------
-- 3. Tickets opened per day in the last 14 days
--    Useful for spotting volume spikes after deployments
-- -------------------------------------------------------
SELECT
    DATE(created_at)   AS day,
    COUNT(*)           AS tickets_opened
FROM tickets
WHERE created_at >= CURRENT_DATE - INTERVAL '14 days'
GROUP BY DATE(created_at)
ORDER BY day ASC;


-- -------------------------------------------------------
-- 4. Open tickets broken down by priority
-- -------------------------------------------------------
SELECT
    priority,
    COUNT(*) AS open_tickets
FROM tickets
WHERE status = 'open'
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'urgent'  THEN 1
        WHEN 'high'    THEN 2
        WHEN 'medium'  THEN 3
        WHEN 'low'     THEN 4
    END;


-- -------------------------------------------------------
-- 5. Monthly ticket volume — year overview
--    Useful for capacity planning and trend analysis
-- -------------------------------------------------------
SELECT
    TO_CHAR(created_at, 'YYYY-MM') AS month,
    COUNT(*)                        AS total_tickets,
    COUNT(*) FILTER (WHERE status = 'resolved') AS resolved,
    COUNT(*) FILTER (WHERE status = 'open')     AS still_open
FROM tickets
WHERE created_at >= DATE_TRUNC('year', CURRENT_DATE)
GROUP BY TO_CHAR(created_at, 'YYYY-MM')
ORDER BY month ASC;


-- -------------------------------------------------------
-- 6. Top 5 most common ticket subjects (keyword grouping)
--    Helps identify documentation or product gaps
-- -------------------------------------------------------
SELECT
    category,
    COUNT(*) AS frequency
FROM tickets
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY category
ORDER BY frequency DESC
LIMIT 5;
