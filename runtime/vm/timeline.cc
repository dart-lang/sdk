// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(SUPPORT_TIMELINE)

#include "vm/timeline.h"

#include <errno.h>
#include <fcntl.h>

#include <cstdlib>

#include "platform/atomic.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/service.h"
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
            "Valid values: all, API, Compiler, CompilerVerbose, Dart, "
            "Debugger, Embedder, GC, Isolate, and VM.");
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

#if defined(HOST_OS_LINUX) || defined(HOST_OS_ANDROID)
      return new TimelineEventSystraceRecorder();
#elif defined(HOST_OS_MACOS)
      if (__builtin_available(iOS 12.0, macOS 10.14, *)) {
        return new TimelineEventMacosRecorder();
      }
#elif defined(HOST_OS_FUCHSIA)
      return new TimelineEventFuchsiaRecorder();
#else
      OS::PrintErr(
          "Warning: The systrace timeline recorder is equivalent to the"
          "ring recorder on this platform.");
      return new TimelineEventRingRecorder();
#endif
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
  char* streams = Utils::StrDup(FLAG_timeline_streams);
  char* token = strtok_r(streams, ",", &save_ptr);
  while (token != NULL) {
    result->Add(Utils::StrDup(token));
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

void Timeline::Init() {
  ASSERT(recorder_ == NULL);
  recorder_ = CreateTimelineRecorder();
  ASSERT(recorder_ != NULL);
  enabled_streams_ = GetEnabledByDefaultTimelineStreams();
// Global overrides.
#define TIMELINE_STREAM_FLAG_DEFAULT(name, fuchsia_name)                       \
  stream_##name##_.set_enabled(HasStream(enabled_streams_, #name));
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_FLAG_DEFAULT)
#undef TIMELINE_STREAM_FLAG_DEFAULT
}

