// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';

class MetricGraphElement extends CustomElement implements Renderable {
  late RenderingScheduler<MetricGraphElement> _r;

  Stream<RenderedEvent<MetricGraphElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.Metric _metric;
  late M.MetricRepository _metrics;
  late Timer _timer;

  M.IsolateRef get isolate => _isolate;
  M.Metric get metric => _metric;

  factory MetricGraphElement(
      M.IsolateRef isolate, M.Metric metric, M.MetricRepository metrics,
      {RenderingQueue? queue}) {
    MetricGraphElement e = new MetricGraphElement.created();
    e._r = new RenderingScheduler<MetricGraphElement>(e, queue: queue);
    e._isolate = isolate;
    e._metric = metric;
    e._metrics = metrics;
    return e;
  }

  MetricGraphElement.created() : super.created('metric-graph');

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
    removeChildren();
    _timer.cancel();
  }

  void render() {
    final min = _metrics.getMinValue(_isolate, _metric);
    final max = _metrics.getMaxValue(_isolate, _metric);
    final rows = _metrics
        .getSamples(_isolate, _metric)!
        .map((s) => [s.time!.millisecondsSinceEpoch, s.value])
        .toList();
    final current = rows.last.last;

    var message = 'current: $current';
    message = 'min: $min, $message';
    message = message + ', max: $max';

    children = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'memberList'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren([
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'min',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..textContent = '$min'
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'current',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..textContent = '$current'
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren([
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'max',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..textContent = '$max'
            ])
        ]),
    ];
    if (rows.length <= 1) {
      return;
    }
  }
}
