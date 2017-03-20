// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class VMUpdateEventMock implements M.VMUpdateEvent {
  final M.VMRef vm;
  final DateTime timestamp;
  const VMUpdateEventMock({this.timestamp, this.vm});
}
class IsolateStartEventMock implements M.IsolateStartEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const IsolateStartEventMock({this.timestamp, this.isolate});
}
class IsolateRunnableEventMock implements M.IsolateRunnableEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const IsolateRunnableEventMock({this.timestamp, this.isolate});
}
class IsolateExitEventMock implements M.IsolateExitEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const IsolateExitEventMock({this.timestamp, this.isolate});
}
class IsolateUpdateEventMock implements M.IsolateUpdateEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const IsolateUpdateEventMock({this.timestamp, this.isolate});
}
class IsolateRealodEventMock implements M.IsolateReloadEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Error error;
  const IsolateRealodEventMock({this.timestamp, this.isolate, this.error});
}
class ServiceExtensionAddedEventMock implements M.ServiceExtensionAddedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final String extensionRPC;
  const ServiceExtensionAddedEventMock({this.extensionRPC, this.isolate,
      this.timestamp});
}
class DebuggerSettingsUpdateEventMock implements M.PauseStartEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const DebuggerSettingsUpdateEventMock({this.isolate, this.timestamp});
}
class PauseStartEventMock implements M.PauseStartEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const PauseStartEventMock({this.isolate, this.timestamp});
}
class PauseExitEventMock implements M.PauseExitEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const PauseExitEventMock({this.isolate, this.timestamp});
}
class PauseBreakpointEventMock implements M.PauseBreakpointEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Breakpoint breakpoint;
  final List<M.Breakpoint> pauseBreakpoints;
  final M.Frame topFrame;
  final bool atAsyncSuspension;
  const PauseBreakpointEventMock({this.timestamp, this.isolate, this.breakpoint,
      this.pauseBreakpoints, this.topFrame, this.atAsyncSuspension});
}
class PauseInterruptedEventMock implements M.PauseInterruptedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Frame topFrame;
  final bool atAsyncSuspension;
  const PauseInterruptedEventMock({this.timestamp, this.isolate, this.topFrame,
      this.atAsyncSuspension});
}
class PauseExceptionEventMock implements M.PauseExceptionEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Frame topFrame;
  final M.InstanceRef exception;
  const PauseExceptionEventMock({this.timestamp, this.isolate, this.topFrame,
      this.exception});
}
class ResumeEventMock implements M.ResumeEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Frame topFrame;
  const ResumeEventMock({this.timestamp, this.isolate, this.topFrame});
}
class BreakpointAddedEventMock implements M.BreakpointAddedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Breakpoint breakpoint;
  const BreakpointAddedEventMock({this.timestamp, this.isolate,
      this.breakpoint});
}
class BreakpointResolvedEventMock implements M.BreakpointResolvedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Breakpoint breakpoint;
  const BreakpointResolvedEventMock({this.timestamp, this.isolate,
      this.breakpoint});
}
class BreakpointRemovedEventMock implements M.BreakpointRemovedEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.Breakpoint breakpoint;
  const BreakpointRemovedEventMock({this.timestamp, this.isolate,
      this.breakpoint});
}
class InspectEventMock implements M.InspectEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final M.InstanceRef inspectee;
  const InspectEventMock({this.timestamp, this.isolate, this.inspectee});
}
class NoneEventMock implements M.NoneEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const NoneEventMock({this.timestamp, this.isolate});
}
class GCEventMock implements M.GCEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  const GCEventMock({this.timestamp, this.isolate});
}
class ExtensionEventMock implements M.ExtensionEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final String extensionKind;
  final M.ExtensionData extensionData;
  const ExtensionEventMock({this.timestamp, this.isolate, this.extensionKind,
      this.extensionData});
}
class TimelineEventsEventMock implements M.TimelineEventsEvent {
  final DateTime timestamp;
  final M.IsolateRef isolate;
  final List<M.TimelineEvent> timelineEvents;
  const TimelineEventsEventMock({this.timestamp, this.isolate,
      this.timelineEvents});
}
class ConnectionClockedEventMock implements M.ConnectionClosedEvent {
  final DateTime timestamp;
  final String reason;
  const ConnectionClockedEventMock({this.timestamp, this.reason});
}
