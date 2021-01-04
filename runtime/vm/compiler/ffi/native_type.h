// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_NATIVE_TYPE_H_
#define RUNTIME_VM_COMPILER_FFI_NATIVE_TYPE_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/growable_array.h"

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)
#include "vm/compiler/backend/locations.h"
#endif
#if !defined(FFI_UNIT_TESTS)
#include "vm/object.h"
#endif

namespace dart {

class BaseTextBuffer;

namespace compiler {

namespace ffi {

class NativePrimitiveType;
class NativeCompoundType;

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
// * Primitive types (https://en.cppreference.com/w/cpp/language/types):
//   * int8_t
//   * int16_t
//   * uint8_t
//   * uint16t
//   * void
// * Compound types (https://en.cppreference.com/w/cpp/language/type):
//   * Struct
//   * Union
class NativeType : public ZoneAllocated {
 public:
#if !defined(FFI_UNIT_TESTS)
  static NativeType& FromAbstractType(Zone* zone, const AbstractType& type);
#endif
  static NativeType& FromTypedDataClassId(Zone* zone, classid_t class_id);

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)
  static NativePrimitiveType& FromUnboxedRepresentation(Zone* zone,
                                                        Representation rep);
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)

  virtual bool IsPrimitive() const { return false; }
  const NativePrimitiveType& AsPrimitive() const;
  virtual bool IsCompound() const { return false; }
  const NativeCompoundType& AsCompound() const;

  virtual bool IsInt() const { return false; }
  virtual bool IsFloat() const { return false; }
  virtual bool IsVoid() const { return false; }

  virtual bool IsSigned() const { return false; }

  // The size in bytes of this representation.
  //
  // Does not take into account padding required if repeating.
  virtual intptr_t SizeInBytes() const = 0;

  // The alignment in bytes of this represntation on the stack.
  virtual intptr_t AlignmentInBytesStack() const = 0;

  // The alignment in bytes of this representation as member of a composite.
  virtual intptr_t AlignmentInBytesField() const = 0;

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)
  // NativeTypes which are available as unboxed Representations.
  virtual bool IsExpressibleAsRepresentation() const { return false; }

  // Unboxed Representation if it exists.
  virtual Representation AsRepresentation() const { UNREACHABLE(); }

  // Unboxed Representation, over approximates if needed.
  Representation AsRepresentationOverApprox(Zone* zone_) const {
    const auto& widened = WidenTo4Bytes(zone_);
    return widened.AsRepresentation();
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)

  virtual bool Equals(const NativeType& other) const { UNREACHABLE(); }

  // Split representation in two.
  virtual NativeType& Split(Zone* zone, intptr_t index) const { UNREACHABLE(); }

  // If this is a 8 or 16 bit int, returns a 32 bit container.
  // Otherwise, return original representation.
  const NativeType& WidenTo4Bytes(Zone* zone) const;

  virtual void PrintTo(BaseTextBuffer* f,
                       bool multi_line = false,
                       bool verbose = true) const;
  const char* ToCString(Zone* zone,
                        bool multi_line = false,
                        bool verbose = true) const;
#if !defined(FFI_UNIT_TESTS)
  const char* ToCString() const;
#endif

  virtual intptr_t NumPrimitiveMembersRecursive() const { UNREACHABLE(); }
  virtual const NativePrimitiveType& FirstPrimitiveMember() const {
    UNREACHABLE();
  }

  virtual ~NativeType() {}

 protected:
  NativeType() {}
};

enum PrimitiveType {
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

PrimitiveType PrimitiveTypeFromSizeInBytes(intptr_t size);

// Represents a primitive native type.
//
// These are called object types in the C standard (ISO/IEC 9899:2011) and
// fundamental types in C++ (https://en.cppreference.com/w/cpp/language/types)
// but more commonly these are called primitive types
// (https://en.wikipedia.org/wiki/Primitive_data_type).
class NativePrimitiveType : public NativeType {
 public:
  explicit NativePrimitiveType(PrimitiveType rep) : representation_(rep) {}

  PrimitiveType representation() const { return representation_; }

  virtual bool IsPrimitive() const { return true; }

