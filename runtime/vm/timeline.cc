// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#ifndef PRODUCT

#include "vm/timeline.h"

#include <errno.h>
#include <fcntl.h>
#include <cstdlib>

#include "vm/atomic.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/service_event.h"
#include "vm/thread.h"

namespace dart {

DEFINE_FLAG(bool, complete_timeline, false, "Record the complete timeline");
DEFINE_FLAG(bool, startup_timeline, false, "Record the startup timeline");
DEFINE_FLAG(
    bool,
    systrace_timeline,
    false,
    "Record the timeline to the platform's tracing service if there is one");
DEFINE_FLAG(bool, trace_timeline, false, "Trace timeline backend");
DEFINE_FLAG(bool,
            trace_timeline_analysis,
            false,
            "Trace timeline analysis backend");
DEFINE_FLAG(bool,
            timing,
            false,
            "Dump isolate timing information from timeline.");
DEFINE_FLAG(charp,
            timeline_dir,
            NULL,
            "Enable all timeline trace streams and output VM global trace "
            "into specified directory.");
DEFINE_FLAG(charp,
            timeline_streams,
            NULL,
            "Comma separated list of timeline streams to record. "
            "Valid values: all, API, Compiler, Dart, Debugger, Embedder, "
            "GC, Isolate, and VM.");
DEFINE_FLAG(charp,
            timeline_recorder,
            "ring",
            "Select the timeline recorder used. "
            "Valid values: ring, endless, startup, and systrace.")

// Implementation notes:
//
// Writing events:
// |TimelineEvent|s are written into |TimelineEventBlock|s. Each |Thread| caches
// a |TimelineEventBlock| object so that it can write events without
// synchronizing with other threads in the system. Even though the |Thread| owns
// the |TimelineEventBlock| the block may need to be reclaimed by the reporting
// system. To support that, a |Thread| must hold its |timeline_block_lock_|
// when operating on the |TimelineEventBlock|. This lock will only ever be
// busy if blocks are being reclaimed by the reporting system.
//
// Reporting:
// When requested, the timeline is serialized in the trace-event format
// (https://goo.gl/hDZw5M). The request can be for a VM-wide timeline or an
// isolate specific timeline. In both cases it may be that a thread has
// a |TimelineEventBlock| cached in TLS partially filled with events. In order
// to report a complete timeline the cached |TimelineEventBlock|s need to be
// reclaimed.
//
// Reclaiming open |TimelineEventBlock|s from threads:
//
// Each |Thread| can have one |TimelineEventBlock| cached in it.
//
// To reclaim blocks, we iterate over all threads and remove the cached
// |TimelineEventBlock| from each thread. This is safe because we hold the
// |Thread|'s |timeline_block_lock_| meaning the block can't be being modified.
//
// Locking notes:
// The following locks are used by the timeline system:
// - |TimelineEventRecorder::lock_| This lock is held whenever a
// |TimelineEventBlock| is being requested or reclaimed.
// - |Thread::timeline_block_lock_| This lock is held whenever a |Thread|'s
// cached block is being operated on.
// - |Thread::thread_list_lock_| This lock is held when iterating over
// |Thread|s.
//
// Locks must always be taken in the following order:
//   |Thread::thread_list_lock_|
//     |Thread::timeline_block_lock_|
//       |TimelineEventRecorder::lock_|
//

static TimelineEventRecorder* CreateTimelineRecorder() {
  // Some flags require that we use the endless recorder.
  const bool use_endless_recorder =
      (FLAG_timeline_dir != NULL) || FLAG_timing || FLAG_complete_timeline;

  const bool use_startup_recorder = FLAG_startup_timeline;
  const bool use_systrace_recorder = FLAG_systrace_timeline;

  const char* flag = FLAG_timeline_recorder;

  if (use_systrace_recorder || (flag != NULL)) {
    if (use_systrace_recorder || (strcmp("systrace", flag) == 0)) {
      if (FLAG_trace_timeline) {
        THR_Print("Using the Systrace timeline recorder.\n");
      }
      return TimelineEventPlatformRecorder::CreatePlatformRecorder();
    }
  }

  if (use_endless_recorder || (flag != NULL)) {
    if (use_endless_recorder || (strcmp("endless", flag) == 0)) {
      if (FLAG_trace_timeline) {
        THR_Print("Using the endless timeline recorder.\n");
      }
      return new TimelineEventEndlessRecorder();
    }
  }

  if (use_startup_recorder || (flag != NULL)) {
    if (use_startup_recorder || (strcmp("startup", flag) == 0)) {
      if (FLAG_trace_timeline) {
        THR_Print("Using the startup recorder.\n");
      }
      return new TimelineEventStartupRecorder();
    }
  }

  if (FLAG_trace_timeline) {
    THR_Print("Using the ring timeline recorder.\n");
  }

  // Always fall back to the ring recorder.
  return new TimelineEventRingRecorder();
}

// Returns a caller freed array of stream names in FLAG_timeline_streams.
static MallocGrowableArray<char*>* GetEnabledByDefaultTimelineStreams() {
  MallocGrowableArray<char*>* result = new MallocGrowableArray<char*>();
  if (FLAG_timeline_streams == NULL) {
    // Nothing set.
    return result;
  }
  char* save_ptr;  // Needed for strtok_r.
  // strtok modifies arg 1 so we make a copy of it.
  char* streams = strdup(FLAG_timeline_streams);
  char* token = strtok_r(streams, ",", &save_ptr);
  while (token != NULL) {
    result->Add(strdup(token));
    token = strtok_r(NULL, ",", &save_ptr);
  }
  free(streams);
  return result;
}

// Frees the result of |GetEnabledByDefaultTimelineStreams|.
static void FreeEnabledByDefaultTimelineStreams(
    MallocGrowableArray<char*>* streams) {
  if (streams == NULL) {
    return;
  }
  for (intptr_t i = 0; i < streams->length(); i++) {
    free((*streams)[i]);
  }
  delete streams;
}

// Returns true if |streams| contains |stream| or "all". Not case sensitive.
static bool HasStream(MallocGrowableArray<char*>* streams, const char* stream) {
  if ((FLAG_timeline_dir != NULL) || FLAG_timing || FLAG_complete_timeline ||
      FLAG_startup_timeline) {
    return true;
  }
  for (intptr_t i = 0; i < streams->length(); i++) {
    const char* checked_stream = (*streams)[i];
    if ((strstr(checked_stream, "all") != NULL) ||
        (strstr(checked_stream, stream) != NULL)) {
      return true;
    }
  }
  return false;
}

void Timeline::InitOnce() {
  ASSERT(recorder_ == NULL);
  recorder_ = CreateTimelineRecorder();
  ASSERT(recorder_ != NULL);
  enabled_streams_ = GetEnabledByDefaultTimelineStreams();
// Global overrides.
#define TIMELINE_STREAM_FLAG_DEFAULT(name, not_used)                           \
  stream_##name##_.Init(#name, HasStream(enabled_streams_, #name));
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_FLAG_DEFAULT)
#undef TIMELINE_STREAM_FLAG_DEFAULT

