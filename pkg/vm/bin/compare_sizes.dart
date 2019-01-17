// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This tool compares two JSON size reports produced by
// --print-instructions-sizes-to and reports which symbols increased in size
// and which symbols decreased in size.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main(List<String> args) {
  if (args.length != 2) {
    print("""
Usage: dart ${Platform.script} <old.json> <new.json>

This tool compares two JSON size reports produced by
--print-instructions-sizes-to and reports which symbols increased in size
and which symbols decreased in size.
""");
    exit(-1);
  }

  final oldSizes = loadSymbolSizes(args[0]);
  final newSizes = loadSymbolSizes(args[1]);

  var totalDiff = 0;
  final diffBySymbol = <String, int>{};

  // Process all symbols (from both old and new results) and compute the change
  // in size. If symbol is not present in the compilation assume its size to be
  // zero.
  for (var key in Set<String>()..addAll(newSizes.keys)..addAll(oldSizes.keys)) {
    final diff = (newSizes[key] ?? 0) - (oldSizes[key] ?? 0);
    if (diff != 0) diffBySymbol[key] = diff;
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
  ]);

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

  print('Comparing ${args[0]} (old) to ${args[1]} (new)');
  table.render();
  print('Total change ${totalDiff > 0 ? '+' : ''}${totalDiff} bytes.');
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
  return Map<String, int>.fromIterable(symbols,
      key: (e) =>
          (e['l'] ?? '') +
          librarySeparator +
          e['n'].replaceAll('[Optimized] ', ''),
      value: (e) => e['s']);
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
    switch (direction) {
      case AlignmentDirection.Left:
        return value.padRight(width);
      case AlignmentDirection.Right:
        return value.padLeft(width);
      case AlignmentDirection.Center:
        final diff = width - value.length;
        return ' ' * (diff ~/ 2) + value + (' ' * (diff - diff ~/ 2));
    }
  }

  int get length => value.length;
}

class AsciiTable {
  final List<Row> rows = <Row>[];
  AsciiTable({List<dynamic> header}) {
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

    for (var row in rows) {
      print(row.render(widths, alignments));
    }
  }
}
