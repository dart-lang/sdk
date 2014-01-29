// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_profile_element;

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

  @published Map profile;
  @published List sortedProfile;
  int _sortColumnIndex = 1;
  HeapProfileElement.created() : super.created();

  // Display columns.
  @observable final List<String> columns = [
    'Class',
    'Current (new)',
    'Allocated Since GC (new)',
    'Total before GC (new)',
    'Survivors (new)',
    'Current (old)',
    'Allocated Since GC (old)',
    'Total before GC (old)',
    'Survivors (old)',
  ];

  dynamic _columnValue(Map v, int index) {
    assert(columns.length == 9);
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

  int _sortColumn(Map a, Map b, int index) {
    var aValue = _columnValue(a, index);
    var bValue = _columnValue(b, index);
    return Comparable.compare(bValue, aValue);
  }

  _sort() {
    if ((profile == null) || (profile['members'] is! List) ||
        (profile['members'].length == 0)) {
      sortedProfile = toObservable([]);
      return;
    }
    sortedProfile = profile['members'].toList();
    sortedProfile.sort((a, b) => _sortColumn(a, b, _sortColumnIndex));
    sortedProfile = toObservable(sortedProfile);
    notifyPropertyChange(#sortedProfile, [], sortedProfile);
    notifyPropertyChange(#current, 0, 1);
    notifyPropertyChange(#allocated, 0, 1);
    notifyPropertyChange(#beforeGC, 0, 1);
    notifyPropertyChange(#afterGC, 0, 1);
  }

  void changeSortColumn(Event e, var detail, Element target) {
    var message = target.attributes['data-msg'];
    var index;
    try {
      index = int.parse(message);
    } catch (e) {
      return;
    }
    assert(index is int);
    assert(index > 0);
    assert(index < columns.length);
    _sortColumnIndex = index;
    _sort();
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
    _sort();
    notifyPropertyChange(#status, [], status);
  }

  String status(bool new_space) {
    if (profile == null) {
      return '';
    }
    String space = new_space ? 'new' : 'old';
    Map heap = profile['heaps'][space];
    var usage = '${ObservatoryApplication.scaledSizeUnits(heap['used'])} / '
                '${ObservatoryApplication.scaledSizeUnits(heap['capacity'])}';
    var timings = '${ObservatoryApplication.timeUnits(heap['time'])} secs';
    var collections = '${heap['collections']} collections';
    var avgTime = '${(heap['time'] * 1000.0) / heap['collections']} ms';
    return '$usage ($timings) [$collections] $avgTime';
  }

  String current(Map cls, bool new_space, [bool instances = false]) {
    if (cls is !Map) {
      return '';
    }
    List data = cls[new_space ? 'new' : 'old'];
    if (data == null) {
      return '';
    }
    int current = data[instances ? LIVE_AFTER_GC : LIVE_AFTER_GC_SIZE] +
        data[instances ? ALLOCATED_SINCE_GC : ALLOCATED_SINCE_GC_SIZE];
    if (instances) {
      return '$current';
    }
    return ObservatoryApplication.scaledSizeUnits(current);
  }

  String allocated(Map cls, bool new_space, [bool instances = false]) {
    if (cls is !Map) {
      return '';
    }
    List data = cls[new_space ? 'new' : 'old'];
    if (data == null) {
      return '';
    }
    int current =
        data[instances ? ALLOCATED_SINCE_GC : ALLOCATED_SINCE_GC_SIZE];
    if (instances) {
      return '$current';
    }
    return ObservatoryApplication.scaledSizeUnits(current);
  }

  String beforeGC(Map cls, bool new_space, [bool instances = false]) {
    if (cls is! Map) {
      return '';
    }
    List data = cls[new_space ? 'new' : 'old'];
    if (data == null) {
      return '';
    }
    int current =
        data[instances ? ALLOCATED_BEFORE_GC : ALLOCATED_BEFORE_GC_SIZE];
    if (instances) {
      return '$current';
    }
    return ObservatoryApplication.scaledSizeUnits(current);
  }

  String afterGC(Map cls, bool new_space, [bool instances = false]) {
    if (cls is! Map) {
      return '';
    }
    List data = cls[new_space ? 'new' : 'old'];
    if (data == null) {
      return '';
    }
    int current = data[instances ? LIVE_AFTER_GC : LIVE_AFTER_GC_SIZE];
    if (instances) {
      return '$current';
    }
    return ObservatoryApplication.scaledSizeUnits(current);
  }
}