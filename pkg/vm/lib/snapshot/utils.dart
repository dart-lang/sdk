// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library vm.snapshot.utils;

import 'dart:io';
import 'dart:convert';

import 'package:vm/snapshot/ascii_table.dart';
import 'package:vm/snapshot/program_info.dart';
import 'package:vm/snapshot/instruction_sizes.dart' as instruction_sizes;

Future<Object> loadJson(File input) async {
  return await input
      .openRead()
      .transform(utf8.decoder)
      .transform(json.decoder)
      .first;
}

Future<ProgramInfo> loadProgramInfo(File input,
    {bool collapseAnonymousClosures = false}) async {
  final json = await loadJson(input);
  return instruction_sizes.loadProgramInfo(json,
      collapseAnonymousClosures: collapseAnonymousClosures);
}

void printHistogram(SizesHistogram histogram,
    {Iterable<String> prefix = const [],
    Iterable<String> suffix = const [],
    String sizeHeader = 'Size (Bytes)',
    int maxWidth = 0}) {
  final table = AsciiTable(header: [
    for (var col in histogram.bucketing.nameComponents) Text.left(col),
    Text.right(sizeHeader),
    Text.right('Percent'),
  ], maxWidth: maxWidth);

  String formatPercent(int value, int total) {
    final p = value / total * 100.0;
    return p.toStringAsFixed(2) + "%";
  }

  if (prefix.isNotEmpty) {
    for (var key in prefix) {
      table.addRow([
        ...histogram.bucketing.namesFromBucket(key),
        histogram.buckets[key].toString(),
        formatPercent(histogram.buckets[key], histogram.totalSize),
      ]);
    }
    table.addSeparator(
        prefix.length < histogram.length ? Separator.Wave : Separator.Line);
  }

  final numRestRows = histogram.length - (suffix.length + prefix.length);
  if (numRestRows > 0) {
    final totalRestBytes = histogram.totalSize -
        [prefix, suffix]
            .expand((l) => l)
            .fold(0, (sum, key) => sum + histogram.buckets[key]);
    table.addTextSeparator(
        '$numRestRows more rows accounting for ${totalRestBytes}'
        ' (${formatPercent(totalRestBytes, histogram.totalSize)}) bytes');
    final avg = (totalRestBytes / numRestRows).round();
    table.addTextSeparator(
        'on average that is ${avg} (${formatPercent(avg, histogram.totalSize)})'
        ' bytes per row');
    table.addSeparator(suffix.isNotEmpty ? Separator.Wave : Separator.Line);
  }

  if (suffix.isNotEmpty) {
    for (var key in suffix) {
      table.addRow([
        ...histogram.bucketing.namesFromBucket(key),
        histogram.buckets[key].toString(),
        formatPercent(histogram.buckets[key], histogram.totalSize),
      ]);
    }
    table.addSeparator(Separator.Line);
  }

  table.render();
  print('Total: ${histogram.totalSize} bytes');
}
