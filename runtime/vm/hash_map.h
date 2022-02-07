// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HASH_MAP_H_
#define RUNTIME_VM_HASH_MAP_H_

#include "platform/utils.h"
#include "vm/flags.h"
#include "vm/growable_array.h"  // For Malloc, EmptyBase
#include "vm/hash.h"
#include "vm/zone.h"

namespace dart {

template <typename KeyValueTrait, typename B, typename Allocator = Zone>
class BaseDirectChainedHashMap : public B {
 public:
  explicit BaseDirectChainedHashMap(Allocator* allocator,
                                    intptr_t initial_size = kInitialSize)
      : allocator_(allocator) {
    Resize(initial_size);
  }

  BaseDirectChainedHashMap(const BaseDirectChainedHashMap& other);

  intptr_t Length() const { return next_pair_index_ - deleted_count_; }

  ~BaseDirectChainedHashMap() {
    allocator_->template Free<uint32_t>(hash_table_, hash_table_size_);
    allocator_->template Free<typename KeyValueTrait::Pair>(pairs_,
                                                            pairs_size_);
  }

  // Assumes that no existing pair in the map has a key equal to [kv.key].
  void Insert(typename KeyValueTrait::Pair kv);
  bool Remove(typename KeyValueTrait::Key key);

  // If a pair already exists in the map with an equal key, replace that pair
  // with this one. Otherwise, insert the pair as a new entry.
  //
  // Note: Insert operates in constant time, while Update must walk the chained
  // entries for a given hash value, checking keys for equality. However, if
  // multiple value updates are needed for the same key, only using Update
  // guarantees constant space usage whereas Insert does not.
  void Update(typename KeyValueTrait::Pair kv);

  typename KeyValueTrait::Value LookupValue(
      typename KeyValueTrait::Key key) const;

  typename KeyValueTrait::Pair* Lookup(typename KeyValueTrait::Key key) const;
  bool HasKey(typename KeyValueTrait::Key key) const {
    return Lookup(key) != nullptr;
  }

  intptr_t Size() const { return next_pair_index_ - deleted_count_; }
  bool IsEmpty() const { return Size() == 0; }

  void Clear() {
    for (uint32_t i = 0; i < hash_table_size_; i++) {
      hash_table_[i] = kEmpty;
    }
    for (uint32_t i = 0; i < next_pair_index_; i++) {
      pairs_[i] = typename KeyValueTrait::Pair();
    }
    next_pair_index_ = 0;
    deleted_count_ = 0;
  }

  class Iterator {
   public:
    typename KeyValueTrait::Pair* Next();

    void Reset() { pair_index_ = 0; }

   private:
    explicit Iterator(const BaseDirectChainedHashMap& map)
        : map_(map), pair_index_(0) {}

    const BaseDirectChainedHashMap& map_;
    uint32_t pair_index_;

    template <typename T, typename Bs, typename A>
    friend class BaseDirectChainedHashMap;
  };

  Iterator GetIterator() const { return Iterator(*this); }

 protected:
  static constexpr intptr_t kInitialSize = 16;

  void Resize(intptr_t new_size);

  Allocator* const allocator_;
  uint32_t* hash_table_ = nullptr;
  typename KeyValueTrait::Pair* pairs_ = nullptr;
  uint32_t hash_table_size_ = 0;
  uint32_t pairs_size_ = 0;
  uint32_t next_pair_index_ = 0;
  uint32_t deleted_count_ = 0;

  static constexpr uint32_t kEmpty = kMaxUint32;
  static constexpr uint32_t kDeleted = kMaxUint32 - 1;
  static constexpr uint32_t kMaxPairs = kMaxUint32 - 2;

