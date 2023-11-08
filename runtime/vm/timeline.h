// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TIMELINE_H_
#define RUNTIME_VM_TIMELINE_H_

#include <functional>
#include <memory>

#include "include/dart_tools_api.h"

#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/hashmap.h"
#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/os.h"
#include "vm/os_thread.h"

#if defined(SUPPORT_TIMELINE) && defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
#include "perfetto/protozero/scattered_heap_buffer.h"
#include "vm/protos/perfetto/trace/trace_packet.pbzero.h"
#endif  // defined(SUPPORT_TIMELINE) && defined(SUPPORT_PERFETTO) &&           \
        // !defined(PRODUCT)

#if defined(FUCHSIA_SDK) || defined(DART_HOST_OS_FUCHSIA)
#include <lib/trace-engine/context.h>
#include <lib/trace-engine/instrumentation.h>
#elif defined(DART_HOST_OS_MACOS)
#include <os/availability.h>
#if defined(__MAC_10_14) || defined (__IPHONE_12_0)
#define DART_HOST_OS_SUPPORTS_SIGNPOST 1
#endif
// signpost.h exists in macOS 10.14, iOS 12 or above
#if defined(DART_HOST_OS_SUPPORTS_SIGNPOST)
#include <os/signpost.h>
#else
#include <os/log.h>
#endif
#endif

namespace dart {

#if !defined(SUPPORT_TIMELINE)
#define TIMELINE_DURATION(thread, stream, name)
#define TIMELINE_FUNCTION_COMPILATION_DURATION(thread, name, function)
#define TIMELINE_FUNCTION_GC_DURATION(thread, name)
#endif  // !defined(SUPPORT_TIMELINE)

class JSONArray;
class JSONBase64String;
class JSONObject;
class JSONStream;
class JSONWriter;
class Object;
class ObjectPointerVisitor;
class Isolate;
class Thread;
class TimelineEvent;
class TimelineEventBlock;
class TimelineEventRecorder;
class TimelineStream;
class VirtualMemory;
class Zone;

#if defined(SUPPORT_TIMELINE)
#define CALLBACK_RECORDER_NAME "Callback"
#define ENDLESS_RECORDER_NAME "Endless"
#define FILE_RECORDER_NAME "File"
#define FUCHSIA_RECORDER_NAME "Fuchsia"
#define MACOS_RECORDER_NAME "Macos"
#define PERFETTO_FILE_RECORDER_NAME "Perfettofile"
#define RING_RECORDER_NAME "Ring"
#define STARTUP_RECORDER_NAME "Startup"
#define SYSTRACE_RECORDER_NAME "Systrace"

// (name, fuchsia_name, has_static_labels).
#define TIMELINE_STREAM_LIST(V)                                                \
  V(API, "dart:api", true)                                                     \
  V(Compiler, "dart:compiler", true)                                           \
  V(CompilerVerbose, "dart:compiler.verbose", true)                            \
  V(Dart, "dart:dart", false)                                                  \
  V(Debugger, "dart:debugger", true)                                           \
  V(Embedder, "dart:embedder", true)                                           \
  V(GC, "dart:gc", true)                                                       \
  V(Isolate, "dart:isolate", true)                                             \
  V(VM, "dart:vm", true)
#endif  // defined(SUPPORT_TIMELINE)

// A stream of timeline events. A stream has a name and can be enabled or
// disabled (globally and per isolate).
class TimelineStream {
 public:
  TimelineStream(const char* name,
                 const char* fuchsia_name,
                 bool static_labels,
                 bool enabled);

  const char* name() const { return name_; }
  const char* fuchsia_name() const { return fuchsia_name_; }

  bool enabled() {
#if defined(DART_HOST_OS_FUCHSIA)
#ifdef PRODUCT
    return trace_is_category_enabled(fuchsia_name_);
#else
    return trace_is_category_enabled(fuchsia_name_) || enabled_ != 0;
#endif  // PRODUCT
#else
    return enabled_ != 0;
#endif  // defined(DART_HOST_OS_FUCHSIA)
  }

  void set_enabled(bool enabled) { enabled_ = enabled ? 1 : 0; }

  // Records an event. Will return |nullptr| if not enabled. The returned
  // |TimelineEvent| is in an undefined state and must be initialized.
  TimelineEvent* StartEvent();

  static intptr_t enabled_offset() {
    return OFFSET_OF(TimelineStream, enabled_);
  }

#if defined(DART_HOST_OS_FUCHSIA)
  trace_site_t* trace_site() { return &trace_site_; }
#elif defined(DART_HOST_OS_MACOS)
  os_log_t macos_log() const { return macos_log_; }
  bool has_static_labels() const { return has_static_labels_; }
#endif

 private:
  const char* const name_;
  const char* const fuchsia_name_;

  // This field is accessed by generated code (intrinsic) and expects to see
  // 0 or 1. If this becomes a BitField, the generated code must be updated.
  uintptr_t enabled_;

#if defined(DART_HOST_OS_FUCHSIA)
  trace_site_t trace_site_ = {};
#elif defined(DART_HOST_OS_MACOS)
  os_log_t macos_log_ = {};
  bool has_static_labels_ = false;
#endif
};

#if defined(SUPPORT_TIMELINE)
class RecorderSynchronizationLock : public AllStatic {
 public:
  static void Init() {
    recorder_state_.store(kActive, std::memory_order_release);
    outstanding_event_writes_.store(0);
  }

  static void EnterLock() {
    outstanding_event_writes_.fetch_add(1, std::memory_order_acquire);
  }

  static void ExitLock() {
    intptr_t count =
        outstanding_event_writes_.fetch_sub(1, std::memory_order_release);
    ASSERT(count >= 0);
  }

