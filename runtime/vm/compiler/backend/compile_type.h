// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_COMPILE_TYPE_H_
#define RUNTIME_VM_COMPILER_BACKEND_COMPILE_TYPE_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"
#include "vm/class_id.h"
#include "vm/compiler/runtime_api.h"

namespace dart {

class AbstractType;
class BaseTextBuffer;
class Definition;
class FlowGraphSerializer;
class SExpression;
class SExpList;

template <typename T>
class GrowableArray;

// CompileType describes type of a value produced by a definition.
//
// It captures the following properties:
//    - whether the value can potentially be null or if it is definitely not
//      null;
//    - concrete class id of the value or kDynamicCid if unknown statically;
//    - abstract super type of the value, where the concrete type of the value
//      in runtime is guaranteed to be sub type of this type.
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
    // This intentionally does not change the owner of this type.
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
  bool IsAssignableTo(const AbstractType& other);

  // Return true if value of this type always passes 'is' test
  // against given type.
  bool IsInstanceOf(const AbstractType& other);

  // Create a new CompileType representing given combination of class id and
  // abstract type. The pair is assumed to be coherent.
  static CompileType Create(intptr_t cid, const AbstractType& type);

  // Return the non-nullable version of this type.
  CompileType CopyNonNullable() {
    if (IsNull()) {
      // Represent a non-nullable null type (typically arising for
      // unreachable values) as None.
      return None();
    }

    return CompileType(kNonNullable, cid_, type_);
  }

  static CompileType CreateNullable(bool is_nullable, intptr_t cid) {
    return CompileType(is_nullable, cid, nullptr);
  }

  // Create a new CompileType representing given abstract type.
  // By default nullability of values is determined by type.
  // CompileType can be further constrained to non-nullable values by
  // passing kNonNullable as an optional parameter.
  static CompileType FromAbstractType(const AbstractType& type,
                                      bool is_nullable = kNullable);

  // Create a new CompileType representing a value with the given class id.
  // Resulting CompileType is nullable only if cid is kDynamicCid or kNullCid.
  static CompileType FromCid(intptr_t cid);

  // Create None CompileType. It is the bottom of the lattice and is used to
  // represent type of the phi that was not yet inferred.
  static CompileType None() {
    return CompileType(kNullable, kIllegalCid, nullptr);
  }

  // Create Dynamic CompileType. It is the top of the lattice and is used to
  // represent unknown type.
  static CompileType Dynamic();

  static CompileType Null();

  // Create non-nullable Bool type.
  static CompileType Bool();

  // Create non-nullable Int type.
  static CompileType Int();

  // Create non-nullable 32-bit Int type (arch dependent).
  static CompileType Int32();

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
           (compiler::IsEqualType(*ToAbstractType(), *other->ToAbstractType()));
  }

  bool IsNone() const { return (cid_ == kIllegalCid) && (type_ == nullptr); }

  // Return true if value of this type is a non-nullable int.
  bool IsInt() { return !is_nullable() && IsNullableInt(); }

  // Return true if value of this type is a non-nullable double.
  bool IsDouble() { return !is_nullable() && IsNullableDouble(); }

  // Return true if value of this type is a non-nullable double.
  bool IsBool() { return !is_nullable() && IsNullableBool(); }

  // Return true if value of this type is either int or null.
  bool IsNullableInt() {
    if (cid_ == kSmiCid || cid_ == kMintCid) {
      return true;
    }
    if (cid_ == kIllegalCid || cid_ == kDynamicCid) {
      return type_ != nullptr &&
             (compiler::IsIntType(*type_) || compiler::IsSmiType(*type_));
    }
    return false;
  }

  // Returns true if value of this type is either Smi or null.
  bool IsNullableSmi() {
    if (cid_ == kSmiCid) {
      return true;
    }
    if (cid_ == kIllegalCid || cid_ == kDynamicCid) {
      return type_ != nullptr && compiler::IsSmiType(*type_);
    }
    return false;
  }

  // Return true if value of this type is either double or null.
  bool IsNullableDouble() {
    if (cid_ == kDoubleCid) {
      return true;
    }
    if ((cid_ == kIllegalCid) || (cid_ == kDynamicCid)) {
      return type_ != nullptr && compiler::IsDoubleType(*type_);
    }
    return false;
  }

  // Return true if value of this type is either double or null.
  bool IsNullableBool() {
    if (cid_ == kBoolCid) {
      return true;
    }
    if ((cid_ == kIllegalCid) || (cid_ == kDynamicCid)) {
      return type_ != nullptr && compiler::IsBoolType(*type_);
    }
    return false;
  }

  // Returns true if a value of this CompileType can contain a Smi.
  // Note that this is not the same as calling
  // CompileType::Smi().IsAssignableTo(this) - because this compile type
  // can be uninstantiated.
  bool CanBeSmi();

  bool Specialize(GrowableArray<intptr_t>* class_ids);

  void PrintTo(BaseTextBuffer* f) const;
  SExpression* ToSExpression(FlowGraphSerializer* s) const;
  void AddExtraInfoToSExpression(SExpList* sexp, FlowGraphSerializer* s) const;

  const char* ToCString() const;

  // CompileType object might be unowned or owned by a definition.
  // Owned CompileType objects can change during type propagation when
  // [RecomputeType] is called on the owner. We keep track of which
  // definition owns [CompileType] to prevent situations where
  // owned [CompileType] is cached as a reaching type in a [Value] which
  // is no longer connected to the original owning definition.
  // See [Value::SetReachingType].
  void set_owner(Definition* owner) { owner_ = owner; }
  Definition* owner() const { return owner_; }

 private:
  bool is_nullable_;
  classid_t cid_;
  const AbstractType* type_;
  Definition* owner_ = nullptr;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_COMPILE_TYPE_H_
