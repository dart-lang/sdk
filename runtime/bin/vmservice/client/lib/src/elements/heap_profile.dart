// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_profile_element;

import 'dart:html';
import 'isolate_element.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'package:observatory/app.dart';

/// Displays an Error response.
@CustomTag('heap-profile')
class HeapProfileElement extends IsolateElement {
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

  // The combined chart has old and new space merged.
  var _combinedDataTable;
  var _combinedChart;

  // The full chart has separate columns for new and old space.
  var _fullDataTable;
  var _fullChart;

  @published Map profile;

  HeapProfileElement.created() : super.created() {
    _fullDataTable = new DataTable();
    _fullDataTable.addColumn('string', 'Class');
    _fullDataTable.addColumn('number', 'Current (new)');
    _fullDataTable.addColumn('number', 'Allocated Since GC (new)');
    _fullDataTable.addColumn('number', 'Total before GC (new)');
    _fullDataTable.addColumn('number', 'Survivors (new)');
    _fullDataTable.addColumn('number', 'Current (old)');
    _fullDataTable.addColumn('number', 'Allocated Since GC (old)');
    _fullDataTable.addColumn('number', 'Total before GC (old)');
    _fullDataTable.addColumn('number', 'Survivors (old)');
    _newPieDataTable = new DataTable();
    _newPieDataTable.addColumn('string', 'Type');
    _newPieDataTable.addColumn('number', 'Size');
    _oldPieDataTable = new DataTable();
    _oldPieDataTable.addColumn('string', 'Type');
    _oldPieDataTable.addColumn('number', 'Size');
    _combinedDataTable = new DataTable();
    _combinedDataTable.addColumn('string', 'Class');
    _combinedDataTable.addColumn('number', 'Accumulator');
    _combinedDataTable.addColumn('number', 'Accumulator Instances');
    _combinedDataTable.addColumn('number', 'Current');
    _combinedDataTable.addColumn('number', 'Allocated Since GC');
    _combinedDataTable.addColumn('number', 'Total before GC');
    _combinedDataTable.addColumn('number', 'Survivors after GC');
  }

  void enteredView() {
    super.enteredView();
    _fullChart = new Chart('Table',
        shadowRoot.querySelector('#table'));
    _fullChart.options['allowHtml'] = true;
    _fullChart.options['sortColumn'] = 1;
    _fullChart.options['sortAscending'] = false;
    _newPieChart = new Chart('PieChart',
        shadowRoot.querySelector('#newPieChart'));
    _newPieChart.options['title'] = 'New Space';
    _oldPieChart = new Chart('PieChart',
        shadowRoot.querySelector('#oldPieChart'));
    _oldPieChart.options['title'] = 'Old Space';
    _combinedChart = new Chart('Table',
        shadowRoot.querySelector('#simpleTable'));
    _combinedChart.options['allowHtml'] = true;
    _combinedChart.options['sortColumn'] = 1;
    _combinedChart.options['sortAscending'] = false;
    _draw();
  }

  bool _first = true;

  void _updateChartData() {
    if ((profile == null) || (profile['members'] is! List) ||
        (profile['members'].length == 0)) {
      return;
    }
    assert(_fullDataTable != null);
    assert(_combinedDataTable != null);
    _fullDataTable.clearRows();
    _combinedDataTable.clearRows();
    for (Map cls in profile['members']) {
      if (_classHasNoAllocations(cls)) {
        // If a class has no allocations, don't display it.
        continue;
      }
      var vm_name = cls['class']['name'];
      var url = isolate.relativeLink(cls['class']['id']);
      _fullDataTable.addRow([
          '<a title="$vm_name" href="$url">'
          '${_fullTableColumnValue(cls, 0)}</a>',
          _fullTableColumnValue(cls, 1),
          _fullTableColumnValue(cls, 2),
          _fullTableColumnValue(cls, 3),
          _fullTableColumnValue(cls, 4),
          _fullTableColumnValue(cls, 5),
          _fullTableColumnValue(cls, 6),
          _fullTableColumnValue(cls, 7),
          _fullTableColumnValue(cls, 8)]);
      _combinedDataTable.addRow([
           '<a title="$vm_name" href="$url">'
           '${_combinedTableColumnValue(cls, 0)}</a>',
           _combinedTableColumnValue(cls, 1),
           _combinedTableColumnValue(cls, 2),
           _combinedTableColumnValue(cls, 3),
           _combinedTableColumnValue(cls, 4),
           _combinedTableColumnValue(cls, 5),
           _combinedTableColumnValue(cls, 6)]);
    }
    _newPieDataTable.clearRows();
    var heap = profile['heaps']['new'];
    _newPieDataTable.addRow(['Used', heap['used']]);
    _newPieDataTable.addRow(['Free', heap['capacity'] - heap['used']]);
    _oldPieDataTable.clearRows();
    heap = profile['heaps']['old'];
    _oldPieDataTable.addRow(['Used', heap['used']]);
    _oldPieDataTable.addRow(['Free', heap['capacity'] - heap['used']]);
    _draw();
  }

