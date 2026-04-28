# Case Study #02 — Analytics Report Not Loading

**Category:** Performance / Data  
**Priority:** Medium  
**Status:** Resolved (Escalated to Engineering)  
**Time to Resolution:** 1 business day

---

## 📥 User Report

> *"The monthly report page is just spinning and never loads. It's been like this since this morning. I need to export the data for a meeting tomorrow."*

— Submitted via live chat, then converted to ticket. SMB account (Basic plan).

---

## 🔎 Investigation

### Step 1 — Understanding the Problem

The user is experiencing a loading failure on a specific page (monthly analytics report). Key context:
- Started "this morning" — possible correlation with a deployment or scheduled job
- The user has a time-sensitive need (meeting tomorrow)
- The issue is scoped to one specific page — not a full platform outage

First, I checked our internal status dashboard: no active incidents were reported.

### Step 2 — Reproducing the Error

Logged in with a test account on the same plan (Basic) and navigated to the monthly report page. The page loaded after approximately 40 seconds — very slow, but not fully broken.

Tried with an account that had a larger dataset: the page timed out completely after 60 seconds and returned a blank screen.

This suggested the issue was **data-volume dependent** — the query behind the report was taking too long to complete for accounts with larger datasets.

### Step 3 — Verifying Logs and Data

Checked application logs for the relevant endpoint:

```
[ERROR] Query timeout: /api/reports/monthly — execution_time: 62.3s — user_id: 8842
[ERROR] Query timeout: /api/reports/monthly — execution_time: 61.9s — user_id: 10031
[WARN]  Slow query detected: /api/reports/monthly — execution_time: 38.2s — user_id: 5514
```

Multiple users were hitting the same endpoint with timeout errors. This was not isolated to one account.

Checked the user's account size:

```sql
SELECT
    u.id,
    u.email,
    COUNT(e.id) AS total_events
FROM users u
JOIN events e ON e.user_id = u.id
WHERE u.email = 'user@example.com'
GROUP BY u.id, u.email;
```

**Result:** 487,000 event records — significantly above the typical account on this plan.

### Step 4 — Root Cause

A recent backend deployment introduced a change to the monthly report query that removed a previously used index on the `events` table. For accounts with large datasets, this caused full table scans, leading to timeouts.

This is a **product bug introduced by a deployment**.

---

## ✅ Resolution

**Immediate (user-facing):** Communicated the issue clearly and provided a workaround — the user could export data in weekly date ranges instead of the full month, which completed without timeout.

**User communication:**

> *"I've identified the cause of the issue — there's a performance problem affecting the monthly report for accounts with larger datasets, and our engineering team is already working on a fix. In the meantime, you can access your data by filtering it week by week using the custom date range option — this should work fine for your meeting tomorrow. I'll follow up as soon as the full report is restored."*

**Escalation note sent to engineering:**

> **Issue:** Monthly report endpoint timing out for high-volume accounts.  
> **Affected endpoint:** `GET /api/reports/monthly`  
> **Observed:** Query execution time >60s for accounts with 400k+ events. Timeout errors logged for user IDs 8842, 10031, and others.  
> **Suspected cause:** Index regression from today's deployment (see events table, `created_at` index).  
> **Workaround available:** Weekly date range filtering works correctly.  
> **User impact:** At least 3 confirmed, likely broader. Suggested priority: high.

**Resolution:** Engineering confirmed the index regression and deployed a fix within the same business day. Full monthly report was restored by end of day.

---

## 📝 Lessons / Notes

- When a page stops working after "this morning," always check if there was a deployment — timing is often the first clue
- Reproducing with different account sizes quickly revealed the data-volume dependency
- Offering a workaround kept the user unblocked while engineering fixed the root cause — this is the balance between urgency and thoroughness
- The escalation note gave engineering exactly what they needed: the endpoint, the log evidence, the suspected cause, and the impact scope
