// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "vm/native_symbol.h"

#include "platform/assert.h"

namespace dart {

void NativeSymbolResolver::InitOnce() {
  UNIMPLEMENTED();
}


void NativeSymbolResolver::ShutdownOnce() {
  UNIMPLEMENTED();
}


char* NativeSymbolResolver::LookupSymbolName(uintptr_t pc, uintptr_t* start) {
  UNIMPLEMENTED();
  return NULL;
}


void NativeSymbolResolver::FreeSymbolName(char* name) {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)
