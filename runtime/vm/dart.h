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
class LocalHandle;
class RawError;
class ReadOnlyHandles;
class ThreadPool;

class Dart : public AllStatic {
 public:
  static const char* InitOnce(
      const uint8_t* vm_isolate_snapshot,
      const uint8_t* instructions_snapshot,
      Dart_IsolateCreateCallback create,
      Dart_IsolateInterruptCallback interrupt,
      Dart_IsolateUnhandledExceptionCallback unhandled,
      Dart_IsolateShutdownCallback shutdown,
      Dart_FileOpenCallback file_open,
      Dart_FileReadCallback file_read,
      Dart_FileWriteCallback file_write,
      Dart_FileCloseCallback file_close,
      Dart_EntropySource entropy_source,
      Dart_GetVMServiceAssetsArchive get_service_assets);
  static const char* Cleanup();

  static Isolate* CreateIsolate(const char* name_prefix,
                                const Dart_IsolateFlags& api_flags);
  static RawError* InitializeIsolate(const uint8_t* snapshot, void* data);
  static void RunShutdownCallback();
  static void ShutdownIsolate(Isolate* isolate);
  static void ShutdownIsolate();

  static Isolate* vm_isolate() { return vm_isolate_; }
  static ThreadPool* thread_pool() { return thread_pool_; }

  static void set_pprof_symbol_generator(DebugInfo* value) {
    pprof_symbol_generator_ = value;
  }
  static DebugInfo* pprof_symbol_generator() { return pprof_symbol_generator_; }

  static LocalHandle* AllocateReadOnlyApiHandle();
  static bool IsReadOnlyApiHandle(Dart_Handle handle);

  static uword AllocateReadOnlyHandle();
  static bool IsReadOnlyHandle(uword address);

  static const uint8_t* instructions_snapshot_buffer() {
    return instructions_snapshot_buffer_;
  }
  static void set_instructions_snapshot_buffer(const uint8_t* buffer) {
    instructions_snapshot_buffer_ = buffer;
  }
  static bool IsRunningPrecompiledCode() {
    return instructions_snapshot_buffer_ != NULL;
  }

 private:
  static void WaitForIsolateShutdown();

  static Isolate* vm_isolate_;
  static ThreadPool* thread_pool_;
  static DebugInfo* pprof_symbol_generator_;
  static ReadOnlyHandles* predefined_handles_;
  static const uint8_t* instructions_snapshot_buffer_;
};

}  // namespace dart

#endif  // VM_DART_H_
