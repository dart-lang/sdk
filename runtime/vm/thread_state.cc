// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_state.h"

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

}  // namespace dart
