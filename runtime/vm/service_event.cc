// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/service_event.h"

#include "vm/debugger.h"
#include "vm/message_handler.h"
#include "vm/service_isolate.h"
#include "vm/timeline.h"

namespace dart {

#ifndef PRODUCT

ServiceEvent::ServiceEvent(EventKind event_kind)
    : ServiceEvent(nullptr, nullptr, event_kind) {}

ServiceEvent::ServiceEvent(IsolateGroup* isolate_group, EventKind event_kind)
    : ServiceEvent(isolate_group, nullptr, event_kind) {}

ServiceEvent::ServiceEvent(Isolate* isolate, EventKind event_kind)
    : ServiceEvent(isolate != nullptr ? isolate->group() : nullptr,
                   isolate,
                   event_kind) {}

ServiceEvent::ServiceEvent(IsolateGroup* isolate_group,
                           Isolate* isolate,
                           EventKind event_kind)
    : isolate_(isolate),
      isolate_group_(isolate_group),
      kind_(event_kind),
      flag_name_(nullptr),
      flag_new_value_(nullptr),
      previous_tag_(nullptr),
      updated_tag_(nullptr),
      embedder_kind_(nullptr),
      embedder_stream_id_(nullptr),
      breakpoint_(nullptr),
      top_frame_(nullptr),
      timeline_event_block_(nullptr),
      extension_rpc_(nullptr),
      exception_(nullptr),
      reload_error_(nullptr),
      spawn_token_(nullptr),
      spawn_error_(nullptr),
      at_async_jump_(false),
      inspectee_(nullptr),
      gc_stats_(nullptr),
      bytes_(nullptr),
      bytes_length_(0),
      timestamp_(OS::GetCurrentTimeMillis()) {
  // We should never generate events for the vm isolate as it is never reported
  // over the service.
  ASSERT(isolate_ != Dart::vm_isolate());

  // VM internal isolates should never post service events. However, the Isolate
  // service object uses a service event to represent the current running state
  // of the isolate, so we need to allow for system isolates to create resume
  // and none events for this purpose. The resume event represents a running
  // isolate and the none event is returned for an isolate that has not yet
  // been marked as runnable (see "pauseEvent" in Isolate::PrintJSON).
  ASSERT(isolate == nullptr || !Isolate::IsVMInternalIsolate(isolate) ||
         (Isolate::IsVMInternalIsolate(isolate) &&
          (event_kind == ServiceEvent::kResume ||
           event_kind == ServiceEvent::kNone ||
           // VM service can print Observatory information to Stdout or Stderr
           // which are embedder streams.
           event_kind == ServiceEvent::kEmbedder ||
           event_kind == ServiceEvent::kCpuSamples)));

  if ((event_kind == ServiceEvent::kPauseStart) ||
      (event_kind == ServiceEvent::kPauseExit)) {
    timestamp_ = isolate->message_handler()->paused_timestamp();
  } else if (event_kind == ServiceEvent::kResume) {
    timestamp_ = isolate->last_resume_timestamp();
  }
  ASSERT(timestamp_ > -1);
}

void ServiceEvent::UpdateTimestamp() {
  timestamp_ = OS::GetCurrentTimeMillis();
}

const char* ServiceEvent::KindAsCString() const {
  switch (kind()) {
    case kVMUpdate:
      return "VMUpdate";
    case kVMFlagUpdate:
      return "VMFlagUpdate";
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
    case kIsolateReload:
      return "IsolateReload";
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
    case kPausePostRequest:
      return "PausePostRequest";
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
    case kBreakpointUpdated:
      return "BreakpointUpdated";
    case kGC:
      return "GC";  // TODO(koda): Change to GarbageCollected.
    case kInspect:
      return "Inspect";
    case kEmbedder:
      return embedder_kind();
    case kLogging:
      return "Logging";
    case kDebuggerSettingsUpdate:
      return "_DebuggerSettingsUpdate";
    case kIllegal:
      return "Illegal";
    case kExtension:
      return "Extension";
    case kTimelineEvents:
      return "TimelineEvents";
    case kTimelineStreamSubscriptionsUpdate:
      return "TimelineStreamSubscriptionsUpdate";
    case kUserTagChanged:
      return "UserTagChanged";
    case kCpuSamples:
      return "CpuSamples";
    default:
      UNREACHABLE();
      return "Unknown";
  }
}

const StreamInfo* ServiceEvent::stream_info() const {
  switch (kind()) {
    case kVMUpdate:
    case kVMFlagUpdate:
      return &Service::vm_stream;

    case kIsolateStart:
    case kIsolateRunnable:
    case kIsolateExit:
    case kIsolateUpdate:
    case kIsolateReload:
    case kServiceExtensionAdded:
      return &Service::isolate_stream;

    case kPauseStart:
    case kPauseExit:
    case kPauseBreakpoint:
    case kPauseInterrupted:
    case kPauseException:
    case kPausePostRequest:
    case kNone:
    case kResume:
    case kBreakpointAdded:
    case kBreakpointResolved:
    case kBreakpointRemoved:
    case kBreakpointUpdated:
    case kInspect:
    case kDebuggerSettingsUpdate:
      return &Service::debug_stream;

    case kGC:
      return &Service::gc_stream;

    case kLogging:
      return &Service::logging_stream;

    case kExtension:
      return &Service::extension_stream;

    case kTimelineEvents:
    case kTimelineStreamSubscriptionsUpdate:
      return &Service::timeline_stream;

    case kEmbedder:
      return nullptr;

    case kCpuSamples:
    case kUserTagChanged:
      return &Service::profiler_stream;

    default:
      UNREACHABLE();
      return nullptr;
  }
}

const char* ServiceEvent::stream_id() const {
  const StreamInfo* stream = stream_info();
  if (stream == nullptr) {
    ASSERT(kind() == kEmbedder);
    return embedder_stream_id_;
  } else {
    return stream->id();
  }
}

void ServiceEvent::PrintJSON(JSONStream* js) const {
  JSONObject jsobj(js);
  PrintJSONHeader(&jsobj);
  if (kind() == kVMFlagUpdate) {
    jsobj.AddProperty("flag", flag_name());
    // For backwards compatibility, "new_value" is also provided.
    jsobj.AddProperty("newValue", flag_new_value());
  }
  if (kind() == kUserTagChanged) {
    jsobj.AddProperty("previousTag", previous_tag());
    jsobj.AddProperty("updatedTag", updated_tag());
  }
  if (kind() == kIsolateReload) {
    if (reload_error_ == nullptr) {
      jsobj.AddProperty("status", "success");
    } else {
      jsobj.AddProperty("status", "failure");
      jsobj.AddProperty("reloadError", *(reload_error()));
    }
  }
  if (kind() == kServiceExtensionAdded) {
    ASSERT(extension_rpc_ != nullptr);
    jsobj.AddProperty("extensionRPC", extension_rpc_->ToCString());
  }
  if (kind() == kPauseBreakpoint) {
    JSONArray jsarr(&jsobj, "pauseBreakpoints");
    // TODO(rmacnak): If we are paused at more than one breakpoint,
    // provide it here.
    if (breakpoint() != nullptr) {
      jsarr.AddValue(breakpoint());
    }
  } else {
    if (breakpoint() != nullptr) {
      jsobj.AddProperty("breakpoint", breakpoint());
    }
  }
  if (kind() == kTimelineEvents) {
    jsobj.AddProperty("timelineEvents", timeline_event_block_);
  }
  if (kind() == kTimelineStreamSubscriptionsUpdate) {
    JSONArray arr(&jsobj, "updatedStreams");
    Timeline::PrintFlagsToJSONArray(&arr);
  }
  if (kind() == kDebuggerSettingsUpdate) {
    JSONObject jssettings(&jsobj, "_debuggerSettings");
    isolate()->debugger()->PrintSettingsToJSONObject(&jssettings);
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (top_frame() != nullptr) {
    JSONObject jsFrame(&jsobj, "topFrame");
    top_frame()->PrintToJSONObject(&jsFrame);
    intptr_t index = 0;  // Avoid ambiguity in call to AddProperty.
    jsFrame.AddProperty("index", index);
  }
#endif
  if (exception() != nullptr) {
    jsobj.AddProperty("exception", *(exception()));
  }
  if (at_async_jump()) {
    jsobj.AddProperty("atAsyncSuspension", true);
  }
  if (inspectee() != nullptr) {
    jsobj.AddProperty("inspectee", *(inspectee()));
  }
  if (gc_stats() != nullptr) {
    jsobj.AddProperty("reason", Heap::GCReasonToString(gc_stats()->reason_));
    jsobj.AddProperty("gcType", Heap::GCTypeToString(gc_stats()->type_));
    isolate_group()->heap()->PrintToJSONObject(Heap::kNew, &jsobj);
    isolate_group()->heap()->PrintToJSONObject(Heap::kOld, &jsobj);
  }
  if (bytes() != nullptr) {
    jsobj.AddPropertyBase64("bytes", bytes(), bytes_length());
  }
  if (kind() == kLogging) {
    JSONObject logRecord(&jsobj, "logRecord");
    logRecord.AddProperty("type", "LogRecord");
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

  if (kind() == kCpuSamples) {
    JSONObject cpu_profile(&jsobj, "cpuSamples");
    cpu_profile_->PrintProfileJSON(&cpu_profile, /*include_code_samples=*/false,
                                   /*is_event=*/true);
  }
}

void ServiceEvent::PrintJSONHeader(JSONObject* jsobj) const {
  ASSERT(jsobj != nullptr);
  jsobj->AddProperty("type", "Event");
  jsobj->AddProperty("kind", KindAsCString());
  if (kind() == kExtension) {
    ASSERT(extension_event_.event_kind != nullptr);
    jsobj->AddProperty("extensionKind",
                       extension_event_.event_kind->ToCString());
  }
  if (isolate() == nullptr) {
    jsobj->AddPropertyVM("vm");
  } else {
    jsobj->AddProperty("isolate", isolate());
  }
  ASSERT(timestamp_ != -1);
  jsobj->AddPropertyTimeMillis("timestamp", timestamp_);
}

#endif  // !PRODUCT

}  // namespace dart
