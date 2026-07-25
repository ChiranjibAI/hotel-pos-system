import 'package:hotel_pos_system/services/database.dart';

void rerunMigration() async {
  await Database.execMigrationAction(Database.instance.db, Database.latestVersion);
}
