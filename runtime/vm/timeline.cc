// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstdlib>

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/object.h"
#include "vm/thread.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(bool, trace_timeline, false, "Timeline trace");

TimelineEvent::TimelineEvent()
    : timestamp0_(0),
      timestamp1_(0),
      arguments_(NULL),
      arguments_length_(0),
      state_(0),
      label_(NULL),
      stream_(NULL),
      thread_(NULL) {
}


TimelineEvent::~TimelineEvent() {
  Reset();
}


void TimelineEvent::Reset() {
  set_event_type(kNone);
  thread_ = NULL;
  stream_ = NULL;
  label_ = NULL;
  FreeArguments();
}


int64_t TimelineEvent::AsyncBegin(const char* label) {
  Init(kAsyncBegin, label);
  timestamp0_ = OS::GetCurrentTimeMicros();
  ASSERT(stream_ != NULL);
  int64_t async_id = stream_->GetNextSeq();
  // Overload timestamp1_ with the async_id.
  timestamp1_ = async_id;
  return async_id;
}


void TimelineEvent::AsyncInstant(const char* label,
                                 int64_t async_id) {
  Init(kAsyncInstant, label);
  timestamp0_ = OS::GetCurrentTimeMicros();
  // Overload timestamp1_ with the async_id.
  timestamp1_ = async_id;
}


void TimelineEvent::AsyncEnd(const char* label,
                             int64_t async_id) {
  Init(kAsyncEnd, label);
  timestamp0_ = OS::GetCurrentTimeMicros();
  // Overload timestamp1_ with the async_id.
  timestamp1_ = async_id;
}


void TimelineEvent::DurationBegin(const char* label) {
  Init(kDuration, label);
  timestamp0_ = OS::GetCurrentTimeMicros();
}


void TimelineEvent::DurationEnd() {
  timestamp1_ = OS::GetCurrentTimeMicros();
}


void TimelineEvent::Instant(const char* label) {
  Init(kInstant, label);
  timestamp0_ = OS::GetCurrentTimeMicros();
}


void TimelineEvent::Duration(const char* label,
                             int64_t start_micros,
                             int64_t end_micros) {
  Init(kDuration, label);
  timestamp0_ = start_micros;
  timestamp1_ = end_micros;
}


