// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_COMPILE_TYPE_H_
#define RUNTIME_VM_COMPILER_BACKEND_COMPILE_TYPE_H_

#include "vm/object.h"
#include "vm/thread.h"

namespace dart {

class BufferFormatter;

// CompileType describes type of a value produced by a definition.
//
// It captures the following properties:
//    - whether the value can potentially be null or if it is definitely not
//      null;
//    - concrete class id of the value or kDynamicCid if unknown statically;
//    - abstract super type of the value, concrete type of the value in runtime
//      is guaranteed to be sub type of this type.
//
// Values of CompileType form a lattice with a None type as a bottom and a
// nullable Dynamic type as a top element. Method Union provides a join
// operation for the lattice.
class CompileType : public ZoneAllocated {
 public:
  static const bool kNullable = true;
  static const bool kNonNullable = false;

  CompileType(bool is_nullable, intptr_t cid, const AbstractType* type)
      : is_nullable_(is_nullable), cid_(cid), type_(type) {}

  CompileType(const CompileType& other)
      : ZoneAllocated(),
        is_nullable_(other.is_nullable_),
        cid_(other.cid_),
        type_(other.type_) {}

  CompileType& operator=(const CompileType& other) {
    is_nullable_ = other.is_nullable_;
    cid_ = other.cid_;
    type_ = other.type_;
    return *this;
  }

  bool is_nullable() const { return is_nullable_; }

  // Return type such that concrete value's type in runtime is guaranteed to
  // be subtype of it.
  const AbstractType* ToAbstractType();

  // Return class id such that it is either kDynamicCid or in runtime
  // value is guaranteed to have an equal class id.
  intptr_t ToCid();

  // Return class id such that it is either kDynamicCid or in runtime
  // value is guaranteed to be either null or have an equal class id.
  intptr_t ToNullableCid();

  // Return true if the value is guaranteed to be not-null or is known to be
  // always null.
  bool HasDecidableNullability();

  // Return true if the value is known to be always null.
  bool IsNull();

  // Return true if this type is a subtype of the given type.
  bool IsSubtypeOf(const AbstractType& other);

  // Return true if value of this type is assignable to a location of the
  // given type.
  bool IsAssignableTo(const AbstractType& type) {
    bool is_instance;
    return CanComputeIsInstanceOf(type, kNullable, &is_instance) && is_instance;
  }

  // Create a new CompileType representing given combination of class id and
  // abstract type. The pair is assumed to be coherent.
  static CompileType Create(intptr_t cid, const AbstractType& type);

  CompileType CopyNonNullable() const {
    return CompileType(kNonNullable, kIllegalCid, type_);
  }

  static CompileType CreateNullable(bool is_nullable, intptr_t cid) {
    return CompileType(is_nullable, cid, NULL);
  }

  // Create a new CompileType representing given abstract type. By default
  // values as assumed to be nullable.
  static CompileType FromAbstractType(const AbstractType& type,
                                      bool is_nullable = kNullable);

  // Create a new CompileType representing a value with the given class id.
  // Resulting CompileType is nullable only if cid is kDynamicCid or kNullCid.
  static CompileType FromCid(intptr_t cid);

  // Create None CompileType. It is the bottom of the lattice and is used to
  // represent type of the phi that was not yet inferred.
  static CompileType None() {
    return CompileType(kNullable, kIllegalCid, NULL);
  }

  // Create Dynamic CompileType. It is the top of the lattice and is used to
  // represent unknown type.
  static CompileType Dynamic();

  static CompileType Null();

  // Create non-nullable Bool type.
  static CompileType Bool();

  // Create non-nullable Int type.
  static CompileType Int();

  // Create nullable Int type.
  static CompileType NullableInt();

  // Create non-nullable Smi type.
  static CompileType Smi();

  // Create nullable Smi type.
  static CompileType NullableSmi() {
    return CreateNullable(kNullable, kSmiCid);
  }

  // Create nullable Mint type.
  static CompileType NullableMint() {
    return CreateNullable(kNullable, kMintCid);
  }

  // Create non-nullable Double type.
  static CompileType Double();

  // Create nullable Double type.
  static CompileType NullableDouble();

  // Create non-nullable String type.
  static CompileType String();

  // Perform a join operation over the type lattice.
  void Union(CompileType* other);

  // Refine old type with newly inferred type (it could be more or less
  // specific, or even unrelated to an old type in case of unreachable code).
  // May return 'old_type', 'new_type' or create a new CompileType instance.
  static CompileType* ComputeRefinedType(CompileType* old_type,
                                         CompileType* new_type);

  // Return true if this and other types are the same.
  bool IsEqualTo(CompileType* other) {
    return (is_nullable_ == other->is_nullable_) &&
           (ToNullableCid() == other->ToNullableCid()) &&
           (ToAbstractType()->Equals(*other->ToAbstractType()));
  }

  bool IsNone() const { return (cid_ == kIllegalCid) && (type_ == NULL); }

  // Return true if value of this type is a non-nullable int.
  bool IsInt() { return !is_nullable() && IsNullableInt(); }

  // Return true if value of this type is a non-nullable double.
  bool IsDouble() { return !is_nullable() && IsNullableDouble(); }

  // Return true if value of this type is either int or null.
  bool IsNullableInt() {
    if ((cid_ == kSmiCid) || (cid_ == kMintCid)) {
      return true;
    }
    if ((cid_ == kIllegalCid) || (cid_ == kDynamicCid)) {
      return (type_ != NULL) && ((type_->IsIntType() || type_->IsSmiType()));
    }
    return false;
  }

  // Returns true if value of this type is either Smi or null.
  bool IsNullableSmi() {
    if (cid_ == kSmiCid) {
      return true;
    }
    if ((cid_ == kIllegalCid) || (cid_ == kDynamicCid)) {
      return type_ != nullptr && type_->IsSmiType();
    }
    return false;
  }

  // Return true if value of this type is either double or null.
  bool IsNullableDouble() {
    if (cid_ == kDoubleCid) {
      return true;
    }
    if ((cid_ == kIllegalCid) || (cid_ == kDynamicCid)) {
      return (type_ != NULL) && type_->IsDoubleType();
    }
    return false;
  }

  void PrintTo(BufferFormatter* f) const;
  const char* ToCString() const;

 private:
  bool CanComputeIsInstanceOf(const AbstractType& type,
                              bool is_nullable,
                              bool* is_instance);

  bool is_nullable_;
  intptr_t cid_;
  const AbstractType* type_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_COMPILE_TYPE_H_
