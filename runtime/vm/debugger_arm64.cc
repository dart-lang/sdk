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

uword CodeBreakpoint::OrigStubAddress() const {
  const Code& code = Code::Handle(code_);
  const Array& object_pool = Array::Handle(code.ObjectPool());
  const uword offset = saved_value_;
  ASSERT((offset % kWordSize) == 0);
  const intptr_t index = (offset - Array::data_offset()) / kWordSize;
  const uword stub_address = reinterpret_cast<uword>(object_pool.At(index));
  ASSERT(stub_address % kWordSize == 0);
  return stub_address;
}


void CodeBreakpoint::PatchCode() {
  ASSERT(!is_enabled_);
  const Code& code = Code::Handle(code_);
  const Instructions& instrs = Instructions::Handle(code.instructions());
  {
    WritableInstructionsScope writable(instrs.EntryPoint(), instrs.size());
    switch (breakpoint_kind_) {
      case RawPcDescriptors::kIcCall:
      case RawPcDescriptors::kUnoptStaticCall: {
        int32_t offset = CodePatcher::GetPoolOffsetAt(pc_);
        ASSERT((offset > 0) && ((offset & 0x7) == 0));
        saved_value_ = static_cast<uword>(offset);
        const uint32_t stub_offset =
            InstructionPattern::OffsetFromPPIndex(
                Assembler::kICCallBreakpointCPIndex);
        CodePatcher::SetPoolOffsetAt(pc_, stub_offset);
        break;
      }
      case RawPcDescriptors::kClosureCall: {
        int32_t offset = CodePatcher::GetPoolOffsetAt(pc_);
        ASSERT((offset > 0) && ((offset & 0x7) == 0));
        saved_value_ = static_cast<uword>(offset);
        const uint32_t stub_offset =
            InstructionPattern::OffsetFromPPIndex(
                Assembler::kClosureCallBreakpointCPIndex);
        CodePatcher::SetPoolOffsetAt(pc_, stub_offset);
        break;
      }
      case RawPcDescriptors::kRuntimeCall: {
        int32_t offset = CodePatcher::GetPoolOffsetAt(pc_);
        ASSERT((offset > 0) && ((offset & 0x7) == 0));
        saved_value_ = static_cast<uword>(offset);
        const uint32_t stub_offset =
            InstructionPattern::OffsetFromPPIndex(
                Assembler::kRuntimeCallBreakpointCPIndex);
        CodePatcher::SetPoolOffsetAt(pc_, stub_offset);
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
        CodePatcher::SetPoolOffsetAt(pc_, static_cast<int32_t>(saved_value_));
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  is_enabled_ = false;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
