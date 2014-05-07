// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_profile_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

/// Displays an Error response.
@CustomTag('heap-profile')
class HeapProfileElement extends ObservatoryElement {
  // Indexes into VM provided map.
  static const ALLOCATED_BEFORE_GC = 0;
  static const ALLOCATED_BEFORE_GC_SIZE = 1;
  static const LIVE_AFTER_GC = 2;
  static const LIVE_AFTER_GC_SIZE = 3;
  static const ALLOCATED_SINCE_GC = 4;
  static const ALLOCATED_SINCE_GC_SIZE = 5;
  static const ACCUMULATED = 6;
  static const ACCUMULATED_SIZE = 7;

  // Pie chart of new space usage.
  var _newPieDataTable;
  var _newPieChart;

  // Pie chart of old space usage.
  var _oldPieDataTable;
  var _oldPieChart;

  @observable SortedTable classTable;

  @published ServiceMap profile;

  HeapProfileElement.created() : super.created() {
    _newPieDataTable = new DataTable();
    _newPieDataTable.addColumn('string', 'Type');
    _newPieDataTable.addColumn('number', 'Size');
    _oldPieDataTable = new DataTable();
    _oldPieDataTable.addColumn('string', 'Type');
    _oldPieDataTable.addColumn('number', 'Size');
    var columns = [
      new SortedTableColumn('Class'),
      new SortedTableColumn.withFormatter('Accumulator Size (New)',
                                          Utils.formatSize),
      new SortedTableColumn.withFormatter('Accumulator (New)',
                                          Utils.formatCommaSeparated),
      new SortedTableColumn.withFormatter('Current Size (New)',
                                          Utils.formatSize),
      new SortedTableColumn.withFormatter('Current (New)',
                                          Utils.formatCommaSeparated),
      new SortedTableColumn.withFormatter('Accumulator Size (Old)',
                                          Utils.formatSize),
      new SortedTableColumn.withFormatter('Accumulator (Old)',
                                          Utils.formatCommaSeparated),
      new SortedTableColumn.withFormatter('Current Size (Old)',
                                          Utils.formatSize),
      new SortedTableColumn.withFormatter('Current (Old)',
                                          Utils.formatCommaSeparated)
    ];
    classTable = new SortedTable(columns);
    classTable.sortColumnIndex = 1;
  }

  void enteredView() {
    super.enteredView();
    _newPieChart = new Chart('PieChart',
        shadowRoot.querySelector('#newPieChart'));
    _newPieChart.options['title'] = 'New Space';
    _oldPieChart = new Chart('PieChart',
        shadowRoot.querySelector('#oldPieChart'));
    _oldPieChart.options['title'] = 'Old Space';
    _draw();
  }

  void _updateChartData() {
    if ((profile == null) || (profile['members'] is! List) ||
        (profile['members'].length == 0)) {
      return;
    }
    assert(classTable != null);
    classTable.clearRows();
    for (ServiceMap cls in profile['members']) {
      if (_classHasNoAllocations(cls)) {
        // If a class has no allocations, don't display it.
        continue;
      }
      var row = [cls['class'],
                 _combinedTableColumnValue(cls, 1),
                 _combinedTableColumnValue(cls, 2),
                 _combinedTableColumnValue(cls, 3),
                 _combinedTableColumnValue(cls, 4),
                 _combinedTableColumnValue(cls, 5),
                 _combinedTableColumnValue(cls, 6),
                 _combinedTableColumnValue(cls, 7),
                 _combinedTableColumnValue(cls, 8)];
      classTable.addRow(new SortedTableRow(row));
    }
    classTable.sort();
    _newPieDataTable.clearRows();
    var heap = profile['heaps']['new'];
    _newPieDataTable.addRow(['Used', heap['used']]);
    _newPieDataTable.addRow(['Free', heap['capacity'] - heap['used']]);
    _newPieDataTable.addRow(['External', heap['external']]);
    _oldPieDataTable.clearRows();
    heap = profile['heaps']['old'];
    _oldPieDataTable.addRow(['Used', heap['used']]);
    _oldPieDataTable.addRow(['Free', heap['capacity'] - heap['used']]);
    _oldPieDataTable.addRow(['External', heap['external']]);
    _draw();
  }

