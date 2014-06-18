// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

class TagProfileChart {
  var _table = new DataTable();
  var _chart;

  void update(TagProfile tagProfile) {
    if (_table.columns == 0) {
      // Initialize.
      _table.addColumn('string', 'Time');
      for (var tagName in tagProfile.names) {
        if (tagName == 'Idle') {
          // Skip Idle tag.
          continue;
        }
        _table.addColumn('number', tagName);
      }
    }
    _table.clearRows();
    var idleIndex = tagProfile.names.indexOf('Idle');
    assert(idleIndex != -1);
    var t = tagProfile.updatedAtSeconds;
    for (var i = 0; i < tagProfile.snapshots.length; i++) {
      var snapshotTime = tagProfile.snapshots[i].seconds;
      var row = [];
      if (snapshotTime > 0.0) {
        row.add('t ${(snapshotTime - t).toStringAsFixed(2)}');
      } else {
        row.add('');
      }
      var sum = tagProfile.snapshots[i].sum;
      if (sum == 0) {
        for (var j = 0; j < tagProfile.snapshots[i].counters.length; j++) {
          if (j == idleIndex) {
            // Skip idle.
            continue;
          }
          row.add(0);
        }
     } else {
       for (var j = 0; j < tagProfile.snapshots[i].counters.length; j++) {
         if (j == idleIndex) {
           // Skip idle.
           continue;
         }
         var percentage = tagProfile.snapshots[i].counters[j] / sum * 100.0;
         row.add(percentage.toInt());
       }
     }
     _table.addRow(row);
    }
  }

  void draw(var element) {
    if (_chart == null) {
      assert(element != null);
      _chart = new Chart('SteppedAreaChart', element);
      _chart.options['isStacked'] = true;
      _chart.options['connectSteps'] = false;
      _chart.options['vAxis'] = {
        'minValue': 0.0,
        'maxValue': 100.0,
      };
    }
    _chart.draw(_table);
  }
}

@CustomTag('isolate-view')
class IsolateViewElement extends ObservatoryElement {
  @published Isolate isolate;
  Timer _updateTimer;
  TagProfileChart tagProfileChart = new TagProfileChart();
  IsolateViewElement.created() : super.created();

  Future<ServiceObject> eval(String text) {
    return isolate.get(
        isolate.rootLib.id + "/eval?expr=${Uri.encodeComponent(text)}");
  }

  void _updateTagProfile() {
    isolate.updateTagProfile().then((tagProfile) {
      tagProfileChart.update(tagProfile);
      _drawTagProfileChart();
      if (_updateTimer != null) {
        // Start the timer again.
        _updateTimer = new Timer(new Duration(seconds: 1), _updateTagProfile);
      }
    });
  }

  @override
  void attached() {
    super.attached();
    // Start a timer to update the isolate summary once a second.
    _updateTimer = new Timer(new Duration(seconds: 1), _updateTagProfile);
  }

  @override
  void detached() {
    super.detached();
    if (_updateTimer != null) {
      _updateTimer.cancel();
      _updateTimer = null;
    }
  }

  void _drawTagProfileChart() {
    var element = shadowRoot.querySelector('#tagProfileChart');
    if (element != null) {
      tagProfileChart.draw(element);
    }
  }

  void refresh(var done) {
    isolate.reload().whenComplete(done);
  }

  Future pause(_) {
    return isolate.get("debug/pause").then((result) {
        // TODO(turnidge): Instead of asserting here, handle errors
        // properly.
        assert(result.serviceType == 'Success');
        return isolate.reload();
      });
  }

  Future resume(_) {
    return isolate.get("resume").then((result) {
        // TODO(turnidge): Instead of asserting here, handle errors
        // properly.
        assert(result.serviceType == 'Success');
        return isolate.reload();
      });
  }
}
