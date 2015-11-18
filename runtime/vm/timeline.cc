// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstdlib>

#include "vm/atomic.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/thread.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(bool, complete_timeline, false, "Record the complete timeline");
DEFINE_FLAG(bool, trace_timeline, false,
            "Trace timeline backend");
DEFINE_FLAG(bool, trace_timeline_analysis, false,
            "Trace timeline analysis backend");
DEFINE_FLAG(bool, timing, false,
            "Dump isolate timing information from timeline.");
DEFINE_FLAG(charp, timeline_dir, NULL,
            "Enable all timeline trace streams and output VM global trace "
            "into specified directory.");

// Implementation notes:
//
// Writing events:
// |TimelineEvent|s are written into |TimelineEventBlock|s. Each |Thread| caches
// a |TimelineEventBlock| in TLS so that it can write events without
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
// a |TimelineEventBlock| cached in TLS. In order to report a complete timeline
// the cached |TimelineEventBlock|s need to be reclaimed.
//
// Reclaiming open |TimelineEventBlock|s for an isolate:
//
// Cached |TimelineEventBlock|s can be in two places:
// 1) In a |Thread| (Thread currently in an |Isolate|)
// 2) In a |Thread::State| (Thread not currently in an |Isolate|).
//
// As a |Thread| enters and exits an |Isolate|, a |TimelineEventBlock|
// will move between (1) and (2).
//
// The first case occurs for |Thread|s that are currently running inside an
// isolate. The second case occurs for |Thread|s that are not currently
// running inside an isolate.
//
// To reclaim the first case, we take the |Thread|'s |timeline_block_lock_|
// and reclaim the cached block.
//
// To reclaim the second case, we can take the |ThreadRegistry| lock and
// reclaim these blocks.
//
// |Timeline::ReclaimIsolateBlocks| and |Timeline::ReclaimAllBlocks| are
// the two utility methods used to reclaim blocks before reporting.
//
// Locking notes:
// The following locks are used by the timeline system:
// - |TimelineEventRecorder::lock_| This lock is held whenever a
// |TimelineEventBlock| is being requested or reclaimed.
// - |Thread::timeline_block_lock_| This lock is held whenever a |Thread|'s
// cached block is being operated on.
// - |ThreadRegistry::monitor_| This lock protects the cached block for
// unscheduled threads of an isolate.
// - |Isolate::isolates_list_monitor_| This lock protects the list of
// isolates in the system.
//
// Locks must always be taken in the following order:
// |Isolate::isolates_list_monitor_|
//   |ThreadRegistry::monitor_|
//     |Thread::timeline_block_lock_|
//       |TimelineEventRecorder::lock_|
//

void Timeline::InitOnce() {
  ASSERT(recorder_ == NULL);
  // Default to ring recorder being enabled.
  const bool use_ring_recorder = true;
  // Some flags require that we use the endless recorder.
  const bool use_endless_recorder =
      (FLAG_timeline_dir != NULL) || FLAG_timing;
  if (use_endless_recorder) {
    recorder_ = new TimelineEventEndlessRecorder();
  } else if (use_ring_recorder) {
    recorder_ = new TimelineEventRingRecorder();
  }
  vm_stream_ = new TimelineStream();
  vm_stream_->Init("VM", EnableStreamByDefault("VM"), NULL);
  // Global overrides.
#define ISOLATE_TIMELINE_STREAM_FLAG_DEFAULT(name, not_used)                   \
  stream_##name##_enabled_ = false;
  ISOLATE_TIMELINE_STREAM_LIST(ISOLATE_TIMELINE_STREAM_FLAG_DEFAULT)
#undef ISOLATE_TIMELINE_STREAM_FLAG_DEFAULT
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
  return (FLAG_timeline_dir != NULL) || FLAG_timing;
}


TimelineStream* Timeline::GetVMStream() {
  ASSERT(vm_stream_ != NULL);
  return vm_stream_;
}


void Timeline::ReclaimIsolateBlocks() {
  ReclaimBlocksForIsolate(Isolate::Current());
}


class ReclaimBlocksIsolateVisitor : public IsolateVisitor {
 public:
  ReclaimBlocksIsolateVisitor() {}

  virtual void VisitIsolate(Isolate* isolate) {
    Timeline::ReclaimBlocksForIsolate(isolate);
  }

 private:
};


