// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_
#define RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include <platform/globals.h>

#include "vm/compiler/backend/locations.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/ffi/native_calling_convention.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/object.h"

namespace dart {

namespace compiler {

namespace ffi {

// Provides the mapping from the native calling convention to the Dart calling
// convention.
//
// This class is set up in a query-able way so that it's underlying logic can
// be extended to support more native ABI features and calling conventions.
//
// TODO(36730): Add a way to query arguments that are broken into multiple
// parts.
class BaseMarshaller : public NativeCallingConvention {
 public:
  // Unboxed representation on how the value is passed or received from regular
  // Dart code.
  Representation RepInDart(intptr_t arg_index) const {
    return Location(arg_index).payload_type().AsRepresentationOverApprox(zone_);
  }

  // Representation on how the value is passed to or recieved from the FfiCall
  // instruction or StaticCall, NativeParameter, and NativeReturn instructions.
  Representation RepInFfiCall(intptr_t arg_index) const {
    if (Location(arg_index).container_type().IsInt() &&
        Location(arg_index).payload_type().IsFloat()) {
      return Location(arg_index).container_type().AsRepresentationOverApprox(
          zone_);
    }
    return Location(arg_index).payload_type().AsRepresentationOverApprox(zone_);
  }

  // Bitcasting floats to ints, only required in SoftFP.
  bool RequiresBitCast(intptr_t index) const {
    return Location(index).payload_type().IsFloat() &&
           Location(index).container_type().IsInt();
  }

  // 8 or 16 bit int value to sign extend from.
  const NativeType& SignExtendFrom(intptr_t arg_index) const {
    return Location(arg_index).payload_type();
  }

  // Requires boxing or unboxing.
  bool IsPointer(intptr_t arg_index) const {
    return AbstractType::Handle(zone_, CType(arg_index)).type_class_id() ==
           kFfiPointerCid;
  }
  bool IsHandle(intptr_t arg_index) const {
    return AbstractType::Handle(zone_, CType(arg_index)).type_class_id() ==
           kFfiHandleCid;
  }

  // Treated as a null constant in Dart.
  bool IsVoid(intptr_t arg_index) const {
    return AbstractType::Handle(zone_, CType(arg_index)).type_class_id() ==
           kFfiVoidCid;
  }

  bool ContainsHandles() const;

  StringPtr function_name() const { return dart_signature_.name(); }

 protected:
  BaseMarshaller(Zone* zone, const Function& dart_signature)
      : NativeCallingConvention(
            zone,
            Function::ZoneHandle(zone, dart_signature.FfiCSignature())),
        dart_signature_(dart_signature) {
    ASSERT(dart_signature_.IsZoneHandle());
  }

 private:
  // Contains the function pointer as argument #0.
  // The Dart signature is used for the function and argument names.
  const Function& dart_signature_;
};

class CallMarshaller : public BaseMarshaller {
 public:
  CallMarshaller(Zone* zone, const Function& dart_signature)
      : BaseMarshaller(zone, dart_signature) {}

  dart::Location LocInFfiCall(intptr_t arg_index) const;
};

class CallbackMarshaller : public BaseMarshaller {
 public:
  CallbackMarshaller(Zone* zone, const Function& dart_signature);

  // All parameters are saved on stack to do safe-point transition.
  const NativeLocation& NativeLocationOfNativeParameter(
      intptr_t arg_index) const {
    if (arg_index == kResultIndex) {
      // No moving around of result.
      return Location(arg_index);
    }
    return *callback_locs_.At(arg_index);
  }

  // All parameters are saved on stack to do safe-point transition.
  dart::Location LocationOfNativeParameter(intptr_t arg_index) const {
    return NativeLocationOfNativeParameter(arg_index).AsLocation();
  }

 protected:
  const NativeLocations& callback_locs_;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_MARSHALLER_H_