void Timeline::Cleanup() {
  ASSERT(recorder_ != NULL);

#ifndef PRODUCT
  if (FLAG_timeline_dir != NULL) {
    recorder_->WriteTo(FLAG_timeline_dir);
  }
#endif

// Disable global streams.
#define TIMELINE_STREAM_DISABLE(name, fuchsia_name)                            \
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

#ifndef PRODUCT
void Timeline::PrintFlagsToJSONArray(JSONArray* arr) {
#define ADD_RECORDED_STREAM_NAME(name, fuchsia_name)                           \
  if (stream_##name##_.enabled()) {                                            \
    arr->AddValue(#name);                                                      \
  }
  TIMELINE_STREAM_LIST(ADD_RECORDED_STREAM_NAME);
#undef ADD_RECORDED_STREAM_NAME
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
#define ADD_STREAM_NAME(name, fuchsia_name) availableStreams.AddValue(#name);
    TIMELINE_STREAM_LIST(ADD_STREAM_NAME);
#undef ADD_STREAM_NAME
  }
  {
    JSONArray recordedStreams(&obj, "recordedStreams");
#define ADD_RECORDED_STREAM_NAME(name, fuchsia_name)                           \
  if (stream_##name##_.enabled()) {                                            \
    recordedStreams.AddValue(#name);                                           \
  }
    TIMELINE_STREAM_LIST(ADD_RECORDED_STREAM_NAME);
#undef ADD_RECORDED_STREAM_NAME
  }
}
#endif

void Timeline::Clear() {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder == NULL) {
    return;
  }
  ReclaimCachedBlocksFromThreads();
  recorder->Clear();
}

void TimelineEventArguments::SetNumArguments(intptr_t length) {
  if (length == length_) {
    return;
  }
  if (length == 0) {
    Free();
    return;
  }
  if (buffer_ == NULL) {
    // calloc already nullifies
    buffer_ = reinterpret_cast<TimelineEventArgument*>(
        calloc(sizeof(TimelineEventArgument), length));
  } else {
    for (intptr_t i = length; i < length_; ++i) {
      free(buffer_[i].value);
    }
    buffer_ = reinterpret_cast<TimelineEventArgument*>(
        realloc(buffer_, sizeof(TimelineEventArgument) * length));
    if (length > length_) {
      memset(buffer_ + length_, 0,
             sizeof(TimelineEventArgument) * (length - length_));
    }
  }
  length_ = length;
}

void TimelineEventArguments::SetArgument(intptr_t i,
                                         const char* name,
                                         char* argument) {
  ASSERT(i >= 0);
  ASSERT(i < length_);
  buffer_[i].name = name;
  buffer_[i].value = argument;
}

void TimelineEventArguments::CopyArgument(intptr_t i,
                                          const char* name,
                                          const char* argument) {
  SetArgument(i, name, Utils::StrDup(argument));
}

void TimelineEventArguments::FormatArgument(intptr_t i,
                                            const char* name,
                                            const char* fmt,
                                            va_list args) {
  ASSERT(i >= 0);
  ASSERT(i < length_);
  va_list args2;
  va_copy(args2, args);
  intptr_t len = Utils::VSNPrint(NULL, 0, fmt, args);
  va_end(args);

  char* buffer = reinterpret_cast<char*>(malloc(len + 1));
  Utils::VSNPrint(buffer, (len + 1), fmt, args2);
  va_end(args2);

  SetArgument(i, name, buffer);
}

void TimelineEventArguments::StealArguments(TimelineEventArguments* arguments) {
  Free();
  length_ = arguments->length_;
  buffer_ = arguments->buffer_;
  arguments->length_ = 0;
  arguments->buffer_ = NULL;
}

void TimelineEventArguments::Free() {
  if (buffer_ == NULL) {
    return;
  }
  for (intptr_t i = 0; i < length_; i++) {
    free(buffer_[i].value);
  }
  free(buffer_);
  buffer_ = NULL;
  length_ = 0;
}

TimelineEventRecorder* Timeline::recorder_ = NULL;
MallocGrowableArray<char*>* Timeline::enabled_streams_ = NULL;

#define TIMELINE_STREAM_DEFINE(name, fuchsia_name)                             \
  TimelineStream Timeline::stream_##name##_(#name, fuchsia_name, false);
TIMELINE_STREAM_LIST(TIMELINE_STREAM_DEFINE)
#undef TIMELINE_STREAM_DEFINE

TimelineEvent::TimelineEvent()
    : timestamp0_(0),
      timestamp1_(0),
      thread_timestamp0_(-1),
      thread_timestamp1_(-1),
      state_(0),
      label_(NULL),
      stream_(NULL),
      thread_(OSThread::kInvalidThreadId),
      isolate_id_(ILLEGAL_PORT),
      isolate_group_id_(0) {}

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
  isolate_group_id_ = 0;
  stream_ = NULL;
  label_ = NULL;
  arguments_.Free();
  set_event_type(kNone);
  set_pre_serialized_args(false);
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

void TimelineEvent::CompleteWithPreSerializedArgs(char* args_json) {
  set_pre_serialized_args(true);
  SetNumArguments(1);
  SetArgument(0, "Dart Arguments", args_json);
  Complete();
}

void TimelineEvent::FormatArgument(intptr_t i,
                                   const char* name,
                                   const char* fmt,
                                   ...) {
  va_list args;
  va_start(args, fmt);
  arguments_.FormatArgument(i, name, fmt, args);
}

void TimelineEvent::Complete() {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (recorder != NULL) {
    recorder->CompleteEvent(this);
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
  auto thread = Thread::Current();
  auto isolate = thread != nullptr ? thread->isolate() : nullptr;
  auto isolate_group = thread != nullptr ? thread->isolate_group() : nullptr;
  isolate_id_ = (isolate != nullptr) ? isolate->main_port() : ILLEGAL_PORT;
  isolate_group_id_ = (isolate_group != nullptr) ? isolate_group->id() : 0;
  label_ = label;
  arguments_.Free();
  set_event_type(event_type);
  set_pre_serialized_args(false);
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

#ifndef PRODUCT
void TimelineEvent::PrintJSON(JSONStream* stream) const {
  JSONObject obj(stream);
  int64_t pid = OS::ProcessId();
  int64_t tid = OSThread::ThreadIdToIntPtr(thread_);
  obj.AddProperty("name", label_);
  obj.AddProperty("cat", stream_ != NULL ? stream_->name() : NULL);
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

  if (pre_serialized_args()) {
    ASSERT(arguments_.length() == 1);
    stream->AppendSerializedObject("args", arguments_[0].value);
    if (isolate_id_ != ILLEGAL_PORT) {
      stream->UncloseObject();
      stream->PrintfProperty("isolateId", ISOLATE_SERVICE_ID_FORMAT_STRING,
                             static_cast<int64_t>(isolate_id_));
      stream->CloseObject();
    }
    if (isolate_group_id_ != 0) {
      stream->UncloseObject();
      stream->PrintfProperty("isolateGroupId",
                             ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING,
                             isolate_group_id_);
      stream->CloseObject();
    } else {
      ASSERT(isolate_group_id_ == ILLEGAL_PORT);
    }
  } else {
    JSONObject args(&obj, "args");
    for (intptr_t i = 0; i < arguments_.length(); i++) {
      const TimelineEventArgument& arg = arguments_[i];
      args.AddProperty(arg.name, arg.value);
    }
    if (isolate_id_ != ILLEGAL_PORT) {
      args.AddPropertyF("isolateId", ISOLATE_SERVICE_ID_FORMAT_STRING,
                        static_cast<int64_t>(isolate_id_));
    }
    if (isolate_group_id_ != 0) {
      args.AddPropertyF("isolateGroupId",
                        ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING,
                        isolate_group_id_);
    } else {
      ASSERT(isolate_group_id_ == ILLEGAL_PORT);
    }
  }
}
#endif

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

TimelineStream::TimelineStream(const char* name,
                               const char* fuchsia_name,
                               bool enabled)
    : name_(name),
      fuchsia_name_(fuchsia_name),
#if defined(HOST_OS_FUCHSIA)
      enabled_(static_cast<uintptr_t>(true))  // For generated code.
#else
      enabled_(static_cast<uintptr_t>(enabled))
#endif
{
#if defined(HOST_OS_MACOS)
  if (__builtin_available(iOS 12.0, macOS 10.14, *)) {
    macos_log_ = os_log_create("Dart", name);
  }
#endif
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
      enabled_(false) {
  Init();
}

TimelineEventScope::TimelineEventScope(Thread* thread,
                                       TimelineStream* stream,
                                       const char* label)
    : StackResource(thread), stream_(stream), label_(label), enabled_(false) {
  Init();
}

TimelineEventScope::~TimelineEventScope() {}

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
  arguments_.SetNumArguments(length);
}

// |name| must be a compile time constant. Takes ownership of |argumentp|.
void TimelineEventScope::SetArgument(intptr_t i,
                                     const char* name,
                                     char* argument) {
  if (!enabled()) {
    return;
  }
  arguments_.SetArgument(i, name, argument);
}

// |name| must be a compile time constant. Copies |argument|.
void TimelineEventScope::CopyArgument(intptr_t i,
                                      const char* name,
                                      const char* argument) {
  if (!enabled()) {
    return;
  }
  arguments_.CopyArgument(i, name, argument);
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
  arguments_.FormatArgument(i, name, fmt, args);
}

void TimelineEventScope::StealArguments(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  event->StealArguments(&arguments_);
}

TimelineBeginEndScope::TimelineBeginEndScope(TimelineStream* stream,
                                             const char* label)
    : TimelineEventScope(stream, label) {
  EmitBegin();
}

TimelineBeginEndScope::TimelineBeginEndScope(Thread* thread,
                                             TimelineStream* stream,
                                             const char* label)
    : TimelineEventScope(thread, stream, label) {
  EmitBegin();
}

TimelineBeginEndScope::~TimelineBeginEndScope() {
  EmitEnd();
}

void TimelineBeginEndScope::EmitBegin() {
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

#ifndef PRODUCT
void TimelineEventRecorder::PrintJSONMeta(JSONArray* events) const {
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
      args.AddProperty("mode", "basic");
    }
  }
}
#endif

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

#ifndef PRODUCT
void TimelineEventRecorder::WriteTo(const char* directory) {
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
    OS::PrintErr("Failed to write timeline file: %s\n", filename);
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
#endif

int64_t TimelineEventRecorder::GetNextAsyncId() {
  // TODO(johnmccutchan): Gracefully handle wrap around.
#if defined(HOST_OS_FUCHSIA)
  return trace_generate_nonce();
#else
  uint32_t next = static_cast<uint32_t>(async_id_.fetch_add(1u));
  return static_cast<int64_t>(next);
#endif
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
  memory_ = VirtualMemory::Allocate(size, kNotExecutable, "dart-timeline");
  if (memory_ == NULL) {
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

intptr_t TimelineEventFixedBufferRecorder::Size() {
  return memory_->size();
}

#ifndef PRODUCT
void TimelineEventFixedBufferRecorder::PrintJSONEvents(
    JSONArray* events,
    TimelineEventFilter* filter) {
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
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "Timeline");
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
  JSONArray events(js);
  PrintJSONMeta(&events);
  PrintJSONEvents(&events, filter);
}
#endif

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

#ifndef PRODUCT
void TimelineEventCallbackRecorder::PrintJSON(JSONStream* js,
                                              TimelineEventFilter* filter) {
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
  }
  topLevel.AddPropertyTimeMicros("timeOriginMicros", TimeOriginMicros());
  topLevel.AddPropertyTimeMicros("timeExtentMicros", TimeExtentMicros());
}

void TimelineEventCallbackRecorder::PrintTraceEvent(
    JSONStream* js,
    TimelineEventFilter* filter) {
  JSONArray events(js);
}
#endif

TimelineEvent* TimelineEventCallbackRecorder::StartEvent() {
  TimelineEvent* event = new TimelineEvent();
  return event;
}

void TimelineEventCallbackRecorder::CompleteEvent(TimelineEvent* event) {
  OnEvent(event);
  delete event;
}

TimelineEventPlatformRecorder::TimelineEventPlatformRecorder() {}

TimelineEventPlatformRecorder::~TimelineEventPlatformRecorder() {}

#ifndef PRODUCT
void TimelineEventPlatformRecorder::PrintJSON(JSONStream* js,
                                              TimelineEventFilter* filter) {
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
  }
  topLevel.AddPropertyTimeMicros("timeOriginMicros", TimeOriginMicros());
  topLevel.AddPropertyTimeMicros("timeExtentMicros", TimeExtentMicros());
}

void TimelineEventPlatformRecorder::PrintTraceEvent(
    JSONStream* js,
    TimelineEventFilter* filter) {
  JSONArray events(js);
}
#endif

TimelineEvent* TimelineEventPlatformRecorder::StartEvent() {
  TimelineEvent* event = new TimelineEvent();
  return event;
}

void TimelineEventPlatformRecorder::CompleteEvent(TimelineEvent* event) {
  OnEvent(event);
  delete event;
}

TimelineEventEndlessRecorder::TimelineEventEndlessRecorder()
    : head_(nullptr), tail_(nullptr), block_index_(0) {}

TimelineEventEndlessRecorder::~TimelineEventEndlessRecorder() {
  TimelineEventBlock* current = head_;
  head_ = tail_ = nullptr;

  while (current != nullptr) {
    TimelineEventBlock* next = current->next();
    delete current;
    current = next;
  }
}

#ifndef PRODUCT
void TimelineEventEndlessRecorder::PrintJSON(JSONStream* js,
                                             TimelineEventFilter* filter) {
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "Timeline");
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
  JSONArray events(js);
  PrintJSONMeta(&events);
  PrintJSONEvents(&events, filter);
}
#endif

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
  block->Open();
  if (head_ == nullptr) {
    head_ = tail_ = block;
  } else {
    tail_->set_next(block);
    tail_ = block;
  }
  if (FLAG_trace_timeline) {
    OS::PrintErr("Created new block %p\n", block);
  }
  return block;
}

