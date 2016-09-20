// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';

class IsolateRunStateElement extends HtmlElement implements Renderable {
  static const tag = const Tag<IsolateRunStateElement>('isolate-run-state');

  RenderingScheduler<IsolateRunStateElement> _r;

  Stream<RenderedEvent<IsolateRunStateElement>> get onRendered => _r.onRendered;

  M.Isolate _isolate;
  M.EventRepository _events;
  StreamSubscription _debugSubscription;
  StreamSubscription _isolateSubscription;

  factory IsolateRunStateElement(M.Isolate isolate, M.EventRepository events,
      {RenderingQueue queue}) {
    assert(isolate != null);
    assert(events != null);
    IsolateRunStateElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._events = events;
    return e;
  }

  IsolateRunStateElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
    _debugSubscription = _events.onDebugEvent.listen(_eventListener);
    _isolateSubscription = _events.onIsolateEvent.listen(_eventListener);
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
    _debugSubscription.cancel();
    _isolateSubscription.cancel();
  }

  void render() {
    switch (_isolate.status) {
      case M.IsolateStatus.loading:
        children = [new SpanElement()..text = 'loading... '];
        break;
      case M.IsolateStatus.running:
        children = [new SpanElement()..text = 'running '];
        break;
      case M.IsolateStatus.idle:
        children = [new SpanElement()..text = 'idle '];
        break;
      case M.IsolateStatus.paused:
        children = [
          new SpanElement()
            ..title = '${_isolate.pauseEvent.timestamp}'
            ..text = 'paused '
        ];
        break;
    }
  }

  void _eventListener(e) {
    if (e.isolate.id == _isolate.id) {
      _isolate = e.isolate;
      _r.dirty();
    }
  }
}
