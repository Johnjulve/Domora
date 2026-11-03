# Domora --- Personal Life OS

## Product Vision, Scope, Architecture & MVP Plan

**Document type:** Product and technical planning brief\
**Working product name:** Domora\
**Product category:** Personal Life OS\
**Target platform:** Flutter (mobile-first)\
**Architecture:** Offline-first, local data ownership, optional future
backup/synchronization\
**Status:** Initial product direction --- decisions may be refined
during implementation

------------------------------------------------------------------------

## 1. Executive Summary

Domora is a personal and household platform for organizing everyday
records, possessions, schedules, expenses, documents, and
responsibilities in one connected workspace.

It is intended for individuals and families. It should work reliably
without an internet connection, keep user data locally by default, and
be designed so that optional cloud backup, multi-device synchronization,
and household collaboration can be introduced later.

Domora is not intended to replace every specialized application. Its
purpose is to connect the practical information and responsibilities
that people otherwise scatter across notes, spreadsheets, folders,
calendars, and separate tracking apps.

### Core promise

> Know what you have, what needs attention, what it costs, and what you
> need to do next.

### Product definition

Domora is a local-first, extensible personal information and
responsibility management platform. It combines a flexible record system
with specialized capabilities for assets, tasks, documents, expenses,
bills, events, and household operations.

------------------------------------------------------------------------

## 2. Product Principles

1.  **Capture once, reuse everywhere.** A service receipt can be
    connected to an asset, a maintenance occurrence, and an expense
    without requiring duplicate records.
2.  **Offline-first by default.** Core creation, editing, browsing,
    search, and local reminders must work without an account or network
    connection.
3.  **Flexible, but approachable.** Built-in templates should cover
    common needs. Users can add custom record types, categories, and
    fields without having to design everything themselves.
4.  **Personal by default, household-ready by design.** The initial
    release can be single-user while its data model already supports
    individual and household workspaces.
5.  **Portable user data.** Users must be able to export and restore
    their records and attached files through a documented, versioned
    backup format.
6.  **Modular expansion.** New capabilities should reuse shared records,
    relationships, files, reminders, and expense infrastructure rather
    than creating duplicate systems.
7.  **Reliable history.** Important completed activities and financial
    records should remain understandable even when an asset, task, or
    other record is archived.
8.  **Privacy and user control.** Collect only necessary data, explain
    where files are stored, and make backup and sharing behavior
    explicit.

------------------------------------------------------------------------

## 3. Target Users and Use Cases

### Primary audience

-   Individuals organizing their personal information and
    responsibilities.
-   Families and households managing shared possessions, bills,
    documents, and recurring tasks.

### Representative use cases

-   Register a vehicle, computer, appliance, or other possession.
-   Keep purchase details, serial numbers, condition, location,
    warranty, and related documents.
-   Schedule maintenance and preserve completed service history.
-   Track household bills, due dates, payment status, and recurring
    obligations.
-   Record expenses against the relevant asset, bill, task, or
    responsibility.
-   Store receipts, invoices, manuals, certificates, and other important
    files.
-   Manage one-time and recurring responsibilities.
-   Find related information from one record instead of searching
    several disconnected lists.
-   Eventually share selected records and responsibilities with
    household members.

### Product boundary

**In scope:**

-   Personal and household records
-   Assets and inventory
-   Tasks, events, and recurring responsibilities
-   Maintenance and reminders
-   Documents and attachments
-   Expenses linked to assets and responsibilities
-   Bills and household utilities
-   Custom record types, fields, categories, and labels
-   Basic summaries and insights
-   Local backup and restore

**Not an initial priority:**

-   Full accounting or bookkeeping
-   Direct bank-account integrations
-   A complete project-management suite
-   Social networking or messaging
-   Unlimited cloud file storage
-   Arbitrary user-written scripts or automation
-   AI that autonomously changes user data
-   Real-time multi-user collaboration

------------------------------------------------------------------------

## 4. Product Scope and Release Plan

### 4.1 MVP --- Personal Organizer

