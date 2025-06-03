// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate/location.dart';
import 'package:observatory/src/elements/isolate/run_state.dart';
import 'package:observatory/src/elements/isolate_ref.dart';
import 'package:observatory/utils.dart';

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
    removeChildren();
    _r.disable(notify: true);
  }

  void render() {
    if (_loadedIsolate == null) {
      children = <HTMLElement>[
        new HTMLSpanElement()..textContent = 'loading ',
        new IsolateRefElement(_isolate, _events, queue: _r.queue).element
      ];
    } else {
      children = <HTMLElement>[
        linkAndStatusRow(),
        new HTMLBRElement(),
        memoryRow(),
        new HTMLBRElement(),
        toolsRow(),
      ];
    }
  }

  HTMLElement linkAndStatusRow() {
    return new HTMLDivElement()
      ..className = 'flex-row-wrap'
      ..appendChildren(<HTMLElement>[
        new HTMLDivElement()
          ..className = 'isolate-ref-container'
          ..appendChildren(<HTMLElement>[
            new IsolateRefElement(_isolate, _events, queue: _r.queue).element
          ]),
        new HTMLDivElement()..style.flex = '1',
        new HTMLDivElement()
          ..className = 'flex-row isolate-state-container'
          ..appendChildren(<HTMLElement>[
            new IsolateRunStateElement(_isolate as M.Isolate, _events,
                    queue: _r.queue)
                .element,
            new IsolateLocationElement(_isolate as M.Isolate, _events, _scripts,
                    queue: _r.queue)
                .element,
            new HTMLSpanElement()..textContent = ' [',
            new HTMLAnchorElement()
              ..href = Uris.debugger(_isolate)
              ..textContent = 'debug',
            new HTMLSpanElement()..textContent = ']'
          ])
      ]);
  }

  HTMLElement memoryRow() {
    final isolate = _isolate as M.Isolate;
    final newHeapUsed = Utils.formatSize(isolate.newSpace!.used);
    final newHeapCapacity = Utils.formatSize(isolate.newSpace!.capacity);
    final oldHeapUsed = Utils.formatSize(isolate.oldSpace!.used);
    final oldHeapCapacity = Utils.formatSize(isolate.oldSpace!.capacity);
    final heapUsed =
        Utils.formatSize(isolate.newSpace!.used + isolate.oldSpace!.used);
    final heapCapacity = Utils.formatSize(
        isolate.newSpace!.capacity + isolate.oldSpace!.capacity);
    return new HTMLDivElement()
      ..className = 'flex-row-wrap-right'
      ..appendChildren(<HTMLElement>[
        new HTMLDivElement()
          ..style.padding = '5px'
          ..textContent = 'new-space $newHeapUsed of $newHeapCapacity',
        new HTMLDivElement()
          ..style.padding = '5px'
          ..textContent = '/',
        new HTMLDivElement()
          ..style.padding = '5px'
          ..textContent = 'old-space $oldHeapUsed of $oldHeapCapacity',
        new HTMLDivElement()
          ..style.padding = '5px'
          ..textContent = '/',
        new HTMLDivElement()
          ..style.padding = '5px'
          ..textContent = 'heap $heapUsed of $heapCapacity',
      ]);
  }

  HTMLElement toolsRow() {
    return new HTMLDivElement()
      ..className = 'flex-row-spaced'
      ..appendChildren(<HTMLElement>[
        new HTMLAnchorElement()
          ..href = Uris.debugger(_isolate)
          ..className = 'flex-item-even'
          ..text = 'debugger',
        new HTMLAnchorElement()
          ..href = Uris.classTree(_isolate)
          ..className = 'flex-item-even'
          ..text = 'class hierarchy',
        new HTMLAnchorElement()
          ..href = Uris.cpuProfiler(_isolate)
          ..className = 'flex-item-even'
          ..text = 'cpu profile',
        new HTMLAnchorElement()
          ..href = Uris.cpuProfilerTable(_isolate)
          ..className = 'flex-item-even'
          ..text = 'cpu profile (table)',
        new HTMLAnchorElement()
          ..href = Uris.allocationProfiler(_isolate)
          ..className = 'flex-item-even'
          ..text = 'allocation profile',
        new HTMLAnchorElement()
          ..href = Uris.heapSnapshot(_isolate)
          ..className = 'flex-item-even'
          ..text = 'heap snapshot',
        new HTMLAnchorElement()
          ..href = Uris.heapMap(_isolate)
          ..className = 'flex-item-even'
          ..text = 'heap map',
        new HTMLAnchorElement()
          ..href = Uris.metrics(_isolate)
          ..className = 'flex-item-even'
          ..text = 'metrics',
        new HTMLAnchorElement()
          ..href = Uris.persistentHandles(_isolate)
          ..className = 'flex-item-even'
          ..text = 'persistent handles',
        new HTMLAnchorElement()
          ..href = Uris.ports(_isolate)
          ..className = 'flex-item-even'
          ..text = 'ports',
        new HTMLAnchorElement()
          ..href = Uris.logging(_isolate)
          ..className = 'flex-item-even'
          ..text = 'logging',
      ]);
  }

  Future _load() async {
    _loadedIsolate = await _isolates.get(_isolate);
    _r.dirty();
  }
}