  static bool IsUninitialized() {
    return (recorder_state_.load(std::memory_order_acquire) == kUninitialized);
  }

  static bool IsActive() {
    return (recorder_state_.load(std::memory_order_acquire) == kActive);
  }

  static void WaitForShutdown() {
    recorder_state_.store(kShuttingDown, std::memory_order_release);
    // Spin waiting for outstanding events to be completed.
    while (outstanding_event_writes_.load(std::memory_order_relaxed) > 0) {
    }
  }

 private:
  typedef enum { kUninitialized = 0, kActive, kShuttingDown } RecorderState;
  static std::atomic<RecorderState> recorder_state_;
  static std::atomic<intptr_t> outstanding_event_writes_;

  DISALLOW_COPY_AND_ASSIGN(RecorderSynchronizationLock);
};

// Any modifications to the timeline must be guarded by a
// |RecorderSynchronizationLockScope| to prevent the timeline from being
// cleaned up in the middle of the modifications.
class RecorderSynchronizationLockScope {
 public:
  RecorderSynchronizationLockScope() {
    RecorderSynchronizationLock::EnterLock();
  }

  ~RecorderSynchronizationLockScope() {
    RecorderSynchronizationLock::ExitLock();
  }

  bool IsUninitialized() const {
    return RecorderSynchronizationLock::IsUninitialized();
  }

  bool IsActive() const { return RecorderSynchronizationLock::IsActive(); }

 private:
  DISALLOW_COPY_AND_ASSIGN(RecorderSynchronizationLockScope);
};

class Timeline : public AllStatic {
 public:
  // Initialize timeline system. Not thread safe.
  static void Init();

  // Cleanup timeline system. Not thread safe.
  static void Cleanup();

  // Access the global recorder. Not thread safe.
  static TimelineEventRecorder* recorder() { return recorder_; }

  static bool recorder_discards_clock_values() {
    return recorder_discards_clock_values_;
  }
  static void set_recorder_discards_clock_values(bool value) {
    recorder_discards_clock_values_ = value;
  }

  static Dart_TimelineRecorderCallback callback() { return callback_; }
  static void set_callback(Dart_TimelineRecorderCallback callback) {
    callback_ = callback;
  }

  // Reclaim all |TimelineEventBlocks|s that are cached by threads.
  static void ReclaimCachedBlocksFromThreads();

  static void Clear();

#ifndef PRODUCT
  // Print information about streams to JSON.
  static void PrintFlagsToJSON(JSONStream* json);

  // Output the recorded streams to a JSONS array.
  static void PrintFlagsToJSONArray(JSONArray* arr);
#endif

#define TIMELINE_STREAM_ACCESSOR(name, ...)                                    \
  static TimelineStream* Get##name##Stream() { return &stream_##name##_; }
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_ACCESSOR)
#undef TIMELINE_STREAM_ACCESSOR

#define TIMELINE_STREAM_FLAGS(name, ...)                                       \
  static void SetStream##name##Enabled(bool enabled) {                         \
    stream_##name##_.set_enabled(enabled);                                     \
  }
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_FLAGS)
#undef TIMELINE_STREAM_FLAGS

 private:
  static TimelineEventRecorder* recorder_;
  static Dart_TimelineRecorderCallback callback_;
  static MallocGrowableArray<char*>* enabled_streams_;
  static bool recorder_discards_clock_values_;

#define TIMELINE_STREAM_DECLARE(name, ...)                                     \
  static TimelineStream stream_##name##_;
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_DECLARE)
#undef TIMELINE_STREAM_DECLARE

  template <class>
  friend class TimelineRecorderOverride;
  friend class ReclaimBlocksIsolateVisitor;
};

struct TimelineEventArgument {
  const char* name;
  char* value;
};

class TimelineEventArguments {
 public:
  TimelineEventArguments() : buffer_(nullptr), length_(0) {}
  ~TimelineEventArguments() { Free(); }
  // Get/Set the number of arguments in the event.
  void SetNumArguments(intptr_t length);
  // |name| must be a compile time constant. Takes ownership of |argument|.
  void SetArgument(intptr_t i, const char* name, char* argument);
  // |name| must be a compile time constant. Copies |argument|.
  void CopyArgument(intptr_t i, const char* name, const char* argument);
  // |name| must be a compile time constant. Takes ownership of |args|
  void FormatArgument(intptr_t i,
                      const char* name,
                      const char* fmt,
                      va_list args);

  void StealArguments(TimelineEventArguments* arguments);

  TimelineEventArgument* buffer() const { return buffer_; }

  intptr_t length() const { return length_; }

  void Free();

  TimelineEventArgument& operator[](intptr_t index) const {
    return buffer_[index];
  }

  bool IsEmpty() { return length_ == 0; }

  bool IsNotEmpty() { return length_ != 0; }

 private:
  TimelineEventArgument* buffer_;
  intptr_t length_;
  DISALLOW_COPY_AND_ASSIGN(TimelineEventArguments);
};

// You should get a |TimelineEvent| from a |TimelineStream|.
class TimelineEvent {
 public:
  // Keep in sync with StateBits below.
  // Keep in sync with constants in sdk/lib/developer/timeline.dart.
  enum EventType {
    kNone = 0,
    kBegin = 1,
    kEnd = 2,
    kDuration = 3,
    kInstant = 4,
    kAsyncBegin = 5,
    kAsyncInstant = 6,
    kAsyncEnd = 7,
    kCounter = 8,
    kFlowBegin = 9,
    kFlowStep = 10,
    kFlowEnd = 11,
    kMetadata = 12,
    kNumEventTypes,
  };

