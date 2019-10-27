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

// TypedData class id for a NativeType type, except for Void and NativeFunction.
classid_t ElementTypedDataCid(classid_t class_id);

// Returns the kFFi<type>Cid for the recognized load/store method [kind].
classid_t RecognizedMethodTypeArgCid(MethodRecognizer::Kind kind);

// These ABIs should be kept in sync with pkg/vm/lib/transformations/ffi.dart.
enum class Abi {
  kWordSize64 = 0,
  kWordSize32Align32 = 1,
  kWordSize32Align64 = 2
};

// The target ABI. Defines sizes and alignment of native types.
Abi TargetAbi();

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

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_H_
