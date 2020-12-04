// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

typedef String ValueFormatter(dynamic value);

class SortedTableColumn {
  static String toStringFormatter(dynamic v) {
    return v != null ? v.toString() : '<null>';
  }

  final String label;
  final ValueFormatter formatter;
  SortedTableColumn.withFormatter(this.label, this.formatter);
  SortedTableColumn(this.label) : formatter = toStringFormatter;
}

class SortedTableRow {
  final List values;
  SortedTableRow(this.values);
}

class SortedTable {
  final List<SortedTableColumn> columns;
  final List<SortedTableRow> rows = <SortedTableRow>[];
  final List<int> sortedRows = [];

  SortedTable(this.columns);

  int _sortColumnIndex = 0;
  set sortColumnIndex(var index) {
    assert(index >= 0);
    assert(index < columns.length);
    _sortColumnIndex = index;
  }

  int get sortColumnIndex => _sortColumnIndex;
  bool _sortDescending = true;
  bool get sortDescending => _sortDescending;
  set sortDescending(var descending) {
    _sortDescending = descending;
  }

  dynamic getSortKeyFor(int row, int col) {
    return rows[row].values[col];
  }

  int _sortFuncDescending(int i, int j) {
    var a = getSortKeyFor(i, _sortColumnIndex);
    var b = getSortKeyFor(j, _sortColumnIndex);
    return b.compareTo(a);
  }

  int _sortFuncAscending(int i, int j) {
    var a = getSortKeyFor(i, _sortColumnIndex);
    var b = getSortKeyFor(j, _sortColumnIndex);
    return a.compareTo(b);
  }

  void sort() {
    assert(_sortColumnIndex >= 0);
    assert(_sortColumnIndex < columns.length);
    if (_sortDescending) {
      sortedRows.sort(_sortFuncDescending);
    } else {
      sortedRows.sort(_sortFuncAscending);
    }
  }

  void clearRows() {
    rows.clear();
    sortedRows.clear();
  }

  void addRow(SortedTableRow row) {
    sortedRows.add(rows.length);
    rows.add(row);
  }

  String getFormattedValue(int row, int column) {
    var value = getValue(row, column);
    var formatter = columns[column].formatter;
    return formatter(value);
  }

  String getColumnLabel(int column) {
    assert(column >= 0);
    assert(column < columns.length);
    // TODO(johnmccutchan): Move expander display decisions into html once
    // tables and templates are better supported.
    const arrowUp = '\u25BC';
    const arrowDown = '\u25B2';
    if (column != _sortColumnIndex) {
      return columns[column].label + '\u2003';
    }
    return columns[column].label + (_sortDescending ? arrowUp : arrowDown);
  }

  dynamic getValue(int row, int column) {
    return rows[row].values[column];
  }
}
