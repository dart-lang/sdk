// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class EventRepositoryMock implements M.EventRepository {
  final _onEvent = new StreamController<M.Event>.broadcast();
  Stream<M.Event> get onEvent => _onEvent.stream;
  get onEventHasListener => _onEvent.hasListener;

  final _onVMEvent = new StreamController<M.VMEvent>.broadcast();
  Stream<M.VMEvent> get onVMEvent => _onVMEvent.stream;
  get onVMEventHasListener => _onVMEvent.hasListener;

  final _onVMUpdate = new StreamController<M.VMUpdateEvent>.broadcast();
  Stream<M.VMUpdateEvent> get onVMUpdate => _onVMUpdate.stream;
  get onVMUpdateHasListener => _onVMUpdate.hasListener;

  final _onIsolateEvent = new StreamController<M.IsolateEvent>.broadcast();
  Stream<M.IsolateEvent> get onIsolateEvent => _onIsolateEvent.stream;
  get onIsolateEventHasListener => _onIsolateEvent.hasListener;

  final _onIsolateStart = new StreamController<M.IsolateStartEvent>.broadcast();
  Stream<M.IsolateStartEvent> get onIsolateStart => _onIsolateStart.stream;
  get onIsolateStartHasListener => _onIsolateStart.hasListener;

  final _onIsolateRunnable =
      new StreamController<M.IsolateRunnableEvent>.broadcast();
  Stream<M.IsolateRunnableEvent> get onIsolateRunnable =>
      _onIsolateRunnable.stream;
  get onIsolateRunnableHasListener => _onIsolateRunnable.hasListener;

  final _onIsolateExit = new StreamController<M.IsolateExitEvent>.broadcast();
  Stream<M.IsolateExitEvent> get onIsolateExit => _onIsolateExit.stream;
  get onIsolateExitHasListener => _onIsolateExit.hasListener;

  final _onIsolateUpdate =
      new StreamController<M.IsolateUpdateEvent>.broadcast();
  Stream<M.IsolateUpdateEvent> get onIsolateUpdate => _onIsolateUpdate.stream;
  get onIsolateUpdateHasListener => _onIsolateUpdate.hasListener;

  final _onIsolateReload =
      new StreamController<M.IsolateReloadEvent>.broadcast();
  Stream<M.IsolateReloadEvent> get onIsolateReload => _onIsolateReload.stream;
  get onIsolateReloadHasListener => _onIsolateReload.hasListener;

  final _onServiceExtensionAdded =
      new StreamController<M.ServiceExtensionAddedEvent>.broadcast();
  Stream<M.ServiceExtensionAddedEvent> get onServiceExtensionAdded =>
      _onServiceExtensionAdded.stream;
  get onServiceExtensionAddedHasListener =>
      _onServiceExtensionAdded.hasListener;

  final _onDebugEvent = new StreamController<M.DebugEvent>.broadcast();
  Stream<M.DebugEvent> get onDebugEvent => _onDebugEvent.stream;
  get onDebugEventHasListener => _onDebugEvent.hasListener;

  final _onPauseStart = new StreamController<M.PauseStartEvent>.broadcast();
  Stream<M.PauseStartEvent> get onPauseStart => _onPauseStart.stream;
  get onPauseStartHasListener => _onPauseStart.hasListener;

  final _onPauseExit = new StreamController<M.PauseExitEvent>.broadcast();
  Stream<M.PauseExitEvent> get onPauseExit => _onPauseExit.stream;
  get onPauseExitHasListener => _onPauseExit.hasListener;

  final _onPauseBreakpoint =
      new StreamController<M.PauseBreakpointEvent>.broadcast();
  Stream<M.PauseBreakpointEvent> get onPauseBreakpoint =>
      _onPauseBreakpoint.stream;
  get onPauseBreakpointHasListener => _onPauseBreakpoint.hasListener;

  final _onPauseInterrupted =
      new StreamController<M.PauseInterruptedEvent>.broadcast();
  Stream<M.PauseInterruptedEvent> get onPauseInterrupted =>
      _onPauseInterrupted.stream;
  get onPauseInterruptedHasListener => _onPauseInterrupted.hasListener;

  final _onPauseException =
      new StreamController<M.PauseExceptionEvent>.broadcast();
  Stream<M.PauseExceptionEvent> get onPauseException =>
      _onPauseException.stream;
  get onPauseExceptionHasListener => _onPauseException.hasListener;

  final _onResume = new StreamController<M.ResumeEvent>.broadcast();
  Stream<M.ResumeEvent> get onResume => _onResume.stream;
  get onResumeHasListener => _onResume.hasListener;

  final _onBreakpointAdded =
      new StreamController<M.BreakpointAddedEvent>.broadcast();
  Stream<M.BreakpointAddedEvent> get onBreakpointAdded =>
      _onBreakpointAdded.stream;
  get onBreakpointAddedHasListener => _onBreakpointAdded.hasListener;

  final _onBreakpointResolved =
      new StreamController<M.BreakpointResolvedEvent>.broadcast();
  Stream<M.BreakpointResolvedEvent> get onBreakpointResolved =>
      _onBreakpointResolved.stream;
  get onBreakpointResolvedHasListener => _onBreakpointResolved.hasListener;

  final _onBreakpointRemoved =
      new StreamController<M.BreakpointRemovedEvent>.broadcast();
  Stream<M.BreakpointRemovedEvent> get onBreakpointRemoved =>
      _onBreakpointRemoved.stream;
  get onBreakpointRemovedHasListener => _onBreakpointRemoved.hasListener;

  final _onInspect = new StreamController<M.InspectEvent>.broadcast();
  Stream<M.InspectEvent> get onInspect => _onInspect.stream;
  get onInspectHasListener => _onInspect.hasListener;

  final _onGCEvent = new StreamController<M.GCEvent>.broadcast();
  Stream<M.GCEvent> get onGCEvent => _onGCEvent.stream;
  get onGCEventHasListener => _onGCEvent.hasListener;

  final _onLoggingEvent = new StreamController<M.LoggingEvent>.broadcast();
  Stream<M.LoggingEvent> get onLoggingEvent => _onLoggingEvent.stream;
  get onLoggingEventHasListener => _onLoggingEvent.hasListener;

  final _onExtensionEvent = new StreamController<M.ExtensionEvent>.broadcast();
  Stream<M.ExtensionEvent> get onExtensionEvent => _onExtensionEvent.stream;
  get onExtensionEventHasListener => _onExtensionEvent.hasListener;

  final _onTimelineEvents =
      new StreamController<M.TimelineEventsEvent>.broadcast();
  Stream<M.TimelineEventsEvent> get onTimelineEvents =>
      _onTimelineEvents.stream;
  get onTimelineEventsEventHasListener => _onTimelineEvents.hasListener;

  final _onConnectionClosed =
      new StreamController<M.ConnectionClosedEvent>.broadcast();
  Stream<M.ConnectionClosedEvent> get onConnectionClosed =>
      _onConnectionClosed.stream;
  get onConnectionClosedHasListener => _onConnectionClosed.hasListener;

  final _onServiceEvent = new StreamController<M.ServiceEvent>.broadcast();
  Stream<M.ServiceEvent> get onServiceEvent => _onServiceEvent.stream;
  get onServiceEventHasListener => _onServiceEvent.hasListener;

  final _onServiceRegistered =
      new StreamController<M.ServiceRegisteredEvent>.broadcast();
  Stream<M.ServiceRegisteredEvent> get onServiceRegistered =>
      _onServiceRegistered.stream;
  get onServiceRegisteredHasListener => _onServiceRegistered.hasListener;

  final _onServiceUnregistered =
      new StreamController<M.ServiceUnregisteredEvent>.broadcast();
  Stream<M.ServiceUnregisteredEvent> get onServiceUnregistered =>
      _onServiceUnregistered.stream;
  get onServiceUnregisteredHasListener => _onServiceUnregistered.hasListener;

  void add(M.Event event) {
    _onEvent.add(event);
    if (event is M.VMEvent) {
      _onVMEvent.add(event);
      if (event is M.VMUpdateEvent) {
        _onVMUpdate.add(event);
      }
    } else if (event is M.IsolateEvent) {
      _onIsolateEvent.add(event);
      if (event is M.IsolateStartEvent) {
        _onIsolateStart.add(event);
      } else if (event is M.IsolateRunnableEvent) {
        _onIsolateRunnable.add(event);
      } else if (event is M.IsolateExitEvent) {
        _onIsolateExit.add(event);
      } else if (event is M.IsolateUpdateEvent) {
        _onIsolateUpdate.add(event);
      } else if (event is M.ServiceExtensionAddedEvent) {
        _onServiceExtensionAdded.add(event);
      }
    } else if (event is M.DebugEvent) {
      _onDebugEvent.add(event);
      if (event is M.PauseStartEvent) {
        _onPauseStart.add(event);
      } else if (event is M.PauseExitEvent) {
        _onPauseExit.add(event);
      } else if (event is M.PauseBreakpointEvent) {
        _onPauseBreakpoint.add(event);
      } else if (event is M.PauseInterruptedEvent) {
        _onPauseInterrupted.add(event);
      } else if (event is M.PauseExceptionEvent) {
        _onPauseException.add(event);
      } else if (event is M.ResumeEvent) {
        _onResume.add(event);
      } else if (event is M.BreakpointAddedEvent) {
        _onBreakpointAdded.add(event);
      } else if (event is M.BreakpointResolvedEvent) {
        _onBreakpointResolved.add(event);
      } else if (event is M.BreakpointRemovedEvent) {
        _onBreakpointRemoved.add(event);
      } else if (event is M.InspectEvent) {
        _onInspect.add(event);
      }
    } else if (event is M.GCEvent) {
      _onGCEvent.add(event);
    } else if (event is M.ExtensionEvent) {
      _onExtensionEvent.add(event);
    } else if (event is M.TimelineEventsEvent) {
      _onTimelineEvents.add(event);
    } else if (event is M.ServiceEvent) {
      _onServiceEvent.add(event);
      if (event is M.ServiceRegisteredEvent) {
        _onServiceRegistered.add(event);
      } else if (event is M.ServiceUnregisteredEvent) {
        _onServiceUnregistered.add(event);
      }
    }
  }
}