The MVP should demonstrate that different kinds of everyday information
can be managed in one connected, offline-capable application.

#### Universal records

-   Create, view, edit, archive, and search records.
-   Built-in record types: asset, task, event, expense, bill, document,
    and note.
-   Custom categories, tags, fields, and supported statuses.
-   Relationships between records.
-   Descriptions, dates, metadata, and activity history.
-   Filtering and sorting.

#### Assets

-   Templates for vehicles, electronics, appliances, furniture, tools,
    and general possessions.
-   Purchase date and price.
-   Brand, model, serial number, and other optional identifying details.
-   Location, condition, and lifecycle status.
-   Links to maintenance, expenses, warranties, and documents.
-   Archive or dispose of assets without destroying their historical
    records.

#### Responsibilities and reminders

-   One-time tasks and recurring schedules.
-   Due dates, priority, status, and completion history.
-   Local notifications.
-   Upcoming and overdue views.
-   Reminders for maintenance, bills, renewals, and custom records.

#### Documents and attachments

-   Attach images, PDFs, receipts, invoices, and other supported files.
-   Keep files on the device in the initial release.
-   Store metadata and relationships in the local database.
-   Link a file to one or more relevant records where appropriate.
-   Include attachments in complete backups.
-   Handle missing files and failed imports gracefully.

#### Expenses

-   Record amount, currency, transaction date, description, and
    category.
-   Link an expense to an asset, task, bill, event, or other
    responsibility.
-   Support standalone expenses only where the product needs them.
-   Provide basic totals and summaries.
-   Avoid becoming a full accounting application in the MVP.

#### Dashboard

-   Today's tasks.
-   Upcoming and overdue responsibilities.
-   Upcoming maintenance and bill deadlines.
-   Recently changed records.
-   Quick-add entry point.
-   Basic expense and record summaries.

#### Data safety

-   Local persistence.
-   Database migrations.
-   Versioned export and restore.
-   Backup validation before restore.
-   Clear warnings for destructive restore operations.
-   No requirement to sign in or connect to the internet for core use.

### 4.2 Release 2 --- Household Management

-   Household utilities and bills.
-   Billing periods, due dates, payment status, and payment history.
-   Recurring household responsibilities.
-   Assignable tasks in preparation for multi-member use.
-   Shared expense summaries.
-   More flexible recurrence rules.
-   More advanced reports and filters.
-   Optional appliance usage and electricity estimates, clearly labeled
    as estimates.

### 4.3 Release 3 --- Connected Households

-   Accounts and household membership.
-   Multiple devices.
-   Shared and private records.
-   Roles and permissions.
-   Cloud synchronization.
-   Attachment upload and download.
-   Conflict handling and deletion propagation.
-   Optional cloud document storage.

### 4.4 Later capabilities

-   Natural-language search.
-   Receipt field extraction.
-   Maintenance suggestions based on user-entered history.
-   More advanced workflow rules.
-   Configurable dashboards.
-   Cross-record insights and reports.
-   Optional integrations with external services.

AI features must be assistive and transparent. They should not silently
alter records or perform consequential actions without user
confirmation.

------------------------------------------------------------------------

## 5. Core Product Modules

### 5.1 Workspaces

A workspace is the ownership and access boundary for records.

Initial workspace types:

-   Personal workspace
-   Household workspace

The MVP may create one personal workspace automatically. The schema
should not assume that every record belongs directly to a single global
user.

### 5.2 Universal Records

The shared record layer provides common identity and metadata.

Examples of records:

-   Vehicle
-   Appliance
-   Maintenance task
-   Appointment or event
-   Electricity bill
-   Expense
-   Warranty document
-   Household chore
-   Note or reference

Not every record should be forced into an asset model. A bill, event, or
responsibility has its own behavior and should be represented
appropriately.

### 5.3 Record Types and Customization

Provide built-in templates and user-defined record types.

Customization should initially support:

-   Custom type name and description
-   Icon or visual identifier
-   Category assignment
-   Custom field definitions
-   Field ordering
-   Required/optional settings
-   Basic validation
-   Supported field types
-   Default values where appropriate

