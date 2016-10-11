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

class IsolateSummaryElement extends HtmlElement implements Renderable {
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
    IsolateSummaryElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._isolates = isolates;
    e._events = events;
    e._scripts = scripts;
    return e;
  }

  IsolateSummaryElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
    _load();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void render() {
    if (_loadedIsolate == null) {
      children = [
        new SpanElement()..text = 'loading ',
        new IsolateRefElement(_isolate, _events, queue: _r.queue)
      ];
    } else {
      children = [
        new DivElement()
          ..classes = ['flex-row']
          ..children = [
            new DivElement()
              ..children = [
                new IsolateRefElement(_isolate, _events, queue: _r.queue)
              ],
            new DivElement()..style.flex = '1',
            new DivElement()
              ..children = [
                new IsolateRunStateElement(_isolate, _events, queue: _r.queue),
                new IsolateLocationElement(_isolate, _events, _scripts,
                    queue: _r.queue),
                new SpanElement()..text = ' [',
                new AnchorElement(href: Uris.debugger(_isolate))
                  ..text = 'debug',
                new SpanElement()..text = ']'
              ]
          ],
        new BRElement(),
        new IsolateSharedSummaryElement(_isolate, _events, queue: _r.queue)
      ];
    }
  }

  Future _load() async {
    _loadedIsolate = await _isolates.get(_isolate);
    _r.dirty();
  }
}
