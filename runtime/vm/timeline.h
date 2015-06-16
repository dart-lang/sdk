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
class TimelineEventBuffer;
class TimelineStream;

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
  int64_t AsyncBegin(TimelineStream* stream, const char* label);
  // Marks an instantaneous event associated with |async_id|.
  void AsyncInstant(TimelineStream* stream,
                    const char* label,
                    int64_t async_id);
  // Marks the end of an asynchronous operation associated with |async_id|.
  void AsyncEnd(TimelineStream* stream,
                const char* label,
                int64_t async_id);

  void DurationBegin(TimelineStream* stream, const char* label);
  void DurationEnd();
  void Instant(TimelineStream* stream, const char* label);

  void Duration(TimelineStream* stream,
                const char* label,
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

  void Init(EventType event_type, TimelineStream* stream, const char* label);

  void set_event_type(EventType event_type) {
    state_ = EventTypeField::update(event_type, state_);
  }

  enum StateBits {
    kEventTypeBit = 0,
    // reserve 4 bits for type.
    kNextBit = 4,
  };

  class EventTypeField : public BitField<EventType, kEventTypeBit, 4> {};

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

  TimelineEventBuffer* buffer() const {
    return buffer_;
  }

  void set_buffer(TimelineEventBuffer* buffer) {
    buffer_ = buffer;
  }

  // Records an event. Will return |NULL| if not enabled. The returned
  // |TimelineEvent| is in an undefined state and must be initialized.
  // |obj| is associated with the returned |TimelineEvent|.
  TimelineEvent* RecordEvent(const Object& obj);

  // Records an event. Will return |NULL| if not enabled. The returned
  // |TimelineEvent| is in an undefined state and must be initialized.
  TimelineEvent* RecordEvent();

  int64_t GetNextSeq();

 private:
  // Buffer of TimelineEvents.
  TimelineEventBuffer* buffer_;
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
    event_ = stream->RecordEvent();
    if (event_ == NULL) {
      return;
    }
    event_->DurationBegin(stream, label);
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
  }

 private:
  TimelineEvent* event_;
};


class TimelineEventBuffer {
 public:
  static const intptr_t kDefaultCapacity = 8192;

  static intptr_t SizeForCapacity(intptr_t capacity);

  explicit TimelineEventBuffer(intptr_t capacity = kDefaultCapacity);
  ~TimelineEventBuffer();

  void PrintJSON(JSONStream* js) const;

  void WriteTo(const char* directory);

 private:
  // events_[i] and event_objects_[i] are indexed together.
  TimelineEvent* events_;
  RawArray* event_objects_;
  uintptr_t cursor_;
  intptr_t capacity_;

  void PrintJSONMeta(JSONArray* array) const;
  void PrintJSONEvents(JSONArray* array) const;

  intptr_t GetNextIndex();
  void VisitObjectPointers(ObjectPointerVisitor* visitor);
  TimelineEvent* RecordEvent(const Object& obj);
  TimelineEvent* RecordEvent();

  friend class TimelineStream;
  friend class Isolate;
  DISALLOW_COPY_AND_ASSIGN(TimelineEventBuffer);
};

}  // namespace dart

#endif  // VM_TIMELINE_H_
