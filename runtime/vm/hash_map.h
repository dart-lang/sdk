// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HASH_MAP_H_
#define RUNTIME_VM_HASH_MAP_H_

#include "vm/growable_array.h"  // For Malloc, EmptyBase
#include "vm/hash.h"
#include "vm/zone.h"

namespace dart {

template <typename KeyValueTrait, typename B, typename Allocator = Zone>
class BaseDirectChainedHashMap : public B {
 public:
  explicit BaseDirectChainedHashMap(Allocator* allocator)
      : array_size_(0),
        lists_size_(0),
        count_(0),
        array_(NULL),
        lists_(NULL),
        free_list_head_(kNil),
        allocator_(allocator) {
    ResizeLists(kInitialSize);
    Resize(kInitialSize);
  }

  BaseDirectChainedHashMap(const BaseDirectChainedHashMap& other);

  intptr_t Length() const { return count_; }

  virtual ~BaseDirectChainedHashMap() {
    allocator_->template Free<HashMapListElement>(array_, array_size_);
    allocator_->template Free<HashMapListElement>(lists_, lists_size_);
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
    return Lookup(key) != NULL;
  }

  intptr_t Size() const { return count_; }
  bool IsEmpty() const { return count_ == 0; }

  virtual void Clear() {
    if (!IsEmpty()) {
      count_ = 0;
      InitArray(array_, array_size_);
      InitArray(lists_, lists_size_);
      lists_[0].next = kNil;
      for (intptr_t i = 1; i < lists_size_; ++i) {
        lists_[i].next = i - 1;
      }
      free_list_head_ = lists_size_ - 1;
    }
  }

  class Iterator {
   public:
    typename KeyValueTrait::Pair* Next();

    void Reset() {
      array_index_ = 0;
      list_index_ = kNil;
    }

   private:
    explicit Iterator(const BaseDirectChainedHashMap& map)
        : map_(map), array_index_(0), list_index_(kNil) {}

    const BaseDirectChainedHashMap& map_;
    intptr_t array_index_;
    intptr_t list_index_;

    template <typename T, typename Bs, typename A>
    friend class BaseDirectChainedHashMap;
  };

  Iterator GetIterator() const { return Iterator(*this); }

 protected:
  // A linked list of T values.  Stored in arrays.
  struct HashMapListElement {
    HashMapListElement() : kv(), next(kNil) {}
    typename KeyValueTrait::Pair kv;
    intptr_t next;  // Index in the array of the next list element.
  };
  static const intptr_t kNil = -1;  // The end of a linked list

  static void InitArray(HashMapListElement* array, intptr_t size) {
    for (intptr_t i = 0; i < size; ++i) {
      array[i] = HashMapListElement();
    }
  }

  // Must be a power of 2.
  static const intptr_t kInitialSize = 16;

  void Resize(intptr_t new_size);
  void ResizeLists(intptr_t new_size);
  uword Bound(uword value) const { return value & (array_size_ - 1); }

  intptr_t array_size_;
  intptr_t lists_size_;
  intptr_t count_;             // The number of values stored in the HashMap.
  HashMapListElement* array_;  // Primary store - contains the first value
  // with a given hash.  Colliding elements are stored in linked lists.
  HashMapListElement* lists_;  // The linked lists containing hash collisions.
  intptr_t free_list_head_;  // Unused elements in lists_ are on the free list.
  Allocator* allocator_;

 private:
  void operator=(const BaseDirectChainedHashMap& other) = delete;
};

template <typename KeyValueTrait, typename B, typename Allocator>
BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::BaseDirectChainedHashMap(
    const BaseDirectChainedHashMap& other)
    : B(),
      array_size_(other.array_size_),
      lists_size_(other.lists_size_),
      count_(other.count_),
      array_(other.allocator_->template Alloc<HashMapListElement>(
          other.array_size_)),
      lists_(other.allocator_->template Alloc<HashMapListElement>(
          other.lists_size_)),
      free_list_head_(other.free_list_head_),
      allocator_(other.allocator_) {
  memmove(array_, other.array_, array_size_ * sizeof(HashMapListElement));
  memmove(lists_, other.lists_, lists_size_ * sizeof(HashMapListElement));
}

template <typename KeyValueTrait, typename B, typename Allocator>
typename KeyValueTrait::Pair*
BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Lookup(
    typename KeyValueTrait::Key key) const {
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());

