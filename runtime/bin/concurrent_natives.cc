// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/concurrent_natives.h"

#include "bin/builtin.h"

namespace dart {
namespace bin {

// Lists the native functions implementing advanced dart:io classes.
// Some classes, like File and Directory, list their implementations in
// builtin_natives.cc instead.
#define CONCURRENT_NATIVE_LIST(V)                                              \
  V(Mutex_Initialize, 1)                                                       \
  V(Mutex_Lock, 1)                                                             \
  V(Mutex_Unlock, 1)                                                           \
  V(ConditionVariable_Initialize, 1)                                           \
  V(ConditionVariable_Wait, 2)                                                 \
  V(ConditionVariable_Notify, 1)

CONCURRENT_NATIVE_LIST(DECLARE_FUNCTION);

static const struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} ConcurrentEntries[] = {CONCURRENT_NATIVE_LIST(REGISTER_FUNCTION)};

Dart_NativeFunction ConcurrentNativeLookup(Dart_Handle name,
                                           int argument_count,
                                           bool* auto_setup_scope) {
  const char* function_name = nullptr;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  ASSERT(!Dart_IsError(result));
  ASSERT(function_name != nullptr);
  ASSERT(auto_setup_scope != nullptr);
  *auto_setup_scope = true;
  int num_entries = sizeof(ConcurrentEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    const struct NativeEntries* entry = &(ConcurrentEntries[i]);
    if ((strcmp(function_name, entry->name_) == 0) &&
        (entry->argument_count_ == argument_count)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return nullptr;
}

const uint8_t* ConcurrentNativeSymbol(Dart_NativeFunction nf) {
  int num_entries = sizeof(ConcurrentEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    const struct NativeEntries* entry = &(ConcurrentEntries[i]);
    if (reinterpret_cast<Dart_NativeFunction>(entry->function_) == nf) {
      return reinterpret_cast<const uint8_t*>(entry->name_);
    }
  }
  return nullptr;
}

}  // namespace bin
}  // namespace dart
