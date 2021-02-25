// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_PRIORITY_QUEUE_H_
#define RUNTIME_PLATFORM_PRIORITY_QUEUE_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/hashmap.h"
#include "platform/utils.h"

namespace dart {

// A min-priority queue with deletion support.
//
// The [PriorityQueue] allows insertion of entries with a priority [P] and a
// value [V]. The minimum element can be queried in O(1) time.
// Insertion/Deletion operations have O(N) time.
//
// In addition to the normal insert/minimum/remove-minimum operations this
// priority queue allows deletion-by-value. We have therefore an invariant
// is that the value must be unique amongst all entries.
template <typename P, typename V>
class PriorityQueue {
 public:
  static const intptr_t kMinimumSize = 16;

  struct Entry {
    P priority;
    V value;
  };

  PriorityQueue() : hashmap_(&MatchFun, kMinimumSize) {
    min_heap_size_ = kMinimumSize;
    min_heap_ =
        reinterpret_cast<Entry*>(malloc(sizeof(Entry) * min_heap_size_));
    if (min_heap_ == nullptr) FATAL("Cannot allocate memory.");
    size_ = 0;
  }

  ~PriorityQueue() { free(min_heap_); }

  // Whether the queue is empty.
  bool IsEmpty() const { return size_ == 0; }

  // Inserts a new entry with [priority] and [value], requires there to be no
  // existing entry with given [value].
  void Insert(const P& priority, const V& value) {
    ASSERT(!ContainsValue(value));

    if (size_ == min_heap_size_) {
      Resize(min_heap_size_ << 1);
    }

    Set(size_, {priority, value});
    BubbleUp(size_);

    size_++;
  }

  // Returns a reference to the minimum entry.
  //
  // The caller can access it's priority and value in read-only mode only.
  const Entry& Minimum() const {
    ASSERT(!IsEmpty());
    return min_heap_[0];
  }

  // Removes the minimum entry.
  void RemoveMinimum() {
    ASSERT(!IsEmpty());
    RemoveAt(0);
  }

  // Removes an existing entry with the given [value].
  //
  // Returns true if such an entry was removed.
  bool RemoveByValue(const V& value) {
    auto entry = FindMapEntry(value);
    if (entry != nullptr) {
      const intptr_t offset = ValueOfMapEntry(entry);
      RemoveAt(offset);

      ASSERT(hashmap_.size() == size_);
      return true;
    }
    return false;
  }

  // Whether the priority queue contains an entry with the given [value].
  bool ContainsValue(const V& value) { return FindMapEntry(value) != nullptr; }

  // Changes the priority of an existing entry with given [value] or adds a
  // new entry.
  bool InsertOrChangePriority(const P& priority, const V& value) {
    auto map_entry = FindMapEntry(value);
    if (map_entry == nullptr) {
      Insert(priority, value);
      return true;
    }

    const intptr_t offset = ValueOfMapEntry(map_entry);
    ASSERT(offset < size_);

    Entry& entry = min_heap_[offset];
    entry.priority = priority;
    if (offset == 0) {
      BubbleDown(offset);
    } else {
      intptr_t parent = (offset - 1) / 2;
      intptr_t diff = entry.priority - min_heap_[parent].priority;
      if (diff < 0) {
        BubbleUp(offset);
      } else if (diff > 0) {
        BubbleDown(offset);
      }
    }
    return false;
  }

#ifdef TESTING
  intptr_t min_heap_size() { return min_heap_size_; }
#endif  // TESTING

 private:
  // Utility functions dealing with the SimpleHashMap interface.
  static bool MatchFun(void* key1, void* key2) { return key1 == key2; }

  SimpleHashMap::Entry* FindMapEntry(const V& key, bool insert = false) {
    return hashmap_.Lookup(CastKey(key), HashKey(key), insert);
  }
  void RemoveMapEntry(const V& key) {
    ASSERT(FindMapEntry(key) != nullptr);
    hashmap_.Remove(CastKey(key), HashKey(key));
  }
  void SetMapEntry(const V& key, intptr_t value) {
    FindMapEntry(key, /*insert=*/true)->value = reinterpret_cast<void*>(value);
  }
  static uint32_t HashKey(const V& key) {
    return static_cast<uint32_t>(reinterpret_cast<intptr_t>(CastKey(key)));
  }
  static intptr_t ValueOfMapEntry(SimpleHashMap::Entry* entry) {
    return reinterpret_cast<intptr_t>(entry->value);
  }
  static void* CastKey(const V& key) {
    return reinterpret_cast<void*>((const_cast<V&>(key)));
  }

