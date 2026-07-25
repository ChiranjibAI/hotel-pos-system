import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_pos_system/debug/rerun_migration.dart';
import 'package:hotel_pos_system/services/database.dart';
import 'package:hotel_pos_system/services/database_migration_actions.dart';

import '../services/database_test.mocks.dart';

void main() {
  group('DEBUG', () {
    test('Rerun the migration test', () async {
      dbMigrationActions.remove(Database.latestVersion);
      Database.instance.db = MockDatabase();

      rerunMigration();
    });
  });
}
