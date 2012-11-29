// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/vtune.h"

#include <jitprofiling.h>

#include "platform/assert.h"

namespace dart {

bool VTuneCodeObserver::IsActive() const {
  return (iJIT_IsProfilingActive() == iJIT_SAMPLING_ON);
}


void VTuneCodeObserver::Notify(const char* name,
                               uword base,
                               uword prologue_offset,
                               uword size,
                               bool optimized) {
  ASSERT(IsActive());
  iJIT_Method_Load jmethod;
  memset(&jmethod, 0, sizeof(jmethod));
  jmethod.method_id = iJIT_GetNewMethodID();
  jmethod.method_name = const_cast<char*>(name);
  jmethod.method_load_address = reinterpret_cast<void*>(base);
  jmethod.method_size = size;
  iJIT_NotifyEvent(iJVM_EVENT_TYPE_METHOD_LOAD_FINISHED, &jmethod);
}

}  // namespace dart