  if (Timeline::stream_Embedder_.enabled() &&
      (Timeline::get_start_recording_cb() != NULL)) {
    Timeline::get_start_recording_cb()();
  }
}

void Timeline::StreamStateChange(const char* stream_name,
                                 bool prev,
                                 bool curr) {
  if (prev == curr) {
    return;
  }
  if (strcmp(stream_name, "Embedder") == 0) {
    if (curr && (Timeline::get_start_recording_cb() != NULL)) {
      Timeline::get_start_recording_cb()();
    } else if (!curr && (Timeline::get_stop_recording_cb() != NULL)) {
      Timeline::get_stop_recording_cb()();
    }
  }
}

void Timeline::Shutdown() {
  ASSERT(recorder_ != NULL);

  if (Timeline::stream_Embedder_.enabled() &&
      (Timeline::get_stop_recording_cb() != NULL)) {
    Timeline::get_stop_recording_cb()();
  }

  if (FLAG_timeline_dir != NULL) {
    recorder_->WriteTo(FLAG_timeline_dir);
  }

// Disable global streams.
#define TIMELINE_STREAM_DISABLE(name, not_used)                                \
  Timeline::stream_##name##_.set_enabled(false);
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_DISABLE)
#undef TIMELINE_STREAM_DISABLE
  delete recorder_;
  recorder_ = NULL;
  if (enabled_streams_ != NULL) {
    FreeEnabledByDefaultTimelineStreams(enabled_streams_);
    enabled_streams_ = NULL;
  }
}

TimelineEventRecorder* Timeline::recorder() {
  return recorder_;
}

void Timeline::ReclaimCachedBlocksFromThreads() {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return;
  }

  // Iterate over threads.
  OSThreadIterator it;
  while (it.HasNext()) {
    OSThread* thread = it.Next();
    MutexLocker ml(thread->timeline_block_lock());
    // Grab block and clear it.
    TimelineEventBlock* block = thread->timeline_block();
    thread->set_timeline_block(NULL);
    // TODO(johnmccutchan): Consider dropping the timeline_block_lock here
    // if we can do it everywhere. This would simplify the lock ordering
    // requirements.
    recorder->FinishBlock(block);
  }
}

void Timeline::PrintFlagsToJSON(JSONStream* js) {
  JSONObject obj(js);
  obj.AddProperty("type", "TimelineFlags");
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    obj.AddProperty("recorderName", "null");
  } else {
    obj.AddProperty("recorderName", recorder->name());
  }
  {
    JSONArray availableStreams(&obj, "availableStreams");
#define ADD_STREAM_NAME(name, not_used) availableStreams.AddValue(#name);
    TIMELINE_STREAM_LIST(ADD_STREAM_NAME);
#undef ADD_STREAM_NAME
  }
  {
    JSONArray recordedStreams(&obj, "recordedStreams");
#define ADD_RECORDED_STREAM_NAME(name, not_used)                               \
  if (stream_##name##_.enabled()) {                                            \
    recordedStreams.AddValue(#name);                                           \
  }
    TIMELINE_STREAM_LIST(ADD_RECORDED_STREAM_NAME);
#undef ADD_RECORDED_STREAM_NAME
  }
}

void Timeline::Clear() {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return;
  }
  ReclaimCachedBlocksFromThreads();
  recorder->Clear();
}

TimelineEventRecorder* Timeline::recorder_ = NULL;
MallocGrowableArray<char*>* Timeline::enabled_streams_ = NULL;
Dart_EmbedderTimelineStartRecording Timeline::start_recording_cb_ = NULL;
Dart_EmbedderTimelineStopRecording Timeline::stop_recording_cb_ = NULL;

#define TIMELINE_STREAM_DEFINE(name, enabled_by_default)                       \
  TimelineStream Timeline::stream_##name##_;
TIMELINE_STREAM_LIST(TIMELINE_STREAM_DEFINE)
#undef TIMELINE_STREAM_DEFINE

TimelineEvent::TimelineEvent()
    : timestamp0_(0),
      timestamp1_(0),
      thread_timestamp0_(-1),
      thread_timestamp1_(-1),
      arguments_(NULL),
      arguments_length_(0),
      state_(0),
      label_(NULL),
      category_(""),
      thread_(OSThread::kInvalidThreadId),
      isolate_id_(ILLEGAL_PORT) {}

TimelineEvent::~TimelineEvent() {
  Reset();
}

void TimelineEvent::Reset() {
  if (owns_label() && label_ != NULL) {
    free(const_cast<char*>(label_));
  }
  state_ = 0;
  thread_ = OSThread::kInvalidThreadId;
  isolate_id_ = ILLEGAL_PORT;
  category_ = "";
  label_ = NULL;
  FreeArguments();
  set_pre_serialized_json(false);
  set_event_type(kNone);
  set_owns_label(false);
}

void TimelineEvent::AsyncBegin(const char* label,
                               int64_t async_id,
                               int64_t micros) {
  Init(kAsyncBegin, label);
  set_timestamp0(micros);
  // Overload timestamp1_ with the async_id.
  set_timestamp1(async_id);
}

void TimelineEvent::AsyncInstant(const char* label,
                                 int64_t async_id,
                                 int64_t micros) {
  Init(kAsyncInstant, label);
  set_timestamp0(micros);
  // Overload timestamp1_ with the async_id.
  set_timestamp1(async_id);
}

void TimelineEvent::AsyncEnd(const char* label,
                             int64_t async_id,
                             int64_t micros) {
  Init(kAsyncEnd, label);
  set_timestamp0(micros);
  // Overload timestamp1_ with the async_id.
  set_timestamp1(async_id);
}

void TimelineEvent::DurationBegin(const char* label,
                                  int64_t micros,
                                  int64_t thread_micros) {
  Init(kDuration, label);
  set_timestamp0(micros);
  set_thread_timestamp0(thread_micros);
}

void TimelineEvent::DurationEnd(int64_t micros, int64_t thread_micros) {
  ASSERT(timestamp1_ == 0);
  set_timestamp1(micros);
  set_thread_timestamp1(thread_micros);
}

void TimelineEvent::Instant(const char* label, int64_t micros) {
  Init(kInstant, label);
  set_timestamp0(micros);
}

void TimelineEvent::Duration(const char* label,
                             int64_t start_micros,
                             int64_t end_micros,
                             int64_t thread_start_micros,
                             int64_t thread_end_micros) {
  Init(kDuration, label);
  set_timestamp0(start_micros);
  set_timestamp1(end_micros);
  set_thread_timestamp0(thread_start_micros);
  set_thread_timestamp1(thread_end_micros);
}

