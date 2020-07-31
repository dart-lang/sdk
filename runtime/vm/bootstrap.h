// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BOOTSTRAP_H_
#define RUNTIME_VM_BOOTSTRAP_H_

#include "include/dart_api.h"
#include "vm/allocation.h"
#include "vm/tagged_pointer.h"

namespace dart {

// Forward declarations.
namespace kernel {
class Program;
}

class Bootstrap : public AllStatic {
 public:
  // Compile the bootstrap libraries, either from sources or a Kernel program.
  // If program is NULL, compile from sources or source paths linked into
  // the VM.  If it is non-NULL it represents the Kernel program to use for
  // bootstrapping.
  // The caller of this function is responsible for managing the kernel
  // program's memory.
  static ErrorPtr DoBootstrapping(const uint8_t* kernel_buffer,
                                  intptr_t kernel_buffer_size);

  static void SetupNativeResolver();
  static bool IsBootstrapResolver(Dart_NativeEntryResolver resolver);
};

}  // namespace dart

#endif  // RUNTIME_VM_BOOTSTRAP_H_