  virtual bool IsInt() const;
  virtual bool IsFloat() const;
  virtual bool IsVoid() const;

  virtual bool IsSigned() const;

  virtual intptr_t SizeInBytes() const;
  virtual intptr_t AlignmentInBytesStack() const;
  virtual intptr_t AlignmentInBytesField() const;

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)
  virtual bool IsExpressibleAsRepresentation() const;
  virtual Representation AsRepresentation() const;
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(FFI_UNIT_TESTS)

  virtual bool Equals(const NativeType& other) const;
  virtual NativePrimitiveType& Split(Zone* zone, intptr_t part) const;

  virtual void PrintTo(BaseTextBuffer* f,
                       bool multi_line = false,
                       bool verbose = true) const;

  virtual intptr_t NumPrimitiveMembersRecursive() const;
  virtual const NativePrimitiveType& FirstPrimitiveMember() const;

  virtual ~NativePrimitiveType() {}

 private:
  const PrimitiveType representation_;
};

using NativeTypes = ZoneGrowableArray<const NativeType*>;

// Struct
//
// TODO(dartbug.com/38491): Support unions.
// TODO(dartbug.com/35763): Support inline fixed-length arrays.
class NativeCompoundType : public NativeType {
 public:
  static NativeCompoundType& FromNativeTypes(Zone* zone,
                                             const NativeTypes& members);

  const NativeTypes& members() const { return members_; }
  const ZoneGrowableArray<intptr_t>& member_offsets() const {
    return member_offsets_;
  }

  virtual bool IsCompound() const { return true; }

  virtual intptr_t SizeInBytes() const { return size_; }
  virtual intptr_t AlignmentInBytesField() const { return alignment_field_; }
  virtual intptr_t AlignmentInBytesStack() const { return alignment_stack_; }

  virtual bool Equals(const NativeType& other) const;

  virtual void PrintTo(BaseTextBuffer* f,
                       bool multi_line = false,
                       bool verbose = true) const;

  // Whether a range within a struct contains only floats.
  //
  // Useful for determining whether struct is passed in FP registers on x64.
  bool ContainsOnlyFloats(intptr_t offset_in_bytes,
                          intptr_t size_in_bytes) const;

  // Returns how many word-sized chuncks _only_ contain floats.
  //
  // Useful for determining whether struct is passed in FP registers on x64.
  intptr_t NumberOfWordSizeChunksOnlyFloat() const;

  // Returns how many word-sized chunks do not _only_ contain floats.
  //
  // Useful for determining whether struct is passed in FP registers on x64.
  intptr_t NumberOfWordSizeChunksNotOnlyFloat() const;

  // Whether this type has only same-size floating point members.
  //
  // Useful for determining whether struct is passed in FP registers in hardfp
  // and arm64.
  bool ContainsHomogenuousFloats() const;

  virtual intptr_t NumPrimitiveMembersRecursive() const;
  virtual const NativePrimitiveType& FirstPrimitiveMember() const;

 private:
  NativeCompoundType(const NativeTypes& members,
                     const ZoneGrowableArray<intptr_t>& member_offsets,
                     intptr_t size,
                     intptr_t alignment_field,
                     intptr_t alignment_stack)
      : members_(members),
        member_offsets_(member_offsets),
        size_(size),
        alignment_field_(alignment_field),
        alignment_stack_(alignment_stack) {}

  const NativeTypes& members_;
  const ZoneGrowableArray<intptr_t>& member_offsets_;
  const intptr_t size_;
  const intptr_t alignment_field_;
  const intptr_t alignment_stack_;
};

class NativeFunctionType : public ZoneAllocated {
 public:
  NativeFunctionType(const NativeTypes& argument_types,
                     const NativeType& return_type)
      : argument_types_(argument_types), return_type_(return_type) {}

  const NativeTypes& argument_types() const { return argument_types_; }
  const NativeType& return_type() const { return return_type_; }

  void PrintTo(BaseTextBuffer* f) const;
  const char* ToCString(Zone* zone) const;
#if !defined(FFI_UNIT_TESTS)
  const char* ToCString() const;
#endif

 private:
  const NativeTypes& argument_types_;
  const NativeType& return_type_;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_NATIVE_TYPE_H_
