// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

abstract class TableTreeRow extends Observable {
  static const arrowRight = '\u2192';
  static const arrowDownRight = '\u21b3';
  // Number of pixels each subtree is indented.
  static const subtreeIndent = 16;

  final TableTree tree;
  final TableTreeRow parent;
  final int depth;
  final List<TableTreeRow> children = new List<TableTreeRow>();
  final List<TableCellElement> tableColumns = new List<TableCellElement>();
  SpanElement _expander;
  TableRowElement _tr;
  TableRowElement get tr {
    assert(_tr != null);
    return _tr;
  }

  TableTreeRow(this.tree, TableTreeRow parent) :
      parent = parent,
      depth = parent != null ? parent.depth+1 : 0 {
  }

  bool _expanded = false;
  bool get expanded => _expanded;
  set expanded(bool expanded) {
    var changed = _expanded != expanded;
    _expanded = expanded;
    if (changed) {
      // If the state has changed, fire callbacks.
      if (_expanded) {
        _onExpand();
      } else {
        _onCollapse();
      }
    }
  }

  bool expandOrCollapse() {
    expanded = !expanded;
    return expanded;
  }

  bool hasChildren();

  String _backgroundColorClassForRow() {
    const colors = const ['rowColor0', 'rowColor1', 'rowColor2', 'rowColor3',
                          'rowColor4', 'rowColor5', 'rowColor6', 'rowColor7',
                          'rowColor8'];
    var index = (depth - 1) % colors.length;
    return colors[index];
  }

  void _buildRow() {
    _tr = new TableRowElement();
    for (var i = 0; i < tree.columnCount; i++) {
      var cell = _tr.insertCell(-1);
      cell.classes.add(_backgroundColorClassForRow());
      tableColumns.add(cell);
    }
    var firstColumn = tableColumns[0];
    _expander = new SpanElement();
    _expander.style.display = 'inline-block';
    _expander.style.minWidth = '1.5em';
    _expander.onClick.listen(onClick);
    firstColumn.children.add(_expander);
    firstColumn.style.paddingLeft = '${depth * subtreeIndent}px';
    updateExpanderView();
  }

  void updateExpanderView() {
    if (_expander == null) {
      return;
    }
    if (!hasChildren()) {
      _expander.style.visibility = 'hidden';
      _expander.style.cursor = 'auto';
      return;
    } else {
      _expander.style.visibility = 'visible';
      _expander.style.cursor = 'pointer';
    }
    _expander.text = expanded ? arrowDownRight : arrowRight;
  }

  /// Fired when the tree row is being shown.
  /// Populate tr and add logical children here.
  void onShow() {
    assert(_tr == null);
    _buildRow();
  }

  /// Fired when the tree row is being hidden.
  void onHide() {
    assert(_tr != null);
    _tr = null;
    tableColumns.clear();
    _expander = null;
  }

  /// Fired when the tree row is being expanded.
  void _onExpand() {
    for (var child in children) {
      child.onShow();
      child.updateExpanderView();
    }
    updateExpanderView();
  }

  /// Fired when the tree row is being collapsed.
  void _onCollapse() {
    for (var child in children) {
      child.onHide();
    }
    updateExpanderView();
  }

  void onClick(Event e) {
    tree.toggle(this);
    e.stopPropagation();
  }
}

class TableTree extends Observable {
  final TableSectionElement tableBody;
  final List<TableTreeRow> rows = [];
  final int columnCount;

  /// Create a table tree with column [headers].
  TableTree(this.tableBody, this.columnCount);

  /// Initialize the table tree with the list of root children.
  void initialize(TableTreeRow root) {
    tableBody.children.clear();
    rows.clear();
    root.onShow();
    rows.addAll(root.children);
    for (var i = 0; i < rows.length; i++) {
      rows[i].onShow();
      tableBody.children.add(rows[i].tr);
    }
  }

  /// Toggle expansion of row in tree.
  void toggle(TableTreeRow row) {
    if (row.expandOrCollapse()) {
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
    for (var i = 0; i < row.children.length; i++) {
      tableBody.children.insert(index + i + 1, row.children[i].tr);
    }
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
    for (var i = 0; i < childCount; i++) {
      tableBody.children.removeAt(index + 1);
    }
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
