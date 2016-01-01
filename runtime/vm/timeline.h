// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TIMELINE_H_
#define VM_TIMELINE_H_

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/os.h"

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
class Zone;

// (name, enabled by default for isolate).
#define ISOLATE_TIMELINE_STREAM_LIST(V)                                        \
  V(API, false)                                                                \
  V(Compiler, false)                                                           \
  V(Dart, false)                                                               \
  V(Debugger, false)                                                           \
  V(Embedder, false)                                                           \
  V(GC, false)                                                                 \
  V(Isolate, false)                                                            \

class Timeline : public AllStatic {
 public:
  // Initialize timeline system. Not thread safe.
  static void InitOnce();

  // Shutdown timeline system. Not thread safe.
  static void Shutdown();

  // Access the global recorder. Not thread safe.
  static TimelineEventRecorder* recorder();

  static bool EnableStreamByDefault(const char* stream_name);

  static TimelineStream* GetVMStream();

  static TimelineStream* GetVMApiStream();

  // Reclaim all |TimelineEventBlocks|s that are cached by threads.
  static void ReclaimCachedBlocksFromThreads();

  static void Clear();

#define ISOLATE_TIMELINE_STREAM_FLAGS(name, not_used)                          \
  static const bool* Stream##name##EnabledFlag() {                             \
    return &stream_##name##_enabled_;                                          \
  }                                                                            \
  static void SetStream##name##Enabled(bool enabled) {                         \
    stream_##name##_enabled_ = enabled;                                        \
  }
  ISOLATE_TIMELINE_STREAM_LIST(ISOLATE_TIMELINE_STREAM_FLAGS)
#undef ISOLATE_TIMELINE_STREAM_FLAGS

 private:
  static TimelineEventRecorder* recorder_;
  static TimelineStream* vm_stream_;
  static TimelineStream* vm_api_stream_;

#define ISOLATE_TIMELINE_STREAM_DECLARE_FLAG(name, not_used)                   \
  static bool stream_##name##_enabled_;
  ISOLATE_TIMELINE_STREAM_LIST(ISOLATE_TIMELINE_STREAM_DECLARE_FLAG)
#undef ISOLATE_TIMELINE_STREAM_DECLARE_FLAG

  friend class TimelineRecorderOverride;
  friend class ReclaimBlocksIsolateVisitor;
};


struct TimelineEventArgument {
  const char* name;
  char* value;
};


// You should get a |TimelineEvent| from a |TimelineStream|.
class TimelineEvent {
 public:
  // Keep in sync with StateBits below.
  enum EventType {
    kNone,
    kSerializedJSON,  // Events from Dart code.
    kBegin,
    kEnd,
    kDuration,
    kInstant,
    kAsyncBegin,
    kAsyncInstant,
    kAsyncEnd,
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
                     int64_t micros = OS::GetCurrentMonotonicMicros());
  void DurationEnd(int64_t micros = OS::GetCurrentMonotonicMicros());
  void Instant(const char* label,
               int64_t micros = OS::GetCurrentMonotonicMicros());

  void Duration(const char* label,
                int64_t start_micros,
                int64_t end_micros);

  void Begin(const char* label,
             int64_t micros = OS::GetCurrentMonotonicMicros());

  void End(const char* label,
           int64_t micros = OS::GetCurrentMonotonicMicros());

  // Completes this event with pre-serialized JSON. Copies |json|.
  void CompleteWithPreSerializedJSON(const char* json);

  // Set the number of arguments in the event.
  void SetNumArguments(intptr_t length);
  // |name| must be a compile time constant. Takes ownership of |argument|.
  void SetArgument(intptr_t i, const char* name, char* argument);
  // |name| must be a compile time constant. Copies |argument|.
  void CopyArgument(intptr_t i, const char* name, const char* argument);
  // |name| must be a compile time constant.
  void FormatArgument(intptr_t i,
                      const char* name,
                      const char* fmt, ...) PRINTF_ATTRIBUTE(4, 5);

  void StealArguments(intptr_t arguments_length,
                      TimelineEventArgument* arguments);
  // Mandatory to call when this event is completely filled out.
  void Complete();

  EventType event_type() const {
    return EventTypeField::decode(state_);
  }

  bool IsFinishedDuration() const {
    return (event_type() == kDuration) && (timestamp1_ > timestamp0_);
  }

  int64_t TimeOrigin() const;
  int64_t AsyncId() const;
  int64_t TimeDuration() const;
  int64_t TimeEnd() const {
    ASSERT(IsFinishedDuration());
    return timestamp1_;
  }

