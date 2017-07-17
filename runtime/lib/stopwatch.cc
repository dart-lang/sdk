// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/object.h"
#include "vm/os.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Stopwatch_now, 0) {
  return Integer::New(OS::GetCurrentMonotonicTicks());
}

DEFINE_NATIVE_ENTRY(Stopwatch_frequency, 0) {
  return Integer::New(OS::GetCurrentMonotonicFrequency());
}

}  // namespace dart
