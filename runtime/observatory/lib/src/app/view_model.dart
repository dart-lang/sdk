// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

abstract class TableTreeRow extends Observable {
  static const arrowRight = '\u2192';
  static const arrowDownRight = '\u21b3';
  // Number of ems each subtree is indented.
  static const subtreeIndent = 2;

  TableTreeRow(this.tree, TableTreeRow parent) :
      parent = parent,
      depth = parent != null ? parent.depth + 1 : 0 {
  }

  final TableTree tree;
  final TableTreeRow parent;
  final int depth;
  final List<TableTreeRow> children = new List<TableTreeRow>();
  final List<TableCellElement> _tableColumns = new List<TableCellElement>();
  final List<DivElement> flexColumns = new List<DivElement>();
  final List<StreamSubscription> listeners = new List<StreamSubscription>();

  SpanElement _expander;
  TableRowElement _tr;
  TableRowElement get tr => _tr;
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

  /// Fired when the tree row is being expanded.
  void _onExpand() {
    _updateExpanderView();
  }

  /// Fired when the tree row is being collapsed.
  void _onCollapse() {
    for (var child in children) {
      child.onHide();
    }
    _updateExpanderView();
  }

  bool toggle() {
    expanded = !expanded;
    return expanded;
  }

  HtmlElement _makeColorBlock(String backgroundColor) {
    var colorBlock = new DivElement();
    colorBlock.style.minWidth = '2px';
    colorBlock.style.backgroundColor = backgroundColor;
    return colorBlock;
  }

  HtmlElement _makeExpander() {
    var expander = new SpanElement();
    expander.style.minWidth = '2em';
    listeners.add(expander.onClick.listen(onClick));
    return expander;
  }

  void _cleanUpListeners() {
    for (var i = 0; i < listeners.length; i++) {
      listeners[i].cancel();
    }
    listeners.clear();
  }

  void onClick(Event e) {
    e.stopPropagation();
    tree.toggle(this);
  }

  static const redColor = '#F44336';
  static const blueColor = '#3F51B5';
  static const purpleColor = '#673AB7';
  static const greenColor = '#4CAF50';
  static const orangeColor = '#FF9800';
  static const lightGrayColor = '#FAFAFA';

  void _buildRow() {
    const List backgroundColors = const [
      purpleColor,
      redColor,
      greenColor,
      blueColor,
      orangeColor,
    ];
    _tr = new TableRowElement();
    for (var i = 0; i < tree.columnCount; i++) {
      var cell = _tr.insertCell(-1);
      _tableColumns.add(cell);
      var flex = new DivElement();
      flex.classes.add('flex-row');
      cell.children.add(flex);
      flexColumns.add(flex);
    }
    var firstColumn = flexColumns[0];
    _tableColumns[0].style.paddingLeft = '${(depth - 1) * subtreeIndent}em';
    var backgroundColor = lightGrayColor;
    if (depth > 1) {
      var colorIndex = (depth - 1) % backgroundColors.length;
      backgroundColor = backgroundColors[colorIndex];
    }
    var colorBlock = _makeColorBlock(backgroundColor);
    firstColumn.children.add(colorBlock);
    _expander = _makeExpander();
    firstColumn.children.add(_expander);
    // Enable expansion by clicking anywhere on the first column.
    listeners.add(firstColumn.onClick.listen(onClick));
    _updateExpanderView();
  }

  void _updateExpanderView() {
    if (_expander == null) {
      return;
    }
    if (!hasChildren()) {
      _expander.style.visibility = 'hidden';
      _expander.classes.remove('pointer');
      return;
    } else {
      _expander.style.visibility = 'visible';
      _expander.classes.add('pointer');
    }
    _expander.children.clear();
    _expander.children.add(expanded ?
        new Element.tag('icon-expand-more') :
        new Element.tag('icon-chevron-right'));
  }

  bool hasChildren();

  /// Fired when the tree row is being shown.
  /// Populate tr and add logical children here.
  void onShow() {
    assert(_tr == null);
    _buildRow();
  }

  /// Fired when the tree row is being hidden.
  void onHide() {
    _tr = null;
    _expander = null;
    if (_tableColumns != null) {
      _tableColumns.clear();
    }
    if (flexColumns != null) {
      flexColumns.clear();
    }
    _cleanUpListeners();
  }
}

class TableTree extends Observable {
  final TableSectionElement tableBody;
  final List<TableTreeRow> rows = [];
  final int columnCount;
  Future _pendingOperation;
  /// Create a table tree with column [headers].
  TableTree(this.tableBody, this.columnCount);

  void clear() {
    tableBody.children.clear();
    for (var i = 0; i < rows.length; i++) {
      rows[i]._cleanUpListeners();
    }
    rows.clear();
  }

  /// Initialize the table tree with the list of root children.
  void initialize(TableTreeRow root) {
    clear();
    root.onShow();
    toggle(root);
  }

  /// Toggle expansion of row in tree.
  toggle(TableTreeRow row) async {
    if (_pendingOperation != null) {
      return;
    }
    if (row.toggle()) {
      document.body.classes.add('busy');
      _pendingOperation = _expand(row);
      await _pendingOperation;
      _pendingOperation = null;
      document.body.classes.remove('busy');
      if (row.children.length == 1) {
        // Auto expand single child.
        await toggle(row.children[0]);
      }
    } else {
      document.body.classes.add('busy');
      _pendingOperation = _collapse(row);
      await _pendingOperation;
      _pendingOperation = null;
      document.body.classes.remove('busy');
    }
  }

  int _index(TableTreeRow row) => rows.indexOf(row);

  _insertRow(index, child) {
    rows.insert(index, child);
    tableBody.children.insert(index, child.tr);
  }

  _expand(TableTreeRow row) async {
    int index = _index(row);
    if ((index == -1) && (rows.length != 0)) {
      return;
    }
    assert((index != -1) || (rows.length == 0));
    var i = 0;
    var addPerIteration = 10;
    while (i < row.children.length) {
      await window.animationFrame;
      for (var j = 0; j < addPerIteration; j++) {
        if (i == row.children.length) {
          break;
        }
        var child = row.children[i];
        child.onShow();
        child._updateExpanderView();
        _insertRow(index + i + 1, child);
        i++;
      }
    }
  }

  _collapseSync(TableTreeRow row) {
    var childCount = row.children.length;
    if (childCount == 0) {
      return;
    }
    for (var i = 0; i < childCount; i++) {
      // Close all inner rows.
      if (row.children[i].expanded) {
        _collapseSync(row.children[i]);
      }
    }
    // Collapse this row.
    row.expanded = false;
    // Remove all children.
    int index = _index(row);
    for (var i = 0; i < childCount; i++) {
      rows.removeAt(index + 1);
      tableBody.children.removeAt(index + 1);
    }
  }

  _collapse(TableTreeRow row) async {
    _collapseSync(row);
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