#ifndef PRODUCT
void TimelineEventEndlessRecorder::PrintJSONEvents(
    JSONArray* events,
    TimelineEventFilter* filter) {
  MutexLocker ml(&lock_);
  ResetTimeTracking();
  for (TimelineEventBlock* current = head_; current != nullptr;
       current = current->next()) {
    if (!filter->IncludeBlock(current)) {
      continue;
    }
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
#endif

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

#ifndef PRODUCT
void TimelineEventBlock::PrintJSON(JSONStream* js) const {
  ASSERT(!in_use());
  JSONArray events(js);
  for (intptr_t i = 0; i < length(); i++) {
    const TimelineEvent* event = At(i);
    events.AddValue(event);
  }
}
#endif

TimelineEvent* TimelineEventBlock::StartEvent() {
  ASSERT(!IsFull());
  if (FLAG_trace_timeline) {
    OSThread* os_thread = OSThread::Current();
    ASSERT(os_thread != NULL);
    intptr_t tid = OSThread::ThreadIdToIntPtr(os_thread->id());
    OS::PrintErr("StartEvent in block %p for thread %" Pd "\n", this, tid);
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
    OS::PrintErr("Finish block %p\n", this);
  }
  in_use_ = false;
#ifndef PRODUCT
  if (Service::timeline_stream.enabled()) {
    ServiceEvent service_event(NULL, ServiceEvent::kTimelineEvents);
    service_event.set_timeline_event_block(this);
    Service::HandleEvent(&service_event);
  }
#endif
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

void DartTimelineEventHelpers::ReportTaskEvent(Thread* thread,
                                               TimelineEvent* event,
                                               int64_t id,
                                               const char* phase,
                                               const char* category,
                                               char* name,
                                               char* args) {
  ASSERT(phase != NULL);
  ASSERT((phase[0] == 'n') || (phase[0] == 'b') || (phase[0] == 'e') ||
         (phase[0] == 'B') || (phase[0] == 'E'));
  ASSERT(phase[1] == '\0');
  const int64_t start = OS::GetCurrentMonotonicMicros();
  const int64_t start_cpu = OS::GetCurrentThreadCPUMicrosForTimeline();
  switch (phase[0]) {
    case 'n':
      event->AsyncInstant(name, id, start);
      break;
    case 'b':
      event->AsyncBegin(name, id, start);
      break;
    case 'e':
      event->AsyncEnd(name, id, start);
      break;
    case 'B':
      event->Begin(name, start, start_cpu);
      break;
    case 'E':
      event->End(name, start, start_cpu);
      break;
    default:
      UNREACHABLE();
  }
  event->set_owns_label(true);
  event->CompleteWithPreSerializedArgs(args);
}

void DartTimelineEventHelpers::ReportFlowEvent(Thread* thread,
                                               TimelineEvent* event,
                                               const char* category,
                                               char* name,
                                               int64_t type,
                                               int64_t flow_id,
                                               char* args) {
  const int64_t start = OS::GetCurrentMonotonicMicros();
  TimelineEvent::EventType event_type =
      static_cast<TimelineEvent::EventType>(type);
  switch (event_type) {
    case TimelineEvent::kFlowBegin:
      event->FlowBegin(name, flow_id, start);
      break;
    case TimelineEvent::kFlowStep:
      event->FlowStep(name, flow_id, start);
      break;
    case TimelineEvent::kFlowEnd:
      event->FlowEnd(name, flow_id, start);
      break;
    default:
      UNREACHABLE();
      break;
  }
  event->set_owns_label(true);
  event->CompleteWithPreSerializedArgs(args);
}

void DartTimelineEventHelpers::ReportInstantEvent(Thread* thread,
                                                  TimelineEvent* event,
                                                  const char* category,
                                                  char* name,
                                                  char* args) {
  const int64_t start = OS::GetCurrentMonotonicMicros();
  event->Instant(name, start);
  event->set_owns_label(true);
  event->CompleteWithPreSerializedArgs(args);
}

}  // namespace dart

#endif  // defined(SUPPORT_TIMELINE)
