// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_profile_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:charted/charted.dart';
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

@CustomTag('heap-profile')
class HeapProfileElement extends ObservatoryElement {
  @observable String lastServiceGC = '---';
  @observable String lastAccumulatorReset = '---';

  // Pie chart of new space usage.
  var _newPieChart;
  final _newPieChartRows = [];
  // Pie chart of old space usage.
  var _oldPieChart;
  final _oldPieChartRows = [];

  @observable ClassSortedTable classTable;
  var _classTableBody;

  @published bool autoRefresh = false;
  var _subscriptionFuture;

  @published Isolate isolate;
  @observable ServiceMap profile;

  final _pieChartColumns = [
      new ChartColumnSpec(label: 'Type', type: ChartColumnSpec.TYPE_STRING),
      new ChartColumnSpec(label: 'Size', formatter: (v) => v.toString())
  ];

  HeapProfileElement.created() : super.created() {
    _initPieChartData(_newPieChartRows);
    _initPieChartData(_oldPieChartRows);

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

  LayoutArea _makePieChart(String id, List rows) {
    var wrapper = shadowRoot.querySelector(id);
    var areaHost = wrapper.querySelector('.chart-host');
    assert(areaHost != null);
    var legendHost = wrapper.querySelector('.chart-legend-host');
    assert(legendHost != null);
    var series = new ChartSeries(id, [1], new PieChartRenderer(
      sortDataByValue: false
    ));
    var config = new ChartConfig([series], [0]);
    config.minimumSize = new Rect(300, 300);
    config.legend = new ChartLegend(legendHost, showValues: true);
    var data = new ChartData(_pieChartColumns, rows);
    var area = new LayoutArea(areaHost,
                              data,
                              config,
                              state: new ChartState(),
                              autoUpdate: false);
    area.addChartBehavior(new Hovercard());
    area.addChartBehavior(new AxisLabelTooltip());
    return area;
  }

  @override
  void attached() {
    super.attached();
    _newPieChart = _makePieChart('#new-pie-chart', _newPieChartRows);
    _oldPieChart = _makePieChart('#old-pie-chart', _oldPieChartRows);
    _classTableBody = shadowRoot.querySelector('#classTableBody');
    _subscriptionFuture =
        app.vm.listenEventStream(VM.kGCStream, _onEvent);
  }

  @override
  void detached() {
    cancelFutureSubscription(_subscriptionFuture);
    _subscriptionFuture = null;
    super.detached();
  }

  // Keep at most one outstanding auto-refresh RPC.
  bool refreshAutoPending = false;
  bool refreshAutoQueued = false;

  void _onEvent(ServiceEvent event) {
    assert(event.kind == 'GC');
    if (autoRefresh) {
      if (!refreshAutoPending) {
        refreshAuto();
      } else {
        // Remember to refresh once more, to ensure latest profile.
        refreshAutoQueued = true;
      }
    }
  }

  void refreshAuto() {
    refreshAutoPending = true;
    refreshAutoQueued = false;
    refresh().then((_) {
      refreshAutoPending = false;
      // Keep refreshing if at least one GC event was received while waiting.
      if (refreshAutoQueued) {
        refreshAuto();
      }
    }).catchError(app.handleException);
  }

  static const _USED_INDEX = 0;
  static const _FREE_INDEX = 1;
  static const _EXTERNAL_INDEX = 2;

  static const _LABEL_INDEX = 0;
  static const _VALUE_INDEX = 1;

  void _initPieChartData(List rows) {
    rows.add(['Used', 0]);
    rows.add(['Free', 0]);
    rows.add(['External', 0]);
  }

  void _updatePieChartData(List rows, HeapSpace space) {
    rows[_USED_INDEX][_VALUE_INDEX] = space.used;
    rows[_FREE_INDEX][_VALUE_INDEX] = space.capacity - space.used;
    rows[_EXTERNAL_INDEX][_VALUE_INDEX] = space.external;
  }

  void _updatePieCharts() {
    assert(profile != null);
    _updatePieChartData(_newPieChartRows, isolate.newSpace);
    _updatePieChartData(_oldPieChartRows, isolate.oldSpace);
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
      if (i > 1) {  // Numbers.
        cell.style.textAlign = 'right';
        cell.style.paddingLeft = '1em';
      }
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
    _newPieChart.draw();
    _oldPieChart.draw();
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

  void isolateChanged(oldValue) {
    if (isolate == null) {
      profile = null;
      return;
    }
    isolate.invokeRpc('_getAllocationProfile', {})
      .then(_update)
      .catchError(app.handleException);
  }

  Future refresh() {
    if (isolate == null) {
      return new Future.value(null);
    }
    return isolate.invokeRpc('_getAllocationProfile', {})
        .then(_update);
  }

  Future refreshGC() {
    if (isolate == null) {
      return new Future.value(null);
    }
    return isolate.invokeRpc('_getAllocationProfile', { 'gc': 'full' })
        .then(_update);
  }

  Future resetAccumulator() {
    if (isolate == null) {
      return new Future.value(null);
    }
    return isolate.invokeRpc('_getAllocationProfile', { 'reset': 'true' })
        .then(_update);
  }

  void _update(ServiceMap newProfile) {
    profile = newProfile;
  }

  void profileChanged(oldValue) {
    if (profile == null) {
      return;
    }
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
    var heap = newSpace ? isolate.newSpace : isolate.oldSpace;
    var avg = ((heap.totalCollectionTimeInSeconds * 1000.0) / heap.collections);
    return '${avg.toStringAsFixed(2)} ms';
  }

  @observable String formattedCollections(bool newSpace) {
    if (profile == null) {
      return '';
    }
    var heap = newSpace ? isolate.newSpace : isolate.oldSpace;
    return heap.collections.toString();
  }

  @observable String formattedTotalCollectionTime(bool newSpace) {
    if (profile == null) {
      return '';
    }
    var heap = newSpace ? isolate.newSpace : isolate.oldSpace;
    return '${Utils.formatSeconds(heap.totalCollectionTimeInSeconds)} secs';
  }
}
