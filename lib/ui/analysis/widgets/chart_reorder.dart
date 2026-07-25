import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/scaffold/reorderable_scaffold.dart';
import 'package:hotel_pos_system/models/analysis/analysis.dart';
import 'package:hotel_pos_system/models/analysis/chart.dart';
import 'package:hotel_pos_system/translator.dart';

class ChartReorder extends StatelessWidget {
  const ChartReorder({super.key});

  @override
  Widget build(BuildContext context) {
    return ReorderableScaffold(
      items: Analysis.instance.itemList,
      title: S.analysisChartTitleReorder,
      handleSubmit: (List<Chart> items) => Analysis.instance.reorderItems(items),
    );
  }
}
