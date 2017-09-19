// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TIMELINE_H_
#define RUNTIME_VM_TIMELINE_H_

#include "include/dart_tools_api.h"

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/growable_array.h"
#include "vm/os.h"
#include "vm/os_thread.h"

namespace dart {

class JSONArray;
class JSONObject;
class JSONStream;
class Object;
class ObjectPointerVisitor;
class Isolate;
class RawArray;
class Thread;
class TimelineEvent;
class TimelineEventBlock;
class TimelineEventRecorder;
class TimelineStream;
class VirtualMemory;
class Zone;

// (name, enabled by default for isolate).
#define TIMELINE_STREAM_LIST(V)                                                \
  V(API, false)                                                                \
  V(Compiler, false)                                                           \
  V(Dart, false)                                                               \
  V(Debugger, false)                                                           \
  V(Embedder, false)                                                           \
  V(GC, false)                                                                 \
  V(Isolate, false)                                                            \
  V(VM, false)

// A stream of timeline events. A stream has a name and can be enabled or
// disabled (globally and per isolate).
class TimelineStream {
 public:
  TimelineStream();

  void Init(const char* name, bool enabled);

  const char* name() const { return name_; }

  bool enabled() const { return enabled_ != 0; }

  void set_enabled(bool enabled) { enabled_ = enabled ? 1 : 0; }

  // Records an event. Will return |NULL| if not enabled. The returned
  // |TimelineEvent| is in an undefined state and must be initialized.
  // NOTE: It is not allowed to call StartEvent again without completing
  // the first event.
  TimelineEvent* StartEvent();

  static intptr_t enabled_offset() {
    return OFFSET_OF(TimelineStream, enabled_);
  }

 private:
  const char* name_;

  // This field is accessed by generated code (intrinsic) and expects to see
  // 0 or 1. If this becomes a BitField, the generated code must be updated.
  uintptr_t enabled_;
};

class Timeline : public AllStatic {
 public:
  // Initialize timeline system. Not thread safe.
  static void InitOnce();

  // Shutdown timeline system. Not thread safe.
  static void Shutdown();

  // Access the global recorder. Not thread safe.
  static TimelineEventRecorder* recorder();

  // Reclaim all |TimelineEventBlocks|s that are cached by threads.
  static void ReclaimCachedBlocksFromThreads();

  static void Clear();

  // Print information about streams to JSON.
  static void PrintFlagsToJSON(JSONStream* json);

#define TIMELINE_STREAM_ACCESSOR(name, not_used)                               \
  static TimelineStream* Get##name##Stream() { return &stream_##name##_; }
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_ACCESSOR)
#undef TIMELINE_STREAM_ACCESSOR

#define TIMELINE_STREAM_FLAGS(name, not_used)                                  \
  static void SetStream##name##Enabled(bool enabled) {                         \
    StreamStateChange(#name, stream_##name##_.enabled(), enabled);             \
    stream_##name##_.set_enabled(enabled);                                     \
  }
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_FLAGS)
#undef TIMELINE_STREAM_FLAGS

  static void set_start_recording_cb(
      Dart_EmbedderTimelineStartRecording start_recording_cb) {
    start_recording_cb_ = start_recording_cb;
  }

  static Dart_EmbedderTimelineStartRecording get_start_recording_cb() {
    return start_recording_cb_;
  }

  static void set_stop_recording_cb(
      Dart_EmbedderTimelineStopRecording stop_recording_cb) {
    stop_recording_cb_ = stop_recording_cb;
  }

  static Dart_EmbedderTimelineStopRecording get_stop_recording_cb() {
    return stop_recording_cb_;
  }

 private:
  static void StreamStateChange(const char* stream_name, bool prev, bool curr);
  static TimelineEventRecorder* recorder_;
  static MallocGrowableArray<char*>* enabled_streams_;
  static Dart_EmbedderTimelineStartRecording start_recording_cb_;
  static Dart_EmbedderTimelineStopRecording stop_recording_cb_;

#define TIMELINE_STREAM_DECLARE(name, not_used)                                \
  static bool stream_##name##_enabled_;                                        \
  static TimelineStream stream_##name##_;
  TIMELINE_STREAM_LIST(TIMELINE_STREAM_DECLARE)
#undef TIMELINE_STREAM_DECLARE

  friend class TimelineRecorderOverride;
  friend class ReclaimBlocksIsolateVisitor;
};

