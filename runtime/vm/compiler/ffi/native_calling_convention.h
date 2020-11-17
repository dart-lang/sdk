// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_
#define RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "platform/globals.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"

namespace dart {

namespace compiler {

namespace ffi {

using NativeLocations = ZoneGrowableArray<const NativeLocation*>;

// Calculates native calling convention, is not aware of Dart calling
// convention constraints.
//
// This class is meant to beembedded in a class that is aware of Dart calling
// convention constraints.
class NativeCallingConvention : public ZoneAllocated {
 public:
  static const NativeCallingConvention& FromSignature(
      Zone* zone,
      const NativeFunctionType& signature);

  const NativeLocations& argument_locations() const {
    return argument_locations_;
  }
  const NativeLocation& return_location() const { return return_location_; }

  intptr_t StackTopInBytes() const;

  void PrintTo(BaseTextBuffer* f, bool multi_line = false) const;
  void PrintToMultiLine(BaseTextBuffer* f) const;
  const char* ToCString(Zone* zone, bool multi_line = false) const;
#if !defined(FFI_UNIT_TESTS)
  const char* ToCString(bool multi_line = false) const;
#endif

 private:
  NativeCallingConvention(const NativeLocations& argument_locations,
                          const NativeLocation& return_location)
      : argument_locations_(argument_locations),
        return_location_(return_location) {}

  const NativeLocations& argument_locations_;
  const NativeLocation& return_location_;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_
