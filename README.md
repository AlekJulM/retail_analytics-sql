# retail-analytics-sql-
Advanced MySQL-based retail analytics platform. Implements stored routines, optimized queries, JSON parsing, triggers, and common table expressions (CTEs) to support business performance tracking, audit automation, and customer activity analysis across multiple entities.

---

## 📊 Entity Relationship Diagram

### Mermaid (editable)
```mermaid
erDiagram
  Clients {
    string ClientID
    string FullName
    int ContactNumber
    int AddressID
  }
  Addresses {
    int AddressID
    string Street
    string County
  }
  Employees {
    int EmployeeID
    string FullName
    string JobTitle
    string Department
    int AddressID
  }
  Products {
    string ProductID
    string ProductName
    float BuyPrice
    float SellPrice
    int NumberOfItems
    string Category
  }
  Orders {
    int OrderID
    string ClientID
    string ProductID
    int EmployeeID
    int Quantity
    float Cost
    date Date
  }
  Activity {
    int ActivityID
    string ClientID
    string ProductID
    string Properties
    string ActivityType
    datetime CreatedAt
  }
  Audit {
    int AuditID
    int OrderID
    string Action
    string OldValues
    string NewValues
    datetime CreatedAt
  }
  Notifications {
    int NotificationID
    string ClientID
    string Message
    string Type
    boolean IsRead
    datetime CreatedAt
  }

  Clients ||--o{ Orders : places
  Products ||--o{ Orders : contains
  Employees ||--o{ Orders : processes
  Clients }o--|| Addresses : has
  Employees }o--|| Addresses : has
  Orders ||--o{ Audit : tracked_in
  Clients ||--o{ Activity : performs
  Products ||--o{ Activity : browsed
  Clients ||--o{ Notifications : receives
```


