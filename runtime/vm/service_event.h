// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SERVICE_EVENT_H_
#define RUNTIME_VM_SERVICE_EVENT_H_

#include "vm/globals.h"
#include "vm/heap.h"

namespace dart {

class ActivationFrame;
class Breakpoint;
class Instance;
class Isolate;
class Object;
class StreamInfo;
class String;
class TimelineEventBlock;

class ServiceEvent {
 public:
  enum EventKind {
    kVMUpdate,  // VM identity information has changed

    kIsolateStart,           // New isolate has started
    kIsolateRunnable,        // Isolate is ready to run
    kIsolateExit,            // Isolate has exited
    kIsolateUpdate,          // Isolate identity information has changed
    kIsolateReload,          // Result of a reload request
    kIsolateSpawn,           // Result of an isolate spawn request
    kServiceExtensionAdded,  // A service extension was registered

    kPauseStart,  // --pause-isolates-on-start
    kPauseExit,   // --pause-isolates-on-exit
    kPauseBreakpoint,
    kPauseInterrupted,
    kPauseException,
    kPausePostRequest,  // isolate is paused after a service request.
    kNone,              // isolate has not been made runnable yet.
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

    kTimelineEvents,

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

  Isolate* isolate() const { return isolate_; }

  // Used by the C embedding api.
  Dart_Port isolate_id() const { return isolate_->main_port(); }

  EventKind kind() const { return kind_; }

  bool IsPause() const {
    switch (kind()) {
      case kPauseStart:
      case kPauseExit:
      case kPauseBreakpoint:
      case kPauseInterrupted:
      case kPauseException:
      case kPausePostRequest:
        return true;
      default:
        return false;
    }
  }

  const char* embedder_kind() const { return embedder_kind_; }

  const char* KindAsCString() const;

  void set_embedder_kind(const char* embedder_kind) {
    embedder_kind_ = embedder_kind;
  }

  const StreamInfo* stream_info() const;
  const char* stream_id() const;

  void set_embedder_stream_id(const char* stream_id) {
    embedder_stream_id_ = stream_id;
  }

  Breakpoint* breakpoint() const { return breakpoint_; }
  void set_breakpoint(Breakpoint* bpt) {
    ASSERT(kind() == kPauseBreakpoint || kind() == kBreakpointAdded ||
           kind() == kBreakpointResolved || kind() == kBreakpointRemoved);
    breakpoint_ = bpt;
  }

  ActivationFrame* top_frame() const { return top_frame_; }
  void set_top_frame(ActivationFrame* frame) {
    ASSERT(kind() == kPauseBreakpoint || kind() == kPauseInterrupted ||
           kind() == kPauseException || kind() == kPausePostRequest ||
           kind() == kResume);
    top_frame_ = frame;
  }

  const String* extension_rpc() const { return extension_rpc_; }
  void set_extension_rpc(const String* extension_rpc) {
    extension_rpc_ = extension_rpc;
  }

  const Object* exception() const { return exception_; }
  void set_exception(const Object* exception) {
    ASSERT(kind_ == kPauseException);
    exception_ = exception;
  }

  const Error* reload_error() const {
    ASSERT(kind_ == kIsolateReload);
    return reload_error_;
  }
  void set_reload_error(const Error* error) {
    ASSERT(kind_ == kIsolateReload);
    reload_error_ = error;
  }

  const String* spawn_token() const {
    ASSERT(kind_ == kIsolateSpawn);
    return spawn_token_;
  }
  void set_spawn_token(const String* error) {
    ASSERT(kind_ == kIsolateSpawn);
    spawn_token_ = error;
  }

  const String* spawn_error() const {
    ASSERT(kind_ == kIsolateSpawn);
    return spawn_error_;
  }
  void set_spawn_error(const String* error) {
    ASSERT(kind_ == kIsolateSpawn);
    spawn_error_ = error;
  }

  bool at_async_jump() const { return at_async_jump_; }
  void set_at_async_jump(bool value) { at_async_jump_ = value; }

  const Object* inspectee() const { return inspectee_; }
  void set_inspectee(const Object* inspectee) {
    ASSERT(kind_ == kInspect);
    inspectee_ = inspectee;
  }

  const Heap::GCStats* gc_stats() const { return gc_stats_; }

  void set_gc_stats(const Heap::GCStats* gc_stats) { gc_stats_ = gc_stats; }

  const uint8_t* bytes() const { return bytes_; }

  intptr_t bytes_length() const { return bytes_length_; }

  void set_bytes(const uint8_t* bytes, intptr_t bytes_length) {
    bytes_ = bytes;
    bytes_length_ = bytes_length;
  }

  void set_log_record(const LogRecord& log_record) { log_record_ = log_record; }

  void set_extension_event(const ExtensionEvent& extension_event) {
    extension_event_ = extension_event;
  }

  void UpdateTimestamp();

  int64_t timestamp() const { return timestamp_; }

  const TimelineEventBlock* timeline_event_block() const {
    return timeline_event_block_;
  }

  void set_timeline_event_block(const TimelineEventBlock* block) {
    ASSERT(kind() == kTimelineEvents);
    timeline_event_block_ = block;
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
  const TimelineEventBlock* timeline_event_block_;
  const String* extension_rpc_;
  const Object* exception_;
  const Error* reload_error_;
  const String* spawn_token_;
  const String* spawn_error_;
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

#endif  // RUNTIME_VM_SERVICE_EVENT_H_
