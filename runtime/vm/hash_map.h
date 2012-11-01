// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HASH_MAP_H_
#define VM_HASH_MAP_H_

namespace dart {

template <typename KeyValueTrait>
class DirectChainedHashMap: public ValueObject {
 public:
  DirectChainedHashMap() : array_size_(0),
                           lists_size_(0),
                           count_(0),
                           array_(NULL),
                           lists_(NULL),
                           free_list_head_(kNil) {
    ResizeLists(kInitialSize);
    Resize(kInitialSize);
  }

  DirectChainedHashMap(const DirectChainedHashMap& other);

  void Insert(typename KeyValueTrait::Pair kv);

  typename KeyValueTrait::Value Lookup(typename KeyValueTrait::Key key) const;

  bool IsEmpty() const { return count_ == 0; }

 private:
  // A linked list of T values.  Stored in arrays.
  struct HashMapListElement {
    typename KeyValueTrait::Pair kv;
    intptr_t next;  // Index in the array of the next list element.
  };
  static const intptr_t kNil = -1;  // The end of a linked list

  // Must be a power of 2.
  static const intptr_t kInitialSize = 16;

  void Resize(intptr_t new_size);
  void ResizeLists(intptr_t new_size);
  uword Bound(uword value) const { return value & (array_size_ - 1); }

  intptr_t array_size_;
  intptr_t lists_size_;
  intptr_t count_;  // The number of values stored in the HashMap.
  HashMapListElement* array_;  // Primary store - contains the first value
  // with a given hash.  Colliding elements are stored in linked lists.
  HashMapListElement* lists_;  // The linked lists containing hash collisions.
  intptr_t free_list_head_;  // Unused elements in lists_ are on the free list.
};


template <typename KeyValueTrait>
typename KeyValueTrait::Value
    DirectChainedHashMap<KeyValueTrait>::
        Lookup(typename KeyValueTrait::Key key) const {
  uword hash = static_cast<uword>(KeyValueTrait::Hashcode(key));
  uword pos = Bound(hash);
  if (KeyValueTrait::ValueOf(array_[pos].kv) != NULL) {
    if (KeyValueTrait::IsKeyEqual(array_[pos].kv, key)) {
      return KeyValueTrait::ValueOf(array_[pos].kv);
    }

    intptr_t next = array_[pos].next;
    while (next != kNil) {
      if (KeyValueTrait::IsKeyEqual(lists_[next].kv, key)) {
        return KeyValueTrait::ValueOf(lists_[next].kv);
      }
      next = lists_[next].next;
    }
  }
  return NULL;
}


template <typename KeyValueTrait>
DirectChainedHashMap<KeyValueTrait>::
    DirectChainedHashMap(const DirectChainedHashMap& other)
  : ValueObject(),
    array_size_(other.array_size_),
    lists_size_(other.lists_size_),
    count_(other.count_),
    array_(Isolate::Current()->current_zone()->
           Alloc<HashMapListElement>(other.array_size_)),
    lists_(Isolate::Current()->current_zone()->
           Alloc<HashMapListElement>(other.lists_size_)),
    free_list_head_(other.free_list_head_) {
  memmove(array_, other.array_, array_size_ * sizeof(HashMapListElement));
  memmove(lists_, other.lists_, lists_size_ * sizeof(HashMapListElement));
}


template <typename KeyValueTrait>
void DirectChainedHashMap<KeyValueTrait>::Resize(intptr_t new_size) {
  ASSERT(new_size > count_);
  // Hashing the values into the new array has no more collisions than in the
  // old hash map, so we can use the existing lists_ array, if we are careful.

  // Make sure we have at least one free element.
  if (free_list_head_ == kNil) {
    ResizeLists(lists_size_ << 1);
  }

  HashMapListElement* new_array =
      Isolate::Current()->current_zone()->Alloc<HashMapListElement>(new_size);
  memset(new_array, 0, sizeof(HashMapListElement) * new_size);

  HashMapListElement* old_array = array_;
  intptr_t old_size = array_size_;

  intptr_t old_count = count_;
  count_ = 0;
  array_size_ = new_size;
  array_ = new_array;

  if (old_array != NULL) {
    // Iterate over all the elements in lists, rehashing them.
    for (intptr_t i = 0; i < old_size; ++i) {
      if (KeyValueTrait::ValueOf(old_array[i].kv) != NULL) {
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
}


template <typename T>
void DirectChainedHashMap<T>::ResizeLists(intptr_t new_size) {
  ASSERT(new_size > lists_size_);

  HashMapListElement* new_lists =
      Isolate::Current()->current_zone()->
      Alloc<HashMapListElement>(new_size);
  memset(new_lists, 0, sizeof(HashMapListElement) * new_size);

  HashMapListElement* old_lists = lists_;
  intptr_t old_size = lists_size_;

  lists_size_ = new_size;
  lists_ = new_lists;

  if (old_lists != NULL) {
    memmove(lists_, old_lists, old_size * sizeof(HashMapListElement));
  }
  for (intptr_t i = old_size; i < lists_size_; ++i) {
    lists_[i].next = free_list_head_;
    free_list_head_ = i;
  }
}


template <typename KeyValueTrait>
void DirectChainedHashMap<KeyValueTrait>::
    Insert(typename KeyValueTrait::Pair kv) {
  ASSERT(KeyValueTrait::ValueOf(kv) != NULL);
  // Resizing when half of the hashtable is filled up.
  if (count_ >= array_size_ >> 1) Resize(array_size_ << 1);
  ASSERT(count_ < array_size_);
  count_++;
  uword pos = Bound(
      static_cast<uword>(KeyValueTrait::Hashcode(KeyValueTrait::KeyOf(kv))));
  if (KeyValueTrait::ValueOf(array_[pos].kv) == NULL) {
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
           KeyValueTrait::ValueOf(lists_[array_[pos].next].kv) != NULL);
    array_[pos].next = new_element_pos;
  }
}


template<typename T>
class PointerKeyValueTrait {
 public:
  typedef T* Value;
  typedef T* Key;
  typedef T* Pair;

  static Key KeyOf(Pair kv) {
    return kv;
  }

  static Value ValueOf(Pair kv) {
    return kv;
  }

  static inline intptr_t Hashcode(Key key) {
    return key->Hashcode();
  }

  static inline bool IsKeyEqual(Pair kv, Key key) {
    return kv->Equals(key);
  }
};

}  // namespace dart

#endif  // VM_HASH_MAP_H_
