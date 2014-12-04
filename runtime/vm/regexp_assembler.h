// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_REGEXP_ASSEMBLER_H_
#define VM_REGEXP_ASSEMBLER_H_

#include "vm/assembler.h"
#include "vm/intermediate_language.h"
#include "vm/object.h"

namespace dart {

// Utility function for the DotPrinter
void PrintUtf16(uint16_t c);


/// Convenience wrapper around a BlockEntryInstr pointer.
class BlockLabel : public ValueObject {
 public:
  BlockLabel()
    : block_(new JoinEntryInstr(-1, -1)),
      is_bound_(false),
      is_linked_(false) { }

  BlockLabel(const BlockLabel& that)
    : ValueObject(),
      block_(that.block_),
      is_bound_(that.is_bound_),
      is_linked_(that.is_linked_) { }

  BlockLabel& operator=(const BlockLabel& that) {
    block_ = that.block_;
    is_bound_ = that.is_bound_;
    is_linked_ = that.is_linked_;
    return *this;
  }

  JoinEntryInstr* block() const { return block_; }

  bool IsBound() const { return is_bound_; }
  void SetBound(intptr_t block_id) {
    ASSERT(!is_bound_);
    block_->set_block_id(block_id);
    is_bound_ = true;
  }

  bool IsLinked() const { return !is_bound_ && is_linked_; }
  void SetLinked() {
    is_linked_ = true;
  }

  intptr_t Position() const {
    ASSERT(IsBound());
    return block_->block_id();
  }

 private:
  JoinEntryInstr* block_;

  bool is_bound_;
  bool is_linked_;
};


class RegExpMacroAssembler : public ZoneAllocated {
 public:
  // The implementation must be able to handle at least:
  static const intptr_t kMaxRegister = (1 << 16) - 1;
  static const intptr_t kMaxCPOffset = (1 << 15) - 1;
  static const intptr_t kMinCPOffset = -(1 << 15);

  static const intptr_t kTableSizeBits = 7;
  static const intptr_t kTableSize = 1 << kTableSizeBits;
  static const intptr_t kTableMask = kTableSize - 1;

  enum {
    kParamStringIndex = 0,
    kParamStartOffsetIndex,
    kParamCount
  };

  enum IrregexpImplementation {
    kIRImplementation
  };

  explicit RegExpMacroAssembler(Isolate* isolate);
  virtual ~RegExpMacroAssembler();
  // The maximal number of pushes between stack checks. Users must supply
  // kCheckStackLimit flag to push operations (instead of kNoStackLimitCheck)
  // at least once for every stack_limit() pushes that are executed.
  virtual intptr_t stack_limit_slack() = 0;
  virtual bool CanReadUnaligned() = 0;
  virtual void AdvanceCurrentPosition(intptr_t by) = 0;  // Signed cp change.
  virtual void AdvanceRegister(intptr_t reg, intptr_t by) = 0;  // r[reg] += by.
  // Continues execution from the position pushed on the top of the backtrack
  // stack by an earlier PushBacktrack(BlockLabel*).
  virtual void Backtrack() = 0;
  virtual void BindBlock(BlockLabel* label) = 0;
  virtual void CheckAtStart(BlockLabel* on_at_start) = 0;
  // Dispatch after looking the current character up in a 2-bits-per-entry
  // map.  The destinations vector has up to 4 labels.
  virtual void CheckCharacter(unsigned c, BlockLabel* on_equal) = 0;
  // Bitwise and the current character with the given constant and then
  // check for a match with c.
  virtual void CheckCharacterAfterAnd(unsigned c,
                                      unsigned and_with,
                                      BlockLabel* on_equal) = 0;
  virtual void CheckCharacterGT(uint16_t limit, BlockLabel* on_greater) = 0;
  virtual void CheckCharacterLT(uint16_t limit, BlockLabel* on_less) = 0;
  virtual void CheckGreedyLoop(BlockLabel* on_tos_equals_current_position) = 0;
  virtual void CheckNotAtStart(BlockLabel* on_not_at_start) = 0;
  virtual void CheckNotBackReference(
      intptr_t start_reg, BlockLabel* on_no_match) = 0;
  virtual void CheckNotBackReferenceIgnoreCase(intptr_t start_reg,
                                               BlockLabel* on_no_match) = 0;
  // Check the current character for a match with a literal character.  If we
  // fail to match then goto the on_failure label.  End of input always
  // matches.  If the label is NULL then we should pop a backtrack address off
  // the stack and go to that.
  virtual void CheckNotCharacter(unsigned c, BlockLabel* on_not_equal) = 0;
  virtual void CheckNotCharacterAfterAnd(unsigned c,
                                         unsigned and_with,
                                         BlockLabel* on_not_equal) = 0;
  // Subtract a constant from the current character, then and with the given
  // constant and then check for a match with c.
  virtual void CheckNotCharacterAfterMinusAnd(uint16_t c,
                                              uint16_t minus,
                                              uint16_t and_with,
                                              BlockLabel* on_not_equal) = 0;
  virtual void CheckCharacterInRange(uint16_t from,
                                     uint16_t to,  // Both inclusive.
                                     BlockLabel* on_in_range) = 0;
  virtual void CheckCharacterNotInRange(uint16_t from,
                                        uint16_t to,  // Both inclusive.
                                        BlockLabel* on_not_in_range) = 0;

