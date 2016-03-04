// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/service_event.h"

#include "vm/message_handler.h"

namespace dart {

#ifndef PRODUCT

// Translate from the legacy DebugEvent to a ServiceEvent.
static ServiceEvent::EventKind TranslateEventKind(
    DebuggerEvent::EventType kind) {
    switch (kind) {
      case DebuggerEvent::kIsolateCreated:
        return ServiceEvent::kIsolateStart;

      case DebuggerEvent::kIsolateShutdown:
        return ServiceEvent::kIsolateExit;

      case DebuggerEvent::kBreakpointReached:
        return ServiceEvent::kPauseBreakpoint;

      case DebuggerEvent::kIsolateInterrupted:
        return ServiceEvent::kPauseInterrupted;

      case DebuggerEvent::kExceptionThrown:
        return ServiceEvent::kPauseException;
      default:
        UNREACHABLE();
        return ServiceEvent::kIllegal;
    }
}


ServiceEvent::ServiceEvent(Isolate* isolate, EventKind event_kind)
    : isolate_(isolate),
      kind_(event_kind),
      embedder_kind_(NULL),
      embedder_stream_id_(NULL),
      breakpoint_(NULL),
      top_frame_(NULL),
      timeline_event_block_(NULL),
      extension_rpc_(NULL),
      exception_(NULL),
      at_async_jump_(false),
      inspectee_(NULL),
      gc_stats_(NULL),
      bytes_(NULL),
      bytes_length_(0),
      timestamp_(OS::GetCurrentTimeMillis()) {
  if ((event_kind == ServiceEvent::kPauseStart) ||
      (event_kind == ServiceEvent::kPauseExit)) {
    timestamp_ = isolate->message_handler()->paused_timestamp();
  } else if (event_kind == ServiceEvent::kResume) {
    timestamp_ = isolate->last_resume_timestamp();
  }
}


ServiceEvent::ServiceEvent(const DebuggerEvent* debugger_event)
    : isolate_(debugger_event->isolate()),
      kind_(TranslateEventKind(debugger_event->type())),
      breakpoint_(NULL),
      top_frame_(NULL),
      timeline_event_block_(NULL),
      extension_rpc_(NULL),
      exception_(NULL),
      at_async_jump_(false),
      inspectee_(NULL),
      gc_stats_(NULL),
      bytes_(NULL),
      bytes_length_(0),
      timestamp_(OS::GetCurrentTimeMillis()) {
  DebuggerEvent::EventType type = debugger_event->type();
  if (type == DebuggerEvent::kBreakpointReached) {
    set_breakpoint(debugger_event->breakpoint());
    set_at_async_jump(debugger_event->at_async_jump());
  }
  if (type == DebuggerEvent::kExceptionThrown) {
    set_exception(debugger_event->exception());
  }
  if (type == DebuggerEvent::kBreakpointReached ||
      type == DebuggerEvent::kIsolateInterrupted ||
      type == DebuggerEvent::kExceptionThrown) {
    set_top_frame(debugger_event->top_frame());
  }
  if (debugger_event->timestamp() != -1) {
    timestamp_ = debugger_event->timestamp();
  }
}


const char* ServiceEvent::KindAsCString() const {
  switch (kind()) {
    case kVMUpdate:
      return "VMUpdate";
    case kIsolateStart:
      return "IsolateStart";
    case kIsolateRunnable:
      return "IsolateRunnable";
    case kIsolateExit:
      return "IsolateExit";
    case kIsolateUpdate:
      return "IsolateUpdate";
    case kServiceExtensionAdded:
      return "ServiceExtensionAdded";
    case kPauseStart:
      return "PauseStart";
    case kPauseExit:
      return "PauseExit";
    case kPauseBreakpoint:
      return "PauseBreakpoint";
    case kPauseInterrupted:
      return "PauseInterrupted";
    case kPauseException:
      return "PauseException";
    case kNone:
      return "None";
    case kResume:
      return "Resume";
    case kBreakpointAdded:
      return "BreakpointAdded";
    case kBreakpointResolved:
      return "BreakpointResolved";
    case kBreakpointRemoved:
      return "BreakpointRemoved";
    case kGC:
      return "GC";  // TODO(koda): Change to GarbageCollected.
    case kInspect:
      return "Inspect";
    case kEmbedder:
      return embedder_kind();
    case kLogging:
      return "_Logging";
    case kDebuggerSettingsUpdate:
      return "_DebuggerSettingsUpdate";
    case kIllegal:
      return "Illegal";
    case kExtension:
      return "Extension";
    case kTimelineEvents:
      return "TimelineEvents";
    default:
      UNREACHABLE();
      return "Unknown";
  }
}


const char* ServiceEvent::stream_id() const {
  switch (kind()) {
    case kVMUpdate:
      return Service::vm_stream.id();

    case kIsolateStart:
    case kIsolateRunnable:
    case kIsolateExit:
    case kIsolateUpdate:
    case kServiceExtensionAdded:
      return Service::isolate_stream.id();

    case kPauseStart:
    case kPauseExit:
    case kPauseBreakpoint:
    case kPauseInterrupted:
    case kPauseException:
    case kNone:
    case kResume:
    case kBreakpointAdded:
    case kBreakpointResolved:
    case kBreakpointRemoved:
    case kInspect:
    case kDebuggerSettingsUpdate:
      return Service::debug_stream.id();

    case kGC:
      return Service::gc_stream.id();

    case kEmbedder:
      return embedder_stream_id_;

    case kLogging:
      return Service::logging_stream.id();

    case kExtension:
      return Service::extension_stream.id();

    case kTimelineEvents:
      return Service::timeline_stream.id();

    default:
      UNREACHABLE();
      return NULL;
  }
}


void ServiceEvent::PrintJSON(JSONStream* js) const {
  JSONObject jsobj(js);
  PrintJSONHeader(&jsobj);
  if (kind() == kServiceExtensionAdded) {
    ASSERT(extension_rpc_ != NULL);
    jsobj.AddProperty("extensionRPC", extension_rpc_->ToCString());
  }
  if (kind() == kPauseBreakpoint) {
    JSONArray jsarr(&jsobj, "pauseBreakpoints");
    // TODO(rmacnak): If we are paused at more than one breakpoint,
    // provide it here.
    if (breakpoint() != NULL) {
      jsarr.AddValue(breakpoint());
    }
  } else {
    if (breakpoint() != NULL) {
      jsobj.AddProperty("breakpoint", breakpoint());
    }
  }
  if (kind() == kTimelineEvents) {
    jsobj.AddProperty("timelineEvents", timeline_event_block_);
  }
  if (kind() == kDebuggerSettingsUpdate) {
    JSONObject jssettings(&jsobj, "_debuggerSettings");
    isolate()->debugger()->PrintSettingsToJSONObject(&jssettings);
  }
  if ((top_frame() != NULL) && Isolate::Current()->compilation_allowed()) {
    JSONObject jsFrame(&jsobj, "topFrame");
    top_frame()->PrintToJSONObject(&jsFrame);
    intptr_t index = 0;  // Avoid ambiguity in call to AddProperty.
    jsFrame.AddProperty("index", index);
  }
  if (exception() != NULL) {
    jsobj.AddProperty("exception", *(exception()));
  }
  if (at_async_jump()) {
    jsobj.AddProperty("atAsyncSuspension", true);
  }
  if (inspectee() != NULL) {
    jsobj.AddProperty("inspectee", *(inspectee()));
  }
  if (gc_stats() != NULL) {
    jsobj.AddProperty("reason", Heap::GCReasonToString(gc_stats()->reason_));
    isolate()->heap()->PrintToJSONObject(Heap::kNew, &jsobj);
    isolate()->heap()->PrintToJSONObject(Heap::kOld, &jsobj);
  }
  if (bytes() != NULL) {
    jsobj.AddPropertyBase64("bytes", bytes(), bytes_length());
  }
  if (kind() == kLogging) {
    JSONObject logRecord(&jsobj, "logRecord");
    logRecord.AddProperty64("sequenceNumber", log_record_.sequence_number);
    logRecord.AddPropertyTimeMillis("time", log_record_.timestamp);
    logRecord.AddProperty64("level", log_record_.level);
    logRecord.AddProperty("loggerName", *(log_record_.name));
    logRecord.AddProperty("message", *(log_record_.message));
    logRecord.AddProperty("zone", *(log_record_.zone));
    logRecord.AddProperty("error", *(log_record_.error));
    logRecord.AddProperty("stackTrace", *(log_record_.stack_trace));
  }
  if (kind() == kExtension) {
    js->AppendSerializedObject("extensionData",
                               extension_event_.event_data->ToCString());
  }
}


void ServiceEvent::PrintJSONHeader(JSONObject* jsobj) const {
  ASSERT(jsobj != NULL);
  jsobj->AddProperty("type", "Event");
  jsobj->AddProperty("kind", KindAsCString());
  if (kind() == kExtension) {
    ASSERT(extension_event_.event_kind != NULL);
    jsobj->AddProperty("extensionKind",
                       extension_event_.event_kind->ToCString());
  }
  if (isolate() == NULL) {
    jsobj->AddPropertyVM("vm");
  } else {
    jsobj->AddProperty("isolate", isolate());
  }
  ASSERT(timestamp_ != -1);
  jsobj->AddPropertyTimeMillis("timestamp", timestamp_);
}

#endif  // !PRODUCT

}  // namespace dart