  uword hash = static_cast<uword>(KeyValueTrait::Hashcode(key));
  uword pos = Bound(hash);
  if (KeyValueTrait::ValueOf(array_[pos].kv) != kNoValue) {
    if (KeyValueTrait::IsKeyEqual(array_[pos].kv, key)) {
      return &array_[pos].kv;
    }

    intptr_t next = array_[pos].next;
    while (next != kNil) {
      if (KeyValueTrait::IsKeyEqual(lists_[next].kv, key)) {
        return &lists_[next].kv;
      }
      next = lists_[next].next;
    }
  }
  return NULL;
}

template <typename KeyValueTrait, typename B, typename Allocator>
typename KeyValueTrait::Value
BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::LookupValue(
    typename KeyValueTrait::Key key) const {
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());
  typename KeyValueTrait::Pair* pair = Lookup(key);
  return (pair == NULL) ? kNoValue : KeyValueTrait::ValueOf(*pair);
}

template <typename KeyValueTrait, typename B, typename Allocator>
typename KeyValueTrait::Pair*
BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Iterator::Next() {
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());

  // Return the current lists_ entry (if any), advancing list_index_.
  if (list_index_ != kNil) {
    intptr_t current = list_index_;
    list_index_ = map_.lists_[current].next;
    return &map_.lists_[current].kv;
  }

  // When we're done with the list, we'll continue with the next array
  // slot.
  while ((array_index_ < map_.array_size_) &&
         KeyValueTrait::ValueOf(map_.array_[array_index_].kv) == kNoValue) {
    ++array_index_;
  }
  if (array_index_ < map_.array_size_) {
    const intptr_t old_array_index = array_index_;
    ++array_index_;
    list_index_ = map_.array_[old_array_index].next;
    return &map_.array_[old_array_index].kv;
  }

  return nullptr;
}

template <typename KeyValueTrait, typename B, typename Allocator>
void BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Resize(
    intptr_t new_size) {
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());

  ASSERT(new_size > count_);
  // Hashing the values into the new array has no more collisions than in the
  // old hash map, so we can use the existing lists_ array, if we are careful.

  // Make sure we have at least one free element.
  if (free_list_head_ == kNil) {
    ResizeLists(lists_size_ << 1);
  }

  HashMapListElement* new_array =
      allocator_->template Alloc<HashMapListElement>(new_size);
  InitArray(new_array, new_size);

  HashMapListElement* old_array = array_;
  intptr_t old_size = array_size_;

  intptr_t old_count = count_;
  count_ = 0;
  array_size_ = new_size;
  array_ = new_array;

  if (old_array != NULL) {
    // Iterate over all the elements in lists, rehashing them.
    for (intptr_t i = 0; i < old_size; ++i) {
      if (KeyValueTrait::ValueOf(old_array[i].kv) != kNoValue) {
        intptr_t current = old_array[i].next;
        while (current != kNil) {
          Insert(lists_[current].kv);
          intptr_t next = lists_[current].next;
          lists_[current].next = free_list_head_;
          free_list_head_ = current;
          current = next;
        }
        // Rehash the directly stored value.
        Insert(old_array[i].kv);
      }
    }
  }
  USE(old_count);
  ASSERT(count_ == old_count);
  allocator_->template Free<HashMapListElement>(old_array, old_size);
}

