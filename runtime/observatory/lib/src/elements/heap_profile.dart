// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_profile_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/elements.dart';
import 'package:polymer/polymer.dart';

class ClassSortedTable extends SortedTable {

  ClassSortedTable(columns) : super(columns);

  @override
  dynamic getSortKeyFor(int row, int col) {
    if (col == 0) {
      // Use class name as sort key.
      return rows[row].values[col].name;
    }
    return super.getSortKeyFor(row, col);
  }
}

/// Displays an Error response.
@CustomTag('heap-profile')
class HeapProfileElement extends ObservatoryElement {
  @observable String lastServiceGC = '---';
  @observable String lastAccumulatorReset = '---';

  // Pie chart of new space usage.
  var _newPieDataTable;
  var _newPieChart;

  // Pie chart of old space usage.
  var _oldPieDataTable;
  var _oldPieChart;

  @observable ClassSortedTable classTable;
  var _classTableBody;

  @published ServiceMap profile;
  @published bool autoRefresh = false;
  var _subscription;

  @observable Isolate isolate;

  HeapProfileElement.created() : super.created() {
    // Create pie chart models.
    _newPieDataTable = new DataTable();
    _newPieDataTable.addColumn('string', 'Type');
    _newPieDataTable.addColumn('number', 'Size');
    _oldPieDataTable = new DataTable();
    _oldPieDataTable.addColumn('string', 'Type');
    _oldPieDataTable.addColumn('number', 'Size');

    // Create class table model.
    var columns = [
      new SortedTableColumn('Class'),
      new SortedTableColumn(''),  // Spacer column.
      new SortedTableColumn.withFormatter('Accumulated Size (New)',
                                          Utils.formatSize),
      new SortedTableColumn.withFormatter('Accumulated Instances',
                                          Utils.formatCommaSeparated),
      new SortedTableColumn.withFormatter('Current Size',
                                          Utils.formatSize),
      new SortedTableColumn.withFormatter('Current Instances',
                                          Utils.formatCommaSeparated),
      new SortedTableColumn(''),  // Spacer column.
      new SortedTableColumn.withFormatter('Accumulator Size (Old)',
                                          Utils.formatSize),
      new SortedTableColumn.withFormatter('Accumulator Instances',
                                          Utils.formatCommaSeparated),
      new SortedTableColumn.withFormatter('Current Size',
                                          Utils.formatSize),
      new SortedTableColumn.withFormatter('Current Instances',
                                          Utils.formatCommaSeparated)
    ];
    classTable = new ClassSortedTable(columns);
    // By default, start with accumulated new space bytes.
    classTable.sortColumnIndex = 2;
  }

  @override
  void attached() {
    super.attached();
    // Grab the pie chart divs.
    _newPieChart = new Chart('PieChart',
        shadowRoot.querySelector('#newPieChart'));
    _oldPieChart = new Chart('PieChart',
        shadowRoot.querySelector('#oldPieChart'));
    _classTableBody = shadowRoot.querySelector('#classTableBody');
    _subscription = app.vm.events.stream.where(
        (event) => event.isolate == isolate).listen(_onEvent);
  }

  @override
  void detached() {
    _subscription.cancel((){});
    super.detached();
  }
  
  void _onEvent(ServiceEvent event) {
    if (autoRefresh && event.eventType == 'GC') {
      refresh((){});
    }
  }
  
  void _updatePieCharts() {
    assert(profile != null);
    _newPieDataTable.clearRows();
    var isolate = profile.isolate;
    _newPieDataTable.addRow(['Used', isolate.newSpace.used]);
    _newPieDataTable.addRow(['Free',
        isolate.newSpace.capacity - isolate.newSpace.used]);
    _newPieDataTable.addRow(['External', isolate.newSpace.external]);
    _oldPieDataTable.clearRows();
    _oldPieDataTable.addRow(['Used', isolate.oldSpace.used]);
    _oldPieDataTable.addRow(['Free',
        isolate.oldSpace.capacity - isolate.oldSpace.used]);
    _oldPieDataTable.addRow(['External', isolate.oldSpace.external]);
  }

  void _updateClasses() {
    for (ServiceMap clsAllocations in profile['members']) {
      Class cls = clsAllocations['class'];
      if (cls == null) {
        continue;
      }
      cls.newSpace.update(clsAllocations['new']);
      cls.oldSpace.update(clsAllocations['old']);
    }
  }

  void _updateClassTable() {
    classTable.clearRows();
    for (ServiceMap clsAllocations in profile['members']) {
      Class cls = clsAllocations['class'];
      if (cls == null) {
        continue;
      }
      if (cls.hasNoAllocations) {
        // If a class has no allocations, don't display it.
        continue;
      }
      var row = [cls,
                 '',  // Spacer column.
                 cls.newSpace.accumulated.bytes,
                 cls.newSpace.accumulated.instances,
                 cls.newSpace.current.bytes,
                 cls.newSpace.current.instances,
                 '', // Spacer column.
                 cls.oldSpace.accumulated.bytes,
                 cls.oldSpace.accumulated.instances,
                 cls.oldSpace.current.bytes,
                 cls.oldSpace.current.instances];
      classTable.addRow(new SortedTableRow(row));
    }
    classTable.sort();
  }

