// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';

class IsolateRunStateElement extends CustomElement implements Renderable {
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
    IsolateRunStateElement e = new IsolateRunStateElement.created();
    e._r = new RenderingScheduler<IsolateRunStateElement>(e, queue: queue);
    e._isolate = isolate;
    e._events = events;
    return e;
  }

  IsolateRunStateElement.created() : super.created('isolate-run-state');

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
    children = <Element>[];
    _r.disable(notify: true);
    _debugSubscription.cancel();
    _isolateSubscription.cancel();
  }

  void render() {
    switch (_isolate.status) {
      case M.IsolateStatus.loading:
        children = <Element>[new SpanElement()..text = 'loading... '];
        break;
      case M.IsolateStatus.running:
        children = <Element>[new SpanElement()..text = 'running '];
        break;
      case M.IsolateStatus.idle:
        children = <Element>[new SpanElement()..text = 'idle '];
        break;
      case M.IsolateStatus.paused:
        children = <Element>[
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