  // This value must be kept in sync with the value of _noFlowId in
  // sdk/lib/developer/timeline.dart.
  static const int64_t kNoFlowId = -1;

  TimelineEvent();
  ~TimelineEvent();

  void Reset();

  bool IsValid() const {
    return (event_type() > kNone) && (event_type() < kNumEventTypes);
  }

  // Marks the beginning of an asynchronous operation with |async_id|.
  void AsyncBegin(const char* label,
                  int64_t async_id,
                  int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());
  // Marks an instantaneous event associated with |async_id|.
  void AsyncInstant(
      const char* label,
      int64_t async_id,
      int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());
  // Marks the end of an asynchronous operation associated with |async_id|.
  void AsyncEnd(const char* label,
                int64_t async_id,
                int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());

  void DurationBegin(
      const char* label,
      int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());

  void Instant(const char* label,
               int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());

  void Duration(const char* label, int64_t start_micros, int64_t end_micros);

  void Begin(const char* label,
             int64_t id,
             int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());

  void End(const char* label,
           int64_t id,
           int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());

  void Counter(const char* label,
               int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());

  void FlowBegin(const char* label,
                 int64_t id,
                 int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());
  void FlowStep(const char* label,
                int64_t id,
                int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());
  void FlowEnd(const char* label,
               int64_t id,
               int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());

  void Metadata(const char* label,
                int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline());

  void CompleteWithPreSerializedArgs(char* args_json);

  // Get/Set the number of arguments in the event.
  intptr_t GetNumArguments() const { return arguments_.length(); }
  void SetNumArguments(intptr_t length) { arguments_.SetNumArguments(length); }
  // |name| must be a compile time constant. Takes ownership of |argument|.
  void SetArgument(intptr_t i, const char* name, char* argument) {
    arguments_.SetArgument(i, name, argument);
  }
  // |name| must be a compile time constant. Copies |argument|.
  void CopyArgument(intptr_t i, const char* name, const char* argument) {
    arguments_.CopyArgument(i, name, argument);
  }
  // |name| must be a compile time constant.
  void FormatArgument(intptr_t i, const char* name, const char* fmt, ...)
      PRINTF_ATTRIBUTE(4, 5);

  void StealArguments(TimelineEventArguments* arguments) {
    arguments_.StealArguments(arguments);
  }
  // Mandatory to call when this event is completely filled out.
  void Complete();

  EventType event_type() const { return EventTypeField::decode(state_); }

  TimelineStream* stream() const { return stream_; }

  int64_t TimeOrigin() const { return timestamp0_; }
  int64_t Id() const {
    ASSERT(event_type() != kDuration && event_type() != kInstant &&
           event_type() != kCounter);
    return timestamp1_or_id_;
  }
  int64_t TimeDuration() const;
  void SetTimeEnd(int64_t micros = OS::GetCurrentMonotonicMicrosForTimeline()) {
    ASSERT(event_type() == kDuration);
    ASSERT(timestamp1_or_id_ == 0);
    set_timestamp1_or_id(micros);
  }
  int64_t TimeEnd() const {
    ASSERT(IsFinishedDuration());
    return timestamp1_or_id_;
  }

  int64_t timestamp0() const { return timestamp0_; }
  int64_t timestamp1_or_id() const { return timestamp1_or_id_; }

  void SetFlowIds(intptr_t flow_id_count,
                  std::unique_ptr<const int64_t[]>& flow_ids) {
    flow_id_count_ = flow_id_count;
    flow_ids_.swap(flow_ids);
  }
  intptr_t flow_id_count() const { return flow_id_count_; }
  const int64_t* FlowIds() const { return flow_ids_.get(); }

  bool HasIsolateId() const;
  bool HasIsolateGroupId() const;
  std::unique_ptr<const char[]> GetFormattedIsolateId() const;
  std::unique_ptr<const char[]> GetFormattedIsolateGroupId() const;

  // The lowest time value stored in this event.
  int64_t LowTime() const;
  // The highest time value stored in this event.
  int64_t HighTime() const;

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream) const;
#endif
  void PrintJSON(JSONWriter* writer) const;