struct TimelineEventArgument {
  const char* name;
  char* value;
};

class TimelineEventArguments {
 public:
  TimelineEventArguments() : buffer_(NULL), length_(0) {}
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
  enum EventType {
    kNone,
    kBegin,
    kEnd,
    kDuration,
    kInstant,
    kAsyncBegin,
    kAsyncInstant,
    kAsyncEnd,
    kCounter,
    kFlowBegin,
    kFlowStep,
    kFlowEnd,
    kMetadata,
    kNumEventTypes,
  };

  TimelineEvent();
  ~TimelineEvent();

  void Reset();

  bool IsValid() const {
    return (event_type() > kNone) && (event_type() < kNumEventTypes);
  }

  // Marks the beginning of an asynchronous operation with |async_id|.
  void AsyncBegin(const char* label,
                  int64_t async_id,
                  int64_t micros = OS::GetCurrentMonotonicMicros());
  // Marks an instantaneous event associated with |async_id|.
  void AsyncInstant(const char* label,
                    int64_t async_id,
                    int64_t micros = OS::GetCurrentMonotonicMicros());
  // Marks the end of an asynchronous operation associated with |async_id|.
  void AsyncEnd(const char* label,
                int64_t async_id,
                int64_t micros = OS::GetCurrentMonotonicMicros());

  void DurationBegin(const char* label,
                     int64_t micros = OS::GetCurrentMonotonicMicros(),
                     int64_t thread_micros = OS::GetCurrentThreadCPUMicros());
  void DurationEnd(int64_t micros = OS::GetCurrentMonotonicMicros(),
                   int64_t thread_micros = OS::GetCurrentThreadCPUMicros());

  void Instant(const char* label,
               int64_t micros = OS::GetCurrentMonotonicMicros());

  void Duration(const char* label,
                int64_t start_micros,
                int64_t end_micros,
                int64_t thread_start_micros = -1,
                int64_t thread_end_micros = -1);

  void Begin(const char* label,
             int64_t micros = OS::GetCurrentMonotonicMicros(),
             int64_t thread_micros = OS::GetCurrentThreadCPUMicros());

  void End(const char* label,
           int64_t micros = OS::GetCurrentMonotonicMicros(),
           int64_t thread_micros = OS::GetCurrentThreadCPUMicros());

  void Counter(const char* label,
               int64_t micros = OS::GetCurrentMonotonicMicros());

  void FlowBegin(const char* label,
                 int64_t async_id,
                 int64_t micros = OS::GetCurrentMonotonicMicros());
  void FlowStep(const char* label,
                int64_t async_id,
                int64_t micros = OS::GetCurrentMonotonicMicros());
  void FlowEnd(const char* label,
               int64_t async_id,
               int64_t micros = OS::GetCurrentMonotonicMicros());

  void Metadata(const char* label,
                int64_t micros = OS::GetCurrentMonotonicMicros());

  void CompleteWithPreSerializedArgs(char* args_json);

  // Get/Set the number of arguments in the event.
  intptr_t GetNumArguments() { return arguments_.length(); }
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

  bool IsFinishedDuration() const {
    return (event_type() == kDuration) && (timestamp1_ > timestamp0_);
  }

  bool HasThreadCPUTime() const;
  int64_t ThreadCPUTimeDuration() const;
  int64_t ThreadCPUTimeOrigin() const;

  int64_t TimeOrigin() const;
  int64_t AsyncId() const;
  int64_t TimeDuration() const;
  int64_t TimeEnd() const {
    ASSERT(IsFinishedDuration());
    return timestamp1_;
  }

  // The lowest time value stored in this event.
  int64_t LowTime() const;
  // The highest time value stored in this event.
  int64_t HighTime() const;

  void PrintJSON(JSONStream* stream) const;

  ThreadId thread() const { return thread_; }

  void set_thread(ThreadId tid) { thread_ = tid; }

  Dart_Port isolate_id() const { return isolate_id_; }

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

 private:
  void StreamInit(TimelineStream* stream);
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
  void set_timestamp1(int64_t value) {
    ASSERT(timestamp1_ == 0);
    timestamp1_ = value;
  }

  void set_thread_timestamp0(int64_t value) {
    ASSERT(thread_timestamp0_ == -1);
    thread_timestamp0_ = value;
  }

