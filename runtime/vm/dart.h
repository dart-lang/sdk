// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DART_H_
#define RUNTIME_VM_DART_H_

#include "include/dart_api.h"
#include "vm/allocation.h"
#include "vm/snapshot.h"

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
  static char* InitOnce(
      const uint8_t* vm_isolate_snapshot,
      const uint8_t* instructions_snapshot,
      const uint8_t* data_snapshot,
      Dart_IsolateCreateCallback create,
      Dart_IsolateShutdownCallback shutdown,
      Dart_ThreadExitCallback thread_exit,
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

  // Returns a timestamp for use in debugging output in milliseconds
  // since start time.
  static int64_t timestamp();

  static void set_pprof_symbol_generator(DebugInfo* value) {
    pprof_symbol_generator_ = value;
  }
  static DebugInfo* pprof_symbol_generator() { return pprof_symbol_generator_; }

  static LocalHandle* AllocateReadOnlyApiHandle();
  static bool IsReadOnlyApiHandle(Dart_Handle handle);

  static uword AllocateReadOnlyHandle();
  static bool IsReadOnlyHandle(uword address);

  static const char* FeaturesString(Snapshot::Kind kind);

  static Snapshot::Kind snapshot_kind() {
    return snapshot_kind_;
  }
  static const uint8_t* instructions_snapshot_buffer() {
    return instructions_snapshot_buffer_;
  }
  static void set_instructions_snapshot_buffer(const uint8_t* buffer) {
    instructions_snapshot_buffer_ = buffer;
  }
  static const uint8_t* data_snapshot_buffer() {
    return data_snapshot_buffer_;
  }
  static void set_data_snapshot_buffer(const uint8_t* buffer) {
    data_snapshot_buffer_ = buffer;
  }

  static Dart_ThreadExitCallback thread_exit_callback() {
    return thread_exit_callback_;
  }
  static void set_thread_exit_callback(Dart_ThreadExitCallback cback) {
    thread_exit_callback_ = cback;
  }
  static void SetFileCallbacks(Dart_FileOpenCallback file_open,
                               Dart_FileReadCallback file_read,
                               Dart_FileWriteCallback file_write,
                               Dart_FileCloseCallback file_close) {
    file_open_callback_ = file_open;
    file_read_callback_ = file_read;
    file_write_callback_ = file_write;
    file_close_callback_ = file_close;
  }

  static Dart_FileOpenCallback file_open_callback() {
    return file_open_callback_;
  }
  static Dart_FileReadCallback file_read_callback() {
    return file_read_callback_;
  }
  static Dart_FileWriteCallback file_write_callback() {
    return file_write_callback_;
  }
  static Dart_FileCloseCallback file_close_callback() {
    return file_close_callback_;
  }

  static void set_entropy_source_callback(Dart_EntropySource entropy_source) {
    entropy_source_callback_ = entropy_source;
  }
  static Dart_EntropySource entropy_source_callback() {
    return entropy_source_callback_;
  }

 private:
  static void WaitForIsolateShutdown();
  static void WaitForApplicationIsolateShutdown();

  static Isolate* vm_isolate_;
  static int64_t start_time_;
  static ThreadPool* thread_pool_;
  static DebugInfo* pprof_symbol_generator_;
  static ReadOnlyHandles* predefined_handles_;
  static Snapshot::Kind snapshot_kind_;
  static const uint8_t* instructions_snapshot_buffer_;
  static const uint8_t* data_snapshot_buffer_;
  static Dart_ThreadExitCallback thread_exit_callback_;
  static Dart_FileOpenCallback file_open_callback_;
  static Dart_FileReadCallback file_read_callback_;
  static Dart_FileWriteCallback file_write_callback_;
  static Dart_FileCloseCallback file_close_callback_;
  static Dart_EntropySource entropy_source_callback_;
};

}  // namespace dart

#endif  // RUNTIME_VM_DART_H_