#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
  bool CanBeRepresentedByPerfettoTracePacket() const;
  /*
   * Populates the fields of |packet| with this event's data.
   */
  void PopulateTracePacket(perfetto::protos::pbzero::TracePacket* packet) const;
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

  ThreadId thread() const { return thread_; }

  void set_thread(ThreadId tid) { thread_ = tid; }

  Dart_Port isolate_id() const { return isolate_id_; }

  uint64_t isolate_group_id() const { return isolate_group_id_; }

  void* isolate_data() const { return isolate_data_; }

  void* isolate_group_data() const { return isolate_group_data_; }

  const char* label() const { return label_; }

  // Does this duration end before |micros| ?
  bool DurationFinishedBefore(int64_t micros) const {
    return TimeEnd() <= micros;
  }

  bool IsDuration() const { return (event_type() == kDuration); }

  bool IsBegin() const { return (event_type() == kBegin); }

  bool IsEnd() const { return (event_type() == kEnd); }

  // Is this event a synchronous begin or end event?
  bool IsBeginOrEnd() const { return IsBegin() || IsEnd(); }

  // Does this duration fully contain |other| ?
  bool DurationContains(TimelineEvent* other) const {
    ASSERT(IsFinishedDuration());
    if (other->IsBegin()) {
      if (other->TimeOrigin() < TimeOrigin()) {
        return false;
      }
      if (other->TimeOrigin() > TimeEnd()) {
        return false;
      }
      return true;
    } else {
      ASSERT(other->IsFinishedDuration());
      if (other->TimeOrigin() < TimeOrigin()) {
        return false;
      }
      if (other->TimeEnd() < TimeOrigin()) {
        return false;
      }
      if (other->TimeOrigin() > TimeEnd()) {
        return false;
      }
      if (other->TimeEnd() > TimeEnd()) {
        return false;
      }
      return true;
    }
  }

  bool Within(int64_t time_origin_micros, int64_t time_extent_micros);

  void set_owns_label(bool owns_label) {
    state_ = OwnsLabelBit::update(owns_label, state_);
  }

  TimelineEventArgument* arguments() const { return arguments_.buffer(); }

  intptr_t arguments_length() const { return arguments_.length(); }

  bool ArgsArePreSerialized() const {
    return PreSerializedArgsBit::decode(state_);
  }

  TimelineEvent* next() const {
    return next_;
  }
  void set_next(TimelineEvent* next) {
    next_ = next;
  }

 private:
  void StreamInit(TimelineStream* stream) { stream_ = stream; }
  void Init(EventType event_type, const char* label);

  void set_event_type(EventType event_type) {
    // We only reserve 4 bits to hold the event type.
    COMPILE_ASSERT(kNumEventTypes < 16);
    state_ = EventTypeField::update(event_type, state_);
  }

  void set_timestamp0(int64_t value) {
    ASSERT(timestamp0_ == 0);
    timestamp0_ = value;
  }
  void set_timestamp1_or_id(int64_t value) {
    ASSERT(timestamp1_or_id_ == 0);
    timestamp1_or_id_ = value;
  }

  bool IsFinishedDuration() const {
    return (event_type() == kDuration) && (timestamp1_or_id_ > timestamp0_);
  }

  void set_pre_serialized_args(bool pre_serialized_args) {
    state_ = PreSerializedArgsBit::update(pre_serialized_args, state_);
  }

  bool owns_label() const { return OwnsLabelBit::decode(state_); }

  enum StateBits {
    kEventTypeBit = 0,  // reserve 4 bits for type.
    kPreSerializedArgsBit = 4,
    kOwnsLabelBit = 5,
    kNextBit = 6,
  };

  class EventTypeField : public BitField<uword, EventType, kEventTypeBit, 4> {};
  class PreSerializedArgsBit
      : public BitField<uword, bool, kPreSerializedArgsBit, 1> {};
  class OwnsLabelBit : public BitField<uword, bool, kOwnsLabelBit, 1> {};

  int64_t timestamp0_;
  // For an event of type |kDuration|, this is the end time. For an event of
  // type |kFlowBegin|, |kFlowStep|, or |kFlowEnd| this is the flow ID. For an
  // event of type |kBegin| or |kEnd|, this is the event ID (which is only
  // referenced by the MacOS recorder). For an async event, this is the async
  // ID.
  int64_t timestamp1_or_id_;
  intptr_t flow_id_count_;
  // This field is needed to support trace serialization in Perfetto's proto
  // format. Flow IDs must be associated with |TimelineEvent::kBegin|,
  // |TimelineEvent::kDuration|, |TimelineEvent::kInstant|,
  // |TimelineEvent::kAsyncBegin|, and |TimelineEvent::kAsyncInstant| events to
  // serialize traces in Perfetto's format. Flow event information is serialized
  // in Chrome's JSON trace format through events of type
  // |TimelineEvent::kFlowBegin|, |TimelineEvent::kFlowStep|, and
  // |TimelineEvent::kFlowEnd|.
  std::unique_ptr<const int64_t[]> flow_ids_;
  TimelineEventArguments arguments_;
  uword state_;
  const char* label_;
  TimelineStream* stream_;
  ThreadId thread_;
  Dart_Port isolate_id_;
  uint64_t isolate_group_id_;
  void* isolate_data_;
  void* isolate_group_data_;
  TimelineEvent* next_;

  friend class TimelineEventRecorder;
  friend class TimelineEventEndlessRecorder;
  friend class TimelineEventRingRecorder;
  friend class TimelineEventStartupRecorder;
  friend class TimelineEventPlatformRecorder;
  friend class TimelineEventFuchsiaRecorder;
  friend class TimelineEventMacosRecorder;
#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
  friend class TimelineEventPerfettoFileRecorder;
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
  friend class TimelineStream;
  friend class TimelineTestHelper;
  DISALLOW_COPY_AND_ASSIGN(TimelineEvent);
};

class TimelineTrackMetadata {
 public:
  TimelineTrackMetadata(intptr_t pid,
                        intptr_t tid,
                        Utils::CStringUniquePtr&& track_name);
  intptr_t pid() const { return pid_; }
  intptr_t tid() const { return tid_; }
  const char* track_name() const { return track_name_.get(); }
  inline void set_track_name(Utils::CStringUniquePtr&& track_name);
#if !defined(PRODUCT)
  /*
   * Prints a Chrome-format event representing the metadata stored by this
   * object into |jsarr_events|.
   */
  void PrintJSON(const JSONArray& jsarr_events) const;
#if defined(SUPPORT_PERFETTO)
  /*
   * Populates the fields of |track_descriptor_packet| with the metadata stored
   * by this object.
   */
  void PopulateTracePacket(
      perfetto::protos::pbzero::TracePacket* track_descriptor_packet) const;
#endif  // defined(SUPPORT_PERFETTO)
#endif  // !defined(PRODUCT)

 private:
  // The ID of the process that this track is associated with.
  intptr_t pid_;
  // The trace ID of the thread that this track is associated with.
  intptr_t tid_;
  // The name of this track.
  Utils::CStringUniquePtr track_name_;
};