void Timeline::ReclaimAllBlocks() {
  if (recorder() == NULL) {
    return;
  }
  // Reclaim all blocks cached for all isolates.
  ReclaimBlocksIsolateVisitor visitor;
  Isolate::VisitIsolates(&visitor);
  // Reclaim the global VM block.
  recorder()->ReclaimGlobalBlock();
}


void Timeline::ReclaimBlocksForIsolate(Isolate* isolate) {
  if (recorder() == NULL) {
    return;
  }
  ASSERT(isolate != NULL);
  isolate->ReclaimTimelineBlocks();
}


TimelineEventRecorder* Timeline::recorder_ = NULL;
TimelineStream* Timeline::vm_stream_ = NULL;

#define ISOLATE_TIMELINE_STREAM_DEFINE_FLAG(name, enabled_by_default)          \
  bool Timeline::stream_##name##_enabled_ = false;
  ISOLATE_TIMELINE_STREAM_LIST(ISOLATE_TIMELINE_STREAM_DEFINE_FLAG)
#undef ISOLATE_TIMELINE_STREAM_DEFINE_FLAG

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
  timestamp0_ = OS::GetCurrentTraceMicros();
  // Overload timestamp1_ with the async_id.
  timestamp1_ = async_id;
}


void TimelineEvent::AsyncInstant(const char* label,
                                 int64_t async_id) {
  Init(kAsyncInstant, label);
  timestamp0_ = OS::GetCurrentTraceMicros();
  // Overload timestamp1_ with the async_id.
  timestamp1_ = async_id;
}


void TimelineEvent::AsyncEnd(const char* label,
                             int64_t async_id) {
  Init(kAsyncEnd, label);
  timestamp0_ = OS::GetCurrentTraceMicros();
  // Overload timestamp1_ with the async_id.
  timestamp1_ = async_id;
}


void TimelineEvent::DurationBegin(const char* label) {
  Init(kDuration, label);
  timestamp0_ = OS::GetCurrentTraceMicros();
}


void TimelineEvent::DurationEnd() {
  timestamp1_ = OS::GetCurrentTraceMicros();
}


void TimelineEvent::Instant(const char* label) {
  Init(kInstant, label);
  timestamp0_ = OS::GetCurrentTraceMicros();
}


void TimelineEvent::Duration(const char* label,
                             int64_t start_micros,
                             int64_t end_micros) {
  Init(kDuration, label);
  timestamp0_ = start_micros;
  timestamp1_ = end_micros;
}


void TimelineEvent::Begin(const char* label,
                          int64_t micros) {
  Init(kBegin, label);
  timestamp0_ = micros;
}


void TimelineEvent::End(const char* label,
                        int64_t micros) {
  Init(kEnd, label);
  timestamp0_ = micros;
}


