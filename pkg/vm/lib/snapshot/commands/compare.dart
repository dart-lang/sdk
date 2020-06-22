// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool compares two JSON size reports produced by
/// --print-instructions-sizes-to and reports which symbols increased in size
/// and which symbols decreased in size.
library vm.snapshot.compare;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:vm/snapshot/ascii_table.dart';

import 'package:vm/snapshot/program_info.dart';
import 'package:vm/snapshot/utils.dart';

class CompareCommand extends Command<void> {
  @override
  final String name = 'compare';

  @override
  final String description = '''
Compare two instruction size outputs and report which symbols changed in size.

This tool compares two JSON size reports produced by
--print-instructions-sizes-to and reports which symbols
changed in size.

Use --narrow flag to limit column widths.''';

  @override
  String get invocation =>
      super.invocation.replaceAll('[arguments]', '<old.json> <new.json>');

  CompareCommand() {
    argParser
      ..addOption('column-width',
          help: 'Truncate column content to the given width'
              ' (${AsciiTable.unlimitedWidth} means do not truncate).',
          defaultsTo: AsciiTable.unlimitedWidth.toString())
      ..addOption('granularity',
          help: 'Choose the granularity of the output.',
          allowed: ['method', 'class', 'library', 'package'],
          defaultsTo: 'method')
      ..addFlag('collapse-anonymous-closures', help: '''
Collapse all anonymous closures from the same scope into a single entry.
When comparing size of AOT snapshots for two different versions of a
program there is no reliable way to precisely establish which two anonymous
closures are the same and should be compared in size - so
comparison might produce a noisy output. This option reduces confusion
by collapsing different anonymous closures within the same scope into a
single entry. Note that when comparing the same application compiled
with two different versions of an AOT compiler closures can be distinguished
precisely based on their source position (which is included in their name).
''');
  }

  @override
  Future<void> run() async {
    if (argResults.rest.length != 2) {
      usageException('Need to provide path to old.json and new.json reports.');
    }

    final columnWidth = argResults['column-width'];
    final maxWidth = int.tryParse(columnWidth);
    if (maxWidth == null) {
      usageException(
          'Specified column width (${columnWidth}) is not an integer');
    }

    final oldJsonPath = _checkExists(argResults.rest[0]);
    final newJsonPath = _checkExists(argResults.rest[1]);
    printComparison(oldJsonPath, newJsonPath,
        maxWidth: maxWidth,
        granularity: _parseHistogramType(argResults['granularity']),
        collapseAnonymousClosures: argResults['collapse-anonymous-closures']);
  }

  HistogramType _parseHistogramType(String value) {
    switch (value) {
      case 'method':
        return HistogramType.bySymbol;
      case 'class':
        return HistogramType.byClass;
      case 'library':
        return HistogramType.byLibrary;
      case 'package':
        return HistogramType.byPackage;
    }
  }

  File _checkExists(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      usageException('File $path does not exist!');
    }
    return file;
  }
}

void printComparison(File oldJson, File newJson,
    {int maxWidth: 0,
    bool collapseAnonymousClosures = false,
    HistogramType granularity = HistogramType.bySymbol}) async {
  final oldSizes = await loadProgramInfo(oldJson,
      collapseAnonymousClosures: collapseAnonymousClosures);
  final newSizes = await loadProgramInfo(newJson,
      collapseAnonymousClosures: collapseAnonymousClosures);
  final diff = computeDiff(oldSizes, newSizes);

  // Compute total sizes.
  final totalOld = oldSizes.totalSize;
  final totalNew = newSizes.totalSize;
  final totalDiff = diff.totalSize;

  // Compute histogram.
  final histogram = SizesHistogram.from(diff, granularity);

  // Now produce the report table.
  const numLargerSymbolsToReport = 30;
  const numSmallerSymbolsToReport = 10;
  printHistogram(histogram,
      sizeHeader: 'Diff (Bytes)',
      prefix: histogram.bySize
          .where((k) => histogram.buckets[k] > 0)
          .take(numLargerSymbolsToReport),
      suffix: histogram.bySize.reversed
          .where((k) => histogram.buckets[k] < 0)
          .take(numSmallerSymbolsToReport)
          .toList()
          .reversed,
      maxWidth: maxWidth);

  print('Comparing ${oldJson.path} (old) to ${newJson.path} (new)');
  print('Old   : ${totalOld} bytes.');
  print('New   : ${totalNew} bytes.');
  print('Change: ${totalDiff > 0 ? '+' : ''}${totalDiff} bytes.');
}