Recommended initial field types:

-   Short text
-   Long text
-   Integer
-   Decimal
-   Date
-   Date and time
-   Boolean
-   Single selection
-   Multiple selection
-   URL
-   Email
-   Phone number
-   Currency or monetary amount, with explicit currency

Custom fields should be versioned. Changing a field definition must not
silently corrupt existing values.

### 5.4 Assets and Inventory

Assets represent possessions or resources that users want to track over
time.

Examples:

-   Vehicles
-   Computers and phones
-   Appliances
-   Furniture
-   Tools
-   Equipment

Asset-specific information may include purchase details, identifying
information, condition, location, warranty, and lifecycle state.

### 5.5 Tasks and Responsibilities

Tasks represent actions that need to be performed.

Examples:

-   Change vehicle oil
-   Pay electricity bill
-   Clean an appliance
-   Renew registration
-   Replace a water filter
-   Complete a household chore

A recurring schedule is not the same as an individual task occurrence.
Preserve the recurrence definition separately from each generated or
completed occurrence.

### 5.6 Events

Events represent things that happen or are planned for a particular
time.

Examples:

-   Appointment
-   Service visit
-   Inspection
-   Purchase
-   Renewal date
-   Household event

Events may be linked to assets, people, expenses, or documents.

### 5.7 Expenses

Expenses represent monetary transactions or costs.

Expenses should be linkable to the records that explain why the cost
exists. Avoid duplicating an expense every time it appears in an asset
or task view.

Store monetary values safely using integer minor units or an equivalent
exact decimal representation. Do not use binary floating-point values
for financial calculations. Store the currency code explicitly; do not
assume every amount is PHP.

### 5.8 Bills and Utilities

Bills represent obligations with billing periods, due dates, amounts
due, and payment state.

Examples:

-   Electricity
-   Water
-   Internet
-   Rent
-   Subscriptions
-   Other recurring household payments

A bill may generate or be associated with an expense when payment is
recorded. Define this relationship carefully to avoid double-counting.

### 5.9 Documents and Attachments

Documents are user-facing records or references. Attachments are the
underlying files.

Examples:

-   Receipt
-   Invoice
-   Warranty
-   Manual
-   Registration document
-   Certificate
-   Photograph

A document record may contain expiration dates, issuer, reference
number, and notes. Its file attachment should be managed separately.

### 5.10 Reminders

Reminders provide notification behavior for tasks, bills, events,
document expirations, and other dated records.

A reminder should refer to the underlying record or schedule. Avoid
creating separate copies of business data inside the notification
subsystem.

### 5.11 Dashboard and Insights

The dashboard is a read-oriented overview assembled from the modules. It
should not become the owner of business data.

Initial sections:

-   Today
-   Upcoming
-   Overdue
-   Recently updated
-   Quick actions
-   Basic spending summaries

------------------------------------------------------------------------

## 6. Data Model and Database Direction

### 6.1 Recommended approach: hybrid structured model

Use strongly structured tables for core entities and behavior, plus
configurable definitions and values for custom fields.

Do **not** store the entire application as arbitrary JSON documents.
That makes important operations such as date filtering, recurring tasks,
expense calculations, relationships, migrations, and future
synchronization harder to maintain.

Use JSON only where it is appropriate for versioned configuration or
flexible metadata, not as a substitute for relational modeling.

### 6.2 Core entities

#### Workspace

Represents a personal or household data space.

Suggested fields:

-   `id`
-   `name`
-   `workspace_type`
-   `created_at`
-   `updated_at`
-   `archived_at`

#### WorkspaceMember

Reserved for future household collaboration.

Suggested fields:

-   `id`
-   `workspace_id`
-   `user_id`
-   `role`
-   `created_at`
-   `updated_at`

The MVP can operate without remote user accounts, but the ownership
model should be ready for membership.

#### Record

The common identity and metadata for a user-managed item.

Suggested fields:

