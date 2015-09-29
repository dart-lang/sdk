// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library metrics;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:charted/charted.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('metrics-page')
class MetricsPageElement extends ObservatoryElement {
  MetricsPageElement.created() : super.created();

  @observable MetricsPage page;
  @observable Isolate isolate;
  @observable ServiceMetric selectedMetric;

  void _autoPickSelectedMetric() {
    if (selectedMetric != null) {
      return;
    }
    // Attempt to pick the last selected metric.
    if ((isolate != null) && (page != null) &&
        (page.selectedMetricId != null)) {
      selectedMetric = isolate.dartMetrics[page.selectedMetricId];
      if (selectedMetric != null) {
        return;
      }
      selectedMetric = isolate.nativeMetrics[page.selectedMetricId];
    }
    if ((selectedMetric == null) && (isolate != null)) {
      var values = isolate.dartMetrics.values.toList();
      if ((values != null) && (values.length > 0)) {
        // Fall back and pick the first isolate metric.
        selectedMetric = values.first;
      }
      if (selectedMetric != null) {
        return;
      }
      values = isolate.nativeMetrics.values.toList();
      if ((values != null) && (values.length > 0)) {
        // Fall back and pick the first isolate metric.
        selectedMetric = values.first;
      }
    }
  }

  void attached() {
    _autoPickSelectedMetric();
  }

  void isolateChanged(oldValue) {
    if (isolate != null) {
      isolate.refreshMetrics().then((_) {
        _autoPickSelectedMetric();
      });
    }
  }

  Future refresh() {
    return isolate.refreshMetrics();
  }

  void selectMetric(Event e, var detail, Element target) {
    String id = target.attributes['data-id'];
    selectedMetric = isolate.dartMetrics[id];
    if (selectedMetric == null) {
      // Check VM metrics.
      selectedMetric = isolate.nativeMetrics[id];
    }
    if (selectedMetric != null) {
      page.selectedMetricId = id;
    } else {
      page.selectedMetricId = null;
    }
  }
}

@CustomTag('metric-details')
class MetricDetailsElement extends ObservatoryElement {
  MetricDetailsElement.created() : super.created();
  @published MetricsPage page;
  @published ServiceMetric metric;

  int _findIndex(SelectElement element, int value) {
    if (element == null) {
      return null;
    }
    for (var i = 0; i < element.options.length; i++) {
      var optionElement = element.options[i];
      int optionValue = int.parse(optionElement.value);
      if (optionValue == value) {
        return i;
      }
    }
    return null;
  }

  void attached() {
    super.attached();
    _updateSelectedIndexes();
  }

  void _updateSelectedIndexes() {
    if (metric == null) {
      return;
    }
    SelectElement refreshRateElement = shadowRoot.querySelector('#refreshrate');
    if (refreshRateElement == null) {
      // Race between shadowRoot setup and events.
      return;
    }
    int period = 0;
    if (metric.poller != null) {
      period = metric.poller.pollPeriod.inMilliseconds;
    }
    var index = _findIndex(refreshRateElement, period);
    assert(index != null);
    refreshRateElement.selectedIndex = index;
    SelectElement bufferSizeElement = shadowRoot.querySelector('#buffersize');
    index = _findIndex(bufferSizeElement, metric.sampleBufferSize);
    assert(index != null);
    bufferSizeElement.selectedIndex = index;
  }

  metricChanged(oldValue) {
    _updateSelectedIndexes();
  }

  void refreshRateChange(Event e, var detail, Element target) {
    var value = int.parse((target as SelectElement).value);
    if (metric == null) {
      return;
    }
    page.setRefreshPeriod(value, metric);
  }

  void sampleBufferSizeChange(Event e, var detail, Element target) {
    var value = int.parse((target as SelectElement).value);
    if (metric == null) {
      return;
    }
    metric.sampleBufferSize = value;
  }
}

@CustomTag('metrics-graph')
class MetricsGraphElement extends ObservatoryElement {
  MetricsGraphElement.created() : super.created();

  HtmlElement _wrapper;
  HtmlElement _areaHost;
  CartesianArea _area;
  ChartData _data;
  final _columns = [
      new ChartColumnSpec(label: 'Time', type: ChartColumnSpec.TYPE_TIMESTAMP),
      new ChartColumnSpec(label: 'Value', formatter: (v) => v.toString())
  ];
  final _rows = [[0, 1000000.0]];

  @published ServiceMetric metric;
  @observable Isolate isolate;

  void attached() {
    super.attached();
    // Redraw once a second.
    pollPeriod = new Duration(seconds: 1);
    _reset();
  }

  void onPoll() {
    if (metric == null) {
      return;
    }
    _update();
    _draw();
  }

  void _reset() {
    _rows.clear();
    _wrapper = shadowRoot.querySelector('#metric-chart');
    assert(_wrapper != null);
    _areaHost = _wrapper.querySelector('.chart-host');
    assert(_areaHost != null);
    _areaHost.children.clear();
    var series = new ChartSeries("one", [1], new LineChartRenderer());
    var config = new ChartConfig([series], [0]);
    config.minimumSize = new Rect(800, 600);
    _data = new ChartData(_columns, _rows);
    _area = new CartesianArea(_areaHost,
                              _data,
                              config,
                              state: new ChartState());
  }

  void _update() {
    _rows.clear();
    for (var i = 0; i < metric.samples.length; i++) {
      var sample = metric.samples[i];
      _rows.add([sample.time.millisecondsSinceEpoch, sample.value]);
    }
  }

  void _draw() {
    if (_rows.length < 2) {
      return;
    }
    _area.data = new ChartData(_columns, _rows);
    _area.draw();
  }

  metricChanged(oldValue) {
    if (oldValue != metric) {
      _reset();
    }
  }
}
