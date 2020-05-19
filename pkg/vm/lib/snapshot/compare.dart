// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool compares two JSON size reports produced by
/// --print-instructions-sizes-to and reports which symbols increased in size
/// and which symbols decreased in size.
library vm.snapshot.compare;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:args/command_runner.dart';

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
    argParser.addOption('column-width',
        help: 'Truncate column content to the given width'
            ' (${AsciiTable.unlimitedWidth} means do not truncate).',
        defaultsTo: AsciiTable.unlimitedWidth.toString());
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
    printComparison(oldJsonPath, newJsonPath, maxWidth: maxWidth);
  }

  String _checkExists(String path) {
    if (!File(path).existsSync()) {
      usageException('File $path does not exist!');
    }
    return path;
  }
}

void printComparison(String oldJsonPath, String newJsonPath,
    {int maxWidth: 0}) {
  final oldSizes = loadSymbolSizes(oldJsonPath);
  final newSizes = loadSymbolSizes(newJsonPath);

  var totalOld = 0;
  var totalNew = 0;
  var totalDiff = 0;
  final diffBySymbol = <String, int>{};

  // Process all symbols (from both old and new results) and compute the change
  // in size. If symbol is not present in the compilation assume its size to be
  // zero.
  for (var key in Set<String>()..addAll(newSizes.keys)..addAll(oldSizes.keys)) {
    final oldSize = oldSizes[key] ?? 0;
    final newSize = newSizes[key] ?? 0;
    final diff = newSize - oldSize;
    if (diff != 0) diffBySymbol[key] = diff;
    totalOld += oldSize;
    totalNew += newSize;
    totalDiff += diff;
  }

  // Compute the list of changed symbols sorted by difference (descending).
  final changedSymbolsBySize = diffBySymbol.keys.toList();
  changedSymbolsBySize.sort((a, b) => diffBySymbol[b] - diffBySymbol[a]);

  // Now produce the report table.
  const numLargerSymbolsToReport = 30;
  const numSmallerSymbolsToReport = 10;
  final table = AsciiTable(header: [
    Text.left('Library'),
    Text.left('Method'),
    Text.right('Diff (Bytes)')
  ], maxWidth: maxWidth);

  // Report [numLargerSymbolsToReport] symbols that increased in size most.
  for (var key in changedSymbolsBySize
      .where((k) => diffBySymbol[k] > 0)
      .take(numLargerSymbolsToReport)) {
    final name = key.split(librarySeparator);
    table.addRow([name[0], name[1], '+${diffBySymbol[key]}']);
  }
  table.addSeparator(Separator.Wave);

  // Report [numSmallerSymbolsToReport] symbols that decreased in size most.
  for (var key in changedSymbolsBySize.reversed
      .where((k) => diffBySymbol[k] < 0)
      .take(numSmallerSymbolsToReport)
      .toList()
      .reversed) {
    final name = key.split(librarySeparator);
    table.addRow([name[0], name[1], '${diffBySymbol[key]}']);
  }
  table.addSeparator();

  table.render();
  print('Comparing ${oldJsonPath} (old) to ${newJsonPath} (new)');
  print('Old   : ${totalOld} bytes.');
  print('New   : ${totalNew} bytes.');
  print('Change: ${totalDiff > 0 ? '+' : ''}${totalDiff} bytes.');
}

/// A combination of characters that is unlikely to occur in the symbol name.
const String librarySeparator = ',';

/// Load --print-instructions-sizes-to output as a mapping from symbol names
/// to their sizes.
///
/// Note: we produce a single symbol name from function name and library name
/// by concatenating them with [librarySeparator].
Map<String, int> loadSymbolSizes(String name) {
  final symbols = jsonDecode(File(name).readAsStringSync());
  final result = new Map<String, int>();
  final regexp = new RegExp(r"0x[a-fA-F0-9]+");
  for (int i = 0, n = symbols.length; i < n; i++) {
    final e = symbols[i];
    // Obtain a key by combining library and method name. Strip anything
    // after the library separator to make sure we can easily decode later.
    // For method names, also remove non-deterministic parts to avoid
    // reporting non-existing differences against the same layout.
    String lib = ((e['l'] ?? '').split(librarySeparator))[0];
    String name = (e['n'].split(librarySeparator))[0]
        .replaceAll('[Optimized] ', '')
        .replaceAll(regexp, '');
    String key = lib + librarySeparator + name;
    int val = e['s'];
    result[key] =
        (result[key] ?? 0) + val; // add (key,val), accumulate if exists
  }
  return result;
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
