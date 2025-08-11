// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:web/web.dart';

import '../../../models.dart' as M;
import '../helpers/custom_element.dart';
import '../helpers/rendering_scheduler.dart';

class IsolateRunStateElement extends CustomElement implements Renderable {
  late RenderingScheduler<IsolateRunStateElement> _r;

  Stream<RenderedEvent<IsolateRunStateElement>> get onRendered => _r.onRendered;

  late M.Isolate _isolate;
  late M.EventRepository _events;
  late StreamSubscription _debugSubscription;
  late StreamSubscription _isolateSubscription;

  factory IsolateRunStateElement(
    M.Isolate isolate,
    M.EventRepository events, {
    RenderingQueue? queue,
  }) {
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
    removeChildren();
    _r.disable(notify: true);
    _debugSubscription.cancel();
    _isolateSubscription.cancel();
  }

  void render() {
    switch (_isolate.status!) {
      case M.IsolateStatus.loading:
        children = <HTMLElement>[
          new HTMLSpanElement()..textContent = 'loading... ',
        ];
        break;
      case M.IsolateStatus.running:
        children = <HTMLElement>[
          new HTMLSpanElement()..textContent = 'running ',
        ];
        break;
      case M.IsolateStatus.idle:
        children = <HTMLElement>[new HTMLSpanElement()..textContent = 'idle '];
        break;
      case M.IsolateStatus.paused:
        children = <HTMLElement>[
          new HTMLSpanElement()
            ..title = '${_isolate.pauseEvent!.timestamp}'
            ..textContent = 'paused ',
        ];
        break;
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
