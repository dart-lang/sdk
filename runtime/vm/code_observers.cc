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

class ExternalCodeObserverAdapter : public CodeObserver {
 public:
  explicit ExternalCodeObserverAdapter(Dart_CodeObserver delegate)
      : delegate_(delegate) {}

  virtual bool IsActive() const { return true; }

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized,
                      const CodeComments* comments) {
    return delegate_.on_new_code(&delegate_, name, base, size);
  }

 private:
  Dart_CodeObserver delegate_;
};

void CodeObservers::RegisterExternal(Dart_CodeObserver observer) {
  Register(new ExternalCodeObserverAdapter(observer));
}

void CodeObservers::Register(CodeObserver* observer) {
  observers_length_++;
  observers_ = reinterpret_cast<CodeObserver**>(
      realloc(observers_, sizeof(observer) * observers_length_));
  observers_[observers_length_ - 1] = observer;
}

void CodeObservers::NotifyAll(const char* name,
                              uword base,
                              uword prologue_offset,
                              uword size,
                              bool optimized,
                              const CodeComments* comments) {
  ASSERT(!AreActive() || (strlen(name) != 0));
  for (intptr_t i = 0; i < observers_length_; i++) {
    if (observers_[i]->IsActive()) {
      observers_[i]->Notify(name, base, prologue_offset, size, optimized,
                            comments);
    }
  }
}

bool CodeObservers::AreActive() {
  for (intptr_t i = 0; i < observers_length_; i++) {
    if (observers_[i]->IsActive()) return true;
  }
  return false;
}

void CodeObservers::Cleanup() {
  for (intptr_t i = 0; i < observers_length_; i++) {
    delete observers_[i];
  }
  free(observers_);
  observers_length_ = 0;
  observers_ = NULL;
}

void CodeObservers::Init() {
  if (mutex_ == NULL) {
    mutex_ = new Mutex();
  }
  ASSERT(mutex_ != NULL);
  OS::RegisterCodeObservers();
}

#endif  // !PRODUCT

}  // namespace dart
