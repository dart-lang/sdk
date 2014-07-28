// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_summary_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('isolate-summary')
class IsolateSummaryElement extends ObservatoryElement {
  IsolateSummaryElement.created() : super.created();

  @published Isolate isolate;
}

@CustomTag('isolate-run-state')
class IsolateRunStateElement extends ObservatoryElement {
  IsolateRunStateElement.created() : super.created();

  @published Isolate isolate;

  Future pause(_) {
    return isolate.pause();
  }
  Future resume(_) {
    app.removePauseEvents(isolate);
    return isolate.resume();
  }
  Future stepInto(_) {
    app.removePauseEvents(isolate);
    return isolate.stepInto();
  }
  Future stepOver(_) {
    app.removePauseEvents(isolate);
    return isolate.stepOver();
  }
  Future stepOut(_) {
    app.removePauseEvents(isolate);
    return isolate.stepOut();
  }
}

@CustomTag('isolate-location')
class IsolateLocationElement extends ObservatoryElement {
  IsolateLocationElement.created() : super.created();

  @published Isolate isolate;
}

@CustomTag('isolate-shared-summary')
class IsolateSharedSummaryElement extends ObservatoryElement {
  IsolateSharedSummaryElement.created() : super.created();

  @published Isolate isolate;
}

class CounterChart {
  var _table = new DataTable();
  var _chart;

  void update(Map counters) {
    if (_table.columns == 0) {
      // Initialize.
      _table.addColumn('string', 'Name');
      _table.addColumn('number', 'Value');
    }
    _table.clearRows();
    for (var key in counters.keys) {
      var value = double.parse(counters[key].split('%')[0]);
      _table.addRow([key, value]);
    }
  }

  void draw(var element) {
    if (_chart == null) {
      assert(element != null);
      _chart = new Chart('PieChart', element);
    }
    _chart.draw(_table);
  }
}

@CustomTag('isolate-counter-chart')
class IsolateCounterChartElement extends ObservatoryElement {
  IsolateCounterChartElement.created() : super.created();

  @published ObservableMap counters;
  CounterChart chart;

  void countersChanged(oldValue) {
    if (counters == null) {
      return;
    }
    // Lazily create the chart.
    if (GoogleChart.ready && chart == null) {
      chart = new CounterChart();
    }
    if (chart == null) {
      return;
    }
    chart.update(counters);
    var element = shadowRoot.querySelector('#counterPieChart');
    if (element != null) {
      chart.draw(element);
    }
  }
}