  // The current character (modulus the kTableSize) is looked up in the byte
  // array, and if the found byte is non-zero, we jump to the on_bit_set label.
  virtual void CheckBitInTable(const TypedData& table,
                               BlockLabel* on_bit_set) = 0;

  // Checks whether the given offset from the current position is before
  // the end of the string.  May overwrite the current character.
  virtual void CheckPosition(intptr_t cp_offset, BlockLabel* on_outside_input) {
    LoadCurrentCharacter(cp_offset, on_outside_input, true);
  }
  // Check whether a standard/default character class matches the current
  // character. Returns false if the type of special character class does
  // not have custom support.
  // May clobber the current loaded character.
  virtual bool CheckSpecialCharacterClass(uint16_t type,
                                          BlockLabel* on_no_match) {
    return false;
  }
  virtual void Fail() = 0;
  // Check whether a register is >= a given constant and go to a label if it
  // is.  Backtracks instead if the label is NULL.
  virtual void IfRegisterGE(
      intptr_t reg, intptr_t comparand, BlockLabel* if_ge) = 0;
  // Check whether a register is < a given constant and go to a label if it is.
  // Backtracks instead if the label is NULL.
  virtual void IfRegisterLT(
      intptr_t reg, intptr_t comparand, BlockLabel* if_lt) = 0;
  // Check whether a register is == to the current position and go to a
  // label if it is.
  virtual void IfRegisterEqPos(intptr_t reg, BlockLabel* if_eq) = 0;
  virtual IrregexpImplementation Implementation() = 0;
  // The assembler is closed, iff there is no current instruction assigned.
  virtual bool IsClosed() const = 0;
  // Jump to the target label without setting it as the current instruction.
  virtual void GoTo(BlockLabel* to) = 0;
  virtual void LoadCurrentCharacter(intptr_t cp_offset,
                                    BlockLabel* on_end_of_input,
                                    bool check_bounds = true,
                                    intptr_t characters = 1) = 0;
  virtual void PopCurrentPosition() = 0;
  virtual void PopRegister(intptr_t register_index) = 0;
  // Prints string within the generated code. Used for debugging.
  virtual void Print(const char* str) = 0;
  // Prints all emitted blocks.
  virtual void PrintBlocks() = 0;
  // Pushes the label on the backtrack stack, so that a following Backtrack
  // will go to this label. Always checks the backtrack stack limit.
  virtual void PushBacktrack(BlockLabel* label) = 0;
  virtual void PushCurrentPosition() = 0;
  virtual void PushRegister(intptr_t register_index) = 0;
  virtual void ReadCurrentPositionFromRegister(intptr_t reg) = 0;
  virtual void ReadStackPointerFromRegister(intptr_t reg) = 0;
  virtual void SetCurrentPositionFromEnd(intptr_t by) = 0;
  virtual void SetRegister(intptr_t register_index, intptr_t to) = 0;
  // Return whether the matching (with a global regexp) will be restarted.
  virtual bool Succeed() = 0;
  virtual void WriteCurrentPositionToRegister(
      intptr_t reg, intptr_t cp_offset) = 0;
  virtual void ClearRegisters(intptr_t reg_from, intptr_t reg_to) = 0;
  virtual void WriteStackPointerToRegister(intptr_t reg) = 0;

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

