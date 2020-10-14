// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DART_H_
#define RUNTIME_VM_DART_H_

#include "include/dart_api.h"
#include "include/dart_tools_api.h"
#include "vm/allocation.h"
#include "vm/snapshot.h"

namespace dart {

// Forward declarations.
class DebugInfo;
class Isolate;
class LocalHandle;
class ReadOnlyHandles;
class ThreadPool;
namespace kernel {
class Program;
}

class Dart : public AllStatic {
 public:
  // Returns null if initialization succeeds, otherwise returns an error message
  // (caller owns error message and has to free it).
  static char* Init(const uint8_t* vm_snapshot_data,
                    const uint8_t* vm_snapshot_instructions,
                    Dart_IsolateGroupCreateCallback create_group,
                    Dart_InitializeIsolateCallback initialize_isolate,
                    Dart_IsolateShutdownCallback shutdown,
                    Dart_IsolateCleanupCallback cleanup,
                    Dart_IsolateGroupCleanupCallback cleanup_group,
                    Dart_ThreadExitCallback thread_exit,
                    Dart_FileOpenCallback file_open,
                    Dart_FileReadCallback file_read,
                    Dart_FileWriteCallback file_write,
                    Dart_FileCloseCallback file_close,
                    Dart_EntropySource entropy_source,
                    Dart_GetVMServiceAssetsArchive get_service_assets,
                    bool start_kernel_isolate,
                    Dart_CodeObserver* observer);

  // Returns null if cleanup succeeds, otherwise returns an error message
  // (caller owns error message and has to free it).
  static char* Cleanup();

  static Isolate* CreateIsolate(const char* name_prefix,
                                const Dart_IsolateFlags& api_flags,
                                IsolateGroup* isolate_group);

  // Initialize an isolate, either from a snapshot, from a Kernel binary, or
  // from SDK library sources.  If the snapshot_buffer is non-NULL,
  // initialize from a snapshot or a Kernel binary depending on the value of
  // from_kernel.  Otherwise, initialize from sources.
  static ErrorPtr InitializeIsolate(const uint8_t* snapshot_data,
                                    const uint8_t* snapshot_instructions,
                                    const uint8_t* kernel_buffer,
                                    intptr_t kernel_buffer_size,
                                    IsolateGroup* source_isolate_group,
                                    void* data);
  static ErrorPtr InitIsolateFromSnapshot(Thread* T,
                                          Isolate* I,
                                          const uint8_t* snapshot_data,
                                          const uint8_t* snapshot_instructions,
                                          const uint8_t* kernel_buffer,
                                          intptr_t kernel_buffer_size);

  static bool DetectNullSafety(const char* script_uri,
                               const uint8_t* snapshot_data,
                               const uint8_t* snapshot_instructions,
                               const uint8_t* kernel_buffer,
                               intptr_t kernel_buffer_size,
                               const char* package_config,
                               const char* original_working_directory);

  static void RunShutdownCallback();
  static void ShutdownIsolate(Isolate* isolate);
  static void ShutdownIsolate();

  static Isolate* vm_isolate() { return vm_isolate_; }
  static ThreadPool* thread_pool() { return thread_pool_; }
  static bool VmIsolateNameEquals(const char* name);

  static int64_t UptimeMicros();
  static int64_t UptimeMillis() {
    return UptimeMicros() / kMicrosecondsPerMillisecond;
  }

  static void set_pprof_symbol_generator(DebugInfo* value) {
    pprof_symbol_generator_ = value;
  }
  static DebugInfo* pprof_symbol_generator() { return pprof_symbol_generator_; }

  static LocalHandle* AllocateReadOnlyApiHandle();
  static bool IsReadOnlyApiHandle(Dart_Handle handle);

  static uword AllocateReadOnlyHandle();
  static bool IsReadOnlyHandle(uword address);

  static const char* FeaturesString(Isolate* isolate,
                                    bool is_vm_snapshot,
                                    Snapshot::Kind kind);
  static Snapshot::Kind vm_snapshot_kind() { return vm_snapshot_kind_; }

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

  static void set_gc_event_callback(Dart_GCEventCallback gc_event) {
    gc_event_callback_ = gc_event;
  }
  static Dart_GCEventCallback gc_event_callback() { return gc_event_callback_; }

 private:
  static constexpr const char* kVmIsolateName = "vm-isolate";

  static void WaitForIsolateShutdown();
  static void WaitForApplicationIsolateShutdown();

  static Isolate* vm_isolate_;
  static int64_t start_time_micros_;
  static ThreadPool* thread_pool_;
  static DebugInfo* pprof_symbol_generator_;
  static ReadOnlyHandles* predefined_handles_;
  static Snapshot::Kind vm_snapshot_kind_;
  static Dart_ThreadExitCallback thread_exit_callback_;
  static Dart_FileOpenCallback file_open_callback_;
  static Dart_FileReadCallback file_read_callback_;
  static Dart_FileWriteCallback file_write_callback_;
  static Dart_FileCloseCallback file_close_callback_;
  static Dart_EntropySource entropy_source_callback_;
  static Dart_GCEventCallback gc_event_callback_;
};

}  // namespace dart

#endif  // RUNTIME_VM_DART_H_
