// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_state.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/thread.h"
#include "vm/timeline.h"

namespace dart {

BackgroundFinalizer::BackgroundFinalizer(Isolate* isolate,
                                         FinalizationQueue* queue) :
    isolate_(isolate),
    queue_(queue) {
  MonitorLocker ml(isolate->heap()->finalization_tasks_lock());
  isolate->heap()->set_finalization_tasks(
      isolate->heap()->finalization_tasks() + 1);
  ml.Notify();
}


void BackgroundFinalizer::Run() {
  bool result = Thread::EnterIsolateAsHelper(isolate_,
                                             Thread::kFinalizerTask,
                                             true /* bypass_safepoint */);
  ASSERT(result);

  {
    Thread* thread = Thread::Current();
    TIMELINE_FUNCTION_GC_DURATION(thread, "BackgroundFinalization");
    TransitionVMToNative transition(thread);
    for (intptr_t i = 0; i < queue_->length(); i++) {
      FinalizablePersistentHandle* handle = (*queue_)[i];
      FinalizablePersistentHandle::Finalize(isolate_, handle);
    }
    delete queue_;
  }

  // Exit isolate cleanly *before* notifying it, to avoid shutdown race.
  Thread::ExitIsolateAsHelper();

  {
    Heap* heap = isolate_->heap();
    MonitorLocker ml(heap->finalization_tasks_lock());
    heap->set_finalization_tasks(heap->finalization_tasks() - 1);
    ml.Notify();
  }
}

}  // namespace dart
