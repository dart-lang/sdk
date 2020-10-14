// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate/counter_chart.dart';

class IsolateSharedSummaryElement extends CustomElement implements Renderable {
  late RenderingScheduler<IsolateSharedSummaryElement> _r;

  Stream<RenderedEvent<IsolateSharedSummaryElement>> get onRendered =>
      _r.onRendered;

  late M.Isolate _isolate;
  late M.EventRepository _events;
  late StreamSubscription _isolateSubscription;

  factory IsolateSharedSummaryElement(
      M.Isolate isolate, M.EventRepository events,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(events != null);
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
    children = <Element>[];
    _r.disable(notify: true);
    _isolateSubscription.cancel();
  }

  void render() {
    final newHeapUsed = Utils.formatSize(_isolate.newSpace!.used);
    final newHeapCapacity = Utils.formatSize(_isolate.newSpace!.capacity);
    final oldHeapUsed = Utils.formatSize(_isolate.oldSpace!.used);
    final oldHeapCapacity = Utils.formatSize(_isolate.oldSpace!.capacity);
    final content = <Element>[
      new DivElement()
        ..classes = ['menu']
        ..children = <Element>[
          new DivElement()
            ..classes = ['memberList']
            ..children = <Element>[
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'new heap',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '$newHeapUsed of $newHeapCapacity',
                ],
              new DivElement()
                ..classes = ['memberItem']
                ..children = <Element>[
                  new DivElement()
                    ..classes = ['memberName']
                    ..text = 'old heap',
                  new DivElement()
                    ..classes = ['memberValue']
                    ..text = '$oldHeapUsed of $oldHeapCapacity',
                ]
            ],
          new BRElement(),
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.debugger(_isolate))
                ..text = 'debugger'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.classTree(_isolate))
                ..text = 'class hierarchy'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.cpuProfiler(_isolate))
                ..text = 'cpu profile'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.cpuProfilerTable(_isolate))
                ..text = 'cpu profile (table)'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.allocationProfiler(_isolate))
                ..text = 'allocation profile'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.heapSnapshot(_isolate))
                ..text = 'heap snapshot'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.heapMap(_isolate))..text = 'heap map'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.metrics(_isolate))..text = 'metrics'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.persistentHandles(_isolate))
                ..text = 'persistent handles'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.ports(_isolate))..text = 'ports'
            ],
          new DivElement()
            ..children = <Element>[
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.logging(_isolate))..text = 'logging'
            ]
        ],
      new IsolateCounterChartElement(_isolate.counters!, queue: _r.queue)
          .element
    ];
    if (_isolate.error != null) {
      children = <Element>[
        new PreElement()
          ..classes = ['errorBox']
          ..text = _isolate.error!.message,
        new DivElement()
          ..classes = ['summary']
          ..children = content
      ];
    } else {
      children = <Element>[
        new DivElement()
          ..classes = ['summary']
          ..children = content
      ];
    }
  }

  void _eventListener(e) {
    if (e.isolate.id == _isolate.id) {
      _isolate = e.isolate;
      _r.dirty();
    }
  }
}