 private:
  void operator=(const BaseDirectChainedHashMap& other) = delete;
};

template <typename KeyValueTrait, typename B, typename Allocator>
BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::BaseDirectChainedHashMap(
    const BaseDirectChainedHashMap& other)
    : B(),
      allocator_(other.allocator_),
      hash_table_(
          other.allocator_->template Alloc<uint32_t>(other.hash_table_size_)),
      pairs_(other.allocator_->template Alloc<typename KeyValueTrait::Pair>(
          other.pairs_size_)),
      hash_table_size_(other.hash_table_size_),
      pairs_size_(other.pairs_size_),
      next_pair_index_(other.next_pair_index_),
      deleted_count_(other.deleted_count_) {
  memmove(hash_table_, other.hash_table_, hash_table_size_ * sizeof(uint32_t));
  memmove(pairs_, other.pairs_,
          pairs_size_ * sizeof(typename KeyValueTrait::Pair));
}

template <typename KeyValueTrait, typename B, typename Allocator>
typename KeyValueTrait::Pair*
BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Lookup(
    typename KeyValueTrait::Key key) const {
  uword hash = KeyValueTrait::Hash(key);
  uint32_t mask = hash_table_size_ - 1;
  uint32_t hash_index = hash & mask;
  uint32_t start = hash_index;
  intptr_t probes = 0;
  for (;;) {
    uint32_t pair_index = hash_table_[hash_index];
    if (pair_index == kEmpty) {
      return nullptr;
    }
    if (pair_index != kDeleted) {
      ASSERT(pair_index < pairs_size_);
      RELEASE_ASSERT(++probes < FLAG_hash_map_probes_limit);
      if (KeyValueTrait::IsKeyEqual(pairs_[pair_index], key)) {
        return &pairs_[pair_index];
      }
    }
    hash_index = (hash_index + 1) & mask;
    // Hashtable must contain at least one empty marker.
    ASSERT(hash_index != start);
  }
  UNREACHABLE();
  return nullptr;
}

template <typename KeyValueTrait, typename B, typename Allocator>
typename KeyValueTrait::Value
BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::LookupValue(
    typename KeyValueTrait::Key key) const {
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());
  typename KeyValueTrait::Pair* pair = Lookup(key);
  return (pair == nullptr) ? kNoValue : KeyValueTrait::ValueOf(*pair);
}

template <typename KeyValueTrait, typename B, typename Allocator>
typename KeyValueTrait::Pair*
BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Iterator::Next() {
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());
  while (pair_index_ < map_.next_pair_index_) {
    if (KeyValueTrait::ValueOf(map_.pairs_[pair_index_]) != kNoValue) {
      intptr_t old_index = pair_index_;
      pair_index_++;
      return &map_.pairs_[old_index];
    }
    pair_index_++;
  }
  return nullptr;
}

template <typename KeyValueTrait, typename B, typename Allocator>
void BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Resize(
    intptr_t new_size) {
  ASSERT(new_size >= Size());

  uint32_t old_hash_table_size = hash_table_size_;
  // 75% load factor + at least one kEmpty slot
  hash_table_size_ = Utils::RoundUpToPowerOfTwo(new_size * 4 / 3 + 1);
  hash_table_ = allocator_->template Realloc<uint32_t>(
      hash_table_, old_hash_table_size, hash_table_size_);
  for (uint32_t i = 0; i < hash_table_size_; i++) {
    hash_table_[i] = kEmpty;
  }

  typename KeyValueTrait::Pair* old_pairs = pairs_;
  uint32_t old_pairs_size = pairs_size_;
  uint32_t old_next_pair_index = next_pair_index_;
  uint32_t old_deleted_count = deleted_count_;
  next_pair_index_ = 0;
  deleted_count_ = 0;
  pairs_size_ = new_size;
  pairs_ =
      allocator_->template Alloc<typename KeyValueTrait::Pair>(pairs_size_);
  for (uint32_t i = 0; i < pairs_size_; i++) {
    pairs_[i] = typename KeyValueTrait::Pair();
  }

  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());
  uint32_t used = 0;
  uint32_t deleted = 0;
  for (uint32_t i = 0; i < old_next_pair_index; i++) {
    if (KeyValueTrait::ValueOf(old_pairs[i]) == kNoValue) {
      deleted++;
    } else {
      Insert(old_pairs[i]);
      used++;
    }
  }
  ASSERT_EQUAL(deleted, old_deleted_count);
  ASSERT_EQUAL(used, old_next_pair_index - old_deleted_count);
  ASSERT_EQUAL(used, next_pair_index_);
  allocator_->template Free<typename KeyValueTrait::Pair>(old_pairs,
                                                          old_pairs_size);
}