template <typename KeyValueTrait, typename B, typename Allocator>
void BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::ResizeLists(
    intptr_t new_size) {
  ASSERT(new_size > lists_size_);

  HashMapListElement* new_lists =
      allocator_->template Alloc<HashMapListElement>(new_size);
  InitArray(new_lists, new_size);

  HashMapListElement* old_lists = lists_;
  intptr_t old_size = lists_size_;

  lists_size_ = new_size;
  lists_ = new_lists;

  if (old_lists != NULL) {
    for (intptr_t i = 0; i < old_size; i++) {
      lists_[i] = old_lists[i];
    }
  }
  for (intptr_t i = old_size; i < lists_size_; ++i) {
    lists_[i].next = free_list_head_;
    free_list_head_ = i;
  }
  allocator_->template Free<HashMapListElement>(old_lists, old_size);
}

template <typename KeyValueTrait, typename B, typename Allocator>
void BaseDirectChainedHashMap<KeyValueTrait, B, Allocator>::Insert(
    typename KeyValueTrait::Pair kv) {
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());

  ASSERT(KeyValueTrait::ValueOf(kv) != kNoValue);
  // TODO(dartbug.com/38018): Add assert that Lookup returns nullptr for key.

  // Resizing when half of the hashtable is filled up.
  if (count_ >= array_size_ >> 1) Resize(array_size_ << 1);
  ASSERT(count_ < array_size_);
  count_++;
  uword pos = Bound(
      static_cast<uword>(KeyValueTrait::Hashcode(KeyValueTrait::KeyOf(kv))));
  if (KeyValueTrait::ValueOf(array_[pos].kv) == kNoValue) {
    array_[pos].kv = kv;
    array_[pos].next = kNil;
  } else {
    if (free_list_head_ == kNil) {
      ResizeLists(lists_size_ << 1);
    }
    intptr_t new_element_pos = free_list_head_;
    ASSERT(new_element_pos != kNil);
    free_list_head_ = lists_[free_list_head_].next;
    lists_[new_element_pos].kv = kv;
    lists_[new_element_pos].next = array_[pos].next;
    ASSERT(array_[pos].next == kNil ||
           KeyValueTrait::ValueOf(lists_[array_[pos].next].kv) != kNoValue);
    array_[pos].next = new_element_pos;
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
  const typename KeyValueTrait::Value kNoValue =
      KeyValueTrait::ValueOf(typename KeyValueTrait::Pair());

  uword pos = Bound(static_cast<uword>(KeyValueTrait::Hashcode(key)));

  // Check to see if the first element in the bucket is the one we want to
  // remove.
  if (KeyValueTrait::ValueOf(array_[pos].kv) == kNoValue) return false;
  if (KeyValueTrait::IsKeyEqual(array_[pos].kv, key)) {
    if (array_[pos].next == kNil) {
      array_[pos] = HashMapListElement();
    } else {
      intptr_t next = array_[pos].next;
      array_[pos] = lists_[next];
      lists_[next] = HashMapListElement();
      lists_[next].next = free_list_head_;
      free_list_head_ = next;
    }
    count_--;
    return true;
  }

  intptr_t current = array_[pos].next;

  // If there's only the single element in the bucket and it does not match the
  // key to be removed, just return.
  if (current == kNil) {
    return false;
  }

  // Check the case where the second element in the bucket is the one to be
  // removed.
  if (KeyValueTrait::IsKeyEqual(lists_[current].kv, key)) {
    array_[pos].next = lists_[current].next;
    lists_[current] = HashMapListElement();
    lists_[current].next = free_list_head_;
    free_list_head_ = current;
    count_--;
    return true;
  }

  // Finally, iterate through the rest of the bucket to see if we can find the
  // entry that matches our key.
  intptr_t previous = -1;
  while (!KeyValueTrait::IsKeyEqual(lists_[current].kv, key)) {
    previous = current;
    current = lists_[current].next;

    if (current == kNil) {
      // Could not find entry with provided key to remove.
      return false;
    }
  }

  lists_[previous].next = lists_[current].next;
  lists_[current] = HashMapListElement();
  lists_[current].next = free_list_head_;
  free_list_head_ = current;
  count_--;
  return true;
}

