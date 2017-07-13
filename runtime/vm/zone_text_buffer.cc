// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/zone_text_buffer.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"
#include "vm/os.h"
#include "vm/zone.h"

namespace dart {

ZoneTextBuffer::ZoneTextBuffer(Zone* zone, intptr_t initial_capacity)
    : zone_(zone), buffer_(NULL), length_(0), capacity_(0) {
  ASSERT(initial_capacity > 0);
  buffer_ = reinterpret_cast<char*>(zone->Alloc<char>(initial_capacity));
  capacity_ = initial_capacity;
  buffer_[length_] = '\0';
}

intptr_t ZoneTextBuffer::Printf(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t remaining = capacity_ - length_;
  ASSERT(remaining >= 0);
  intptr_t len = OS::VSNPrint(buffer_ + length_, remaining, format, args);
  va_end(args);
  if (len >= remaining) {
    EnsureCapacity(len);
    remaining = capacity_ - length_;
    ASSERT(remaining > len);
    va_list args2;
    va_start(args2, format);
    intptr_t len2 = OS::VSNPrint(buffer_ + length_, remaining, format, args2);
    va_end(args2);
    ASSERT(len == len2);
  }
  length_ += len;
  buffer_[length_] = '\0';
  return len;
}

void ZoneTextBuffer::AddString(const char* s) {
  Printf("%s", s);
}

void ZoneTextBuffer::EnsureCapacity(intptr_t len) {
  intptr_t remaining = capacity_ - length_;
  if (remaining <= len) {
    const int kBufferSpareCapacity = 64;  // Somewhat arbitrary.
    // TODO(turnidge): do we need to guard against overflow or other
    // security issues here? Text buffers are used by the debugger
    // to send user-controlled data (e.g. values of string variables) to
    // the debugger front-end.
    intptr_t new_capacity = capacity_ + len + kBufferSpareCapacity;
    buffer_ = zone_->Realloc<char>(buffer_, capacity_, new_capacity);
    capacity_ = new_capacity;
  }
}

}  // namespace dart
