// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/source_link.dart';

class IsolateLocationElement extends CustomElement implements Renderable {
  late RenderingScheduler<IsolateLocationElement> _r;

  Stream<RenderedEvent<IsolateLocationElement>> get onRendered => _r.onRendered;

  late M.Isolate _isolate;
  late M.EventRepository _events;
  late M.ScriptRepository _scripts;
  late StreamSubscription _debugSubscription;
  late StreamSubscription _isolateSubscription;

  factory IsolateLocationElement(
      M.Isolate isolate, M.EventRepository events, M.ScriptRepository scripts,
      {RenderingQueue? queue}) {
    assert(isolate != null);
    assert(events != null);
    assert(scripts != null);
    IsolateLocationElement e = new IsolateLocationElement.created();
    e._r = new RenderingScheduler<IsolateLocationElement>(e, queue: queue);
    e._isolate = isolate;
    e._events = events;
    e._scripts = scripts;
    return e;
  }

  IsolateLocationElement.created() : super.created('isolate-location');

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
        children = <Element>[new SpanElement()..text = 'not yet runnable'];
        break;
      case M.IsolateStatus.running:
        children = <Element>[
          new SpanElement()..text = 'at ',
          new FunctionRefElement(
                  _isolate, M.topFrame(_isolate.pauseEvent)!.function!,
                  queue: _r.queue)
              .element,
          new SpanElement()..text = ' (',
          new SourceLinkElement(_isolate,
                  M.topFrame(_isolate.pauseEvent)!.location!, _scripts,
                  queue: _r.queue)
              .element,
          new SpanElement()..text = ') '
        ];
        break;
      case M.IsolateStatus.paused:
        if (_isolate.pauseEvent is M.PauseStartEvent) {
          children = <Element>[new SpanElement()..text = 'at isolate start'];
        } else if (_isolate.pauseEvent is M.PauseExitEvent) {
          children = <Element>[new SpanElement()..text = 'at isolate exit'];
        } else if (_isolate.pauseEvent is M.NoneEvent) {
          children = <Element>[new SpanElement()..text = 'not yet runnable'];
        } else {
          final content = <Element>[];
          if (_isolate.pauseEvent is M.PauseBreakpointEvent) {
            content.add(new SpanElement()..text = 'by breakpoint');
          } else if (_isolate.pauseEvent is M.PauseExceptionEvent) {
            content.add(new SpanElement()..text = 'by exception');
          }
          if (M.topFrame(_isolate.pauseEvent) != null) {
            content.addAll([
              new SpanElement()..text = ' at ',
              new FunctionRefElement(
                      _isolate, M.topFrame(_isolate.pauseEvent)!.function!,
                      queue: _r.queue)
                  .element,
              new SpanElement()..text = ' (',
              new SourceLinkElement(_isolate,
                      M.topFrame(_isolate.pauseEvent)!.location!, _scripts,
                      queue: _r.queue)
                  .element,
              new SpanElement()..text = ') '
            ]);
          }
          children = content;
        }
        break;
      default:
        children = const [];
    }
  }

  void _eventListener(e) {
    if (e.isolate.id == _isolate.id) {
      _r.dirty();
    }
  }
}