  void set_thread_timestamp1(int64_t value) {
    ASSERT(thread_timestamp1_ == -1);
    thread_timestamp1_ = value;
  }

  bool pre_serialized_args() const {
    return PreSerializedArgsBit::decode(state_);
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
  int64_t timestamp1_;
  int64_t thread_timestamp0_;
  int64_t thread_timestamp1_;
  TimelineEventArguments arguments_;
  uword state_;
  const char* label_;
  const char* category_;
  ThreadId thread_;
  Dart_Port isolate_id_;

  friend class TimelineEventRecorder;
  friend class TimelineEventEndlessRecorder;
  friend class TimelineEventRingRecorder;
  friend class TimelineEventStartupRecorder;
  friend class TimelineEventPlatformRecorder;
  friend class TimelineStream;
  friend class TimelineTestHelper;
  DISALLOW_COPY_AND_ASSIGN(TimelineEvent);
};

#ifndef PRODUCT
#define TIMELINE_FUNCTION_COMPILATION_DURATION(thread, name, function)         \
  TimelineDurationScope tds(thread, Timeline::GetCompilerStream(), name);      \
  if (tds.enabled()) {                                                         \
    tds.SetNumArguments(1);                                                    \
    tds.CopyArgument(0, "function",                                            \
                     function.ToLibNamePrefixedQualifiedCString());            \
  }

#define TIMELINE_FUNCTION_GC_DURATION(thread, name)                            \
  TimelineDurationScope tds(thread, Timeline::GetGCStream(), name);
#define TIMELINE_FUNCTION_GC_DURATION_BASIC(thread, name)                      \
  TIMELINE_FUNCTION_GC_DURATION(thread, name)                                  \
  tds.SetNumArguments(1);                                                      \
  tds.CopyArgument(0, "mode", "basic");
#else
#define TIMELINE_FUNCTION_COMPILATION_DURATION(thread, name, function)
#define TIMELINE_FUNCTION_GC_DURATION(thread, name)
#define TIMELINE_FUNCTION_GC_DURATION_BASIC(thread, name)
#endif  // !PRODUCT

// See |TimelineDurationScope| and |TimelineBeginEndScope|.
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

  TimelineEventArgument* arguments() const { return arguments_.buffer(); }

  intptr_t arguments_length() const { return arguments_.length(); }

  TimelineStream* stream() const { return stream_; }

  virtual ~TimelineEventScope();

  void StealArguments(TimelineEvent* event);

 private:
  void Init();

  TimelineStream* stream_;
  const char* label_;
  TimelineEventArguments arguments_;
  bool enabled_;

  DISALLOW_COPY_AND_ASSIGN(TimelineEventScope);
};

class TimelineDurationScope : public TimelineEventScope {
 public:
  TimelineDurationScope(TimelineStream* stream, const char* label);

  TimelineDurationScope(Thread* thread,
                        TimelineStream* stream,
                        const char* label);

  virtual ~TimelineDurationScope();

 private:
  int64_t timestamp_;
  int64_t thread_timestamp_;

  DISALLOW_COPY_AND_ASSIGN(TimelineDurationScope);
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
class TimelineEventBlock {
 public:
  static const intptr_t kBlockSize = 64;

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

  // Returns false if |this| violates any of the following invariants:
  // - events in the block come from one thread.
  // - events have monotonically increasing timestamps.
  bool CheckBlock();

  // Call Reset on all events and set length to 0.
  void Reset();

  // Only safe to access under the recorder's lock.
  bool in_use() const { return in_use_; }

  // Only safe to access under the recorder's lock.
  ThreadId thread_id() const { return thread_id_; }

 protected:
  void PrintJSON(JSONStream* stream) const;

  TimelineEvent* StartEvent();

  TimelineEvent events_[kBlockSize];
  TimelineEventBlock* next_;
  intptr_t length_;
  intptr_t block_index_;

  // Only accessed under the recorder's lock.
  ThreadId thread_id_;
  bool in_use_;

  void Open();
  void Finish();

  friend class Thread;
  friend class TimelineEventRecorder;
  friend class TimelineEventEndlessRecorder;
  friend class TimelineEventRingRecorder;
  friend class TimelineEventStartupRecorder;
  friend class TimelineEventPlatformRecorder;
  friend class TimelineTestHelper;
  friend class JSONStream;

