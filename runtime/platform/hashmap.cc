// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/hashmap.h"

#include "platform/utils.h"

namespace dart {

HashMap::HashMap(MatchFun match, uint32_t initial_capacity) {
  match_ = match;
  Initialize(initial_capacity);
}

HashMap::~HashMap() {
  delete[] map_;
}

HashMap::Entry* HashMap::Lookup(void* key, uint32_t hash, bool insert) {
  // Find a matching entry.
  Entry* p = Probe(key, hash);
  if (p->key != NULL) {
    return p;
  }

  // No entry found; insert one if necessary.
  if (insert) {
    p->key = key;
    p->value = NULL;
    p->hash = hash;
    occupancy_++;

    // Grow the map if we reached >= 80% occupancy.
    if ((occupancy_ + (occupancy_ / 4)) >= capacity_) {
      Resize();
      p = Probe(key, hash);
    }

    return p;
  }

  // No entry found and none inserted.
  return NULL;
}

void HashMap::Remove(void* key, uint32_t hash) {
  // Lookup the entry for the key to remove.
  Entry* candidate = Probe(key, hash);
  if (candidate->key == NULL) {
    // Key not found nothing to remove.
    return;
  }

  // To remove an entry we need to ensure that it does not create an empty
  // entry that will cause the search for another entry to stop too soon. If all
  // the entries between the entry to remove and the next empty slot have their
  // initial position inside this interval, clearing the entry to remove will
  // not break the search. If, while searching for the next empty entry, an
  // entry is encountered which does not have its initial position between the
  // entry to remove and the position looked at, then this entry can be moved to
  // the place of the entry to remove without breaking the search for it. The
  // entry made vacant by this move is now the entry to remove and the process
  // starts over.
  // Algorithm from http://en.wikipedia.org/wiki/Open_addressing.

  // This guarantees loop termination as there is at least one empty entry so
  // eventually the removed entry will have an empty entry after it.
  ASSERT(occupancy_ < capacity_);

  // "candidate" is the candidate entry to clear. "next" is used to scan
  // forwards.
  Entry* next = candidate;  // Start at the entry to remove.
  while (true) {
    // Move "next" to the next entry. Wrap when at the end of the array.
    next = next + 1;
    if (next == map_end()) {
      next = map_;
    }

    // All entries between "candidate" and "next" have their initial position
    // between candidate and entry and the entry candidate can be cleared
    // without breaking the search for these entries.
    if (next->key == NULL) {
      break;
    }

    // Find the initial position for the entry at position "next". That is
    // the entry where searching for the entry at position "next" will
    // actually start.
    Entry* start = map_ + (next->hash & (capacity_ - 1));

    // If the entry at position "next" has its initial position outside the
    // range between "candidate" and "next" it can be moved forward to
    // position "candidate" and will still be found. There is now the new
    // candidate entry for clearing.
    if ((next > candidate && (start <= candidate || start > next)) ||
        (next < candidate && (start <= candidate && start > next))) {
      *candidate = *next;
      candidate = next;
    }
  }

  // Clear the candidate which will not break searching the hash table.
  candidate->key = NULL;
  occupancy_--;
}

void HashMap::Clear(ClearFun clear) {
  // Mark all entries as empty.
  const Entry* end = map_end();
  for (Entry* p = map_; p < end; p++) {
    if ((clear != NULL) && (p->key != NULL)) {
      clear(p->value);
    }
    p->key = NULL;
  }
  occupancy_ = 0;
}

HashMap::Entry* HashMap::Start() const {
  return Next(map_ - 1);
}

HashMap::Entry* HashMap::Next(Entry* p) const {
  const Entry* end = map_end();
  ASSERT(map_ - 1 <= p && p < end);
  for (p++; p < end; p++) {
    if (p->key != NULL) {
      return p;
    }
  }
  return NULL;
}

HashMap::Entry* HashMap::Probe(void* key, uint32_t hash) {
  ASSERT(key != NULL);

  ASSERT(dart::Utils::IsPowerOfTwo(capacity_));
  Entry* p = map_ + (hash & (capacity_ - 1));
  const Entry* end = map_end();
  ASSERT(map_ <= p && p < end);

  ASSERT(occupancy_ < capacity_);  // Guarantees loop termination.
  while (p->key != NULL && (hash != p->hash || !match_(key, p->key))) {
    p++;
    if (p >= end) {
      p = map_;
    }
  }

  return p;
}

void HashMap::Initialize(uint32_t capacity) {
  ASSERT(dart::Utils::IsPowerOfTwo(capacity));
  map_ = new Entry[capacity];
  if (map_ == NULL) {
    OUT_OF_MEMORY();
  }
  capacity_ = capacity;
  occupancy_ = 0;
}

void HashMap::Resize() {
  Entry* map = map_;
  uint32_t n = occupancy_;

  // Allocate larger map.
  Initialize(capacity_ * 2);

  // Rehash all current entries.
  for (Entry* p = map; n > 0; p++) {
    if (p->key != NULL) {
      Lookup(p->key, p->hash, true)->value = p->value;
      n--;
    }
  }

  // Delete old map.
  delete[] map;
}

}  // namespace dart