void TimelineEvent::SetNumArguments(intptr_t length) {
  // Cannot call this twice.
  ASSERT(arguments_ == NULL);
  ASSERT(arguments_length_ == 0);
  if (length == 0) {
    return;
  }
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


void TimelineEvent::StealArguments(intptr_t arguments_length,
                                   TimelineEventArgument* arguments) {
  arguments_length_ = arguments_length;
  arguments_ = arguments;
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
  thread_ = OSThread::GetCurrentThreadTraceId();
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
  obj.AddPropertyTimeMicros("ts", TimeOrigin());

  switch (event_type()) {
    case kBegin: {
      obj.AddProperty("ph", "B");
    }
    break;
    case kEnd: {
      obj.AddProperty("ph", "E");
    }
    break;
    case kDuration: {
      obj.AddProperty("ph", "X");
      obj.AddPropertyTimeMicros("dur", TimeDuration());
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
    return OS::GetCurrentTraceMicros() - timestamp0_;
  }
  return timestamp1_ - timestamp0_;
}


TimelineStream::TimelineStream()
    : name_(NULL),
      enabled_(false),
      globally_enabled_(NULL) {
}


void TimelineStream::Init(const char* name,
                          bool enabled,
                          const bool* globally_enabled) {
  name_ = name;
  enabled_ = enabled;
  globally_enabled_ = globally_enabled;
}


TimelineEvent* TimelineStream::StartEvent() {
  TimelineEventRecorder* recorder = Timeline::recorder();
  if (!Enabled() || (recorder == NULL)) {
    return NULL;
  }
  ASSERT(name_ != NULL);
  TimelineEvent* event = recorder->StartEvent();
  if (event != NULL) {
    event->StreamInit(this);
  }
  return event;
}


TimelineDurationScope::TimelineDurationScope(TimelineStream* stream,
                                             const char* label)
    : StackResource(reinterpret_cast<Thread*>(NULL)),
      timestamp_(0),
      stream_(stream),
      label_(label),
      arguments_(NULL),
      arguments_length_(0),
      enabled_(false) {
  Init();
}


TimelineDurationScope::TimelineDurationScope(Thread* thread,
                                             TimelineStream* stream,
                                             const char* label)
    : StackResource(thread),
      timestamp_(0),
      stream_(stream),
      label_(label),
      arguments_(NULL),
      arguments_length_(0),
      enabled_(false) {
  ASSERT(thread != NULL);
  Init();
}


TimelineDurationScope::~TimelineDurationScope() {
  if (!enabled_) {
    FreeArguments();
    return;
  }
  TimelineEvent* event = stream_->StartEvent();
  ASSERT(event != NULL);
  event->Duration(label_, timestamp_, OS::GetCurrentTraceMicros());
  event->StealArguments(arguments_length_, arguments_);
  event->Complete();
  arguments_length_ = 0;
  arguments_ = NULL;
}


void TimelineDurationScope::Init() {
  ASSERT(enabled_ == false);
  ASSERT(label_ != NULL);
  ASSERT(stream_ != NULL);
  if (!stream_->Enabled()) {
    // Stream is not enabled, do nothing.
    return;
  }
  timestamp_ = OS::GetCurrentTraceMicros();
  enabled_ = true;
}


void TimelineDurationScope::SetNumArguments(intptr_t length) {
  if (!enabled()) {
    return;
  }
  ASSERT(arguments_ == NULL);
  ASSERT(arguments_length_ == 0);
  arguments_length_ = length;
  if (arguments_length_ == 0) {
    return;
  }
  arguments_ = reinterpret_cast<TimelineEventArgument*>(
      calloc(sizeof(TimelineEventArgument), length));
}


// |name| must be a compile time constant. Takes ownership of |argumentp|.
void TimelineDurationScope::SetArgument(intptr_t i,
                                        const char* name,
                                        char* argument) {
  if (!enabled()) {
    return;
  }
  ASSERT(i >= 0);
  ASSERT(i < arguments_length_);
  arguments_[i].name = name;
  arguments_[i].value = argument;
}


// |name| must be a compile time constant. Copies |argument|.
void TimelineDurationScope::CopyArgument(intptr_t i,
                                         const char* name,
                                         const char* argument) {
  if (!enabled()) {
    return;
  }
  SetArgument(i, name, strdup(argument));
}


void TimelineDurationScope::FormatArgument(intptr_t i,
                                           const char* name,
                                           const char* fmt, ...) {
  if (!enabled()) {
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

  SetArgument(i, name, buffer);
}


void TimelineDurationScope::FreeArguments() {
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


TimelineEventFilter::TimelineEventFilter() {
}


TimelineEventFilter::~TimelineEventFilter() {
}


IsolateTimelineEventFilter::IsolateTimelineEventFilter(Isolate* isolate)
    : isolate_(isolate) {
}


DartTimelineEvent::DartTimelineEvent()
    : isolate_(NULL),
      event_as_json_(NULL) {
}


DartTimelineEvent::~DartTimelineEvent() {
  Clear();
}


void DartTimelineEvent::Clear() {
  if (isolate_ != NULL) {
    isolate_ = NULL;
  }
  if (event_as_json_ != NULL) {
    free(event_as_json_);
    event_as_json_ = NULL;
  }
}


void DartTimelineEvent::Init(Isolate* isolate, const char* event) {
  ASSERT(isolate_ == NULL);
  ASSERT(event != NULL);
  isolate_ = isolate;
  event_as_json_ = strdup(event);
}


TimelineEventRecorder::TimelineEventRecorder()
    : global_block_(NULL),
      async_id_(0) {
}


void TimelineEventRecorder::PrintJSONMeta(JSONArray* events) const {
}


TimelineEvent* TimelineEventRecorder::ThreadBlockStartEvent() {
  // Grab the current thread.
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(thread->isolate() != NULL);
  Mutex* thread_block_lock = thread->timeline_block_lock();
  ASSERT(thread_block_lock != NULL);
  // We are accessing the thread's timeline block- so take the lock here.
  // This lock will be held until the call to |CompleteEvent| is made.
  thread_block_lock->Lock();

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
    // NOTE: We are exiting this function with the thread's block lock held.
    ASSERT(!thread_block->IsFull());
    TimelineEvent* event = thread_block->StartEvent();
    if (event != NULL) {
      event->set_global_block(false);
    }
    return event;
  }
  // Drop lock here as no event is being handed out.
  thread_block_lock->Unlock();
  return NULL;
}


TimelineEvent* TimelineEventRecorder::GlobalBlockStartEvent() {
  // Take recorder lock. This lock will be held until the call to
  // |CompleteEvent| is made.
  lock_.Lock();
  if (FLAG_trace_timeline) {
    OS::Print("GlobalBlockStartEvent in block %p for thread %" Px "\n",
              global_block_, OSThread::CurrentCurrentThreadIdAsIntPtr());
  }
  if ((global_block_ != NULL) && global_block_->IsFull()) {
    // Global block is full.
    global_block_->Finish();
    global_block_ = NULL;
  }
  if (global_block_ == NULL) {
    // Allocate a new block.
    global_block_ = GetNewBlockLocked(NULL);
    ASSERT(global_block_ != NULL);
  }
  if (global_block_ != NULL) {
    // NOTE: We are exiting this function with the recorder's lock held.
    ASSERT(!global_block_->IsFull());
    TimelineEvent* event = global_block_->StartEvent();
    if (event != NULL) {
      event->set_global_block(true);
    }
    return event;
  }
  // Drop lock here as no event is being handed out.
  lock_.Unlock();
  return NULL;
}


void TimelineEventRecorder::ThreadBlockCompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  ASSERT(!event->global_block());
  // Grab the current thread.
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(thread->isolate() != NULL);
  // This event came from the isolate's thread local block. Unlock the
  // thread's block lock.
  Mutex* thread_block_lock = thread->timeline_block_lock();
  ASSERT(thread_block_lock != NULL);
  thread_block_lock->Unlock();
}


void TimelineEventRecorder::GlobalBlockCompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  ASSERT(event->global_block());
  // This event came from the global block, unlock the recorder's lock now
  // that the event is filled.
  lock_.Unlock();
}


// Trims the ']' character.
static void TrimOutput(char* output,
                       intptr_t* output_length) {
  ASSERT(output != NULL);
  ASSERT(output_length != NULL);
  ASSERT(*output_length >= 2);
  // We expect the first character to be the opening of an array.
  ASSERT(output[0] == '[');
  // We expect the last character to be the closing of an array.
  ASSERT(output[*output_length - 1] == ']');
  // Skip the ].
  *output_length -= 1;
}


void TimelineEventRecorder::WriteTo(const char* directory) {
  Dart_FileOpenCallback file_open = Isolate::file_open_callback();
  Dart_FileWriteCallback file_write = Isolate::file_write_callback();
  Dart_FileCloseCallback file_close = Isolate::file_close_callback();
  if ((file_open == NULL) || (file_write == NULL) || (file_close == NULL)) {
    return;
  }
  Thread* T = Thread::Current();
  StackZone zone(T);

  Timeline::ReclaimAllBlocks();

  intptr_t pid = OS::ProcessId();
  char* filename = OS::SCreate(NULL,
      "%s/dart-timeline-%" Pd ".json", directory, pid);
  void* file = (*file_open)(filename, true);
  if (file == NULL) {
    OS::Print("Failed to write timeline file: %s\n", filename);
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
  js.Steal(const_cast<const char**>(&output), &output_length);
  TrimOutput(output, &output_length);
  ASSERT(output_length >= 1);
  (*file_write)(output, output_length, file);
  // Free the stolen output.
  free(output);

  const char* dart_events =
      DartTimelineEventIterator::PrintTraceEvents(this,
                                                  zone.GetZone(),
                                                  NULL);

  // If we wrote out vm events and have dart events, write out the comma.
  if ((output_length > 1) && (dart_events != NULL)) {
    // Write out the ',' character.
    const char* comma = ",";
    (*file_write)(comma, 1, file);
  }

  // Write out the Dart events.
  if (dart_events != NULL) {
    (*file_write)(dart_events, strlen(dart_events), file);
  }

  // Write out the ']' character.
  const char* array_close = "]";
  (*file_write)(array_close, 1, file);
  (*file_close)(file);

  return;
}


void TimelineEventRecorder::ReclaimGlobalBlock() {
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


void TimelineEventRecorder::FinishBlock(TimelineEventBlock* block) {
  if (block == NULL) {
    return;
  }
  MutexLocker ml(&lock_);
  block->Finish();
}


TimelineEventBlock* TimelineEventRecorder::GetNewBlock() {
  MutexLocker ml(&lock_);
  return GetNewBlockLocked(Isolate::Current());
}


TimelineEventRingRecorder::TimelineEventRingRecorder(intptr_t capacity)
    : blocks_(NULL),
      capacity_(capacity),
      num_blocks_(0),
      block_cursor_(0),
      dart_events_(NULL),
      dart_events_capacity_(capacity),
      dart_events_cursor_(0) {
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
  // Pre-allocate DartTimelineEvents.
  dart_events_ =
      reinterpret_cast<DartTimelineEvent**>(
          calloc(dart_events_capacity_, sizeof(DartTimelineEvent*)));
  for (intptr_t i = 0; i < dart_events_capacity_; i++) {
    dart_events_[i] = new DartTimelineEvent();
  }
}


TimelineEventRingRecorder::~TimelineEventRingRecorder() {
  // Delete all blocks.
  for (intptr_t i = 0; i < num_blocks_; i++) {
    TimelineEventBlock* block = blocks_[i];
    delete block;
  }
  free(blocks_);
  // Delete all DartTimelineEvents.
  for (intptr_t i = 0; i < dart_events_capacity_; i++) {
    DartTimelineEvent* event = dart_events_[i];
    delete event;
  }
  free(dart_events_);
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


void TimelineEventRingRecorder::AppendDartEvent(Isolate* isolate,
                                                const char* event) {
  MutexLocker ml(&lock_);
  // TODO(johnmccutchan): If locking becomes an issue, use the Isolate to store
  // the events.
  if (dart_events_cursor_ == dart_events_capacity_) {
    dart_events_cursor_ = 0;
  }
  ASSERT(dart_events_[dart_events_cursor_] != NULL);
  dart_events_[dart_events_cursor_]->Clear();
  dart_events_[dart_events_cursor_]->Init(isolate, event);
  dart_events_cursor_++;
}


intptr_t TimelineEventRingRecorder::NumDartEventsLocked() {
  return dart_events_capacity_;
}


DartTimelineEvent* TimelineEventRingRecorder::DartEventAtLocked(intptr_t i) {
  ASSERT(i >= 0);
  ASSERT(i < dart_events_capacity_);
  return dart_events_[i];
}


void TimelineEventRingRecorder::PrintTraceEvent(JSONStream* js,
                                                TimelineEventFilter* filter) {
  JSONArray events(js);
  PrintJSONEvents(&events, filter);
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
  // Grab the current thread.
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  if (thread->isolate() == NULL) {
    // Non-isolate thread case. This should be infrequent.
    return GlobalBlockStartEvent();
  }
  return ThreadBlockStartEvent();
}


void TimelineEventRingRecorder::CompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  if (event->global_block()) {
    GlobalBlockCompleteEvent(event);
  } else {
    ThreadBlockCompleteEvent(event);
  }
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


void TimelineEventStreamingRecorder::PrintTraceEvent(
    JSONStream* js,
    TimelineEventFilter* filter) {
  JSONArray events(js);
}


void TimelineEventStreamingRecorder::AppendDartEvent(Isolate* isolate,
                                                     const char* event) {
  if (event != NULL) {
    StreamDartEvent(event);
  }
}


intptr_t TimelineEventStreamingRecorder::NumDartEventsLocked() {
  return 0;
}


DartTimelineEvent* TimelineEventStreamingRecorder::DartEventAtLocked(
    intptr_t i) {
  return NULL;
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
      block_index_(0),
      dart_events_(NULL),
      dart_events_capacity_(0),
      dart_events_cursor_(0) {
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


void TimelineEventEndlessRecorder::PrintTraceEvent(
    JSONStream* js,
    TimelineEventFilter* filter) {
  JSONArray events(js);
  PrintJSONEvents(&events, filter);
}


void TimelineEventEndlessRecorder::AppendDartEvent(Isolate* isolate,
                                                   const char* event) {
  MutexLocker ml(&lock_);
  // TODO(johnmccutchan): If locking becomes an issue, use the Isolate to store
  // the events.
  if (dart_events_cursor_ == dart_events_capacity_) {
    // Grow.
    intptr_t new_capacity =
        (dart_events_capacity_ == 0) ? 16 : dart_events_capacity_ * 2;
    dart_events_ = reinterpret_cast<DartTimelineEvent**>(
        realloc(dart_events_, new_capacity * sizeof(DartTimelineEvent*)));
    for (intptr_t i = dart_events_capacity_; i < new_capacity; i++) {
      // Fill with NULLs.
      dart_events_[i] = NULL;
    }
    dart_events_capacity_ = new_capacity;
  }
  ASSERT(dart_events_cursor_ < dart_events_capacity_);
  DartTimelineEvent* dart_event = new DartTimelineEvent();
  dart_event->Init(isolate, event);
  ASSERT(dart_events_[dart_events_cursor_] == NULL);
  dart_events_[dart_events_cursor_++] = dart_event;
}


TimelineEventBlock* TimelineEventEndlessRecorder::GetHeadBlockLocked() {
  return head_;
}


TimelineEvent* TimelineEventEndlessRecorder::StartEvent() {
  // Grab the current thread.
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  if (thread->isolate() == NULL) {
    // Non-isolate thread case. This should be infrequent.
    return GlobalBlockStartEvent();
  }
  return ThreadBlockStartEvent();
}


void TimelineEventEndlessRecorder::CompleteEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  if (event->global_block()) {
    GlobalBlockCompleteEvent(event);
  } else {
    ThreadBlockCompleteEvent(event);
  }
}


TimelineEventBlock* TimelineEventEndlessRecorder::GetNewBlockLocked(
    Isolate* isolate) {
  TimelineEventBlock* block = new TimelineEventBlock(block_index_++);
  block->set_next(head_);
  block->Open(isolate);
  head_ = block;
  if (FLAG_trace_timeline) {
    if (isolate != NULL) {
      OS::Print("Created new isolate block %p for %s\n",
                block, isolate->name());
    } else {
      OS::Print("Created new global block %p\n", block);
    }
  }
  return head_;
}


intptr_t TimelineEventEndlessRecorder::NumDartEventsLocked() {
  return dart_events_cursor_;
}


DartTimelineEvent* TimelineEventEndlessRecorder::DartEventAtLocked(
    intptr_t i) {
  ASSERT(i >= 0);
  ASSERT(i < dart_events_cursor_);
  return dart_events_[i];
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
      block_index_(block_index),
      isolate_(NULL),
      in_use_(false) {
}


TimelineEventBlock::~TimelineEventBlock() {
  Reset();
}


TimelineEvent* TimelineEventBlock::StartEvent() {
  ASSERT(!IsFull());
  if (FLAG_trace_timeline) {
    OS::Print("StartEvent in block %p for thread %" Px "\n",
              this, OSThread::CurrentCurrentThreadIdAsIntPtr());
  }
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
  in_use_ = false;
}


void TimelineEventBlock::Open(Isolate* isolate) {
  isolate_ = isolate;
  in_use_ = true;
}


void TimelineEventBlock::Finish() {
  if (FLAG_trace_timeline) {
    OS::Print("Finish block %p\n", this);
  }
  in_use_ = false;
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


DartTimelineEventIterator::DartTimelineEventIterator(
    TimelineEventRecorder* recorder)
    : cursor_(0),
      num_events_(0),
      recorder_(NULL) {
  Reset(recorder);
}


DartTimelineEventIterator::~DartTimelineEventIterator() {
  Reset(NULL);
}


void DartTimelineEventIterator::Reset(TimelineEventRecorder* recorder) {
  // Clear state.
  cursor_ = 0;
  num_events_ = 0;
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
  cursor_ = 0;
  num_events_ = recorder_->NumDartEventsLocked();
}


bool DartTimelineEventIterator::HasNext() const {
  return cursor_ < num_events_;
}


DartTimelineEvent* DartTimelineEventIterator::Next() {
  ASSERT(cursor_ < num_events_);
  DartTimelineEvent* r = recorder_->DartEventAtLocked(cursor_);
  cursor_++;
  return r;
}

const char* DartTimelineEventIterator::PrintTraceEvents(
    TimelineEventRecorder* recorder,
    Zone* zone,
    Isolate* isolate) {
  if (recorder == NULL) {
    return NULL;
  }

  if (zone == NULL) {
    return NULL;
  }

  char* result = NULL;
  DartTimelineEventIterator iterator(recorder);
  while (iterator.HasNext()) {
    DartTimelineEvent* event = iterator.Next();
    if (!event->IsValid()) {
      // Skip invalid
      continue;
    }
    if ((isolate != NULL) && (isolate != event->isolate())) {
      // If an isolate was specified, skip events from other isolates.
      continue;
    }
    ASSERT(event->event_as_json() != NULL);
    result = zone->ConcatStrings(result, event->event_as_json());
  }
  return result;
}

}  // namespace dart
