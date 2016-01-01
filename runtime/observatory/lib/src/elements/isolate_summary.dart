// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_summary_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:charted/charted.dart';
import "package:charted/charts/charts.dart";
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
  final HtmlElement _wrapper;
  HtmlElement _areaHost;
  HtmlElement _legendHost;
  LayoutArea _area;
  ChartData _data;
  final _columns = [
      new ChartColumnSpec(label: 'Type', type: ChartColumnSpec.TYPE_STRING),
      new ChartColumnSpec(label: 'Percent', formatter: (v) => v.toString())
  ];

  CounterChart(this._wrapper) {
    assert(_wrapper != null);
    _areaHost = _wrapper.querySelector('.chart-host');
    assert(_areaHost != null);
    _areaHost.clientWidth;
    _legendHost = _wrapper.querySelector('.chart-legend-host');
    assert(_legendHost != null);
    var series = new ChartSeries("Work", [1], new PieChartRenderer(
      sortDataByValue: false
    ));
    var config = new ChartConfig([series], [0]);
    config.minimumSize = new Rect(200, 200);
    config.legend = new ChartLegend(_legendHost, showValues: true);
    _data = new ChartData(_columns, []);
    _area = new LayoutArea(_areaHost,
                           _data,
                           config,
                           state: new ChartState(),
                           autoUpdate: false);
    _area.addChartBehavior(new Hovercard());
    _area.addChartBehavior(new AxisLabelTooltip());
  }

  void update(Map counters) {
    var rows = [];
    for (var key in counters.keys) {
      var value = double.parse(counters[key].split('%')[0]);
      rows.add([key, value]);
    }
    _area.data = new ChartData(_columns, rows);
    _area.draw();
  }
}

@CustomTag('isolate-counter-chart')
class IsolateCounterChartElement extends ObservatoryElement {
  IsolateCounterChartElement.created() : super.created();

  @published ObservableMap counters;
  CounterChart chart;

  attached() {
    super.attached();
    chart =
        new CounterChart(shadowRoot.querySelector('#isolate-counter-chart'));
  }

  detached() {
    super.detached();
    var host = shadowRoot.querySelector('#isolate-counter-chart-host');
    host.children.clear();
    var legendHost =
        shadowRoot.querySelector('#isolate-counter-chart-legend-host');
    legendHost.children.clear();
  }

  void countersChanged(oldValue) {
    if (counters == null) {
      return;
    }
    if (chart == null) {
      return;
    }
    chart.update(counters);
  }
}
