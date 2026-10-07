// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_AUTORELEASE_POOL_SCOPE_H_
#define RUNTIME_VM_AUTORELEASE_POOL_SCOPE_H_

#include "platform/allocation.h"
#include "platform/globals.h"

#if defined(DART_HOST_OS_MACOS)
extern "C" {
void* objc_autoreleasePoolPush(void);
void objc_autoreleasePoolPop(void* pool);
}
#endif

namespace dart {

// RAII scope for managing an Objective-C autorelease pool.
//
// On macOS and iOS, constructing this scope creates an autorelease pool that
// is released when this object is destroyed.
//
// On non-Apple platforms, this is a no-op.
class AutoreleasePoolScope : public ValueObject {
 public:
  AutoreleasePoolScope() {
#if defined(DART_HOST_OS_MACOS)
    pool_ = objc_autoreleasePoolPush();
#endif
  }

  ~AutoreleasePoolScope() {
#if defined(DART_HOST_OS_MACOS)
    objc_autoreleasePoolPop(pool_);
#endif
  }

 private:
#if defined(DART_HOST_OS_MACOS)
  void* pool_ = nullptr;
#endif

  DISALLOW_COPY_AND_ASSIGN(AutoreleasePoolScope);
};

}  // namespace dart

#endif  // RUNTIME_VM_AUTORELEASE_POOL_SCOPE_H_