class AsyncTimelineTrackMetadata {
 public:
  AsyncTimelineTrackMetadata(intptr_t pid, intptr_t async_id);
  intptr_t pid() const { return pid_; }
  intptr_t async_id() const { return async_id_; }
#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
  /*
   * Populates the fields of |track_descriptor_packet| with the metadata stored
   * by this object.
   */
  void PopulateTracePacket(
      perfetto::protos::pbzero::TracePacket* track_descriptor_packet) const;
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

 private:
  // The ID of the process that this track is associated with.
  intptr_t pid_;
  // The async ID that this track is associated with.
  intptr_t async_id_;
};

#define TIMELINE_DURATION(thread, stream, name)                                \
  TimelineBeginEndScope tbes(thread, Timeline::Get##stream##Stream(), name);
#define TIMELINE_FUNCTION_COMPILATION_DURATION(thread, name, function)         \
  TimelineBeginEndScope tbes(thread, Timeline::GetCompilerStream(), name);     \
  if (tbes.enabled()) {                                                        \
    tbes.SetNumArguments(1);                                                   \
    tbes.CopyArgument(0, "function", function.ToQualifiedCString());           \
  }

#define TIMELINE_FUNCTION_GC_DURATION(thread, name)                            \
  TimelineBeginEndScope tbes(thread, Timeline::GetGCStream(), name);

// See |TimelineBeginEndScope|.
class TimelineEventScope : public StackResource {
 public:
  bool enabled() const { return enabled_; }

  intptr_t GetNumArguments() { return arguments_.length(); }
  void SetNumArguments(intptr_t length);

  void SetArgument(intptr_t i, const char* name, char* argument);

  void CopyArgument(intptr_t i, const char* name, const char* argument);

  void FormatArgument(intptr_t i, const char* name, const char* fmt, ...)
      PRINTF_ATTRIBUTE(4, 5);

 protected:
  TimelineEventScope(TimelineStream* stream, const char* label);

  TimelineEventScope(Thread* thread, TimelineStream* stream, const char* label);

  bool ShouldEmitEvent() const { return enabled_; }

  void set_enabled(bool enabled) { enabled_ = enabled; }

  const char* label() const { return label_; }

  int64_t id() const { return id_; }

  TimelineEventArgument* arguments() const { return arguments_.buffer(); }

  intptr_t arguments_length() const { return arguments_.length(); }

  TimelineStream* stream() const { return stream_; }

  virtual ~TimelineEventScope();

  void StealArguments(TimelineEvent* event);

 private:
  void Init();

  TimelineStream* stream_;
  const char* label_;
  int64_t id_;
  TimelineEventArguments arguments_;
  bool enabled_;

  DISALLOW_COPY_AND_ASSIGN(TimelineEventScope);
};

class TimelineBeginEndScope : public TimelineEventScope {
 public:
  TimelineBeginEndScope(TimelineStream* stream, const char* label);

  TimelineBeginEndScope(Thread* thread,
                        TimelineStream* stream,
                        const char* label);

  virtual ~TimelineBeginEndScope();

 private:
  void EmitBegin();
  void EmitEnd();

  DISALLOW_COPY_AND_ASSIGN(TimelineBeginEndScope);
};

// A block of |TimelineEvent|s. Not thread safe.
class TimelineEventBlock : public MallocAllocated {
 public:
  static constexpr intptr_t kBlockSize = 64;

  explicit TimelineEventBlock(intptr_t index);
  ~TimelineEventBlock();

  TimelineEventBlock* next() const { return next_; }
  void set_next(TimelineEventBlock* next) { next_ = next; }

  intptr_t length() const { return length_; }

  intptr_t block_index() const { return block_index_; }

  bool IsEmpty() const { return length_ == 0; }

  bool IsFull() const { return length_ == kBlockSize; }

  TimelineEvent* At(intptr_t index) {
    ASSERT(index >= 0);
    ASSERT(index < kBlockSize);
    return &events_[index];
  }

  const TimelineEvent* At(intptr_t index) const {
    ASSERT(index >= 0);
    ASSERT(index < kBlockSize);
    return &events_[index];
  }

  // Attempt to sniff the timestamp from the first event.
  int64_t LowerTimeBound() const;

  // Call Reset on all events and set length to 0.
  void Reset();

  // Only safe to access under the recorder's lock.
  inline bool InUseLocked() const;

  // Only safe to access under the recorder's lock.
  inline bool ContainsEventsThatCanBeSerializedLocked() const;

 protected:
#ifndef PRODUCT
  void PrintJSON(JSONStream* stream) const;
#endif

  // Only safe to call from the thread that owns this block, while the thread is
  // holding its block lock.
  TimelineEvent* StartEventLocked();

  TimelineEvent events_[kBlockSize];
  TimelineEventBlock* next_;
  intptr_t length_;
  intptr_t block_index_;

  // Only safe to access under the recorder's lock.
  OSThread* current_owner_;
  bool in_use_;

  void Open();

  friend class Thread;
  friend class TimelineEventRecorder;
  friend class TimelineEventEndlessRecorder;
  friend class TimelineEventRingRecorder;
  friend class TimelineEventStartupRecorder;
  friend class TimelineEventPlatformRecorder;
  friend class TimelineTestHelper;
  friend class JSONStream;

 private:
  void Finish();

  DISALLOW_COPY_AND_ASSIGN(TimelineEventBlock);
};

class TimelineEventFilter : public ValueObject {
 public:
  TimelineEventFilter(int64_t time_origin_micros = -1,
                      int64_t time_extent_micros = -1);

  virtual ~TimelineEventFilter();

  virtual bool IncludeEvent(TimelineEvent* event) const {
    if (event == nullptr) {
      return false;
    }
    return event->IsValid();
  }

  int64_t time_origin_micros() const { return time_origin_micros_; }

  int64_t time_extent_micros() const { return time_extent_micros_; }

 private:
  int64_t time_origin_micros_;
  int64_t time_extent_micros_;
};

class IsolateTimelineEventFilter : public TimelineEventFilter {
 public:
  explicit IsolateTimelineEventFilter(Dart_Port isolate_id,
                                      int64_t time_origin_micros = -1,
                                      int64_t time_extent_micros = -1);

  bool IncludeEvent(TimelineEvent* event) const final {
    return event->IsValid() && (event->isolate_id() == isolate_id_);
  }

 private:
  Dart_Port isolate_id_;
};

// Recorder of |TimelineEvent|s.
class TimelineEventRecorder : public MallocAllocated {
 public:
  TimelineEventRecorder();
  virtual ~TimelineEventRecorder();

  // Interface method(s) which must be implemented.
#ifndef PRODUCT
  virtual void PrintJSON(JSONStream* js, TimelineEventFilter* filter) = 0;
#if defined(SUPPORT_PERFETTO)
  /*
   * Prints a PerfettoTimeline service response into |js|.
   */
  virtual void PrintPerfettoTimeline(JSONStream* js,
                                     const TimelineEventFilter& filter) = 0;
#endif  // defined(SUPPORT_PERFETTO)
  virtual void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter) = 0;
#endif  // !defined(PRODUCT)
  virtual const char* name() const = 0;
  virtual intptr_t Size() = 0;
  // Only safe to call when holding |lock_|.
  virtual TimelineEventBlock* GetNewBlockLocked() = 0;
  void FinishBlock(TimelineEventBlock* block);
  // This function must be called at least once for each thread that corresponds
  // to a track in the trace.
  void AddTrackMetadataBasedOnThread(const intptr_t process_id,
                                     const intptr_t trace_id,
                                     const char* thread_name);
  void AddAsyncTrackMetadataBasedOnEvent(const TimelineEvent& event);

 protected:
  SimpleHashMap& track_uuid_to_track_metadata() {
    return track_uuid_to_track_metadata_;
  }
  SimpleHashMap& async_track_uuid_to_track_metadata() {
    return async_track_uuid_to_track_metadata_;
  }
#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
  protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket>& packet() {
    return packet_;
  }
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

#ifndef PRODUCT
  void WriteTo(const char* directory);
#endif

  // Interface method(s) which must be implemented.
  virtual TimelineEvent* StartEvent() = 0;
  virtual void CompleteEvent(TimelineEvent* event) = 0;
  // Only safe to call when holding |lock_|.
  virtual TimelineEventBlock* GetHeadBlockLocked() = 0;
  // Only safe to call when holding |lock_|.
  virtual void ClearLocked() = 0;

  // Utility method(s).
#ifndef PRODUCT
  void PrintJSONMeta(const JSONArray& jsarr_events);
#if defined(SUPPORT_PERFETTO)
  /*
   * Appends metadata about the timeline in Perfetto's proto format to
   * |jsonBase64String|.
   */
  void PrintPerfettoMeta(JSONBase64String* jsonBase64String);
#endif  // defined(SUPPORT_PERFETTO)
#endif  // !defined(PRODUCT)
  TimelineEvent* ThreadBlockStartEvent();
  void ThreadBlockCompleteEvent(TimelineEvent* event);

  void ResetTimeTracking();
  void ReportTime(int64_t micros);
  int64_t TimeOriginMicros() const;
  int64_t TimeExtentMicros() const;

  Mutex lock_;
  int64_t time_low_micros_;
  int64_t time_high_micros_;

  friend class TimelineEvent;
  friend class TimelineEventBlock;
  friend class TimelineStream;
  friend class TimelineTestHelper;
  friend class Timeline;
  friend class OSThread;

 private:
  static constexpr intptr_t kTrackUuidToTrackMetadataInitialCapacity = 1 << 4;
  Mutex track_uuid_to_track_metadata_lock_;
  SimpleHashMap track_uuid_to_track_metadata_;
  Mutex async_track_uuid_to_track_metadata_lock_;
  SimpleHashMap async_track_uuid_to_track_metadata_;
#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
  // We allocate one heap-buffered packet as a class member, because it lets us
  // continuously follow a cycle of resetting the buffer and writing its
  // contents.
  protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket> packet_;
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

  DISALLOW_COPY_AND_ASSIGN(TimelineEventRecorder);
};

