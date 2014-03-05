// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

abstract class TableTreeRow extends Observable {
  final TableTreeRow parent;
  @observable final int depth;
  @observable final List<TableTreeRow> children = new List<TableTreeRow>();
  @observable final List<String> columns = [];

  TableTreeRow(TableTreeRow parent) :
      parent = parent,
      depth = parent != null ? parent.depth+1 : 0;

  bool _expanded = false;
  bool get expanded => _expanded;
  set expanded(bool expanded) {
    var changed = _expanded != expanded;
    _expanded = expanded;
    if (changed) {
      // If the state has changed, fire callbacks.
      if (_expanded) {
        onShow();
      } else {
        onHide();
      }
    }
  }

  bool toggle() {
    expanded = !expanded;
    return expanded;
  }

  /// Fired when the tree row is expanded. Add children rows here.
  void onShow();

  /// Fired when the tree row is collapsed.
  void onHide();
}

class TableTree extends Observable {
  final List<String> columnHeaders = [];
  @observable final List<TableTreeRow> rows = toObservable([]);

  /// Create a table tree with column [headers].
  TableTree(List<String> headers) {
    columnHeaders.addAll(headers);
  }

  /// Initialize the table tree with the list of root children.
  void initialize(List<TableTreeRow> children) {
    rows.clear();
    rows.addAll(children);
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

  void _insertRow(int index, TableTreeRow row) {
    if (index == -1) {
      rows.add(row);
    } else {
      rows.insert(index, row);
    }
  }

  void _expand(TableTreeRow row) {
    int index = _index(row);
    assert(index != -1);
    for (var i = 0; i < row.children.length; i++) {
      _insertRow(index + i + 1, row.children[i]);
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
    for (var i = 0; i < childCount; i++) {
      rows.removeAt(index + 1);
    }
  }
}
