// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class EventRepository {
  Stream<Event> get onEvent;
  Stream<VMEvent> get onVMEvent;
  Stream<VMUpdateEvent> get onVMUpdate;
  Stream<IsolateEvent> get onIsolateEvent;
  Stream<IsolateStartEvent> get onIsolateStart;
  Stream<IsolateRunnableEvent> get onIsolateRunnable;
  Stream<IsolateExitEvent> get onIsolateExit;
  Stream<IsolateUpdateEvent> get onIsolateUpdate;
  Stream<IsolateReloadEvent> get onIsolateReload;
  Stream<ServiceExtensionAddedEvent> get onServiceExtensionAdded;
  Stream<DebugEvent> get onDebugEvent;
  Stream<PauseStartEvent> get onPauseStart;
  Stream<PauseExitEvent> get onPauseExit;
  Stream<PauseBreakpointEvent> get onPauseBreakpoint;
  Stream<PauseInterruptedEvent> get onPauseInterrupted;
  Stream<PauseExceptionEvent> get onPauseException;
  Stream<ResumeEvent> get onResume;
  Stream<BreakpointAddedEvent> get onBreakpointAdded;
  Stream<BreakpointResolvedEvent> get onBreakpointResolved;
  Stream<BreakpointRemovedEvent> get onBreakpointRemoved;
  Stream<InspectEvent> get onInspect;
  Stream<GCEvent> get onGCEvent;
  Stream<LoggingEvent> get onLoggingEvent;
  Stream<ExtensionEvent> get onExtensionEvent;
  Stream<TimelineEventsEvent> get onTimelineEvents;
  Stream<ConnectionClosedEvent> get onConnectionClosed;
  Stream<ServiceEvent> get onServiceEvent;
  Stream<ServiceRegisteredEvent> get onServiceRegistered;
  Stream<ServiceUnregisteredEvent> get onServiceUnregistered;
}
