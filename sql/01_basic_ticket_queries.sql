-- ============================================================
-- FILE: 01_basic_ticket_queries.sql
-- PURPOSE: Basic filtering and exploration of a support ticket table
-- CONTEXT: Fictional helpdesk database for a SaaS/EdTech company
-- ============================================================

-- TABLE REFERENCE: tickets
-- Columns: id, user_id, subject, category, status, priority, created_at, updated_at, resolved_at


-- -------------------------------------------------------
-- 1. View all open tickets
-- -------------------------------------------------------
SELECT
    id,
    user_id,
    subject,
    category,
    priority,
    created_at
FROM tickets
WHERE status = 'open'
ORDER BY created_at ASC;


-- -------------------------------------------------------
-- 2. Find all high-priority tickets created in the last 7 days
-- -------------------------------------------------------
SELECT
    id,
    user_id,
    subject,
    status,
    priority,
    created_at
FROM tickets
WHERE priority = 'high'
  AND created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY created_at DESC;


-- -------------------------------------------------------
-- 3. Filter tickets by category (e.g. login issues)
-- -------------------------------------------------------
SELECT
    id,
    user_id,
    subject,
    status,
    created_at
FROM tickets
WHERE category = 'login'
  AND status != 'resolved'
ORDER BY priority DESC, created_at ASC;


-- -------------------------------------------------------
-- 4. Search for tickets containing a keyword in the subject
--    Useful when a user can't provide a ticket ID
-- -------------------------------------------------------
SELECT
    id,
    user_id,
    subject,
    status,
    created_at
FROM tickets
WHERE subject ILIKE '%password reset%'
ORDER BY created_at DESC;


-- -------------------------------------------------------
-- 5. Find tickets that have been open for more than 48 hours
--    without being updated (potential SLA breach)
-- -------------------------------------------------------
SELECT
    id,
    user_id,
    subject,
    priority,
    created_at,
    updated_at,
    EXTRACT(EPOCH FROM (NOW() - updated_at)) / 3600 AS hours_since_last_update
FROM tickets
WHERE status = 'open'
  AND updated_at < NOW() - INTERVAL '48 hours'
ORDER BY hours_since_last_update DESC;
