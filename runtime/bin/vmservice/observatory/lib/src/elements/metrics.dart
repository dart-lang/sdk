// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library metrics;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
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
      if (selectedMetric == null) {
        selectedMetric = isolate.vmMetrics[page.selectedMetricId];
      }
    }
    if ((selectedMetric == null) && (isolate != null)) {
      var values = isolate.dartMetrics.values;
      if (values != null) {
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

  void refresh(var done) {
    isolate.refreshMetrics().whenComplete(done);
  }

  void selectMetric(Event e, var detail, Element target) {
    String id = target.attributes['data-id'];
    selectedMetric = isolate.dartMetrics[id];
    if (selectedMetric == null) {
      // Check VM metrics.
      selectedMetric = isolate.vmMetrics[id];
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

  final DataTable _table = new DataTable();
  Chart _chart;

  @published ServiceMetric metric;
  @observable Isolate isolate;

  void attached() {
    // Redraw once a second.
    pollPeriod = new Duration(seconds: 1);
    super.attached();
  }

  void onPoll() {
    draw();
  }

  void draw() {
    if (_chart == null) {
      // Construct chart.
      var element = shadowRoot.querySelector('#graph');
      if (element == null) {
        // Bail.
        return;
      }
      _chart = new Chart('LineChart', element);
    }
    if (metric == null) {
      return;
    }
    _update();
    _chart.draw(_table);
  }

  void _setupInitialDataTable() {
    _table.clearColumns();
    // Only one metric right now.
    _table.addColumn('timeofday', 'time');
    _table.addColumn('number', metric.name);
  }

  void _update() {
    _table.clearRows();
    for (var i = 0; i < metric.samples.length; i++) {
      var sample = metric.samples[i];
      _table.addTimeOfDayValue(sample.time, sample.value);
    }
  }

  metricChanged(oldValue) {
    if (oldValue != metric) {
      _setupInitialDataTable();
    }
  }
}