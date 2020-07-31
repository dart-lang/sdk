// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

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
  ASSERT(!is_enabled_);
  const Code& code = Code::Handle(code_);
  switch (breakpoint_kind_) {
    case PcDescriptorsLayout::kIcCall: {
      Object& data = Object::Handle();
      saved_value_ = CodePatcher::GetInstanceCallAt(pc_, code, &data);
      CodePatcher::PatchInstanceCallAt(pc_, code, data,
                                       StubCode::ICCallBreakpoint());
      break;
    }
    case PcDescriptorsLayout::kUnoptStaticCall: {
      saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
      CodePatcher::PatchPoolPointerCallAt(
          pc_, code, StubCode::UnoptStaticCallBreakpoint());
      break;
    }
    case PcDescriptorsLayout::kRuntimeCall: {
      saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
      CodePatcher::PatchPoolPointerCallAt(pc_, code,
                                          StubCode::RuntimeCallBreakpoint());
      break;
    }
    default:
      UNREACHABLE();
  }
  is_enabled_ = true;
}

void CodeBreakpoint::RestoreCode() {
  ASSERT(is_enabled_);
  const Code& code = Code::Handle(code_);
  switch (breakpoint_kind_) {
    case PcDescriptorsLayout::kIcCall: {
      Object& data = Object::Handle();
      CodePatcher::GetInstanceCallAt(pc_, code, &data);
      CodePatcher::PatchInstanceCallAt(pc_, code, data,
                                       Code::Handle(saved_value_));
      break;
    }
    case PcDescriptorsLayout::kUnoptStaticCall:
    case PcDescriptorsLayout::kRuntimeCall: {
      CodePatcher::PatchPoolPointerCallAt(pc_, code,
                                          Code::Handle(saved_value_));
      break;
    }
    default:
      UNREACHABLE();
  }
  is_enabled_ = false;
}

#endif  // !PRODUCT

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
