// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

class VMUpdateEvent implements M.VMUpdateEvent {
  final DateTime timestamp;
  final M.VMRef vm;
  VMUpdateEvent(this.timestamp, this.vm) {
    assert(timestamp != null);
    assert(vm != null);
  }
}

class IsolateStartEvent implements M.IsolateStartEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  IsolateStartEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class IsolateRunnableEvent implements M.IsolateRunnableEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  IsolateRunnableEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class IsolateExitEvent implements M.IsolateExitEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  IsolateExitEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class IsolateUpdateEvent implements M.IsolateUpdateEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  IsolateUpdateEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class IsolateReloadEvent implements M.IsolateReloadEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.ErrorRef error;
  IsolateReloadEvent(this.timestamp, this.isolate, this.error) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(error != null);
  }
}

class ServiceExtensionAddedEvent implements M.ServiceExtensionAddedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final String extensionRPC;
  ServiceExtensionAddedEvent(this.timestamp, this.isolate, this.extensionRPC) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(extensionRPC != null);
  }
}

class DebuggerSettingsUpdateEvent implements M.DebuggerSettingsUpdateEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  DebuggerSettingsUpdateEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class PauseStartEvent implements M.PauseStartEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  PauseStartEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class PauseExitEvent implements M.PauseExitEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  PauseExitEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class PauseBreakpointEvent implements M.PauseBreakpointEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final Iterable<M.Breakpoint> pauseBreakpoints;
  final M.Frame topFrame;
  final bool atAsyncSuspension;
  /// [optional]
  final M.Breakpoint breakpoint;
  PauseBreakpointEvent(this.timestamp, this.isolate,
      Iterable<M.Breakpoint> pauseBreakpoints, this.topFrame,
      this.atAsyncSuspension, [this.breakpoint])
    : pauseBreakpoints = new List.unmodifiable(pauseBreakpoints){
    assert(timestamp != null);
    assert(isolate != null);
    assert(pauseBreakpoints != null);
    assert(topFrame != null);
    assert(atAsyncSuspension != null);
  }
}

class PauseInterruptedEvent implements M.PauseInterruptedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Frame topFrame;
  final bool atAsyncSuspension;
  PauseInterruptedEvent(this.timestamp, this.isolate, this.topFrame,
      this.atAsyncSuspension) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(atAsyncSuspension != null);
  }
}

class PauseExceptionEvent implements M.PauseExceptionEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Frame topFrame;
  final M.InstanceRef exception;
  PauseExceptionEvent(this.timestamp, this.isolate, this.topFrame,
      this.exception) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(topFrame != null);
    assert(exception != null);
  }
}

class ResumeEvent implements M.ResumeEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Frame topFrame;
  ResumeEvent(this.timestamp, this.isolate, this.topFrame) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class BreakpointAddedEvent implements M.BreakpointAddedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Breakpoint breakpoint;
  BreakpointAddedEvent(this.timestamp, this.isolate, this.breakpoint) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(breakpoint != null);
  }
}

class BreakpointResolvedEvent implements M.BreakpointResolvedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Breakpoint breakpoint;
  BreakpointResolvedEvent(this.timestamp, this.isolate, this.breakpoint) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(breakpoint != null);
  }
}

class BreakpointRemovedEvent implements M.BreakpointRemovedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Breakpoint breakpoint;
  BreakpointRemovedEvent(this.timestamp, this.isolate, this.breakpoint) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(breakpoint != null);
  }
}

class InspectEvent implements M.InspectEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.InstanceRef inspectee;
  InspectEvent(this.timestamp, this.isolate, this.inspectee) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(inspectee != null);
  }
}

class NoneEvent implements M.NoneEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  NoneEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class GCEvent implements M.GCEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  GCEvent(this.timestamp, this.isolate) {
    assert(timestamp != null);
    assert(isolate != null);
  }
}

class ExtensionEvent implements M.ExtensionEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final String extensionKind;
  final M.ExtensionData extensionData;
  ExtensionEvent(this.timestamp, this.isolate, this.extensionKind,
      this.extensionData) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(extensionKind != null);
    assert(extensionData != null);
  }
}

class TimelineEventsEvent implements M.TimelineEventsEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final Iterable<M.TimelineEvent> timelineEvents;
  TimelineEventsEvent(this.timestamp, this.isolate,
      Iterable<M.TimelineEvent> timelineEvents)
    : timelineEvents = new List.unmodifiable(timelineEvents){
    assert(timestamp != null);
    assert(isolate != null);
    assert(timelineEvents != null);
  }
}

class ConnectionClosedEvent implements M.ConnectionClosedEvent {
  final DateTime timestamp;
  final String reason;
  ConnectionClosedEvent(this.timestamp, this.reason) {
    assert(timestamp != null);
    assert(reason != null);
  }
}