template <typename KeyValueTrait, typename B, typename Allocator>
void BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Insert(
    typename KeyValueTrait::Pair kv) {
  // TODO(dartbug.com/38018):
  // ASSERT(Lookup(KeyValueTrait::KeyOf(kv)) == nullptr);
  ASSERT(next_pair_index_ < pairs_size_);
  uword hash = KeyValueTrait::Hash(KeyValueTrait::KeyOf(kv));
  uint32_t mask = hash_table_size_ - 1;
  uint32_t hash_index = hash & mask;
  uint32_t start = hash_index;
  intptr_t probes = 0;
  for (;;) {
    uint32_t pair_index = hash_table_[hash_index];
    if ((pair_index == kEmpty) || (pair_index == kDeleted)) {
      hash_table_[hash_index] = next_pair_index_;
      pairs_[next_pair_index_] = kv;
      next_pair_index_++;
      break;
    }
    RELEASE_ASSERT(++probes < FLAG_hash_map_probes_limit);
    ASSERT(pair_index < pairs_size_);
    hash_index = (hash_index + 1) & mask;
    // Hashtable must contain at least one empty marker.
    ASSERT(hash_index != start);
  }

  if (next_pair_index_ == pairs_size_) {
    Resize(Size() << 1);
  }
}

template <typename KeyValueTrait, typename B, typename Allocator>
void BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Update(
    typename KeyValueTrait::Pair kv) {
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());

  ASSERT(KeyValueTrait::ValueOf(kv) != kNoValue);
  if (auto const old_kv = Lookup(KeyValueTrait::KeyOf(kv))) {
    *old_kv = kv;
  } else {
    Insert(kv);
  }
}

template <typename KeyValueTrait, typename B, typename Allocator>
bool BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Remove(
    typename KeyValueTrait::Key key) {
  uword hash = KeyValueTrait::Hash(key);
  uint32_t mask = hash_table_size_ - 1;
  uint32_t hash_index = hash & mask;
  uint32_t start = hash_index;
  intptr_t probes = 0;
  for (;;) {
    uint32_t pair_index = hash_table_[hash_index];
    if (pair_index == kEmpty) {
      return false;
    }
    if (pair_index != kDeleted) {
      ASSERT(pair_index < pairs_size_);
      RELEASE_ASSERT(++probes < FLAG_hash_map_probes_limit);
      if (KeyValueTrait::IsKeyEqual(pairs_[pair_index], key)) {
        hash_table_[hash_index] = kDeleted;
        pairs_[pair_index] = typename KeyValueTrait::Pair();
        deleted_count_++;
        return true;
      }
    }
    hash_index = (hash_index + 1) & mask;
    // Hashtable must contain at least one empty marker.
    ASSERT(hash_index != start);
  }
  UNREACHABLE();
  return false;
}

template <typename KeyValueTrait>
class DirectChainedHashMap
    : public BaseDirectChainedHashMap<KeyValueTrait, ValueObject> {
 public:
  DirectChainedHashMap()
      : BaseDirectChainedHashMap<KeyValueTrait, ValueObject>(
            ASSERT_NOTNULL(ThreadState::Current()->zone())) {}

  explicit DirectChainedHashMap(
      Zone* zone,
      intptr_t initial_size = DirectChainedHashMap::kInitialSize)
      : BaseDirectChainedHashMap<KeyValueTrait, ValueObject>(
            ASSERT_NOTNULL(zone),
            initial_size) {}

  // There is a current use of the copy constructor in CSEInstructionSet
  // (compiler/backend/redundancy_elimination.cc), so work is needed if we
  // want to disallow it.
  DirectChainedHashMap(const DirectChainedHashMap& other)
      : BaseDirectChainedHashMap<KeyValueTrait, ValueObject>(other) {}

 private:
  void operator=(const DirectChainedHashMap& other) = delete;
};

