// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_DBC_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_DBC_H_

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
#error Do not include assembler_dbc.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_dbc.h"
#include "vm/cpu.h"
#include "vm/hash_map.h"
#include "vm/simulator.h"

namespace dart {

namespace compiler {

// Dummy declaration to make things compile.
class Address : public ValueObject {
 private:
  Address();
};

class Assembler : public AssemblerBase {
 public:
  explicit Assembler(ObjectPoolBuilder* object_pool_builder,
                     bool use_far_branches = false)
      : AssemblerBase(object_pool_builder) {}
  ~Assembler() {}

  void Bind(Label* label);
  void Jump(Label* label);

  // Misc. functionality
  intptr_t prologue_offset() const { return 0; }

  void MonomorphicCheckedEntryJIT() {}
  void MonomorphicCheckedEntryAOT() {}

  // Debugging and bringup support.
  void Stop(const char* message) override;

  static void InitializeMemoryWithBreakpoints(uword data, intptr_t length);

  static uword GetBreakInstructionFiller() { return SimulatorBytecode::kTrap; }

  static bool IsSafe(const Object& value) { return true; }
  static bool IsSafeSmi(const Object& value) { return false; }

  enum CanBeSmi {
    kValueIsNotSmi,
    kValueCanBeSmi,
  };

  // Bytecodes.

#define DECLARE_EMIT(Name, Signature, Fmt0, Fmt1, Fmt2)                        \
  void Name(PARAMS_##Signature);

#define PARAMS_0
#define PARAMS_A_D uintptr_t ra, uintptr_t rd
#define PARAMS_D uintptr_t rd
#define PARAMS_A_B_C uintptr_t ra, uintptr_t rb, uintptr_t rc
#define PARAMS_A_B_Y uintptr_t ra, uintptr_t rb, intptr_t ry
#define PARAMS_A uintptr_t ra
#define PARAMS_X intptr_t x
#define PARAMS_T intptr_t x
#define PARAMS_A_X uintptr_t ra, intptr_t x

  BYTECODES_LIST(DECLARE_EMIT)

#undef PARAMS_0
#undef PARAMS_A_D
#undef PARAMS_D
#undef PARAMS_A_B_C
#undef PARAMS_A_B_Y
#undef PARAMS_A
#undef PARAMS_X
#undef PARAMS_T
#undef PARAMS_A_X
#undef DECLARE_EMIT

  void Emit(int32_t value);

  void PushConstant(const Object& obj);
  void LoadConstant(uintptr_t ra, const Object& obj);

  intptr_t AddConstant(const Object& obj);

  void Nop(intptr_t d) { Nop(0, d); }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_DBC_H_
