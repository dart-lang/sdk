// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_NATIVE_TYPE_H_
#define RUNTIME_VM_COMPILER_FFI_NATIVE_TYPE_H_

#include <platform/globals.h>

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/compiler/runtime_api.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/backend/locations.h"
#endif

namespace dart {

class BufferFormatter;

namespace compiler {

namespace ffi {

class NativeFundamentalType;

// NativeTypes are the types used in calling convention specifications:
// integers, floats, and composites.
//
// NativeTypes exclude C types which are not discussed in calling conventions:
// pointer types (they are lowered to integers).
//
// The NativeTypes are a partially overlapping with unboxed Representations.
// NativeTypes do not have Dart representations such as the following:
// * tagged
// * untagged
//
// Instead, NativeTypes support representations not supported in Dart's unboxed
// Representations, such as:
// * Fundamental types (https://en.cppreference.com/w/cpp/language/types):
//   * int8_t
//   * int16_t
//   * uint8_t
//   * uint16t
//   * void
// * Compound types (https://en.cppreference.com/w/cpp/language/type):
//   * Struct
//   * Union
//
// TODO(36730): Add composites.
class NativeType : public ZoneAllocated {
 public:
  static NativeType& FromAbstractType(const AbstractType& type, Zone* zone);
  static NativeType& FromTypedDataClassId(classid_t class_id, Zone* zone);

#if !defined(DART_PRECOMPILED_RUNTIME)
  static NativeFundamentalType& FromUnboxedRepresentation(Representation rep,
                                                          Zone* zone);
#endif

  virtual bool IsFundamental() const { return false; }
  const NativeFundamentalType& AsFundamental() const;

  virtual bool IsInt() const { return false; }
  virtual bool IsFloat() const { return false; }
  virtual bool IsVoid() const { return false; }

  virtual bool IsSigned() const = 0;

  // The size in bytes of this representation.
  //
  // Does not take into account padding required if repeating.
  virtual intptr_t SizeInBytes() const = 0;

  // The alignment in bytes of this represntation on the stack.
  virtual intptr_t AlignmentInBytesStack() const = 0;

  // The alignment in bytes of this representation as member of a composite.
  virtual intptr_t AlignmentInBytesField() const = 0;

#if !defined(DART_PRECOMPILED_RUNTIME)
  // NativeTypes which are available as unboxed Representations.
  virtual bool IsExpressibleAsRepresentation() const { return false; }

  // Unboxed Representation if it exists.
  virtual Representation AsRepresentation() const = 0;

  // Unboxed Representation, over approximates if needed.
  Representation AsRepresentationOverApprox(Zone* zone_) const {
    const auto& widened = WidenTo4Bytes(zone_);
    return widened.AsRepresentation();
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  virtual bool Equals(const NativeType& other) const { UNREACHABLE(); }

  // Split representation in two.
  virtual NativeType& Split(intptr_t index, Zone* zone) const { UNREACHABLE(); }

  // If this is a 8 or 16 bit int, returns a 32 bit container.
  // Otherwise, return original representation.
  const NativeType& WidenTo4Bytes(Zone* zone) const;

  virtual void PrintTo(BufferFormatter* f) const;
  const char* ToCString() const;

  virtual ~NativeType() {}

 protected:
  NativeType() {}
};

enum FundamentalType {
  kInt8,
  kUint8,
  kInt16,
  kUint16,
  kInt32,
  kUint32,
  kInt64,
  kUint64,
  kFloat,
  kDouble,
  kHalfDouble,  // When doubles are split over two 32 bit locations.
  kVoid,
  // TODO(37470): Add packed data structures.
};

class NativeFundamentalType : public NativeType {
 public:
  explicit NativeFundamentalType(FundamentalType rep) : representation_(rep) {}

  FundamentalType representation() const { return representation_; }

  virtual bool IsFundamental() const { return true; }

  virtual bool IsInt() const;
  virtual bool IsFloat() const;
  virtual bool IsVoid() const;

  virtual bool IsSigned() const;

  virtual intptr_t SizeInBytes() const;
  virtual intptr_t AlignmentInBytesStack() const;
  virtual intptr_t AlignmentInBytesField() const;

#if !defined(DART_PRECOMPILED_RUNTIME)
  virtual bool IsExpressibleAsRepresentation() const;
  virtual Representation AsRepresentation() const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  virtual bool Equals(const NativeType& other) const;
  virtual NativeFundamentalType& Split(intptr_t part, Zone* zone) const;

  virtual void PrintTo(BufferFormatter* f) const;

  virtual ~NativeFundamentalType() {}

 private:
  const FundamentalType representation_;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_NATIVE_TYPE_H_
