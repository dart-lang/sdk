// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/object.h"
#include "vm/os.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Stopwatch_now, 0) {
  // TODO(iposva): investigate other hi-res time sources such as cycle count.
  return Integer::New(OS::GetCurrentTimeMicros());
}


DEFINE_NATIVE_ENTRY(Stopwatch_frequency, 0) {
  // TODO(iposva): investigate other hi-res time sources such as cycle count.
  return Integer::New(1000000);
}

}  // namespace dart
