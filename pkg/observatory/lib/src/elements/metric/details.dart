// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../../models.dart' as M;
import '../helpers/custom_element.dart';
import '../helpers/element_utils.dart';
import '../helpers/rendering_scheduler.dart';

class MetricDetailsElement extends CustomElement implements Renderable {
  late RenderingScheduler<MetricDetailsElement> _r;

  Stream<RenderedEvent<MetricDetailsElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.Metric _metric;
  late M.MetricRepository _metrics;

  M.IsolateRef get isolate => _isolate;
  M.Metric get metric => _metric;

  factory MetricDetailsElement(
    M.IsolateRef isolate,
    M.Metric metric,
    M.MetricRepository metrics, {
    RenderingQueue? queue,
  }) {
    MetricDetailsElement e = new MetricDetailsElement.created();
    e._r = new RenderingScheduler<MetricDetailsElement>(e, queue: queue);
    e._isolate = isolate;
    e._metric = metric;
    e._metrics = metrics;
    return e;
  }

  MetricDetailsElement.created() : super.created('metric-details');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  void render() {
    children = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'memberList'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'name',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..textContent = _metric.name ?? '',
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'description',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..textContent = _metric.description ?? '',
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'refresh rate',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChildren(_createRefreshRateSelect()),
            ]),
          new HTMLDivElement()
            ..className = 'memberItem'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberName'
                ..textContent = 'buffer size',
              new HTMLDivElement()
                ..className = 'memberValue'
                ..appendChildren(_createBufferSizeSelect()),
            ]),
        ]),
    ];
  }

  List<HTMLElement> _createRefreshRateSelect() {
    final current = _metrics.getSamplingRate(_isolate, _metric);
    final s = new HTMLSelectElement()
      ..value = _rateToString(current)
      ..appendChildren(
        M.MetricSamplingRate.values.map(
          (rate) => HTMLOptionElement()
            ..value = _rateToString(current)
            ..selected = current == rate
            ..textContent = _rateToString(rate),
        ),
      );
    return [
      s
        ..onChange.listen((_) {
          _metrics.setSamplingRate(
            _isolate,
            _metric,
            M.MetricSamplingRate.values[s.selectedIndex],
          );
          _r.dirty();
        }),
    ];
  }

  List<HTMLElement> _createBufferSizeSelect() {
    final current = _metrics.getBufferSize(_isolate, _metric);
    final s = HTMLSelectElement()
      ..value = _sizeToString(current)
      ..appendChildren(
        M.MetricBufferSize.values.map(
          (rate) => HTMLOptionElement()
            ..value = _sizeToString(current)
            ..selected = current == rate
            ..textContent = _sizeToString(rate),
        ),
      );
    return [
      s
        ..onChange.listen((_) {
          _metrics.setBufferSize(
            _isolate,
            _metric,
            M.MetricBufferSize.values[s.selectedIndex],
          );
          _r.dirty();
        }),
    ];
  }

  static String _rateToString(M.MetricSamplingRate rate) {
    switch (rate) {
      case M.MetricSamplingRate.off:
        return 'Never';
      case M.MetricSamplingRate.e100ms:
        return 'Ten times per second';
      case M.MetricSamplingRate.e1s:
        return 'Once a second';
      case M.MetricSamplingRate.e2s:
        return 'Every two seconds';
      case M.MetricSamplingRate.e4s:
        return 'Every four seconds';
      case M.MetricSamplingRate.e8s:
        return 'Every eight seconds';
    }
  }

  static String _sizeToString(M.MetricBufferSize size) {
    switch (size) {
      case M.MetricBufferSize.n10samples:
        return '10';
      case M.MetricBufferSize.n100samples:
        return '100';
      case M.MetricBufferSize.n1000samples:
        return '1000';
    }
  }
}
