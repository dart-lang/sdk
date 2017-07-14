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

  EventRepository() : this._(new StreamController.broadcast());

  EventRepository._(StreamController controller)
      : this.__(
            controller,
            controller.stream.where((e) => e is M.VMEvent),
            controller.stream.where((e) => e is M.IsolateEvent),
            controller.stream.where((e) => e is M.DebugEvent),
            controller.stream.where((e) => e is M.GCEvent),
            controller.stream.where((e) => e is M.LoggingEvent),
            controller.stream.where((e) => e is M.ExtensionEvent),
            controller.stream.where((e) => e is M.TimelineEventsEvent),
            controller.stream.where((e) => e is M.ConnectionClosedEvent),
            controller.stream.where((e) => e is M.ServiceEvent));

  EventRepository.__(
      StreamController controller,
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
        onVMUpdate = onVMEvent.where((e) => e is M.VMUpdateEvent),
        onIsolateEvent = onIsolateEvent,
        onIsolateStart = onIsolateEvent.where((e) => e is M.IsolateStartEvent),
        onIsolateRunnable =
            onIsolateEvent.where((e) => e is M.IsolateRunnableEvent),
        onIsolateExit = onIsolateEvent.where((e) => e is M.IsolateExitEvent),
        onIsolateUpdate =
            onIsolateEvent.where((e) => e is M.IsolateUpdateEvent),
        onIsolateReload =
            onIsolateEvent.where((e) => e is M.IsolateReloadEvent),
        onServiceExtensionAdded =
            onIsolateEvent.where((e) => e is M.IsolateReloadEvent),
        onDebugEvent = onDebugEvent,
        onPauseStart = onDebugEvent.where((e) => e is M.PauseStartEvent),
        onPauseExit = onDebugEvent.where((e) => e is M.PauseExitEvent),
        onPauseBreakpoint =
            onDebugEvent.where((e) => e is M.PauseBreakpointEvent),
        onPauseInterrupted =
            onDebugEvent.where((e) => e is M.PauseInterruptedEvent),
        onPauseException =
            onDebugEvent.where((e) => e is M.PauseExceptionEvent),
        onResume = onDebugEvent.where((e) => e is M.ResumeEvent),
        onBreakpointAdded =
            onDebugEvent.where((e) => e is M.BreakpointAddedEvent),
        onBreakpointResolved =
            onDebugEvent.where((e) => e is M.BreakpointResolvedEvent),
        onBreakpointRemoved =
            onDebugEvent.where((e) => e is M.BreakpointRemovedEvent),
        onInspect = onDebugEvent.where((e) => e is M.InspectEvent),
        onGCEvent = onGCEvent,
        onLoggingEvent = onLoggingEvent,
        onExtensionEvent = onExtensionEvent,
        onTimelineEvents = onTimelineEvents,
        onConnectionClosed = onConnectionClosed,
        onServiceEvent = onServiceEvent,
        onServiceRegistered =
            onServiceEvent.where((e) => e is M.ServiceRegisteredEvent),
        onServiceUnregistered =
            onServiceEvent.where((e) => e is M.ServiceUnregisteredEvent);

  void add(M.Event e) {
    _onEvent.add(e);
  }
}
