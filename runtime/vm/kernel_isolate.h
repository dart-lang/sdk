// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_KERNEL_ISOLATE_H_
#define RUNTIME_VM_KERNEL_ISOLATE_H_

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "include/dart_api.h"
#include "include/dart_native_api.h"

#include "vm/allocation.h"
#include "vm/dart.h"
#include "vm/os_thread.h"

namespace dart {

class KernelIsolate : public AllStatic {
 public:
  static const char* kName;
  static const int kCompileTag;
  static const int kUpdateSourcesTag;
  static const int kAcceptTag;
  static const int kTrainTag;
  static const int kCompileExpressionTag;

  static void Run();

  static bool NameEquals(const char* name);
  static bool Exists();
  static bool IsRunning();
  static bool IsKernelIsolate(const Isolate* isolate);
  static Dart_Port WaitForKernelPort();
  static Dart_Port KernelPort() { return kernel_port_; }

  static Dart_KernelCompilationResult CompileToKernel(
      const char* script_uri,
      const uint8_t* platform_kernel,
      intptr_t platform_kernel_size,
      int source_files_count = 0,
      Dart_SourceFile source_files[] = NULL,
      bool incremental_compile = true,
      const char* package_config = NULL);

  static Dart_KernelCompilationResult AcceptCompilation();
  static Dart_KernelCompilationResult UpdateInMemorySources(
      int source_files_count,
      Dart_SourceFile source_files[]);

  static Dart_KernelCompilationResult CompileExpressionToKernel(
      const char* expression,
      const Array& definitions,
      const Array& type_definitions,
      const char* library_url,
      const char* klass,
      bool is_static);

 protected:
  static Monitor* monitor_;
  static Dart_IsolateCreateCallback create_callback_;

  static void InitCallback(Isolate* I);
  static void SetKernelIsolate(Isolate* isolate);
  static void SetLoadPort(Dart_Port port);
  static void FinishedInitializing();

  static Dart_Port kernel_port_;
  static Isolate* isolate_;
  static bool initializing_;

  static Dart_IsolateCreateCallback create_callback() {
    return create_callback_;
  }

  friend class Dart;
  friend class RunKernelTask;
};

}  // namespace dart

#endif  // DART_PRECOMPILED_RUNTIME

#endif  // RUNTIME_VM_KERNEL_ISOLATE_H_
