-- ============================================================
-- FILE: 02_joins_users_tickets.sql
-- PURPOSE: Connecting user and ticket data across tables
-- CONTEXT: Fictional helpdesk database for a SaaS/EdTech company
-- ============================================================

-- TABLE REFERENCE:
--   users   → id, name, email, plan, created_at, company_id
--   tickets → id, user_id, subject, category, status, priority, created_at, resolved_at
--   logs    → id, user_id, ticket_id, action, performed_at


-- -------------------------------------------------------
-- 1. Get ticket details together with user information
--    Useful for quick context before responding to a user
-- -------------------------------------------------------
SELECT
    t.id             AS ticket_id,
    u.name           AS user_name,
    u.email          AS user_email,
    u.plan           AS subscription_plan,
    t.subject,
    t.category,
    t.status,
    t.priority,
    t.created_at
FROM tickets t
JOIN users u ON t.user_id = u.id
WHERE t.status = 'open'
ORDER BY t.created_at ASC;


-- -------------------------------------------------------
-- 2. Find all tickets from users on the Free plan
--    Helpful when checking if an issue is plan-related
-- -------------------------------------------------------
SELECT
    t.id             AS ticket_id,
    u.name           AS user_name,
    u.plan,
    t.subject,
    t.category,
    t.status
FROM tickets t
JOIN users u ON t.user_id = u.id
WHERE u.plan = 'free'
  AND t.status != 'resolved'
ORDER BY t.created_at DESC;


-- -------------------------------------------------------
-- 3. See the action history (logs) for a specific ticket
--    Useful for audit trail and escalation context
-- -------------------------------------------------------
SELECT
    l.performed_at,
    u.name     AS performed_by,
    l.action
FROM logs l
JOIN users u ON l.user_id = u.id
WHERE l.ticket_id = 1042   -- replace with target ticket ID
ORDER BY l.performed_at ASC;


-- -------------------------------------------------------
-- 4. Find users who opened more than 3 tickets in 30 days
--    May indicate a recurring issue or frustrated customer
-- -------------------------------------------------------
SELECT
    u.id,
    u.name,
    u.email,
    u.plan,
    COUNT(t.id) AS ticket_count
FROM tickets t
JOIN users u ON t.user_id = u.id
WHERE t.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY u.id, u.name, u.email, u.plan
HAVING COUNT(t.id) > 3
ORDER BY ticket_count DESC;


-- -------------------------------------------------------
-- 5. Full context query: open tickets with user info and
--    the most recent log action recorded
-- -------------------------------------------------------
SELECT
    t.id             AS ticket_id,
    u.name           AS user_name,
    u.email,
    u.plan,
    t.subject,
    t.status,
    t.priority,
    t.created_at     AS ticket_opened,
    last_log.action  AS last_action,
    last_log.performed_at AS last_action_at
FROM tickets t
JOIN users u ON t.user_id = u.id
LEFT JOIN LATERAL (
    SELECT action, performed_at
    FROM logs
    WHERE ticket_id = t.id
    ORDER BY performed_at DESC
    LIMIT 1
) last_log ON true
WHERE t.status IN ('open', 'pending')
ORDER BY t.priority DESC, t.created_at ASC;
