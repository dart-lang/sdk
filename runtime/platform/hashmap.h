// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_HASHMAP_H_
#define PLATFORM_HASHMAP_H_

#include "platform/globals.h"

class HashMap {
 public:
  typedef bool (*MatchFun) (void* key1, void* key2);

  static bool SamePointerValue(void* key1, void* key2) {
    return key1 == key2;
  }

  // initial_capacity is the size of the initial hash map;
  // it must be a power of 2 (and thus must not be 0).
  HashMap(MatchFun match, uint32_t initial_capacity);

  ~HashMap();

  // HashMap entries are (key, value, hash) triplets.
  // Some clients may not need to use the value slot
  // (e.g. implementers of sets, where the key is the value).
  struct Entry {
    void* key;
    void* value;
    uint32_t hash;  // The full hash value for key.
  };

  // If an entry with matching key is found, Lookup()
  // returns that entry. If no matching entry is found,
  // but insert is set, a new entry is inserted with
  // corresponding key, key hash, and NULL value.
  // Otherwise, NULL is returned.
  Entry* Lookup(void* key, uint32_t hash, bool insert);

  // Removes the entry with matching key.
  void Remove(void* key, uint32_t hash);

  // Empties the hash map (occupancy() == 0).
  void Clear();

  // The capacity of the table. The implementation
  // makes sure that occupancy is at most 80% of
  // the table capacity.
  intptr_t capacity() const { return capacity_; }

  // Iteration
  //
  // for (Entry* p = map.Start(); p != NULL; p = map.Next(p)) {
  //   ...
  // }
  //
  // If entries are inserted during iteration, the effect of
  // calling Next() is undefined.
  Entry* Start() const;
  Entry* Next(Entry* p) const;

 private:
  MatchFun match_;
  Entry* map_;
  uint32_t capacity_;
  uint32_t occupancy_;

  Entry* map_end() const { return map_ + capacity_; }
  Entry* Probe(void* key, uint32_t hash);
  void Initialize(uint32_t capacity);
  void Resize();

  friend class IntSet;  // From hashmap_test.cc
};

#endif  // PLATFORM_HASHMAP_H_