void TimelineEvent::Begin(const char* label,
                          int64_t micros,
                          int64_t thread_micros) {
  Init(kBegin, label);
  set_timestamp0(micros);
  set_thread_timestamp0(thread_micros);
}

void TimelineEvent::End(const char* label,
                        int64_t micros,
                        int64_t thread_micros) {
  Init(kEnd, label);
  set_timestamp0(micros);
  set_thread_timestamp0(thread_micros);
}

void TimelineEvent::Counter(const char* label, int64_t micros) {
  Init(kCounter, label);
  set_timestamp0(micros);
}

void TimelineEvent::FlowBegin(const char* label,
                              int64_t async_id,
                              int64_t micros) {
  Init(kFlowBegin, label);
  set_timestamp0(micros);
  // Overload timestamp1_ with the async_id.
  set_timestamp1(async_id);
}

void TimelineEvent::FlowStep(const char* label,
                             int64_t async_id,
                             int64_t micros) {
  Init(kFlowStep, label);
  set_timestamp0(micros);
  // Overload timestamp1_ with the async_id.
  set_timestamp1(async_id);
}

void TimelineEvent::FlowEnd(const char* label,
                            int64_t async_id,
                            int64_t micros) {
  Init(kFlowEnd, label);
  set_timestamp0(micros);
  // Overload timestamp1_ with the async_id.
  set_timestamp1(async_id);
}

void TimelineEvent::Metadata(const char* label, int64_t micros) {
  Init(kMetadata, label);
  set_timestamp0(micros);
}

void TimelineEvent::CompleteWithPreSerializedJSON(const char* json) {
  set_pre_serialized_json(true);
  SetNumArguments(1);
  CopyArgument(0, "Dart", json);
  Complete();
}

void TimelineEvent::SetNumArguments(intptr_t length) {
  // Cannot call this twice.
  ASSERT(arguments_ == NULL);
  ASSERT(arguments_length_ == 0);
  if (length == 0) {
    return;
  }
  arguments_length_ = length;
  arguments_ = reinterpret_cast<TimelineEventArgument*>(
      calloc(sizeof(TimelineEventArgument), length));
}

void TimelineEvent::SetArgument(intptr_t i, const char* name, char* argument) {
  ASSERT(i >= 0);
  ASSERT(i < arguments_length_);
  arguments_[i].name = name;
  arguments_[i].value = argument;
}

void TimelineEvent::FormatArgument(intptr_t i,
                                   const char* name,
                                   const char* fmt,
                                   ...) {
  ASSERT(i >= 0);
  ASSERT(i < arguments_length_);
  va_list args;
  va_start(args, fmt);
  intptr_t len = OS::VSNPrint(NULL, 0, fmt, args);
  va_end(args);

  char* buffer = reinterpret_cast<char*>(malloc(len + 1));
  va_list args2;
  va_start(args2, fmt);
  OS::VSNPrint(buffer, (len + 1), fmt, args2);
  va_end(args2);

  SetArgument(i, name, buffer);
}

void TimelineEvent::CopyArgument(intptr_t i,
                                 const char* name,
                                 const char* argument) {
  SetArgument(i, name, strdup(argument));
}

void TimelineEvent::StealArguments(intptr_t arguments_length,
                                   TimelineEventArgument* arguments) {
  arguments_length_ = arguments_length;
  arguments_ = arguments;
}

void TimelineEvent::Complete() {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder != NULL) {
    recorder->CompleteEvent(this);
  }
}

void TimelineEvent::FreeArguments() {
  if (arguments_ == NULL) {
    return;
  }
  for (intptr_t i = 0; i < arguments_length_; i++) {
    free(arguments_[i].value);
  }
  free(arguments_);
  arguments_ = NULL;
  arguments_length_ = 0;
}

void TimelineEvent::StreamInit(TimelineStream* stream) {
  if (stream != NULL) {
    category_ = stream->name();
  } else {
    category_ = "";
  }
}

void TimelineEvent::Init(EventType event_type, const char* label) {
  ASSERT(label != NULL);
  state_ = 0;
  timestamp0_ = 0;
  timestamp1_ = 0;
  thread_timestamp0_ = -1;
  thread_timestamp1_ = -1;
  OSThread* os_thread = OSThread::Current();
  ASSERT(os_thread != NULL);
  thread_ = os_thread->trace_id();
  Isolate* isolate = Isolate::Current();
  if (isolate != NULL) {
    isolate_id_ = isolate->main_port();
  } else {
    isolate_id_ = ILLEGAL_PORT;
  }
  label_ = label;
  FreeArguments();
  set_pre_serialized_json(false);
  set_event_type(event_type);
  set_owns_label(false);
}

bool TimelineEvent::Within(int64_t time_origin_micros,
                           int64_t time_extent_micros) {
  if ((time_origin_micros == -1) || (time_extent_micros == -1)) {
    // No time range specified.
    return true;
  }
  if (IsFinishedDuration()) {
    // Event is from e_t0 to e_t1.
    int64_t e_t0 = TimeOrigin();
    int64_t e_t1 = TimeEnd();
    ASSERT(e_t0 <= e_t1);
    // Range is from r_t0 to r_t1.
    int64_t r_t0 = time_origin_micros;
    int64_t r_t1 = time_origin_micros + time_extent_micros;
    ASSERT(r_t0 <= r_t1);
    return !((r_t1 < e_t0) || (e_t1 < r_t0));
  }
  int64_t delta = TimeOrigin() - time_origin_micros;
  return (delta >= 0) && (delta <= time_extent_micros);
}

const char* TimelineEvent::GetSerializedJSON() const {
  ASSERT(pre_serialized_json());
  ASSERT(arguments_length_ == 1);
  ASSERT(arguments_ != NULL);
  return arguments_[0].value;
}