  Isolate* isolate() const { return isolate_; }

 private:
  bool slow_safe_compiler_;
  bool global_mode_;
  Isolate* isolate_;
};


class IRRegExpMacroAssembler : public RegExpMacroAssembler {
 public:
  // Type of input string to generate code for.
  enum Mode { ASCII = 1, UC16 = 2 };

  // Result of calling generated native RegExp code.
  // RETRY: Something significant changed during execution, and the matching
  //        should be retried from scratch.
  // EXCEPTION: Something failed during execution. If no exception has been
  //        thrown, it's an internal out-of-memory, and the caller should
  //        throw the exception.
  // FAILURE: Matching failed.
  // SUCCESS: Matching succeeded, and the output array has been filled with
  //        capture positions.
  enum Result { RETRY = -2, EXCEPTION = -1, FAILURE = 0, SUCCESS = 1 };

  IRRegExpMacroAssembler(intptr_t specialization_cid,
                         intptr_t capture_count,
                         const ParsedFunction* parsed_function,
                         const ZoneGrowableArray<const ICData*>& ic_data_array,
                         Isolate* isolate);
  virtual ~IRRegExpMacroAssembler();

  virtual bool CanReadUnaligned();

  // Compares two-byte strings case insensitively.
  // Called from generated RegExp code.
  static RawBool* CaseInsensitiveCompareUC16(
      RawString* str_raw,
      RawSmi* lhs_index_raw,
      RawSmi* rhs_index_raw,
      RawSmi* length_raw);

  static RawArray* Execute(const Function& function,
                           const String& input,
                           const Smi& start_offset,
                           Isolate* isolate);

  virtual bool IsClosed() const { return (current_instruction_ == NULL); }

