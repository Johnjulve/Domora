import 'package:drift/drift.dart';

/// Table definition for Workspaces.
@DataClassName('WorkspaceEntity')
class Workspaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get workspaceType => text().withDefault(const Constant('personal'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft-deletion timestamp

  @override
  Set<Column> get primaryKey => {id};
}

/// Table definition for Categories (Properties, Vehicles, Appliances, Electronics, etc.).
@DataClassName('CategoryEntity')
@TableIndex(name: 'categories_workspace_name_idx', columns: {#workspaceId, #name})
class Categories extends Table {
  TextColumn get id => text()();
  @ReferenceName('categoriesInWorkspace')
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get iconKey => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Universal table definition for Records.
@DataClassName('RecordEntity')
@TableIndex(name: 'records_workspace_type_idx', columns: {#workspaceId, #recordType})
@TableIndex(name: 'records_deleted_idx', columns: {#deletedAt})
class Records extends Table {
  TextColumn get id => text()();
  @ReferenceName('recordsInWorkspace')
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('recordsInCategory')
  TextColumn get categoryId => text().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get recordType => text()(); // e.g. 'asset', 'task', 'expense', 'bill', 'document'
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft-deletion timestamp

  @override
  Set<Column> get primaryKey => {id};
}

/// Specialized table definition for Assets, linked 1-to-1 to a parent Record.
@DataClassName('AssetEntity')
class Assets extends Table {
  @ReferenceName('assetRecord')
  TextColumn get recordId => text().references(Records, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  IntColumn get purchaseAmountMinor => integer().nullable()(); // Financial integer precision in minor units (e.g. cents)
  TextColumn get purchaseCurrency => text().nullable().withDefault(const Constant('PHP'))();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get condition => text().nullable()();
  TextColumn get locationDescription => text().nullable()();
  TextColumn get acquiredFrom => text().nullable()();
  DateTimeColumn get disposedAt => dateTime().nullable()();
  IntColumn get odometerReading => integer().nullable()(); // Vehicle mileage (e.g. km)
  IntColumn get pmsDistanceIntervalKm => integer().nullable()(); // PMS distance cycle (e.g. 5000 km)
  IntColumn get pmsTimeIntervalMonths => integer().nullable()(); // PMS time cycle (e.g. 3 or 6 months)
  DateTimeColumn get nextPmsDueDate => dateTime().nullable()(); // Next target PMS calendar date
  IntColumn get nextPmsOdometerTarget => integer().nullable()(); // Next target PMS odometer reading (km)

  @override
  Set<Column> get primaryKey => {recordId};
}

/// Specialized table definition for Tasks & Responsibilities, linked 1-to-1 to a parent Record.
@DataClassName('TaskEntity')
@TableIndex(name: 'tasks_status_due_idx', columns: {#status, #dueDate})
class Tasks extends Table {
  @ReferenceName('taskRecord')
  TextColumn get recordId => text().references(Records, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))(); // 'low', 'medium', 'high', 'urgent'
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'in_progress', 'completed', 'cancelled'
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get recurrenceRule => text().nullable()(); // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  @ReferenceName('tasksForAsset')
  TextColumn get assetRecordId => text().nullable().references(Records, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {recordId};
}

/// Specialized table definition for Documents & Attachments, linked 1-to-1 to a parent Record.
@DataClassName('DocumentEntity')
@TableIndex(name: 'documents_linked_asset_idx', columns: {#linkedAssetRecordId})
@TableIndex(name: 'documents_type_idx', columns: {#documentType})
class Documents extends Table {
  @ReferenceName('documentRecord')
  TextColumn get recordId => text().references(Records, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text().nullable()();
  TextColumn get documentType => text().withDefault(const Constant('general'))(); // 'warranty', 'receipt', 'manual', 'deed', 'id', 'general'
  IntColumn get fileSizeBytes => integer().nullable()();
  TextColumn get mimeType => text().nullable()();
  @ReferenceName('documentsForAsset')
  TextColumn get linkedAssetRecordId => text().nullable().references(Records, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {recordId};
}

/// Specialized table definition for Expenses & Maintenance Costs, linked 1-to-1 to a parent Record.
@DataClassName('ExpenseEntity')
@TableIndex(name: 'expenses_asset_idx', columns: {#linkedAssetRecordId})
@TableIndex(name: 'expenses_task_idx', columns: {#linkedTaskRecordId})
@TableIndex(name: 'expenses_bill_idx', columns: {#linkedBillRecordId})
@TableIndex(name: 'expenses_date_idx', columns: {#transactionDate})
class Expenses extends Table {
  @ReferenceName('expenseRecord')
  TextColumn get recordId => text().references(Records, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountMinor => integer()(); // Financial integer precision in minor units (e.g. cents)
  TextColumn get currencyCode => text().withDefault(const Constant('PHP'))();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get paymentMethod => text().nullable()(); // 'cash', 'card', 'bank_transfer', 'e_wallet', 'other'
  TextColumn get expenseCategory => text().withDefault(const Constant('maintenance'))(); // 'maintenance', 'purchase', 'utility', 'service', 'subscription', 'other'
  @ReferenceName('expensesForAsset')
  TextColumn get linkedAssetRecordId => text().nullable().references(Records, #id, onDelete: KeyAction.setNull)();
  @ReferenceName('expensesForTask')
  TextColumn get linkedTaskRecordId => text().nullable().references(Records, #id, onDelete: KeyAction.setNull)();
  @ReferenceName('expensesForBill')
  TextColumn get linkedBillRecordId => text().nullable().references(Records, #id, onDelete: KeyAction.setNull)();
  IntColumn get odometerReading => integer().nullable()(); // Mileage recorded during service

  @override
  Set<Column> get primaryKey => {recordId};
}

/// Specialized table definition for Household Utilities & Bills, linked 1-to-1 to a parent Record.
@DataClassName('BillEntity')
@TableIndex(name: 'bills_status_due_idx', columns: {#paymentStatus, #dueDate})
@TableIndex(name: 'bills_asset_idx', columns: {#linkedAssetRecordId})
class Bills extends Table {
  @ReferenceName('billRecord')
  TextColumn get recordId => text().references(Records, #id, onDelete: KeyAction.cascade)();
  TextColumn get utilityType => text().withDefault(const Constant('utility'))(); // 'electricity', 'water', 'internet', 'rent', 'insurance', 'subscription', 'trash', 'other'
  TextColumn get providerName => text().nullable()(); // e.g. 'Meralco', 'Manila Water', 'PLDT'
  TextColumn get accountNumber => text().nullable()();
  DateTimeColumn get billingPeriodStart => dateTime().nullable()();
  DateTimeColumn get billingPeriodEnd => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get amountDueMinor => integer()(); // Financial integer precision in minor units (e.g. cents)
  TextColumn get currencyCode => text().withDefault(const Constant('PHP'))();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))(); // 'unpaid', 'paid', 'overdue', 'cancelled'
  DateTimeColumn get paidAt => dateTime().nullable()();
  @ReferenceName('billsForAsset')
  TextColumn get linkedAssetRecordId => text().nullable().references(Records, #id, onDelete: KeyAction.setNull)();
  @ReferenceName('billLinkedExpense')
  TextColumn get linkedExpenseRecordId => text().nullable().references(Records, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {recordId};
}
