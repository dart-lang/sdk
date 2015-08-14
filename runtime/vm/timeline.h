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

  // Marks the beginning of an asynchronous operation.
  // Returns |async_id| which must be passed to |AsyncInstant| and |AsyncEnd|.
  int64_t AsyncBegin(const char* label);
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
  TimelineStream* stream_;
  ThreadId thread_;

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

  TimelineEventRecorder* recorder() const {
    return recorder_;
  }

  // TODO(johnmccutchan): Disallow setting recorder after Init?
  void set_recorder(TimelineEventRecorder* recorder) {
    recorder_ = recorder;
  }

  // Records an event. Will return |NULL| if not enabled. The returned
  // |TimelineEvent| is in an undefined state and must be initialized.
  // |obj| is associated with the returned |TimelineEvent|.
  TimelineEvent* StartEvent(const Object& obj);

  // Records an event. Will return |NULL| if not enabled. The returned
  // |TimelineEvent| is in an undefined state and must be initialized.
  TimelineEvent* StartEvent();

  void CompleteEvent(TimelineEvent* event);

  int64_t GetNextSeq();

 private:
  TimelineEventRecorder* recorder_;
  const char* name_;
  bool enabled_;
  int64_t seq_;
};


// (name, enabled by default).
#define ISOLATE_TIMELINE_STREAM_LIST(V)                                        \
  V(API, false)                                                                \
  V(Compiler, false)                                                           \
  V(Embedder, false)                                                           \
  V(GC, false)                                                                 \
  V(Isolate, false)                                                            \


#define TIMELINE_FUNCTION_COMPILATION_DURATION(isolate, suffix, function)      \
  TimelineDurationScope tds(isolate,                                           \
                            isolate->GetCompilerStream(),                      \
                            "Compile" suffix);                                 \
  if (tds.enabled()) {                                                         \
    tds.SetNumArguments(1);                                                    \
    tds.CopyArgument(                                                          \
        0,                                                                     \
        "function",                                                            \
        const_cast<char*>(function.QualifiedUserVisibleNameCString()));        \
  }

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

 protected:
  TimelineEvent* StartEvent();

  TimelineEvent events_[kBlockSize];
  TimelineEventBlock* next_;
  intptr_t length_;
  intptr_t block_index_;

  friend class TimelineEventEndlessRecorder;
  friend class TimelineEventRecorder;
  friend class TimelineTestHelper;

 private:
  DISALLOW_COPY_AND_ASSIGN(TimelineEventBlock);
};


// Recorder of |TimelineEvent|s.
class TimelineEventRecorder {
 public:
  TimelineEventRecorder();
  virtual ~TimelineEventRecorder() {}

  // Interface method(s) which must be implemented.
  virtual void PrintJSON(JSONStream* js) = 0;
  virtual TimelineEventBlock* GetNewBlock() = 0;
  virtual TimelineEventBlock* GetHeadBlock() = 0;

  void WriteTo(const char* directory);

 protected:
  // Interface method(s) which must be implemented.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor) = 0;
  virtual TimelineEvent* StartEvent(const Object& object) = 0;
  virtual TimelineEvent* StartEvent() = 0;
  virtual void CompleteEvent(TimelineEvent* event) = 0;

  // Utility method(s).
  void PrintJSONMeta(JSONArray* array) const;
  TimelineEvent* ThreadBlockStartEvent();

  Mutex lock_;

  friend class TimelineEventBlockIterator;
  friend class TimelineStream;
  friend class TimelineTestHelper;
  friend class Isolate;

 private:
  DISALLOW_COPY_AND_ASSIGN(TimelineEventRecorder);
};


// A recorder that stores events in a ring buffer of fixed capacity.
// This recorder does track Dart objects.
class TimelineEventRingRecorder : public TimelineEventRecorder {
 public:
  static const intptr_t kDefaultCapacity = 8192;

  explicit TimelineEventRingRecorder(intptr_t capacity = kDefaultCapacity);
  ~TimelineEventRingRecorder();

  void PrintJSON(JSONStream* js);
  TimelineEventBlock* GetNewBlock();
  TimelineEventBlock* GetHeadBlock();

 protected:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);
  TimelineEvent* StartEvent(const Object& object);
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);

  intptr_t FindOldestBlockIndex() const;
  TimelineEventBlock* GetNewBlockLocked();

  void PrintJSONEvents(JSONArray* array) const;

  TimelineEventBlock** blocks_;
  RawArray* event_objects_;
  intptr_t capacity_;
  intptr_t num_blocks_;
  intptr_t block_cursor_;
};


// An abstract recorder that calls |StreamEvent| whenever an event is complete.
// This recorder does not track Dart objects.
class TimelineEventStreamingRecorder : public TimelineEventRecorder {
 public:
  TimelineEventStreamingRecorder();
  ~TimelineEventStreamingRecorder();

  void PrintJSON(JSONStream* js);
  TimelineEventBlock* GetNewBlock() {
    return NULL;
  }
  TimelineEventBlock* GetHeadBlock() {
    return NULL;
  }

  // Called when |event| is ready to be streamed. It is unsafe to keep a
  // reference to |event| as it may be freed as soon as this function returns.
  virtual void StreamEvent(TimelineEvent* event) = 0;

 protected:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);
  TimelineEvent* StartEvent(const Object& object);
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
};


// A recorder that stores events in chains of blocks of events.
// This recorder does not track Dart objects.
// NOTE: This recorder will continue to allocate blocks until it exhausts
// memory.
class TimelineEventEndlessRecorder : public TimelineEventRecorder {
 public:
  TimelineEventEndlessRecorder();

  // Acquire a new block of events.
  // Takes a lock.
  // Recorder owns the block and it should be filled by only one thread.
  TimelineEventBlock* GetNewBlock();

  TimelineEventBlock* GetHeadBlock();

  // It is expected that this function is only called when an isolate is
  // shutting itself down.
  // NOTE: Calling this while threads are filling in their blocks is not safe
  // and there are no checks in place to ensure that doesn't happen.
  // TODO(koda): Add isolate count to |ThreadRegistry| and verify that it is 1.
  void PrintJSON(JSONStream* js);

 protected:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);
  TimelineEvent* StartEvent(const Object& object);
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);

  TimelineEventBlock* GetNewBlockLocked();
  void PrintJSONEvents(JSONArray* array) const;

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