  void RemoveAt(intptr_t offset) {
    ASSERT(offset < size_);

    size_--;

    if (offset == size_) {
      RemoveMapEntry(min_heap_[offset].value);
    } else {
      Replace(offset, size_);
      BubbleDown(offset);
    }

    if (size_ <= (min_heap_size_ >> 2) &&
        kMinimumSize <= (min_heap_size_ >> 1)) {
      Resize(min_heap_size_ >> 1);
    }
  }

  void BubbleUp(intptr_t offset) {
    while (true) {
      if (offset == 0) return;

      intptr_t parent = (offset - 1) / 2;
      if (min_heap_[parent].priority > min_heap_[offset].priority) {
        Swap(parent, offset);
      }
      offset = parent;
    }
  }

  void BubbleDown(intptr_t offset) {
    while (true) {
      intptr_t left_child_index = 2 * offset + 1;
      bool has_left_child = left_child_index < size_;

      if (!has_left_child) return;

      intptr_t smallest_index = offset;

      if (min_heap_[left_child_index].priority < min_heap_[offset].priority) {
        smallest_index = left_child_index;
      }

      intptr_t right_child_index = left_child_index + 1;
      bool has_right_child = right_child_index < size_;
      if (has_right_child) {
        if (min_heap_[right_child_index].priority <
            min_heap_[smallest_index].priority) {
          smallest_index = right_child_index;
        }
      }

      if (offset == smallest_index) {
        return;
      }

      Swap(offset, smallest_index);
      offset = smallest_index;
    }
  }

  void Set(intptr_t offset1, const Entry& entry) {
    min_heap_[offset1] = entry;
    SetMapEntry(entry.value, offset1);
  }

  void Swap(intptr_t offset1, intptr_t offset2) {
    Entry temp = min_heap_[offset1];
    min_heap_[offset1] = min_heap_[offset2];
    min_heap_[offset2] = temp;

    SetMapEntry(min_heap_[offset1].value, offset1);
    SetMapEntry(min_heap_[offset2].value, offset2);
  }

  void Replace(intptr_t index, intptr_t with_other) {
    RemoveMapEntry(min_heap_[index].value);

    const Entry& entry = min_heap_[with_other];
    SetMapEntry(entry.value, index);
    min_heap_[index] = entry;
  }

  void Resize(intptr_t new_min_heap_size) {
    ASSERT(size_ < new_min_heap_size);
    ASSERT(new_min_heap_size != min_heap_size_);

    Entry* new_backing = reinterpret_cast<Entry*>(
        realloc(min_heap_, sizeof(Entry) * new_min_heap_size));

    if (new_backing == NULL) FATAL("Cannot allocate memory.");

    min_heap_ = new_backing;
    min_heap_size_ = new_min_heap_size;
  }

  // The array is representing a tree structure with guaranteed log(n) height.
  // It has the property that the value of node N is always equal or smaller
  // than the value of N's children. Furthermore it is a "dense" tree in the
  // sense that all rows/layers of the tree are fully occupied except the last
  // one. The way to represent such "dense" trees is via an array that allows
  // finding left/right children by <2*index+1><2*index+2> and the parent by
  // <(index-1)/2>.
  //
  // Insertion operations can be performed by adding one more entry at the end
  // (bottom right) and bubbling it up until the tree invariant is satisfied
  // again.
  //
  // Deletion operations can be performed by replacing the minimum element
  // (first entry) by the last entry (bottom right) and bubbling it down until
  // the tree invariant is satisified again.
  Entry* min_heap_;
  intptr_t min_heap_size_;
  intptr_t size_;
  SimpleHashMap hashmap_;
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_PRIORITY_QUEUE_H_
