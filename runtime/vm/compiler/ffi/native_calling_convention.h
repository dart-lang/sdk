// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_
#define RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <platform/globals.h>

#include "vm/compiler/backend/locations.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"

namespace dart {

namespace compiler {

namespace ffi {

using NativeLocations = ZoneGrowableArray<const NativeLocation*>;


// Values below 0 index result (result might be multiple if composite).
const intptr_t kResultIndex = -1;

// Calculates native calling convention, is not aware of Dart calling
// convention constraints.
//
// This class is meant to be extended or embedded in a class that is aware
// of Dart calling convention constraints.
class NativeCallingConvention : public ZoneAllocated {
 public:
  NativeCallingConvention(Zone* zone, const Function& c_signature);

  // Excluding the #0 argument which is the function pointer.
  intptr_t num_args() const;

  // The C Type (expressed in a Dart Type) of the argument at `arg_index`.
  //
  // Excluding the #0 argument which is the function pointer.
  AbstractTypePtr CType(intptr_t arg_index) const;

  // The location of the argument at `arg_index`.
  const NativeLocation& Location(intptr_t arg_index) const {
    if (arg_index == kResultIndex) {
      return result_loc_;
    }
    return *arg_locs_.At(arg_index);
  }

  intptr_t StackTopInBytes() const;

 protected:
  Zone* const zone_;
  // Contains the function pointer as argument #0.
  const Function& c_signature_;
  const NativeLocations& arg_locs_;
  const NativeLocation& result_loc_;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_
