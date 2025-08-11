// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library metrics;

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/metric/details.dart';
import 'package:observatory/src/elements/metric/graph.dart';
import 'package:observatory/src/elements/nav/isolate_menu.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

class MetricsPageElement extends CustomElement implements Renderable {
  late RenderingScheduler<MetricsPageElement> _r;

  Stream<RenderedEvent<MetricsPageElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  late M.MetricRepository _metrics;
  List<M.Metric>? _available;
  M.Metric? _selected;

  M.VMRef get vm => _vm;
  M.IsolateRef get isolate => _isolate;
  M.NotificationRepository get notifications => _notifications;

  factory MetricsPageElement(
      M.VM vm,
      M.IsolateRef isolate,
      M.EventRepository events,
      M.NotificationRepository notifications,
      M.MetricRepository metrics,
      {RenderingQueue? queue}) {
    MetricsPageElement e = new MetricsPageElement.created();
    e._r = new RenderingScheduler<MetricsPageElement>(e, queue: queue);
    e._vm = vm;
    e._isolate = isolate;
    e._events = events;
    e._notifications = notifications;
    e._metrics = metrics;
    return e;
  }

  MetricsPageElement.created() : super.created('metrics-page');

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
    removeChildren();
  }

  void render() {
    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(_vm, _events, queue: _r.queue).element,
        new NavIsolateMenuElement(_isolate, _events, queue: _r.queue).element,
        navMenu('metrics'),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) {
                e.element.disabled = true;
                _refresh();
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h2()..textContent = 'Metrics',
          new HTMLHRElement(),
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'Metric',
                  new HTMLDivElement()
                    ..className = 'memberValue'
                    ..appendChildren(_available == null
                        ? [new HTMLSpanElement()..textContent = 'Loading..']
                        : _createMetricSelect())
                ])
            ]),
          new HTMLHRElement(),
          new HTMLDivElement()
            ..appendChildren(_selected == null
                ? const []
                : [
                    new MetricDetailsElement(_isolate, _selected!, _metrics,
                            queue: _r.queue)
                        .element
                  ]),
          new HTMLHRElement(),
          new HTMLDivElement()
            ..className = 'graph'
            ..appendChildren(_selected == null
                ? const []
                : [
                    new MetricGraphElement(_isolate, _selected!, _metrics,
                            queue: _r.queue)
                        .element
                  ])
        ]),
    ];
  }

  Future _refresh() async {
    _available = (await _metrics.list(_isolate)).toList();
    if (!_available!.contains(_selected)) {
      _selected = _available!.first;
    }
    _r.dirty();
  }

  List<HTMLElement> _createMetricSelect() {
    final s = new HTMLSelectElement()
      ..value = _selected!.name!
      ..appendChildren(_available!.map((metric) => HTMLOptionElement()
        ..value = metric.name!
        ..selected = _selected == metric
        ..textContent = metric.name!));
    return [
      s
        ..onChange.listen((_) {
          _selected = _available![s.selectedIndex];
          _r.dirty();
        })
    ];
  }
}
