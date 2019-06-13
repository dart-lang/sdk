// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_LIB_FFI_H_
#define RUNTIME_LIB_FFI_H_

#if defined(TARGET_ARCH_DBC)

#include <platform/globals.h>

#include "vm/class_id.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/ffi.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

// This structure contains all data required for an ffi call.
// It consists of the function address, all calling convention argument
// register values, argument fpu register values, number of stack arguments,
// and stack argument values. The generic DBC trampoline reads its arguments
// from this structure.
//
// Moreover, the DBC trampoline also stores the integer and floating point
// result registers in the first two slots when returning.
class FfiMarshalledArguments : public ValueObject {
 public:
  explicit FfiMarshalledArguments(uint64_t* data) : data_(data) {}

  // Copies ffi trampoline arguments (including target address) from stack into
  // a signature agnostic data structure (FfiMarshalledArguments) using the
  // signature and the stack address of the first argument. (Note that this
  // only works on DBC as the stack grows upwards in DBC.)
  static uint64_t* New(const compiler::ffi::FfiSignatureDescriptor& signature,
                       const uint64_t* arg_values);

  uint64_t IntResult() const { return data_[kOffsetIntResult]; }
  uint64_t DoubleResult() const { return data_[kOffsetDoubleResult]; }

#if defined(DEBUG)
  void Print() const;
#endif

 private:
  void SetFunctionAddress(uint64_t value) const;
  void SetRegister(::dart::host::Register reg, uint64_t value) const;
  void SetFpuRegister(::dart::host::FpuRegister reg, uint64_t value) const;
  void SetAlignmentMask(uint64_t kOffsetAlignmentMask) const;
  void SetNumStackSlots(intptr_t num_args) const;
  intptr_t GetNumStackSlots() const;
  void SetStackSlotValue(intptr_t index, uint64_t value) const;

  // TODO(36809): Replace this with uword. On 32 bit architecture,
  // this should be 32 bits, as the DBC stack itself is 32 bits.
  uint64_t* data_;

  static const intptr_t kOffsetFunctionAddress = 0;
  static const intptr_t kOffsetRegisters = 1;
  static const intptr_t kOffsetFpuRegisters =
      kOffsetRegisters + ::dart::host::CallingConventions::kNumArgRegs;
  static const intptr_t kOffsetAlignmentMask =
      kOffsetFpuRegisters + ::dart::host::CallingConventions::kNumFpuArgRegs;
  static const intptr_t kOffsetNumStackSlots = kOffsetAlignmentMask + 1;
  static const intptr_t kOffsetStackSlotValues = kOffsetNumStackSlots + 1;

  static const intptr_t kOffsetIntResult = 0;
  static const intptr_t kOffsetDoubleResult = 1;
};

}  // namespace dart

#endif  // defined(TARGET_ARCH_DBC)

#endif  // RUNTIME_LIB_FFI_H_
