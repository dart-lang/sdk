// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_REGEXP_ASSEMBLER_H_
#define VM_REGEXP_ASSEMBLER_H_

// SNIP

namespace dart {

// SNIP

class RegExpMacroAssembler {
 public:
  // The implementation must be able to handle at least:
  static const int kMaxRegister = (1 << 16) - 1;
  static const int kMaxCPOffset = (1 << 15) - 1;
  static const int kMinCPOffset = -(1 << 15);

  static const int kTableSizeBits = 7;
  static const int kTableSize = 1 << kTableSizeBits;
  static const int kTableMask = kTableSize - 1;

  enum IrregexpImplementation {
    kIA32Implementation,
    kARMImplementation,
    kARM64Implementation,
    kMIPSImplementation,
    kX64Implementation,
    kX87Implementation,
    kBytecodeImplementation
  };

  enum StackCheckFlag {
    kNoStackLimitCheck = false,
    kCheckStackLimit = true
  };

  explicit RegExpMacroAssembler(Zone* zone);
  virtual ~RegExpMacroAssembler();
  // The maximal number of pushes between stack checks. Users must supply
  // kCheckStackLimit flag to push operations (instead of kNoStackLimitCheck)
  // at least once for every stack_limit() pushes that are executed.
  virtual int stack_limit_slack() = 0;
  virtual bool CanReadUnaligned() = 0;
  virtual void AdvanceCurrentPosition(int by) = 0;  // Signed cp change.
  virtual void AdvanceRegister(int reg, int by) = 0;  // r[reg] += by.
  // Continues execution from the position pushed on the top of the backtrack
  // stack by an earlier PushBacktrack(Label*).
  virtual void Backtrack() = 0;
  virtual void Bind(Label* label) = 0;
  virtual void CheckAtStart(Label* on_at_start) = 0;
  // Dispatch after looking the current character up in a 2-bits-per-entry
  // map.  The destinations vector has up to 4 labels.
  virtual void CheckCharacter(unsigned c, Label* on_equal) = 0;
  // Bitwise and the current character with the given constant and then
  // check for a match with c.
  virtual void CheckCharacterAfterAnd(unsigned c,
                                      unsigned and_with,
                                      Label* on_equal) = 0;
  virtual void CheckCharacterGT(uc16 limit, Label* on_greater) = 0;
  virtual void CheckCharacterLT(uc16 limit, Label* on_less) = 0;
  virtual void CheckGreedyLoop(Label* on_tos_equals_current_position) = 0;
  virtual void CheckNotAtStart(Label* on_not_at_start) = 0;
  virtual void CheckNotBackReference(int start_reg, Label* on_no_match) = 0;
  virtual void CheckNotBackReferenceIgnoreCase(int start_reg,
                                               Label* on_no_match) = 0;
  // Check the current character for a match with a literal character.  If we
  // fail to match then goto the on_failure label.  End of input always
  // matches.  If the label is NULL then we should pop a backtrack address off
  // the stack and go to that.
  virtual void CheckNotCharacter(unsigned c, Label* on_not_equal) = 0;
  virtual void CheckNotCharacterAfterAnd(unsigned c,
                                         unsigned and_with,
                                         Label* on_not_equal) = 0;
  // Subtract a constant from the current character, then and with the given
  // constant and then check for a match with c.
  virtual void CheckNotCharacterAfterMinusAnd(uc16 c,
                                              uc16 minus,
                                              uc16 and_with,
                                              Label* on_not_equal) = 0;
  virtual void CheckCharacterInRange(uc16 from,
                                     uc16 to,  // Both inclusive.
                                     Label* on_in_range) = 0;
  virtual void CheckCharacterNotInRange(uc16 from,
                                        uc16 to,  // Both inclusive.
                                        Label* on_not_in_range) = 0;

  // The current character (modulus the kTableSize) is looked up in the byte
  // array, and if the found byte is non-zero, we jump to the on_bit_set label.
  virtual void CheckBitInTable(Handle<ByteArray> table, Label* on_bit_set) = 0;

  // Checks whether the given offset from the current position is before
  // the end of the string.  May overwrite the current character.
  virtual void CheckPosition(int cp_offset, Label* on_outside_input) {
    LoadCurrentCharacter(cp_offset, on_outside_input, true);
  }
  // Check whether a standard/default character class matches the current
  // character. Returns false if the type of special character class does
  // not have custom support.
  // May clobber the current loaded character.
  virtual bool CheckSpecialCharacterClass(uc16 type,
                                          Label* on_no_match) {
    return false;
  }
  virtual void Fail() = 0;
  virtual Handle<HeapObject> GetCode(Handle<String> source) = 0;
  virtual void GoTo(Label* label) = 0;
  // Check whether a register is >= a given constant and go to a label if it
  // is.  Backtracks instead if the label is NULL.
  virtual void IfRegisterGE(int reg, int comparand, Label* if_ge) = 0;
  // Check whether a register is < a given constant and go to a label if it is.
  // Backtracks instead if the label is NULL.
  virtual void IfRegisterLT(int reg, int comparand, Label* if_lt) = 0;
  // Check whether a register is == to the current position and go to a
  // label if it is.
  virtual void IfRegisterEqPos(int reg, Label* if_eq) = 0;
  virtual IrregexpImplementation Implementation() = 0;
  virtual void LoadCurrentCharacter(int cp_offset,
                                    Label* on_end_of_input,
                                    bool check_bounds = true,
                                    int characters = 1) = 0;
  virtual void PopCurrentPosition() = 0;
  virtual void PopRegister(int register_index) = 0;
  // Pushes the label on the backtrack stack, so that a following Backtrack
  // will go to this label. Always checks the backtrack stack limit.
  virtual void PushBacktrack(Label* label) = 0;
  virtual void PushCurrentPosition() = 0;
  virtual void PushRegister(int register_index,
                            StackCheckFlag check_stack_limit) = 0;
  virtual void ReadCurrentPositionFromRegister(int reg) = 0;
  virtual void ReadStackPointerFromRegister(int reg) = 0;
  virtual void SetCurrentPositionFromEnd(int by) = 0;
  virtual void SetRegister(int register_index, int to) = 0;
  // Return whether the matching (with a global regexp) will be restarted.
  virtual bool Succeed() = 0;
  virtual void WriteCurrentPositionToRegister(int reg, int cp_offset) = 0;
  virtual void ClearRegisters(int reg_from, int reg_to) = 0;
  virtual void WriteStackPointerToRegister(int reg) = 0;

  // Controls the generation of large inlined constants in the code.
  void set_slow_safe(bool ssc) { slow_safe_compiler_ = ssc; }
  bool slow_safe() { return slow_safe_compiler_; }

  enum GlobalMode { NOT_GLOBAL, GLOBAL, GLOBAL_NO_ZERO_LENGTH_CHECK };
  // Set whether the regular expression has the global flag.  Exiting due to
  // a failure in a global regexp may still mean success overall.
  inline void set_global_mode(GlobalMode mode) { global_mode_ = mode; }
  inline bool global() { return global_mode_ != NOT_GLOBAL; }
  inline bool global_with_zero_length_check() {
    return global_mode_ == GLOBAL;
  }

  Zone* zone() const { return zone_; }

 private:
  bool slow_safe_compiler_;
  bool global_mode_;
  Zone* zone_;
};

// SNIP

}  // namespace dart

#endif  // VM_REGEXP_ASSEMBLER_H_
