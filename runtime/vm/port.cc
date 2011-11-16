// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/port.h"

#include "vm/isolate.h"
#include "vm/thread.h"
#include "vm/utils.h"

namespace dart {


Mutex* PortMap::mutex_ = NULL;

PortMap::Entry* PortMap::map_ = NULL;
Isolate* PortMap::deleted_entry_ = reinterpret_cast<Isolate*>(1);
intptr_t PortMap::capacity_ = 0;
intptr_t PortMap::used_ = 0;
intptr_t PortMap::deleted_ = 0;

Dart_Port PortMap::next_port_ = 7111;


intptr_t PortMap::FindPort(Dart_Port port) {
  intptr_t index = port % capacity_;
  intptr_t start_index = index;
  Entry entry = map_[index];
  while (entry.isolate != NULL) {
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


void PortMap::Rehash(intptr_t new_capacity) {
  Entry* new_ports = new Entry[new_capacity];
  memset(new_ports, 0, new_capacity * sizeof(Entry));

  for (intptr_t i = 0; i < capacity_; i++) {
    Entry entry = map_[i];
    // Skip free and deleted entries.
    if (entry.port != 0) {
      intptr_t new_index = entry.port % new_capacity;
      while (new_ports[new_index].port != 0) {
        new_index = (new_index + 1) % new_capacity;
      }
      new_ports[new_index] = entry;
    }
  }
  delete[] map_;
  map_ = new_ports;
  capacity_ = new_capacity;
  deleted_ = 0;
}


Dart_Port PortMap::AllocatePort() {
  Dart_Port result = next_port_;

  do {
    // TODO(iposva): Use an approved hashing function to have less predictable
    // port ids, or make them not accessible from Dart code or both.
    next_port_++;
  } while (FindPort(next_port_) >= 0);

  ASSERT(result != 0);
  return result;
}


void PortMap::MaintainInvariants() {
  intptr_t empty = capacity_ - used_ - deleted_;
  if (used_ > ((capacity_ / 4) * 3)) {
    // Grow the port map.
    Rehash(capacity_ * 2);
  } else if (empty < deleted_) {
    // Rehash without growing the table to flush the deleted slots out of the
    // map.
    Rehash(capacity_);
  }
}


Dart_Port PortMap::CreatePort() {
  Isolate* isolate = Isolate::Current();

  MutexLocker ml(mutex_);

  Entry entry;
  entry.port = AllocatePort();
  entry.isolate = isolate;

  // Search for the first unused slot. Make use of the knowledge that here is
  // currently no port with this id in the port map.
  ASSERT(FindPort(entry.port) < 0);
  intptr_t index = entry.port % capacity_;
  Entry cur = map_[index];
  // Stop the search at the first found unused (free or deleted) slot.
  while (cur.port != 0) {
    index = (index + 1) % capacity_;
    cur = map_[index];
  }

  // Insert the newly created port at the index.
  ASSERT(index >= 0);
  ASSERT(index < capacity_);
  ASSERT(map_[index].port == 0);
  ASSERT((map_[index].isolate == NULL) ||
         (map_[index].isolate == deleted_entry_));
  if (map_[index].isolate == deleted_entry_) {
    // Consuming a deleted entry.
    deleted_--;
  }
  map_[index] = entry;
  isolate->increment_active_ports();

  // Increment number of used slots and grow if necessary.
  used_++;
  MaintainInvariants();

  return entry.port;
}


void PortMap::ClosePort(Dart_Port port) {
  Isolate* isolate = Isolate::Current();
  {
    MutexLocker ml(mutex_);
    intptr_t index = FindPort(port);
    if (index < 0) {
      return;
    }
    ASSERT(index < capacity_);
    ASSERT(map_[index].port != 0);
    ASSERT(map_[index].isolate == isolate);
    // Before releasing the lock mark the slot in the map as deleted. This makes
    // it possible to release the port map lock before flushing all of its
    // pending messages below.
    map_[index].port = 0;
    map_[index].isolate = deleted_entry_;
    isolate->decrement_active_ports();

    used_--;
    deleted_++;
    MaintainInvariants();
  }

  // Notify the embedder that this port is closed.
  Dart_ClosePortCallback callback = isolate->close_port_callback();
  ASSERT(callback);
  ASSERT(port != kCloseAllPorts);
  (*callback)(isolate, port);
}


void PortMap::ClosePorts() {
  Isolate* isolate = Isolate::Current();
  {
    MutexLocker ml(mutex_);
    for (intptr_t i = 0; i < capacity_; i++) {
      if (map_[i].isolate == isolate) {
        // Mark the slot as deleted.
        map_[i].port = 0;
        map_[i].isolate = deleted_entry_;
        isolate->decrement_active_ports();

        used_--;
        deleted_++;
      }
    }
    MaintainInvariants();
  }

  // Notify the embedder that all ports are closed.
  Dart_ClosePortCallback callback = isolate->close_port_callback();
  ASSERT(callback);
  (*callback)(isolate, kCloseAllPorts);
}


bool PortMap::IsActivePort(Dart_Port port) {
  MutexLocker ml(mutex_);
  return (FindPort(port) >= 0);
}


bool PortMap::PostMessage(Dart_Port dest_port,
                          Dart_Port reply_port,
                          Dart_Message message) {
  mutex_->Lock();
  intptr_t index = FindPort(dest_port);
  if (index < 0) {
    free(message);
    mutex_->Unlock();
    return false;
  }
  ASSERT(index >= 0);
  ASSERT(index < capacity_);
  Isolate* isolate = map_[index].isolate;
  ASSERT(map_[index].port != 0);
  ASSERT((isolate != NULL) && (isolate != deleted_entry_));

  // Delegate message delivery to the embedder.
  Dart_PostMessageCallback callback = isolate->post_message_callback();
  ASSERT(callback);
  bool result = (*callback)(isolate, dest_port, reply_port, message);

  mutex_->Unlock();
  return result;
}


void PortMap::InitOnce() {
  mutex_ = new Mutex();

  static const intptr_t kInitialCapacity = 8;
  // TODO(iposva): Verify whether we want to keep exponentially growing.
  ASSERT(Utils::IsPowerOfTwo(kInitialCapacity));
  map_ = new Entry[kInitialCapacity];
  memset(map_, 0, kInitialCapacity * sizeof(Entry));
  capacity_ = kInitialCapacity;
  used_ = 0;
  deleted_ = 0;
}


}  // namespace dart