 private:
  DISALLOW_COPY_AND_ASSIGN(TimelineEventBlock);
};

class TimelineEventFilter : public ValueObject {
 public:
  TimelineEventFilter(int64_t time_origin_micros = -1,
                      int64_t time_extent_micros = -1);

  virtual ~TimelineEventFilter();

  virtual bool IncludeBlock(TimelineEventBlock* block) {
    if (block == NULL) {
      return false;
    }
    // Not empty and not in use.
    return !block->IsEmpty() && !block->in_use();
  }

  virtual bool IncludeEvent(TimelineEvent* event) {
    if (event == NULL) {
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

  bool IncludeBlock(TimelineEventBlock* block) {
    if (block == NULL) {
      return false;
    }
    // Not empty, not in use, and isolate match.
    return !block->IsEmpty() && !block->in_use();
  }

  bool IncludeEvent(TimelineEvent* event) {
    return event->IsValid() && (event->isolate_id() == isolate_id_);
  }

 private:
  Dart_Port isolate_id_;
};

// Recorder of |TimelineEvent|s.
class TimelineEventRecorder {
 public:
  TimelineEventRecorder();
  virtual ~TimelineEventRecorder() {}

  TimelineEventBlock* GetNewBlock();

  // Interface method(s) which must be implemented.
  virtual void PrintJSON(JSONStream* js, TimelineEventFilter* filter) = 0;
  virtual void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter) = 0;
  virtual const char* name() const = 0;
  int64_t GetNextAsyncId();

  void FinishBlock(TimelineEventBlock* block);

 protected:
  void WriteTo(const char* directory);

  // Interface method(s) which must be implemented.
  virtual TimelineEvent* StartEvent() = 0;
  virtual void CompleteEvent(TimelineEvent* event) = 0;
  virtual TimelineEventBlock* GetHeadBlockLocked() = 0;
  virtual TimelineEventBlock* GetNewBlockLocked() = 0;
  virtual void Clear() = 0;

  // Utility method(s).
  void PrintJSONMeta(JSONArray* array) const;
  TimelineEvent* ThreadBlockStartEvent();
  void ThreadBlockCompleteEvent(TimelineEvent* event);

  void ResetTimeTracking();
  void ReportTime(int64_t micros);
  int64_t TimeOriginMicros() const;
  int64_t TimeExtentMicros() const;

  Mutex lock_;
  uintptr_t async_id_;
  int64_t time_low_micros_;
  int64_t time_high_micros_;

  friend class TimelineEvent;
  friend class TimelineEventBlockIterator;
  friend class TimelineStream;
  friend class TimelineTestHelper;
  friend class Timeline;

 private:
  DISALLOW_COPY_AND_ASSIGN(TimelineEventRecorder);
};

// An abstract recorder that stores events in a buffer of fixed capacity.
class TimelineEventFixedBufferRecorder : public TimelineEventRecorder {
 public:
  static const intptr_t kDefaultCapacity = 8192;

  explicit TimelineEventFixedBufferRecorder(intptr_t capacity);
  virtual ~TimelineEventFixedBufferRecorder();

  void PrintJSON(JSONStream* js, TimelineEventFilter* filter);
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter);

 protected:
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
  TimelineEventBlock* GetHeadBlockLocked();
  intptr_t FindOldestBlockIndex() const;
  void Clear();

  void PrintJSONEvents(JSONArray* array, TimelineEventFilter* filter);

  VirtualMemory* memory_;
  TimelineEventBlock* blocks_;
  intptr_t capacity_;
  intptr_t num_blocks_;
  intptr_t block_cursor_;
};

// A recorder that stores events in a buffer of fixed capacity. When the buffer
// is full, new events overwrite old events.
class TimelineEventRingRecorder : public TimelineEventFixedBufferRecorder {
 public:
  explicit TimelineEventRingRecorder(intptr_t capacity = kDefaultCapacity)
      : TimelineEventFixedBufferRecorder(capacity) {}
  virtual ~TimelineEventRingRecorder() {}

  const char* name() const { return "Ring"; }

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

  const char* name() const { return "Startup"; }

 protected:
  TimelineEventBlock* GetNewBlockLocked();
};

// An abstract recorder that calls |OnEvent| whenever an event is complete.
// This should only be used for testing.
class TimelineEventCallbackRecorder : public TimelineEventRecorder {
 public:
  TimelineEventCallbackRecorder();
  virtual ~TimelineEventCallbackRecorder();