void TimelineEvent::PrintJSON(JSONStream* stream) const {
  if (!FLAG_support_service) {
    return;
  }
  if (pre_serialized_json()) {
    // Event has already been serialized into JSON- just append the
    // raw data.
    stream->AppendSerializedObject(GetSerializedJSON());
    return;
  }
  JSONObject obj(stream);
  int64_t pid = OS::ProcessId();
  int64_t tid = OSThread::ThreadIdToIntPtr(thread_);
  obj.AddProperty("name", label_);
  obj.AddProperty("cat", category_);
  obj.AddProperty64("tid", tid);
  obj.AddProperty64("pid", pid);
  obj.AddPropertyTimeMicros("ts", TimeOrigin());
  if (HasThreadCPUTime()) {
    obj.AddPropertyTimeMicros("tts", ThreadCPUTimeOrigin());
  }
  switch (event_type()) {
    case kBegin: {
      obj.AddProperty("ph", "B");
    } break;
    case kEnd: {
      obj.AddProperty("ph", "E");
    } break;
    case kDuration: {
      obj.AddProperty("ph", "X");
      obj.AddPropertyTimeMicros("dur", TimeDuration());
      if (HasThreadCPUTime()) {
        obj.AddPropertyTimeMicros("tdur", ThreadCPUTimeDuration());
      }
    } break;
    case kInstant: {
      obj.AddProperty("ph", "i");
      obj.AddProperty("s", "p");
    } break;
    case kAsyncBegin: {
      obj.AddProperty("ph", "b");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    } break;
    case kAsyncInstant: {
      obj.AddProperty("ph", "n");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    } break;
    case kAsyncEnd: {
      obj.AddProperty("ph", "e");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    } break;
    case kCounter: {
      obj.AddProperty("ph", "C");
    } break;
    case kFlowBegin: {
      obj.AddProperty("ph", "s");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    } break;
    case kFlowStep: {
      obj.AddProperty("ph", "t");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    } break;
    case kFlowEnd: {
      obj.AddProperty("ph", "f");
      obj.AddProperty("bp", "e");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    } break;
    case kMetadata: {
      obj.AddProperty("ph", "M");
    } break;
    default:
      UNIMPLEMENTED();
  }
  {
    JSONObject args(&obj, "args");
    for (intptr_t i = 0; i < arguments_length_; i++) {
      const TimelineEventArgument& arg = arguments_[i];
      args.AddProperty(arg.name, arg.value);
    }
    if (isolate_id_ != ILLEGAL_PORT) {
      // If we have one, append the isolate id.
      args.AddPropertyF("isolateNumber", "%" Pd64 "",
                        static_cast<int64_t>(isolate_id_));
    }
  }
}

int64_t TimelineEvent::TimeOrigin() const {
  return timestamp0_;
}

int64_t TimelineEvent::AsyncId() const {
  return timestamp1_;
}

int64_t TimelineEvent::LowTime() const {
  return timestamp0_;
}

int64_t TimelineEvent::HighTime() const {
  if (event_type() == kDuration) {
    return timestamp1_;
  } else {
    return timestamp0_;
  }
}

int64_t TimelineEvent::TimeDuration() const {
  if (timestamp1_ == 0) {
    // This duration is still open, use current time as end.
    return OS::GetCurrentMonotonicMicros() - timestamp0_;
  }
  return timestamp1_ - timestamp0_;
}

bool TimelineEvent::HasThreadCPUTime() const {
  return (thread_timestamp0_ != -1);
}

int64_t TimelineEvent::ThreadCPUTimeOrigin() const {
  ASSERT(HasThreadCPUTime());
  return thread_timestamp0_;
}

int64_t TimelineEvent::ThreadCPUTimeDuration() const {
  ASSERT(HasThreadCPUTime());
  if (thread_timestamp1_ == -1) {
    // This duration is still open, use current time as end.
    return OS::GetCurrentThreadCPUMicros() - thread_timestamp0_;
  }
  return thread_timestamp1_ - thread_timestamp0_;
}

TimelineStream::TimelineStream() : name_(NULL), enabled_(false) {}

void TimelineStream::Init(const char* name, bool enabled) {
  name_ = name;
  enabled_ = enabled;
}

TimelineEvent* TimelineStream::StartEvent() {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (!enabled() || (recorder == NULL)) {
    return NULL;
  }
  ASSERT(name_ != NULL);
  TimelineEvent* event = recorder->StartEvent();
  if (event != NULL) {
    event->StreamInit(this);
  }
  return event;
}

TimelineEventScope::TimelineEventScope(TimelineStream* stream,
                                       const char* label)
    : StackResource(reinterpret_cast<Thread*>(NULL)),
      stream_(stream),
      label_(label),
      arguments_(NULL),
      arguments_length_(0),
      enabled_(false) {
  Init();
}

TimelineEventScope::TimelineEventScope(Thread* thread,
                                       TimelineStream* stream,
                                       const char* label)
    : StackResource(thread),
      stream_(stream),
      label_(label),
      arguments_(NULL),
      arguments_length_(0),
      enabled_(false) {
  Init();
}

TimelineEventScope::~TimelineEventScope() {
  FreeArguments();
}

void TimelineEventScope::Init() {
  ASSERT(enabled_ == false);
  ASSERT(label_ != NULL);
  ASSERT(stream_ != NULL);
  if (!stream_->enabled()) {
    // Stream is not enabled, do nothing.
    return;
  }
  enabled_ = true;
}

void TimelineEventScope::SetNumArguments(intptr_t length) {
  if (!enabled()) {
    return;
  }
  ASSERT(arguments_ == NULL);
  ASSERT(arguments_length_ == 0);
  arguments_length_ = length;
  if (arguments_length_ == 0) {
    return;
  }
  arguments_ = reinterpret_cast<TimelineEventArgument*>(
      calloc(sizeof(TimelineEventArgument), length));
}

// |name| must be a compile time constant. Takes ownership of |argumentp|.
void TimelineEventScope::SetArgument(intptr_t i,
                                     const char* name,
                                     char* argument) {
  if (!enabled()) {
    return;
  }
  ASSERT(i >= 0);
  ASSERT(i < arguments_length_);
  arguments_[i].name = name;
  arguments_[i].value = argument;
}

// |name| must be a compile time constant. Copies |argument|.
void TimelineEventScope::CopyArgument(intptr_t i,
                                      const char* name,
                                      const char* argument) {
  if (!enabled()) {
    return;
  }
  SetArgument(i, name, strdup(argument));
}

void TimelineEventScope::FormatArgument(intptr_t i,
                                        const char* name,
                                        const char* fmt,
                                        ...) {
  if (!enabled()) {
    return;
  }
  va_list args;
  va_start(args, fmt);
  intptr_t len = OS::VSNPrint(NULL, 0, fmt, args);
  va_end(args);

  char* buffer = reinterpret_cast<char*>(malloc(len + 1));
  va_list args2;
  va_start(args2, fmt);
  OS::VSNPrint(buffer, (len + 1), fmt, args2);
  va_end(args2);

  SetArgument(i, name, buffer);
}

void TimelineEventScope::FreeArguments() {
  if (arguments_ == NULL) {
    return;
  }
  for (intptr_t i = 0; i < arguments_length_; i++) {
    free(arguments_[i].value);
  }
  free(arguments_);
  arguments_ = NULL;
  arguments_length_ = 0;
}

void TimelineEventScope::StealArguments(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  event->StealArguments(arguments_length_, arguments_);
  arguments_length_ = 0;
  arguments_ = NULL;
}

