// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_COUNTERS_H_
#define VM_COUNTERS_H_

#include "platform/assert.h"

namespace dart {

struct Counter {
  Counter() : name(NULL), value(0) {}
  const char* name;
  int64_t value;
};


// Light-weight stats counters for temporary experiments/debugging.
// A single statement is enough to add a counter:
//   ...
//   Isolate::Current()->counters()->Increment("allocated", size_in_bytes);
//   ...
class Counters {
 public:
  Counters() : collision_(false) {}

  // Adds 'delta' to the named counter. 'name' must be a literal string.
  void Increment(const char* name, int64_t delta) {
    Counter& counter =
      counters_[reinterpret_cast<uword>(name) & (kSize - 1)];
    if (counter.name != name && counter.name != NULL) {
      collision_ = true;
    }
    counter.name = name;
    counter.value += delta;
  }

  // Prints all counters to stderr.
  ~Counters();

 private:
  enum { kSize = 1024 };
  COMPILE_ASSERT((0 == (kSize & (kSize - 1))));  // kSize is a power of 2.
  Counter counters_[kSize];
  bool collision_;
};

}  // namespace dart

#endif  // VM_COUNTERS_H_