// An abstract recorder that stores events in a buffer of fixed capacity.
class TimelineEventFixedBufferRecorder : public TimelineEventRecorder {
 public:
  static constexpr intptr_t kDefaultCapacity = 32 * KB;  // Number of events.

  explicit TimelineEventFixedBufferRecorder(intptr_t capacity);
  virtual ~TimelineEventFixedBufferRecorder();

#ifndef PRODUCT
  void PrintJSON(JSONStream* js, TimelineEventFilter* filter) final;
#if defined(SUPPORT_PERFETTO)
  void PrintPerfettoTimeline(JSONStream* js,
                             const TimelineEventFilter& filter) final;
#endif  // defined(SUPPORT_PERFETTO)
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter) final;
#endif  // !defined(PRODUCT)

  intptr_t Size();

 protected:
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
  TimelineEventBlock* GetHeadBlockLocked();
  // Only safe to call when holding |lock_|.
  intptr_t FindOldestBlockIndexLocked() const;
  void ClearLocked();

#ifndef PRODUCT
  void PrintJSONEvents(const JSONArray& array,
                       const TimelineEventFilter& filter);
#if defined(SUPPORT_PERFETTO)
  void PrintPerfettoEvents(JSONBase64String* jsonBase64String,
                           const TimelineEventFilter& filter);