-   `id`
-   `workspace_id`
-   `record_type_id`
-   `category_id`
-   `title`
-   `description`
-   `status`
-   `created_at`
-   `updated_at`
-   `archived_at`
-   `deleted_at` (if using soft deletion)

#### RecordType

Describes a built-in or user-created type.

Suggested fields:

-   `id`
-   `workspace_id` (nullable only for system-defined types, if that
    convention is adopted)
-   `name`
-   `description`
-   `icon_key`
-   `is_system`
-   `schema_version`
-   `created_at`
-   `updated_at`

#### FieldDefinition

Describes a custom field belonging to a record type.

Suggested fields:

-   `id`
-   `record_type_id`
-   `field_key`
-   `label`
-   `data_type`
-   `is_required`
-   `is_searchable`
-   `validation_config`
-   `options_config`
-   `display_order`
-   `created_at`
-   `updated_at`

#### FieldValue

Stores a custom field value for a record.

Suggested fields:

-   `id`
-   `record_id`
-   `field_definition_id`
-   `value_text`
-   `value_integer`
-   `value_decimal`
-   `value_boolean`
-   `value_date`
-   `value_json` (only for supported complex values)
-   `created_at`
-   `updated_at`

Choose one canonical storage strategy after prototyping. Enforce that a
value is stored in the correct typed column for its field definition.
Consider a normalized value representation if the selected database
library makes typed columns cumbersome.

#### RecordRelationship

Connects records through explicit relationship types.

Suggested fields:

-   `id`
-   `workspace_id`
-   `source_record_id`
-   `relationship_type`
-   `target_record_id`
-   `created_at`

Example relationship types:

-   `belongs_to`
-   `maintains`
-   `documents`
-   `has_expense`
-   `related_to`
-   `replaces`
-   `located_at`

Use stable identifiers or a controlled relationship registry rather than
arbitrary, undocumented strings.

### 6.3 Specialized entities

These entities contain behavior that should not be reduced to custom
fields.

#### Asset

-   `record_id` (primary key and relation to Record)
-   `purchase_date`
-   `purchase_amount_minor`
-   `purchase_currency`
-   `brand`
-   `model`
-   `serial_number`
-   `condition`
-   `location_description`
-   `acquired_from`
-   `disposed_at`

Not every asset needs every field. Templates can guide users through
optional details.

#### Task

-   `record_id`
-   `due_at`
-   `priority`
-   `completion_status`
-   `completed_at`
-   `recurrence_rule_id` (nullable)

#### RecurrenceRule

-   `id`
-   `workspace_id`
-   `frequency`
-   `interval`
-   `start_at`
-   `end_at`
-   `timezone`
-   `rule_config`
-   `created_at`
-   `updated_at`

Use a documented recurrence representation. Avoid implementing an
incomplete recurrence engine without defining edge cases such as
month-end dates, daylight-saving changes, missed occurrences, and edits
to future schedules.

#### TaskOccurrence

-   `id`
-   `task_record_id`
-   `scheduled_at`
-   `status`
-   `completed_at`
-   `completion_notes`
-   `created_at`
-   `updated_at`

Preserve completed occurrences as history. Editing a future recurrence
should not rewrite past completions.

#### Expense

-   `record_id`
-   `amount_minor`
-   `currency_code`
-   `transaction_date`
-   `expense_category_id`
-   `payment_method` (optional)
-   `notes`

Use integer minor units or an exact decimal strategy. Currency precision
differs, so do not assume every currency has exactly two decimal places.

#### Bill

-   `record_id`
-   `billing_period_start`
-   `billing_period_end`
-   `due_at`
-   `amount_due_minor`
-   `currency_code`
-   `payment_status`
-   `paid_at` (nullable)

Define whether a bill payment creates an Expense or links to an existing
Expense. Prevent duplicate counting.

#### Event

-   `record_id`
-   `starts_at`
-   `ends_at`
-   `timezone`
-   `location_description`
-   `all_day`

#### Attachment

