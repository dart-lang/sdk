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
import 'package:observatory/src/elements/isolate_ref.dart';
import 'package:observatory/src/elements/isolate/location.dart';
import 'package:observatory/src/elements/isolate/run_state.dart';
import 'package:observatory/src/elements/isolate/shared_summary.dart';

class IsolateSummaryElement extends CustomElement implements Renderable {
  late RenderingScheduler<IsolateSummaryElement> _r;

  Stream<RenderedEvent<IsolateSummaryElement>> get onRendered => _r.onRendered;

  late M.IsolateRef _isolate;
  late M.EventRepository _events;
  late M.IsolateRepository _isolates;
  late M.ScriptRepository _scripts;
  M.Isolate? _loadedIsolate;

  factory IsolateSummaryElement(
      M.IsolateRef isolate,
      M.IsolateRepository isolates,
      M.EventRepository events,
      M.ScriptRepository scripts,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(isolates != null);
    assert(events != null);
    assert(scripts != null);
    IsolateSummaryElement e = new IsolateSummaryElement.created();
    e._r = new RenderingScheduler<IsolateSummaryElement>(e, queue: queue);
    e._isolate = isolate;
    e._isolates = isolates;
    e._events = events;
    e._scripts = scripts;
    return e;
  }

  IsolateSummaryElement.created() : super.created('isolate-summary');

  @override
  void attached() {
    super.attached();
    _r.enable();
    _load();
  }

  @override
  void detached() {
    super.detached();
    children = <Element>[];
    _r.disable(notify: true);
  }

  void render() {
    if (_loadedIsolate == null) {
      children = <Element>[
        new SpanElement()..text = 'loading ',
        new IsolateRefElement(_isolate, _events, queue: _r.queue).element
      ];
    } else {
      children = <Element>[
        linkAndStatusRow(),
        new BRElement(),
        memoryRow(),
        new BRElement(),
        toolsRow(),
      ];
    }
  }

  Element linkAndStatusRow() {
    return new DivElement()
      ..classes = ['flex-row-wrap']
      ..children = <Element>[
        new DivElement()
          ..classes = ['isolate-ref-container']
          ..children = <Element>[
            new IsolateRefElement(_isolate, _events, queue: _r.queue).element
          ],
        new DivElement()..style.flex = '1',
        new DivElement()
          ..classes = ['flex-row', 'isolate-state-container']
          ..children = <Element>[
            new IsolateRunStateElement(_isolate as M.Isolate, _events,
                    queue: _r.queue)
                .element,
            new IsolateLocationElement(_isolate as M.Isolate, _events, _scripts,
                    queue: _r.queue)
                .element,
            new SpanElement()..text = ' [',
            new AnchorElement(href: Uris.debugger(_isolate))..text = 'debug',
            new SpanElement()..text = ']'
          ]
      ];
  }

  Element memoryRow() {
    final isolate = _isolate as M.Isolate;
    final newHeapUsed = Utils.formatSize(isolate.newSpace!.used);
    final newHeapCapacity = Utils.formatSize(isolate.newSpace!.capacity);
    final oldHeapUsed = Utils.formatSize(isolate.oldSpace!.used);
    final oldHeapCapacity = Utils.formatSize(isolate.oldSpace!.capacity);
    final heapUsed =
        Utils.formatSize(isolate.newSpace!.used + isolate.oldSpace!.used);
    final heapCapacity = Utils.formatSize(
        isolate.newSpace!.capacity + isolate.oldSpace!.capacity);
    return new DivElement()
      ..classes = ['flex-row-wrap-right']
      ..children = <Element>[
        new DivElement()
          ..style.padding = '5px'
          ..text = 'new-space $newHeapUsed of $newHeapCapacity',
        new DivElement()
          ..style.padding = '5px'
          ..text = '/',
        new DivElement()
          ..style.padding = '5px'
          ..text = 'old-space $oldHeapUsed of $oldHeapCapacity',
        new DivElement()
          ..style.padding = '5px'
          ..text = '/',
        new DivElement()
          ..style.padding = '5px'
          ..text = 'heap $heapUsed of $heapCapacity',
      ];
  }

  Element toolsRow() {
    return new DivElement()
      ..classes = ['flex-row-spaced']
      ..children = <Element>[
        new AnchorElement(href: Uris.debugger(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'debugger',
        new AnchorElement(href: Uris.classTree(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'class hierarchy',
        new AnchorElement(href: Uris.cpuProfiler(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'cpu profile',
        new AnchorElement(href: Uris.cpuProfilerTable(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'cpu profile (table)',
        new AnchorElement(href: Uris.allocationProfiler(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'allocation profile',
        new AnchorElement(href: Uris.heapSnapshot(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'heap snapshot',
        new AnchorElement(href: Uris.heapMap(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'heap map',
        new AnchorElement(href: Uris.metrics(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'metrics',
        new AnchorElement(href: Uris.persistentHandles(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'persistent handles',
        new AnchorElement(href: Uris.ports(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'ports',
        new AnchorElement(href: Uris.logging(_isolate))
          ..classes = ['flex-item-even']
          ..text = 'logging',
      ];
  }

  Future _load() async {
    _loadedIsolate = await _isolates.get(_isolate);
    _r.dirty();
  }
}
