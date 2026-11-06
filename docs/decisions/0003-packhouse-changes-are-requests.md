# 0003: Packhouse changes are requests, never pushed through

**Context.** Packhouses edit their copies (add rows, fix spellings, even add columns). Pulling their whole file into the master overwrote everyone else's work.

**Decision.** A returned copy is compared row by row with what was published. Every difference becomes an `ops.ChangeRequest`, which a technician approves or rejects. New columns are only flagged.

**Consequences.** The master stays clean and every packhouse change is traceable. Someone has to work the inbox, and packhouse fixes appear on their labels after approval and the next publish.
