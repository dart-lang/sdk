// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_
#define RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_

#include <platform/globals.h>

#include "vm/compiler/backend/locations.h"

namespace dart {

namespace compiler {

namespace ffi {

// Unboxed representation of an FFI type (extends 'ffi.NativeType').
Representation TypeRepresentation(classid_t class_id);

// Unboxed representation of an FFI type (extends 'ffi.NativeType') for 8 and 16
// bit integers.
SmallRepresentation TypeSmallRepresentation(const AbstractType& result_type);

// Whether a type which extends 'ffi.NativeType' also extends 'ffi.Pointer'.
bool NativeTypeIsPointer(const AbstractType& result_type);

// Whether a type is 'ffi.Void'.
bool NativeTypeIsVoid(const AbstractType& result_type);

// Location for the result of a C signature function.
Location ResultLocation(Representation result_rep);

RawFunction* TrampolineFunction(const Function& dart_signature,
                                const Function& c_signature);

RawFunction* NativeCallbackFunction(const Function& c_signature,
                                    const Function& dart_target,
                                    const Instance& exceptional_return);

// Unboxed representations of the arguments to a C signature function.
ZoneGrowableArray<Representation>* ArgumentRepresentations(
    const Function& signature);

// Unboxed representation of the result of a C signature function.
Representation ResultRepresentation(const Function& signature);

// Location for the arguments of a C signature function.
ZoneGrowableArray<Location>* ArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_reps);

// Number of stack slots used in 'locations'.
intptr_t NumStackSlots(const ZoneGrowableArray<Location>& locations);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_NATIVE_CALLING_CONVENTION_H_
