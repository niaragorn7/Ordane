# Domain definition

Customer has one or more Opportunities.

Opportunity has one or more Quotes.

Quote has one or more Quote Items.

Each Quote Item references one Product and specifies a quantity.

Each quote is converted into an order, one order per quote.

Approval will be included as a simulation for this one to keep statuses consistent. 

--------------------
## Entities
Customer
Opportunity
Quote
QuoteItem
Product
Order
OrderItem

With their relationships:
Customer
  └── Opportunity
        └── Quote
              └── QuoteItem ──→ Product
              └── Order
                    └── OrderItem ──→ Product

---------------------

## Data Model

Customer
- id (UUIDv7)
- name
- created_at
- updated_at

Opportunity
- id (UUIDv7)
- customer_id
- name
- created_at
- updated_at

Quote
- id (UUIDv7)
- opportunity_id
- status
- total_price
- created_at
- updated_at
- rejection_reason

QuoteItem
- id
- quote_id
- product_id
- quantity
- unit_price (nullable)
- created_at
- updated_at

Product
- id (UUIDv7)
- name
- price
- created_at
- updated_at

Order
- id (UUIDv7)
- quote_id
- status
- created_at
- updated_at

OrderItem
- id (UUIDv7)
- order_id
- product_id
- quantity
- unit_price
- created_at
- updated_at

## Pricing

QuoteItem.unit_price represents the price agreed for that quote, 

Quote.total_price is derived from its QuoteItems:

total_price = Σ(quantity × unit_price)

Product.price represents the current catalog price and is not used to recalculate existing quotes.

Salesforce
Customer
   ↓
Opportunity
   ↓
Quote
   ↓
Quote Items
   ├── Product
   └── Quantity
          ↓
         AWS
          ↓
   Pricing / availability
          ↓
Salesforce receives result

So for V1:
- No PriceList, nor PriceListItem, nor complex pricing rules.
- QuoteItems can have a product and quantity, without pricing.
- AWS is responsible for determining the actual price.
- Salesforce receives the resulting pricing.
- Pricing becomes a proper domain in V2.

---------------------

## Relationship
+ Customer 1 ── N Opportunity

+ Opportunity 1 ── N Quote

+ Quote 1 ── N QuoteItem

+ Product 1 ── N QuoteItem

+ Quote 1 ── 1 Order

+ Order 1 ── N OrderItem

---------------------

## Statuses

Quote 
- Draft (not yet submitted)
    Fully editable
- Pending Approval [sync in progress] (when submitted)
    Not editable, can be cancelled using a button
- Approved (automatically be send to AWS)
    Not editable
- Accepted (When AWS sends back info)
    Not editable
- Rejected (with comments)
    Similar to Draft, can be edited and resubmitted for approval.

Order
- Draft (order not fully completed)
- Submitted (to AWS)
- Confirmed (response from AWS)
- Completed (fulfilled)
- Failed (AWS failure)
- Cancelled

---------------------
## O2C Rules

### Ownership
Salesforce owns Customer, Opportunity, Quote (header and status) and the approval workflow.
Ordane owns Product, QuoteItem, Order, OrderItem, order lifecycle, and pricing/availability
processing. Ordane uses UUIDv7 identifiers; Salesforce stores the matching Ordane IDs.

### Quote flow
1. A Quote is created in Salesforce as Draft. QuoteItems (product + quantity, no price)
   are added and fully editable.
2. Submit (Draft → Pending Approval) requires at least one QuoteItem. While pending, the
   Quote is not editable but can be cancelled (Pending Approval → Draft).
3. The simulated approval resolves to Approved or Rejected.
4. Rejected carries a rejection reason. The Quote returns to Draft, is edited per the
   reason, and is resubmitted, which re-runs approval.
5. Approved means approved and awaiting AWS. The QuoteItems are sent to AWS for pricing
   and availability.
6. If AWS confirms availability, unit prices are populated, total_price is derived, and
   the Quote becomes Accepted. If not, the Quote becomes Rejected with the AWS reason.

### Order flow
1. An Order can only be created from an Accepted Quote, from within the Quote. It starts
   as Draft. A Quote has at most one active (non-Cancelled) Order.
2. Order quantities must equal Quote quantities (no partials in V1). OrderItems copy
   product, quantity and unit_price from the Quote (operational snapshot).
3. Submit (Draft → Submitted) sends the Order to AWS. A 201 Created response moves it to
   Confirmed; an AWS error moves it to Failed. Failed → Submitted is a retry.
4. Confirmed → Completed on fulfilment. Draft, Submitted, Confirmed and Failed Orders
   can be Cancelled. Completed and Cancelled are terminal.

### Quote changes after Order generation
- Order in Draft: update or regenerate it from the Quote.
- Order in Submitted or Confirmed: cancel it, revise the Quote, and generate a new Order
  so synchronization runs again.
- The Quote is the commercial source of truth; the Order is the operational snapshot.

### Status Transitions
Quote
  Draft → Pending Approval
  Pending Approval → Draft (cancelled)
  Pending Approval → Approved
  Pending Approval → Rejected
  Approved → Accepted
  Approved → Rejected
  Rejected → Draft
  Accepted → Draft (revision)

Order
  Draft → Submitted
  Draft → Cancelled
  Submitted → Confirmed
  Submitted → Failed
  Submitted → Cancelled
  Failed → Submitted
  Failed → Cancelled
  Confirmed → Completed
  Confirmed → Cancelled

---------------------

## Core Invariants

- An Opportunity must belong to a Customer.
- A Quote must belong to an Opportunity.
- A Quote must contain at least one QuoteItem.
- A QuoteItem must reference exactly one Product.
- An Order can only be generated from an Accepted Quote.
- A Quote can generate only one Order.
- An Order must contain at least one OrderItem.
- An OrderItem must reference exactly one Product.
- Order quantity cannot exceed the quantity defined by the Quote.
- Invalid status transitions must be rejected.
- Completed or Cancelled Orders cannot transition to another status.
- Every order must fulfill the complete quantity specified in the quote, no remaining could be left, meaning order quantity must equal quote quantity (at least on V1).

--------------------

## Boundaries for Version 1 (V1)

V1 focuses exclusively on the core B2B quote-to-order flow.

### Included

- Customer management
- Opportunity management
- Product catalog
- Quote creation and management
- Quote Items and pricing
- Quote approval simulation
- AWS inventory availability check
- Order generation from an Accepted Quote
- Order Items
- Order submission and status tracking
- Salesforce ↔ AWS integration

### Out of Scope

- Partial orders
- Multiple Orders per Quote
- Inventory management
- Manufacturing
- Logistics and fulfillment management
- Automated approval workflows
- Advanced pricing
- Analytics and reporting
- Mobile application
- Machine learning / AI