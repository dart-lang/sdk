// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../helpers/custom_element.dart';
import '../helpers/element_utils.dart';
import '../helpers/rendering_scheduler.dart';

class IsolateCounterChartElement extends CustomElement implements Renderable {
  late RenderingScheduler<IsolateCounterChartElement> _r;

  Stream<RenderedEvent<IsolateCounterChartElement>> get onRendered =>
      _r.onRendered;

  late Map _counters;
  late StreamSubscription _subscription;

  factory IsolateCounterChartElement(Map counters, {RenderingQueue? queue}) {
    IsolateCounterChartElement e = new IsolateCounterChartElement.created();
    e._r = new RenderingScheduler<IsolateCounterChartElement>(e, queue: queue);
    e._counters = counters;
    return e;
  }

  IsolateCounterChartElement.created() : super.created('isolate-counter-chart');

  @override
  void attached() {
    super.attached();
    _r.enable();
    _subscription = element(this).onResize.listen((_) => _r.dirty());
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
    _subscription.cancel();
  }

  void render() {
    var members = <HTMLElement>[];
    _counters.forEach((key, value) {
      members.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = key,
            new HTMLDivElement()
              ..className = 'memberValue'
              ..textContent = value,
          ]),
      );
    });

    children = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'memberList'
        ..appendChildren(members),
    ];
  }
}
