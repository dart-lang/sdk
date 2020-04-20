// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_state.h"

#include "vm/handles_impl.h"
#include "vm/zone.h"

namespace dart {

ThreadState::ThreadState(bool is_os_thread) : BaseThread(is_os_thread) {
  // This thread should not yet own any zones. If it does, we need to make sure
  // we've accounted for any memory it has already allocated.
  if (zone_ == nullptr) {
    ASSERT(current_zone_capacity_ == 0);
  } else {
    Zone* current = zone_;
    uintptr_t total_zone_capacity = 0;
    while (current != nullptr) {
      total_zone_capacity += current->CapacityInBytes();
      current = current->previous();
    }
    ASSERT(current_zone_capacity_ == total_zone_capacity);
  }
}

ThreadState::~ThreadState() {}

bool ThreadState::ZoneIsOwnedByThread(Zone* zone) const {
  ASSERT(zone != nullptr);
  Zone* current = zone_;
  while (current != nullptr) {
    if (current == zone) {
      return true;
    }
    current = current->previous();
  }
  return false;
}

bool ThreadState::IsValidZoneHandle(Dart_Handle object) const {
  Zone* zone = this->zone();
  while (zone != NULL) {
    if (zone->handles()->IsValidZoneHandle(reinterpret_cast<uword>(object))) {
      return true;
    }
    zone = zone->previous();
  }
  return false;
}

intptr_t ThreadState::CountZoneHandles() const {
  intptr_t count = 0;
  Zone* zone = this->zone();
  while (zone != NULL) {
    count += zone->handles()->CountZoneHandles();
    zone = zone->previous();
  }
  ASSERT(count >= 0);
  return count;
}

bool ThreadState::IsValidScopedHandle(Dart_Handle object) const {
  Zone* zone = this->zone();
  while (zone != NULL) {
    if (zone->handles()->IsValidScopedHandle(reinterpret_cast<uword>(object))) {
      return true;
    }
    zone = zone->previous();
  }
  return false;
}

intptr_t ThreadState::CountScopedHandles() const {
  intptr_t count = 0;
  Zone* zone = this->zone();
  while (zone != NULL) {
    count += zone->handles()->CountScopedHandles();
    zone = zone->previous();
  }
  ASSERT(count >= 0);
  return count;
}

}  // namespace dart