TimelineDurationScope::TimelineDurationScope(TimelineStream* stream,
                                             const char* label)
    : TimelineEventScope(stream, label) {
  if (!FLAG_support_timeline || !enabled()) {
    return;
  }
  timestamp_ = OS::GetCurrentMonotonicMicros();
  thread_timestamp_ = OS::GetCurrentThreadCPUMicros();
}

TimelineDurationScope::TimelineDurationScope(Thread* thread,
                                             TimelineStream* stream,
                                             const char* label)
    : TimelineEventScope(thread, stream, label) {
  if (!FLAG_support_timeline || !enabled()) {
    return;
  }
  timestamp_ = OS::GetCurrentMonotonicMicros();
  thread_timestamp_ = OS::GetCurrentThreadCPUMicros();
}

TimelineDurationScope::~TimelineDurationScope() {
  if (!FLAG_support_timeline) {
    return;
  }
  if (!ShouldEmitEvent()) {
    return;
  }
  TimelineEvent* event = stream()->StartEvent();
  if (event == NULL) {
    // Stream is now disabled.
    return;
  }
  ASSERT(event != NULL);
  // Emit a duration event.
  event->Duration(label(), timestamp_, OS::GetCurrentMonotonicMicros(),
                  thread_timestamp_, OS::GetCurrentThreadCPUMicros());
  StealArguments(event);
  event->Complete();
}

TimelineBeginEndScope::TimelineBeginEndScope(TimelineStream* stream,
                                             const char* label)
    : TimelineEventScope(stream, label) {
  if (!FLAG_support_timeline) {
    return;
  }
  EmitBegin();
}

TimelineBeginEndScope::TimelineBeginEndScope(Thread* thread,
                                             TimelineStream* stream,
                                             const char* label)
    : TimelineEventScope(thread, stream, label) {
  if (!FLAG_support_timeline) {
    return;
  }
  EmitBegin();
}

TimelineBeginEndScope::~TimelineBeginEndScope() {
  if (!FLAG_support_timeline) {
    return;
  }
  EmitEnd();
}

void TimelineBeginEndScope::EmitBegin() {
  if (!FLAG_support_timeline) {
    return;
  }
  if (!ShouldEmitEvent()) {
    return;
  }
  TimelineEvent* event = stream()->StartEvent();
  if (event == NULL) {
    // Stream is now disabled.
    set_enabled(false);
    return;
  }
  ASSERT(event != NULL);
  // Emit a begin event.
  event->Begin(label());
  event->Complete();
}

void TimelineBeginEndScope::EmitEnd() {
  if (!FLAG_support_timeline) {
    return;
  }
  if (!ShouldEmitEvent()) {
    return;
  }
  TimelineEvent* event = stream()->StartEvent();
  if (event == NULL) {
    // Stream is now disabled.
    set_enabled(false);
    return;
  }
  ASSERT(event != NULL);
  // Emit an end event.
  event->End(label());
  StealArguments(event);
  event->Complete();
}

TimelineEventFilter::TimelineEventFilter(int64_t time_origin_micros,
                                         int64_t time_extent_micros)
    : time_origin_micros_(time_origin_micros),
      time_extent_micros_(time_extent_micros) {
  ASSERT(time_origin_micros_ >= -1);
  ASSERT(time_extent_micros_ >= -1);
}

TimelineEventFilter::~TimelineEventFilter() {}

IsolateTimelineEventFilter::IsolateTimelineEventFilter(
    Dart_Port isolate_id,
    int64_t time_origin_micros,
    int64_t time_extent_micros)
    : TimelineEventFilter(time_origin_micros, time_extent_micros),
      isolate_id_(isolate_id) {}

TimelineEventRecorder::TimelineEventRecorder()
    : async_id_(0), time_low_micros_(0), time_high_micros_(0) {}

void TimelineEventRecorder::PrintJSONMeta(JSONArray* events) const {
  if (!FLAG_support_service) {
    return;
  }
  OSThreadIterator it;
  while (it.HasNext()) {
    OSThread* thread = it.Next();
    const char* thread_name = thread->name();
    if (thread_name == NULL) {
      // Only emit a thread name if one was set.
      continue;
    }
    JSONObject obj(events);
    int64_t pid = OS::ProcessId();
    int64_t tid = OSThread::ThreadIdToIntPtr(thread->trace_id());
    obj.AddProperty("name", "thread_name");
    obj.AddProperty("ph", "M");
    obj.AddProperty64("pid", pid);
    obj.AddProperty64("tid", tid);
    {
      JSONObject args(&obj, "args");
      args.AddPropertyF("name", "%s (%" Pd64 ")", thread_name, tid);
    }
  }
}

TimelineEvent* TimelineEventRecorder::ThreadBlockStartEvent() {
  // Grab the current thread.
  OSThread* thread = OSThread::Current();
  ASSERT(thread != NULL);
  Mutex* thread_block_lock = thread->timeline_block_lock();
  ASSERT(thread_block_lock != NULL);
  // We are accessing the thread's timeline block- so take the lock here.
  // This lock will be held until the call to |CompleteEvent| is made.
  thread_block_lock->Lock();
#if defined(DEBUG)
  Thread* T = Thread::Current();
  if (T != NULL) {
    T->IncrementNoSafepointScopeDepth();
  }
#endif  // defined(DEBUG)

  TimelineEventBlock* thread_block = thread->timeline_block();

  if ((thread_block != NULL) && thread_block->IsFull()) {
    MutexLocker ml(&lock_);
    // Thread has a block and it is full:
    // 1) Mark it as finished.
    thread_block->Finish();
    // 2) Allocate a new block.
    thread_block = GetNewBlockLocked();
    thread->set_timeline_block(thread_block);
  } else if (thread_block == NULL) {
    MutexLocker ml(&lock_);
    // Thread has no block. Attempt to allocate one.
    thread_block = GetNewBlockLocked();
    thread->set_timeline_block(thread_block);
  }
  if (thread_block != NULL) {
    // NOTE: We are exiting this function with the thread's block lock held.
    ASSERT(!thread_block->IsFull());
    TimelineEvent* event = thread_block->StartEvent();
    return event;
  }
// Drop lock here as no event is being handed out.
#if defined(DEBUG)
  if (T != NULL) {
    T->DecrementNoSafepointScopeDepth();
  }
#endif  // defined(DEBUG)
  thread_block_lock->Unlock();
  return NULL;
}

void TimelineEventRecorder::ResetTimeTracking() {
  time_high_micros_ = 0;
  time_low_micros_ = kMaxInt64;
}

void TimelineEventRecorder::ReportTime(int64_t micros) {
  if (time_high_micros_ < micros) {
    time_high_micros_ = micros;
  }
  if (time_low_micros_ > micros) {
    time_low_micros_ = micros;
  }
}

