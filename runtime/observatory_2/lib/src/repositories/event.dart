// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of repositories;

class EventRepository implements M.EventRepository {
  final StreamController<M.Event> _onEvent;
  Stream<M.Event> get onEvent => _onEvent.stream;

  final Stream<M.VMEvent> onVMEvent;
  final Stream<M.VMUpdateEvent> onVMUpdate;
  final Stream<M.IsolateEvent> onIsolateEvent;
  final Stream<M.IsolateStartEvent> onIsolateStart;
  final Stream<M.IsolateRunnableEvent> onIsolateRunnable;
  final Stream<M.IsolateExitEvent> onIsolateExit;
  final Stream<M.IsolateUpdateEvent> onIsolateUpdate;
  final Stream<M.IsolateReloadEvent> onIsolateReload;
  final Stream<M.ServiceExtensionAddedEvent> onServiceExtensionAdded;
  final Stream<M.DebugEvent> onDebugEvent;
  final Stream<M.PauseStartEvent> onPauseStart;
  final Stream<M.PauseExitEvent> onPauseExit;
  final Stream<M.PauseBreakpointEvent> onPauseBreakpoint;
  final Stream<M.PauseInterruptedEvent> onPauseInterrupted;
  final Stream<M.PauseExceptionEvent> onPauseException;
  final Stream<M.ResumeEvent> onResume;
  final Stream<M.BreakpointAddedEvent> onBreakpointAdded;
  final Stream<M.BreakpointResolvedEvent> onBreakpointResolved;
  final Stream<M.BreakpointRemovedEvent> onBreakpointRemoved;
  final Stream<M.InspectEvent> onInspect;
  final Stream<M.GCEvent> onGCEvent;
  final Stream<M.LoggingEvent> onLoggingEvent;
  final Stream<M.ExtensionEvent> onExtensionEvent;
  final Stream<M.TimelineEventsEvent> onTimelineEvents;
  final Stream<M.ConnectionClosedEvent> onConnectionClosed;
  final Stream<M.ServiceEvent> onServiceEvent;
  final Stream<M.ServiceRegisteredEvent> onServiceRegistered;
  final Stream<M.ServiceUnregisteredEvent> onServiceUnregistered;

  static Stream<T> where<T extends M.Event>(
      Stream<M.Event> stream, bool predicate(M.Event event)) {
    var controller = new StreamController<T>.broadcast();
    stream.listen(
      (M.Event event) {
        if (predicate(event)) {
          controller.add(event as T);
        }
      },
      onError: (error) => controller.addError(error),
      onDone: () => controller.close(),
    );
    return controller.stream;
  }

  EventRepository() : this._(new StreamController<M.Event>.broadcast());

  EventRepository._(StreamController<M.Event> controller)
      : this.__(
            controller,
            where<M.VMEvent>(controller.stream, (e) => e is M.VMEvent),
            where<M.IsolateEvent>(
                controller.stream, (e) => e is M.IsolateEvent),
            where<M.DebugEvent>(controller.stream, (e) => e is M.DebugEvent),
            where<M.GCEvent>(controller.stream, (e) => e is M.GCEvent),
            where<M.LoggingEvent>(
                controller.stream, (e) => e is M.LoggingEvent),
            where<M.ExtensionEvent>(
                controller.stream, (e) => e is M.ExtensionEvent),
            where<M.TimelineEventsEvent>(
                controller.stream, (e) => e is M.TimelineEventsEvent),
            where<M.ConnectionClosedEvent>(
                controller.stream, (e) => e is M.ConnectionClosedEvent),
            where<M.ServiceEvent>(
                controller.stream, (e) => e is M.ServiceEvent));

  EventRepository.__(
      StreamController<M.Event> controller,
      Stream<M.VMEvent> onVMEvent,
      Stream<M.IsolateEvent> onIsolateEvent,
      Stream<M.DebugEvent> onDebugEvent,
      Stream<M.GCEvent> onGCEvent,
      Stream<M.LoggingEvent> onLoggingEvent,
      Stream<M.ExtensionEvent> onExtensionEvent,
      Stream<M.TimelineEventsEvent> onTimelineEvents,
      Stream<M.ConnectionClosedEvent> onConnectionClosed,
      Stream<M.ServiceEvent> onServiceEvent)
      : _onEvent = controller,
        onVMEvent = onVMEvent,
        onVMUpdate =
            where<M.VMUpdateEvent>(onVMEvent, (e) => e is M.VMUpdateEvent),
        onIsolateEvent = onIsolateEvent,
        onIsolateStart = where<M.IsolateStartEvent>(
            onIsolateEvent, (e) => e is M.IsolateStartEvent),
        onIsolateRunnable = where<M.IsolateRunnableEvent>(
            onIsolateEvent, (e) => e is M.IsolateRunnableEvent),
        onIsolateExit = where<M.IsolateExitEvent>(
            onIsolateEvent, (e) => e is M.IsolateExitEvent),
        onIsolateUpdate = where<M.IsolateUpdateEvent>(
            onIsolateEvent, (e) => e is M.IsolateUpdateEvent),
        onIsolateReload = where<M.IsolateReloadEvent>(
            onIsolateEvent, (e) => e is M.IsolateReloadEvent),
        onServiceExtensionAdded = where<M.ServiceExtensionAddedEvent>(
            onIsolateEvent, (e) => e is M.ServiceExtensionAddedEvent),
        onDebugEvent = onDebugEvent,
        onPauseStart = where<M.PauseStartEvent>(
            onDebugEvent, (e) => e is M.PauseStartEvent),
        onPauseExit =
            where<M.PauseExitEvent>(onDebugEvent, (e) => e is M.PauseExitEvent),
        onPauseBreakpoint = where<M.PauseBreakpointEvent>(
            onDebugEvent, (e) => e is M.PauseBreakpointEvent),
        onPauseInterrupted = where<M.PauseInterruptedEvent>(
            onDebugEvent, (e) => e is M.PauseInterruptedEvent),
        onPauseException = where<M.PauseExceptionEvent>(
            onDebugEvent, (e) => e is M.PauseExceptionEvent),
        onResume =
            where<M.ResumeEvent>(onDebugEvent, (e) => e is M.ResumeEvent),
        onBreakpointAdded = where<M.BreakpointAddedEvent>(
            onDebugEvent, (e) => e is M.BreakpointAddedEvent),
        onBreakpointResolved = where<M.BreakpointResolvedEvent>(
            onDebugEvent, (e) => e is M.BreakpointResolvedEvent),
        onBreakpointRemoved = where<M.BreakpointRemovedEvent>(
            onDebugEvent, (e) => e is M.BreakpointRemovedEvent),
        onInspect =
            where<M.InspectEvent>(onDebugEvent, (e) => e is M.InspectEvent),
        onGCEvent = onGCEvent,
        onLoggingEvent = onLoggingEvent,
        onExtensionEvent = onExtensionEvent,
        onTimelineEvents = onTimelineEvents,
        onConnectionClosed = onConnectionClosed,
        onServiceEvent = onServiceEvent,
        onServiceRegistered = where<M.ServiceRegisteredEvent>(
            onServiceEvent, (e) => e is M.ServiceRegisteredEvent),
        onServiceUnregistered = where<M.ServiceUnregisteredEvent>(
            onServiceEvent, (e) => e is M.ServiceUnregisteredEvent);

  void add(M.Event e) {
    _onEvent.add(e);
  }
}
