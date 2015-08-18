// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstdlib>

#include "vm/atomic.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/object.h"
#include "vm/thread.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(bool, trace_timeline, false, "Trace timeline backend");
DEFINE_FLAG(bool, complete_timeline, false, "Record the complete timeline");

DEFINE_FLAG(charp, timeline_dir, NULL,
            "Enable all timeline trace streams and output VM global trace "
            "into specified directory.");

void Timeline::InitOnce() {
  ASSERT(recorder_ == NULL);
  // Default to ring recorder being enabled.
  const bool use_ring_recorder = true;
  // Some flags require that we use the endless recorder.
  const bool use_endless_recorder = (FLAG_timeline_dir != NULL);
  if (use_endless_recorder) {
    recorder_ = new TimelineEventEndlessRecorder();
  } else if (use_ring_recorder) {
    recorder_ = new TimelineEventRingRecorder();
  }
  vm_stream_ = new TimelineStream();
  vm_stream_->Init("VM", EnableStreamByDefault("VM"));
}


void Timeline::Shutdown() {
  ASSERT(recorder_ != NULL);
  if (FLAG_timeline_dir != NULL) {
    recorder_->WriteTo(FLAG_timeline_dir);
  }
  delete recorder_;
  recorder_ = NULL;
  delete vm_stream_;
  vm_stream_ = NULL;
}


TimelineEventRecorder* Timeline::recorder() {
  return recorder_;
}


bool Timeline::EnableStreamByDefault(const char* stream_name) {
  // TODO(johnmccutchan): Allow for command line control over streams.
  return FLAG_timeline_dir != NULL;
}


TimelineStream* Timeline::GetVMStream() {
  ASSERT(vm_stream_ != NULL);
  return vm_stream_;
}


TimelineEventRecorder* Timeline::recorder_ = NULL;
TimelineStream* Timeline::vm_stream_ = NULL;

TimelineEvent::TimelineEvent()
    : timestamp0_(0),
      timestamp1_(0),
      arguments_(NULL),
      arguments_length_(0),
      state_(0),
      label_(NULL),
      category_(""),
      thread_(OSThread::kInvalidThreadId) {
}


TimelineEvent::~TimelineEvent() {
  Reset();
}


void TimelineEvent::Reset() {
  set_event_type(kNone);
  thread_ = OSThread::kInvalidThreadId;
  isolate_ = NULL;
  category_ = "";
  label_ = NULL;
  FreeArguments();
}


