// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_OBJECT_POOL_BUILDER_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_OBJECT_POOL_BUILDER_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/bitfield.h"
#include "vm/hash_map.h"

namespace dart {

class Object;

namespace compiler {

class ExternalLabel;

bool IsSameObject(const Object& a, const Object& b);

struct ObjectPoolBuilderEntry {
  enum Patchability {
    kPatchable = 0,
    kNotPatchable,
  };

  enum SnapshotBehavior {
    kSnapshotable,
    // This should never be snapshot. Typically an memory address in the current
    // process.
    kNotSnapshotable,
    // Set the value to StubCode::CallBootstrapNative() on snapshot reading.
    kResetToBootstrapNative,
  };

  enum EntryType {
    kImmediate = 0,
    kTaggedObject,
    kNativeFunction,

    // Used only during AOT snapshot serialization/deserialization.
    // Denotes kImmediate entry with
    //  - StubCode::SwitchableCallMiss().MonomorphicEntryPoint()
    //  - StubCode::MegamorphicCall().MonomorphicEntryPoint()
    // values which become known only at run time.
    kSwitchableCallMissEntryPoint,
    kMegamorphicCallEntryPoint,

  // Used only during object pool building to find duplicates. Become multiple
  // kImmediate in the final pool.
#if defined(TARGET_ARCH_IS_32_BIT)
    kImmediate64,
#endif
    kImmediate128,
  };

  using TypeBits = BitField<uint8_t, EntryType, 0, 5>;
  using PatchableBit = BitField<uint8_t, Patchability, TypeBits::kNextBit, 1>;
  using SnapshotBehaviorBit =
      BitField<uint8_t, SnapshotBehavior, PatchableBit::kNextBit, 2>;

  static inline uint8_t EncodeTraits(
      EntryType type,
      Patchability patchable,
      SnapshotBehavior snapshot_behavior = SnapshotBehavior::kSnapshotable) {
    return TypeBits::encode(type) | PatchableBit::encode(patchable) |
           PatchableBit::encode(patchable) |
           SnapshotBehaviorBit::encode(snapshot_behavior);
  }

  ObjectPoolBuilderEntry() : imm128_(), entry_bits_(0), equivalence_() {}
  ObjectPoolBuilderEntry(const Object* obj,
                         Patchability patchable,
                         SnapshotBehavior snapshot_behavior = kSnapshotable)
      : ObjectPoolBuilderEntry(obj, obj, patchable, snapshot_behavior) {}
  ObjectPoolBuilderEntry(const Object* obj,
                         const Object* eqv,
                         Patchability patchable,
                         SnapshotBehavior snapshot_behavior = kSnapshotable)
      : obj_(obj),
        entry_bits_(EncodeTraits(kTaggedObject, patchable, snapshot_behavior)),
        equivalence_(eqv) {}
  ObjectPoolBuilderEntry(
      uword value,
      EntryType info,
      Patchability patchable,
      SnapshotBehavior snapshot_behavior = SnapshotBehavior::kSnapshotable)
      : imm_(value),
        entry_bits_(EncodeTraits(info, patchable, snapshot_behavior)),
        equivalence_() {}
#if defined(ARCH_IS_32_BIT)
  ObjectPoolBuilderEntry(uint64_t value, EntryType info, Patchability patchable)
      : imm64_(value),
        entry_bits_(EncodeTraits(info, patchable)),
        equivalence_() {}
#endif
  ObjectPoolBuilderEntry(simd128_value_t value,
                         EntryType info,
                         Patchability patchable)
      : imm128_(value),
        entry_bits_(EncodeTraits(info, patchable)),
        equivalence_() {}

  EntryType type() const { return TypeBits::decode(entry_bits_); }

  Patchability patchable() const { return PatchableBit::decode(entry_bits_); }

  SnapshotBehavior snapshot_behavior() const {
    return SnapshotBehaviorBit::decode(entry_bits_);
  }

  union {
    const Object* obj_;
    uword imm_;
    uint64_t imm64_;
    simd128_value_t imm128_;
  };
  uint8_t entry_bits_;
  const Object* equivalence_;
};

// Pair type parameter for DirectChainedHashMap used for the constant pool.
class ObjIndexPair {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef ObjectPoolBuilderEntry Key;
  typedef intptr_t Value;
  typedef ObjIndexPair Pair;

  static constexpr intptr_t kNoIndex = -1;

  ObjIndexPair()
      : key_(reinterpret_cast<uword>(nullptr),
             ObjectPoolBuilderEntry::kTaggedObject,
             ObjectPoolBuilderEntry::kPatchable),
        value_(kNoIndex) {}

  ObjIndexPair(Key key, Value value) : value_(value) {
    key_.entry_bits_ = key.entry_bits_;
    if (key.type() == ObjectPoolBuilderEntry::kTaggedObject) {
      key_.obj_ = key.obj_;
      key_.equivalence_ = key.equivalence_;
    } else if (key.type() == ObjectPoolBuilderEntry::kImmediate128) {
      key_.imm128_ = key.imm128_;
#if defined(TARGET_ARCH_IS_32_BIT)
    } else if (key.type() == ObjectPoolBuilderEntry::kImmediate64) {
      key_.imm64_ = key.imm64_;
#endif
    } else {
      key_.imm_ = key.imm_;
    }
  }

  static Key KeyOf(Pair kv) { return kv.key_; }

