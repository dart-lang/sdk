// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Print the given [table].
void printTable(List<List<String>> table) {
  var buffer = StringBuffer();
  buffer.writeTable(table);
  print(buffer.toString());
}

/// Return an iterable that will produce all of the integer values between
/// [first] and [last] inclusive.
Iterable<int> range(int first, int last) sync* {
  for (var i = first; i < last; i++) {
    yield i;
  }
}

/// Given a [table] represented as a list of rows, right justify all of the
/// cells in the given [column].
void rightJustifyColumn(List<List<String>> table, int column) {
  var width = 0;
  for (var i = 0; i < table.length; i++) {
    var row = table[i];
    width = math.max(width, row[column].length);
  }
  for (var i = 0; i < table.length; i++) {
    var row = table[i];
    var cellValue = row[column];
    var length = cellValue.length;
    if (length < width) {
      var padding = ' ' * (width - length);
      row[column] = '$padding$cellValue';
    }
  }
}

/// Given a [table] represented as a list of rows, right justify all of the
/// cells in the given [columns].
void rightJustifyColumns(List<List<String>> table, Iterable<int> columns) {
  for (var column in columns) {
    rightJustifyColumn(table, column);
  }
}

extension OutputUtilities on StringSink {
  /// Write the given [table].
  ///
  /// The table is represented as a list or rows, where each row is a list of
  /// the contents of the cells in that row.
  ///
  /// Throws an [ArgumentError] if the table is empty or if the rows do not
  /// contain the same number of cells.
  void writeTable(List<List<String>> table) {
    var columnWidths = _computeColumnWidths(table);
    for (var row in table) {
      var lastNonEmpty = row.length - 1;
      while (lastNonEmpty > 0) {
        if (row[lastNonEmpty].isNotEmpty) {
          break;
        }
        lastNonEmpty--;
      }
      for (var i = 0; i <= lastNonEmpty; i++) {
        var cellContent = row[i];
        var columnWidth = columnWidths[i];
        var padding = columnWidth - cellContent.length;
        write(cellContent);
        if (i < lastNonEmpty) {
          write(' ' * (padding + 2));
        }
      }
      writeln();
    }
  }

  /// Return the minimum widths for each of the columns in the given [table].
  ///
  /// The table is represented as a list or rows, where each row is a list of
  /// the contents of the cells in that row.
  ///
  /// Throws an [ArgumentError] if the table is empty or if the rows do not
  /// contain the same number of cells.
  List<int> _computeColumnWidths(List<List<String>> table) {
    if (table.isEmpty) {
      throw ArgumentError('table cannot be empty');
    }
    var columnCount = table[0].length;
    if (columnCount == 0) {
      throw ArgumentError('rows cannot be empty');
    }
    var columnWidths = List<int>.filled(columnCount, 0);
    for (var row in table) {
      var rowLength = row.length;
      if (rowLength > 0) {
        if (rowLength != columnCount) {
          throw ArgumentError(
              'non-empty rows must contain the same number of columns');
        }
        for (var i = 0; i < rowLength; i++) {
          var cellWidth = row[i].length;
          columnWidths[i] = math.max(columnWidths[i], cellWidth);
        }
      }
    }
    return columnWidths;
  }
}
