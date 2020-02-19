// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/isolate_ref.dart';
import 'package:observatory/src/elements/isolate/location.dart';
import 'package:observatory/src/elements/isolate/run_state.dart';
import 'package:observatory/src/elements/isolate/shared_summary.dart';

class IsolateSummaryElement extends CustomElement implements Renderable {
  static const tag =
      const Tag<IsolateSummaryElement>('isolate-summary', dependencies: const [
    IsolateRefElement.tag,
    IsolateLocationElement.tag,
    IsolateRunStateElement.tag,
    IsolateSharedSummaryElement.tag
  ]);

  RenderingScheduler<IsolateSummaryElement> _r;

  Stream<RenderedEvent<IsolateSummaryElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.EventRepository _events;
  M.IsolateRepository _isolates;
  M.ScriptRepository _scripts;
  M.Isolate _loadedIsolate;

  factory IsolateSummaryElement(
      M.IsolateRef isolate,
      M.IsolateRepository isolates,
      M.EventRepository events,
      M.ScriptRepository scripts,
      {RenderingQueue queue}) {
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

  IsolateSummaryElement.created() : super.created(tag);

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
        new DivElement()
          ..classes = ['flex-row']
          ..children = <Element>[
            new DivElement()
              ..classes = ['isolate-ref-container']
              ..children = <Element>[
                new IsolateRefElement(_isolate, _events, queue: _r.queue)
                    .element
              ],
            new DivElement()..style.flex = '1',
            new DivElement()
              ..classes = ['flex-row', 'isolate-state-container']
              ..children = <Element>[
                new IsolateRunStateElement(_isolate, _events, queue: _r.queue)
                    .element,
                new IsolateLocationElement(_isolate, _events, _scripts,
                        queue: _r.queue)
                    .element,
                new SpanElement()..text = ' [',
                new AnchorElement(href: Uris.debugger(_isolate))
                  ..text = 'debug',
                new SpanElement()..text = ']'
              ]
          ],
        new BRElement(),
        new IsolateSharedSummaryElement(_isolate, _events, queue: _r.queue)
            .element
      ];
    }
  }

  Future _load() async {
    _loadedIsolate = await _isolates.get(_isolate);
    _r.dirty();
  }
}
