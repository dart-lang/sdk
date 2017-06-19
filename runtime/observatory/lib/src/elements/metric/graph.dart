// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:charted/charted.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

class MetricGraphElement extends HtmlElement implements Renderable {
  static const tag = const Tag<MetricGraphElement>('metric-graph');

  RenderingScheduler<MetricGraphElement> _r;

  Stream<RenderedEvent<MetricGraphElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.Metric _metric;
  M.MetricRepository _metrics;
  Timer _timer;

  M.IsolateRef get isolate => _isolate;
  M.Metric get metric => _metric;

  factory MetricGraphElement(
      M.IsolateRef isolate, M.Metric metric, M.MetricRepository metrics,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(metric != null);
    assert(metrics != null);
    MetricGraphElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._metric = metric;
    e._metrics = metrics;
    return e;
  }

  MetricGraphElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
    _timer = new Timer.periodic(const Duration(seconds: 1), (_) => _r.dirty());
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
    _timer.cancel();
  }

  final _columns = [
    new ChartColumnSpec(label: 'Time', type: ChartColumnSpec.TYPE_TIMESTAMP),
    new ChartColumnSpec(label: 'Value', formatter: (v) => v.toString())
  ];

  void render() {
    final min = _metrics.getMinValue(_isolate, _metric);
    final max = _metrics.getMaxValue(_isolate, _metric);
    final rows = _metrics
        .getSamples(_isolate, _metric)
        .map((s) => [s.time.millisecondsSinceEpoch, s.value])
        .toList();
    final current = rows.last.last;

    var message = 'current: $current';
    if (min != null) {
      message = 'min: $min, $message';
    }
    if (max != null) {
      message = message + ', max: $max';
    }

    final host = new DivElement();
    children = [
      new DivElement()
        ..classes = ['memberList']
        ..children = [
          new DivElement()
            ..classes = ['memberItem']
            ..children = min == null
                ? const []
                : [
                    new DivElement()
                      ..classes = ['memberName']
                      ..text = 'min',
                    new DivElement()
                      ..classes = ['memberValue']
                      ..text = '$min'
                  ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'current',
              new DivElement()
                ..classes = ['memberValue']
                ..text = '$current'
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = max == null
                ? const []
                : [
                    new DivElement()
                      ..classes = ['memberName']
                      ..text = 'max',
                    new DivElement()
                      ..classes = ['memberValue']
                      ..text = '$max'
                  ]
        ],
      new DivElement()
        ..classes = ['graph']
        ..children = [host]
    ];
    if (rows.length <= 1) {
      return;
    }
    final rect = host.getBoundingClientRect();
    var series = new ChartSeries("one", [1], new LineChartRenderer());
    var config = new ChartConfig([series], [0]);
    config.minimumSize = new Rect(rect.width, rect.height);
    final data = new ChartData(_columns, rows);
    new CartesianArea(host, data, config, state: new ChartState()).draw();
  }
}
