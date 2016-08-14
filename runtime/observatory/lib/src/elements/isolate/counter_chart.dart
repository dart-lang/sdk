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

  void render() {
    var areaHost;
    var legendHost;
    children = [
      areaHost = new DivElement()..classes = ['host'],
      legendHost = new DivElement()..classes = ['legend']
    ];
    final series = new ChartSeries("Work", [1], new PieChartRenderer(
      sortDataByValue: false
    ));
    var rect = areaHost.getBoundingClientRect();
    var minSize = new Rect.size(rect.width, rect.height);
    final config = new ChartConfig([series], [0])
        ..minimumSize = minSize
        ..legend = new ChartLegend(legendHost, showValues: true);
    final data = new ChartData([
        new ChartColumnSpec(label: 'Type', type: ChartColumnSpec.TYPE_STRING),
        new ChartColumnSpec(label: 'Percent', formatter: (v) => v.toString())
      ], _counters.keys
          .map((key) => [key, double.parse(_counters[key].split('%')[0])])
          .toList());

    new LayoutArea(areaHost, data, config, state: new ChartState(),
        autoUpdate: true)
      ..addChartBehavior(new Hovercard())
      ..addChartBehavior(new AxisLabelTooltip())
      ..draw();
  }
}
