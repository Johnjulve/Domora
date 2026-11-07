import 'package:flutter_test/flutter_test.dart';
import 'package:domora/features/records/domain/record.dart';
import 'package:domora/features/expenses/domain/expense_item.dart';
import 'package:domora/features/vault/domain/document_item.dart';

void main() {
  group('Service History & Vault File Domain Tests', () {
    test('ExpenseItem preserves odometer reading and service metadata', () {
      final now = DateTime.now();
      final expense = ExpenseItem(
        recordId: 'rec-exp-1',
        amountMinor: 350000,
        currencyCode: 'PHP',
        transactionDate: now,
        expenseCategory: 'maintenance',
        linkedAssetRecordId: 'asset-car-1',
        odometerReading: 15000,
      );

      expect(expense.odometerReading, 15000);
      expect(expense.linkedAssetRecordId, 'asset-car-1');
      expect(expense.expenseCategory, 'maintenance');

      final copy = expense.copyWith(odometerReading: 20000);
      expect(copy.odometerReading, 20000);
      expect(copy.amountMinor, 350000);
    });

    test('DocumentItem preserves filePath and formats file size accurately', () {
      const doc = DocumentItem(
        recordId: 'rec-doc-1',
        fileName: 'vehicle_registration.pdf',
        filePath: '/data/user/0/com.domora/app_flutter/vault/vehicle_registration.pdf',
        documentType: 'deed',
        fileSizeBytes: 2048 * 1024,
        mimeType: 'application/pdf',
        linkedAssetRecordId: 'asset-car-1',
      );

      expect(doc.filePath, contains('vehicle_registration.pdf'));
      expect(doc.formattedFileSize, '2.0 MB');
      expect(doc.documentType, 'deed');
      expect(doc.linkedAssetRecordId, 'asset-car-1');
    });

    test('RecordWithAsset maintains PMS interval parameters', () {
      final now = DateTime.now();
      final record = Record(
        id: 'asset-car-1',
        workspaceId: 'ws-1',
        recordType: 'asset',
        title: 'Toyota Fortuner',
        createdAt: now,
        updatedAt: now,
      );

      final asset = Asset(
        recordId: 'asset-car-1',
        odometerReading: 15000,
        pmsDistanceIntervalKm: 5000,
        pmsTimeIntervalMonths: 6,
        nextPmsOdometerTarget: 20000,
        nextPmsDueDate: DateTime(now.year, now.month + 6, now.day),
      );

      final item = RecordWithAsset(record: record, asset: asset);
      expect(item.asset?.odometerReading, 15000);
      expect(item.asset?.pmsDistanceIntervalKm, 5000);
      expect(item.asset?.nextPmsOdometerTarget, 20000);
    });
  });
}
