// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

class MetricDetailsElement extends HtmlElement implements Renderable {
  static const tag = const Tag<MetricDetailsElement>('metric-details');

  RenderingScheduler<MetricDetailsElement> _r;

  Stream<RenderedEvent<MetricDetailsElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.Metric _metric;
  M.MetricRepository _metrics;

  M.IsolateRef get isolate => _isolate;
  M.Metric get metric => _metric;

  factory MetricDetailsElement(
      M.IsolateRef isolate, M.Metric metric, M.MetricRepository metrics,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(metric != null);
    assert(metrics != null);
    MetricDetailsElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._metric = metric;
    e._metrics = metrics;
    return e;
  }

  MetricDetailsElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    children = [
      new DivElement()
        ..classes = ['memberList']
        ..children = [
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'name',
              new DivElement()
                ..classes = ['memberValue']
                ..text = _metric.name,
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'description',
              new DivElement()
                ..classes = ['memberValue']
                ..text = _metric.description,
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'refresh rate',
              new DivElement()
                ..classes = ['memberValue']
                ..children = _createRefreshRateSelect(),
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'buffer size',
              new DivElement()
                ..classes = ['memberValue']
                ..children = _createBufferSizeSelect(),
            ]
        ]
    ];
  }

  List<Element> _createRefreshRateSelect() {
    final current = _metrics.getSamplingRate(_isolate, _metric);
    var s;
    return [
      s = new SelectElement()
        ..value = _rateToString(current)
        ..children = M.MetricSamplingRate.values.map((rate) {
          return new OptionElement(
              value: _rateToString(current), selected: current == rate)
            ..text = _rateToString(rate);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _metrics.setSamplingRate(
              _isolate, _metric, M.MetricSamplingRate.values[s.selectedIndex]);
          _r.dirty();
        })
    ];
  }

  List<Element> _createBufferSizeSelect() {
    final current = _metrics.getBufferSize(_isolate, _metric);
    var s;
    return [
      s = new SelectElement()
        ..value = _sizeToString(current)
        ..children = M.MetricBufferSize.values.map((rate) {
          return new OptionElement(
              value: _sizeToString(current), selected: current == rate)
            ..text = _sizeToString(rate);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _metrics.setBufferSize(
              _isolate, _metric, M.MetricBufferSize.values[s.selectedIndex]);
          _r.dirty();
        })
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
    throw new Exception('Unknown MetricSamplingRate ($rate)');
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
    throw new Exception('Unknown MetricSamplingRate ($size)');
  }
}