#endif  // defined(SUPPORT_PERFETTO)
#endif  // !defined(PRODUCT)

  VirtualMemory* memory_;
  TimelineEventBlock* blocks_;
  intptr_t capacity_;
  intptr_t num_blocks_;
  intptr_t block_cursor_;

 private:
#if !defined(PRODUCT)
  inline void PrintEventsCommon(
      const TimelineEventFilter& filter,
      std::function<void(const TimelineEvent&)>&& print_impl);
#endif  // !defined(PRODUCT)
};

// A recorder that stores events in a buffer of fixed capacity. When the buffer
// is full, new events overwrite old events.
class TimelineEventRingRecorder : public TimelineEventFixedBufferRecorder {
 public:
  explicit TimelineEventRingRecorder(intptr_t capacity = kDefaultCapacity)
      : TimelineEventFixedBufferRecorder(capacity) {}
  virtual ~TimelineEventRingRecorder() {}

  const char* name() const { return RING_RECORDER_NAME; }

 protected:
  TimelineEventBlock* GetNewBlockLocked();
};

// A recorder that stores events in a buffer of fixed capacity. When the buffer
// is full, new events are dropped.
class TimelineEventStartupRecorder : public TimelineEventFixedBufferRecorder {
 public:
  explicit TimelineEventStartupRecorder(intptr_t capacity = kDefaultCapacity)
      : TimelineEventFixedBufferRecorder(capacity) {}
  virtual ~TimelineEventStartupRecorder() {}

  const char* name() const { return STARTUP_RECORDER_NAME; }

 protected:
  TimelineEventBlock* GetNewBlockLocked();
};

// An abstract recorder that calls |OnEvent| whenever an event is complete.
// This should only be used for testing.
class TimelineEventCallbackRecorder : public TimelineEventRecorder {
 public:
  TimelineEventCallbackRecorder();
  virtual ~TimelineEventCallbackRecorder();

#ifndef PRODUCT
  void PrintJSON(JSONStream* js, TimelineEventFilter* filter) final;
#if defined(SUPPORT_PERFETTO)
  void PrintPerfettoTimeline(JSONStream* js,
                             const TimelineEventFilter& filter) final;
#endif  // defined(SUPPORT_PERFETTO)
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter) final;
#endif  // !defined(PRODUCT)

  // Called when |event| is completed. It is unsafe to keep a reference to
  // |event| as it may be freed as soon as this function returns.
  virtual void OnEvent(TimelineEvent* event) = 0;

  const char* name() const { return CALLBACK_RECORDER_NAME; }
  intptr_t Size() {
    return 0;
  }

 protected:
  TimelineEventBlock* GetNewBlockLocked() { UNREACHABLE(); }
  TimelineEventBlock* GetHeadBlockLocked() { UNREACHABLE(); }
  void ClearLocked() { ASSERT(lock_.IsOwnedByCurrentThread()); }
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
};

// A recorder that forwards completed events to the callback provided by
// Dart_SetTimelineRecorderCallback.
class TimelineEventEmbedderCallbackRecorder
    : public TimelineEventCallbackRecorder {
 public:
  TimelineEventEmbedderCallbackRecorder() {}
  virtual ~TimelineEventEmbedderCallbackRecorder() {}

  virtual void OnEvent(TimelineEvent* event);
};

// A recorder that does nothing.
class TimelineEventNopRecorder : public TimelineEventCallbackRecorder {
 public:
  TimelineEventNopRecorder() {}
  virtual ~TimelineEventNopRecorder() {}

  virtual void OnEvent(TimelineEvent* event);
};

// A recorder that stores events in chains of blocks of events.
// NOTE: This recorder will continue to allocate blocks until it exhausts
// memory.
class TimelineEventEndlessRecorder : public TimelineEventRecorder {
 public:
  TimelineEventEndlessRecorder();
  virtual ~TimelineEventEndlessRecorder();

#ifndef PRODUCT
  void PrintJSON(JSONStream* js, TimelineEventFilter* filter) final;
#if defined(SUPPORT_PERFETTO)
  void PrintPerfettoTimeline(JSONStream* js,
                             const TimelineEventFilter& filter) final;
#endif  // defined(SUPPORT_PERFETTO)
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter) final;
#endif  // !defined(PRODUCT)

  const char* name() const { return ENDLESS_RECORDER_NAME; }
  intptr_t Size() { return block_index_ * sizeof(TimelineEventBlock); }

 protected:
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
  TimelineEventBlock* GetNewBlockLocked();
  TimelineEventBlock* GetHeadBlockLocked();
  void ClearLocked();

#ifndef PRODUCT
  void PrintJSONEvents(const JSONArray& array,
                       const TimelineEventFilter& filter);
#if defined(SUPPORT_PERFETTO)
  void PrintPerfettoEvents(JSONBase64String* jsonBase64String,
                           const TimelineEventFilter& filter);
#endif  // defined(SUPPORT_PERFETTO)
#endif  // !defined(PRODUCT)

  TimelineEventBlock* head_;
  TimelineEventBlock* tail_;
  intptr_t block_index_;

 private:
#if !defined(PRODUCT)
  inline void PrintEventsCommon(
      const TimelineEventFilter& filter,
      std::function<void(const TimelineEvent&)>&& print_impl);
#endif  // !defined(PRODUCT)

  friend class TimelineTestHelper;
};