int64_t TimelineEventRecorder::TimeOriginMicros() const {
  if (time_high_micros_ == 0) {
    return 0;
  }
  return time_low_micros_;
}

int64_t TimelineEventRecorder::TimeExtentMicros() const {
  if (time_high_micros_ == 0) {
    return 0;
  }
  return time_high_micros_ - time_low_micros_;
}

void TimelineEventRecorder::ThreadBlockCompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  // Grab the current thread.
  OSThread* thread = OSThread::Current();
  ASSERT(thread != NULL);
  // Unlock the thread's block lock.
  Mutex* thread_block_lock = thread->timeline_block_lock();
  ASSERT(thread_block_lock != NULL);
#if defined(DEBUG)
  Thread* T = Thread::Current();
  if (T != NULL) {
    T->DecrementNoSafepointScopeDepth();
  }
#endif  // defined(DEBUG)
  thread_block_lock->Unlock();
}

void TimelineEventRecorder::WriteTo(const char* directory) {
  if (!FLAG_support_service) {
    return;
  }
  Dart_FileOpenCallback file_open = Dart::file_open_callback();
  Dart_FileWriteCallback file_write = Dart::file_write_callback();
  Dart_FileCloseCallback file_close = Dart::file_close_callback();
  if ((file_open == NULL) || (file_write == NULL) || (file_close == NULL)) {
    return;
  }

  Timeline::ReclaimCachedBlocksFromThreads();

  intptr_t pid = OS::ProcessId();
  char* filename =
      OS::SCreate(NULL, "%s/dart-timeline-%" Pd ".json", directory, pid);
  void* file = (*file_open)(filename, true);
  if (file == NULL) {
    OS::Print("Failed to write timeline file: %s\n", filename);
    free(filename);
    return;
  }
  free(filename);

  JSONStream js;
  TimelineEventFilter filter;
  PrintTraceEvent(&js, &filter);
  // Steal output from JSONStream.
  char* output = NULL;
  intptr_t output_length = 0;
  js.Steal(&output, &output_length);
  (*file_write)(output, output_length, file);
  // Free the stolen output.
  free(output);
  (*file_close)(file);

  return;
}

int64_t TimelineEventRecorder::GetNextAsyncId() {
  // TODO(johnmccutchan): Gracefully handle wrap around.
  // TODO(rmacnak): Use TRACE_NONCE() on Fuchsia?
  uint32_t next =
      static_cast<uint32_t>(AtomicOperations::FetchAndIncrement(&async_id_));
  return static_cast<int64_t>(next);
}

void TimelineEventRecorder::FinishBlock(TimelineEventBlock* block) {
  if (block == NULL) {
    return;
  }
  MutexLocker ml(&lock_);
  block->Finish();
}

TimelineEventBlock* TimelineEventRecorder::GetNewBlock() {
  MutexLocker ml(&lock_);
  return GetNewBlockLocked();
}

TimelineEventFixedBufferRecorder::TimelineEventFixedBufferRecorder(
    intptr_t capacity)
    : memory_(NULL),
      blocks_(NULL),
      capacity_(capacity),
      num_blocks_(0),
      block_cursor_(0) {
  // Capacity must be a multiple of TimelineEventBlock::kBlockSize
  ASSERT((capacity % TimelineEventBlock::kBlockSize) == 0);
  // Allocate blocks array.
  num_blocks_ = capacity / TimelineEventBlock::kBlockSize;

  intptr_t size = Utils::RoundUp(num_blocks_ * sizeof(TimelineEventBlock),
                                 VirtualMemory::PageSize());
  const bool kNotExecutable = false;
  memory_ = VirtualMemory::Reserve(size);
  if ((memory_ == NULL) || !memory_->Commit(kNotExecutable, "dart-timeline")) {
    OUT_OF_MEMORY();
  }
  blocks_ = reinterpret_cast<TimelineEventBlock*>(memory_->address());
}

TimelineEventFixedBufferRecorder::~TimelineEventFixedBufferRecorder() {
  // Delete all blocks.
  for (intptr_t i = 0; i < num_blocks_; i++) {
    blocks_[i].Reset();
  }
  delete memory_;
}

void TimelineEventFixedBufferRecorder::PrintJSONEvents(
    JSONArray* events,
    TimelineEventFilter* filter) {
  if (!FLAG_support_service) {
    return;
  }
  MutexLocker ml(&lock_);
  ResetTimeTracking();
  intptr_t block_offset = FindOldestBlockIndex();
  if (block_offset == -1) {
    // All blocks are empty.
    return;
  }
  for (intptr_t block_idx = 0; block_idx < num_blocks_; block_idx++) {
    TimelineEventBlock* block =
        &blocks_[(block_idx + block_offset) % num_blocks_];
    if (!filter->IncludeBlock(block)) {
      continue;
    }
    for (intptr_t event_idx = 0; event_idx < block->length(); event_idx++) {
      TimelineEvent* event = block->At(event_idx);
      if (filter->IncludeEvent(event) &&
          event->Within(filter->time_origin_micros(),
                        filter->time_extent_micros())) {
        ReportTime(event->LowTime());
        ReportTime(event->HighTime());
        events->AddValue(event);
      }
    }
  }
}

void TimelineEventFixedBufferRecorder::PrintJSON(JSONStream* js,
                                                 TimelineEventFilter* filter) {
  if (!FLAG_support_service) {
    return;
  }
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "_Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
    PrintJSONEvents(&events, filter);
  }
  topLevel.AddPropertyTimeMicros("timeOriginMicros", TimeOriginMicros());
  topLevel.AddPropertyTimeMicros("timeExtentMicros", TimeExtentMicros());
}

void TimelineEventFixedBufferRecorder::PrintTraceEvent(
    JSONStream* js,
    TimelineEventFilter* filter) {
  if (!FLAG_support_service) {
    return;
  }
  JSONArray events(js);
  PrintJSONMeta(&events);
  PrintJSONEvents(&events, filter);
}

TimelineEventBlock* TimelineEventFixedBufferRecorder::GetHeadBlockLocked() {
  return &blocks_[0];
}

void TimelineEventFixedBufferRecorder::Clear() {
  MutexLocker ml(&lock_);
  for (intptr_t i = 0; i < num_blocks_; i++) {
    TimelineEventBlock* block = &blocks_[i];
    block->Reset();
  }
}

intptr_t TimelineEventFixedBufferRecorder::FindOldestBlockIndex() const {
  int64_t earliest_time = kMaxInt64;
  intptr_t earliest_index = -1;
  for (intptr_t block_idx = 0; block_idx < num_blocks_; block_idx++) {
    TimelineEventBlock* block = &blocks_[block_idx];
    if (block->IsEmpty()) {
      // Skip empty blocks.
      continue;
    }
    if (block->LowerTimeBound() < earliest_time) {
      earliest_time = block->LowerTimeBound();
      earliest_index = block_idx;
    }
  }
  return earliest_index;
}

