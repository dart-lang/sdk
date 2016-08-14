// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate/counter_chart.dart';

class IsolateSharedSummaryElement extends HtmlElement implements Renderable {
  static const tag =
    const Tag<IsolateSharedSummaryElement>('isolate-shared-summary-wrapped',
                                           dependencies: const [
                                             IsolateCounterChartElement.tag
                                           ]);

  RenderingScheduler<IsolateSharedSummaryElement> _r;

  Stream<RenderedEvent<IsolateSharedSummaryElement>> get onRendered =>
      _r.onRendered;

  M.Isolate _isolate;

  factory IsolateSharedSummaryElement(M.Isolate isolate,
                                      {RenderingQueue queue}) {
    assert(isolate != null);
    IsolateSharedSummaryElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    return e;
  }

  IsolateSharedSummaryElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void render() {
    children = [];
    if (_isolate.error != null) {
      children = [
        new PreElement()..classes = const ["errorBox"]
          ..text = _isolate.error.message
      ];
    }
    final newHeapUsed = Utils.formatSize(_isolate.newSpace.used);
    final newHeapCapacity = Utils.formatSize(_isolate.newSpace.capacity);
    final oldHeapUsed = Utils.formatSize(_isolate.oldSpace.used);
    final oldHeapCapacity = Utils.formatSize(_isolate.oldSpace.capacity);
    children.addAll([
      new DivElement()..classes = ['menu']
        ..children = [
          new DivElement()..classes = const ['memberList']
            ..children = [
              new DivElement()..classes = const ['memberItem']
                ..children = [
                  new DivElement()..classes = const ['memberName']
                    ..text = 'new heap',
                  new DivElement()..classes = const ['memberValue']
                    ..text = '$newHeapUsed of $newHeapCapacity',
                ],
              new DivElement()..classes = const ['memberItem']
                ..children = [
                  new DivElement()..classes = const ['memberName']
                    ..text = 'old heap',
                  new DivElement()..classes = const ['memberValue']
                    ..text = '$oldHeapUsed of $oldHeapCapacity',
                ]
            ],
          new BRElement(),
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.debugger(_isolate))
                ..text = 'debug'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.classTree(_isolate))
                ..text = 'class hierarchy'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.cpuProfiler(_isolate))
                ..text = 'cpu profile'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.cpuProfilerTable(_isolate))
                ..text = 'cpu profile (table)'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.allocationProfiler(_isolate))
                ..text = 'allocation profile'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.heapMap(_isolate))
                ..text = 'heap map'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.metrics(_isolate))
                ..text = 'metrics'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.heapSnapshot(_isolate))
                ..text = 'heap snapshot'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.persistentHandles(_isolate))
                ..text = 'persistent handles'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.ports(_isolate))
                ..text = 'ports'
            ],
          new DivElement()
            ..children = [
              new SpanElement()..text = 'see ',
              new AnchorElement(href: Uris.logging(_isolate))
                ..text = 'logging'
            ]
      ],
      new IsolateCounterChartElement(_isolate.counters, queue: _r.queue)
    ]);
  }
}
