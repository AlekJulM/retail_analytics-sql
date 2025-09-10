# retail-analytics-sql-
Advanced MySQL-based retail analytics platform. Implements stored routines, optimized queries, JSON parsing, triggers, and common table expressions (CTEs) to support business performance tracking, audit automation, and customer activity analysis across multiple entities.

---

## 📊 Entity Relationship Diagram

### Mermaid (editable)
```mermaid
erDiagram
  Clients ||--o{ Orders : places
  Products ||--o{ Orders : contains
  Employees ||--o{ Orders : processes
  Clients }o--|| Addresses : has
  Employees }o--|| Addresses : has
  Orders ||--o{ Audit : tracks
  Clients ||--o{ Activity : performs
  Clients ||--o{ Notifications : receives

