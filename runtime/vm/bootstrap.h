// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BOOTSTRAP_H_
#define RUNTIME_VM_BOOTSTRAP_H_

#include "include/dart_api.h"
#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class RawError;
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
  static RawError* DoBootstrapping(kernel::Program* program);

  static void SetupNativeResolver();
  static bool IsBootstapResolver(Dart_NativeEntryResolver resolver);

  // Source path mapping for library URI and 'parts'.
  static const char* async_source_paths_[];
  static const char* core_source_paths_[];
  static const char* collection_source_paths_[];
  static const char* convert_source_paths_[];
  static const char* developer_source_paths_[];
  static const char* _internal_source_paths_[];
  static const char* isolate_source_paths_[];
  static const char* json_source_paths_[];
  static const char* math_source_paths_[];
  static const char* mirrors_source_paths_[];
  static const char* profiler_source_paths_[];
  static const char* typed_data_source_paths_[];
  static const char* utf_source_paths_[];
  static const char* _vmservice_source_paths_[];

  // Source path mapping for patch URI and 'parts'.
  static const char* async_patch_paths_[];
  static const char* core_patch_paths_[];
  static const char* collection_patch_paths_[];
  static const char* convert_patch_paths_[];
  static const char* developer_patch_paths_[];
  static const char* _internal_patch_paths_[];
  static const char* isolate_patch_paths_[];
  static const char* math_patch_paths_[];
  static const char* mirrors_patch_paths_[];
  static const char* _vmservice_patch_paths_[];

  // NULL patch paths for libraries that do not have patch files.
  static const char** profiler_patch_paths_;
  static const char** typed_data_patch_paths_;
};

}  // namespace dart

#endif  // RUNTIME_VM_BOOTSTRAP_H_
