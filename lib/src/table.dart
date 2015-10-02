// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_info.src.table;

import 'dart:math' show max;

/// Helper class to present data on the command-line in a table form.
class Table {
  int _totalColumns = 0;
  int get totalColumns => _totalColumns;

  /// Abbreviations, used to make headers shorter.
  Map<String, String> abbreviations = {};

  /// Width of each column.
  List<int> widths = <int>[];

  /// The header for each column (`header.length == totalColumns`).
  List header = [];

  /// The color for each column (`color.length == totalColumns`).
  List colors = [];

  /// Each row on the table. Note that all rows have the same size
  /// (`rows[*].length == totalColumns`).
  List<List> rows = [];

  /// Columns to skip, for example, if they are all zero entries.
  List<bool> _skipped = <bool>[];

  /// Whether we started adding entries. Indicates that no more columns can be
  /// added.
  bool _sealed = false;

  /// Current row being built by [addEntry].
  List _currentRow;

  /// Add a column with the given [name].
  void declareColumn(String name,
      {bool abbreviate: false, String color: _NO_COLOR}) {
    assert(!_sealed);
    var headerName = name;
    if (abbreviate) {
      // abbreviate the header by using only the initials of each word
      headerName =
          name.split(' ').map((s) => s.substring(0, 1).toUpperCase()).join('');
      while (abbreviations[headerName] != null) headerName = "$headerName'";
      abbreviations[headerName] = name;
    }
    widths.add(max(5, headerName.length + 1));
    header.add(headerName);
    colors.add(color);
    _skipped.add(_totalColumns > 0);
    _totalColumns++;
  }

  /// Add an entry in the table, creating a new row each time [totalColumns]
  /// entries are added.
  void addEntry(entry) {
    if (_currentRow == null) {
      _sealed = true;
      _currentRow = [];
    }
    int pos = _currentRow.length;
    assert(pos < _totalColumns);

    widths[pos] = max(widths[pos], '$entry'.length + 1);
    _currentRow.add('$entry');
    if (entry is int && entry != 0) {
      _skipped[pos] = false;
    }

    if (pos + 1 == _totalColumns) {
      rows.add(_currentRow);
      _currentRow = [];
    }
  }

  /// Add an empty row to divide sections of the table.
  void addEmptyRow() {
    var emptyRow = [];
    for (int i = 0; i < _totalColumns; i++) {
      emptyRow.add('-' * widths[i]);
    }
    rows.add(emptyRow);
  }

  /// Enter the header titles. OK to do so more than once in long tables.
  void addHeader() {
    rows.add(header);
  }

  /// Generates a string representation of the table to print on a terminal.
  // TODO(sigmund): add also a .csv format
  String toString() {
    var sb = new StringBuffer();
    sb.write('\n');
    for (var row in rows) {
      var lastColor = _NO_COLOR;
      for (int i = 0; i < _totalColumns; i++) {
        if (_skipped[i]) continue;
        var entry = row[i];
        var color = colors[i];
        if (lastColor != color) {
          sb.write(color);
          lastColor = color;
        }
        // Align first column to the left, everything else to the right.
        sb.write(
            i == 0 ? entry.padRight(widths[i]) : entry.padLeft(widths[i] + 1));
      }
      if (lastColor != _NO_COLOR) sb.write(_NO_COLOR);
      sb.write('\n');
    }
    sb.write('\nWhere:\n');
    for (var id in abbreviations.keys) {
      sb.write('  $id:'.padRight(7));
      sb.write(' ${abbreviations[id]}\n');
    }
    return sb.toString();
  }
}

const _NO_COLOR = "\x1b[0m";
