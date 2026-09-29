# Ordane

Ordane is a portfolio project: a B2B order-management platform built as an evolving system rather than a single deliverable, moving from a standalone backend to an integrated, cloud-deployed platform.

## Systems

- **Business Application** — Salesforce (Apex, LWC, automation) — customer-facing front end for order submission and tracking
- **Backend Platform** — Go, Gin, PostgreSQL — owns the order domain and acts as the system of record
- **Mobile Application** — iOS (Swift) — native client consuming the backend API

```mermaid
flowchart LR

    USER[Business Users]

    SF[Salesforce<br/>Business Application]

    OR[Ordane<br/>Go API]

    DB[(PostgreSQL)]

    AWS[AWS<br/>Pricing & Processing]

    USER --> SF
    SF -->|API| OR
    OR --> DB
    OR -->|Processing| AWS
    AWS -->|Results| OR
    OR -->|Status / Data| SF
```

## Project Stages

1. **Order Management Core** — Domain model: customers, products, orders, order lifecycle
2. **Backend Platform** — Go API, business rules, PostgreSQL persistence
3. **Business Application** — Salesforce customer and order management
4. **System Integration** — Salesforce ↔ API integration
5. **Cloud Deployment** — AWS, containers, CI/CD, monitoring
6. **Asynchronous Processing** — Events, queues, workers, retries
7. **Mobile Application** — Native iOS client
8. **Analytics Platform** — Reporting and analytical workloads

```mermaid
flowchart LR

    V1[V1<br/>Order Management]
    V2[V2<br/>Commercial & Order Capabilities]
    V3[V3<br/>Analytics & Platform]

    V1 --> V2 --> V3
```

## Repository

- `docs/architecture/` — Architecture decisions, diagrams, domain documentation
- `evolution/` — Project evolution and milestones
- `proposals/` — Proposed features and architectural changes