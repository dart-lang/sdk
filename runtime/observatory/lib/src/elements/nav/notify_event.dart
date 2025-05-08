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

class EventDeleteEvent {
  final M.Event event;
  EventDeleteEvent(this.event);
}

class NavNotifyEventElement extends CustomElement implements Renderable {
  late RenderingScheduler<NavNotifyEventElement> _r;

  Stream<RenderedEvent<NavNotifyEventElement>> get onRendered => _r.onRendered;

  final StreamController<EventDeleteEvent> _onDelete =
      new StreamController<EventDeleteEvent>.broadcast();
  Stream<EventDeleteEvent> get onDelete => _onDelete.stream;

  late M.Event _event;

  M.Event get event => _event;

  factory NavNotifyEventElement(M.Event event, {RenderingQueue? queue}) {
    NavNotifyEventElement e = new NavNotifyEventElement.created();
    e._r = new RenderingScheduler<NavNotifyEventElement>(e, queue: queue);
    e._event = event;
    return e;
  }

  NavNotifyEventElement.created() : super.created('nav-event');

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
  }

  void render() {
    removeChildren();
    List<HTMLElement> content;
    if (event is M.PauseStartEvent) {
      content = _managePauseStartEvent(event as M.PauseStartEvent);
    } else if (event is M.PauseExitEvent) {
      content = _managePauseExitEvent(event as M.PauseExitEvent);
    } else if (event is M.PauseBreakpointEvent) {
      content = _managePauseBreakpointEvent(event as M.PauseBreakpointEvent);
    } else if (event is M.PauseInterruptedEvent) {
      content = _managePauseInterruptedEvent(event as M.PauseInterruptedEvent);
    } else if (event is M.PauseExceptionEvent) {
      content = _managePauseExceptionEvent(event as M.PauseExceptionEvent);
    } else if (event is M.NoneEvent) {
      content = _manageNoneEvent(event as M.NoneEvent);
    } else if (event is M.ConnectionClosedEvent) {
      content = _manageConnectionClosedEvent(event as M.ConnectionClosedEvent);
    } else if (event is M.InspectEvent) {
      content = _manageInspectEvent(event as M.InspectEvent);
    } else if (event is M.IsolateReloadEvent) {
      content = _manageIsolateReloadEvent(event as M.IsolateReloadEvent);
    } else {
      return;
    }
    children = <HTMLElement>[
      new HTMLDivElement()
        ..appendChildren(content)
        ..appendChild(new HTMLButtonElement()
          ..textContent = '×'
          ..onClick.map(_toEvent).listen(_delete))
    ];
  }

  static List<HTMLElement> _managePauseStartEvent(M.PauseStartEvent event) {
    return [
      new HTMLSpanElement()..textContent = 'Isolate ',
      new HTMLAnchorElement()
        ..href = Uris.inspect(event.isolate)
        ..text = event.isolate.name ?? '',
      new HTMLSpanElement()..textContent = ' is paused at isolate start',
      new HTMLBRElement(),
      new HTMLBRElement(),
      new HTMLSpanElement()..textContent = '[',
      new HTMLAnchorElement()
        ..href = Uris.debugger(event.isolate)
        ..text = 'debug',
      new HTMLSpanElement()..textContent = ']'
    ];
  }

  static List<HTMLElement> _managePauseExitEvent(M.PauseExitEvent event) {
    return [
      new HTMLSpanElement()..textContent = 'Isolate ',
      new HTMLAnchorElement()
        ..href = Uris.inspect(event.isolate)
        ..text = event.isolate.name ?? '',
      new HTMLSpanElement()..textContent = ' is paused at isolate exit',
      new HTMLBRElement(),
      new HTMLBRElement(),
      new HTMLSpanElement()..textContent = '[',
      new HTMLAnchorElement()
        ..href = Uris.debugger(event.isolate)
        ..text = 'debug',
      new HTMLSpanElement()..textContent = ']'
    ];
  }

  static List<HTMLElement> _managePauseBreakpointEvent(
      M.PauseBreakpointEvent event) {
    String message = ' is paused';
    if (event.breakpoint != null) {
      message += ' at breakpoint ${event.breakpoint!.number}';
    }
    return [
      new HTMLSpanElement()..textContent = 'Isolate ',
      new HTMLAnchorElement()
        ..href = Uris.inspect(event.isolate)
        ..text = event.isolate.name ?? '',
      new HTMLSpanElement()..textContent = message,
      new HTMLBRElement(),
      new HTMLBRElement(),
      new HTMLSpanElement()..textContent = '[',
      new HTMLAnchorElement()
        ..href = Uris.debugger(event.isolate)
        ..text = 'debug',
      new HTMLSpanElement()..textContent = ']'
    ];
  }

  static List<HTMLElement> _managePauseInterruptedEvent(
      M.PauseInterruptedEvent event) {
    return [
      new HTMLSpanElement()..textContent = 'Isolate ',
      new HTMLAnchorElement()
        ..href = Uris.inspect(event.isolate)
        ..text = event.isolate.name ?? '',
      new HTMLSpanElement()..textContent = ' is paused',
      new HTMLBRElement(),
      new HTMLBRElement(),
      new HTMLSpanElement()..textContent = '[',
      new HTMLAnchorElement()
        ..href = Uris.debugger(event.isolate)
        ..text = 'debug',
      new HTMLSpanElement()..textContent = ']'
    ];
  }

  static List<HTMLElement> _managePauseExceptionEvent(
      M.PauseExceptionEvent event) {
    return [
      new HTMLSpanElement()..textContent = 'Isolate ',
      new HTMLAnchorElement()
        ..href = Uris.inspect(event.isolate)
        ..text = event.isolate.name ?? '',
      new HTMLSpanElement()..textContent = ' is paused due to exception',
      new HTMLBRElement(),
      new HTMLBRElement(),
      new HTMLSpanElement()..textContent = '[',
      new HTMLAnchorElement()
        ..href = Uris.debugger(event.isolate)
        ..text = 'debug',
      new HTMLSpanElement()..textContent = ']'
    ];
  }

  static List<HTMLElement> _manageNoneEvent(M.NoneEvent event) {
    return [
      new HTMLSpanElement()..textContent = 'Isolate ',
      new HTMLAnchorElement()
        ..href = Uris.inspect(event.isolate)
        ..text = event.isolate.name ?? '',
      new HTMLSpanElement()..textContent = ' is paused',
      new HTMLBRElement(),
      new HTMLBRElement(),
      new HTMLSpanElement()..textContent = '[',
      new HTMLAnchorElement()
        ..href = Uris.debugger(event.isolate)
        ..text = 'debug',
      new HTMLSpanElement()..textContent = ']'
    ];
  }

  static List<HTMLElement> _manageConnectionClosedEvent(
      M.ConnectionClosedEvent event) {
    return [
      new HTMLSpanElement()
        ..textContent = 'Disconnected from VM: ${event.reason}',
      new HTMLBRElement(),
      new HTMLBRElement(),
      new HTMLSpanElement()..textContent = '[',
      new HTMLAnchorElement()
        ..href = Uris.vmConnect()
        ..text = 'Connect to a VM',
      new HTMLSpanElement()..textContent = ']'
    ];
  }

  static List<HTMLElement> _manageInspectEvent(M.InspectEvent event) {
    return [
      new HTMLSpanElement()..textContent = 'Inspect ${event.inspectee.id}',
      new HTMLBRElement(), new HTMLBRElement(),
      new HTMLSpanElement()..textContent = '[',
      new HTMLAnchorElement()
        ..href = Uris.inspect(event.isolate, object: event.inspectee)
        ..text = 'Inspect',
      new HTMLSpanElement()..textContent = ']'
      // TODO(cbernaschina) add InstanceRefElement back.
      //new InstanceRefElement()..instance = event.inspectee
    ];
  }

  static List<HTMLElement> _manageIsolateReloadEvent(
      M.IsolateReloadEvent event) {
    return [
      new HTMLSpanElement()..textContent = 'Isolate reload failed:',
      new HTMLBRElement(),
      new HTMLBRElement(),
      new HTMLDivElement()
        ..className = "indent error"
        ..textContent = event.error.message.toString()
    ];
  }

  EventDeleteEvent _toEvent(_) {
    return new EventDeleteEvent(_event);
  }

  void _delete(EventDeleteEvent e) {
    _onDelete.add(e);
  }

  void delete() {
    _onDelete.add(new EventDeleteEvent(_event));
  }
}
