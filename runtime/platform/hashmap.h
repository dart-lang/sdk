// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_HASHMAP_H_
#define RUNTIME_PLATFORM_HASHMAP_H_

#include "platform/globals.h"

namespace dart {

class SimpleHashMap {
 public:
  typedef bool (*MatchFun)(void* key1, void* key2);

  typedef void (*ClearFun)(void* value);

  // initial_capacity is the size of the initial hash map;
  // it must be a power of 2 (and thus must not be 0).
  SimpleHashMap(MatchFun match, uint32_t initial_capacity);

  ~SimpleHashMap();

  static bool SamePointerValue(void* key1, void* key2) { return key1 == key2; }

  static uint32_t StringHash(char* key) {
    uint32_t hash_ = 0;
    if (key == NULL) return hash_;
    int len = strlen(key);
    for (int i = 0; i < len; i++) {
      hash_ += key[i];
      hash_ += hash_ << 10;
      hash_ ^= hash_ >> 6;
    }
    hash_ += hash_ << 3;
    hash_ ^= hash_ >> 11;
    hash_ += hash_ << 15;
    return hash_ == 0 ? 1 : hash_;
  }

  static bool SameStringValue(void* key1, void* key2) {
    return strcmp(reinterpret_cast<char*>(key1),
                  reinterpret_cast<char*>(key2)) == 0;
  }

  // SimpleHashMap entries are (key, value, hash) triplets.
  // Some clients may not need to use the value slot
  // (e.g. implementers of sets, where the key is the value).
  struct Entry {
    Entry() : key(NULL), value(NULL), hash(0) {}
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
  //
  // WARNING: This method cannot be called while iterating a `SimpleHashMap`
  // otherwise the iteration might step over elements!
  void Remove(void* key, uint32_t hash);

  // Empties the hash map (occupancy() == 0), and calls the function 'clear' on
  // each of the values if given.
  void Clear(ClearFun clear = NULL);

  // The number of entries stored in the table.
  intptr_t size() const { return occupancy_; }

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
  DISALLOW_COPY_AND_ASSIGN(SimpleHashMap);
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_HASHMAP_H_