void TimelineEvent::SetNumArguments(intptr_t length) {
  // Cannot call this twice.
  ASSERT(arguments_ == NULL);
  ASSERT(arguments_length_ == 0);
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


void TimelineEvent::FormatArgument(intptr_t i, const char* name,
                                   const char* fmt, ...) {
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


void TimelineEvent::Complete() {
  stream_->CompleteEvent(this);
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
  ASSERT(stream != NULL);
  stream_ = stream;
}


void TimelineEvent::Init(EventType event_type,
                         const char* label) {
  ASSERT(label != NULL);
  set_event_type(event_type);
  timestamp0_ = 0;
  timestamp1_ = 0;
  thread_ = Thread::Current();
  label_ = label;
  FreeArguments();
}


static int64_t GetPid(Isolate* isolate) {
  // Some mapping from Isolate* to an integer process id.
  // TODO(Cutch): Investigate if process ids can be strings.
  return static_cast<int64_t>(reinterpret_cast<uintptr_t>(isolate));
}


static int64_t GetTid(Thread* thread) {
  // Some mapping from Thread* to an integer thread id.
  // TODO(Cutch): Investigate if process ids can be strings.
  return static_cast<int64_t>(reinterpret_cast<uintptr_t>(thread));
}


void TimelineEvent::PrintJSON(JSONStream* stream) const {
  JSONObject obj(stream);
  int64_t pid = GetPid(Isolate::Current());
  int64_t tid = GetTid(thread_);
  obj.AddProperty("name", label_);
  obj.AddProperty("cat", stream_->name());
  obj.AddProperty64("tid", tid);
  obj.AddProperty64("pid", pid);
  obj.AddProperty("ts", static_cast<double>(TimeOrigin()));

  switch (event_type()) {
    case kDuration: {
      obj.AddProperty("ph", "X");
      obj.AddProperty("dur", static_cast<double>(TimeDuration()));
    }
    break;
    case kInstant: {
      obj.AddProperty("ph", "i");
      obj.AddProperty("s", "p");
    }
    break;
    case kAsyncBegin: {
      obj.AddProperty("ph", "b");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    }
    break;
    case kAsyncInstant: {
      obj.AddProperty("ph", "n");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    }
    break;
    case kAsyncEnd: {
      obj.AddProperty("ph", "e");
      obj.AddPropertyF("id", "%" Px64 "", AsyncId());
    }
    break;
    default:
      UNIMPLEMENTED();
  }
  {
    JSONObject args(&obj, "args");
    for (intptr_t i = 0; i < arguments_length_; i++) {
      const TimelineEventArgument& arg = arguments_[i];
      args.AddProperty(arg.name, arg.value);
    }
  }
}


int64_t TimelineEvent::TimeOrigin() const {
  return timestamp0_;
}


int64_t TimelineEvent::AsyncId() const {
  return timestamp1_;
}


int64_t TimelineEvent::TimeDuration() const {
  if (timestamp1_ == 0) {
    // This duration is still open, use current time as end.
    return OS::GetCurrentTimeMicros() - timestamp0_;
  }
  return timestamp1_ - timestamp0_;
}


TimelineStream::TimelineStream()
    : recorder_(NULL),
      name_(NULL),
      enabled_(false),
      seq_(0) {
}


void TimelineStream::Init(const char* name, bool enabled) {
  name_ = name;
  enabled_ = enabled;
}


TimelineEvent* TimelineStream::StartEvent(const Object& obj) {
  if (!enabled_ || (recorder_ == NULL)) {
    return NULL;
  }
  ASSERT(name_ != NULL);
  ASSERT(recorder_ != NULL);
  TimelineEvent* event = recorder_->StartEvent(obj);
  if (event != NULL) {
    event->StreamInit(this);
  }
  return event;
}


TimelineEvent* TimelineStream::StartEvent() {
  if (!enabled_ || (recorder_ == NULL)) {
    return NULL;
  }
  ASSERT(name_ != NULL);
  TimelineEvent* event = recorder_->StartEvent();
  if (event != NULL) {
    event->StreamInit(this);
  }
  return event;
}


void TimelineStream::CompleteEvent(TimelineEvent* event) {
  if (!enabled_ || (recorder_ == NULL)) {
    return;
  }
  recorder_->CompleteEvent(event);
}


int64_t TimelineStream::GetNextSeq() {
  seq_++;
  if (seq_ < 0) {
    seq_ = 0;
  }
  return seq_;
}


void TimelineDurationScope::FormatArgument(intptr_t i,
                                           const char* name,
                                           const char* fmt, ...) {
  if (event_ == NULL) {
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

  event_->SetArgument(i, name, buffer);
}


TimelineEventRecorder::TimelineEventRecorder() {
}


void TimelineEventRecorder::PrintJSONMeta(JSONArray* events) const {
  Isolate* isolate = Isolate::Current();
  JSONObject obj(events);
  int64_t pid = GetPid(isolate);
  obj.AddProperty("ph", "M");
  obj.AddProperty64("pid", pid);
  obj.AddProperty("name", "process_name");
  {
    JSONObject args(&obj, "args");
    args.AddProperty("name", isolate->debugger_name());
  }
}


void TimelineEventRecorder::WriteTo(const char* directory) {
  Isolate* isolate = Isolate::Current();

  Dart_FileOpenCallback file_open = Isolate::file_open_callback();
  Dart_FileWriteCallback file_write = Isolate::file_write_callback();
  Dart_FileCloseCallback file_close = Isolate::file_close_callback();
  if ((file_open == NULL) || (file_write == NULL) || (file_close == NULL)) {
    return;
  }

  JSONStream js;
  PrintJSON(&js);

  const char* format = "%s/dart-timeline-%" Pd "-%" Pd ".json";
  intptr_t pid = OS::ProcessId();
  intptr_t len = OS::SNPrint(NULL, 0, format,
                             directory, pid, isolate->main_port());
  char* filename = Thread::Current()->zone()->Alloc<char>(len + 1);
  OS::SNPrint(filename, len + 1, format,
              directory, pid, isolate->main_port());
  void* file = (*file_open)(filename, true);
  if (file == NULL) {
    OS::Print("Failed to write timeline file: %s\n", filename);
    return;
  }
  (*file_write)(js.buffer()->buf(), js.buffer()->length(), file);
  (*file_close)(file);
}


intptr_t TimelineEventRingRecorder::SizeForCapacity(intptr_t capacity) {
  return sizeof(TimelineEvent) * capacity;
}


TimelineEventRingRecorder::TimelineEventRingRecorder(intptr_t capacity)
    : events_(NULL),
      event_objects_(Array::null()),
      cursor_(0),
      capacity_(capacity) {
  if (FLAG_trace_timeline) {
    // 32-bit: 262,144 bytes per isolate.
    // 64-bit: 393,216 bytes per isolate.
    // NOTE: Internal isolates (vm and service) do not have a timeline
    // event buffer.
    OS::Print("TimelineEventRingRecorder is %" Pd " bytes (%" Pd " events)\n",
              SizeForCapacity(capacity),
              capacity);
  }
  events_ =
      reinterpret_cast<TimelineEvent*>(calloc(capacity, sizeof(TimelineEvent)));
  const Array& array = Array::Handle(Array::New(capacity, Heap::kOld));
  event_objects_ = array.raw();
}


TimelineEventRingRecorder::~TimelineEventRingRecorder() {
  for (intptr_t i = 0; i < capacity_; i++) {
    // Clear any extra data.
    events_[i].Reset();
  }
  free(events_);
  event_objects_ = Array::null();
}


void TimelineEventRingRecorder::PrintJSONEvents(JSONArray* events) const {
  for (intptr_t i = 0; i < capacity_; i++) {
    if (events_[i].IsValid()) {
      events->AddValue(&events_[i]);
    }
  }
}


void TimelineEventRingRecorder::PrintJSON(JSONStream* js) const {
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "_Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
    PrintJSONEvents(&events);
  }
}


intptr_t TimelineEventRingRecorder::GetNextIndex() {
  uintptr_t cursor = AtomicOperations::FetchAndIncrement(&cursor_);
  return cursor % capacity_;
}


void TimelineEventRingRecorder::VisitObjectPointers(
    ObjectPointerVisitor* visitor) {
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&event_objects_));
}


