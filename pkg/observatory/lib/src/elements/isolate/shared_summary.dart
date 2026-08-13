// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../../models.dart' as M;
import '../helpers/custom_element.dart';
import '../helpers/element_utils.dart';
import '../helpers/rendering_scheduler.dart';
import '../helpers/uris.dart';
import 'counter_chart.dart';
import '../../../utils.dart';

class IsolateSharedSummaryElement extends CustomElement implements Renderable {
  late RenderingScheduler<IsolateSharedSummaryElement> _r;

  Stream<RenderedEvent<IsolateSharedSummaryElement>> get onRendered =>
      _r.onRendered;

  late M.Isolate _isolate;
  late M.EventRepository _events;
  late StreamSubscription _isolateSubscription;

  factory IsolateSharedSummaryElement(
    M.Isolate isolate,
    M.EventRepository events, {
    RenderingQueue? queue,
  }) {
    IsolateSharedSummaryElement e = new IsolateSharedSummaryElement.created();
    e._r = new RenderingScheduler<IsolateSharedSummaryElement>(e, queue: queue);
    e._isolate = isolate;
    e._events = events;
    return e;
  }

  IsolateSharedSummaryElement.created()
    : super.created('isolate-shared-summary');

  @override
  void attached() {
    super.attached();
    _r.enable();
    _isolateSubscription = _events.onIsolateEvent.listen(_eventListener);
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
    _isolateSubscription.cancel();
  }

  void render() {
    final newHeapUsed = Utils.formatSize(_isolate.newSpace!.used);
    final newHeapCapacity = Utils.formatSize(_isolate.newSpace!.capacity);
    final oldHeapUsed = Utils.formatSize(_isolate.oldSpace!.used);
    final oldHeapCapacity = Utils.formatSize(_isolate.oldSpace!.capacity);
    final content = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'menu'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberList'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'new heap',
                  new HTMLDivElement()
                    ..className = 'memberValue'
                    ..textContent = '$newHeapUsed of $newHeapCapacity',
                ]),
              new HTMLDivElement()
                ..className = 'memberItem'
                ..appendChildren(<HTMLElement>[
                  new HTMLDivElement()
                    ..className = 'memberName'
                    ..textContent = 'old heap',
                  new HTMLDivElement()
                    ..className = 'memberValue'
                    ..textContent = '$oldHeapUsed of $oldHeapCapacity',
                ]),
            ]),
          new HTMLBRElement(),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.debugger(_isolate)
              ..textContent = 'debugger',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.classTree(_isolate)
              ..textContent = 'class hierarchy',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.cpuProfiler(_isolate)
              ..textContent = 'cpu profile',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.cpuProfilerTable(_isolate)
              ..textContent = 'cpu profile (table)',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.allocationProfiler(_isolate)
              ..textContent = 'allocation profile',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.heapSnapshot(_isolate)
              ..textContent = 'heap snapshot',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.heapMap(_isolate)
              ..textContent = 'heap map',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.metrics(_isolate)
              ..textContent = 'metrics',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.persistentHandles(_isolate)
              ..textContent = 'persistent handles',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.ports(_isolate)
              ..textContent = 'ports',
          ]),
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLSpanElement()..textContent = 'see ',
            new HTMLAnchorElement()
              ..href = Uris.logging(_isolate)
              ..textContent = 'logging',
          ]),
        ]),
      new IsolateCounterChartElement(
        _isolate.counters!,
        queue: _r.queue,
      ).element,
    ];
    if (_isolate.error != null) {
      appendChildren(<HTMLElement>[
        new HTMLPreElement.pre()
          ..className = 'errorBox'
          ..textContent = _isolate.error!.message ?? '',
        new HTMLDivElement()
          ..className = 'summary'
          ..appendChildren(content),
      ]);
    } else {
      appendChildren(<HTMLElement>[
        new HTMLDivElement()
          ..className = 'summary'
          ..appendChildren(content),
      ]);
    }
  }

  void _eventListener(e) {
    if (e.isolate.id == _isolate.id) {
      // This view doesn't display registered service extensions.
      if (e is! M.ServiceRegisteredEvent && e is! M.ServiceUnregisteredEvent) {
        _isolate = e.isolate;
        _r.dirty();
      }
    }
  }
}
