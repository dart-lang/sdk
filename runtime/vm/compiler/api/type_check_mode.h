// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_API_TYPE_CHECK_MODE_H_
#define RUNTIME_VM_COMPILER_API_TYPE_CHECK_MODE_H_

namespace dart {

// Invocation mode for TypeCheck runtime entry that describes
// where we are calling it from.
enum TypeCheckMode {
  // TypeCheck is invoked from LazySpecializeTypeTest stub.
  // It should replace stub on the type with a specialized version.
  kTypeCheckFromLazySpecializeStub,

  // TypeCheck is invoked from the SlowTypeTest stub.
  // This means that cache can be lazily created (if needed)
  // and dst_name can be fetched from the pool.
  kTypeCheckFromSlowStub,

  // TypeCheck is invoked from normal inline AssertAssignable.
  // Both cache and dst_name must be already populated.
  kTypeCheckFromInline
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_API_TYPE_CHECK_MODE_H_