-   `id`
-   `workspace_id`
-   `file_name`
-   `relative_path`
-   `mime_type`
-   `file_size_bytes`
-   `checksum`
-   `created_at`
-   `deleted_at`

#### RecordAttachment

-   `record_id`
-   `attachment_id`
-   `relationship_label` (optional)
-   `created_at`

This supports one file being associated with multiple records without
duplicating the physical file.

#### Reminder

-   `id`
-   `workspace_id`
-   `record_id` (nullable only for explicitly supported standalone
    reminders)
-   `scheduled_at`
-   `reminder_type`
-   `status`
-   `notification_identifier`
-   `created_at`
-   `updated_at`

#### Category and Tag

Use categories for structured classification and tags for flexible
cross-cutting labels. Support hierarchy for categories only if it
provides a real user benefit.

#### ActivityLog

-   `id`
-   `workspace_id`
-   `record_id` (nullable for workspace-level actions)
-   `action_type`
-   `summary`
-   `occurred_at`
-   `metadata` (versioned and limited)

Activity history should record meaningful actions, not every low-level
database write.

### 6.4 Workspace ownership

Every user-owned record and attachment should have a clear workspace
ownership path.

This is important for future household sharing, exports, deletion, and
access control.

### 6.5 Relationships and deletion

Examples:

  Source             Relationship        Destination
  ------------------ ------------------- ---------------------------
  Motorcycle         `has_maintenance`   Oil change occurrence
  Oil change         `has_expense`       Service expense
  Oil change         `has_attachment`    Receipt
  Refrigerator       `has_document`      Warranty
  Electricity bill   `belongs_to`        Household workspace
  Household task     `assigned_to`       Household member (future)

Deletion behavior must be explicit:

-   Archiving should not remove historical information.
-   Deleting a record must not silently delete unrelated records.
-   Attachments should be deleted only when no records reference them
    and the user has confirmed the action, or according to a documented
    retention policy.
-   Future synchronization requires deletion tombstones so deletes can
    propagate to other devices.

------------------------------------------------------------------------

## 7. Module Boundaries

Organize the Flutter application by business capability, not by screen.

Suggested initial structure:

``` text
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── bootstrap.dart
├── core/
│   ├── database/
│   ├── files/
│   ├── notifications/
│   ├── backup/
│   ├── search/
│   ├── errors/
│   └── common/
├── features/
│   ├── workspaces/
│   ├── records/
│   ├── record_types/
│   ├── assets/
│   ├── tasks/
│   ├── events/
│   ├── expenses/
│   ├── bills/
│   ├── documents/
│   ├── reminders/
│   ├── dashboard/
│   ├── reports/
│   └── settings/
└── shared/
    ├── widgets/
    ├── models/
    └── utilities/
```

A feature may use this internal structure where useful:

``` text
features/assets/
├── data/
│   ├── asset_dao.dart
│   └── asset_repository_impl.dart
├── domain/
│   ├── asset.dart
│   ├── asset_repository.dart
│   └── use_cases/
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/
```

### Layer responsibilities

**Presentation**

-   Screens, widgets, navigation, and UI state.
-   Form interaction and user feedback.
-   No direct SQL or core business rules.

**Domain**

-   Business entities and rules.
-   Use cases such as completing a task, recording a payment, generating
    task occurrences, and calculating ownership costs.
-   Repository interfaces.

**Data**

-   SQLite queries and DAOs.
-   Repository implementations.
-   Model mapping and database migrations.

**Core infrastructure**

-   File storage.
-   Notifications.
-   Backup and restore.
-   Search infrastructure.
-   Shared errors and utilities.
-   Future synchronization interfaces.

Features should communicate through defined interfaces and shared domain
concepts. Avoid importing another feature's private database
implementation.

------------------------------------------------------------------------

## 8. Recommended Flutter Technology Choices

