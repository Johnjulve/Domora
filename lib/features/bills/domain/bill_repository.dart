import '../../expenses/domain/expense_item.dart';
import '../../records/domain/record.dart';
import 'bill_item.dart';

/// Contract for Household Utilities & Recurring Bills operations.
abstract class BillRepository {
  /// Atomically creates a universal [Record] with linked specialized [BillItem].
  Future<RecordWithBill> createBillRecord({
    required Record record,
    required BillItem bill,
  });

  /// Updates existing bill record and metadata.
  Future<RecordWithBill> updateBillRecord({
    required Record record,
    required BillItem bill,
  });

  /// Atomically marks a bill as paid and executes the transactional bridge:
  /// creates a linked [Expense] record, annotates late manual payments, and
  /// advances recurring bills to the next upcoming cycle.
  Future<RecordWithBill> markBillAsPaid({
    required String billRecordId,
    required DateTime paidAt,
    String? paymentMethod,
  });

  /// Atomically auto-logs all due cycles for active recurring bills with
  /// `autoLogPayment == true`, returning the total number of newly logged cycles.
  Future<int> processDueSubscriptions(String workspaceId, {DateTime? now});

  /// Pauses a recurring bill/subscription without losing its recurrence settings.
  Future<RecordWithBill> pauseSubscription(String billRecordId);

  /// Cancels a recurring bill/subscription and disables auto-logging.
  Future<RecordWithBill> cancelSubscription(String billRecordId);

  /// Resumes a paused or cancelled bill/subscription without back-charging missed cycles.
  Future<RecordWithBill> resumeSubscription({
    required String billRecordId,
    DateTime? nextDueDate,
    bool? autoLogPayment,
  });

  /// Watches active linked payment expenses for [billRecordId], newest first.
  Stream<List<RecordWithExpense>> watchPaymentHistoryForBill(String billRecordId);

  /// Fetches a single bill record by universal record ID.
  Future<RecordWithBill?> getBillById(String recordId);

  /// Reactive stream of bills in the workspace with optional status/type filter.
  Stream<List<RecordWithBill>> watchBillsByWorkspace(
    String workspaceId, {
    String? paymentStatus,
    String? utilityType,
  });

  /// Reactive stream of upcoming unpaid bills due within the specified [window] or overdue.
  Stream<List<RecordWithBill>> watchUpcomingBillsByWorkspace(
    String workspaceId, {
    Duration window = const Duration(days: 30),
  });

  /// Reactive stream calculating total unpaid obligations in minor units.
  Stream<int> watchTotalUnpaidBillsAmount(String workspaceId);

  /// Soft-deletes a bill record.
  Future<void> softDeleteBillRecord(String recordId);
}
