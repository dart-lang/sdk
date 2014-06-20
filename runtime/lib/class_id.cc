// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bootstrap_natives.h"

namespace dart {

DEFINE_NATIVE_ENTRY(ClassID_getID, 1) {
  const Instance& instance =
      Instance::CheckedHandle(isolate, arguments->NativeArgAt(0));
  return Smi::New(instance.GetClassId());
}

}  // namespace dart
