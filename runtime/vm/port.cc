// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/port.h"

namespace dart {

MessageQueue::~MessageQueue() {
  // Ensure that all pending messages have been released.
  ASSERT(head_ == NULL);
}


void MessageQueue::Enqueue(PortMessage* msg) {
  // Make sure messages are not reused.
  ASSERT(msg->next_ == NULL);
  if (head_ == NULL) {
    // Only element in the queue.
    head_ = msg;
    tail_ = msg;
  } else {
    ASSERT(tail_ != NULL);
    // Append at the tail.
    tail_->next_ = msg;
    tail_ = msg;
  }
}


PortMessage* MessageQueue::Dequeue() {
  PortMessage* result = head_;
  if (result != NULL) {
    head_ = result->next_;
    // The following update to tail_ is not strictly needed.
    if (head_ == NULL) {
      tail_ = NULL;
    }
#if DEBUG
    result->next_ = result;  // Make sure to trigger ASSERT in Enqueue.
#endif  // DEBUG
  }
  return result;
}


void MessageQueue::Flush(intptr_t port_id) {
  PortMessage* cur = head_;
  PortMessage* prev = NULL;
  while (cur != NULL) {
    PortMessage* next = cur->next_;
    // If the message matches, then remove it from the queue and delete it.
    if (cur->dest_id() == port_id) {
      if (prev != NULL) {
        prev->next_ = next;
      } else {
        head_ = next;
      }
      delete cur;
    } else {
      // Move prev forward.
      prev = cur;
    }
    // Advance to the next message in the queue.
    cur = next;
  }
  tail_ = prev;
}


void MessageQueue::FlushAll() {
  PortMessage* cur = head_;
  head_ = NULL;
  tail_ = NULL;
  while (cur != NULL) {
    PortMessage* next = cur->next_;
    delete next;
    cur = next;
  }
}


Mutex* PortMap::mutex_ = NULL;

PortMap::Entry* PortMap::map_ = NULL;
Isolate* PortMap::deleted_entry_ = reinterpret_cast<Isolate*>(1);
intptr_t PortMap::capacity_ = 0;
intptr_t PortMap::used_ = 0;
intptr_t PortMap::deleted_ = 0;

intptr_t PortMap::next_id_ = 7111;


intptr_t PortMap::FindId(intptr_t id) {
  intptr_t index = id % capacity_;
  intptr_t start_index = index;
  Entry entry = map_[index];
  while (entry.isolate != NULL) {
    if (entry.id == id) {
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
    if (entry.id != 0) {
      intptr_t new_index = entry.id % new_capacity;
      while (new_ports[new_index].id != 0) {
        new_index = (new_index + 1) % new_capacity;
      }
      new_ports[new_index] = entry;
    }
  }
  delete map_;
  map_ = new_ports;
  capacity_ = new_capacity;
  deleted_ = 0;
}


intptr_t PortMap::AllocateId() {
  intptr_t result = next_id_;

  do {
    // TODO(iposva): Use an approved hashing function to have less predictable
    // port ids, or make them not accessible from Dart code or both.
    next_id_++;
  } while (FindId(next_id_) >= 0);

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


intptr_t PortMap::CreatePort() {
  Isolate* isolate = Isolate::Current();

  MutexLocker ml(mutex_);

  Entry entry;
  entry.id = AllocateId();
  entry.isolate = isolate;

  // Search for the first unused slot. Make use of the knowledge that here is
  // currently no port with this id in the port map.
  ASSERT(FindId(entry.id) < 0);
  intptr_t index = entry.id % capacity_;
  Entry cur = map_[index];
  // Stop the search at the first found unused (free or deleted) slot.
  while (cur.id != 0) {
    index = (index + 1) % capacity_;
    cur = map_[index];
  }

  // Insert the newly created port at the index.
  ASSERT(index >= 0);
  ASSERT(index < capacity_);
  ASSERT(map_[index].id == 0);
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

  return entry.id;
}


void PortMap::ClosePort(intptr_t id) {
  Isolate* isolate = Isolate::Current();
  {
    MutexLocker ml(mutex_);
    intptr_t index = FindId(id);
    if (index < 0) {
      return;
    }
    ASSERT(index < capacity_);
    ASSERT(map_[index].id != 0);
    ASSERT(map_[index].isolate == isolate);
    // Before releasing the lock mark the slot in the map as deleted. This makes
    // it possible to release the port map lock before flushing all of its
    // pending messages below.
    map_[index].id = 0;
    map_[index].isolate = deleted_entry_;
    isolate->decrement_active_ports();

    used_--;
    deleted_++;
    MaintainInvariants();
  }
  {
    // Remove the pending messages for this port.
    MonitorLocker ml(isolate->monitor());
    isolate->message_queue()->Flush(id);
  }
}


void PortMap::ClosePorts() {
  Isolate* isolate = Isolate::Current();
  {
    MutexLocker ml(mutex_);
    for (intptr_t i = 0; i < capacity_; i++) {
      if (map_[i].isolate == isolate) {
        // Mark the slot as deleted.
        map_[i].id = 0;
        map_[i].isolate = deleted_entry_;
        isolate->decrement_active_ports();

        used_--;
        deleted_++;
      }
    }
    MaintainInvariants();
  }
  isolate->message_queue()->FlushAll();
}


bool PortMap::IsActivePort(intptr_t id) {
  MutexLocker ml(mutex_);
  return (FindId(id) >= 0);
}


bool PortMap::PostMessage(PortMessage* msg) {
  intptr_t id = msg->dest_id();
  mutex_->Lock();
  intptr_t index = FindId(id);
  if (index < 0) {
    mutex_->Unlock();
    return false;
  }
  ASSERT(index >= 0);
  ASSERT(index < capacity_);
  Isolate* isolate = map_[index].isolate;
  ASSERT(map_[index].id != 0);
  ASSERT((isolate != NULL) && (isolate != deleted_entry_));
  Monitor* monitor = isolate->monitor();
  monitor->Enter();
  isolate->message_queue()->Enqueue(msg);
  monitor->Notify();
  monitor->Exit();
  mutex_->Unlock();
  return true;
}


PortMessage* PortMap::ReceiveMessage(int64_t millis) {
  // Since only the isolate owning the port can close the port and remove it
  // from the port map and flush its messages, we can safely assume that the
  // all messages in the message queue are for active ports.
  Isolate* isolate = Isolate::Current();
  {
    MonitorLocker ml(isolate->monitor());
    PortMessage* result = isolate->message_queue()->Dequeue();
    if (result == NULL) {
      ml.Wait(millis);
      result = isolate->message_queue()->Dequeue();
      // We will return a NULL message for spurious wakeups or timeouts.
    }
    return result;
  }
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
