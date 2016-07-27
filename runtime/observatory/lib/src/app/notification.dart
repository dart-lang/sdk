// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

class ExceptionNotification implements M.ExceptionNotification {
  final Exception exception;
  /// [optional]
  final StackTrace stacktrace;
  ExceptionNotification(this.exception, {this.stacktrace});
}

class EventNotification implements M.EventNotification {
  final M.Event event;
  EventNotification(this.event);
  factory EventNotification.fromServiceEvent(ServiceEvent event) {
    M.Event e;
    switch(event.kind) {
      case ServiceEvent.kVMUpdate:
        e = new VMUpdateEventMock(timestamp: event.timestamp, vm: event.vm);
        break;
      case ServiceEvent.kIsolateStart:
        e = new IsolateStartEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kIsolateRunnable:
        e = new IsolateRunnableEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kIsolateExit:
        e = new IsolateExitEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kIsolateUpdate:
        e = new IsolateUpdateEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kIsolateReload:
        // TODO(bernaschina) add error: realoadError.
        e = new IsolateRealodEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kServiceExtensionAdded:
        e = new ServiceExtensionAddedEventMock(timestamp: event.timestamp,
            isolate: event.isolate, extensionRPC: event.extensionRPC);
        break;
      case ServiceEvent.kPauseStart:
        e = new PauseStartEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kPauseExit:
        e = new PauseExitEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kPauseBreakpoint:
        // TODO(cbernaschina) add pauseBreakpoints.
        e = new PauseBreakpointEventMock(timestamp: event.timestamp,
            isolate: event.isolate, breakpoint: event.breakpoint,
            pauseBreakpoints: const <M.Breakpoint>[],
            topFrame: event.topFrame,
            atAsyncSuspension: event.atAsyncSuspension);
        break;
      case ServiceEvent.kPauseInterrupted:
        e = new PauseInterruptedEventMock(timestamp: event.timestamp,
            isolate: event.isolate, topFrame: event.topFrame,
            atAsyncSuspension: event.atAsyncSuspension);
        break;
      case ServiceEvent.kPauseException:
        // TODO(cbernaschina) add exception.
        e = new PauseExceptionEventMock(timestamp: event.timestamp,
            isolate: event.isolate, topFrame: event.topFrame);
        break;
      case ServiceEvent.kNone:
        e = new NoneEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kResume:
        e = new ResumeEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kBreakpointAdded:
        e = new BreakpointAddedEventMock(timestamp: event.timestamp,
            isolate: event.isolate, breakpoint: event.breakpoint);
        break;
      case ServiceEvent.kBreakpointResolved:
        e = new BreakpointResolvedEventMock(timestamp: event.timestamp,
            isolate: event.isolate, breakpoint: event.breakpoint);
        break;
      case ServiceEvent.kBreakpointRemoved:
        e = new BreakpointRemovedEventMock(timestamp: event.timestamp,
            isolate: event.isolate, breakpoint: event.breakpoint);
        break;
      case ServiceEvent.kGC:
        e = new GCEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kInspect:
       // TODO(cbernaschina) add inspectee: event.inspectee.
        e = new InspectEventMock(timestamp: event.timestamp,
            isolate: event.isolate);
        break;
      case ServiceEvent.kConnectionClosed:
        e = new ConnectionClockedEventMock(timestamp: event.timestamp,
            reason: event.reason);
        break;
      case ServiceEvent.kExtension:
        e = new ExtensionEventMock(timestamp: event.timestamp,
            isolate: event.isolate, extensionKind: event.extensionKind,
            extensionData: event.extensionData);
        break;
    }
    return new EventNotification(e);
  }
}