  virtual intptr_t stack_limit_slack();
  virtual void AdvanceCurrentPosition(intptr_t by);
  virtual void AdvanceRegister(intptr_t reg, intptr_t by);
  virtual void Backtrack();
  virtual void BindBlock(BlockLabel* label);
  virtual void CheckAtStart(BlockLabel* on_at_start);
  virtual void CheckCharacter(uint32_t c, BlockLabel* on_equal);
  virtual void CheckCharacterAfterAnd(uint32_t c,
                                      uint32_t mask,
                                      BlockLabel* on_equal);
  virtual void CheckCharacterGT(uint16_t limit, BlockLabel* on_greater);
  virtual void CheckCharacterLT(uint16_t limit, BlockLabel* on_less);
  // A "greedy loop" is a loop that is both greedy and with a simple
  // body. It has a particularly simple implementation.
  virtual void CheckGreedyLoop(BlockLabel* on_tos_equals_current_position);
  virtual void CheckNotAtStart(BlockLabel* on_not_at_start);
  virtual void CheckNotBackReference(intptr_t start_reg,
                                     BlockLabel* on_no_match);
  virtual void CheckNotBackReferenceIgnoreCase(intptr_t start_reg,
                                               BlockLabel* on_no_match);
  virtual void CheckNotCharacter(uint32_t c, BlockLabel* on_not_equal);
  virtual void CheckNotCharacterAfterAnd(uint32_t c,
                                         uint32_t mask,
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

  // Checks whether the given offset from the current position is before
  // the end of the string.
  virtual void CheckPosition(intptr_t cp_offset, BlockLabel* on_outside_input);
  virtual bool CheckSpecialCharacterClass(
      uint16_t type, BlockLabel* on_no_match);
  virtual void Fail();
  virtual void IfRegisterGE(intptr_t reg,
                            intptr_t comparand, BlockLabel* if_ge);
  virtual void IfRegisterLT(intptr_t reg,
                            intptr_t comparand, BlockLabel* if_lt);
  virtual void IfRegisterEqPos(intptr_t reg, BlockLabel* if_eq);
  virtual IrregexpImplementation Implementation();
  virtual void GoTo(BlockLabel* to);
  virtual void LoadCurrentCharacter(intptr_t cp_offset,
                                    BlockLabel* on_end_of_input,
                                    bool check_bounds = true,
                                    intptr_t characters = 1);
  virtual void PopCurrentPosition();
  virtual void PopRegister(intptr_t register_index);
  virtual void Print(const char* str);
  virtual void PushBacktrack(BlockLabel* label);
  virtual void PushCurrentPosition();
  virtual void PushRegister(intptr_t register_index);
  virtual void ReadCurrentPositionFromRegister(intptr_t reg);
  virtual void ReadStackPointerFromRegister(intptr_t reg);
  virtual void SetCurrentPositionFromEnd(intptr_t by);
  virtual void SetRegister(intptr_t register_index, intptr_t to);
  virtual bool Succeed();
  virtual void WriteCurrentPositionToRegister(intptr_t reg, intptr_t cp_offset);
  virtual void ClearRegisters(intptr_t reg_from, intptr_t reg_to);
  virtual void WriteStackPointerToRegister(intptr_t reg);

  virtual void PrintBlocks();

  IndirectGotoInstr* backtrack_goto() const { return backtrack_goto_; }
  GraphEntryInstr* graph_entry() const { return entry_block_; }

  intptr_t num_stack_locals() const { return local_id_.Count(); }
  intptr_t num_blocks() const { return block_id_.Count(); }

  // Generate a dispatch block implementing backtracking. Must be done after
  // graph construction.
  void GenerateBacktrackBlock();

 private:
  // Generate the contents of preset blocks. The entry block is the entry point
  // of the generated code.
  void GenerateEntryBlock();
  // Copies capture indices into the result area and returns true.
  void GenerateSuccessBlock();
  // Returns false.
  void GenerateExitBlock();

  enum ComparisonKind {
    kEQ,
    kNE,
    kLT,
    kGT,
    kLTE,
    kGTE,
  };

  struct InstanceCallDescriptor {
    // Standard (i.e. most non-Smi) functions.
    explicit InstanceCallDescriptor(const String& name)
      : name(name),
        token_kind(Token::kILLEGAL),
        checked_argument_count(1) { }

    InstanceCallDescriptor(const String& name,
                           Token::Kind token_kind,
                           intptr_t checked_argument_count)
      : name(name),
        token_kind(token_kind),
        checked_argument_count(checked_argument_count) { }

    // Special cases for Smi and indexing functions.
    static InstanceCallDescriptor FromToken(Token::Kind token_kind) {
      switch (token_kind) {
        case Token::kEQ: return InstanceCallDescriptor(
                  Symbols::EqualOperator(), token_kind, 2);
        case Token::kADD: return InstanceCallDescriptor(
                Symbols::Plus(), token_kind, 2);
        case Token::kSUB: return InstanceCallDescriptor(
                Symbols::Minus(), token_kind, 2);
        case Token::kBIT_OR: return InstanceCallDescriptor(
                Symbols::BitOr(), token_kind, 2);
        case Token::kBIT_AND: return InstanceCallDescriptor(
                Symbols::BitAnd(), token_kind, 2);
        case Token::kLT: return InstanceCallDescriptor(
                Symbols::LAngleBracket(), token_kind, 2);
        case Token::kLTE: return InstanceCallDescriptor(
                Symbols::LessEqualOperator(), token_kind, 2);
        case Token::kGT: return InstanceCallDescriptor(
                Symbols::RAngleBracket(), token_kind, 2);
        case Token::kGTE: return InstanceCallDescriptor(
                Symbols::GreaterEqualOperator(), token_kind, 2);
        case Token::kNEGATE: return InstanceCallDescriptor(
                Symbols::UnaryMinus(), token_kind, 1);
        case Token::kINDEX: return InstanceCallDescriptor(
                Symbols::IndexToken(), token_kind, 2);
        case Token::kASSIGN_INDEX: return InstanceCallDescriptor(
                Symbols::AssignIndexToken(), token_kind, 3);
        default:
          UNREACHABLE();
      }
      UNREACHABLE();
      return InstanceCallDescriptor(Symbols::Empty());
    }

    const String& name;
    Token::Kind token_kind;
    intptr_t checked_argument_count;
  };

  LocalVariable* Local(const String& name);
  LocalVariable* Parameter(const String& name, intptr_t index) const;

  ConstantInstr* Int64Constant(int64_t value) const;
  ConstantInstr* Uint64Constant(uint64_t value) const;
  ConstantInstr* BoolConstant(bool value) const;
  ConstantInstr* StringConstant(const char* value) const;

  // The word character map static member of the RegExp class.
  // Byte map of one byte characters with a 0xff if the character is a word
  // character (digit, letter or underscore) and 0x00 otherwise.
  // Used by generated RegExp code.
  ConstantInstr* WordCharacterMapConstant() const;

  ComparisonInstr* Comparison(ComparisonKind kind,
                              Definition* lhs, Definition* rhs);

  InstanceCallInstr* InstanceCall(const InstanceCallDescriptor& desc,
                                  PushArgumentInstr* arg1) const;
  InstanceCallInstr* InstanceCall(const InstanceCallDescriptor& desc,
                                  PushArgumentInstr* arg1,
                                  PushArgumentInstr* arg2) const;
  InstanceCallInstr* InstanceCall(const InstanceCallDescriptor& desc,
                                  PushArgumentInstr* arg1,
                                  PushArgumentInstr* arg2,
                                  PushArgumentInstr* arg3) const;
  InstanceCallInstr* InstanceCall(
      const InstanceCallDescriptor& desc,
      ZoneGrowableArray<PushArgumentInstr*>* arguments) const;

  StaticCallInstr* StaticCall(const Function& function) const;
  StaticCallInstr* StaticCall(const Function& function,
                              PushArgumentInstr* arg1) const;
  StaticCallInstr* StaticCall(const Function& function,
                              PushArgumentInstr* arg1,
                              PushArgumentInstr* arg2) const;
  StaticCallInstr* StaticCall(
      const Function& function,
      ZoneGrowableArray<PushArgumentInstr*>* arguments) const;

  // Creates a new block consisting simply of a goto to dst.
  TargetEntryInstr* TargetWithJoinGoto(JoinEntryInstr* dst);
  IndirectEntryInstr* IndirectWithJoinGoto(JoinEntryInstr* dst);

  // Adds, respectively subtracts lhs and rhs and returns the result.
  Definition* Add(PushArgumentInstr* lhs, PushArgumentInstr* rhs);
  Definition* Sub(PushArgumentInstr* lhs, PushArgumentInstr* rhs);

  LoadLocalInstr* LoadLocal(LocalVariable* local) const;
  void StoreLocal(LocalVariable* local, Value* value);

  PushArgumentInstr* PushArgument(Value* value);
  PushArgumentInstr* PushLocal(LocalVariable* local);

  // Load a number of characters at the given offset from the
  // current position, into the current-character register.
  void LoadCurrentCharacterUnchecked(intptr_t cp_offset,
                                     intptr_t character_count);

  // Returns the character within the passed string at the specified index.
  Value* CharacterAt(LocalVariable* index);

  // Load a number of characters starting from index in the pattern string.
  Value* LoadCodeUnitsAt(LocalVariable* index, intptr_t character_count);

  // Check whether preemption has been requested.
  void CheckPreemption();

  // Byte size of chars in the string to match (decided by the Mode argument)
  inline intptr_t char_size() { return static_cast<int>(mode_); }

  // Equivalent to a conditional branch to the label, unless the label
  // is NULL, in which case it is a conditional Backtrack.
  void BranchOrBacktrack(ComparisonInstr* comparison,
                         BlockLabel* true_successor);

  // Set up all local variables and parameters.
  void InitializeLocals();

  // Allocates a new local, and returns the appropriate id for placing it
  // on the stack.
  intptr_t GetNextLocalIndex();

  // We never have any copied parameters.
  intptr_t num_copied_params() const {
    return 0;
  }

  // Return the position register at the specified index, creating it if
  // necessary. Note that the number of such registers can exceed the amount
  // required by the number of output captures.
  LocalVariable* position_register(intptr_t index);

  void set_current_instruction(Instruction* instruction);

  // The following functions are responsible for appending instructions
  // to the current instruction in various ways. The most simple one
  // is AppendInstruction, which simply appends an instruction and performs
  // bookkeeping.
  void AppendInstruction(Instruction* instruction);
  // Similar to AppendInstruction, but closes the current block by
  // setting current_instruction_ to NULL.
  void CloseBlockWith(Instruction* instruction);
  // Appends definition and allocates a temp index for the result.
  Value* Bind(Definition* definition);
  // Loads and binds a local variable.
  Value* BindLoadLocal(const LocalVariable& local);

  // Appends the definition.
  void Do(Definition* definition);
  // Closes the current block with a jump to the specified block.
  void GoTo(JoinEntryInstr* to);

  // Accessors for our local stack_.
  void PushStack(Definition* definition);
  Value* PopStack();

  // Prints the specified argument. Used for debugging.
  void Print(PushArgumentInstr* argument);

  // A utility class tracking ids of various objects such as blocks, temps, etc.
  class IdAllocator : public ValueObject {
   public:
    IdAllocator() : next_id(0) { }

    intptr_t Count() const { return next_id; }
    intptr_t Alloc(intptr_t count = 1) {
      ASSERT(count >= 0);
      intptr_t current_id = next_id;
      next_id += count;
      return current_id;
    }
    void Dealloc(intptr_t count = 1) {
      ASSERT(count <= next_id);
      next_id -= count;
    }

   private:
    intptr_t next_id;
  };

  // Which mode to generate code for (ASCII or UC16).
  Mode mode_;

  // Which specific string class to generate code for.
  intptr_t specialization_cid_;

  // Block entries used internally.
  GraphEntryInstr* entry_block_;
  JoinEntryInstr* start_block_;
  JoinEntryInstr* success_block_;
  JoinEntryInstr* exit_block_;

  // Shared backtracking block.
  JoinEntryInstr* backtrack_block_;
  // Single indirect goto instruction which performs all backtracking.
  IndirectGotoInstr* backtrack_goto_;

  const ParsedFunction* parsed_function_;
  const ZoneGrowableArray<const ICData*>& ic_data_array_;

  // All created blocks are contained within this set. Used for printing
  // the generated code.
  GrowableArray<BlockEntryInstr*> blocks_;

  // The current instruction to link to when new code is emitted.
  Instruction* current_instruction_;

  // A list, acting as the runtime stack for both backtrack locations and
  // stored positions within the string.
  LocalVariable* stack_;

  // Stores the current character within the string.
  LocalVariable* current_character_;

  // Stores the current location within the string as a negative offset
  // from the end of the string.
  LocalVariable* current_position_;

  // The string being processed, passed as a function parameter.
  LocalVariable* string_param_;

  // Stores the length of string_param_.
  LocalVariable* string_param_length_;

  // The start index within the string, passed as a function parameter.
  LocalVariable* start_index_param_;

  // An assortment of utility variables.
  LocalVariable* capture_length_;
  LocalVariable* match_start_index_;
  LocalVariable* capture_start_index_;
  LocalVariable* match_end_index_;
  LocalVariable* char_in_capture_;
  LocalVariable* char_in_match_;
  LocalVariable* index_temp_;

  LocalVariable* result_;

  // Stored positions containing group bounds. Generated as needed.
  const intptr_t position_registers_count_;
  GrowableArray<LocalVariable*> position_registers_;

  // The actual array object used as the stack.
  GrowableObjectArray& stack_array_;

  IdAllocator block_id_;
  IdAllocator temp_id_;
  IdAllocator arg_id_;
  IdAllocator local_id_;
  IdAllocator indirect_id_;
};


}  // namespace dart

#endif  // VM_REGEXP_ASSEMBLER_H_