These are initial recommendations, not requirements that must be adopted
without evaluation.

  -----------------------------------------------------------------------
  Concern                             Proposed choice
  ----------------------------------- -----------------------------------
  UI framework                        Flutter

  Language                            Dart

  Local relational database           SQLite

  SQLite integration                  Drift

  State management                    Riverpod

  Navigation                          GoRouter

  Preferences                         SharedPreferences, only for
                                      non-sensitive simple settings

  Local file storage                  App-managed local files with
                                      database metadata

  Notifications                       A maintained Flutter
                                      local-notification package

  Backup                              Versioned archive containing
                                      database export and attachments

  Future backend                      Select after sync requirements and
                                      hosting constraints are defined
  -----------------------------------------------------------------------

### Engineering rules

-   Use database migrations from the beginning.
-   Keep domain rules independent from Flutter widgets and database
    implementation.
-   Use stable IDs generated on the client.
-   Store timestamps consistently and define timezone behavior.
-   Use exact monetary representations, not binary floating point.
-   Use transactions for operations that update multiple related tables.
-   Add indexes for frequently filtered fields and relationship lookups.
-   Avoid premature microservices or unnecessary backend infrastructure.
-   Keep dependencies maintained and review their platform support
    before adoption.

------------------------------------------------------------------------

## 9. Offline-First and Future Synchronization

### 9.1 MVP behavior

The local database is the source of truth.

-   Create and update records locally.
-   Read and search local records.
-   Schedule local reminders.
-   Store attachments locally.
-   Export and restore user data.
-   Do not block core workflows on network availability.

### 9.2 Future sync preparation

Before introducing multi-device synchronization, define:

-   Stable client-generated IDs.
-   `created_at` and `updated_at` timestamps.
-   A deletion tombstone strategy.
-   A local outbox/change queue.
-   Retry and idempotency behavior.
-   Record versioning.
-   Conflict-resolution rules.
-   Workspace membership and server-side authorization.
-   Attachment upload/download state and checksum validation.

A timestamp alone is not a complete conflict-resolution strategy. Two
devices may edit the same record while offline. Some changes can be
merged field by field; others should preserve both versions or ask the
user.

The backend must enforce permissions. Hiding UI controls in Flutter is
not an authorization mechanism.

### 9.3 Backup is not synchronization

Backup creates a recoverable snapshot. Synchronization keeps multiple
active copies aligned.

The MVP should implement backup and restore without pretending that this
is multi-device sync.

Backup requirements:

-   Versioned format.
-   Manifest containing format version and included files.
-   File checksums.
-   Validation before restore.
-   Safe handling of interrupted export/import.
-   Clear restore warnings.
-   A way to verify that attachments are included and readable.

------------------------------------------------------------------------

## 10. Customization Strategy

Implement customization in three levels.

### Level 1 --- Built-in templates (MVP)

Examples:

-   Vehicle
-   Computer
-   Phone
-   Appliance
-   Furniture
-   General asset
-   Task
-   Bill
-   Event
-   Document

### Level 2 --- Custom types and fields (MVP, with controlled limits)

Users can:

-   Create custom record types.
-   Add supported field types.
-   Configure labels and display order.
-   Mark fields required or optional.
-   Configure basic validation.
-   Add categories and tags.

Custom fields must have stable keys and schema versions. Renaming a
label should not change the field's identity.

### Level 3 --- Advanced workflows (later)

Potential capabilities:

-   Custom status transitions.
-   Conditional fields.
-   Rule-based reminders.
-   Automated actions.
-   More advanced recurrence.
-   User-defined workflows.

Do not build a general-purpose workflow scripting engine in the MVP.

------------------------------------------------------------------------

## 11. MVP User Experience

Suggested primary navigation:

1.  **Home** --- overview, upcoming items, overdue responsibilities,
    recent activity.
2.  **Records** --- browse and search all record types.
3.  **Responsibilities** --- tasks, recurring schedules, bills, and
    events.
4.  **Documents** --- files and important document records.
5.  **Insights** --- basic expense and ownership summaries.
6.  **Settings** --- workspace, categories, templates, backup, and
    preferences.

The exact navigation can be tested and adjusted. The underlying feature
boundaries should not depend on this layout.

### Key vertical-slice workflow

The first end-to-end demonstration should be:

