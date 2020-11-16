// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/unit_test_custom_zone.h"

#include "vm/compiler/runtime_api.h"

// Directly compile cc files into the custom zone, so that we do not get linker
// errors from object files compiled against the DartVM Zone.
#include "vm/compiler/ffi/native_calling_convention.cc"  // NOLINT
#include "vm/compiler/ffi/native_location.cc"            // NOLINT
#include "vm/compiler/ffi/native_type.cc"                // NOLINT
#include "vm/zone_text_buffer.cc"                        // NOLINT

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
