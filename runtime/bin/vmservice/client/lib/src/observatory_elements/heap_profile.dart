// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_profile_element;

import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

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

  var _newPieDataTable;
  var _newPieChart;

  var _oldPieDataTable;
  var _oldPieChart;

  var _tableDataTable;
  var _tableChart;

  @published Map profile;

  HeapProfileElement.created() : super.created() {
    _tableDataTable = new DataTable();
    _tableDataTable.addColumn('string', 'Class');
    _tableDataTable.addColumn('number', 'Current (new)');
    _tableDataTable.addColumn('number', 'Allocated Since GC (new)');
    _tableDataTable.addColumn('number', 'Total before GC (new)');
    _tableDataTable.addColumn('number', 'Survivors (new)');
    _tableDataTable.addColumn('number', 'Current (old)');
    _tableDataTable.addColumn('number', 'Allocated Since GC (old)');
    _tableDataTable.addColumn('number', 'Total before GC (old)');
    _tableDataTable.addColumn('number', 'Survivors (old)');
    _newPieDataTable = new DataTable();
    _newPieDataTable.addColumn('string', 'Type');
    _newPieDataTable.addColumn('number', 'Size');
    _oldPieDataTable = new DataTable();
    _oldPieDataTable.addColumn('string', 'Type');
    _oldPieDataTable.addColumn('number', 'Size');
  }

  void enteredView() {
    super.enteredView();
    _tableChart = new Chart('Table',
        shadowRoot.querySelector('#table'));
    _tableChart.options['allowHtml'] = true;
    _tableChart.options['sortColumn'] = 1;
    _tableChart.options['sortAscending'] = false;
    _newPieChart = new Chart('PieChart',
        shadowRoot.querySelector('#newPieChart'));
    _newPieChart.options['title'] = 'New Space';
    _oldPieChart = new Chart('PieChart',
        shadowRoot.querySelector('#oldPieChart'));
    _oldPieChart.options['title'] = 'Old Space';
    _draw();
  }

  bool _first = true;

  void _updateChartData() {
    if ((profile == null) || (profile['members'] is! List) ||
        (profile['members'].length == 0)) {
      return;
    }
    assert(_tableDataTable != null);
    _tableDataTable.clearRows();
    for (Map cls in profile['members']) {
      var url =
          app.locationManager.currentIsolateRelativeLink(cls['class']['id']);
      _tableDataTable.addRow(
          ['<a href="$url">${_columnValue(cls, 0)}</a>',
           _columnValue(cls, 1),
           _columnValue(cls, 2),
           _columnValue(cls, 3),
           _columnValue(cls, 4),
           _columnValue(cls, 5),
           _columnValue(cls, 6),
           _columnValue(cls, 7),
           _columnValue(cls, 8)]);
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
    if (_tableChart == null) {
      return;
    }
    _tableChart.draw(_tableDataTable);
    _newPieChart.draw(_newPieDataTable);
    _oldPieChart.draw(_oldPieDataTable);
  }

  dynamic _columnValue(Map v, int index) {
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
  }

  void refreshData(Event e, var detail, Node target) {
    var isolateId = app.locationManager.currentIsolateId();
    var isolate = app.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      Logger.root.info('No isolate found.');
      return;
    }
    var request = '/$isolateId/allocationprofile';
    app.requestManager.requestMap(request).then((Map response) {
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