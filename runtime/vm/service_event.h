// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SERVICE_EVENT_H_
#define VM_SERVICE_EVENT_H_

#include "vm/debugger.h"

class DebuggerEvent;

namespace dart {

class ServiceEvent {
 public:
  enum EventType {
    kIsolateStart,       // New isolate has started
    kIsolateExit,        // Isolate has exited
    kIsolateUpdate,      // Isolate identity information has changed

    kPauseStart,         // --pause-isolates-on-start
    kPauseExit,          // --pause-isolates-on-exit
    kPauseBreakpoint,
    kPauseInterrupted,
    kPauseException,
    kResume,
    kBreakpointAdded,
    kBreakpointResolved,
    kBreakpointRemoved,
    kInspect,
    kDebuggerSettingsUpdate,

    kGC,

    kIllegal,
  };

  ServiceEvent(Isolate* isolate, EventType event_type)
      : isolate_(isolate),
        type_(event_type),
        breakpoint_(NULL),
        top_frame_(NULL),
        exception_(NULL),
        inspectee_(NULL),
        gc_stats_(NULL) {}

  explicit ServiceEvent(const DebuggerEvent* debugger_event);

  Isolate* isolate() const { return isolate_; }

  EventType type() const { return type_; }

  const char* stream_id() const;

  Breakpoint* breakpoint() const {
    return breakpoint_;
  }
  void set_breakpoint(Breakpoint* bpt) {
    ASSERT(type() == kPauseBreakpoint ||
           type() == kBreakpointAdded ||
           type() == kBreakpointResolved ||
           type() == kBreakpointRemoved);
    breakpoint_ = bpt;
  }

  ActivationFrame* top_frame() const {
    return top_frame_;
  }
  void set_top_frame(ActivationFrame* frame) {
    ASSERT(type() == kPauseBreakpoint ||
           type() == kPauseInterrupted ||
           type() == kPauseException ||
           type() == kResume);
    top_frame_ = frame;
  }

  const Object* exception() const {
    return exception_;
  }
  void set_exception(const Object* exception) {
    ASSERT(type_ == kPauseException);
    exception_ = exception;
  }

  const Object* inspectee() const {
    return inspectee_;
  }
  void set_inspectee(const Object* inspectee) {
    ASSERT(type_ == kInspect);
    inspectee_ = inspectee;
  }

  const Heap::GCStats* gc_stats() const {
    return gc_stats_;
  }

  void set_gc_stats(const Heap::GCStats* gc_stats) {
    gc_stats_ = gc_stats;
  }

  void PrintJSON(JSONStream* js) const;

  static const char* EventTypeToCString(EventType type);

 private:
  Isolate* isolate_;
  EventType type_;
  Breakpoint* breakpoint_;
  ActivationFrame* top_frame_;
  const Object* exception_;
  const Object* inspectee_;
  const Heap::GCStats* gc_stats_;
};

}  // namespace dart

#endif  // VM_SERVICE_EVENT_H_
