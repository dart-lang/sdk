// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TIMELINE_H_
#define VM_TIMELINE_H_

#include "vm/allocation.h"
#include "vm/bitfield.h"

namespace dart {

class JSONArray;
class JSONObject;
class JSONStream;
class Object;
class ObjectPointerVisitor;
class RawArray;
class Thread;
class TimelineEvent;
class TimelineEventBlock;
class TimelineEventRecorder;
class TimelineStream;


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

 private:
  static TimelineEventRecorder* recorder_;
  static TimelineStream* vm_stream_;

  friend class TimelineRecorderOverride;
};


// You should get a |TimelineEvent| from a |TimelineStream|.
class TimelineEvent {
 public:
  // Keep in sync with StateBits below.
  enum EventType {
    kNone,
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
  void AsyncBegin(const char* label, int64_t async_id);
  // Marks an instantaneous event associated with |async_id|.
  void AsyncInstant(const char* label,
                    int64_t async_id);
  // Marks the end of an asynchronous operation associated with |async_id|.
  void AsyncEnd(const char* label,
                int64_t async_id);

  void DurationBegin(const char* label);
  void DurationEnd();
  void Instant(const char* label);

  void Duration(const char* label,
                int64_t start_micros,
                int64_t end_micros);

  // Set the number of arguments in the event.
  void SetNumArguments(intptr_t length);
  // |name| must be a compile time constant. Takes ownership of |argumentp|.
  void SetArgument(intptr_t i, const char* name, char* argument);
  // |name| must be a compile time constant. Copies |argument|.
  void CopyArgument(intptr_t i, const char* name, const char* argument);
  // |name| must be a compile time constant.
  void FormatArgument(intptr_t i,
                      const char* name,
                      const char* fmt, ...) PRINTF_ATTRIBUTE(4, 5);

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

  const char* label() const {
    return label_;
  }

  // Does this duration end before |micros| ?
  bool DurationFinishedBefore(int64_t micros) const {
    return TimeEnd() <= micros;
  }

  // Does this duration fully contain |other| ?
  bool DurationContains(TimelineEvent* other) const {
    ASSERT(IsFinishedDuration());
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

 private:
  struct TimelineEventArgument {
    const char* name;
    char* value;
  };

  int64_t timestamp0_;
  int64_t timestamp1_;
  TimelineEventArgument* arguments_;
  intptr_t arguments_length_;
  uword state_;
  const char* label_;
  const char* category_;
  ThreadId thread_;
  Isolate* isolate_;

  void FreeArguments();

  void StreamInit(TimelineStream* stream);
  void Init(EventType event_type, const char* label);

  void set_event_type(EventType event_type) {
    state_ = EventTypeField::update(event_type, state_);
  }

  enum StateBits {
    kEventTypeBit = 0,
    // reserve 4 bits for type.
    kNextBit = 4,
  };

  class EventTypeField : public BitField<EventType, kEventTypeBit, 4> {};

  friend class TimelineTestHelper;
  friend class TimelineStream;
  DISALLOW_COPY_AND_ASSIGN(TimelineEvent);
};


// A stream of timeline events. A stream has a name and can be enabled or
// disabled.
class TimelineStream {
 public:
  TimelineStream();

  void Init(const char* name, bool enabled);

  const char* name() const {
    return name_;
  }

  bool enabled() const {
    return enabled_;
  }

  void set_enabled(bool enabled) {
    enabled_ = enabled;
  }

  // Records an event. Will return |NULL| if not enabled. The returned
  // |TimelineEvent| is in an undefined state and must be initialized.
  TimelineEvent* StartEvent();

 private:
  const char* name_;
  bool enabled_;
};


// (name, enabled by default).
#define ISOLATE_TIMELINE_STREAM_LIST(V)                                        \
  V(API, false)                                                                \
  V(Compiler, false)                                                           \
  V(Embedder, false)                                                           \
  V(GC, false)                                                                 \
  V(Isolate, false)                                                            \


#define TIMELINE_FUNCTION_COMPILATION_DURATION(thread, suffix, function)       \
  TimelineDurationScope tds(thread,                                            \
                            thread->isolate()->GetCompilerStream(),            \
                            "Compile" suffix);                                 \
  if (tds.enabled()) {                                                         \
    tds.SetNumArguments(1);                                                    \
    tds.CopyArgument(                                                          \
        0,                                                                     \
        "function",                                                            \
        const_cast<char*>(function.ToLibNamePrefixedQualifiedCString()));      \
  }


// TODO(johnmccutchan): TimelineDurationScope should only allocate the
// event when complete.
class TimelineDurationScope : public StackResource {
 public:
  TimelineDurationScope(Isolate* isolate,
                        TimelineStream* stream,
                        const char* label)
      : StackResource(isolate) {
    Init(stream, label);
  }

  TimelineDurationScope(Thread* thread,
                        TimelineStream* stream,
                        const char* label)
      : StackResource(thread) {
    Init(stream, label);
  }

  TimelineDurationScope(TimelineStream* stream,
                        const char* label)
      : StackResource(reinterpret_cast<Thread*>(NULL)) {
    Init(stream, label);
  }

  void Init(TimelineStream* stream, const char* label) {
    event_ = stream->StartEvent();
    if (event_ == NULL) {
      return;
    }
    event_->DurationBegin(label);
  }

  bool enabled() const {
    return event_ != NULL;
  }

