// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_NATIVE_SYMBOL_H_
#define VM_NATIVE_SYMBOL_H_

#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

class Mutex;

class NativeSymbolResolver : public AllStatic {
 public:
  static void InitOnce();
  static void ShutdownOnce();
  static char* LookupSymbolName(uintptr_t pc, uintptr_t* start);
  static void FreeSymbolName(char* name);
};


}  // namespace dart

#endif  // VM_NATIVE_SYMBOL_H_
