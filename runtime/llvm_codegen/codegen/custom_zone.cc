// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "custom_zone.h"

#include "platform/text_buffer.h"
#include "platform/unicode.h"
#include "platform/utils.h"
#include "vm/double_conversion.h"
#include "vm/os.h"

#include "platform/assert.cc"  // NOLINT
#include "platform/syslog_linux.cc"  // NOLINT
#include "platform/text_buffer.cc"  // NOLINT
#include "platform/unicode.cc"  // NOLINT
#include "platform/utils.cc"  // NOLINT
#include "platform/utils_linux.cc"  // NOLINT
#include "vm/compiler/backend/sexpression.cc"  // NOLINT
#include "vm/double_conversion.cc"  // NOLINT
#include "vm/flags.cc"  // NOLINT
#include "vm/os_linux.cc"  // NOLINT
#include "vm/zone_text_buffer.cc"  // NOLINT

namespace dart {

void* ZoneAllocated::operator new(uintptr_t size, dart::Zone* zone) {
  return reinterpret_cast<void*>(zone->AllocUnsafe(size));
}

Zone::~Zone() {
  while (buffers_.size() > 0) {
    free(buffers_.back());
    buffers_.pop_back();
  }
}

void* Zone::AllocUnsafe(intptr_t size) {
  void* memory = malloc(size);
  buffers_.push_back(memory);
  return memory;
}

DART_EXPORT void Dart_PrepareToAbort() {
  fprintf(stderr, "Dart_PrepareToAbort() not implemented!\n");
  exit(1);
}

DART_EXPORT void Dart_DumpNativeStackTrace(void* context) {
  fprintf(stderr, "Dart_DumpNativeStackTrace() not implemented!\n");
  exit(1);
}

}  // namespace dart
