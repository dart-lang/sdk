// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_stack_resource.h"

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/thread.h"
#include "vm/zone.h"

namespace dart {

ThreadStackResource::~ThreadStackResource() {
#if defined(DEBUG)
  if (thread() != nullptr) {
    BaseIsolate::AssertCurrent(reinterpret_cast<BaseIsolate*>(isolate()));
  }
#endif
}

Isolate* ThreadStackResource::isolate() const {
  return thread()->isolate();
}

IsolateGroup* ThreadStackResource::isolate_group() const {
  return thread()->isolate_group();
}

}  // namespace dart
