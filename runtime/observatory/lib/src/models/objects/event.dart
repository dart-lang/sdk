// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class Event {
  /// The timestamp (in milliseconds since the epoch) associated with this
  /// event. For some isolate pause events, the timestamp is from when the
  /// isolate was paused. For other events, the timestamp is from when the
  /// event was created.
  DateTime get timestamp;
  static bool isPauseEvent(Event event) {
    return event is PauseStartEvent ||
        event is PauseExitEvent ||
        event is PauseBreakpointEvent ||
        event is PauseInterruptedEvent ||
        event is PauseExceptionEvent ||
        event is PausePostRequestEvent ||
        event is NoneEvent;
  }
}

abstract class VMEvent extends Event {
  /// The vm with which this event is associated.
  VMRef get vm;
}

abstract class VMUpdateEvent extends VMEvent {}

abstract class IsolateEvent extends Event {
  /// The isolate with which this event is associated.
  IsolateRef get isolate;
}

abstract class IsolateStartEvent extends IsolateEvent {}

abstract class IsolateRunnableEvent extends IsolateEvent {}

abstract class IsolateExitEvent extends IsolateEvent {}

abstract class IsolateUpdateEvent extends IsolateEvent {}

abstract class IsolateReloadEvent extends IsolateEvent {
  ErrorRef get error;
}

abstract class ServiceExtensionAddedEvent extends IsolateEvent {
  /// The RPC name of the extension that was added.
  String get extensionRPC;
}

abstract class DebugEvent extends Event {
  /// The isolate with which this event is associated.
  IsolateRef get isolate;
}

abstract class BreakpointEvent extends DebugEvent {
  /// [optional] The breakpoint associated with this event.
  Breakpoint get breakpoint;
}

abstract class PauseEvent extends DebugEvent {}

abstract class AsyncSuspensionEvent extends PauseEvent {
  /// Is the isolate paused at an await, yield, or yield* statement?
  bool get atAsyncSuspension;
}

abstract class DebuggerSettingsUpdateEvent extends DebugEvent {}

abstract class PauseStartEvent extends PauseEvent {}

abstract class PauseExitEvent extends PauseEvent {}

abstract class PauseBreakpointEvent extends AsyncSuspensionEvent {
  /// [optional] The breakpoint at which we are currently paused.
  Breakpoint? get breakpoint;

  /// The list of breakpoints at which we are currently paused
  /// for a PauseBreakpoint event.
  ///
  /// This list may be empty. For example, while single-stepping, the
  /// VM sends a PauseBreakpoint event with no breakpoints.
  ///
  /// If there is more than one breakpoint set at the program position,
  /// then all of them will be provided.
  Iterable<Breakpoint> get pauseBreakpoints;

  /// The top stack frame associated with this event.
  Frame get topFrame;
}

abstract class PauseInterruptedEvent extends AsyncSuspensionEvent {
  /// [optional] The top stack frame associated with this event. There will be
  /// no top frame if the isolate is idle (waiting in the message loop).
  Frame? get topFrame;
}

abstract class PausePostRequestEvent extends AsyncSuspensionEvent {
  /// [optional] The top stack frame associated with this event. There will be
  /// no top frame if the isolate is idle (waiting in the message loop).
  Frame? get topFrame;
}

abstract class PauseExceptionEvent extends PauseEvent {
  /// The top stack frame associated with this event.
  Frame get topFrame;

  /// The exception associated with this event
  InstanceRef get exception;
}

abstract class ResumeEvent extends DebugEvent {
  /// [optional] The top stack frame associated with this event. It is provided
  /// at all times except for the initial resume event that is delivered when an
  /// isolate begins execution.
  Frame? get topFrame;
}

abstract class BreakpointAddedEvent extends BreakpointEvent {}

abstract class BreakpointResolvedEvent extends BreakpointEvent {}

abstract class BreakpointRemovedEvent extends BreakpointEvent {}

abstract class InspectEvent extends DebugEvent {
  /// The argument passed to dart:developer.inspect.
  InstanceRef get inspectee;
}

abstract class NoneEvent extends PauseEvent {}

abstract class GCEvent extends Event {
  /// The isolate with which this event is associated.
  IsolateRef get isolate;
}

abstract class ExtensionEvent extends Event {
  /// The isolate with which this event is associated.
  IsolateRef get isolate;

  /// The extension event kind.
  String get extensionKind;

  /// The extension event data.
  ExtensionData get extensionData;
}

abstract class LoggingEvent extends Event {
  /// The isolate with which this event is associated.
  IsolateRef get isolate;

  // TODO(cbernaschina) objectify
  Map get logRecord;
}

abstract class TimelineEventsEvent extends Event {
  /// The isolate with which this event is associated.
  IsolateRef get isolate;

  /// An array of TimelineEvents
  Iterable<TimelineEvent> get timelineEvents;
}

abstract class ConnectionClosedEvent extends Event {
  /// The reason of the closed connection
  String get reason;
}

Frame? topFrame(Event? event) {
  if (event is PauseBreakpointEvent) {
    return event.topFrame;
  }
  if (event is PauseInterruptedEvent) {
    return event.topFrame;
  }
  if (event is PauseExceptionEvent) {
    return event.topFrame;
  }
  if (event is ResumeEvent) {
    return event.topFrame;
  }
  return null;
}

bool isAtAsyncSuspension(DebugEvent? event) {
  if (event is PauseBreakpointEvent) {
    return event.atAsyncSuspension;
  }
  if (event is PauseInterruptedEvent) {
    return event.atAsyncSuspension;
  }
  return false;
}

abstract class ServiceEvent extends Event {
  /// The identifier of the service
  String get service;

  /// The JSON-RPC 2.0 Method that identifes this instance
  String get method;
}

abstract class ServiceRegisteredEvent extends ServiceEvent {
  /// The alias associated with this new instance
  String get alias;
}

abstract class ServiceUnregisteredEvent extends ServiceEvent {}