  void SetNumArguments(intptr_t length) {
    if (event_ == NULL) {
      return;
    }
    event_->SetNumArguments(length);
  }

  void SetArgument(intptr_t i, const char* name, char* argument) {
    if (event_ == NULL) {
      return;
    }
    event_->SetArgument(i, name, argument);
  }

  void CopyArgument(intptr_t i, const char* name, const char* argument) {
    if (event_ == NULL) {
      return;
    }
    event_->CopyArgument(i, name, argument);
  }

  void FormatArgument(intptr_t i,
                      const char* name,
                      const char* fmt, ...)  PRINTF_ATTRIBUTE(4, 5);

  ~TimelineDurationScope() {
    if (event_ == NULL) {
      return;
    }
    event_->DurationEnd();
    event_->Complete();
  }

 private:
  TimelineEvent* event_;
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

  // Attempt to sniff a thread id from the first event.
  ThreadId thread() const;
  // Attempt to sniff the timestamp from the first event.
  int64_t LowerTimeBound() const;

  // Returns false if |this| violates any of the following invariants:
  // - events in the block come from one thread.
  // - events have monotonically increasing timestamps.
  bool CheckBlock();

  // Call Reset on all events and set length to 0.
  void Reset();

  // Only safe to access under the recorder's lock.
  bool open() const {
    return open_;
  }

  // Only safe to access under the recorder's lock.
  Isolate* isolate() const {
    return isolate_;
  }

 protected:
  TimelineEvent* StartEvent();

  TimelineEvent events_[kBlockSize];
  TimelineEventBlock* next_;
  intptr_t length_;
  intptr_t block_index_;

  // Only accessed under the recorder's lock.
  Isolate* isolate_;
  bool open_;

  void Open(Isolate* isolate);
  void Finish();

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
  TimelineEventFilter();
  virtual ~TimelineEventFilter();

  virtual bool IncludeBlock(TimelineEventBlock* block) {
    if (block == NULL) {
      return false;
    }
    // Not empty and not open.
    return !block->IsEmpty() && !block->open();
  }

  virtual bool IncludeEvent(TimelineEvent* event) {
    if (event == NULL) {
      return false;
    }
    return event->IsValid();
  }

 private:
};


class IsolateTimelineEventFilter : public TimelineEventFilter {
 public:
  explicit IsolateTimelineEventFilter(Isolate* isolate);

  bool IncludeBlock(TimelineEventBlock* block) {
    if (block == NULL) {
      return false;
    }
    // Not empty, not open, and isolate match.
    return !block->IsEmpty() &&
           (block->isolate() == isolate_);
  }

 private:
  Isolate* isolate_;
};


// Recorder of |TimelineEvent|s.
class TimelineEventRecorder {
 public:
  TimelineEventRecorder();
  virtual ~TimelineEventRecorder() {}

  TimelineEventBlock* GetNewBlock();

  // Interface method(s) which must be implemented.
  virtual void PrintJSON(JSONStream* js, TimelineEventFilter* filter) = 0;

  int64_t GetNextAsyncId();

 protected:
  void WriteTo(const char* directory);

  // Interface method(s) which must be implemented.
  virtual TimelineEvent* StartEvent() = 0;
  virtual void CompleteEvent(TimelineEvent* event) = 0;
  virtual TimelineEventBlock* GetHeadBlockLocked() = 0;
  virtual TimelineEventBlock* GetNewBlockLocked(Isolate* isolate) = 0;

  // Utility method(s).
  void PrintJSONMeta(JSONArray* array) const;
  TimelineEvent* ThreadBlockStartEvent();
  TimelineEvent* GlobalBlockStartEvent();

  Mutex lock_;
  // Only accessed under |lock_|.
  TimelineEventBlock* global_block_;
  void FinishGlobalBlock();

  uintptr_t async_id_;

  friend class ThreadRegistry;
  friend class TimelineEvent;
  friend class TimelineEventBlockIterator;
  friend class TimelineStream;
  friend class TimelineTestHelper;
  friend class Timeline;
  friend class Isolate;

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

 protected:
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
  TimelineEventBlock* GetHeadBlockLocked();
  intptr_t FindOldestBlockIndex() const;
  TimelineEventBlock* GetNewBlockLocked(Isolate* isolate);

  void PrintJSONEvents(JSONArray* array, TimelineEventFilter* filter) const;

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

  // Called when |event| is ready to be streamed. It is unsafe to keep a
  // reference to |event| as it may be freed as soon as this function returns.
  virtual void StreamEvent(TimelineEvent* event) = 0;

 protected:
  TimelineEventBlock* GetNewBlockLocked(Isolate* isolate) {
    return NULL;
  }
  TimelineEventBlock* GetHeadBlockLocked() {
    return NULL;
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

  // NOTE: Calling this while threads are filling in their blocks is not safe
  // and there are no checks in place to ensure that doesn't happen.
  // TODO(koda): Add isolate count to |ThreadRegistry| and verify that it is 1.
  void PrintJSON(JSONStream* js, TimelineEventFilter* filter);

 protected:
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
  TimelineEventBlock* GetNewBlockLocked(Isolate* isolate);
  TimelineEventBlock* GetHeadBlockLocked();

  void PrintJSONEvents(JSONArray* array, TimelineEventFilter* filter) const;

  // Useful only for testing. Only works for one thread.
  void Clear();

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
