// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ASSEMBLER_DBC_H_
#define RUNTIME_VM_ASSEMBLER_DBC_H_

#ifndef RUNTIME_VM_ASSEMBLER_H_
#error Do not include assembler_dbc.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_dbc.h"
#include "vm/cpu.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/simulator.h"

namespace dart {

// Dummy declaration to make things compile.
class Address : public ValueObject {
 private:
  Address();
};

class Label : public ValueObject {
 public:
  Label() : position_(0) {}

  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
  }

  // Returns the position for bound and linked labels. Cannot be used
  // for unused labels.
  intptr_t Position() const {
    ASSERT(!IsUnused());
    return IsBound() ? -position_ - kWordSize : position_ - kWordSize;
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return position_ == 0; }
  bool IsLinked() const { return position_ > 0; }

 private:
  intptr_t position_;

  void Reinitialize() { position_ = 0; }

  void BindTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};

class Assembler : public ValueObject {
 public:
  explicit Assembler(bool use_far_branches = false) : buffer_(), comments_() {}

  ~Assembler() {}

  void Bind(Label* label);
  void Jump(Label* label);

  // Misc. functionality
  intptr_t CodeSize() const { return buffer_.Size(); }
  intptr_t prologue_offset() const { return 0; }
  bool has_single_entry_point() const { return true; }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.
  intptr_t CountPointerOffsets() const { return 0; }

  const ZoneGrowableArray<intptr_t>& GetPointerOffsets() const {
    ASSERT(buffer_.pointer_offsets().length() == 0);  // No pointers in code.
    return buffer_.pointer_offsets();
  }

  ObjectPoolWrapper& object_pool_wrapper() { return object_pool_wrapper_; }

  RawObjectPool* MakeObjectPool() {
    return object_pool_wrapper_.MakeObjectPool();
  }

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Debugging and bringup support.
  void Stop(const char* message);
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, intptr_t length);

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  static bool EmittingComments();

  const Code::Comments& GetCodeComments() const;

  static const char* RegisterName(Register reg);

  static const char* FpuRegisterName(FpuRegister reg) { return "?"; }

  static uword GetBreakInstructionFiller() { return Bytecode::kTrap; }

  static bool IsSafe(const Object& value) { return true; }
  static bool IsSafeSmi(const Object& value) { return false; }

// Bytecodes.

#define DECLARE_EMIT(Name, Signature, Fmt0, Fmt1, Fmt2)                        \
  void Name(PARAMS_##Signature);

#define PARAMS_0
#define PARAMS_A_D uintptr_t ra, uintptr_t rd
#define PARAMS_D uintptr_t rd
#define PARAMS_A_B_C uintptr_t ra, uintptr_t rb, uintptr_t rc
#define PARAMS_A uintptr_t ra
#define PARAMS_X intptr_t x
#define PARAMS_T intptr_t x
#define PARAMS_A_X uintptr_t ra, intptr_t x

  BYTECODES_LIST(DECLARE_EMIT)

#undef PARAMS_0
#undef PARAMS_A_D
#undef PARAMS_D
#undef PARAMS_A_B_C
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
  AssemblerBuffer buffer_;  // Contains position independent code.
  ObjectPoolWrapper object_pool_wrapper_;

  class CodeComment : public ZoneAllocated {
   public:
    CodeComment(intptr_t pc_offset, const String& comment)
        : pc_offset_(pc_offset), comment_(comment) {}

    intptr_t pc_offset() const { return pc_offset_; }
    const String& comment() const { return comment_; }

   private:
    intptr_t pc_offset_;
    const String& comment_;

    DISALLOW_COPY_AND_ASSIGN(CodeComment);
  };

  GrowableArray<CodeComment*> comments_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // RUNTIME_VM_ASSEMBLER_DBC_H_