template <typename KeyValueTrait>
class DirectChainedHashMap
    : public BaseDirectChainedHashMap<KeyValueTrait, ValueObject> {
 public:
  DirectChainedHashMap()
      : BaseDirectChainedHashMap<KeyValueTrait, ValueObject>(
            ASSERT_NOTNULL(ThreadState::Current()->zone())) {}

  explicit DirectChainedHashMap(Zone* zone)
      : BaseDirectChainedHashMap<KeyValueTrait, ValueObject>(
            ASSERT_NOTNULL(zone)) {}

  // There is a current use of the copy constructor in CSEInstructionMap
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
  MallocDirectChainedHashMap()
      : BaseDirectChainedHashMap<KeyValueTrait, MallocAllocated, Malloc>(NULL) {
  }

  // The only use of the copy constructor seems to be in hash_map_test.cc.
  // Not disallowing it for now just in case there are other users.
  MallocDirectChainedHashMap(const MallocDirectChainedHashMap& other)
      : BaseDirectChainedHashMap<KeyValueTrait, MallocAllocated, Malloc>(
            other) {}

 private:
  void operator=(const MallocDirectChainedHashMap& other) = delete;
};

template <typename T>
class PointerKeyValueTrait {
 public:
  typedef T* Value;
  typedef T* Key;
  typedef T* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Hashcode(); }

  static inline bool IsKeyEqual(Pair kv, Key key) { return kv->Equals(key); }
};

template <typename T>
class NumbersKeyValueTrait {
 public:
  typedef T Value;
  typedef intptr_t Key;
  typedef T Pair;

  static intptr_t KeyOf(Pair kv) { return kv.first(); }
  static T ValueOf(Pair kv) { return kv; }
  static inline intptr_t Hashcode(Key key) { return key; }
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
    Pair() : key(NULL), value() {}
    Pair(const Key key, const Value& value) : key(key), value(value) {}
    Pair(const Pair& other) : key(other.key), value(other.value) {}
    Pair& operator=(const Pair&) = default;
  };

  static Key KeyOf(Pair kv) { return kv.key; }
  static Value ValueOf(Pair kv) { return kv.value; }
  static intptr_t Hashcode(Key key) { return reinterpret_cast<intptr_t>(key); }
  static bool IsKeyEqual(Pair kv, Key key) { return kv.key == key; }
};

template <typename V>
class CStringKeyValueTrait : public RawPointerKeyValueTrait<const char, V> {
 public:
  typedef typename RawPointerKeyValueTrait<const char, V>::Key Key;
  typedef typename RawPointerKeyValueTrait<const char, V>::Value Value;
  typedef typename RawPointerKeyValueTrait<const char, V>::Pair Pair;

  static intptr_t Hashcode(Key key) {
    ASSERT(key != nullptr);
    intptr_t hash = 0;
    for (size_t i = 0; i < strlen(key); i++) {
      hash = CombineHashes(hash, key[i]);
    }
    return FinalizeHash(hash, kBitsPerWord - 1);
  }
  static bool IsKeyEqual(Pair kv, Key key) {
    ASSERT(kv.key != nullptr && key != nullptr);
    return kv.key == key || strcmp(kv.key, key) == 0;
  }
};

template <typename V>
class CStringMap : public DirectChainedHashMap<CStringKeyValueTrait<V>> {
 public:
  CStringMap() : DirectChainedHashMap<CStringKeyValueTrait<V>>() {}
  explicit CStringMap(Zone* zone)
      : DirectChainedHashMap<CStringKeyValueTrait<V>>(zone) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(CStringMap);
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
  static intptr_t Hashcode(Key key) { return key; }
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

  inline V Lookup(const Key& key) {
    Pair* pair =
        DirectChainedHashMap<IntKeyRawPointerValueTrait<V> >::Lookup(key);
    if (pair == NULL) {
      return V();
    } else {
      return pair->value;
    }
  }

  inline Pair* LookupPair(const Key& key) {
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

  static inline intptr_t Hashcode(Key key) {
    return reinterpret_cast<intptr_t>(key);
  }

  static inline bool IsKeyEqual(Pair pair, Key key) { return pair == key; }
};

}  // namespace dart

#endif  // RUNTIME_VM_HASH_MAP_H_
