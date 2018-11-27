// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_KERNEL_ISOLATE_H_
#define RUNTIME_BIN_KERNEL_ISOLATE_H_

#include "include/dart_api.h"

namespace dart {

typedef enum {
  Dart_KernelCompilationStatus_Unknown = -1,
  Dart_KernelCompilationStatus_Ok = 0,
  Dart_KernelCompilationStatus_Error = 1,
  Dart_KernelCompilationStatus_Crash = 2,
} Dart_KernelCompilationStatus;

typedef struct {
  Dart_KernelCompilationStatus status;
  char* error;

  uint8_t* kernel;
  intptr_t kernel_size;
} Dart_KernelCompilationResult;

DART_EXPORT bool Dart_IsKernelIsolate(Dart_Isolate isolate);
DART_EXPORT bool Dart_KernelIsolateIsRunning();
DART_EXPORT Dart_Port Dart_KernelPort();
DART_EXPORT Dart_KernelCompilationResult
Dart_CompileToKernel(const char* script_uri,
                     const uint8_t* platform_kernel,
                     const intptr_t platform_kernel_size,
                     bool incremental_compile,
                     const char* package_config);

typedef struct {
  const char* uri;
  const char* source;
} Dart_SourceFile;
DART_EXPORT Dart_KernelCompilationResult
Dart_CompileSourcesToKernel(const char* script_uri,
                            const uint8_t* platform_kernel,
                            intptr_t platform_kernel_size,
                            int source_files_count,
                            Dart_SourceFile source_files[],
                            bool incremental_compile,
                            const char* package_config,
                            const char* multiroot_filepaths,
                            const char* multiroot_scheme);

DART_EXPORT Dart_KernelCompilationResult Dart_KernelListDependencies();

#define DART_KERNEL_ISOLATE_NAME "kernel-service"

}  // namespace dart

#endif  // RUNTIME_BIN_KERNEL_ISOLATE_H_