TimelineEvent* TimelineEventRingRecorder::StartEvent(const Object& obj) {
  ASSERT(events_ != NULL);
  uintptr_t index = GetNextIndex();
  const Array& event_objects = Array::Handle(event_objects_);
  event_objects.SetAt(index, obj);
  return &events_[index];
}


TimelineEvent* TimelineEventRingRecorder::StartEvent() {
  ASSERT(events_ != NULL);
  uintptr_t index = GetNextIndex();
  return &events_[index];
}

void TimelineEventRingRecorder::CompleteEvent(TimelineEvent* event) {
  ASSERT(events_ != NULL);
  // no-op.
}


TimelineEventStreamingRecorder::TimelineEventStreamingRecorder() {
}


TimelineEventStreamingRecorder::~TimelineEventStreamingRecorder() {
}


void TimelineEventStreamingRecorder::PrintJSON(JSONStream* js) const {
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "_Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
  }
}

void TimelineEventStreamingRecorder::VisitObjectPointers(
    ObjectPointerVisitor* visitor) {
  // no-op.
}


TimelineEvent* TimelineEventStreamingRecorder::StartEvent(
    const Object& object) {
  // The streaming recorder does not track Dart objects.
  return StartEvent();
}


TimelineEvent* TimelineEventStreamingRecorder::StartEvent() {
  TimelineEvent* event = new TimelineEvent();
  return event;
}


void TimelineEventStreamingRecorder::CompleteEvent(TimelineEvent* event) {
  StreamEvent(event);
  delete event;
}

}  // namespace dart
