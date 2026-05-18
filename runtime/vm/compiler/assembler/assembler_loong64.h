// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_LOONG64_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_LOONG64_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
#error Do not include assembler_loong64.h directly; use assembler.h instead.
#endif

#include "vm/compiler/assembler/assembler_base.h"
#include "vm/constants.h"

namespace dart {

namespace compiler {

class Address {
 public:
  Address(Register base, intptr_t offset) : base_(base), offset_(offset) {}
  explicit Address(Register base) : base_(base), offset_(0) {}

  Address(Register base, Register index) = delete;

  Register base() const { return base_; }
  intptr_t offset() const { return offset_; }

 private:
  Register base_;
  intptr_t offset_;
};

class FieldAddress : public Address {
 public:
  FieldAddress(Register base, intptr_t offset)
      : Address(base, offset - kHeapObjectTag) {}

  FieldAddress(Register base, Register index) = delete;
};

class Assembler : public AssemblerBase {
 public:
  explicit Assembler(ObjectPoolBuilder* object_pool_builder)
      : AssemblerBase(object_pool_builder) {}
  ~Assembler() override = default;
};

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_LOONG64_H_
