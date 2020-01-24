// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_NATIVE_REPRESENTATION_H_
#define RUNTIME_VM_COMPILER_FFI_NATIVE_REPRESENTATION_H_

#include <platform/globals.h>

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/runtime_api.h"

namespace dart {

namespace compiler {

namespace ffi {

// Storage size for an FFI type (extends 'ffi.NativeType').
size_t ElementSizeInBytes(intptr_t class_id);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_NATIVE_REPRESENTATION_H_
