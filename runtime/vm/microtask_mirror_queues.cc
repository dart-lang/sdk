// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(PRODUCT)

#include "vm/microtask_mirror_queues.h"

#include <utility>

#include "platform/hashmap.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/timeline.h"

namespace dart {

DEFINE_FLAG(
    bool,
    profile_microtasks,
    false,
    "Record information about each microtask. Information about completed "
    "microtasks will be written to the \"Microtask\" timeline stream.");

MicrotaskMirrorQueue* MicrotaskMirrorQueues::GetQueue(int64_t isolate_id) {
  void* key = reinterpret_cast<void*>(isolate_id);
  const intptr_t hash = Utils::WordHash(isolate_id);

  MutexLocker ml(&isolate_id_to_queue_lock_);

  SimpleHashMap::Entry* entry = isolate_id_to_queue_.Lookup(key, hash, true);
  if (entry->value == nullptr) {
    entry->value = new MicrotaskMirrorQueue();
  }
  return static_cast<MicrotaskMirrorQueue*>(entry->value);
}

void MicrotaskMirrorQueue::OnScheduleAsyncCallback(const StackTrace& st) {
  if (is_disabled_) {
    return;
  }

  queue_.PushBack(MicrotaskMirrorQueueEntry(
      next_available_id_++, CStringUniquePtr(Utils::StrDup(st.ToCString()))));
}

void MicrotaskMirrorQueue::OnSchedulePriorityAsyncCallback() {
  // If this function is called, it means that the microtask queue can no longer
  // be accurately modeled by a |ListQueue|. This only ever gets called when an
  // exception goes unhandled, so we just handle the situation by disabling all
  // further reads from / writes to this queue.
  is_disabled_ = true;
}

void MicrotaskMirrorQueue::OnAsyncCallbackComplete(int64_t start_time,
                                                   int64_t end_time) {
  if (is_disabled_) {
    return;
  }

  ASSERT(queue_.Length() >= 1);
  MicrotaskMirrorQueueEntry&& front = std::move(queue_.PopFront());

  TimelineStream* stream = Timeline::GetMicrotaskStream();
  ASSERT(stream != nullptr);
  TimelineEvent* event = stream->StartEvent();
  if (event != nullptr) {
    if (start_time < end_time) {
      event->Duration("Microtask", start_time, end_time);
    } else {
      event->Instant("Microtask", start_time);
    }

    event->SetNumArguments(2);
    event->FormatArgument(0, "microtaskId", "%" Pd, front.id());
    event->SetArgument(1, "stack trace captured when microtask was enqueued",
                       front.ReleaseStackTrace());
    event->Complete();
  }
}

void MicrotaskMirrorQueue::PrintJSON(JSONStream& js) const {
  ASSERT(!is_disabled_);

  JSONObject jsobj_topLevel(&js);
  jsobj_topLevel.AddProperty("type", "QueuedMicrotasks");
  jsobj_topLevel.AddProperty64("timestamp", OS::GetCurrentTimeMicros());

  JSONArray jsarr(&jsobj_topLevel, "microtasks");
  queue_.ForEach([&jsarr](const MicrotaskMirrorQueueEntry& entry) {
    JSONObject jsobj_entry(&jsarr);
    jsobj_entry.AddProperty("type", "Microtask");
    jsobj_entry.AddProperty("id", entry.id());
    jsobj_entry.AddProperty("stackTrace", entry.stack_trace().get());
  });
}

Mutex MicrotaskMirrorQueues::isolate_id_to_queue_lock_;

SimpleHashMap MicrotaskMirrorQueues::isolate_id_to_queue_(
    &SimpleHashMap::SamePointerValue,
    MicrotaskMirrorQueues::kIsolateIdToQueueInitialCapacity);

void MicrotaskMirrorQueues::CleanUp() {
  for (SimpleHashMap::Entry* entry = isolate_id_to_queue_.Start();
       entry != nullptr; entry = isolate_id_to_queue_.Next(entry)) {
    MicrotaskMirrorQueue* value =
        static_cast<MicrotaskMirrorQueue*>(entry->value);
    delete value;
  }
}

}  // namespace dart

#endif  // !defined(PRODUCT)
