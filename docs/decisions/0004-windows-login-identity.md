# 0004: The Windows login is the identity

**Context.** Every technician has their own Windows login. We want "who changed this" without extra passwords.

**Decision.** Access links to SQL Server with Windows authentication. Stamps use `ORIGINAL_LOGIN()`. `sec.AppUser` maps logins to display names and roles (Admin / Technician / Viewer).

**Consequences.** Nothing to remember and nothing to share, so stamps can't be faked from the front end. Shared or generic Windows accounts must not be used for SiteBase.