  void _addClassTableDomRow() {
    assert(_classTableBody != null);
    var tr = new TableRowElement();

    // Add class ref.
    var cell = tr.insertCell(-1);
    ClassRefElement classRef = new Element.tag('class-ref');
    cell.children.add(classRef);

    // Add spacer.
    cell = tr.insertCell(-1);
    cell.classes.add('left-border-spacer');

    // Add new space.
    cell = tr.insertCell(-1);
    cell = tr.insertCell(-1);
    cell = tr.insertCell(-1);
    cell = tr.insertCell(-1);

    // Add spacer.
    cell = tr.insertCell(-1);
    cell.classes.add('left-border-spacer');

    // Add old space.
    cell = tr.insertCell(-1);
    cell = tr.insertCell(-1);
    cell = tr.insertCell(-1);
    cell = tr.insertCell(-1);

    // Add row to table.
    _classTableBody.children.add(tr);
  }

  void _fillClassTableDomRow(TableRowElement tr, int rowIndex) {
    const SPACER_COLUMNS = const [1, 6];

    var row = classTable.rows[rowIndex];
    // Add class ref.
    ClassRefElement classRef = tr.children[0].children[0];
    classRef.ref = row.values[0];

    for (var i = 1; i < row.values.length; i++) {
      if (SPACER_COLUMNS.contains(i)) {
        // Skip spacer columns.
        continue;
      }
      var cell = tr.children[i];
      cell.title = row.values[i].toString();
      cell.text = classTable.getFormattedValue(rowIndex, i);
    }
  }

  void _updateClassTableInDom() {
    assert(_classTableBody != null);
    // Resize DOM table.
    if (_classTableBody.children.length > classTable.sortedRows.length) {
      // Shrink the table.
      var deadRows =
          _classTableBody.children.length - classTable.sortedRows.length;
      for (var i = 0; i < deadRows; i++) {
        _classTableBody.children.removeLast();
      }
    } else if (_classTableBody.children.length < classTable.sortedRows.length) {
      // Grow table.
      var newRows =
          classTable.sortedRows.length - _classTableBody.children.length;
      for (var i = 0; i < newRows; i++) {
        _addClassTableDomRow();
      }
    }
    assert(_classTableBody.children.length == classTable.sortedRows.length);
    // Fill table.
    for (var i = 0; i < classTable.sortedRows.length; i++) {
      var rowIndex = classTable.sortedRows[i];
      var tr = _classTableBody.children[i];
      _fillClassTableDomRow(tr, rowIndex);
    }
  }

  void _drawCharts() {
    _newPieChart.draw(_newPieDataTable);
    _oldPieChart.draw(_oldPieDataTable);
  }

  @observable void changeSort(Event e, var detail, Element target) {
    if (target is TableCellElement) {
      if (classTable.sortColumnIndex != target.cellIndex) {
        classTable.sortColumnIndex = target.cellIndex;
        classTable.sortDescending = true;
      } else {
        classTable.sortDescending = !classTable.sortDescending;
      }
      classTable.sort();
      _updateClassTableInDom();
    }
  }

  void refresh(var done) {
    if (profile == null) {
      return;
    }
    var isolate = profile.isolate;
    isolate.get('/allocationprofile').then(_update).whenComplete(done);
  }

  void refreshGC(var done) {
    if (profile == null) {
      return;
    }
    var isolate = profile.isolate;
    isolate.get('/allocationprofile?gc=full').then(_update).whenComplete(done);
  }

  void resetAccumulator(var done) {
    if (profile == null) {
      return;
    }
    var isolate = profile.isolate;
    isolate.get('/allocationprofile?reset=true').then(_update).
                                                 whenComplete(done);
  }

  void _update(ServiceMap newProfile) {
    profile = newProfile;
  }

  void profileChanged(oldValue) {
    if (profile == null) {
      return;
    }
    isolate = profile.isolate;
    isolate.updateHeapsFromMap(profile['heaps']);
    var millis = int.parse(profile['dateLastAccumulatorReset']);
    if (millis != 0) {
      lastAccumulatorReset =
              new DateTime.fromMillisecondsSinceEpoch(millis).toString();
    }
    millis = int.parse(profile['dateLastServiceGC']);
    if (millis != 0) {
      lastServiceGC =
              new DateTime.fromMillisecondsSinceEpoch(millis).toString();
    }
    _updatePieCharts();
    _updateClasses();
    _updateClassTable();
    _updateClassTableInDom();
    _drawCharts();
    notifyPropertyChange(#formattedAverage, 0, 1);
    notifyPropertyChange(#formattedTotalCollectionTime, 0, 1);
    notifyPropertyChange(#formattedCollections, 0, 1);
  }

  @observable String formattedAverage(bool newSpace) {
    if (profile == null) {
      return '';
    }
    var heap = newSpace ? profile.isolate.newSpace : profile.isolate.oldSpace;
    var avg = ((heap.totalCollectionTimeInSeconds * 1000.0) / heap.collections);
    return '${avg.toStringAsFixed(2)} ms';
  }

  @observable String formattedCollections(bool newSpace) {
    if (profile == null) {
      return '';
    }
    var heap = newSpace ? profile.isolate.newSpace : profile.isolate.oldSpace;
    return heap.collections.toString();
  }

  @observable String formattedTotalCollectionTime(bool newSpace) {
    if (profile == null) {
      return '';
    }
    var heap = newSpace ? profile.isolate.newSpace : profile.isolate.oldSpace;
    return '${Utils.formatSeconds(heap.totalCollectionTimeInSeconds)} secs';
  }
}