void TimelineEvent::AsyncBegin(const char* label, int64_t async_id) {
  Init(kAsyncBegin, label);
  timestamp0_ = OS::GetCurrentTimeMicros();
  // Overload timestamp1_ with the async_id.
  timestamp1_ = async_id;
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


void TimelineEvent::Init(EventType event_type,
                         const char* label) {
  ASSERT(label != NULL);
  set_event_type(event_type);
  timestamp0_ = 0;
  timestamp1_ = 0;
  thread_ = OSThread::GetCurrentThreadId();
  isolate_ = Isolate::Current();
  label_ = label;
  FreeArguments();
}


void TimelineEvent::PrintJSON(JSONStream* stream) const {
  JSONObject obj(stream);
  int64_t pid = OS::ProcessId();
  int64_t tid = OSThread::ThreadIdToIntPtr(thread_);
  obj.AddProperty("name", label_);
  obj.AddProperty("cat", category_);
  obj.AddProperty64("tid", tid);
  obj.AddProperty64("pid", pid);
  obj.AddPropertyTimeMillis("ts", TimeOrigin());

  switch (event_type()) {
    case kDuration: {
      obj.AddProperty("ph", "X");
      obj.AddPropertyTimeMillis("dur", TimeDuration());
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
    : name_(NULL),
      enabled_(false) {
}


void TimelineStream::Init(const char* name, bool enabled) {
  name_ = name;
  enabled_ = enabled;
}


TimelineEvent* TimelineStream::StartEvent() {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (!enabled_ || (recorder == NULL)) {
    return NULL;
  }
  ASSERT(name_ != NULL);
  TimelineEvent* event = recorder->StartEvent();
  if (event != NULL) {
    event->StreamInit(this);
  }
  return event;
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


TimelineEventFilter::TimelineEventFilter() {
}


TimelineEventFilter::~TimelineEventFilter() {
}


IsolateTimelineEventFilter::IsolateTimelineEventFilter(Isolate* isolate)
    : isolate_(isolate) {
}


TimelineEventRecorder::TimelineEventRecorder()
    : global_block_(NULL),
      async_id_(0) {
}


void TimelineEventRecorder::PrintJSONMeta(JSONArray* events) const {
}


TimelineEvent* TimelineEventRecorder::ThreadBlockStartEvent() {
  // Grab the thread's timeline event block.
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);

  if (thread->isolate() == NULL) {
    // Non-isolate thread case. This should be infrequent.
    return GlobalBlockStartEvent();
  }

  TimelineEventBlock* thread_block = thread->timeline_block();

  if ((thread_block != NULL) && thread_block->IsFull()) {
    MutexLocker ml(&lock_);
    // Thread has a block and it is full:
    // 1) Mark it as finished.
    thread_block->Finish();
    // 2) Allocate a new block.
    thread_block = GetNewBlockLocked(thread->isolate());
    thread->set_timeline_block(thread_block);
  } else if (thread_block == NULL) {
    MutexLocker ml(&lock_);
    // Thread has no block. Attempt to allocate one.
    thread_block = GetNewBlockLocked(thread->isolate());
    thread->set_timeline_block(thread_block);
  }
  if (thread_block != NULL) {
    ASSERT(!thread_block->IsFull());
    return thread_block->StartEvent();
  }
  return NULL;
}



TimelineEvent* TimelineEventRecorder::GlobalBlockStartEvent() {
  MutexLocker ml(&lock_);
  if ((global_block_ != NULL) && global_block_->IsFull()) {
    // Global block is full.
    global_block_->Finish();
    global_block_ = NULL;
  }
  if (global_block_ == NULL) {
    // Allocate a new block.
    global_block_ = GetNewBlockLocked(NULL);
  }
  if (global_block_ != NULL) {
    ASSERT(!global_block_->IsFull());
    return global_block_->StartEvent();
  }
  return NULL;
}


void TimelineEventRecorder::WriteTo(const char* directory) {
  Dart_FileOpenCallback file_open = Isolate::file_open_callback();
  Dart_FileWriteCallback file_write = Isolate::file_write_callback();
  Dart_FileCloseCallback file_close = Isolate::file_close_callback();
  if ((file_open == NULL) || (file_write == NULL) || (file_close == NULL)) {
    return;
  }

  FinishGlobalBlock();

  JSONStream js;
  TimelineEventFilter filter;
  PrintJSON(&js, &filter);

  const char* format = "%s/dart-timeline-%" Pd ".json";
  intptr_t pid = OS::ProcessId();
  intptr_t len = OS::SNPrint(NULL, 0, format, directory, pid);
  char* filename = reinterpret_cast<char*>(malloc(len + 1));
  OS::SNPrint(filename, len + 1, format, directory, pid);
  void* file = (*file_open)(filename, true);
  if (file == NULL) {
    OS::Print("Failed to write timeline file: %s\n", filename);
    free(filename);
    return;
  }
  free(filename);
  (*file_write)(js.buffer()->buf(), js.buffer()->length(), file);
  (*file_close)(file);
}


void TimelineEventRecorder::FinishGlobalBlock() {
  MutexLocker ml(&lock_);
  if (global_block_ != NULL) {
    global_block_->Finish();
    global_block_ = NULL;
  }
}


int64_t TimelineEventRecorder::GetNextAsyncId() {
  // TODO(johnmccutchan): Gracefully handle wrap around.
  uint32_t next = static_cast<uint32_t>(
      AtomicOperations::FetchAndIncrement(&async_id_));
  return static_cast<int64_t>(next);
}


TimelineEventBlock* TimelineEventRecorder::GetNewBlock() {
  MutexLocker ml(&lock_);
  return GetNewBlockLocked(Isolate::Current());
}


TimelineEventRingRecorder::TimelineEventRingRecorder(intptr_t capacity)
    : blocks_(NULL),
      capacity_(capacity),
      num_blocks_(0),
      block_cursor_(0) {
  // Capacity must be a multiple of TimelineEventBlock::kBlockSize
  ASSERT((capacity % TimelineEventBlock::kBlockSize) == 0);
  // Allocate blocks array.
  num_blocks_ = capacity / TimelineEventBlock::kBlockSize;
  blocks_ =
      reinterpret_cast<TimelineEventBlock**>(
          calloc(num_blocks_, sizeof(TimelineEventBlock*)));
  // Allocate each block.
  for (intptr_t i = 0; i < num_blocks_; i++) {
    blocks_[i] = new TimelineEventBlock(i);
  }
  // Chain blocks together.
  for (intptr_t i = 0; i < num_blocks_ - 1; i++) {
    blocks_[i]->set_next(blocks_[i + 1]);
  }
}


TimelineEventRingRecorder::~TimelineEventRingRecorder() {
  // Delete all blocks.
  for (intptr_t i = 0; i < num_blocks_; i++) {
    TimelineEventBlock* block = blocks_[i];
    delete block;
  }
  free(blocks_);
}


void TimelineEventRingRecorder::PrintJSONEvents(
    JSONArray* events,
    TimelineEventFilter* filter) const {
  intptr_t block_offset = FindOldestBlockIndex();
  if (block_offset == -1) {
    // All blocks are empty.
    return;
  }
  for (intptr_t block_idx = 0; block_idx < num_blocks_; block_idx++) {
    TimelineEventBlock* block =
        blocks_[(block_idx + block_offset) % num_blocks_];
    if (!filter->IncludeBlock(block)) {
      continue;
    }
    for (intptr_t event_idx = 0; event_idx < block->length(); event_idx++) {
      TimelineEvent* event = block->At(event_idx);
      if (filter->IncludeEvent(event)) {
        events->AddValue(event);
      }
    }
  }
}


void TimelineEventRingRecorder::PrintJSON(JSONStream* js,
                                          TimelineEventFilter* filter) {
  MutexLocker ml(&lock_);
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "_Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
    PrintJSONEvents(&events, filter);
  }
}


TimelineEventBlock* TimelineEventRingRecorder::GetHeadBlockLocked() {
  return blocks_[0];
}


TimelineEventBlock* TimelineEventRingRecorder::GetNewBlockLocked(
    Isolate* isolate) {
  // TODO(johnmccutchan): This function should only hand out blocks
  // which have been marked as finished.
  if (block_cursor_ == num_blocks_) {
    block_cursor_ = 0;
  }
  TimelineEventBlock* block = blocks_[block_cursor_++];
  block->Reset();
  block->Open(isolate);
  return block;
}


intptr_t TimelineEventRingRecorder::FindOldestBlockIndex() const {
  int64_t earliest_time = kMaxInt64;
  intptr_t earliest_index = -1;
  for (intptr_t block_idx = 0; block_idx < num_blocks_; block_idx++) {
    TimelineEventBlock* block = blocks_[block_idx];
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


TimelineEvent* TimelineEventRingRecorder::StartEvent() {
  return ThreadBlockStartEvent();
}


void TimelineEventRingRecorder::CompleteEvent(TimelineEvent* event) {
  // no-op.
}


TimelineEventStreamingRecorder::TimelineEventStreamingRecorder() {
}


TimelineEventStreamingRecorder::~TimelineEventStreamingRecorder() {
}


void TimelineEventStreamingRecorder::PrintJSON(JSONStream* js,
                                               TimelineEventFilter* filter) {
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "_Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
  }
}


TimelineEvent* TimelineEventStreamingRecorder::StartEvent() {
  TimelineEvent* event = new TimelineEvent();
  return event;
}


void TimelineEventStreamingRecorder::CompleteEvent(TimelineEvent* event) {
  StreamEvent(event);
  delete event;
}


TimelineEventEndlessRecorder::TimelineEventEndlessRecorder()
    : head_(NULL),
      block_index_(0) {
  GetNewBlock();
}


void TimelineEventEndlessRecorder::PrintJSON(JSONStream* js,
                                             TimelineEventFilter* filter) {
  MutexLocker ml(&lock_);
  JSONObject topLevel(js);
  topLevel.AddProperty("type", "_Timeline");
  {
    JSONArray events(&topLevel, "traceEvents");
    PrintJSONMeta(&events);
    PrintJSONEvents(&events, filter);
  }
}


TimelineEventBlock* TimelineEventEndlessRecorder::GetHeadBlockLocked() {
  return head_;
}


TimelineEvent* TimelineEventEndlessRecorder::StartEvent() {
  return ThreadBlockStartEvent();
}


void TimelineEventEndlessRecorder::CompleteEvent(TimelineEvent* event) {
  // no-op.
}


TimelineEventBlock* TimelineEventEndlessRecorder::GetNewBlockLocked(
    Isolate* isolate) {
  TimelineEventBlock* block = new TimelineEventBlock(block_index_++);
  block->set_next(head_);
  block->Open(isolate);
  head_ = block;
  return head_;
}


void TimelineEventEndlessRecorder::PrintJSONEvents(
    JSONArray* events,
    TimelineEventFilter* filter) const {
  TimelineEventBlock* current = head_;

  while (current != NULL) {
    if (!filter->IncludeBlock(current)) {
      current = current->next();
      continue;
    }
    intptr_t length = current->length();
    for (intptr_t i = 0; i < length; i++) {
      TimelineEvent* event = current->At(i);
      if (!filter->IncludeEvent(event)) {
        continue;
      }
      events->AddValue(event);
    }
    current = current->next();
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
  Thread* thread = Thread::Current();
  thread->set_timeline_block(NULL);
}


TimelineEventBlock::TimelineEventBlock(intptr_t block_index)
    : next_(NULL),
      length_(0),
      block_index_(block_index) {
}


TimelineEventBlock::~TimelineEventBlock() {
  Reset();
}


TimelineEvent* TimelineEventBlock::StartEvent() {
  ASSERT(!IsFull());
  return &events_[length_++];
}


ThreadId TimelineEventBlock::thread() const {
  ASSERT(length_ > 0);
  return events_[0].thread();
}


int64_t TimelineEventBlock::LowerTimeBound() const {
  ASSERT(length_ > 0);
  return events_[0].TimeOrigin();
}


bool TimelineEventBlock::CheckBlock() {
  if (length() == 0) {
    return true;
  }

  // - events in the block come from one thread.
  ThreadId tid = thread();
  for (intptr_t i = 0; i < length(); i++) {
    if (At(i)->thread() != tid) {
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
  isolate_ = NULL;
  open_ = false;
}


void TimelineEventBlock::Open(Isolate* isolate) {
  isolate_ = isolate;
  open_ = true;
}


void TimelineEventBlock::Finish() {
  open_ = false;
}


TimelineEventBlockIterator::TimelineEventBlockIterator(
    TimelineEventRecorder* recorder)
    : current_(NULL),
      recorder_(NULL) {
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

}  // namespace dart
