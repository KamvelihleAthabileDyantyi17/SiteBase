# 0005: No live Synology during development

**Context.** Print stations read their database through Synology Drive. A mistake there prints wrong labels on export fruit.

**Decision.** Until the pilot (Stage 6), SiteBase reads only **copies** of live databases and writes only to a separate test folder. Nothing is written under the Synology Drive folders.

**Consequences.** Testing needs test copies and a test BarTender template. Going live is a deliberate, separate step with the old database kept as a fallback.
