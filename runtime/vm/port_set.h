// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PORT_SET_H_
#define RUNTIME_VM_PORT_SET_H_

#include "include/dart_api.h"

#include "platform/allocation.h"
#include "platform/globals.h"
#include "platform/utils.h"

namespace dart {

template <typename T /* :public PortSet<T>::Entry */>
class PortSet {
 public:
  static constexpr Dart_Port kFreePort = static_cast<Dart_Port>(0);
  static constexpr Dart_Port kDeletedPort = static_cast<Dart_Port>(3);

  struct Entry : public MallocAllocated {
    Entry() : port(kFreePort) {}

    // Free entries have set this to 0.
    Dart_Port port;
  };

  class Iterator {
   public:
    Iterator(PortSet<T>* ports, intptr_t index) : ports_(ports), index_(index) {
#if defined(DEBUG)
      dirty_counter_ = ports_->dirty_counter_;
#endif
    }

    DART_FORCE_INLINE T& operator->() const {
      ASSERT(index_ >= 0 && index_ < ports_->capacity_);
      DEBUG_ASSERT(!WasModified());
      return ports_->map_[index_];
    }
    DART_FORCE_INLINE T& operator*() const {
      ASSERT(index_ >= 0 && index_ < ports_->capacity_);
      DEBUG_ASSERT(!WasModified());
      return ports_->map_[index_];
    }

    DART_FORCE_INLINE bool operator==(const Iterator& other) const {
      DEBUG_ASSERT(!WasModified());
      return ports_ == other.ports_ && index_ == other.index_;
    }

    DART_FORCE_INLINE bool operator!=(const Iterator& other) const {
      DEBUG_ASSERT(!WasModified());
      return !(*this == other);
    }

    DART_FORCE_INLINE Iterator& operator++() {
      DEBUG_ASSERT(!WasModified());
      index_++;
      while (index_ < ports_->capacity_) {
        const Dart_Port port = ports_->map_[index_].port;
        if (port == kFreePort || port == kDeletedPort) {
          index_++;
          continue;
        } else {
          break;
        }
      }
      return *this;
    }

    // The caller must ensure to call [PortSet::Rebalance] once the iterator is
    // not used anymore.
    DART_FORCE_INLINE void Delete() {
      DEBUG_ASSERT(!WasModified());
      ports_->map_[index_] = T();
      ports_->map_[index_].port = kDeletedPort;
      ports_->used_--;
      ports_->deleted_++;
    }

   private:
    friend class PortSet;

#if defined(DEBUG)
    // Whether the underlying [PortSet] was modified in a way that would render
    // the iterator unusable.
    bool WasModified() const {
      return dirty_counter_ != ports_->dirty_counter_;
    }
#endif

    PortSet<T>* ports_;
    intptr_t index_ = 0;
#if defined(DEBUG)
    intptr_t dirty_counter_ = 0;
#endif
  };

  PortSet() {
    static const intptr_t kInitialCapacity = 8;
    ASSERT(Utils::IsPowerOfTwo(kInitialCapacity));
    map_ = new T[kInitialCapacity];
    capacity_ = kInitialCapacity;
  }
  ~PortSet() {
    delete[] map_;
    map_ = nullptr;
  }

  bool IsEmpty() const { return used_ == 0; }

  DART_FORCE_INLINE Iterator begin() {
    for (intptr_t i = 0; i < capacity_; ++i) {
      auto& entry = map_[i];
      if (entry.port != kFreePort && entry.port != kDeletedPort) {
        return Iterator(this, i);
      }
    }
    return end();
  }

  DART_FORCE_INLINE Iterator end() { return Iterator(this, capacity_); }

  void Insert(const T& entry) {
    // Search for the first unused slot. Make use of the knowledge that here is
    // currently no port with this id in the port map.
    ASSERT(FindIndexOfPort(entry.port) < 0);
    intptr_t index = entry.port % capacity_;
    T cur = map_[index];

    // Stop the search at the first found unused (free or deleted) slot.
    while (cur.port != kFreePort && cur.port != kDeletedPort) {
      index = (index + 1) % capacity_;
      cur = map_[index];
    }

    // Insert the newly created port at the index.
    ASSERT(map_[index].port == kFreePort || map_[index].port == kDeletedPort);
    if (map_[index].port == kDeletedPort) {
      deleted_--;
    }
    map_[index] = entry;
    ASSERT(FindIndexOfPort(entry.port) >= 0);

    // Increment number of used slots and grow if necessary.
    used_++;
    MaintainInvariants();

#if defined(DEBUG)
    dirty_counter_++;
#endif
  }

  Iterator TryLookup(Dart_Port port) {
    const intptr_t index = FindIndexOfPort(port);
    if (index >= 0) return Iterator(this, index);
    return Iterator(this, capacity_);
  }

  bool Contains(Dart_Port port) { return FindIndexOfPort(port) >= 0; }

  // To be called if an iterator was used to delete an entry.
  void Rebalance() { MaintainInvariants(); }

 private:
  intptr_t FindIndexOfPort(Dart_Port port) {
    // ILLEGAL_PORT (0) is used as a sentinel value in Entry.port. The loop
    // below could return the index to a deleted port when we are searching for
    // port id ILLEGAL_PORT. Return -1 immediately to indicate the port
    // does not exist.
    if (port == ILLEGAL_PORT) {
      return -1;
    }
    ASSERT(port != ILLEGAL_PORT);
    intptr_t index = port % capacity_;
    intptr_t start_index = index;
    T entry = map_[index];
    while (entry.port != kFreePort) {
      if (entry.port == port) {
        return index;
      }
      index = (index + 1) % capacity_;
      // Prevent endless loops.
      ASSERT(index != start_index);
      entry = map_[index];
    }
    return -1;
  }

  void MaintainInvariants() {
    const intptr_t empty = capacity_ - used_ - deleted_;
    if (used_ > ((capacity_ / 4) * 3)) {
      // Grow the port map.
      Rehash(capacity_ * 2);
    } else if (empty < deleted_) {
      // Rehash without growing the table to flush the deleted slots out of the
      // map.
      Rehash(capacity_);
    }
  }

  void Rehash(intptr_t new_capacity) {
    T* new_ports = new T[new_capacity];

    for (auto entry : *this) {
      intptr_t new_index = entry.port % new_capacity;
      while (new_ports[new_index].port != 0) {
        new_index = (new_index + 1) % new_capacity;
      }
      new_ports[new_index] = entry;
    }
    delete[] map_;
    map_ = new_ports;
    capacity_ = new_capacity;
    deleted_ = 0;

#if defined(DEBUG)
    dirty_counter_++;
#endif
  }

  T* map_ = nullptr;
  intptr_t capacity_ = 0;
  intptr_t used_ = 0;
  intptr_t deleted_ = 0;

#if defined(DEBUG)
  intptr_t dirty_counter_ = 0;
#endif
};

}  // namespace dart

#endif  // RUNTIME_VM_PORT_SET_H_
