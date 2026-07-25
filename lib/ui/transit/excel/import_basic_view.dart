import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/style/snackbar.dart';
import 'package:hotel_pos_system/models/xfile.dart';
import 'package:hotel_pos_system/translator.dart';
import 'package:hotel_pos_system/ui/transit/exporter/excel_exporter.dart';
import 'package:hotel_pos_system/ui/transit/formatter/field_formatter.dart';
import 'package:hotel_pos_system/ui/transit/formatter/formatter.dart';
import 'package:hotel_pos_system/ui/transit/previews/preview_page.dart';
import 'package:hotel_pos_system/ui/transit/widgets.dart';

class ImportBasicHeader extends ImportBasicBaseHeader {
  final ExcelExporter exporter;

  const ImportBasicHeader({
    super.key,
    required super.selected,
    required super.stateNotifier,
    required super.formatter,
    super.icon = const Icon(Icons.file_present_sharp),
    super.allowAll = true,
    super.logName = 'csv',
    this.exporter = const ExcelExporter(),
  });

  @override
  String get label => S.transitImportBtnExcel;

  @override
  Future<PreviewFormatter?> onImport(BuildContext context) async {
    final input = await XFile.pick();
    if (input == null) {
      // ignore: use_build_context_synchronously
      showSnackBar(S.transitImportErrorExcelPickFile, context: context);
      return null;
    }

    final excel = exporter.decode(input);
    return (FormattableModel able) {
      final data = exporter.import(excel, able.l10nName);

      if (data == null) {
        return null;
      }

      return findFieldFormatter(able).format(data);
    };
  }
}
