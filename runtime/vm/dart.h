// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DART_H_
#define VM_DART_H_

#include "include/dart_api.h"
#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class DebugInfo;
class Isolate;

class Dart : public AllStatic {
 public:
  static bool InitOnce(int argc, const char** argv,
                       Dart_IsolateCreateCallback callback);

  static Isolate* CreateIsolate();
  static void InitializeIsolate(const Dart_Snapshot* snapshot, void* data);
  static void ShutdownIsolate();

  static Isolate* vm_isolate() { return vm_isolate_; }

  static void set_pprof_symbol_generator(DebugInfo* value) {
    pprof_symbol_generator_ = value;
  }
  static DebugInfo* pprof_symbol_generator() { return pprof_symbol_generator_; }

 private:
  static Isolate* vm_isolate_;
  static DebugInfo* pprof_symbol_generator_;
};

}  // namespace dart

#endif  // VM_DART_H_