  static Value ValueOf(Pair kv) { return kv.value_; }

  static uword Hash(Key key);

  static inline bool IsKeyEqual(Pair kv, Key key) {
    if (kv.key_.entry_bits_ != key.entry_bits_) return false;
    if (kv.key_.type() == ObjectPoolBuilderEntry::kTaggedObject) {
      return IsSameObject(*kv.key_.obj_, *key.obj_) &&
             IsSameObject(*kv.key_.equivalence_, *key.equivalence_);
    }
    if (kv.key_.type() == ObjectPoolBuilderEntry::kImmediate128) {
      return (kv.key_.imm128_.int_storage[0] == key.imm128_.int_storage[0]) &&
             (kv.key_.imm128_.int_storage[1] == key.imm128_.int_storage[1]) &&
             (kv.key_.imm128_.int_storage[2] == key.imm128_.int_storage[2]) &&
             (kv.key_.imm128_.int_storage[3] == key.imm128_.int_storage[3]);
    }
#if defined(TARGET_ARCH_IS_32_BIT)
    if (kv.key_.type() == ObjectPoolBuilderEntry::kImmediate64) {
      return kv.key_.imm64_ == key.imm64_;
    }
#endif
    return kv.key_.imm_ == key.imm_;
  }

 private:
  Key key_;
  Value value_;
};

class ObjectPoolBuilder : public ValueObject {
 public:
  // When generating AOT code in the bare instructions mode we might use a two
  // stage process of forming the pool - first accumulate objects in the
  // intermediary pool and then commit them into the global pool at the
  // end of a successful compilation. Here [parent] is the pool into which
  // we are going to commit objects.
  // See PrecompileParsedFunctionHelper::Compile for more information.
  explicit ObjectPoolBuilder(ObjectPoolBuilder* parent = nullptr)
      : parent_(parent),
        base_index_(parent != nullptr ? parent->CurrentLength() : 0),
        zone_(nullptr) {}

  ~ObjectPoolBuilder() {
    if (zone_ != nullptr) {
      Reset();
      zone_ = nullptr;
    }
  }

  // Clears all existing entries in this object pool builder.
  //
  // Note: Any code which has been compiled via this builder might use offsets
  // into the pool which are not correct anymore.
  void Reset();

  // Initialize this object pool builder with a [zone].
  //
  // Any objects added later on will be referenced using handles from [zone].
  void InitializeWithZone(Zone* zone) {
    ASSERT(object_pool_.length() == 0);
    ASSERT(zone_ == nullptr && zone != nullptr);
    zone_ = zone;
  }

  intptr_t AddObject(
      const Object& obj,
      ObjectPoolBuilderEntry::Patchability patchable =
          ObjectPoolBuilderEntry::kNotPatchable,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable);
  intptr_t AddImmediate(uword imm);
  intptr_t AddImmediate64(uint64_t imm);
  intptr_t AddImmediate128(simd128_value_t imm);

  intptr_t FindObject(
      const Object& obj,
      ObjectPoolBuilderEntry::Patchability patchable =
          ObjectPoolBuilderEntry::kNotPatchable,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable);
  intptr_t FindObject(const Object& obj, const Object& equivalence);
  intptr_t FindImmediate(uword imm);
  intptr_t FindImmediate64(uint64_t imm);
  intptr_t FindImmediate128(simd128_value_t imm);
  intptr_t FindNativeFunction(const ExternalLabel* label,
                              ObjectPoolBuilderEntry::Patchability patchable);

  intptr_t CurrentLength() const {
    return object_pool_.length() + used_from_parent_.length();
  }
  ObjectPoolBuilderEntry& EntryAt(intptr_t i) {
    if (i < used_from_parent_.length()) {
      return parent_->EntryAt(used_from_parent_[i]);
    }
    return object_pool_[i - used_from_parent_.length()];
  }
  const ObjectPoolBuilderEntry& EntryAt(intptr_t i) const {
    if (i < used_from_parent_.length()) {
      return parent_->EntryAt(used_from_parent_[i]);
    }
    return object_pool_[i - used_from_parent_.length()];
  }

  intptr_t AddObject(ObjectPoolBuilderEntry entry);

  // Try appending all entries from this pool into the parent pool.
  // This might fail if parent pool was modified invalidating indices which
  // we produced. In this case this function will return false.
  bool TryCommitToParent();

  bool HasParent() const { return parent_ != nullptr; }

 private:
  intptr_t FindObject(ObjectPoolBuilderEntry entry);

  // Parent pool into which all entries from this pool will be added at
  // the end of the successful compilation.
  ObjectPoolBuilder* const parent_;

  // Base index at which entries will be inserted into the parent pool.
  // Should be equal to parent_->CurrentLength() - but is cached here
  // to detect cases when parent pool grows due to nested code generations.
  const intptr_t base_index_;

  GrowableArray<intptr_t> used_from_parent_;

  // Objects and jump targets.
  GrowableArray<ObjectPoolBuilderEntry> object_pool_;

  // Hashmap for fast lookup in object pool.
  DirectChainedHashMap<ObjIndexPair> object_pool_index_table_;

  // The zone used for allocating the handles we keep in the map and array (or
  // nullptr, in which case allocations happen using the zone active at the
  // point of insertion).
  Zone* zone_;
};

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_OBJECT_POOL_BUILDER_H_
