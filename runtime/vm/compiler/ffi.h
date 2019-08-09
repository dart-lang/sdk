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

// These ABIs should be kept in sync with pkg/vm/lib/transformations/ffi.dart.
enum class Abi {
  kWordSize64 = 0,
  kWordSize32Align32 = 1,
  kWordSize32Align64 = 2
};

// The target ABI. Defines sizes and alignment of native types.
Abi TargetAbi();

// Unboxed representation of an FFI type (extends 'ffi.NativeType').
Representation TypeRepresentation(const AbstractType& result_type);

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

#if !defined(TARGET_ARCH_DBC)

// Unboxed representations of the arguments to a C signature function.
ZoneGrowableArray<Representation>* ArgumentRepresentations(
    const Function& signature);

// Unboxed representation of the result of a C signature function.
Representation ResultRepresentation(const Function& signature);

#endif  // !defined(TARGET_ARCH_DBC)

#if defined(USING_SIMULATOR)

// Unboxed host representations of the arguments to a C signature function.
ZoneGrowableArray<Representation>* ArgumentHostRepresentations(
    const Function& signature);

// Unboxed host representation of the result of a C signature function.
Representation ResultHostRepresentation(const Function& signature);

#endif  // defined(USING_SIMULATOR)

// Location for the arguments of a C signature function.
ZoneGrowableArray<Location>* ArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_reps);

// Number of stack slots used in 'locations'.
intptr_t NumStackSlots(const ZoneGrowableArray<Location>& locations);

#if defined(TARGET_ARCH_DBC)

// The first argument to a ffi trampoline is the function address, the arguments
// to the call follow the function address.
const intptr_t kFunctionAddressRegister = 0;
const intptr_t kFirstArgumentRegister = 1;

// Location in host for the arguments of a C signature function.
ZoneGrowableArray<HostLocation>* HostArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_reps);

// A signature descriptor consists of the signature length, argument locations,
// and result representation.
class FfiSignatureDescriptor : public ValueObject {
 public:
  explicit FfiSignatureDescriptor(const TypedData& typed_data)
      : typed_data_(typed_data) {}

  static RawTypedData* New(
      const ZoneGrowableArray<HostLocation>& arg_host_locations,
      const Representation result_representation);

  intptr_t length() const;
  intptr_t num_stack_slots() const;
  HostLocation LocationAt(intptr_t index) const;
  Representation ResultRepresentation() const;

 private:
  const TypedData& typed_data_;

  static const intptr_t kOffsetNumArguments = 0;
  static const intptr_t kOffsetNumStackSlots = 1;
  static const intptr_t kOffsetResultRepresentation = 2;
  static const intptr_t kOffsetArgumentLocations = 3;
};

#endif  // defined(TARGET_ARCH_DBC)

// This classes translates the ABI location of arguments into the locations they
// will inhabit after entry-frame setup in the invocation of a native callback.
//
// Native -> Dart callbacks must push all the arguments before executing any
// Dart code because the reading the Thread from TLS requires calling a native
// stub, and the argument registers are volatile on all ABIs we support.
//
// To avoid complicating initial definitions, all callback arguments are read
// off the stack from their pushed locations, so this class updates the argument
// positions to account for this.
//
// See 'NativeEntryInstr::EmitNativeCode' for details.
class CallbackArgumentTranslator : public ValueObject {
 public:
  static ZoneGrowableArray<Location>* TranslateArgumentLocations(
      const ZoneGrowableArray<Location>& arg_locs);

 private:
  void AllocateArgument(Location arg);
  Location TranslateArgument(Location arg);

  intptr_t argument_slots_used_ = 0;
  intptr_t argument_slots_required_ = 0;
};

bool IsAsFunctionInternal(Zone* zone, Isolate* isolate, const Function& func);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_H_
