import 'package:domora/core/database/app_database.dart';
import 'package:domora/core/providers/database_providers.dart';
import 'package:domora/features/records/data/record_repository_impl.dart';
import 'package:domora/features/workspaces/data/workspace_repository_impl.dart';
import 'package:domora/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DomoraApp boots into AppShell with 4 primary navigation tabs', (WidgetTester tester) async {
    final inMemoryDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => inMemoryDb.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(inMemoryDb),
          workspaceRepositoryProvider.overrideWithValue(WorkspaceRepositoryImpl(inMemoryDb)),
          recordRepositoryProvider.overrideWithValue(RecordRepositoryImpl(inMemoryDb)),
        ],
        child: const DomoraApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify bottom navigation tabs exist
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);

    // Default tab is Life Records
    expect(find.text('Life Records'), findsOneWidget);
    expect(find.text('No Life Records Yet'), findsOneWidget);

    // Unmount and flush Drift stream cancellation timer
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
