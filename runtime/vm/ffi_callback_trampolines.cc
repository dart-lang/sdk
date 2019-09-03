// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ffi_callback_trampolines.h"
#include "vm/code_comments.h"
#include "vm/code_observers.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/exceptions.h"

namespace dart {

DECLARE_FLAG(bool, disassemble_stubs);

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(TARGET_ARCH_DBC)
uword NativeCallbackTrampolines::AllocateTrampoline() {
#if defined(DART_PRECOMPILER)
  ASSERT(!Enabled());
  UNREACHABLE();
#else

  // Callback IDs are limited to 32-bits for trampoline compactness.
  if (kWordSize == 8 &&
      !Utils::IsInt(32, next_callback_id_ + NumCallbackTrampolinesPerPage())) {
    Exceptions::ThrowOOM();
  }

  if (trampolines_left_on_page_ == 0) {
    VirtualMemory* const memory = VirtualMemory::AllocateAligned(
        /*size=*/VirtualMemory::PageSize(),
        /*alignment=*/VirtualMemory::PageSize(),
        /*is_executable=*/false, /*name=*/"Dart VM FFI callback trampolines");

    if (memory == nullptr) {
      Exceptions::ThrowOOM();
    }

    trampoline_pages_.Add(memory);

    compiler::Assembler assembler(/*object_pool_builder=*/nullptr);
    compiler::StubCodeCompiler::GenerateJITCallbackTrampolines(
        &assembler, next_callback_id_);

    MemoryRegion region(memory->address(), memory->size());
    assembler.FinalizeInstructions(region);

    memory->Protect(VirtualMemory::kReadExecute);

#if !defined(PRODUCT)
    const char* name = "FfiJitCallbackTrampolines";
    ASSERT(!Thread::Current()->IsAtSafepoint());
    if (CodeObservers::AreActive()) {
      const auto& comments = CreateCommentsFrom(&assembler);
      CodeCommentsWrapper wrapper(comments);
      CodeObservers::NotifyAll(name,
                               /*base=*/memory->start(),
                               /*prologue_offset=*/0,
                               /*size=*/assembler.CodeSize(),
                               /*optimized=*/false,  // not really relevant
                               &wrapper);
    }
#endif
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
    if (FLAG_disassemble_stubs && FLAG_support_disassembler) {
      DisassembleToStdout formatter;
      THR_Print(
          "Code for native callback trampolines "
          "[%" Pd " -> %" Pd "]: {\n",
          next_callback_id_,
          next_callback_id_ + NumCallbackTrampolinesPerPage() - 1);
      const auto& comments = CreateCommentsFrom(&assembler);
      Disassembler::Disassemble(memory->start(),
                                memory->start() + assembler.CodeSize(),
                                &formatter, &comments);
    }
#endif

    next_callback_trampoline_ = memory->start();
    trampolines_left_on_page_ = NumCallbackTrampolinesPerPage();
  }

  trampolines_left_on_page_--;
  next_callback_id_++;
  const uword entrypoint = next_callback_trampoline_;
  next_callback_trampoline_ +=
      compiler::StubCodeCompiler::kNativeCallbackTrampolineSize;
  return entrypoint;
#endif  // defined(DART_PRECOMPILER)
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME) && !defined(TARGET_ARCH_DBC)

}  // namespace dart