  void _draw() {
    if ((_fullChart == null) || (_combinedChart == null)) {
      return;
    }
    _combinedChart.refreshOptionsSortInfo();
    _combinedChart.draw(_combinedDataTable);
    _fullChart.refreshOptionsSortInfo();
    _fullChart.draw(_fullDataTable);
    _newPieChart.draw(_newPieDataTable);
    _oldPieChart.draw(_oldPieDataTable);
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

  dynamic _fullTableColumnValue(Map v, int index) {
    assert(index >= 0);
    assert(index < 9);
    switch (index) {
      case 0:
        return v['class']['user_name'];
      case 1:
        return v['new'][LIVE_AFTER_GC_SIZE] + v['new'][ALLOCATED_SINCE_GC_SIZE];
      case 2:
        return v['new'][ALLOCATED_SINCE_GC_SIZE];
      case 3:
        return v['new'][ALLOCATED_BEFORE_GC_SIZE];
      case 4:
        return v['new'][LIVE_AFTER_GC_SIZE];
      case 5:
        return v['old'][LIVE_AFTER_GC_SIZE] + v['old'][ALLOCATED_SINCE_GC_SIZE];
      case 6:
        return v['old'][ALLOCATED_SINCE_GC_SIZE];
      case 7:
        return v['old'][ALLOCATED_BEFORE_GC_SIZE];
      case 8:
        return v['old'][LIVE_AFTER_GC_SIZE];
    }
    throw new FallThroughError();
  }

  dynamic _combinedTableColumnValue(Map v, int index) {
    assert(index >= 0);
    assert(index < 7);
    switch (index) {
      case 0:
        return v['class']['user_name'];
      case 1:
        return v['new'][ACCUMULATED_SIZE] +
               v['old'][ACCUMULATED_SIZE];
      case 2:
        return v['new'][ACCUMULATED] +
               v['old'][ACCUMULATED];
      case 3:
        return v['new'][LIVE_AFTER_GC_SIZE] +
               v['new'][ALLOCATED_SINCE_GC_SIZE] +
               v['old'][LIVE_AFTER_GC_SIZE] +
               v['old'][ALLOCATED_SINCE_GC_SIZE];
      case 4:
        return v['new'][ALLOCATED_SINCE_GC_SIZE] +
               v['old'][ALLOCATED_SINCE_GC_SIZE];
      case 5:
        return v['new'][ALLOCATED_BEFORE_GC_SIZE] +
               v['old'][ALLOCATED_BEFORE_GC_SIZE];
      case 6:
        return v['new'][LIVE_AFTER_GC_SIZE] + v['old'][LIVE_AFTER_GC_SIZE];
    }
    throw new FallThroughError();
  }

  void refresh(var done) {
    isolate.getMap('/allocationprofile').then((Map response) {
      assert(response['type'] == 'AllocationProfile');
      profile = response;
    }).catchError((e, st) {
      Logger.root.info('$e $st');
    }).whenComplete(done);
  }

  void resetAccumulator(Event e, var detail, Node target) {
    isolate.getMap('/allocationprofile/reset').then((Map response) {
      assert(response['type'] == 'AllocationProfile');
      profile = response;
    }).catchError((e, st) {
      Logger.root.info('$e $st');
    });
  }

  void profileChanged(oldValue) {
    _updateChartData();
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
    return '${ObservatoryApplication.timeUnits(heap['time'])} secs';
  }
}