// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:charted/charted.dart';
import "package:charted/charts/charts.dart";
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

class IsolateCounterChartElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<IsolateCounterChartElement>('isolate-counter-chart');

  RenderingScheduler<IsolateCounterChartElement> _r;

  Stream<RenderedEvent<IsolateCounterChartElement>> get onRendered =>
      _r.onRendered;

  Map _counters;
  StreamSubscription _subscription;

  factory IsolateCounterChartElement(Map counters, {RenderingQueue queue}) {
    assert(counters != null);
    IsolateCounterChartElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._counters = counters;
    return e;
  }

  IsolateCounterChartElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
    _subscription = window.onResize.listen((_) => _r.dirty());
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
    _subscription.cancel();
  }

  static final _columns = [
    new ChartColumnSpec(label: 'Type', type: ChartColumnSpec.TYPE_STRING),
    new ChartColumnSpec(label: 'Percent', formatter: (v) => v.toString())
  ];

  void render() {
    final _series = [
      new ChartSeries(
          "Work", const [1], new PieChartRenderer(sortDataByValue: false))
    ];
    final areaHost = new DivElement()..classes = ['host'];
    final legendHost = new DivElement()..classes = ['legend'];
    children = [areaHost, legendHost];
    final rect = areaHost.getBoundingClientRect();
    final minSize = new Rect.size(rect.width, rect.height);
    final config = new ChartConfig(_series, const [0])
      ..minimumSize = minSize
      ..legend = new ChartLegend(legendHost, showValues: true);
    final data = new ChartData(
        _columns,
        _counters.keys
            .map((key) => [key, double.parse(_counters[key].split('%')[0])])
            .toList());

    new LayoutArea(areaHost, data, config,
        state: new ChartState(), autoUpdate: false)
      ..addChartBehavior(new Hovercard())
      ..addChartBehavior(new AxisLabelTooltip())
      ..draw();
  }
}
