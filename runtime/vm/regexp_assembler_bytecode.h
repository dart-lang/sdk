// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REGEXP_ASSEMBLER_BYTECODE_H_
#define RUNTIME_VM_REGEXP_ASSEMBLER_BYTECODE_H_

#include "vm/object.h"
#include "vm/regexp_assembler.h"

namespace dart {

class BytecodeRegExpMacroAssembler : public RegExpMacroAssembler {
 public:
  // Create an assembler. Instructions and relocation information are emitted
  // into a buffer, with the instructions starting from the beginning and the
  // relocation information starting from the end of the buffer. See CodeDesc
  // for a detailed comment on the layout (globals.h).
  //
  // If the provided buffer is NULL, the assembler allocates and grows its own
  // buffer, and buffer_size determines the initial buffer size. The buffer is
  // owned by the assembler and deallocated upon destruction of the assembler.
  //
  // If the provided buffer is not NULL, the assembler uses the provided buffer
  // for code generation and assumes its size to be buffer_size. If the buffer
  // is too small, a fatal error occurs. No deallocation of the buffer is done
  // upon destruction of the assembler.
  BytecodeRegExpMacroAssembler(ZoneGrowableArray<uint8_t>* buffer, Zone* zone);
  virtual ~BytecodeRegExpMacroAssembler();

  // The byte-code interpreter checks on each push anyway.
  virtual intptr_t stack_limit_slack() { return 1; }
  virtual bool CanReadUnaligned() { return false; }
  virtual void BindBlock(BlockLabel* label);
  virtual void AdvanceCurrentPosition(intptr_t by);  // Signed cp change.
  virtual void PopCurrentPosition();
  virtual void PushCurrentPosition();
  virtual void Backtrack();
  virtual void GoTo(BlockLabel* label);
  virtual void PushBacktrack(BlockLabel* label);
  virtual bool Succeed();
  virtual void Fail();
  virtual void PopRegister(intptr_t register_index);
  virtual void PushRegister(intptr_t register_index);
  virtual void AdvanceRegister(intptr_t reg, intptr_t by);  // r[reg] += by.
  virtual void SetCurrentPositionFromEnd(intptr_t by);
  virtual void SetRegister(intptr_t register_index, intptr_t to);
  virtual void WriteCurrentPositionToRegister(intptr_t reg, intptr_t cp_offset);
  virtual void ClearRegisters(intptr_t reg_from, intptr_t reg_to);
  virtual void ReadCurrentPositionFromRegister(intptr_t reg);
  virtual void WriteStackPointerToRegister(intptr_t reg);
  virtual void ReadStackPointerFromRegister(intptr_t reg);
  virtual void LoadCurrentCharacter(intptr_t cp_offset,
                                    BlockLabel* on_end_of_input,
                                    bool check_bounds = true,
                                    intptr_t characters = 1);
  virtual void CheckCharacter(unsigned c, BlockLabel* on_equal);
  virtual void CheckCharacterAfterAnd(unsigned c,
                                      unsigned mask,
                                      BlockLabel* on_equal);
  virtual void CheckCharacterGT(uint16_t limit, BlockLabel* on_greater);
  virtual void CheckCharacterLT(uint16_t limit, BlockLabel* on_less);
  virtual void CheckGreedyLoop(BlockLabel* on_tos_equals_current_position);
  virtual void CheckAtStart(BlockLabel* on_at_start);
  virtual void CheckNotAtStart(BlockLabel* on_not_at_start);
  virtual void CheckNotCharacter(unsigned c, BlockLabel* on_not_equal);
  virtual void CheckNotCharacterAfterAnd(unsigned c,
                                         unsigned mask,
                                         BlockLabel* on_not_equal);
  virtual void CheckNotCharacterAfterMinusAnd(uint16_t c,
                                              uint16_t minus,
                                              uint16_t mask,
                                              BlockLabel* on_not_equal);
  virtual void CheckCharacterInRange(uint16_t from,
                                     uint16_t to,
                                     BlockLabel* on_in_range);
  virtual void CheckCharacterNotInRange(uint16_t from,
                                        uint16_t to,
                                        BlockLabel* on_not_in_range);
  virtual void CheckBitInTable(const TypedData& table, BlockLabel* on_bit_set);
  virtual void CheckNotBackReference(intptr_t start_reg,
                                     BlockLabel* on_no_match);
  virtual void CheckNotBackReferenceIgnoreCase(intptr_t start_reg,
                                               BlockLabel* on_no_match);
  virtual void IfRegisterLT(intptr_t register_index,
                            intptr_t comparand,
                            BlockLabel* if_lt);
  virtual void IfRegisterGE(intptr_t register_index,
                            intptr_t comparand,
                            BlockLabel* if_ge);
  virtual void IfRegisterEqPos(intptr_t register_index, BlockLabel* if_eq);

  virtual IrregexpImplementation Implementation();
  // virtual Handle<HeapObject> GetCode(Handle<String> source);
  RawTypedData* GetBytecode();

  // New
  virtual bool IsClosed() const {
    // Added by Dart for the IR version. Bytecode version should never need an
    // extra goto.
    return true;
  }
  virtual void Print(const char* str) { UNIMPLEMENTED(); }
  virtual void PrintBlocks() { UNIMPLEMENTED(); }
  /////

  static RawInstance* Interpret(const RegExp& regexp,
                                const String& str,
                                const Smi& start_index,
                                bool is_sticky,
                                Zone* zone);

 private:
  void Expand();
  // Code and bitmap emission.
  inline void EmitOrLink(BlockLabel* label);
  inline void Emit32(uint32_t x);
  inline void Emit16(uint32_t x);
  inline void Emit8(uint32_t x);
  inline void Emit(uint32_t bc, uint32_t arg);
  // Bytecode buffer.
  intptr_t length();

  // The buffer into which code and relocation info are generated.
  ZoneGrowableArray<uint8_t>* buffer_;

  // The program counter.
  intptr_t pc_;

  BlockLabel backtrack_;

  intptr_t advance_current_start_;
  intptr_t advance_current_offset_;
  intptr_t advance_current_end_;

  static const int kInvalidPC = -1;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BytecodeRegExpMacroAssembler);
};

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_ASSEMBLER_BYTECODE_H_
