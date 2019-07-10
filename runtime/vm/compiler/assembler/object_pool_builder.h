// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_OBJECT_POOL_BUILDER_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_OBJECT_POOL_BUILDER_H_

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
    kPatchable,
    kNotPatchable,
  };

  enum EntryType {
    kTaggedObject,
    kImmediate,
    kNativeFunction,
    kNativeFunctionWrapper,
    kNativeEntryData,
  };

  using TypeBits = BitField<uint8_t, EntryType, 0, 7>;
  using PatchableBit = BitField<uint8_t, Patchability, TypeBits::kNextBit, 1>;

  static inline uint8_t EncodeTraits(EntryType type, Patchability patchable) {
    return TypeBits::encode(type) | PatchableBit::encode(patchable);
  }

  ObjectPoolBuilderEntry() : raw_value_(), entry_bits_(0), equivalence_() {}
  ObjectPoolBuilderEntry(const Object* obj, Patchability patchable)
      : ObjectPoolBuilderEntry(obj, obj, patchable) {}
  ObjectPoolBuilderEntry(const Object* obj,
                         const Object* eqv,
                         Patchability patchable)
      : obj_(obj),
        entry_bits_(EncodeTraits(kTaggedObject, patchable)),
        equivalence_(eqv) {}
  ObjectPoolBuilderEntry(uword value, EntryType info, Patchability patchable)
      : raw_value_(value),
        entry_bits_(EncodeTraits(info, patchable)),
        equivalence_() {}

  EntryType type() const { return TypeBits::decode(entry_bits_); }

  Patchability patchable() const { return PatchableBit::decode(entry_bits_); }

  union {
    const Object* obj_;
    uword raw_value_;
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

  static const intptr_t kNoIndex = -1;

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
    } else {
      key_.raw_value_ = key.raw_value_;
    }
  }

  static Key KeyOf(Pair kv) { return kv.key_; }

  static Value ValueOf(Pair kv) { return kv.value_; }

  static intptr_t Hashcode(Key key);

  static inline bool IsKeyEqual(Pair kv, Key key) {
    if (kv.key_.entry_bits_ != key.entry_bits_) return false;
    if (kv.key_.type() == ObjectPoolBuilderEntry::kTaggedObject) {
      return IsSameObject(*kv.key_.obj_, *key.obj_) &&
             IsSameObject(*kv.key_.equivalence_, *key.equivalence_);
    }
    return kv.key_.raw_value_ == key.raw_value_;
  }

 private:
  Key key_;
  Value value_;
};

class ObjectPoolBuilder : public ValueObject {
 public:
  ObjectPoolBuilder() : zone_(nullptr) {}
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

  intptr_t AddObject(const Object& obj,
                     ObjectPoolBuilderEntry::Patchability patchable =
                         ObjectPoolBuilderEntry::kNotPatchable);
  intptr_t AddImmediate(uword imm);

  intptr_t FindObject(const Object& obj,
                      ObjectPoolBuilderEntry::Patchability patchable =
                          ObjectPoolBuilderEntry::kNotPatchable);
  intptr_t FindObject(const Object& obj, const Object& equivalence);
  intptr_t FindImmediate(uword imm);
  intptr_t FindNativeFunction(const ExternalLabel* label,
                              ObjectPoolBuilderEntry::Patchability patchable);
  intptr_t FindNativeFunctionWrapper(
      const ExternalLabel* label,
      ObjectPoolBuilderEntry::Patchability patchable);

  intptr_t CurrentLength() const { return object_pool_.length(); }
  ObjectPoolBuilderEntry& EntryAt(intptr_t i) { return object_pool_[i]; }
  const ObjectPoolBuilderEntry& EntryAt(intptr_t i) const {
    return object_pool_[i];
  }

  intptr_t AddObject(ObjectPoolBuilderEntry entry);

 private:
  intptr_t FindObject(ObjectPoolBuilderEntry entry);

  // Objects and jump targets.
  GrowableArray<ObjectPoolBuilderEntry> object_pool_;

  // Hashmap for fast lookup in object pool.
  DirectChainedHashMap<ObjIndexPair> object_pool_index_table_;

  // The zone used for allocating the handles we keep in the map and array (or
  // NULL, in which case allocations happen using the zone active at the point
  // of insertion).
  Zone* zone_;
};

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_OBJECT_POOL_BUILDER_H_
