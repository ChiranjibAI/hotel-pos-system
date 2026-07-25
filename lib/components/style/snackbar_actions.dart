import 'package:flutter/material.dart';
import 'package:hotel_pos_system/helpers/launcher.dart';
import 'package:hotel_pos_system/helpers/logger.dart';

class LauncherSnackbarAction extends SnackBarAction {
  LauncherSnackbarAction({super.key, required super.label, required String link, required String logCode})
    : super(
        onPressed: () {
          Log.ger('launch_snackbar_action', {'code': logCode, 'link': link});
          Launcher.launch(link).ignore();
        },
      );
}
