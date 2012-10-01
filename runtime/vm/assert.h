// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSERT_H_
#define VM_ASSERT_H_

#include "platform/assert.h"
#include "vm/flags.h"

namespace dart {

DECLARE_FLAG(bool, slow_asserts);

// SLOW_ASSERT is used for slow assertion code and disabled by default.
#if defined(DEBUG)
#define SLOW_ASSERT(cond) ASSERT(!FLAG_slow_asserts || (cond))
#else
#define SLOW_ASSERT(cond)
#endif

}  // namespace dart

#endif  // VM_ASSERT_H_
