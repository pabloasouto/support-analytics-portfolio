# Case Study #03 — Email Notifications Not Being Received

**Category:** Integrations / Notifications  
**Priority:** Medium  
**Status:** Resolved  
**Time to Resolution:** ~3 hours

---

## 📥 User Report

> *"Our team set up email notifications for new course completions last week, but nobody is receiving them. I checked the settings and everything looks configured correctly. We're expecting daily notifications and we've received nothing."*

— Submitted via support portal. Enterprise account (Pro plan), 3 admin users affected.

---

## 🔎 Investigation

### Step 1 — Understanding the Problem

The user has configured an automated notification workflow but emails are not being delivered. Key details:
- The issue has been ongoing for about a week (since setup)
- Multiple users affected (not just one inbox)
- The user believes the settings are correct — which may or may not be accurate

Before investigating the delivery side, I need to confirm whether:
1. The notifications are being **triggered** by the system
2. The notifications are being **sent** by the email service
3. The notifications are being **delivered** to the inbox (or blocked somewhere)

### Step 2 — Reproducing the Error

Simulated a course completion event on a test account with a similar notification rule configured. The notification was triggered and sent correctly — visible in our email service logs.

This suggested the issue was likely in the **configuration** of the user's specific notification rule, not in the notification system itself.

### Step 3 — Verifying Logs and Data

Checked the notification log for the user's account:

```sql
SELECT
    n.id,
    n.event_type,
    n.recipient_email,
    n.status,
    n.error_message,
    n.triggered_at,
    n.sent_at
FROM notification_logs n
JOIN users u ON n.account_id = u.company_id
WHERE u.email = 'admin@clientcompany.com'
  AND n.triggered_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY n.triggered_at DESC;
```

**Result:** Zero records. No notification had been triggered at all in the past 7 days.

This confirmed the issue was **upstream of delivery** — the event trigger was never firing.

Checked the notification rule configuration directly:

```sql
SELECT
    r.id,
    r.event_type,
    r.conditions,
    r.recipient_list,
    r.is_active,
    r.created_at
FROM notification_rules r
JOIN companies c ON r.company_id = c.id
WHERE c.id = 2041;
```

**Result:** `is_active = false`

The notification rule existed but was inactive. The toggle had not been saved correctly during setup.

### Step 4 — Root Cause

The user created the notification rule but did not save it in the active state. The UI showed a toggle that defaults to "off" — the user likely assumed the rule was active after clicking "Save" without toggling it on first.

This is a **configuration issue with a UX contribution**: the inactive default state of new notification rules is not clearly communicated during the setup flow.

---

## ✅ Resolution

**Immediate:** Guided the user to reopen the notification rule, toggle it to active, and save again. Confirmed with the user that a test completion event triggered the notification correctly.

**User communication:**

> *"Good news — I found the issue. The notification rule was created successfully, but it was saved in an inactive state. The toggle needs to be switched on before saving for the rule to start sending. I've walked through where to find this setting below. Once you activate it, notifications should start arriving immediately — could you run a quick test and let me know if you receive it?"*

**Internal note:** Flagged to the product team that the notification rule creation flow should either default to active or make the inactive state more visually prominent. Several similar tickets in the past month suggest this is a recurring confusion point.

**Follow-up:** User confirmed notifications were received within minutes of activating the rule. Ticket closed.

---

## 📝 Lessons / Notes

- When users say "everything looks configured correctly," it's worth verifying — not to doubt the user, but because configuration UX can be misleading
- The log check (zero records in 7 days) immediately narrowed the problem to the trigger level, avoiding a time-consuming investigation of the email delivery layer
- Proactively flagging the UX issue to the product team transforms a one-off ticket into a systemic improvement opportunity — this is the difference between reactive and proactive support
