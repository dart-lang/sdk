// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/kernel_isolate.h"

#include "vm/dart_api_impl.h"
#include "vm/isolate.h"
#include "vm/kernel_isolate.h"

namespace dart {

DART_EXPORT bool Dart_IsKernelIsolate(Dart_Isolate isolate) {
#if defined(DART_PRECOMPILED_RUNTIME)
  return false;
#else
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  return KernelIsolate::IsKernelIsolate(iso);
#endif
}

DART_EXPORT bool Dart_KernelIsolateIsRunning() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return false;
#else
  return KernelIsolate::IsRunning();
#endif
}

DART_EXPORT Dart_Port Dart_KernelPort() {
#if defined(DART_PRECOMPILED_RUNTIME)
  return false;
#else
  return KernelIsolate::KernelPort();
#endif
}

DART_EXPORT Dart_KernelCompilationResult
Dart_CompileToKernel(const char* script_uri,
                     const uint8_t* platform_kernel,
                     intptr_t platform_kernel_size,
                     bool incremental_compile,
                     const char* package_config) {
  API_TIMELINE_DURATION(Thread::Current());

  Dart_KernelCompilationResult result;
#if defined(DART_PRECOMPILED_RUNTIME)
  result.status = Dart_KernelCompilationStatus_Unknown;
  result.error = strdup("Dart_CompileToKernel is unsupported.");
#else
  result = KernelIsolate::CompileToKernel(script_uri, platform_kernel,
                                          platform_kernel_size, 0, NULL,
                                          incremental_compile, package_config);
  if (result.status == Dart_KernelCompilationStatus_Ok) {
    Dart_KernelCompilationResult accept_result =
        KernelIsolate::AcceptCompilation();
    if (accept_result.status != Dart_KernelCompilationStatus_Ok) {
      FATAL1(
          "An error occurred in the CFE while accepting the most recent"
          " compilation results: %s",
          accept_result.error);
    }
  }
#endif
  return result;
}

DART_EXPORT Dart_KernelCompilationResult
Dart_CompileSourcesToKernel(const char* script_uri,
                            const uint8_t* platform_kernel,
                            intptr_t platform_kernel_size,
                            int source_files_count,
                            Dart_SourceFile sources[],
                            bool incremental_compile,
                            const char* package_config,
                            const char* multiroot_filepaths,
                            const char* multiroot_scheme) {
  Dart_KernelCompilationResult result;
#if defined(DART_PRECOMPILED_RUNTIME)
  result.status = Dart_KernelCompilationStatus_Unknown;
  result.error = strdup("Dart_CompileSourcesToKernel is unsupported.");
#else
  result = KernelIsolate::CompileToKernel(
      script_uri, platform_kernel, platform_kernel_size, source_files_count,
      sources, incremental_compile, package_config, multiroot_filepaths,
      multiroot_scheme);
  if (result.status == Dart_KernelCompilationStatus_Ok) {
    if (KernelIsolate::AcceptCompilation().status !=
        Dart_KernelCompilationStatus_Ok) {
      FATAL(
          "An error occurred in the CFE while accepting the most recent"
          " compilation results.");
    }
  }
#endif
  return result;
}

DART_EXPORT Dart_KernelCompilationResult Dart_KernelListDependencies() {
  Dart_KernelCompilationResult result;
#if defined(DART_PRECOMPILED_RUNTIME)
  result.status = Dart_KernelCompilationStatus_Unknown;
  result.error = strdup("Dart_KernelListDependencies is unsupported.");
#else
  result = KernelIsolate::ListDependencies();
#endif
  return result;
}

}  // namespace dart
