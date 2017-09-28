// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REGEXP_ASSEMBLER_IR_H_
#define RUNTIME_VM_REGEXP_ASSEMBLER_IR_H_

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/il.h"
#include "vm/object.h"
#include "vm/regexp_assembler.h"

namespace dart {

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
                         intptr_t osr_id,
                         Zone* zone);
  virtual ~IRRegExpMacroAssembler();

  virtual bool CanReadUnaligned();

  static RawArray* Execute(const RegExp& regexp,
                           const String& input,
                           const Smi& start_offset,
                           bool sticky,
                           Zone* zone);

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
  virtual bool CheckSpecialCharacterClass(uint16_t type,
                                          BlockLabel* on_no_match);
  virtual void Fail();
  virtual void IfRegisterGE(intptr_t reg,
                            intptr_t comparand,
                            BlockLabel* if_ge);
  virtual void IfRegisterLT(intptr_t reg,
                            intptr_t comparand,
                            BlockLabel* if_lt);
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

  // Allocate the actual registers array once its size is known. Must be done
  // after graph construction.
  void FinalizeRegistersArray();

 private:
  intptr_t GetNextDeoptId() const { return thread_->GetNextDeoptId(); }

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
        : name(name), token_kind(Token::kILLEGAL), checked_argument_count(1) {}

    InstanceCallDescriptor(const String& name,
                           Token::Kind token_kind,
                           intptr_t checked_argument_count)
        : name(name),
          token_kind(token_kind),
          checked_argument_count(checked_argument_count) {}

    // Special cases for Smi and indexing functions.
    static InstanceCallDescriptor FromToken(Token::Kind token_kind) {
      switch (token_kind) {
        case Token::kEQ:
          return InstanceCallDescriptor(Symbols::EqualOperator(), token_kind,
                                        2);
        case Token::kADD:
          return InstanceCallDescriptor(Symbols::Plus(), token_kind, 2);
        case Token::kSUB:
          return InstanceCallDescriptor(Symbols::Minus(), token_kind, 2);
        case Token::kBIT_OR:
          return InstanceCallDescriptor(Symbols::BitOr(), token_kind, 2);
        case Token::kBIT_AND:
          return InstanceCallDescriptor(Symbols::BitAnd(), token_kind, 2);
        case Token::kLT:
          return InstanceCallDescriptor(Symbols::LAngleBracket(), token_kind,
                                        2);
        case Token::kLTE:
          return InstanceCallDescriptor(Symbols::LessEqualOperator(),
                                        token_kind, 2);
        case Token::kGT:
          return InstanceCallDescriptor(Symbols::RAngleBracket(), token_kind,
                                        2);
        case Token::kGTE:
          return InstanceCallDescriptor(Symbols::GreaterEqualOperator(),
                                        token_kind, 2);
        case Token::kNEGATE:
          return InstanceCallDescriptor(Symbols::UnaryMinus(), token_kind, 1);
        case Token::kINDEX:
          return InstanceCallDescriptor(Symbols::IndexToken(), token_kind, 2);
        case Token::kASSIGN_INDEX:
          return InstanceCallDescriptor(Symbols::AssignIndexToken(), token_kind,
                                        2);
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
                              PushArgumentInstr* lhs,
                              PushArgumentInstr* rhs);
  ComparisonInstr* Comparison(ComparisonKind kind,
                              Definition* lhs,
                              Definition* rhs);

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

  StaticCallInstr* StaticCall(const Function& function,
                              ICData::RebindRule rebind_rule) const;
  StaticCallInstr* StaticCall(const Function& function,
                              PushArgumentInstr* arg1,
                              ICData::RebindRule rebind_rule) const;
  StaticCallInstr* StaticCall(const Function& function,
                              PushArgumentInstr* arg1,
                              PushArgumentInstr* arg2,
                              ICData::RebindRule rebind_rule) const;
  StaticCallInstr* StaticCall(const Function& function,
                              ZoneGrowableArray<PushArgumentInstr*>* arguments,
                              ICData::RebindRule rebind_rule) const;

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

  PushArgumentInstr* PushRegisterIndex(intptr_t reg);
  Value* LoadRegister(intptr_t reg);
  void StoreRegister(intptr_t reg, intptr_t value);
  void StoreRegister(PushArgumentInstr* registers,
                     PushArgumentInstr* index,
                     PushArgumentInstr* value);

  // Load a number of characters at the given offset from the
  // current position, into the current-character register.
  void LoadCurrentCharacterUnchecked(intptr_t cp_offset,
                                     intptr_t character_count);

  // Returns the character within the passed string at the specified index.
  Value* CharacterAt(LocalVariable* index);

  // Load a number of characters starting from index in the pattern string.
  Value* LoadCodeUnitsAt(LocalVariable* index, intptr_t character_count);

  // Check whether preemption has been requested. Also serves as an OSR entry.
  void CheckPreemption(bool is_backtrack);

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
  intptr_t num_copied_params() const { return 0; }

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
  Definition* PopStack();
  Definition* PeekStack();
  void CheckStackLimit();
  void GrowStack();

  // Prints the specified argument. Used for debugging.
  void Print(PushArgumentInstr* argument);

  // A utility class tracking ids of various objects such as blocks, temps, etc.
  class IdAllocator : public ValueObject {
   public:
    explicit IdAllocator(intptr_t first_id = 0) : next_id(first_id) {}

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

  Thread* thread_;

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
  LocalVariable* stack_pointer_;

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
  LocalVariable* registers_;
  intptr_t registers_count_;
  const intptr_t saved_registers_count_;

  // The actual array objects used for the stack and registers.
  Array& stack_array_cell_;
  TypedData& registers_array_;

  IdAllocator block_id_;
  IdAllocator temp_id_;
  IdAllocator arg_id_;
  IdAllocator local_id_;
  IdAllocator indirect_id_;
};

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_ASSEMBLER_IR_H_