  void PrintJSON(JSONStream* stream) const;

  ThreadId thread() const {
    return thread_;
  }

  Dart_Port isolate_id() const {
    return isolate_id_;
  }

  const char* label() const {
    return label_;
  }

  // Does this duration end before |micros| ?
  bool DurationFinishedBefore(int64_t micros) const {
    return TimeEnd() <= micros;
  }

  bool IsDuration() const {
    return (event_type() == kDuration);
  }

  bool IsBegin() const {
    return (event_type() == kBegin);
  }

  bool IsEnd() const {
    return (event_type() == kEnd);
  }

  // Is this event a synchronous begin or end event?
  bool IsBeginOrEnd() const {
    return IsBegin() || IsEnd();
  }

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

  bool Within(int64_t time_origin_micros,
              int64_t time_extent_micros);

  const char* GetSerializedJSON() const;

 private:
  void FreeArguments();

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

  bool pre_serialized_json() const {
    return PreSerializedJSON::decode(state_);
  }

  void set_pre_serialized_json(bool pre_serialized_json) {
    state_ = PreSerializedJSON::update(pre_serialized_json, state_);
  }

  enum StateBits {
    kEventTypeBit = 0,  // reserve 4 bits for type.
    kPreSerializedJSON = 4,
    kNextBit = 5,
  };

  class EventTypeField : public BitField<EventType, kEventTypeBit, 4> {};
  class PreSerializedJSON :
      public BitField<bool, kPreSerializedJSON, 1> {};

  int64_t timestamp0_;
  int64_t timestamp1_;
  TimelineEventArgument* arguments_;
  intptr_t arguments_length_;
  uword state_;
  const char* label_;
  const char* category_;
  ThreadId thread_;
  Dart_Port isolate_id_;

  friend class TimelineEventRecorder;
  friend class TimelineEventEndlessRecorder;
  friend class TimelineEventRingRecorder;
  friend class TimelineStream;
  friend class TimelineTestHelper;
  DISALLOW_COPY_AND_ASSIGN(TimelineEvent);
};


// A stream of timeline events. A stream has a name and can be enabled or
// disabled (globally and per isolate).
class TimelineStream {
 public:
  TimelineStream();

  void Init(const char* name,
            bool enabled,
            const bool* globally_enabled = NULL);

  const char* name() const {
    return name_;
  }

  bool Enabled() const {
    return ((globally_enabled_ != NULL) && *globally_enabled_) ||
           enabled();
  }

  bool enabled() const {
    return enabled_;
  }

  void set_enabled(bool enabled) {
    enabled_ = enabled;
  }

  // Records an event. Will return |NULL| if not enabled. The returned
  // |TimelineEvent| is in an undefined state and must be initialized.
  // NOTE: It is not allowed to call StartEvent again without completing
  // the first event.
  TimelineEvent* StartEvent();

 private:
  const char* name_;
  bool enabled_;
  const bool* globally_enabled_;
};

#define TIMELINE_FUNCTION_COMPILATION_DURATION(thread, suffix, function)       \
  TimelineDurationScope tds(thread,                                            \
                            thread->isolate()->GetCompilerStream(),            \
                            "Compile" suffix);                                 \
  if (tds.enabled()) {                                                         \
    tds.SetNumArguments(1);                                                    \
    tds.CopyArgument(                                                          \
        0,                                                                     \
        "function",                                                            \
        function.ToLibNamePrefixedQualifiedCString());                         \
  }


// See |TimelineDurationScope| and |TimelineBeginEndScope|.
class TimelineEventScope : public StackResource {
 public:
  bool enabled() const {
    return enabled_;
  }

  void SetNumArguments(intptr_t length);

  void SetArgument(intptr_t i, const char* name, char* argument);

  void CopyArgument(intptr_t i, const char* name, const char* argument);

  void FormatArgument(intptr_t i,
                      const char* name,
                      const char* fmt, ...)  PRINTF_ATTRIBUTE(4, 5);

 protected:
  TimelineEventScope(TimelineStream* stream,
                     const char* label);

  TimelineEventScope(Thread* thread,
                     TimelineStream* stream,
                     const char* label);

  bool ShouldEmitEvent() const {
    return enabled_;
  }

  const char* label() const {
    return label_;
  }

  TimelineStream* stream() const {
    return stream_;
  }

  virtual ~TimelineEventScope();

  void StealArguments(TimelineEvent* event);

