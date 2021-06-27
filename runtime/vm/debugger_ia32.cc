// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/debugger.h"

#include "vm/code_patcher.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/cpu.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

#ifndef PRODUCT

CodePtr CodeBreakpoint::OrigStubAddress() const {
  return saved_value_;
}

void CodeBreakpoint::PatchCode() {
  ASSERT(!IsEnabled());
  auto thread = Thread::Current();
  auto zone = thread->zone();
  const Code& code = Code::Handle(zone, code_);
  const Instructions& instrs = Instructions::Handle(zone, code.instructions());
  Code& stub_target = Code::Handle(zone);
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    WritableInstructionsScope writable(instrs.PayloadStart(), instrs.Size());
    switch (breakpoint_kind_) {
      case UntaggedPcDescriptors::kIcCall: {
        stub_target = StubCode::ICCallBreakpoint().ptr();
        break;
      }
      case UntaggedPcDescriptors::kUnoptStaticCall: {
        stub_target = StubCode::UnoptStaticCallBreakpoint().ptr();
        break;
      }
      case UntaggedPcDescriptors::kRuntimeCall: {
        saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
        stub_target = StubCode::RuntimeCallBreakpoint().ptr();
        break;
      }
      default:
        UNREACHABLE();
    }
    saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
    CodePatcher::PatchStaticCallAt(pc_, code, stub_target);
  });
}

void CodeBreakpoint::RestoreCode() {
  ASSERT(IsEnabled());
  auto thread = Thread::Current();
  auto zone = thread->zone();
  const Code& code = Code::Handle(zone, code_);
  const Instructions& instrs = Instructions::Handle(zone, code.instructions());
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    WritableInstructionsScope writable(instrs.PayloadStart(), instrs.Size());
    switch (breakpoint_kind_) {
      case UntaggedPcDescriptors::kIcCall:
      case UntaggedPcDescriptors::kUnoptStaticCall:
      case UntaggedPcDescriptors::kRuntimeCall: {
        CodePatcher::PatchStaticCallAt(pc_, code, Code::Handle(saved_value_));
        break;
      }
      default:
        UNREACHABLE();
    }
  });
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