1.  Create a personal workspace.
2.  Register a motorcycle as an asset.
3.  Add purchase details.
4.  Attach a receipt or related document.
5.  Create a maintenance schedule.
6.  Complete a maintenance occurrence.
7.  Record the maintenance expense.
8.  Link the expense and receipt to the maintenance record and asset.
9.  View the asset's complete history.
10. Restart the app offline and verify that all information remains
    available.
11. Export a backup and restore it into a clean test environment.

This workflow tests the most important architectural assumptions before
the application grows.

------------------------------------------------------------------------

## 12. Testing and Quality Strategy

Testing is part of implementation, not a final cleanup phase.

### Unit tests

-   Domain validation.
-   Custom field validation.
-   Expense calculations.
-   Recurrence calculations.
-   Status transitions.
-   Relationship rules.
-   Archive and deletion policies.

### Database and repository tests

-   Create, update, archive, and retrieve records.
-   Database constraints and indexes.
-   Transactions involving multiple related entities.
-   Migrations from previous schema versions.
-   Custom field persistence.
-   Relationship integrity.
-   Attachment metadata consistency.

### Feature tests

-   Asset creation and editing.
-   Maintenance scheduling and completion.
-   Expense linking.
-   Document attachment and retrieval.
-   Search and filtering.
-   Reminder scheduling and cancellation.
-   Backup and restore.

### Integration tests

-   Full asset-to-maintenance-to-expense-to-document workflow.
-   App restart and offline persistence.
-   Restore into a clean installation.
-   Handling missing or moved attachment files.
-   Interrupted backup or restore behavior.

### Important acceptance criteria

The MVP is not ready merely because the screens work. It should
demonstrate that:

-   No internet connection is required for core use.
-   Records survive app restarts.
-   Related records remain correctly linked.
-   Historical maintenance and expense data are preserved.
-   Recurring schedules do not rewrite completed history.
-   Custom fields survive edits and app upgrades.
-   Backups can be validated and restored.
-   Invalid or incomplete operations produce understandable errors.

------------------------------------------------------------------------

## 13. Implementation Roadmap

  -----------------------------------------------------------------------
  Stage                   Main deliverable        Exit criterion
  ----------------------- ----------------------- -----------------------
  1\. Foundation          Flutter setup,          Data persists across
                          database, migrations,   restarts and schema
                          workspace IDs, error    upgrades
                          handling                

  2\. Universal records   CRUD, categories,       Different record types
                          templates, custom       can be created and
                          fields, search          retrieved

  3\. Relationships       Record links, assets,   Connected records can
                          expenses, attachments   be navigated without
                                                  duplication

  4\. Responsibilities    Tasks, recurrence,      Due dates and recurring
                          reminders, completion   occurrences behave
                          history                 reliably

  5\. Reliability         Export, backup,         A complete dataset can
                          restore, attachment     be recovered
                          integrity               

  6\. Dashboard           Upcoming, overdue,      Dashboard reflects the
                          recent changes,         underlying records
                          summaries               correctly

  7\. Household expansion Membership,             Multiple devices can
                          permissions, sync       collaborate safely
  -----------------------------------------------------------------------

Build and test one vertical slice before implementing every module. Do
not implement the entire roadmap as one large development task.

------------------------------------------------------------------------

## 14. Risks and Design Decisions to Watch

  -----------------------------------------------------------------------
  Risk                                Mitigation
  ----------------------------------- -----------------------------------
  Universal record model becomes too  Keep specialized entities for
  generic                             behavior-heavy concepts

  Customization becomes a             Limit MVP customization to
  workflow-engine project             templates, fields, categories, and
                                      basic validation

  Relationships become inconsistent   Use typed relationships, foreign
                                      keys, and validation

  Recurrence changes destroy history  Separate recurrence definitions
                                      from task occurrences

  Expenses are double-counted         Define bill-payment and expense
                                      relationships explicitly

  Attachments become orphaned         Track references, checksums, and
                                      safe deletion rules

  Backup is incomplete                Include files, manifest,
                                      validation, and restore tests

  Future sync becomes a rewrite       Use stable IDs, workspace
                                      ownership, timestamps, and
                                      repository boundaries now

  MVP becomes too large               Protect the MVP boundary and defer
                                      collaboration, AI, and advanced
                                      automation
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 15. Naming and Brand Direction

