// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_OBSERVERS_H_
#define VM_CODE_OBSERVERS_H_

#include "vm/globals.h"

namespace dart {

// Object observing code creation events. Used by external profilers and
// debuggers to map address ranges to function names.
class CodeObserver {
 public:
  virtual ~CodeObserver() { }

  // Returns true if this observer is active and should be notified
  // about newly created code objects.
  virtual bool IsActive() const = 0;

  // Notify code observer about a newly created code object with the
  // given properties.
  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized) = 0;
};


class CodeObservers {
 public:
  static void InitOnce();

  static void Register(CodeObserver* observer);

  // Notify all active code observers about a newly created code object.
  static void NotifyAll(const char* name,
                        uword base,
                        uword prologue_offset,
                        uword size,
                        bool optimized);

  // Returns true if there is at least one active code observer.
  static bool AreActive();

 private:
  static intptr_t observers_length_;
  static CodeObserver** observers_;
};


}  // namespace dart

#endif  // VM_CODE_OBSERVERS_H_
