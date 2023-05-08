// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_state.h"

#include "vm/handles_impl.h"
#include "vm/zone.h"

namespace dart {

ThreadState::ThreadState(bool is_os_thread) : BaseThread(is_os_thread) {}

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
  while (zone != nullptr) {
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
  while (zone != nullptr) {
    count += zone->handles()->CountZoneHandles();
    zone = zone->previous();
  }
  ASSERT(count >= 0);
  return count;
}

bool ThreadState::IsValidScopedHandle(Dart_Handle object) const {
  Zone* zone = this->zone();
  while (zone != nullptr) {
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
  while (zone != nullptr) {
    count += zone->handles()->CountScopedHandles();
    zone = zone->previous();
  }
  ASSERT(count >= 0);
  return count;
}

}  // namespace dart
