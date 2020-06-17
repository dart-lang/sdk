// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool compares two JSON size reports produced by
/// --print-instructions-sizes-to and reports which symbols increased in size
/// and which symbols decreased in size.
library vm.snapshot.commands.compare;

import 'dart:io';
import 'dart:math' as math;

import 'package:args/command_runner.dart';

import 'package:vm/snapshot/instruction_sizes.dart';
import 'package:vm/snapshot/program_info.dart';

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
  var totalOld = 0;
  oldSizes.visit((_, __, ___, size) {
    totalOld += size;
  });

  var totalNew = 0;
  newSizes.visit((_, __, ___, size) {
    totalNew += size;
  });

  var totalDiff = 0;
  diff.visit((_, __, ___, size) {
    totalDiff += size.inBytes;
  });

  // Compute histogram.
  final histogram = SizesHistogram.from<SymbolDiff>(
      diff, (diff) => diff.inBytes, granularity);

  // Now produce the report table.
  const numLargerSymbolsToReport = 30;
  const numSmallerSymbolsToReport = 10;
  final table = AsciiTable(header: [
    for (var col in histogram.bucketing.nameComponents) Text.left(col),
    Text.right('Diff (Bytes)')
  ], maxWidth: maxWidth);

  // Report [numLargerSymbolsToReport] symbols that increased in size most.
  for (var key in histogram.bySize
      .where((k) => histogram.buckets[k] > 0)
      .take(numLargerSymbolsToReport)) {
    table.addRow([
      ...histogram.bucketing.namesFromBucket(key),
      '+${histogram.buckets[key]}'
    ]);
  }
  table.addSeparator(Separator.Wave);

  // Report [numSmallerSymbolsToReport] symbols that decreased in size most.
  for (var key in histogram.bySize.reversed
      .where((k) => histogram.buckets[k] < 0)
      .take(numSmallerSymbolsToReport)
      .toList()
      .reversed) {
    table.addRow([
      ...histogram.bucketing.namesFromBucket(key),
      '${histogram.buckets[key]}'
    ]);
  }
  table.addSeparator();

  table.render();
  print('Comparing ${oldJson.path} (old) to ${newJson.path} (new)');
  print('Old   : ${totalOld} bytes.');
  print('New   : ${totalNew} bytes.');
  print('Change: ${totalDiff > 0 ? '+' : ''}${totalDiff} bytes.');
}

/// A row in the [AsciiTable].
abstract class Row {
  String render(List<int> widths, List<AlignmentDirection> alignments);
}

enum Separator {
  /// Line separator looks like this: `+-------+------+`
  Line,

  /// Wave separator looks like this: `~~~~~~~~~~~~~~~~` repeated twice.
  Wave
}

/// A separator row in the [AsciiTable].
class SeparatorRow extends Row {
  final Separator filler;
  SeparatorRow(this.filler);

  @override
  String render(List<int> widths, List<AlignmentDirection> alignments) {
    switch (filler) {
      case Separator.Line:
        final sb = StringBuffer();
        sb.write('+');
        for (var i = 0; i < widths.length; i++) {
          sb.write('-' * (widths[i] + 2));
          sb.write('+');
        }
        return sb.toString();

      case Separator.Wave:
        final sb = StringBuffer();
        sb.write('~');
        for (var i = 0; i < widths.length; i++) {
          sb.write('~' * (widths[i] + 2));
          sb.write('~');
        }
        return sb.toString() + '\n' + sb.toString();
    }
    return null; // Make analyzer happy.
  }
}

class NormalRow extends Row {
  final List<dynamic> columns;
  NormalRow(this.columns);

  @override
  String render(List<int> widths, List<AlignmentDirection> alignments) {
    final sb = StringBuffer();
    sb.write('|');
    for (var i = 0; i < widths.length; i++) {
      sb.write(' ');
      final text = columns[i] is Text
          ? columns[i]
          : Text(value: columns[i], direction: alignments[i]);
      sb.write(text.render(widths[i]));
      sb.write(' |');
    }
    return sb.toString();
  }
}

enum AlignmentDirection { Left, Right, Center }

/// A chunk of text aligned in the given direction within a cell.
class Text {
  final String value;
  final AlignmentDirection direction;

  Text({this.value, this.direction});
  Text.left(String value)
      : this(value: value, direction: AlignmentDirection.Left);
  Text.right(String value)
      : this(value: value, direction: AlignmentDirection.Right);
  Text.center(String value)
      : this(value: value, direction: AlignmentDirection.Center);

  String render(int width) {
    if (value.length > width) {
      // Narrowed column.
      return value.substring(0, width - 2) + '..';
    }
    switch (direction) {
      case AlignmentDirection.Left:
        return value.padRight(width);
      case AlignmentDirection.Right:
        return value.padLeft(width);
      case AlignmentDirection.Center:
        final diff = width - value.length;
        return ' ' * (diff ~/ 2) + value + (' ' * (diff - diff ~/ 2));
    }
    return null; // Make analyzer happy.
  }

  int get length => value.length;
}

class AsciiTable {
  static const int unlimitedWidth = 0;

  final int maxWidth;

  final List<Row> rows = <Row>[];

  AsciiTable({List<dynamic> header, this.maxWidth: unlimitedWidth}) {
    if (header != null) {
      addSeparator();
      addRow(header);
      addSeparator();
    }
  }

  void addRow(List<dynamic> columns) => rows.add(NormalRow(columns));

  void addSeparator([Separator filler = Separator.Line]) =>
      rows.add(SeparatorRow(filler));

  void render() {
    // We assume that the first row gives us alignment directions that
    // subsequent rows would follow.
    List<AlignmentDirection> alignments = rows
        .whereType<NormalRow>()
        .first
        .columns
        .map((v) => v is Text ? v.direction : AlignmentDirection.Left)
        .toList();
    List<int> widths =
        List<int>.filled(rows.whereType<NormalRow>().first.columns.length, 0);

    // Compute max width for each column in the table.
    for (var row in rows.whereType<NormalRow>()) {
      assert(row.columns.length == widths.length);
      for (var i = 0; i < widths.length; i++) {
        widths[i] = math.max(row.columns[i].length, widths[i]);
      }
    }

    if (maxWidth > 0) {
      for (var i = 0; i < widths.length; i++) {
        widths[i] = math.min(widths[i], maxWidth);
      }
    }

    for (var row in rows) {
      print(row.render(widths, alignments));
    }
  }
}
