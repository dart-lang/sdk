// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_
#define RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <platform/globals.h>

#include "platform/assert.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/object.h"

namespace dart {

namespace compiler {

namespace ffi {

// Values below 0 index result (result might be multiple if composite).
const intptr_t kResultIndex = -1;

// Provides the mapping from the native calling convention to the Dart calling
// convention.
//
// This class is set up in a query-able way so that it's underlying logic can
// be extended to support more native ABI features and calling conventions.
class BaseMarshaller : public ZoneAllocated {
 public:
  intptr_t num_args() const {
    return native_calling_convention_.argument_locations().length();
  }

  // Number of definitions passed to FfiCall, number of NativeParams, or number
  // of definitions passed to NativeReturn in IL.
  //
  // All non-struct values have 1 definition, struct values can have either 1
  // or multiple definitions. If a struct has multiple definitions, they either
  // correspond to the number of native locations in the native ABI or to word-
  // sized chunks.
  //
  // `arg_index` is the index of an argument.
  // `def_index_in_argument` is the definition in one argument.
  // `def_index_global` is the index of the definition in all arguments.
  intptr_t NumDefinitions() const;
  intptr_t NumDefinitions(intptr_t arg_index) const;
  intptr_t NumReturnDefinitions() const;
  bool ArgumentIndexIsReturn(intptr_t arg_index) const;
  bool DefinitionIndexIsReturn(intptr_t def_index_global) const;
  intptr_t ArgumentIndex(intptr_t def_index_global) const;
  intptr_t FirstDefinitionIndex(intptr_t arg_index) const;
  intptr_t DefinitionInArgument(intptr_t def_index_global,
                                intptr_t arg_index) const;
  intptr_t DefinitionIndex(intptr_t def_index_in_arg, intptr_t arg_index) const;

  // The location of the argument at `arg_index`.
  const NativeLocation& Location(intptr_t arg_index) const {
    if (arg_index == kResultIndex) {
      return native_calling_convention_.return_location();
    }
    return *native_calling_convention_.argument_locations().At(arg_index);
  }

  // Unboxed representation on how the value is passed or received from regular
  // Dart code.
  //
  // Implemented in BaseMarshaller because most Representations are the same
  // in Calls and Callbacks.
  Representation RepInDart(intptr_t arg_index) const {
    return Location(arg_index).payload_type().AsRepresentationOverApprox(zone_);
  }

  // Representation on how the value is passed to or recieved from the FfiCall
  // instruction or StaticCall, NativeParameter, and NativeReturn instructions.
  virtual Representation RepInFfiCall(intptr_t def_index_global) const;
  void RepsInFfiCall(intptr_t arg_index,
                     GrowableArray<Representation>* out) const;

  // Bitcasting floats to ints, only required in SoftFP.
  bool RequiresBitCast(intptr_t index) const {
    return Location(index).payload_type().IsFloat() &&
           Location(index).container_type().IsInt();
  }

  // 8 or 16 bit int value to sign extend from.
  const NativeType& SignExtendFrom(intptr_t arg_index) const {
    return Location(arg_index).payload_type();
  }

  // The C Type (expressed in a Dart Type) of the argument at `arg_index`.
  //
  // Excluding the #0 argument which is the function pointer.
  AbstractTypePtr CType(intptr_t arg_index) const;

  // Requires boxing or unboxing.
  bool IsPointer(intptr_t arg_index) const {
    return AbstractType::Handle(zone_, CType(arg_index)).type_class_id() ==
           kFfiPointerCid;
  }
  bool IsHandle(intptr_t arg_index) const {
    return AbstractType::Handle(zone_, CType(arg_index)).type_class_id() ==
           kFfiHandleCid;
  }

  bool IsStruct(intptr_t arg_index) const {
    const auto& type = AbstractType::Handle(zone_, CType(arg_index));
    const bool predefined = IsFfiTypeClassId(type.type_class_id());
    return !predefined;
  }

  // Treated as a null constant in Dart.
  bool IsVoid(intptr_t arg_index) const {
    return AbstractType::Handle(zone_, CType(arg_index)).type_class_id() ==
           kFfiVoidCid;
  }

  bool ContainsHandles() const;

  StringPtr function_name() const { return dart_signature_.name(); }

 protected:
  BaseMarshaller(Zone* zone, const Function& dart_signature);

  ~BaseMarshaller() {}

  Zone* zone_;
  // Contains the function pointer as argument #0.
  // The Dart signature is used for the function and argument names.
  const Function& dart_signature_;
  const Function& c_signature_;
  const NativeCallingConvention& native_calling_convention_;
};

class CallMarshaller : public BaseMarshaller {
 public:
  CallMarshaller(Zone* zone, const Function& dart_signature)
      : BaseMarshaller(zone, dart_signature) {}

  virtual Representation RepInFfiCall(intptr_t def_index_global) const;

  // The location of the inputs to the IL FfiCall instruction.
  dart::Location LocInFfiCall(intptr_t def_index_global) const;

  // Allocate a TypedData before the FfiCall and pass it in to the FfiCall so
  // that it can be populated in assembly.
  bool PassTypedData() const;
  intptr_t TypedDataSizeInBytes() const;

  // We allocate space for PointerToMemory arguments and PointerToMemory return
  // locations on the stack. This is faster than allocation ExternalTypedData.
  // Normal TypedData is not an option, as these might be relocated by GC
  // during FFI calls.
  intptr_t PassByPointerStackOffset(intptr_t arg_index) const;

  // The total amount of stack space required for FFI trampolines.
  intptr_t RequiredStackSpaceInBytes() const;

 protected:
  ~CallMarshaller() {}
};

class CallbackMarshaller : public BaseMarshaller {
 public:
  CallbackMarshaller(Zone* zone, const Function& dart_signature);

  virtual Representation RepInFfiCall(intptr_t def_index_global) const;

  // All parameters are saved on stack to do safe-point transition.
  const NativeLocation& NativeLocationOfNativeParameter(
      intptr_t def_index) const;

  // All parameters are saved on stack to do safe-point transition.
  dart::Location LocationOfNativeParameter(intptr_t def_index) const {
    const auto& native_loc = NativeLocationOfNativeParameter(def_index);
    if (native_loc.IsPointerToMemory()) {
      return native_loc.AsPointerToMemory().pointer_location().AsLocation();
    }
    return native_loc.AsLocation();
  }

 protected:
  ~CallbackMarshaller() {}

  const NativeLocations& callback_locs_;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_