  void _draw() {
    if (_newPieChart == null) {
      return;
    }
    _newPieChart.draw(_newPieDataTable);
    _oldPieChart.draw(_oldPieDataTable);
  }

  @observable void changeSort(Event e, var detail, Element target) {
    if (target is TableCellElement) {
      if (classTable.sortColumnIndex != target.cellIndex) {
        classTable.sortColumnIndex = target.cellIndex;
        classTable.sort();
      }
    }
  }

  bool _classHasNoAllocations(Map v) {
    var newSpace = v['new'];
    var oldSpace = v['old'];
    for (var allocation in newSpace) {
      if (allocation != 0) {
        return false;
      }
    }
    for (var allocation in oldSpace) {
      if (allocation != 0) {
        return false;
      }
    }
    return true;
  }

  dynamic _combinedTableColumnValue(Map v, int index) {
    assert(index >= 0);
    assert(index < 9);
    switch (index) {
      case 0:
        return v['class']['user_name'];
      case 1:
        return v['new'][ACCUMULATED_SIZE];
      case 2:
        return v['new'][ACCUMULATED];
      case 3:
        return v['new'][LIVE_AFTER_GC_SIZE] +
               v['new'][ALLOCATED_SINCE_GC_SIZE];
      case 4:
        return v['new'][LIVE_AFTER_GC] +
               v['new'][ALLOCATED_SINCE_GC];
      case 5:
        return v['old'][ACCUMULATED_SIZE];
      case 6:
        return v['old'][ACCUMULATED];
      case 7:
        return v['old'][LIVE_AFTER_GC_SIZE] +
               v['old'][ALLOCATED_SINCE_GC_SIZE];
      case 8:
        return  v['old'][LIVE_AFTER_GC] +
               v['old'][ALLOCATED_SINCE_GC];
    }
    throw new FallThroughError();
  }

  void refresh(var done) {
    if (profile == null) {
      return;
    }
    var isolate = profile.isolate;
    isolate.get('/allocationprofile').then((ServiceMap response) {
      assert(response['type'] == 'AllocationProfile');
      profile = response;
    }).catchError((e, st) {
      Logger.root.info('$e $st');
    }).whenComplete(done);
  }

  void refreshGC(var done) {
      if (profile == null) {
        return;
      }
      var isolate = profile.isolate;
      isolate.get('/allocationprofile?gc=full').then((ServiceMap response) {
        assert(response['type'] == 'AllocationProfile');
        profile = response;
      }).catchError((e, st) {
        Logger.root.info('$e $st');
      }).whenComplete(done);
    }

  void resetAccumulator(var done) {
    if (profile == null) {
      return;
    }
    var isolate = profile.isolate;
    isolate.get('/allocationprofile?reset=true').then((ServiceMap response) {
      assert(response['type'] == 'AllocationProfile');
      profile = response;
    }).catchError((e, st) {
      Logger.root.info('$e $st');
    }).whenComplete(done);
  }

  void profileChanged(oldValue) {
    try {
      _updateChartData();
    } catch (e, st) {
      Logger.root.info('$e $st');
    }
    notifyPropertyChange(#formattedAverage, [], formattedAverage);
    notifyPropertyChange(#formattedTotalCollectionTime, [],
                         formattedTotalCollectionTime);
    notifyPropertyChange(#formattedCollections, [], formattedCollections);
  }

  @observable String formattedAverage(bool newSpace) {
    if (profile == null) {
      return '';
    }
    String space = newSpace ? 'new' : 'old';
    Map heap = profile['heaps'][space];
    var r = ((heap['time'] * 1000.0) / heap['collections']).toStringAsFixed(2);
    return '$r ms';
  }

  @observable String formattedCollections(bool newSpace) {
    if (profile == null) {
      return '';
    }
    String space = newSpace ? 'new' : 'old';
    Map heap = profile['heaps'][space];
    return '${heap['collections']}';
  }

  @observable String formattedTotalCollectionTime(bool newSpace) {
    if (profile == null) {
      return '';
    }
    String space = newSpace ? 'new' : 'old';
    Map heap = profile['heaps'][space];
    return '${Utils.formatSeconds(heap['time'])} secs';
  }
}