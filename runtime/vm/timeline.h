// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TIMELINE_H_
#define VM_TIMELINE_H_

#include "vm/bitfield.h"

namespace dart {

class JSONStream;
class Object;
class RawArray;
class Thread;
class TimelineEvent;
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

  int64_t TimeOrigin() const;
  int64_t AsyncId() const;
  int64_t TimeDuration() const;

  void PrintJSON(JSONStream* stream) const;

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
  Thread* thread_;

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
                            "Compile"#suffix);                                 \
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


// Recorder of |TimelineEvent|s.
class TimelineEventRecorder {
 public:
  TimelineEventRecorder();
  virtual ~TimelineEventRecorder() {}

  // Interface method(s) which must be implemented.
  virtual void PrintJSON(JSONStream* js) const = 0;

  void WriteTo(const char* directory);

 protected:
  // Interface method(s) which must be implemented.
  virtual void VisitObjectPointers(ObjectPointerVisitor* visitor) = 0;
  virtual TimelineEvent* StartEvent(const Object& object) = 0;
  virtual TimelineEvent* StartEvent() = 0;
  virtual void CompleteEvent(TimelineEvent* event) = 0;

  // Utility method(s).
  void PrintJSONMeta(JSONArray* array) const;

  friend class TimelineStream;
  friend class Isolate;

 private:
  DISALLOW_COPY_AND_ASSIGN(TimelineEventRecorder);
};


// A recorder that stores events in a ring buffer of fixed capacity.
class TimelineEventRingRecorder : public TimelineEventRecorder {
 public:
  static const intptr_t kDefaultCapacity = 8192;

  static intptr_t SizeForCapacity(intptr_t capacity);

  explicit TimelineEventRingRecorder(intptr_t capacity = kDefaultCapacity);
  ~TimelineEventRingRecorder();

  void PrintJSON(JSONStream* js) const;

 protected:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);
  TimelineEvent* StartEvent(const Object& object);
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);

  void PrintJSONEvents(JSONArray* array) const;

  intptr_t GetNextIndex();

  // events_[i] and event_objects_[i] are indexed together.
  TimelineEvent* events_;
  RawArray* event_objects_;
  uintptr_t cursor_;
  intptr_t capacity_;
};


// An abstract recorder that calls |StreamEvent| whenever an event is complete.
// This recorder does not track Dart objects.
class TimelineEventStreamingRecorder : public TimelineEventRecorder {
 public:
  TimelineEventStreamingRecorder();
  ~TimelineEventStreamingRecorder();

  void PrintJSON(JSONStream* js) const;

  // Called when |event| is ready to be streamed. It is unsafe to keep a
  // reference to |event| as it may be freed as soon as this function returns.
  virtual void StreamEvent(TimelineEvent* event) = 0;

 protected:
  void VisitObjectPointers(ObjectPointerVisitor* visitor);
  TimelineEvent* StartEvent(const Object& object);
  TimelineEvent* StartEvent();
  void CompleteEvent(TimelineEvent* event);
};

}  // namespace dart

#endif  // VM_TIMELINE_H_
