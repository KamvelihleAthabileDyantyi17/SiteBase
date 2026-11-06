# 0001: SQL Server is the master; files are only for delivery

**Context.** The label data is one Access file per marketer, copied around with Synology Drive. When two people change two copies, one set of changes is lost; Synology creates "conflict" copies; there's no record of who changed what. 7–8 technicians on one network need to edit at the same time.

**Options considered.**
- Split Access database on a network share: cheap, but weaker history and corruption risk.
- **SQL Server 2019 Express (already in-house) with Access screens.** ✔
- Microsoft 365 (SharePoint Lists + Power Apps): needs licences we don't control.
- One-at-a-time check-out lock: simple, but only one editor at a time.
- Merge edited copies with a script: fragile.

**Decision.** The master data lives in SQL Server. Technicians edit through Access screens linked to it. Access files are only produced for delivery to print stations.

**Consequences.** Row-level concurrency, conflict detection and full history come built in (temporal tables). Someone has to look after the server, and Express has no SQL Agent, so scheduling is done by the sync tool.
