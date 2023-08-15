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
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/runtime_api.h"

namespace dart {

class AbstractType;
class BaseTextBuffer;
class Definition;
class FlowGraphDeserializer;
class FlowGraphSerializer;

template <typename T>
class GrowableArray;

// CompileType describes type of a value produced by a definition.
//
// It captures the following properties:
//    - whether the value can potentially be null or if it is definitely not
//      null;
//    - whether the value can potentially be sentinel or if it is definitely
//      not sentinel;
//    - concrete class id of the value or kDynamicCid if unknown statically;
//    - abstract super type of the value, where the concrete type of the value
//      in runtime is guaranteed to be sub type of this type.
//
// Values of CompileType form a lattice with a None type as a bottom and a
// nullable Dynamic type as a top element. Method Union provides a join
// operation for the lattice.
class CompileType : public ZoneAllocated {
 public:
  static constexpr bool kCanBeNull = true;
  static constexpr bool kCannotBeNull = false;

  static constexpr bool kCanBeSentinel = true;
  static constexpr bool kCannotBeSentinel = false;

  CompileType(bool can_be_null,
              bool can_be_sentinel,
              intptr_t cid,
              const AbstractType* type)
      : can_be_null_(can_be_null),
        can_be_sentinel_(can_be_sentinel),
        cid_(cid),
        type_(type) {}

  CompileType(const CompileType& other)
      : ZoneAllocated(),
        can_be_null_(other.can_be_null_),
        can_be_sentinel_(other.can_be_sentinel_),
        cid_(other.cid_),
        type_(other.type_) {}

  CompileType& operator=(const CompileType& other) {
    // This intentionally does not change the owner of this type.
    can_be_null_ = other.can_be_null_;
    can_be_sentinel_ = other.can_be_sentinel_;
    cid_ = other.cid_;
    type_ = other.type_;
    return *this;
  }

  bool is_nullable() const { return can_be_null_; }

  // Return true if value of this type can be Object::sentinel().
  // Such values cannot be unboxed.
  bool can_be_sentinel() const { return can_be_sentinel_; }

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

  // Return the non-nullable version of this type.
  CompileType CopyNonNullable() {
    if (IsNull()) {
      // Represent a non-nullable null type (typically arising for
      // unreachable values) as None.
      return None();
    }

    return CompileType(kCannotBeNull, can_be_sentinel_, cid_, type_);
  }

  // Return the non-sentinel version of this type.
  CompileType CopyNonSentinel() {
    return CompileType(can_be_null_, kCannotBeSentinel, cid_, type_);
  }

  // Create a new CompileType representing given abstract type.
  // By default nullability of values is determined by type.
  // CompileType can be further constrained to non-nullable values by
  // passing kCannotBeNull as |can_be_null| parameter.
  static CompileType FromAbstractType(const AbstractType& type,
                                      bool can_be_null,
                                      bool can_be_sentinel);

  // Create a new CompileType representing a value with the given class id.
  // Resulting CompileType can be null only if cid is kDynamicCid or kNullCid.
  // Resulting CompileType can be sentinel only if cid is kDynamicCid or
  // kSentinelCid.
  static CompileType FromCid(intptr_t cid);

  // Create a new CompileType representing an unboxed value
  // with given unboxed representation.
  // Resulting CompileType cannot be null and cannot be sentinel.
  static CompileType FromUnboxedRepresentation(Representation rep);

  // Create None CompileType. It is the bottom of the lattice and is used to
  // represent type of the phi that was not yet inferred.
  static CompileType None() {
    return CompileType(kCanBeNull, kCanBeSentinel, kIllegalCid, nullptr);
  }

  // Create Dynamic CompileType. It is the top of the lattice and is used to
  // represent unknown type.
  static CompileType Dynamic();

  static CompileType DynamicOrSentinel();

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
    return CompileType(kCanBeNull, kCannotBeSentinel, kSmiCid, nullptr);
  }

  // Create nullable Mint type.
  static CompileType NullableMint() {
    return CompileType(kCanBeNull, kCannotBeSentinel, kMintCid, nullptr);
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
    return (can_be_null_ == other->can_be_null_) &&
           (can_be_sentinel_ == other->can_be_sentinel_) &&
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
      return type_ != nullptr && compiler::IsSubtypeOfInt(*type_);
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

  // Returns true if a value of this CompileType can contain a Future
  // instance.
  bool CanBeFuture();

  bool Specialize(GrowableArray<intptr_t>* class_ids);

  void PrintTo(BaseTextBuffer* f) const;

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

  void Write(FlowGraphSerializer* s) const;
  explicit CompileType(FlowGraphDeserializer* d);

 private:
  bool can_be_null_;
  bool can_be_sentinel_;
  classid_t cid_;
  const AbstractType* type_;
  Definition* owner_ = nullptr;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_COMPILE_TYPE_H_
