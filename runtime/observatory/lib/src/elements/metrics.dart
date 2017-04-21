// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library metrics;

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/metric/details.dart';
import 'package:observatory/src/elements/metric/graph.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

class MetricsPageElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<MetricsPageElement>('metrics-page', dependencies: const [
    MetricDetailsElement.tag,
    MetricGraphElement.tag,
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavIsolateMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag,
  ]);

  RenderingScheduler<MetricsPageElement> _r;

  Stream<RenderedEvent<MetricsPageElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.MetricRepository _metrics;
  List<M.Metric> _available;
  M.Metric _selected;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;

  factory MetricsPageElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.MetricRepository metrics,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(isolate != null);
    assert(events != null);
    assert(notifications != null);
    MetricsPageElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._metrics = metrics;
    return e;
  }

  MetricsPageElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  void render() {
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavVMMenuElement(_vm, _events, queue: _r.queue),
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue),
        navMenu('metrics'),
        new NavRefreshElement(queue: _r.queue)
          ..onRefresh.listen((e) {
            e.element.disabled = true;
            _refresh();
          }),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = [
          new HeadingElement.h2()..text = 'Metrics',
          new HRElement(),
          new DivElement()
            ..classes = ['memberList']
            ..children = [
              new DivElement()
                ..classes = ['memberItem']
                ..children = [
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'Metric',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..children = _available == null
                        ? [new SpanElement()..text = 'Loading..']
                        : _createMetricSelect()
                ]
            ],
          new HRElement(),
          new DivElement()
            ..children = _selected == null
                ? const []
                : [
                    new MetricDetailsElement(_isolate, _selected, _metrics,
                        queue: _r.queue)
                  ],
          new HRElement(),
          new DivElement()
            ..classes = ['graph']
            ..children = _selected == null
                ? const []
                : [
                    new MetricGraphElement(_isolate, _selected, _metrics,
                        queue: _r.queue)
                  ]
        ],
    ];
  }

  Future _refresh() async {
    _available = (await _metrics.list(_isolate)).toList();
    if (!_available.contains(_selected)) {
      _selected = _available.first;
    }
    _r.dirty();
  }

  List<Element> _createMetricSelect() {
    var s;
    return [
      s = new SelectElement()
        ..value = _selected.name
        ..children = _available.map((metric) {
          return new OptionElement(
              value: metric.name, selected: _selected == metric)
            ..text = metric.name;
        }).toList(growable: false)
        ..onChange.listen((_) {
          _selected = _available[s.selectedIndex];
          _r.dirty();
        })
    ];
  }
}
