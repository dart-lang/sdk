// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_H_
#define VM_THREAD_H_

#include "vm/isolate.h"

namespace dart {

// A VM thread; may be executing Dart code or performing helper tasks like
// garbage collection or compilation.
class Thread {
 public:
  static Thread* Current() {
    // For now, there is still just one thread per isolate, and the Thread
    // class just aliases the Isolate*. Once all interfaces and uses have been
    // updated to distinguish between isolates and threads, Thread will get its
    // own thread-local storage key and fields.
    return reinterpret_cast<Thread*>(Isolate::Current());
  }
  // TODO(koda): Remove after pivoting to Thread* in native/runtime entries.
  static Thread* CurrentFromCurrentIsolate(BaseIsolate* isolate) {
    ASSERT(Isolate::Current() == isolate);
    return reinterpret_cast<Thread*>(isolate);
  }

  // The topmost zone used for allocation in this thread.
  Zone* zone() {
    return reinterpret_cast<BaseIsolate*>(this)->current_zone();
  }

  // The isolate that this thread is operating on.
  Isolate* isolate() { return reinterpret_cast<Isolate*>(this); }
  const Isolate* isolate() const {
    return reinterpret_cast<const Isolate*>(this);
  }

  // The log for this thread.
  class Log* Log() {
    return reinterpret_cast<Isolate*>(this)->Log();
  }

  // The (topmost) CHA for the compilation in this thread.
  CHA* cha() const { return isolate()->cha(); }
  void set_cha(CHA* value) { isolate()->set_cha(value); }

 private:
  DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace dart

#endif  // VM_THREAD_H_