template <typename KeyValueTrait>
class MallocDirectChainedHashMap
    : public BaseDirectChainedHashMap<KeyValueTrait, MallocAllocated, Malloc> {
 public:
  MallocDirectChainedHashMap(
      intptr_t initial_size = MallocDirectChainedHashMap::kInitialSize)
      : BaseDirectChainedHashMap<KeyValueTrait, MallocAllocated, Malloc>(
            nullptr,
            initial_size) {}

  // The only use of the copy constructor seems to be in hash_map_test.cc.
  // Not disallowing it for now just in case there are other users.
  MallocDirectChainedHashMap(const MallocDirectChainedHashMap& other)
      : BaseDirectChainedHashMap<KeyValueTrait, MallocAllocated, Malloc>(
            other) {}

 private:
  void operator=(const MallocDirectChainedHashMap& other) = delete;
};

template <typename KeyValueTrait>
class ZoneDirectChainedHashMap
    : public BaseDirectChainedHashMap<KeyValueTrait, ZoneAllocated, Zone> {
 public:
  ZoneDirectChainedHashMap()
      : BaseDirectChainedHashMap<KeyValueTrait, ZoneAllocated, Zone>(
            ThreadState::Current()->zone()) {}
  explicit ZoneDirectChainedHashMap(
      Zone* zone,
      intptr_t initial_size = ZoneDirectChainedHashMap::kInitialSize)
      : BaseDirectChainedHashMap<KeyValueTrait, ZoneAllocated, Zone>(
            zone,
            initial_size) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(ZoneDirectChainedHashMap);
};

template <typename T>
class PointerSetKeyValueTrait {
 public:
  typedef T* Value;
  typedef T* Key;
  typedef T* Pair;

  static Key KeyOf(Pair kv) { return kv; }
  static Value ValueOf(Pair kv) { return kv; }
  static inline uword Hash(Key key) { return key->Hash(); }
  static inline bool IsKeyEqual(Pair kv, Key key) { return kv->Equals(*key); }
};

template <typename T>
using PointerSet = DirectChainedHashMap<PointerSetKeyValueTrait<T>>;

template <typename T>
class NumbersKeyValueTrait {
 public:
  typedef T Value;
  typedef intptr_t Key;
  typedef T Pair;

  static intptr_t KeyOf(Pair kv) { return kv.first(); }
  static T ValueOf(Pair kv) { return kv; }
  static inline uword Hash(Key key) { return key; }
  static inline bool IsKeyEqual(Pair kv, Key key) { return kv.first() == key; }
};

template <typename K, typename V>
class RawPointerKeyValueTrait {
 public:
  typedef K* Key;
  typedef V Value;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(nullptr), value() {}
    Pair(const Key key, const Value& value) : key(key), value(value) {}
    Pair(const Pair& other) : key(other.key), value(other.value) {}
    Pair& operator=(const Pair&) = default;
  };

  static Key KeyOf(Pair kv) { return kv.key; }
  static Value ValueOf(Pair kv) { return kv.value; }
  static uword Hash(Key key) { return reinterpret_cast<intptr_t>(key); }
  static bool IsKeyEqual(Pair kv, Key key) { return kv.key == key; }
};

class CStringSetKeyValueTrait {
 public:
  using Key = const char*;
  using Value = const char*;
  using Pair = const char*;

  static Key KeyOf(Pair kv) { return kv; }
  static Value ValueOf(Pair kv) { return kv; }
  static uword Hash(Key key) {
    ASSERT(key != nullptr);
    return Utils::StringHash(key, strlen(key));
  }
  static bool IsKeyEqual(Pair kv, Key key) {
    ASSERT(kv != nullptr && key != nullptr);
    return kv == key || strcmp(kv, key) == 0;
  }
};

template <typename B, typename Allocator>
class BaseCStringSet
    : public BaseDirectChainedHashMap<CStringSetKeyValueTrait, B, Allocator> {
 public:
  explicit BaseCStringSet(Allocator* allocator)
      : BaseDirectChainedHashMap<CStringSetKeyValueTrait, B, Allocator>(
            allocator) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(BaseCStringSet);
};

class ZoneCStringSet : public BaseCStringSet<ZoneAllocated, Zone> {
 public:
  ZoneCStringSet()
      : BaseCStringSet<ZoneAllocated, Zone>(ThreadState::Current()->zone()) {}
  explicit ZoneCStringSet(Zone* zone)
      : BaseCStringSet<ZoneAllocated, Zone>(zone) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(ZoneCStringSet);
};

