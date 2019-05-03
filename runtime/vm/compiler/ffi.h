// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_H_
#define RUNTIME_VM_COMPILER_FFI_H_

#include <platform/globals.h>

#include "../class_id.h"
#include "../object.h"
#include "../raw_object.h"
#include "backend/locations.h"

namespace dart {

namespace compiler {

namespace ffi {

// On all supported platforms, the minimum width an argument must be sign- or
// zero-extended to is 4 bytes.
constexpr intptr_t kMinimumArgumentWidth = 4;

// Storage size for an FFI type (extends 'ffi.NativeType').
size_t ElementSizeInBytes(intptr_t class_id);

// Unboxed representation of an FFI type (extends 'ffi.NativeType').
Representation TypeRepresentation(const AbstractType& result_type);

// Whether a type which extends 'ffi.NativeType' also extends 'ffi.Pointer'.
bool NativeTypeIsPointer(const AbstractType& result_type);

// Whether a type is 'ffi.Void'.
bool NativeTypeIsVoid(const AbstractType& result_type);

// Unboxed representation of the result of a C signature function.
Representation ResultRepresentation(const Function& signature);

// Location for the result of a C signature function.
Location ResultLocation(Representation result_rep);

// Unboxed representations of the arguments to a C signature function.
ZoneGrowableArray<Representation>* ArgumentRepresentations(
    const Function& signature);

// Location for the arguments of a C signature function.
ZoneGrowableArray<Location>* ArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_reps);

// Number of stack slots used in 'locations'.
intptr_t NumStackSlots(const ZoneGrowableArray<Location>& locations);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_H_