TimelineEvent* TimelineEventFixedBufferRecorder::StartEvent() {
  return ThreadBlockStartEvent();
}

void TimelineEventFixedBufferRecorder::CompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  ThreadBlockCompleteEvent(event);
}

TimelineEventBlock* TimelineEventRingRecorder::GetNewBlockLocked() {
  // TODO(johnmccutchan): This function should only hand out blocks
  // which have been marked as finished.
  if (block_cursor_ == num_blocks_) {
    block_cursor_ = 0;
  }
  TimelineEventBlock* block = &blocks_[block_cursor_++];
  block->Reset();
  block->Open();
  return block;
}

TimelineEventBlock* TimelineEventStartupRecorder::GetNewBlockLocked() {
  if (block_cursor_ == num_blocks_) {
    return NULL;
  }
  TimelineEventBlock* block = &blocks_[block_cursor_++];
  block->Reset();
  block->Open();
  return block;
}

TimelineEventCallbackRecorder::TimelineEventCallbackRecorder() {}

TimelineEventCallbackRecorder::~TimelineEventCallbackRecorder() {}

void TimelineEventCallbackRecorder::PrintJSON(JSONStream* js,
                                              TimelineEventFilter* filter) {
  if (!FLAG_support_service) {
    return;
  }
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "_Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
  }
}

void TimelineEventCallbackRecorder::PrintTraceEvent(
    JSONStream* js,
    TimelineEventFilter* filter) {
  if (!FLAG_support_service) {
    return;
  }
  JSONArray events(js);
}

TimelineEvent* TimelineEventCallbackRecorder::StartEvent() {
  TimelineEvent* event = new TimelineEvent();
  return event;
}

void TimelineEventCallbackRecorder::CompleteEvent(TimelineEvent* event) {
  OnEvent(event);
  delete event;
}

TimelineEventEndlessRecorder::TimelineEventEndlessRecorder()
    : head_(NULL), block_index_(0) {}

TimelineEventEndlessRecorder::~TimelineEventEndlessRecorder() {
  TimelineEventBlock* current = head_;
  head_ = NULL;

  while (current != NULL) {
    TimelineEventBlock* next = current->next();
    delete current;
    current = next;
  }
}

void TimelineEventEndlessRecorder::PrintJSON(JSONStream* js,
                                             TimelineEventFilter* filter) {
  if (!FLAG_support_service) {
    return;
  }
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "_Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
    PrintJSONEvents(&events, filter);
  }
  topLevel.AddPropertyTimeMicros("timeOriginMicros", TimeOriginMicros());
  topLevel.AddPropertyTimeMicros("timeExtentMicros", TimeExtentMicros());
}

void TimelineEventEndlessRecorder::PrintTraceEvent(
    JSONStream* js,
    TimelineEventFilter* filter) {
  if (!FLAG_support_service) {
    return;
  }
  JSONArray events(js);
  PrintJSONMeta(&events);
  PrintJSONEvents(&events, filter);
}

TimelineEventBlock* TimelineEventEndlessRecorder::GetHeadBlockLocked() {
  return head_;
}

TimelineEvent* TimelineEventEndlessRecorder::StartEvent() {
  return ThreadBlockStartEvent();
}

void TimelineEventEndlessRecorder::CompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  ThreadBlockCompleteEvent(event);
}

TimelineEventBlock* TimelineEventEndlessRecorder::GetNewBlockLocked() {
  TimelineEventBlock* block = new TimelineEventBlock(block_index_++);
  block->set_next(head_);
  block->Open();
  head_ = block;
  if (FLAG_trace_timeline) {
    OS::Print("Created new block %p\n", block);
  }
  return head_;
}

static int TimelineEventBlockCompare(TimelineEventBlock* const* a,
                                     TimelineEventBlock* const* b) {
  return (*a)->LowerTimeBound() - (*b)->LowerTimeBound();
}

void TimelineEventEndlessRecorder::PrintJSONEvents(
    JSONArray* events,
    TimelineEventFilter* filter) {
  if (!FLAG_support_service) {
    return;
  }
  MutexLocker ml(&lock_);
  ResetTimeTracking();
  // Collect all interesting blocks.
  MallocGrowableArray<TimelineEventBlock*> blocks(8);
  TimelineEventBlock* current = head_;
  while (current != NULL) {
    if (filter->IncludeBlock(current)) {
      blocks.Add(current);
    }
    current = current->next();
  }
  // Bail early.
  if (blocks.length() == 0) {
    return;
  }
  // Sort the interesting blocks so that blocks with earlier events are
  // outputted first.
  blocks.Sort(TimelineEventBlockCompare);
  // Output blocks in sorted order.
  for (intptr_t block_idx = 0; block_idx < blocks.length(); block_idx++) {
    current = blocks[block_idx];
    intptr_t length = current->length();
    for (intptr_t i = 0; i < length; i++) {
      TimelineEvent* event = current->At(i);
      if (filter->IncludeEvent(event) &&
          event->Within(filter->time_origin_micros(),
                        filter->time_extent_micros())) {
        ReportTime(event->LowTime());
        ReportTime(event->HighTime());
        events->AddValue(event);
      }
    }
  }
}

void TimelineEventEndlessRecorder::Clear() {
  TimelineEventBlock* current = head_;
  while (current != NULL) {
    TimelineEventBlock* next = current->next();
    delete current;
    current = next;
  }
  head_ = NULL;
  block_index_ = 0;
  OSThread* thread = OSThread::Current();
  thread->set_timeline_block(NULL);
}

TimelineEventBlock::TimelineEventBlock(intptr_t block_index)
    : next_(NULL),
      length_(0),
      block_index_(block_index),
      thread_id_(OSThread::kInvalidThreadId),
      in_use_(false) {}

TimelineEventBlock::~TimelineEventBlock() {
  Reset();
}

void TimelineEventBlock::PrintJSON(JSONStream* js) const {
  ASSERT(!in_use());
  JSONArray events(js);
  for (intptr_t i = 0; i < length(); i++) {
    const TimelineEvent* event = At(i);
    events.AddValue(event);
  }
}

TimelineEvent* TimelineEventBlock::StartEvent() {
  ASSERT(!IsFull());
  if (FLAG_trace_timeline) {
    OSThread* os_thread = OSThread::Current();
    ASSERT(os_thread != NULL);
    intptr_t tid = OSThread::ThreadIdToIntPtr(os_thread->id());
    OS::Print("StartEvent in block %p for thread %" Px "\n", this, tid);
  }
  return &events_[length_++];
}

int64_t TimelineEventBlock::LowerTimeBound() const {
  if (length_ == 0) {
    return kMaxInt64;
  }
  ASSERT(length_ > 0);
  return events_[0].TimeOrigin();
}