struct CStringIntMapKeyValueTrait {
  using Key = const char*;
  using Value = intptr_t;

  static constexpr Value kNoValue = kIntptrMin;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(nullptr), value(kNoValue) {}
    Pair(const Key key, const Value& value) : key(key), value(value) {}
    Pair(const Pair& other) : key(other.key), value(other.value) {}
    Pair& operator=(const Pair&) = default;
  };

  static Key KeyOf(const Pair& pair) { return pair.key; }
  static Value ValueOf(const Pair& pair) { return pair.value; }
  static uword Hash(const Key& key) {
    ASSERT(key != nullptr);
    return Utils::StringHash(key, strlen(key));
  }
  static bool IsKeyEqual(const Pair& kv, const Key& key) {
    ASSERT(kv.key != nullptr && key != nullptr);
    return kv.key == key || strcmp(kv.key, key) == 0;
  }
};

template <typename B, typename Allocator>
class BaseCStringIntMap
    : public BaseDirectChainedHashMap<CStringIntMapKeyValueTrait,
                                      B,
                                      Allocator> {
 public:
  explicit BaseCStringIntMap(Allocator* allocator)
      : BaseDirectChainedHashMap<CStringIntMapKeyValueTrait, B, Allocator>(
            allocator) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(BaseCStringIntMap);
};

class CStringIntMap : public BaseCStringIntMap<ValueObject, Zone> {
 public:
  CStringIntMap()
      : BaseCStringIntMap<ValueObject, Zone>(ThreadState::Current()->zone()) {}
  explicit CStringIntMap(Zone* zone)
      : BaseCStringIntMap<ValueObject, Zone>(zone) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(CStringIntMap);
};

template <typename V>
class IntKeyRawPointerValueTrait {
 public:
  typedef intptr_t Key;
  typedef V Value;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(0), value() {}
    Pair(const Key key, const Value& value) : key(key), value(value) {}
    Pair(const Pair& other) : key(other.key), value(other.value) {}
    Pair& operator=(const Pair&) = default;
  };

  static Key KeyOf(Pair kv) { return kv.key; }
  static Value ValueOf(Pair kv) { return kv.value; }
  static uword Hash(Key key) { return key; }
  static bool IsKeyEqual(Pair kv, Key key) { return kv.key == key; }
};

template <typename V>
class IntMap : public DirectChainedHashMap<IntKeyRawPointerValueTrait<V> > {
 public:
  IntMap() : DirectChainedHashMap<IntKeyRawPointerValueTrait<V>>() {}
  explicit IntMap(Zone* zone)
      : DirectChainedHashMap<IntKeyRawPointerValueTrait<V>>(zone) {}

  typedef typename IntKeyRawPointerValueTrait<V>::Key Key;
  typedef typename IntKeyRawPointerValueTrait<V>::Value Value;
  typedef typename IntKeyRawPointerValueTrait<V>::Pair Pair;

  inline void Insert(const Key& key, const Value& value) {
    Pair pair(key, value);
    DirectChainedHashMap<IntKeyRawPointerValueTrait<V> >::Insert(pair);
  }

  inline V Lookup(const Key& key) const {
    Pair* pair =
        DirectChainedHashMap<IntKeyRawPointerValueTrait<V> >::Lookup(key);
    if (pair == nullptr) {
      return V();
    } else {
      return pair->value;
    }
  }

  inline Pair* LookupPair(const Key& key) const {
    return DirectChainedHashMap<IntKeyRawPointerValueTrait<V> >::Lookup(key);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(IntMap);
};

template <typename V>
class IdentitySetKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef V Key;
  typedef V Value;
  typedef V Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline uword Hash(Key key) {
    return Utils::StringHash(reinterpret_cast<const char*>(&key), sizeof(key));
  }

  static inline bool IsKeyEqual(Pair pair, Key key) { return pair == key; }
};

}  // namespace dart

#endif  // RUNTIME_VM_HASH_MAP_H_