 private:
  void Init();
  void FreeArguments();

  TimelineStream* stream_;
  const char* label_;
  TimelineEventArgument* arguments_;
  intptr_t arguments_length_;
  bool enabled_;

  DISALLOW_COPY_AND_ASSIGN(TimelineEventScope);
};


class TimelineDurationScope : public TimelineEventScope {
 public:
  TimelineDurationScope(TimelineStream* stream,
                        const char* label);

  TimelineDurationScope(Thread* thread,
                        TimelineStream* stream,
                        const char* label);

  ~TimelineDurationScope();

 private:
  int64_t timestamp_;

  DISALLOW_COPY_AND_ASSIGN(TimelineDurationScope);
};


class TimelineBeginEndScope : public TimelineEventScope {
 public:
  TimelineBeginEndScope(TimelineStream* stream,
                        const char* label);

  TimelineBeginEndScope(Thread* thread,
                        TimelineStream* stream,
                        const char* label);

  ~TimelineBeginEndScope();

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

  TimelineEventBlock* next() const {
    return next_;
  }
  void set_next(TimelineEventBlock* next) {
    next_ = next;
  }

  intptr_t length() const {
    return length_;
  }

  intptr_t block_index() const {
    return block_index_;
  }

  bool IsEmpty() const {
    return length_ == 0;
  }

  bool IsFull() const {
    return length_ == kBlockSize;
  }

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
  bool in_use() const {
    return in_use_;
  }

  // Only safe to access under the recorder's lock.
  ThreadId thread_id() const {
    return thread_id_;
  }

 protected:
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
  friend class ThreadRegistry;
  friend class TimelineEventRecorder;
  friend class TimelineEventRingRecorder;
  friend class TimelineEventEndlessRecorder;
  friend class TimelineTestHelper;

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

  int64_t time_origin_micros() const {
    return time_origin_micros_;
  }

  int64_t time_extent_micros() const {
    return time_extent_micros_;
  }

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
    return event->IsValid() &&
           (event->isolate_id() == isolate_id_);
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

  Mutex lock_;
  uintptr_t async_id_;

  friend class TimelineEvent;
  friend class TimelineEventBlockIterator;
  friend class TimelineStream;
  friend class TimelineTestHelper;
  friend class Timeline;

 private:
  DISALLOW_COPY_AND_ASSIGN(TimelineEventRecorder);
};


// A recorder that stores events in a ring buffer of fixed capacity.
class TimelineEventRingRecorder : public TimelineEventRecorder {
 public:
  static const intptr_t kDefaultCapacity = 8192;

  explicit TimelineEventRingRecorder(intptr_t capacity = kDefaultCapacity);
  ~TimelineEventRingRecorder();

  void PrintJSON(JSONStream* js, TimelineEventFilter* filter);
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter);

 protected:
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
  TimelineEventBlock* GetHeadBlockLocked();
  intptr_t FindOldestBlockIndex() const;
  TimelineEventBlock* GetNewBlockLocked();
  void Clear();

  void PrintJSONEvents(JSONArray* array, TimelineEventFilter* filter);

  TimelineEventBlock** blocks_;
  intptr_t capacity_;
  intptr_t num_blocks_;
  intptr_t block_cursor_;
};


// An abstract recorder that calls |StreamEvent| whenever an event is complete.
class TimelineEventStreamingRecorder : public TimelineEventRecorder {
 public:
  TimelineEventStreamingRecorder();
  ~TimelineEventStreamingRecorder();

  void PrintJSON(JSONStream* js, TimelineEventFilter* filter);
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter);

  // Called when |event| is ready to be streamed. It is unsafe to keep a
  // reference to |event| as it may be freed as soon as this function returns.
  virtual void StreamEvent(TimelineEvent* event) = 0;

 protected:
  TimelineEventBlock* GetNewBlockLocked() {
    return NULL;
  }
  TimelineEventBlock* GetHeadBlockLocked() {
    return NULL;
  }
  void Clear() {
  }
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
};


// A recorder that stores events in chains of blocks of events.
// NOTE: This recorder will continue to allocate blocks until it exhausts
// memory.
class TimelineEventEndlessRecorder : public TimelineEventRecorder {
 public:
  TimelineEventEndlessRecorder();

  void PrintJSON(JSONStream* js, TimelineEventFilter* filter);
  void PrintTraceEvent(JSONStream* js, TimelineEventFilter* filter);

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


}  // namespace dart

#endif  // VM_TIMELINE_H_
