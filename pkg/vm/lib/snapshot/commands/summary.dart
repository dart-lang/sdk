// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool generates a summary report from a binary size reports produced by
/// the AOT compiler's --print-instructions-sizes-to and
/// --write-v8-snapshot-profile-to flags.
library vm.snapshot.summary;

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:vm/snapshot/ascii_table.dart';
import 'package:vm/snapshot/program_info.dart';
import 'package:vm/snapshot/utils.dart';
import 'package:vm/snapshot/v8_profile.dart';

class SummaryCommand extends Command<void> {
  @override
  final name = 'summary';

  @override
  final description = '''
Generate a summary report from a AOT compilers binary size dumps.

This tool can process snapshot size reports produced by
--print-instructions-sizes-to=symbol-sizes.json and
--write-v8-snapshot-profile-to=profile.heapsnapshot flags.
''';

  SummaryCommand() {
    argParser
      ..addOption('column-width',
          help: 'Truncate column content to the given width'
              ' (${AsciiTable.unlimitedWidth} means do not truncate).',
          defaultsTo: AsciiTable.unlimitedWidth.toString())
      ..addOption('by',
          abbr: 'b',
          help: 'Choose breakdown rule of the output.',
          allowed: ['method', 'class', 'library', 'package'],
          defaultsTo: 'method')
      ..addOption(
        'where',
        abbr: 'w',
        help: 'Filter output using the given glob.',
      )
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
  String get invocation =>
      super.invocation.replaceAll('[arguments]', '<sizes.json>');

  @override
  Future<void> run() async {
    if (argResults.rest.length != 1) {
      usageException('Need to specify input JSON.');
    }

    final input = new File(argResults.rest[0]);
    if (!input.existsSync()) {
      usageException('Input file ${input.path} does not exist!');
    }

    final columnWidth = argResults['column-width'];
    final maxWidth = int.tryParse(columnWidth);
    if (maxWidth == null) {
      usageException(
          'Specified column width (${columnWidth}) is not an integer');
    }

    await outputSummary(input,
        maxWidth: maxWidth,
        granularity: _parseHistogramType(argResults['by']),
        collapseAnonymousClosures: argResults['collapse-anonymous-closures'],
        filter: argResults['where']);
  }

  static HistogramType _parseHistogramType(String value) {
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
    return null;
  }
}

void outputSummary(File input,
    {int maxWidth = 0,
    bool collapseAnonymousClosures = false,
    HistogramType granularity = HistogramType.bySymbol,
    String filter}) async {
  final info = await loadProgramInfo(input);

  // Compute histogram.
  final histogram = computeHistogram(info, granularity, filter: filter);

  // Now produce the report table.
  const topToReport = 30;
  printHistogram(info, histogram,
      prefix: histogram.bySize.take(topToReport), maxWidth: maxWidth);

  if (info.snapshotInfo != null) {
    print('\nBreakdown by object type:');
    final typeHistogram =
        computeHistogram(info, HistogramType.byNodeType, filter: filter);
    printHistogram(info, typeHistogram,
        prefix: typeHistogram.bySize, maxWidth: maxWidth);

    print(bucketLegend);
  }
}
