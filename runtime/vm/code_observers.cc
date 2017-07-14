// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_observers.h"

#include "vm/os.h"
#include "vm/os_thread.h"

namespace dart {

#ifndef PRODUCT

Mutex* CodeObservers::mutex_ = NULL;
intptr_t CodeObservers::observers_length_ = 0;
CodeObserver** CodeObservers::observers_ = NULL;

void CodeObservers::Register(CodeObserver* observer) {
  observers_length_++;
  observers_ = reinterpret_cast<CodeObserver**>(
      realloc(observers_, sizeof(observer) * observers_length_));
  if (observers_ == NULL) {
    FATAL("failed to grow code observers array");
  }
  observers_[observers_length_ - 1] = observer;
}

void CodeObservers::NotifyAll(const char* name,
                              uword base,
                              uword prologue_offset,
                              uword size,
                              bool optimized) {
  ASSERT(!AreActive() || (strlen(name) != 0));
  for (intptr_t i = 0; i < observers_length_; i++) {
    if (observers_[i]->IsActive()) {
      observers_[i]->Notify(name, base, prologue_offset, size, optimized);
    }
  }
}

bool CodeObservers::AreActive() {
  for (intptr_t i = 0; i < observers_length_; i++) {
    if (observers_[i]->IsActive()) return true;
  }
  return false;
}

void CodeObservers::DeleteAll() {
  for (intptr_t i = 0; i < observers_length_; i++) {
    delete observers_[i];
  }
  free(observers_);
  observers_length_ = 0;
  observers_ = NULL;
}

void CodeObservers::InitOnce() {
  ASSERT(mutex_ == NULL);
  mutex_ = new Mutex();
  ASSERT(mutex_ != NULL);
  OS::RegisterCodeObservers();
}

#endif  // !PRODUCT

}  // namespace dart
