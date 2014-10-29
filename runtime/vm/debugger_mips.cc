// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"

namespace dart {

RawInstance* ActivationFrame::GetInstanceCallReceiver(
                 intptr_t num_actual_args) {
  ASSERT(num_actual_args > 0);  // At minimum we have a receiver on the stack.
  // Stack pointer points to last argument that was pushed on the stack.
  uword receiver_addr = sp() + ((num_actual_args - 1) * kWordSize);
  return reinterpret_cast<RawInstance*>(
             *reinterpret_cast<uword*>(receiver_addr));
}


RawObject* ActivationFrame::GetClosureObject(intptr_t num_actual_args) {
  // At a minimum we have the closure object on the stack.
  ASSERT(num_actual_args > 0);
  // Stack pointer points to last argument that was pushed on the stack.
  uword closure_addr = sp() + ((num_actual_args - 1) * kWordSize);
  return reinterpret_cast<RawObject*>(
             *reinterpret_cast<uword*>(closure_addr));
}


uword CodeBreakpoint::OrigStubAddress() const {
  return saved_value_;
}


void CodeBreakpoint::PatchCode() {
  ASSERT(!is_enabled_);
  const Code& code = Code::Handle(code_);
  const Instructions& instrs = Instructions::Handle(code.instructions());
  Isolate* isolate = Isolate::Current();
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    switch (breakpoint_kind_) {
      case RawPcDescriptors::kIcCall:
      case RawPcDescriptors::kUnoptStaticCall: {
        saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
        CodePatcher::PatchStaticCallAt(
            pc_, code, isolate->stub_code()->ICCallBreakpointEntryPoint());
        break;
      }
      case RawPcDescriptors::kClosureCall: {
        saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
        CodePatcher::PatchStaticCallAt(
            pc_, code, isolate->stub_code()->ClosureCallBreakpointEntryPoint());
        break;
      }
      case RawPcDescriptors::kRuntimeCall: {
        saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
        CodePatcher::PatchStaticCallAt(
            pc_, code, isolate->stub_code()->RuntimeCallBreakpointEntryPoint());
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  is_enabled_ = true;
}


void CodeBreakpoint::RestoreCode() {
  ASSERT(is_enabled_);
  const Code& code = Code::Handle(code_);
  const Instructions& instrs = Instructions::Handle(code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    switch (breakpoint_kind_) {
      case RawPcDescriptors::kIcCall:
      case RawPcDescriptors::kUnoptStaticCall:
      case RawPcDescriptors::kClosureCall:
      case RawPcDescriptors::kRuntimeCall: {
        CodePatcher::PatchStaticCallAt(pc_, code, saved_value_);
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  is_enabled_ = false;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
