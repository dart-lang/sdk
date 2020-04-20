// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#ifndef RUNTIME_VM_FFI_CALLBACK_TRAMPOLINES_H_
#define RUNTIME_VM_FFI_CALLBACK_TRAMPOLINES_H_

#include "platform/allocation.h"
#include "platform/growable_array.h"
#include "vm/flag_list.h"
#include "vm/virtual_memory.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/stub_code_compiler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

#if !defined(DART_PRECOMPILED_RUNTIME)
// In JIT mode, when write-protection is enabled without dual-mapping, we cannot
// rely on Instructions generated in the Isolate's heap to be executable while
// native code is running in a safepoint. This means that native code cannot
// directly invoke FFI callback trampolines.
//
// To solve this, we create trampolines tied to consecutive sequences of
// callback IDs which leave the safepoint before invoking the FFI callback,
// and re-enter the safepoint on return from the callback.
//
// Since we can never map these trampolines RX -> RW, we eagerly generate as
// many as will fit on a single page, since pages are the smallest granularity
// of memory protection.
//
// See also:
//  - StubCodeCompiler::GenerateJITCallbackTrampolines
//  - {NativeEntryInstr, NativeReturnInstr}::EmitNativeCode
DECLARE_FLAG(bool, write_protect_code);

class NativeCallbackTrampolines : public ValueObject {
 public:
  static bool Enabled() { return !FLAG_precompiled_mode; }

  static intptr_t NumCallbackTrampolinesPerPage() {
    return (VirtualMemory::PageSize() -
            compiler::StubCodeCompiler::kNativeCallbackSharedStubSize) /
           compiler::StubCodeCompiler::kNativeCallbackTrampolineSize;
  }

  NativeCallbackTrampolines() {}
  ~NativeCallbackTrampolines() {
    // Unmap all the trampoline pages. 'VirtualMemory's are new-allocated.
    for (intptr_t i = 0; i < trampoline_pages_.length(); ++i) {
      delete trampoline_pages_[i];
    }
  }

  // For each callback ID, we have an entry in Thread::ffi_callback_code_ and
  // a trampoline here. These arrays must be kept in sync and this method is
  // exposed to assert that.
  intptr_t next_callback_id() const { return next_callback_id_; }

  // Allocates a callback trampoline corresponding to the callback id
  // 'next_callback_id()'. Returns an entrypoint to the trampoline.
  void AllocateTrampoline();

  // Get the entrypoint for a previously allocated callback ID.
  uword TrampolineForId(int32_t callback_id);

 private:
  MallocGrowableArray<VirtualMemory*> trampoline_pages_;
  intptr_t trampolines_left_on_page_ = 0;
  intptr_t next_callback_id_ = 0;

  DISALLOW_COPY_AND_ASSIGN(NativeCallbackTrampolines);
};
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart

#endif  // RUNTIME_VM_FFI_CALLBACK_TRAMPOLINES_H_
