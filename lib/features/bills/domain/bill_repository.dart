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
  /// creates a linked [Expense] record with category 'utility' and links both records.
  Future<RecordWithBill> markBillAsPaid({
    required String billRecordId,
    required DateTime paidAt,
    String? paymentMethod,
  });

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
