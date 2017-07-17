// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service.dart' as S;

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
  PauseBreakpointEvent(
      this.timestamp,
      this.isolate,
      Iterable<M.Breakpoint> pauseBreakpoints,
      this.topFrame,
      this.atAsyncSuspension,
      [this.breakpoint])
      : pauseBreakpoints = new List.unmodifiable(pauseBreakpoints) {
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
  PauseInterruptedEvent(
      this.timestamp, this.isolate, this.topFrame, this.atAsyncSuspension) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(atAsyncSuspension != null);
  }
}

class PausePostRequestEvent implements M.PausePostRequestEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Frame topFrame;
  final bool atAsyncSuspension;
  PausePostRequestEvent(
      this.timestamp, this.isolate, this.topFrame, this.atAsyncSuspension) {
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
  PauseExceptionEvent(
      this.timestamp, this.isolate, this.topFrame, this.exception) {
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

class LoggingEvent implements M.LoggingEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final Map logRecord;
  LoggingEvent(this.timestamp, this.isolate, this.logRecord) {
    assert(timestamp != null);
    assert(isolate != null);
    assert(logRecord != null);
  }
}

class ExtensionEvent implements M.ExtensionEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final String extensionKind;
  final M.ExtensionData extensionData;
  ExtensionEvent(
      this.timestamp, this.isolate, this.extensionKind, this.extensionData) {
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
  TimelineEventsEvent(
      this.timestamp, this.isolate, Iterable<M.TimelineEvent> timelineEvents)
      : timelineEvents = new List.unmodifiable(timelineEvents) {
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

class ServiceRegisteredEvent implements M.ServiceRegisteredEvent {
  final DateTime timestamp;
  final String service;
  final String method;
  final String alias;
  ServiceRegisteredEvent(
      this.timestamp, this.service, this.method, this.alias) {
    assert(timestamp != null);
    assert(service != null);
    assert(method != null);
    assert(alias != null);
  }
}

class ServiceUnregisteredEvent implements M.ServiceUnregisteredEvent {
  final DateTime timestamp;
  final String service;
  final String method;
  ServiceUnregisteredEvent(this.timestamp, this.service, this.method) {
    assert(timestamp != null);
    assert(service != null);
    assert(method != null);
  }
}

M.Event createEventFromServiceEvent(S.ServiceEvent event) {
  switch (event.kind) {
    case S.ServiceEvent.kVMUpdate:
      return new VMUpdateEvent(event.timestamp, event.vm);
    case S.ServiceEvent.kIsolateStart:
      return new IsolateStartEvent(event.timestamp, event.isolate);
    case S.ServiceEvent.kIsolateRunnable:
      return new IsolateRunnableEvent(event.timestamp, event.isolate);
    case S.ServiceEvent.kIsolateUpdate:
      return new IsolateUpdateEvent(event.timestamp, event.isolate);
    case S.ServiceEvent.kIsolateReload:
      return new IsolateReloadEvent(
          event.timestamp, event.isolate, event.error);
    case S.ServiceEvent.kIsolateExit:
      return new IsolateExitEvent(event.timestamp, event.isolate);
    case S.ServiceEvent.kBreakpointAdded:
      return new BreakpointAddedEvent(
          event.timestamp, event.isolate, event.breakpoint);
    case S.ServiceEvent.kBreakpointResolved:
      return new BreakpointResolvedEvent(
          event.timestamp, event.isolate, event.breakpoint);
    case S.ServiceEvent.kBreakpointRemoved:
      return new BreakpointRemovedEvent(
          event.timestamp, event.isolate, event.breakpoint);
    case S.ServiceEvent.kDebuggerSettingsUpdate:
      return new DebuggerSettingsUpdateEvent(event.timestamp, event.isolate);
    case S.ServiceEvent.kResume:
      return new ResumeEvent(event.timestamp, event.isolate, event.topFrame);
    case S.ServiceEvent.kPauseStart:
      return new PauseStartEvent(event.timestamp, event.isolate);
    case S.ServiceEvent.kPauseExit:
      return new PauseExitEvent(event.timestamp, event.isolate);
    case S.ServiceEvent.kPausePostRequest:
      return new PausePostRequestEvent(event.timestamp, event.isolate,
          event.topFrame, event.atAsyncSuspension);
    case S.ServiceEvent.kPauseBreakpoint:
      return new PauseBreakpointEvent(
          event.timestamp,
          event.isolate,
          event.pauseBreakpoints,
          event.topFrame,
          event.atAsyncSuspension,
          event.breakpoint);
    case S.Isolate.kLoggingStream:
      return new LoggingEvent(event.timestamp, event.isolate, event.logRecord);
    case S.ServiceEvent.kPauseInterrupted:
      return new PauseInterruptedEvent(event.timestamp, event.isolate,
          event.topFrame, event.atAsyncSuspension);
    case S.ServiceEvent.kPauseException:
      return new PauseExceptionEvent(
          event.timestamp, event.isolate, event.topFrame, event.exception);
    case S.ServiceEvent.kInspect:
      return new InspectEvent(event.timestamp, event.isolate, event.inspectee);
    case S.ServiceEvent.kGC:
      return new GCEvent(event.timestamp, event.isolate);
    case S.ServiceEvent.kServiceRegistered:
      return new ServiceRegisteredEvent(
          event.timestamp, event.service, event.method, event.alias);
    case S.ServiceEvent.kServiceUnregistered:
      return new ServiceUnregisteredEvent(
          event.timestamp, event.service, event.method);
    case S.ServiceEvent.kNone:
      return new NoneEvent(event.timestamp, event.isolate);
    default:
      // Ignore unrecognized events.
      Logger.root.severe('Unrecognized event: $event');
      return null;
  }
}