// The TimelineEventPlatformRecorder records timeline events to a platform
// specific destination. It's implementation is in the timeline_{linux,...}.cc
// files.
class TimelineEventPlatformRecorder : public TimelineEventRecorder {
 public:
  TimelineEventPlatformRecorder();
  virtual ~TimelineEventPlatformRecorder();

#ifndef PRODUCT
  void PrintJSON(JSONStream* js, TimelineEventFilter* filter) final;
#if defined(SUPPORT_PERFETTO)
  void PrintPerfettoTimeline(JSONStream* js,
                             const TimelineEventFilter& filter) final;
#endif  // defined(SUPPORT_PERFETTO)
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter) final;
#endif  // !defined(PRODUCT)

  // Called when |event| is completed. It is unsafe to keep a reference to
  // |event| as it may be freed as soon as this function returns.
  virtual void OnEvent(TimelineEvent* event) = 0;

  virtual const char* name() const = 0;

 protected:
  TimelineEventBlock* GetNewBlockLocked() { UNREACHABLE(); }
  TimelineEventBlock* GetHeadBlockLocked() { UNREACHABLE(); }
  void ClearLocked() { ASSERT(lock_.IsOwnedByCurrentThread()); }
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
};

#if defined(DART_HOST_OS_FUCHSIA)
// A recorder that sends events to Fuchsia's tracing app.
class TimelineEventFuchsiaRecorder : public TimelineEventPlatformRecorder {
 public:
  TimelineEventFuchsiaRecorder() {}
  virtual ~TimelineEventFuchsiaRecorder() {}

  const char* name() const { return FUCHSIA_RECORDER_NAME; }
  intptr_t Size() { return 0; }

 private:
  void OnEvent(TimelineEvent* event);
};
#endif  // defined(DART_HOST_OS_FUCHSIA)

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
// A recorder that writes events to Android Systrace. This class is exposed in
// this header file only so that PrintSystrace can be visible to
// timeline_test.cc.
class TimelineEventSystraceRecorder : public TimelineEventPlatformRecorder {
 public:
  TimelineEventSystraceRecorder();
  virtual ~TimelineEventSystraceRecorder();

  static intptr_t PrintSystrace(TimelineEvent* event,
                                char* buffer,
                                intptr_t buffer_size);

  const char* name() const { return SYSTRACE_RECORDER_NAME; }
  intptr_t Size() { return 0; }

 private:
  void OnEvent(TimelineEvent* event);

  int systrace_fd_;
};
#endif  // defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)

#if defined(DART_HOST_OS_MACOS)
// A recorder that sends events to Macos's tracing app. See:
// https://developer.apple.com/documentation/os/logging?language=objc
class TimelineEventMacosRecorder : public TimelineEventPlatformRecorder {
 public:
  TimelineEventMacosRecorder() API_AVAILABLE(ios(12.0), macos(10.14));
  virtual ~TimelineEventMacosRecorder() API_AVAILABLE(ios(12.0), macos(10.14));

  const char* name() const { return MACOS_RECORDER_NAME; }
  intptr_t Size() { return 0; }

 private:
  void OnEvent(TimelineEvent* event) API_AVAILABLE(ios(12.0), macos(10.14));
};
#endif  // defined(DART_HOST_OS_MACOS)

class TimelineEventFileRecorderBase : public TimelineEventPlatformRecorder {
 public:
  explicit TimelineEventFileRecorderBase(const char* path);
  virtual ~TimelineEventFileRecorderBase();

  intptr_t Size() final { return 0; }
  void OnEvent(TimelineEvent* event) final { UNREACHABLE(); }
  void Drain();

 protected:
  void Write(const char* buffer, intptr_t len) const;
  void Write(const char* buffer) const { Write(buffer, strlen(buffer)); }
  void CompleteEvent(TimelineEvent* event) final;
  void ShutDown();

 private:
  virtual void DrainImpl(const TimelineEvent& event) = 0;

  Monitor monitor_;
  TimelineEvent* head_;
  TimelineEvent* tail_;
  void* file_;
  bool shutting_down_;
  bool drained_;
  ThreadJoinId thread_id_;
};

class TimelineEventFileRecorder : public TimelineEventFileRecorderBase {
 public:
  explicit TimelineEventFileRecorder(const char* path);
  virtual ~TimelineEventFileRecorder();

  const char* name() const final { return FILE_RECORDER_NAME; }

 private:
  void DrainImpl(const TimelineEvent& event) final;

  bool first_;
};

#if defined(SUPPORT_PERFETTO) && !defined(PRODUCT)
class TimelineEventPerfettoFileRecorder : public TimelineEventFileRecorderBase {
 public:
  explicit TimelineEventPerfettoFileRecorder(const char* path);
  virtual ~TimelineEventPerfettoFileRecorder();

  const char* name() const final { return PERFETTO_FILE_RECORDER_NAME; }

 private:
  void WritePacket(
      protozero::HeapBuffered<perfetto::protos::pbzero::TracePacket>* packet)
      const;
  void DrainImpl(const TimelineEvent& event) final;
};
#endif  // defined(SUPPORT_PERFETTO) && !defined(PRODUCT)

class DartTimelineEventHelpers : public AllStatic {
 public:
  // When reporting an event of type |kAsyncBegin|, |kAsyncEnd|, or
  // |kAsyncInstant|, the async ID associated with the event should be passed
  // through |id|. When reporting an event of type |kFlowBegin|, |kFlowStep|,
  // or |kFlowEnd|, the flow ID associated with the event should be passed
  // through |id|. When reporting an event of type |kBegin| or |kEnd|, the event
  // ID associated with the event should be passed through |id|. Note that this
  // event ID will only be used by the MacOS recorder.
  static void ReportTaskEvent(TimelineEvent* event,
                              int64_t id,
                              intptr_t flow_id_count,
                              std::unique_ptr<const int64_t[]>& flow_ids,
                              intptr_t type,
                              char* name,
                              char* args);
};
#endif  // defined(SUPPORT_TIMELINE)

}  // namespace dart

#endif  // RUNTIME_VM_TIMELINE_H_
