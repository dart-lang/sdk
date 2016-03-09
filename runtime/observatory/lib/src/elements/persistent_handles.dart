// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library persitent_handles_page;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

class WeakPersistentHandlesSortedTable extends SortedTable {
  factory WeakPersistentHandlesSortedTable() {
    var columns = [
      new SortedTableColumn.withFormatter('External Size',
                                          Utils.formatSize),
      new SortedTableColumn('Peer'),
      new SortedTableColumn('Finalizer Callback'),
      new SortedTableColumn(''),  // Spacer column.
      new SortedTableColumn('Object'),
    ];
    WeakPersistentHandlesSortedTable result =
        new WeakPersistentHandlesSortedTable._(columns);
    // Sort by external size.
    result.sortColumnIndex = 0;
    return result;
  }

  WeakPersistentHandlesSortedTable._(columns) : super(columns);

  @override
  dynamic getSortKeyFor(int row, int col) {
    return super.getSortKeyFor(row, col);
  }

  void update(List<ServiceMap> handles, HtmlElement tableBody) {
    clearRows();
    for (ServiceMap handle in handles) {
      var row = [int.parse(handle['externalSize'], onError: (_) => 0),
                 handle['peer'],
                 handle['callbackSymbolName'] +
                 '( ${handle['callbackAddress']} )',
                 '', // Spacer column.
                 handle['object']];
      addRow(new SortedTableRow(row));
      print(row);
    }
    sort();
    _updateTableInDom(tableBody);
  }

  void sortAndDisplay(HtmlElement tableBody) {
    sort();
    _updateTableInDom(tableBody);
  }


  void _updateTableInDom(HtmlElement tableBody) {
    assert(tableBody != null);
    // Resize DOM table.
    if (tableBody.children.length > sortedRows.length) {
      // Shrink the table.
      var deadRows =
          tableBody.children.length - sortedRows.length;
      for (var i = 0; i < deadRows; i++) {
        tableBody.children.removeLast();
      }
    } else if (tableBody.children.length < sortedRows.length) {
      // Grow table.
      var newRows = sortedRows.length - tableBody.children.length;
      for (var i = 0; i < newRows; i++) {
        _addDomRow(tableBody);
      }
    }
    assert(tableBody.children.length == sortedRows.length);
    // Fill table.
    for (var i = 0; i < sortedRows.length; i++) {
      var rowIndex = sortedRows[i];
      var tr = tableBody.children[i];
      _fillDomRow(tr, rowIndex);
    }
  }

  void _addDomRow(HtmlElement tableBody) {
    // Add empty dom row.
    var tr = new TableRowElement();

    var cell;

    cell = tr.insertCell(-1);
    cell = tr.insertCell(-1);
    cell = tr.insertCell(-1);

    // Add spacer.
    cell = tr.insertCell(-1);
    cell.classes.add('left-border-spacer');

    // Add class ref.
    cell = tr.insertCell(-1);
    AnyServiceRefElement objectRef = new Element.tag('any-service-ref');
    cell.children.add(objectRef);

    // Add row to table.
    tableBody.children.add(tr);
  }

  void _fillDomRow(TableRowElement tr, int rowIndex) {
    var row = rows[rowIndex];

    for (var i = 0; i < row.values.length - 2; i++) {
      var cell = tr.children[i];
      cell.title = row.values[i].toString();
      cell.text = getFormattedValue(rowIndex, i);
      cell.style.paddingLeft = '1em';
      cell.style.paddingRight = '1em';
    }

    final int objectIndex = row.values.length - 1;
    AnyServiceRefElement objectRef = tr.children[objectIndex].children[0];
    objectRef.ref = row.values[objectIndex];
  }
}


@CustomTag('persistent-handles-page')
class PersistentHandlesPageElement extends ObservatoryElement {
  PersistentHandlesPageElement.created() : super.created();

  @observable Isolate isolate;
  @observable var /*ObservableList | ServiceObject*/ persistentHandles;
  @observable var /*ObservableList | ServiceObject*/ weakPersistentHandles;
  @observable WeakPersistentHandlesSortedTable weakPersistentHandlesTable;
  var _weakPersistentHandlesTableBody;

  void isolateChanged(oldValue) {
    if (isolate != null) {
      refresh();
    }
  }

  @override
  void attached() {
    super.attached();
    _weakPersistentHandlesTableBody =
        shadowRoot.querySelector('#weakPersistentHandlesTableBody');
    weakPersistentHandlesTable =
        new WeakPersistentHandlesSortedTable();
  }

  Future refresh() {
    return isolate.getPersistentHandles().then(_refreshView);
  }

  _refreshView(/*ObservableList | ServiceObject*/ object) {
    persistentHandles = object['persistentHandles'];
    weakPersistentHandles = object['weakPersistentHandles'];
    weakPersistentHandlesTable.update(
        weakPersistentHandles,
        _weakPersistentHandlesTableBody);
  }

  @observable void changeSort(Event e, var detail, Element target) {
    if (target is TableCellElement) {
      if (weakPersistentHandlesTable.sortColumnIndex != target.cellIndex) {
        weakPersistentHandlesTable.sortColumnIndex = target.cellIndex;
        weakPersistentHandlesTable.sortDescending = true;
      } else {
        weakPersistentHandlesTable.sortDescending =
            !weakPersistentHandlesTable.sortDescending;
      }
      weakPersistentHandlesTable.sortAndDisplay(
          _weakPersistentHandlesTableBody);
    }
  }
}