### Working brand: Domora

**Category:** Personal Life OS\
**Suggested tagline:** Your everyday life, organized.

Brand qualities:

-   Reliable
-   Calm
-   Practical
-   Private
-   Adaptable
-   Friendly to individuals and families

The brand should not be limited to maintenance or asset management.
Those are important starting modules, not the whole product.

### Alternative candidates

-   **Lifekit** --- approachable and broad, but likely to face naming
    competition.
-   **Everstead** --- stable and platform-oriented, but less immediately
    descriptive.
-   **LifeLedger** --- strong for records and accountability, but may
    imply finance.

These are creative candidates only. Before committing, check domain
availability, app-store listings, social handles, and relevant trademark
databases in the Philippines and intended markets.

### Suggested naming hierarchy

-   Brand: Domora
-   Product category: Personal Life OS
-   Core areas: Home, Records, Responsibilities, Documents, Household,
    Insights
-   Future synchronization capability: Domora Sync

------------------------------------------------------------------------

## 16. Initial Product Decisions

The following decisions are the current baseline:

  -----------------------------------------------------------------------
  Area                                Decision
  ----------------------------------- -----------------------------------
  Audience                            Individuals and families

  Primary value                       One central place for everyday
                                      responsibilities

  Record scope                        Nearly any everyday record, event,
                                      or responsibility

  Architecture                        Offline-first

  Household support                   Household-ready data model from day
                                      one; sharing later

  Documents                           Local files initially; optional
                                      cloud storage later

  Expenses                            Linked to assets and
                                      responsibilities

  Customization                       Templates plus highly customizable
                                      record types and workflows over
                                      time

  Initial platform                    Flutter

  Local persistence                   SQLite, with Drift as the proposed
                                      integration

  Working product name                Domora

  Long-term direction                 Expandable personal and household
                                      platform
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 17. Immediate Next Steps

Do these in order:

1.  Review and accept the proposed MVP boundary.
2.  Convert the entity list into an initial relational schema.
3.  Define ID, timestamp, deletion, currency, timezone, and relationship
    conventions.
4.  Create the Flutter project and feature structure.
5.  Set up Drift, migrations, and repository boundaries.
6.  Implement workspace creation and universal records.
7.  Build the asset-to-maintenance-to-expense-to-document vertical
    slice.
8.  Add automated tests before expanding the feature set.
9.  Implement backup and restore before treating the MVP as reliable.

### First engineering milestone

> A user can create an asset offline, attach a document, schedule and
> complete maintenance, record its cost, navigate all related
> information, restart the app, and recover the complete dataset from
> backup.

This milestone proves the core of Domora. Everything else should build
on that foundation.

------------------------------------------------------------------------

## 18. Guidance for AI Coding Agents

When using an AI coding agent to implement this project:

-   Read this document before proposing or changing architecture.
-   Inspect the existing repository before creating files or replacing
    conventions.
-   Do not assume the repository is empty.
-   Work in small, reviewable phases.
-   Present the proposed schema and migration plan before implementing
    major data-model changes.
-   Explain trade-offs when deviating from this specification.
-   Do not add dependencies without explaining their purpose and
    maintenance implications.
-   Do not implement cloud synchronization, authentication, AI features,
    or multi-user collaboration during the MVP unless explicitly
    requested.
-   Add tests for business rules and data integrity alongside
    implementation.
-   Never silently discard user data during migrations, resets, or
    restore operations.
-   Update this document when an important product or architecture
    decision changes.

**Definition of done for a feature:** implementation, validation, error
handling, tests, and documentation are complete; data remains consistent
after app restart; and the feature works without network access unless
it explicitly depends on an optional online capability.

------------------------------------------------------------------------

**End of product blueprint.**
