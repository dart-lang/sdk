// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/debugger.h"

#include "vm/code_patcher.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"

namespace dart {

#ifndef PRODUCT

RawCode* CodeBreakpoint::OrigStubAddress() const {
  return saved_value_;
}

void CodeBreakpoint::PatchCode() {
  ASSERT(!is_enabled_);
  Code& stub_target = Code::Handle();
  switch (breakpoint_kind_) {
    case RawPcDescriptors::kIcCall:
    case RawPcDescriptors::kUnoptStaticCall:
      stub_target = StubCode::ICCallBreakpoint_entry()->code();
      break;
    case RawPcDescriptors::kRuntimeCall:
      stub_target = StubCode::RuntimeCallBreakpoint_entry()->code();
      break;
    default:
      UNREACHABLE();
  }
  const Code& code = Code::Handle(code_);
  saved_value_ = CodePatcher::GetStaticCallTargetAt(pc_, code);
  CodePatcher::PatchPoolPointerCallAt(pc_, code, stub_target);
  is_enabled_ = true;
}

void CodeBreakpoint::RestoreCode() {
  ASSERT(is_enabled_);
  const Code& code = Code::Handle(code_);
  switch (breakpoint_kind_) {
    case RawPcDescriptors::kIcCall:
    case RawPcDescriptors::kUnoptStaticCall:
    case RawPcDescriptors::kRuntimeCall: {
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

#endif  // defined TARGET_ARCH_X64
