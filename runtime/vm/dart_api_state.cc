// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_state.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/thread.h"
#include "vm/timeline.h"

namespace dart {

intptr_t ApiNativeScope::current_memory_usage_ = 0;

}  // namespace dart
