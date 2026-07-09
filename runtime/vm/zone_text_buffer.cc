// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/zone_text_buffer.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/zone.h"

namespace dart {

ZoneTextBuffer::ZoneTextBuffer(Zone* zone, intptr_t initial_capacity)
    : zone_(zone) {
  ASSERT(initial_capacity > 0);
  buffer_ = reinterpret_cast<char*>(zone->Alloc<char>(initial_capacity));
  capacity_ = initial_capacity;
  buffer_[length_] = '\0';
}

void ZoneTextBuffer::Clear() {
  const intptr_t initial_capacity = 64;
  buffer_ = reinterpret_cast<char*>(zone_->Alloc<char>(initial_capacity));
  capacity_ = initial_capacity;
  length_ = 0;
  buffer_[length_] = '\0';
}

bool ZoneTextBuffer::EnsureCapacity(intptr_t len) {
  intptr_t remaining = capacity_ - length_;
  if (remaining <= len) {
    intptr_t new_capacity = capacity_ + Utils::Maximum(capacity_, len);
    buffer_ = zone_->Realloc<char>(buffer_, capacity_, new_capacity);
    capacity_ = new_capacity;
  }
  return true;
}

}  // namespace dart
