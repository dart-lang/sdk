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
  enum EventKind {
    kVMUpdate,           // VM identity information has changed

    kIsolateStart,       // New isolate has started
    kIsolateRunnable,    // Isolate is ready to run
    kIsolateExit,        // Isolate has exited
    kIsolateUpdate,      // Isolate identity information has changed

    kServiceExtensionAdded,  // A service extension was registered

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

    kEmbedder,

    kLogging,

    kExtension,

    kIllegal,
  };

  struct LogRecord {
    int64_t sequence_number;
    int64_t timestamp;
    intptr_t level;
    const String* name;
    const String* message;
    const Instance* zone;
    const Object* error;
    const Instance* stack_trace;
  };

  struct ExtensionEvent {
    const String* event_kind;
    const String* event_data;
  };

  ServiceEvent(Isolate* isolate, EventKind event_kind);

  explicit ServiceEvent(const DebuggerEvent* debugger_event);

  Isolate* isolate() const { return isolate_; }

  EventKind kind() const { return kind_; }

  const char* embedder_kind() const { return embedder_kind_; }

  const char* KindAsCString() const;

  void set_embedder_kind(const char* embedder_kind) {
    embedder_kind_ = embedder_kind;
  }

  const char* stream_id() const;

  void set_embedder_stream_id(const char* stream_id) {
    embedder_stream_id_ = stream_id;
  }

  Breakpoint* breakpoint() const {
    return breakpoint_;
  }
  void set_breakpoint(Breakpoint* bpt) {
    ASSERT(kind() == kPauseBreakpoint ||
           kind() == kBreakpointAdded ||
           kind() == kBreakpointResolved ||
           kind() == kBreakpointRemoved);
    breakpoint_ = bpt;
  }

  ActivationFrame* top_frame() const {
    return top_frame_;
  }
  void set_top_frame(ActivationFrame* frame) {
    ASSERT(kind() == kPauseBreakpoint ||
           kind() == kPauseInterrupted ||
           kind() == kPauseException ||
           kind() == kResume);
    top_frame_ = frame;
  }

  const String* extension_rpc() const {
    return extension_rpc_;
  }
  void set_extension_rpc(const String* extension_rpc) {
    extension_rpc_ = extension_rpc;
  }

  const Object* exception() const {
    return exception_;
  }
  void set_exception(const Object* exception) {
    ASSERT(kind_ == kPauseException);
    exception_ = exception;
  }

  const Object* async_continuation() const {
    return async_continuation_;
  }
  void set_async_continuation(const Object* closure) {
    ASSERT(kind_ == kPauseBreakpoint);
    async_continuation_ = closure;
  }

  bool at_async_jump() const {
    return at_async_jump_;
  }
  void set_at_async_jump(bool value) {
    at_async_jump_ = value;
  }

  const Object* inspectee() const {
    return inspectee_;
  }
  void set_inspectee(const Object* inspectee) {
    ASSERT(kind_ == kInspect);
    inspectee_ = inspectee;
  }

  const Heap::GCStats* gc_stats() const {
    return gc_stats_;
  }

  void set_gc_stats(const Heap::GCStats* gc_stats) {
    gc_stats_ = gc_stats;
  }

  const uint8_t* bytes() const {
    return bytes_;
  }

  intptr_t bytes_length() const {
    return bytes_length_;
  }

  void set_bytes(const uint8_t* bytes, intptr_t bytes_length) {
    bytes_ = bytes;
    bytes_length_ = bytes_length;
  }

  void set_log_record(const LogRecord& log_record) {
    log_record_ = log_record;
  }

  void set_extension_event(const ExtensionEvent& extension_event) {
    extension_event_ = extension_event;
  }

  int64_t timestamp() const {
    return timestamp_;
  }

  void PrintJSON(JSONStream* js) const;

  void PrintJSONHeader(JSONObject* jsobj) const;

 private:
  Isolate* isolate_;
  EventKind kind_;
  const char* embedder_kind_;
  const char* embedder_stream_id_;
  Breakpoint* breakpoint_;
  ActivationFrame* top_frame_;
  const String* extension_rpc_;
  const Object* exception_;
  const Object* async_continuation_;
  bool at_async_jump_;
  const Object* inspectee_;
  const Heap::GCStats* gc_stats_;
  const uint8_t* bytes_;
  intptr_t bytes_length_;
  LogRecord log_record_;
  ExtensionEvent extension_event_;
  int64_t timestamp_;
};

}  // namespace dart

#endif  // VM_SERVICE_EVENT_H_
