# Case Study #01 — Login Failure After Password Change

**Category:** Authentication  
**Priority:** High  
**Status:** Resolved  
**Time to Resolution:** ~2 hours 15 minutes

---

## 📥 User Report

> *"Hi, I changed my password yesterday and now I can't log in. I keep getting 'Invalid credentials' even though I'm sure I'm typing it correctly. I've already tried resetting it again and it still doesn't work. I need access urgently."*

— Submitted via support portal, B2B account (Pro plan)

---

## 🔎 Investigation

### Step 1 — Understanding the Problem

The user reports being locked out after a voluntary password change. Key flags:
- Issue started immediately after the password change (likely trigger identified)
- A second password reset was already attempted and failed
- The user is on a Pro plan — higher urgency
- The error message is "Invalid credentials" — this can mean wrong password, account locked, or SSO conflict

I checked whether the account had SSO (Single Sign-On) configured.

### Step 2 — Reproducing the Error

Used an internal test environment to simulate a password change on an SSO-enabled account. Confirmed: when a user with SSO enabled attempts a manual password reset, the system updates the password in the local auth database — but login is still routed through the SSO provider, which holds the original credentials.

The manual password reset does not propagate to the SSO identity provider. This creates a mismatch.

### Step 3 — Verifying Logs and Data

Ran a query to confirm the user's auth configuration:

```sql
SELECT
    u.id,
    u.email,
    u.plan,
    c.sso_enabled,
    c.sso_provider,
    u.last_login_at
FROM users u
JOIN companies c ON u.company_id = c.id
WHERE u.email = 'user@example.com';
```

**Result:** `sso_enabled = true`, `sso_provider = 'google'`

Auth logs confirmed that all login attempts were being routed to the Google SSO flow, not the local password flow.

### Step 4 — Root Cause

The user's company has Google SSO enabled at the account level. The password reset form is accessible to all users but is **only effective for non-SSO accounts**. There was no warning in the UI advising SSO users that manual password changes are not applicable.

This is a **UX gap** — not a user error and not a system bug in the traditional sense. The product should suppress or disable the password change form for SSO users.

---

## ✅ Resolution

**Immediate:** Instructed the user to log in through the Google SSO button instead of the email/password form. Confirmed it worked within minutes.

**User communication:**

> *"Thanks for your patience. I found the cause of the issue: your account uses Google Single Sign-On, which means the email/password form doesn't apply to your login. Please use the 'Continue with Google' button on the login page instead — your access is fully intact. I've also flagged this internally so we can improve the experience for users in the same situation."*

**Internal follow-up:** Logged a product feedback item noting that the password change form should be hidden or include a clear warning for SSO-enabled users. Shared with the product team.

---

## 📝 Lessons / Notes

- Always check SSO configuration before assuming a password issue is a user error
- The second failed password reset was a strong indicator of a configuration mismatch, not a user mistake
- Transparent communication turned a frustrated user into a satisfied one — they thanked the team for the quick resolution and the proactive product note