bool TimelineEventBlock::CheckBlock() {
  if (length() == 0) {
    return true;
  }

  for (intptr_t i = 0; i < length(); i++) {
    if (At(i)->thread() != thread_id()) {
      return false;
    }
  }

  // - events have monotonically increasing timestamps.
  int64_t last_time = LowerTimeBound();
  for (intptr_t i = 0; i < length(); i++) {
    if (last_time > At(i)->TimeOrigin()) {
      return false;
    }
    last_time = At(i)->TimeOrigin();
  }

  return true;
}

void TimelineEventBlock::Reset() {
  for (intptr_t i = 0; i < kBlockSize; i++) {
    // Clear any extra data.
    events_[i].Reset();
  }
  length_ = 0;
  thread_id_ = OSThread::kInvalidThreadId;
  in_use_ = false;
}

void TimelineEventBlock::Open() {
  OSThread* os_thread = OSThread::Current();
  ASSERT(os_thread != NULL);
  thread_id_ = os_thread->trace_id();
  in_use_ = true;
}

void TimelineEventBlock::Finish() {
  if (FLAG_trace_timeline) {
    OS::Print("Finish block %p\n", this);
  }
  in_use_ = false;
  if (Service::timeline_stream.enabled()) {
    ServiceEvent service_event(NULL, ServiceEvent::kTimelineEvents);
    service_event.set_timeline_event_block(this);
    Service::HandleEvent(&service_event);
  }
}

TimelineEventBlockIterator::TimelineEventBlockIterator(
    TimelineEventRecorder* recorder)
    : current_(NULL), recorder_(NULL) {
  Reset(recorder);
}

TimelineEventBlockIterator::~TimelineEventBlockIterator() {
  Reset(NULL);
}

void TimelineEventBlockIterator::Reset(TimelineEventRecorder* recorder) {
  // Clear current.
  current_ = NULL;
  if (recorder_ != NULL) {
    // Unlock old recorder.
    recorder_->lock_.Unlock();
  }
  recorder_ = recorder;
  if (recorder_ == NULL) {
    return;
  }
  // Lock new recorder.
  recorder_->lock_.Lock();
  // Queue up first block.
  current_ = recorder_->GetHeadBlockLocked();
}

bool TimelineEventBlockIterator::HasNext() const {
  return current_ != NULL;
}

TimelineEventBlock* TimelineEventBlockIterator::Next() {
  ASSERT(current_ != NULL);
  TimelineEventBlock* r = current_;
  current_ = current_->next();
  return r;
}

void DartCommonTimelineEventHelpers::ReportTaskEvent(Thread* thread,
                                                     Zone* zone,
                                                     TimelineEvent* event,
                                                     int64_t start,
                                                     int64_t id,
                                                     const char* phase,
                                                     const char* category,
                                                     const char* name,
                                                     const char* args) {
  const int64_t pid = OS::ProcessId();
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  const int64_t tid = OSThread::ThreadIdToIntPtr(os_thread->trace_id());
  ASSERT(phase != NULL);
  ASSERT((phase[0] == 'n') || (phase[0] == 'b') || (phase[0] == 'e'));
  ASSERT(phase[1] == '\0');
  char* json = OS::SCreate(
      zone,
      "{\"name\":\"%s\",\"cat\":\"%s\",\"tid\":%" Pd64 ",\"pid\":%" Pd64
      ","
      "\"ts\":%" Pd64 ",\"ph\":\"%s\",\"id\":%" Pd64 ", \"args\":%s}",
      name, category, tid, pid, start, phase, id, args);
  switch (phase[0]) {
    case 'n':
      event->AsyncInstant("", id, start);
      break;
    case 'b':
      event->AsyncBegin("", id, start);
      break;
    case 'e':
      event->AsyncEnd("", id, start);
      break;
    default:
      UNREACHABLE();
  }

  // json was allocated in the zone and a copy will be stored in event.
  event->CompleteWithPreSerializedJSON(json);
}

void DartCommonTimelineEventHelpers::ReportCompleteEvent(Thread* thread,
                                                         Zone* zone,
                                                         TimelineEvent* event,
                                                         int64_t start,
                                                         int64_t start_cpu,
                                                         const char* category,
                                                         const char* name,
                                                         const char* args) {
  const int64_t end = OS::GetCurrentMonotonicMicros();
  const int64_t end_cpu = OS::GetCurrentThreadCPUMicros();
  const int64_t duration = end - start;
  const int64_t duration_cpu = end_cpu - start_cpu;
  const int64_t pid = OS::ProcessId();
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  const int64_t tid = OSThread::ThreadIdToIntPtr(os_thread->trace_id());

  char* json = NULL;
  if ((start_cpu != -1) && (end_cpu != -1)) {
    json = OS::SCreate(
        zone,
        "{\"name\":\"%s\",\"cat\":\"%s\",\"tid\":%" Pd64 ",\"pid\":%" Pd64
        ","
        "\"ts\":%" Pd64 ",\"ph\":\"X\",\"dur\":%" Pd64
        ","
        "\"tdur\":%" Pd64 ",\"args\":%s}",
        name, category, tid, pid, start, duration, duration_cpu, args);
  } else {
    json = OS::SCreate(
        zone,
        "{\"name\":\"%s\",\"cat\":\"%s\",\"tid\":%" Pd64 ",\"pid\":%" Pd64
        ","
        "\"ts\":%" Pd64 ",\"ph\":\"X\",\"dur\":%" Pd64 ",\"args\":%s}",
        name, category, tid, pid, start, duration, args);
  }
  ASSERT(json != NULL);

  event->Duration("", start, end, start_cpu, end_cpu);
  // json was allocated in the zone and a copy will be stored in event.
  event->CompleteWithPreSerializedJSON(json);
}

void DartCommonTimelineEventHelpers::ReportInstantEvent(Thread* thread,
                                                        Zone* zone,
                                                        TimelineEvent* event,
                                                        int64_t start,
                                                        const char* category,
                                                        const char* name,
                                                        const char* args) {
  const int64_t pid = OS::ProcessId();
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  const int64_t tid = OSThread::ThreadIdToIntPtr(os_thread->trace_id());

  char* json = OS::SCreate(zone,
                           "{\"name\":\"%s\",\"cat\":\"%s\",\"tid\":%" Pd64
                           ",\"pid\":%" Pd64
                           ","
                           "\"ts\":%" Pd64 ",\"ph\":\"I\",\"args\":%s}",
                           name, category, tid, pid, start, args);

  event->Instant("", start);
  // json was allocated in the zone and a copy will be stored in event.
  event->CompleteWithPreSerializedJSON(json);
}

}  // namespace dart

#endif  // !PRODUCT
