// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/object.h"
#include "vm/os.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Stopwatch_now, 0) {
  // TODO(iposva): investigate other hi-res time sources such as cycle count.
  const Integer& micros =
      Integer::Handle(Integer::New(OS::GetCurrentTimeMicros()));
  arguments->SetReturn(micros);
}


DEFINE_NATIVE_ENTRY(Stopwatch_frequency, 0) {
  // TODO(iposva): investigate other hi-res time sources such as cycle count.
  const Integer& frequency = Integer::Handle(Integer::New(1000000));
  arguments->SetReturn(frequency);
}

}  // namespace dart
