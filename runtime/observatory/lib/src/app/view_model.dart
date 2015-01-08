// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

abstract class TableTreeRow extends Observable {
  final TableTreeRow parent;
  @observable final int depth;
  @observable final List<TableTreeRow> children = new List<TableTreeRow>();
  @observable final List<String> columns = [];
  static const arrowRight = '\u2192';
  static const arrowDownRight = '\u21b3';
  static const showExpanderStyle = 'cursor: pointer;';
  static const hideExpanderStyle = 'visibility:hidden;';

  // TODO(johnmccutchan): Move expander display decisions into html once
  // tables and templates are better supported.
  @observable String expander = arrowRight;
  @observable String expanderStyle = showExpanderStyle;

  TableTreeRow(TableTreeRow parent) :
      parent = parent,
      depth = parent != null ? parent.depth+1 : 0 {
    if (!hasChildren()) {
      expanderStyle = hideExpanderStyle;
    }
  }

  bool _expanded = false;
  bool get expanded => _expanded;
  set expanded(bool expanded) {
    var changed = _expanded != expanded;
    _expanded = expanded;
    if (changed) {
      // If the state has changed, fire callbacks.
      if (_expanded) {
        expander = arrowDownRight;
        onShow();
      } else {
        expander = arrowRight;
        onHide();
      }
    }
  }

  bool toggle() {
    expanded = !expanded;
    return expanded;
  }

  bool hasChildren();

  /// Fired when the tree row is expanded. Add children rows here.
  void onShow();

  /// Fired when the tree row is collapsed.
  void onHide();
}

class TableTree extends Observable {
  @observable final List<TableTreeRow> rows = toObservable([]);

  /// Create a table tree with column [headers].
  TableTree();

  /// Initialize the table tree with the list of root children.
  void initialize(TableTreeRow root) {
    rows.clear();
    root.onShow();
    rows.addAll(root.children);
  }

  /// Toggle expansion of row at [rowIndex].
  void toggle(int rowIndex) {
    assert(rowIndex >= 0);
    assert(rowIndex < rows.length);
    var row = rows[rowIndex];
    if (row.toggle()) {
      _expand(row);
    } else {
      _collapse(row);
    }
  }

  int _index(TableTreeRow row) => rows.indexOf(row);

  void _expand(TableTreeRow row) {
    int index = _index(row);
    assert(index != -1);
    rows.insertAll(index + 1, row.children);
  }

  void _collapse(TableTreeRow row) {
    var childCount = row.children.length;
    if (childCount == 0) {
      return;
    }
    for (var i = 0; i < childCount; i++) {
      // Close all inner rows.
      if (row.children[i].expanded) {
        _collapse(row.children[i]);
      }
    }
    // Collapse this row.
    row.expanded = false;
    // Remove all children.
    int index = _index(row);
    rows.removeRange(index + 1, index + 1 + childCount);
  }
}

typedef String ValueFormatter(dynamic value);

class SortedTableColumn {
  static String toStringFormatter(dynamic v) {
    return v != null ? v.toString() : '<null>';
  }
  final String label;
  final ValueFormatter formatter;
  SortedTableColumn.withFormatter(this.label, this.formatter);
  SortedTableColumn(this.label)
      : formatter = toStringFormatter;
}

class SortedTableRow {
  final List values;
  SortedTableRow(this.values);
}

class SortedTable extends Observable {
  final List<SortedTableColumn> columns;
  final List<SortedTableRow> rows = new List<SortedTableRow>();
  final List<int> sortedRows = [];

  SortedTable(this.columns);

  int _sortColumnIndex = 0;
  set sortColumnIndex(var index) {
    assert(index >= 0);
    assert(index < columns.length);
    _sortColumnIndex = index;
    notifyPropertyChange(#getColumnLabel, 0, 1);
  }
  int get sortColumnIndex => _sortColumnIndex;
  bool _sortDescending = true;
  bool get sortDescending => _sortDescending;
  set sortDescending(var descending) {
    _sortDescending = descending;
    notifyPropertyChange(#getColumnLabel, 0, 1);
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
    Stopwatch sw = new Stopwatch()..start();
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

  @observable String getColumnLabel(int column) {
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
