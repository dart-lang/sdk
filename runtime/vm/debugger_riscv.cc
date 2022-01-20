// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"

namespace dart {

#ifndef PRODUCT

CodePtr CodeBreakpoint::OrigStubAddress() const {
  return saved_value_;
}

void CodeBreakpoint::PatchCode() {
  ASSERT(!IsEnabled());
  const Code& code = Code::Handle(code_);
  switch (breakpoint_kind_) {
    case UntaggedPcDescriptors::kIcCall: {
      Object& data = Object::Handle();
      saved_value_ = CodePatcher::GetInstanceCallAt(pc_, code, &data);
      CodePatcher::PatchInstanceCallAt(pc_, code, data,
                                       StubCode::ICCallBreakpoint());
      break;
    }
    case UntaggedPcDescriptors::kUnoptStaticCall: {
      saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
      CodePatcher::PatchPoolPointerCallAt(
          pc_, code, StubCode::UnoptStaticCallBreakpoint());
      break;
    }
    case UntaggedPcDescriptors::kRuntimeCall: {
      saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
      CodePatcher::PatchPoolPointerCallAt(pc_, code,
                                          StubCode::RuntimeCallBreakpoint());
      break;
    }
    default:
      UNREACHABLE();
  }
}

void CodeBreakpoint::RestoreCode() {
  ASSERT(IsEnabled());
  const Code& code = Code::Handle(code_);
  switch (breakpoint_kind_) {
    case UntaggedPcDescriptors::kIcCall: {
      Object& data = Object::Handle();
      CodePatcher::GetInstanceCallAt(pc_, code, &data);
      CodePatcher::PatchInstanceCallAt(pc_, code, data,
                                       Code::Handle(saved_value_));
      break;
    }
    case UntaggedPcDescriptors::kUnoptStaticCall:
    case UntaggedPcDescriptors::kRuntimeCall: {
      CodePatcher::PatchPoolPointerCallAt(pc_, code,
                                          Code::Handle(saved_value_));
      break;
    }
    default:
      UNREACHABLE();
  }
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined TARGET_ARCH_RISCV
