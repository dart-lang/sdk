// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HASH_MAP_H_
#define VM_HASH_MAP_H_

namespace dart {

template <typename T>
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

  void Insert(T value);

  T Lookup(T value) const;

  bool IsEmpty() const { return count_ == 0; }

 private:
  // A linked list of T values.  Stored in arrays.
  struct HashMapListElement {
    T value;
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

  DISALLOW_COPY_AND_ASSIGN(DirectChainedHashMap);
};


template <typename T>
T DirectChainedHashMap<T>::Lookup(T value) const {
  uword hash = static_cast<uword>(value->Hashcode());
  uword pos = Bound(hash);
  if (array_[pos].value != NULL) {
    if (array_[pos].value->Equals(value)) return array_[pos].value;
    intptr_t next = array_[pos].next;
    while (next != kNil) {
      if (lists_[next].value->Equals(value)) return lists_[next].value;
      next = lists_[next].next;
    }
  }
  return NULL;
}


template <typename T>
void DirectChainedHashMap<T>::Resize(intptr_t new_size) {
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
      if (old_array[i].value != NULL) {
        intptr_t current = old_array[i].next;
        while (current != kNil) {
          Insert(lists_[current].value);
          intptr_t next = lists_[current].next;
          lists_[current].next = free_list_head_;
          free_list_head_ = current;
          current = next;
        }
        // Rehash the directly stored value.
        Insert(old_array[i].value);
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


template <typename T>
void DirectChainedHashMap<T>::Insert(T value) {
  ASSERT(value != NULL);
  // Resizing when half of the hashtable is filled up.
  if (count_ >= array_size_ >> 1) Resize(array_size_ << 1);
  ASSERT(count_ < array_size_);
  count_++;
  uword pos = Bound(static_cast<uword>(value->Hashcode()));
  if (array_[pos].value == NULL) {
    array_[pos].value = value;
    array_[pos].next = kNil;
  } else {
    if (free_list_head_ == kNil) {
      ResizeLists(lists_size_ << 1);
    }
    intptr_t new_element_pos = free_list_head_;
    ASSERT(new_element_pos != kNil);
    free_list_head_ = lists_[free_list_head_].next;
    lists_[new_element_pos].value = value;
    lists_[new_element_pos].next = array_[pos].next;
    ASSERT(array_[pos].next == kNil || lists_[array_[pos].next].value != NULL);
    array_[pos].next = new_element_pos;
  }
}

}  // namespace dart

#endif  // VM_HASH_MAP_H_
