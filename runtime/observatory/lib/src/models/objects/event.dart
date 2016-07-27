// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

abstract class Event {
  DateTime get timestamp;
  static bool isPauseEvent(Event event) {
    return event is PauseStartEvent || event is PauseExitEvent ||
        event is PauseBreakpointEvent || event is PauseInterruptedEvent ||
        event is PauseExceptionEvent || event is NoneEvent;
  }
}
abstract class VMEvent extends Event {
  VMRef get vm;
}
abstract class VMUpdateEvent extends VMEvent {}
abstract class IsolateEvent extends Event {
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
  String get extensionRPC;
}
abstract class DebugEvent extends IsolateEvent {}
abstract class PauseStartEvent extends DebugEvent {}
abstract class PauseExitEvent extends DebugEvent {}
abstract class PauseBreakpointEvent extends DebugEvent {
  /// [optional]
  Breakpoint get breakpoint;
  Iterable<Breakpoint> get pauseBreakpoints;
  Frame get topFrame;
  bool get atAsyncSuspension;
}
abstract class PauseInterruptedEvent extends DebugEvent {
  Frame get topFrame;
  bool get atAsyncSuspension;
}
abstract class PauseExceptionEvent extends DebugEvent {
  Frame get topFrame;
  InstanceRef get exception;
}
abstract class ResumeEvent extends DebugEvent {}
abstract class BreakpointAddedEvent extends DebugEvent {
  Breakpoint get breakpoint;
}
abstract class BreakpointResolvedEvent extends DebugEvent {
  Breakpoint get breakpoint;
}
abstract class BreakpointRemovedEvent extends DebugEvent {
  Breakpoint get breakpoint;
}
abstract class InspectEvent extends DebugEvent {
  InstanceRef get inspectee;
}
abstract class NoneEvent extends DebugEvent {}
abstract class GCEvent extends IsolateEvent {}
abstract class ExtensionEvent extends Event {
  IsolateRef get isolate;
  String get extensionKind;
  ExtensionData get extensionData;
}
abstract class TimelineEventsEvent extends IsolateEvent {
  Iterable<TimelineEvent> get timelineEvents;
}
abstract class ConnectionClosedEvent extends Event {
  String get reason;
}