  void PrintJSON(JSONStream* js, TimelineEventFilter* filter);
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter);

  // Called when |event| is completed. It is unsafe to keep a reference to
  // |event| as it may be freed as soon as this function returns.
  virtual void OnEvent(TimelineEvent* event) = 0;

  const char* name() const { return "Callback"; }

 protected:
  TimelineEventBlock* GetNewBlockLocked() { return NULL; }
  TimelineEventBlock* GetHeadBlockLocked() { return NULL; }
  void Clear() {}
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
};

// A recorder that stores events in chains of blocks of events.
// NOTE: This recorder will continue to allocate blocks until it exhausts
// memory.
class TimelineEventEndlessRecorder : public TimelineEventRecorder {
 public:
  TimelineEventEndlessRecorder();
  virtual ~TimelineEventEndlessRecorder();

  void PrintJSON(JSONStream* js, TimelineEventFilter* filter);
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter);

  const char* name() const { return "Endless"; }

 protected:
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
  TimelineEventBlock* GetNewBlockLocked();
  TimelineEventBlock* GetHeadBlockLocked();
  void Clear();

  void PrintJSONEvents(JSONArray* array, TimelineEventFilter* filter);

  TimelineEventBlock* head_;
  intptr_t block_index_;

  friend class TimelineTestHelper;
};

// An iterator for blocks.
class TimelineEventBlockIterator {
 public:
  explicit TimelineEventBlockIterator(TimelineEventRecorder* recorder);
  ~TimelineEventBlockIterator();

  void Reset(TimelineEventRecorder* recorder);

  // Returns false when there are no more blocks.
  bool HasNext() const;

  // Returns the next block and moves forward.
  TimelineEventBlock* Next();

 private:
  TimelineEventBlock* current_;
  TimelineEventRecorder* recorder_;
};

// The TimelineEventPlatformRecorder records timeline events to a platform
// specific destination. It's implementation is in the timeline_{linux,...}.cc
// files.
class TimelineEventPlatformRecorder : public TimelineEventFixedBufferRecorder {
 public:
  explicit TimelineEventPlatformRecorder(intptr_t capacity = kDefaultCapacity);
  virtual ~TimelineEventPlatformRecorder();

  static TimelineEventPlatformRecorder* CreatePlatformRecorder(
      intptr_t capacity = kDefaultCapacity);

  const char* name() const;

 protected:
  TimelineEventBlock* GetNewBlockLocked();
  virtual void CompleteEvent(TimelineEvent* event);
};

#if defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX)
// A recorder that writes events to Android Systrace. Events are also stored in
// a buffer of fixed capacity. When the buffer is full, new events overwrite
// old events. This class is exposed in this header file only so that
// PrintSystrace can be visible to timeline_test.cc.
class TimelineEventSystraceRecorder : public TimelineEventPlatformRecorder {
 public:
  explicit TimelineEventSystraceRecorder(intptr_t capacity = kDefaultCapacity);
  virtual ~TimelineEventSystraceRecorder();

  static intptr_t PrintSystrace(TimelineEvent* event,
                                char* buffer,
                                intptr_t buffer_size);

 private:
  virtual void CompleteEvent(TimelineEvent* event);

  int systrace_fd_;
};
#endif  // defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX)

class DartTimelineEventHelpers : public AllStatic {
 public:
  static void ReportTaskEvent(Thread* thread,
                              TimelineEvent* event,
                              int64_t start,
                              int64_t id,
                              const char* phase,
                              const char* category,
                              char* name,
                              char* args);

  static void ReportCompleteEvent(Thread* thread,
                                  TimelineEvent* event,
                                  int64_t start,
                                  int64_t start_cpu,
                                  const char* category,
                                  char* name,
                                  char* args);

  static void ReportFlowEvent(Thread* thread,
                              TimelineEvent* event,
                              int64_t start,
                              int64_t start_cpu,
                              const char* category,
                              char* name,
                              int64_t type,
                              int64_t flow_id,
                              char* args);

  static void ReportInstantEvent(Thread* thread,
                                 TimelineEvent* event,
                                 int64_t start,
                                 const char* category,
                                 char* name,
                                 char* args);
};

}  // namespace dart

#endif  // RUNTIME_VM_TIMELINE_H_
