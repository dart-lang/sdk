// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/regexp.h"

#include "vm/dart_entry.h"
#include "vm/regexp_assembler.h"
#include "vm/regexp_assembler_bytecode.h"
#include "vm/regexp_assembler_ir.h"
#include "vm/regexp_ast.h"
#include "vm/unibrow-inl.h"
#include "vm/unicode.h"
#include "vm/symbols.h"
#include "vm/thread.h"

#define Z (zone())

namespace dart {

// Default to generating optimized regexp code.
static const bool kRegexpOptimization = true;

// More makes code generation slower, less makes V8 benchmark score lower.
static const intptr_t kMaxLookaheadForBoyerMoore = 8;

ContainedInLattice AddRange(ContainedInLattice containment,
                            const intptr_t* ranges,
                            intptr_t ranges_length,
                            Interval new_range) {
  ASSERT((ranges_length & 1) == 1);
  ASSERT(ranges[ranges_length - 1] == Utf16::kMaxCodeUnit + 1);
  if (containment == kLatticeUnknown) return containment;
  bool inside = false;
  intptr_t last = 0;
  for (intptr_t i = 0; i < ranges_length;
       inside = !inside, last = ranges[i], i++) {
    // Consider the range from last to ranges[i].
    // We haven't got to the new range yet.
    if (ranges[i] <= new_range.from()) continue;
    // New range is wholly inside last-ranges[i].  Note that new_range.to() is
    // inclusive, but the values in ranges are not.
    if (last <= new_range.from() && new_range.to() < ranges[i]) {
      return Combine(containment, inside ? kLatticeIn : kLatticeOut);
    }
    return kLatticeUnknown;
  }
  return containment;
}

// -------------------------------------------------------------------
// Implementation of the Irregexp regular expression engine.
//
// The Irregexp regular expression engine is intended to be a complete
// implementation of ECMAScript regular expressions.  It generates
// IR code that is subsequently compiled to native code.

//   The Irregexp regexp engine is structured in three steps.
//   1) The parser generates an abstract syntax tree.  See regexp_ast.cc.
//   2) From the AST a node network is created.  The nodes are all
//      subclasses of RegExpNode.  The nodes represent states when
//      executing a regular expression.  Several optimizations are
//      performed on the node network.
//   3) From the nodes we generate IR instructions that can actually
//      execute the regular expression (perform the search).  The
//      code generation step is described in more detail below.

// Code generation.
//
//   The nodes are divided into four main categories.
//   * Choice nodes
//        These represent places where the regular expression can
//        match in more than one way.  For example on entry to an
//        alternation (foo|bar) or a repetition (*, +, ? or {}).
//   * Action nodes
//        These represent places where some action should be
//        performed.  Examples include recording the current position
//        in the input string to a register (in order to implement
//        captures) or other actions on register for example in order
//        to implement the counters needed for {} repetitions.
//   * Matching nodes
//        These attempt to match some element part of the input string.
//        Examples of elements include character classes, plain strings
//        or back references.
//   * End nodes
//        These are used to implement the actions required on finding
//        a successful match or failing to find a match.
//
//   The code generated maintains some state as it runs.  This consists of the
//   following elements:
//
//   * The capture registers.  Used for string captures.
//   * Other registers.  Used for counters etc.
//   * The current position.
//   * The stack of backtracking information.  Used when a matching node
//     fails to find a match and needs to try an alternative.
//
// Conceptual regular expression execution model:
//
//   There is a simple conceptual model of regular expression execution
//   which will be presented first.  The actual code generated is a more
//   efficient simulation of the simple conceptual model:
//
//   * Choice nodes are implemented as follows:
//     For each choice except the last {
//       push current position
//       push backtrack code location
//       <generate code to test for choice>
//       backtrack code location:
//       pop current position
//     }
//     <generate code to test for last choice>
//
//   * Actions nodes are generated as follows
//     <push affected registers on backtrack stack>
//     <generate code to perform action>
//     push backtrack code location
//     <generate code to test for following nodes>
//     backtrack code location:
//     <pop affected registers to restore their state>
//     <pop backtrack location from stack and go to it>
//
//   * Matching nodes are generated as follows:
//     if input string matches at current position
//       update current position
//       <generate code to test for following nodes>
//     else
//       <pop backtrack location from stack and go to it>
//
//   Thus it can be seen that the current position is saved and restored
//   by the choice nodes, whereas the registers are saved and restored by
//   by the action nodes that manipulate them.
//
//   The other interesting aspect of this model is that nodes are generated
//   at the point where they are needed by a recursive call to Emit().  If
//   the node has already been code generated then the Emit() call will
//   generate a jump to the previously generated code instead.  In order to
//   limit recursion it is possible for the Emit() function to put the node
//   on a work list for later generation and instead generate a jump.  The
//   destination of the jump is resolved later when the code is generated.
//
// Actual regular expression code generation.
//
//   Code generation is actually more complicated than the above.  In order
//   to improve the efficiency of the generated code some optimizations are
//   performed
//
//   * Choice nodes have 1-character lookahead.
//     A choice node looks at the following character and eliminates some of
//     the choices immediately based on that character.  This is not yet
//     implemented.
//   * Simple greedy loops store reduced backtracking information.
//     A quantifier like /.*foo/m will greedily match the whole input.  It will
//     then need to backtrack to a point where it can match "foo".  The naive
//     implementation of this would push each character position onto the
//     backtracking stack, then pop them off one by one.  This would use space
//     proportional to the length of the input string.  However since the "."
//     can only match in one way and always has a constant length (in this case
//     of 1) it suffices to store the current position on the top of the stack
//     once.  Matching now becomes merely incrementing the current position and
//     backtracking becomes decrementing the current position and checking the
//     result against the stored current position.  This is faster and saves
//     space.
//   * The current state is virtualized.
//     This is used to defer expensive operations until it is clear that they
//     are needed and to generate code for a node more than once, allowing
//     specialized an efficient versions of the code to be created. This is
//     explained in the section below.
//
// Execution state virtualization.
//
//   Instead of emitting code, nodes that manipulate the state can record their
//   manipulation in an object called the Trace.  The Trace object can record a
//   current position offset, an optional backtrack code location on the top of
//   the virtualized backtrack stack and some register changes.  When a node is
//   to be emitted it can flush the Trace or update it.  Flushing the Trace
//   will emit code to bring the actual state into line with the virtual state.
//   Avoiding flushing the state can postpone some work (e.g. updates of capture
//   registers).  Postponing work can save time when executing the regular
//   expression since it may be found that the work never has to be done as a
//   failure to match can occur.  In addition it is much faster to jump to a
//   known backtrack code location than it is to pop an unknown backtrack
//   location from the stack and jump there.
//
//   The virtual state found in the Trace affects code generation.  For example
//   the virtual state contains the difference between the actual current
//   position and the virtual current position, and matching code needs to use
//   this offset to attempt a match in the correct location of the input
//   string.  Therefore code generated for a non-trivial trace is specialized
//   to that trace.  The code generator therefore has the ability to generate
//   code for each node several times.  In order to limit the size of the
//   generated code there is an arbitrary limit on how many specialized sets of
//   code may be generated for a given node.  If the limit is reached, the
//   trace is flushed and a generic version of the code for a node is emitted.
//   This is subsequently used for that node.  The code emitted for non-generic
//   trace is not recorded in the node and so it cannot currently be reused in
//   the event that code generation is requested for an identical trace.


void RegExpTree::AppendToText(RegExpText* text) {
  UNREACHABLE();
}


void RegExpAtom::AppendToText(RegExpText* text) {
  text->AddElement(TextElement::Atom(this));
}


void RegExpCharacterClass::AppendToText(RegExpText* text) {
  text->AddElement(TextElement::CharClass(this));
}


void RegExpText::AppendToText(RegExpText* text) {
  for (intptr_t i = 0; i < elements()->length(); i++)
    text->AddElement((*elements())[i]);
}


TextElement TextElement::Atom(RegExpAtom* atom) {
  return TextElement(ATOM, atom);
}


TextElement TextElement::CharClass(RegExpCharacterClass* char_class) {
  return TextElement(CHAR_CLASS, char_class);
}


intptr_t TextElement::length() const {
  switch (text_type()) {
    case ATOM:
      return atom()->length();

    case CHAR_CLASS:
      return 1;
  }
  UNREACHABLE();
  return 0;
}


class FrequencyCollator : public ValueObject {
 public:
  FrequencyCollator() : total_samples_(0) {
    for (intptr_t i = 0; i < RegExpMacroAssembler::kTableSize; i++) {
      frequencies_[i] = CharacterFrequency(i);
    }
  }

  void CountCharacter(intptr_t character) {
    intptr_t index = (character & RegExpMacroAssembler::kTableMask);
    frequencies_[index].Increment();
    total_samples_++;
  }

  // Does not measure in percent, but rather per-128 (the table size from the
  // regexp macro assembler).
  intptr_t Frequency(intptr_t in_character) {
    ASSERT((in_character & RegExpMacroAssembler::kTableMask) == in_character);
    if (total_samples_ < 1) return 1;  // Division by zero.
    intptr_t freq_in_per128 =
        (frequencies_[in_character].counter() * 128) / total_samples_;
    return freq_in_per128;
  }

 private:
  class CharacterFrequency {
   public:
    CharacterFrequency() : counter_(0), character_(-1) {}
    explicit CharacterFrequency(intptr_t character)
        : counter_(0), character_(character) {}

    void Increment() { counter_++; }
    intptr_t counter() { return counter_; }
    intptr_t character() { return character_; }

   private:
    intptr_t counter_;
    intptr_t character_;

    DISALLOW_ALLOCATION();
  };


 private:
  CharacterFrequency frequencies_[RegExpMacroAssembler::kTableSize];
  intptr_t total_samples_;
};


class RegExpCompiler : public ValueObject {
 public:
  RegExpCompiler(intptr_t capture_count, bool ignore_case, bool is_one_byte);

  intptr_t AllocateRegister() { return next_register_++; }

#if !defined(DART_PRECOMPILED_RUNTIME)
  RegExpEngine::CompilationResult Assemble(IRRegExpMacroAssembler* assembler,
                                           RegExpNode* start,
                                           intptr_t capture_count,
                                           const String& pattern);
#endif

  RegExpEngine::CompilationResult Assemble(
      BytecodeRegExpMacroAssembler* assembler,
      RegExpNode* start,
      intptr_t capture_count,
      const String& pattern);

  inline void AddWork(RegExpNode* node) { work_list_->Add(node); }

  static const intptr_t kImplementationOffset = 0;
  static const intptr_t kNumberOfRegistersOffset = 0;
  static const intptr_t kCodeOffset = 1;

  RegExpMacroAssembler* macro_assembler() { return macro_assembler_; }
  EndNode* accept() { return accept_; }

  static const intptr_t kMaxRecursion = 100;
  inline intptr_t recursion_depth() { return recursion_depth_; }
  inline void IncrementRecursionDepth() { recursion_depth_++; }
  inline void DecrementRecursionDepth() { recursion_depth_--; }

  void SetRegExpTooBig() { reg_exp_too_big_ = true; }

  inline bool ignore_case() { return ignore_case_; }
  inline bool one_byte() const { return is_one_byte_; }
  FrequencyCollator* frequency_collator() { return &frequency_collator_; }

  intptr_t current_expansion_factor() { return current_expansion_factor_; }
  void set_current_expansion_factor(intptr_t value) {
    current_expansion_factor_ = value;
  }

  Zone* zone() const { return zone_; }

  static const intptr_t kNoRegister = -1;

 private:
  EndNode* accept_;
  intptr_t next_register_;
  ZoneGrowableArray<RegExpNode*>* work_list_;
  intptr_t recursion_depth_;
  RegExpMacroAssembler* macro_assembler_;
  bool ignore_case_;
  bool is_one_byte_;
  bool reg_exp_too_big_;
  intptr_t current_expansion_factor_;
  FrequencyCollator frequency_collator_;
  Zone* zone_;
};


class RecursionCheck : public ValueObject {
 public:
  explicit RecursionCheck(RegExpCompiler* compiler) : compiler_(compiler) {
    compiler->IncrementRecursionDepth();
  }
  ~RecursionCheck() { compiler_->DecrementRecursionDepth(); }

 private:
  RegExpCompiler* compiler_;
};


static RegExpEngine::CompilationResult IrregexpRegExpTooBig() {
  return RegExpEngine::CompilationResult("RegExp too big");
}


// Attempts to compile the regexp using an Irregexp code generator.  Returns
// a fixed array or a null handle depending on whether it succeeded.
RegExpCompiler::RegExpCompiler(intptr_t capture_count,
                               bool ignore_case,
                               bool is_one_byte)
    : next_register_(2 * (capture_count + 1)),
      work_list_(NULL),
      recursion_depth_(0),
      ignore_case_(ignore_case),
      is_one_byte_(is_one_byte),
      reg_exp_too_big_(false),
      current_expansion_factor_(1),
      zone_(Thread::Current()->zone()) {
  accept_ = new (Z) EndNode(EndNode::ACCEPT, Z);
}


#if !defined(DART_PRECOMPILED_RUNTIME)
RegExpEngine::CompilationResult RegExpCompiler::Assemble(
    IRRegExpMacroAssembler* macro_assembler,
    RegExpNode* start,
    intptr_t capture_count,
    const String& pattern) {
  macro_assembler->set_slow_safe(false /* use_slow_safe_regexp_compiler */);
  macro_assembler_ = macro_assembler;

  ZoneGrowableArray<RegExpNode*> work_list(0);
  work_list_ = &work_list;
  BlockLabel fail;
  macro_assembler_->PushBacktrack(&fail);
  Trace new_trace;
  start->Emit(this, &new_trace);
  macro_assembler_->BindBlock(&fail);
  macro_assembler_->Fail();
  while (!work_list.is_empty()) {
    work_list.RemoveLast()->Emit(this, &new_trace);
  }
  if (reg_exp_too_big_) return IrregexpRegExpTooBig();

  macro_assembler->GenerateBacktrackBlock();
  macro_assembler->FinalizeRegistersArray();

  return RegExpEngine::CompilationResult(
      macro_assembler->backtrack_goto(), macro_assembler->graph_entry(),
      macro_assembler->num_blocks(), macro_assembler->num_stack_locals(),
      next_register_);
}
#endif


RegExpEngine::CompilationResult RegExpCompiler::Assemble(
    BytecodeRegExpMacroAssembler* macro_assembler,
    RegExpNode* start,
    intptr_t capture_count,
    const String& pattern) {
  macro_assembler->set_slow_safe(false /* use_slow_safe_regexp_compiler */);
  macro_assembler_ = macro_assembler;

  ZoneGrowableArray<RegExpNode*> work_list(0);
  work_list_ = &work_list;
  BlockLabel fail;
  macro_assembler_->PushBacktrack(&fail);
  Trace new_trace;
  start->Emit(this, &new_trace);
  macro_assembler_->BindBlock(&fail);
  macro_assembler_->Fail();
  while (!work_list.is_empty()) {
    work_list.RemoveLast()->Emit(this, &new_trace);
  }
  if (reg_exp_too_big_) return IrregexpRegExpTooBig();

  TypedData& bytecode = TypedData::ZoneHandle(macro_assembler->GetBytecode());
  return RegExpEngine::CompilationResult(&bytecode, next_register_);
}


bool Trace::DeferredAction::Mentions(intptr_t that) {
  if (action_type() == ActionNode::CLEAR_CAPTURES) {
    Interval range = static_cast<DeferredClearCaptures*>(this)->range();
    return range.Contains(that);
  } else {
    return reg() == that;
  }
}


bool Trace::mentions_reg(intptr_t reg) {
  for (DeferredAction* action = actions_; action != NULL;
       action = action->next()) {
    if (action->Mentions(reg)) return true;
  }
  return false;
}


bool Trace::GetStoredPosition(intptr_t reg, intptr_t* cp_offset) {
  ASSERT(*cp_offset == 0);
  for (DeferredAction* action = actions_; action != NULL;
       action = action->next()) {
    if (action->Mentions(reg)) {
      if (action->action_type() == ActionNode::STORE_POSITION) {
        *cp_offset = static_cast<DeferredCapture*>(action)->cp_offset();
        return true;
      } else {
        return false;
      }
    }
  }
  return false;
}


// This is called as we come into a loop choice node and some other tricky
// nodes.  It normalizes the state of the code generator to ensure we can
// generate generic code.
intptr_t Trace::FindAffectedRegisters(OutSet* affected_registers, Zone* zone) {
  intptr_t max_register = RegExpCompiler::kNoRegister;
  for (DeferredAction* action = actions_; action != NULL;
       action = action->next()) {
    if (action->action_type() == ActionNode::CLEAR_CAPTURES) {
      Interval range = static_cast<DeferredClearCaptures*>(action)->range();
      for (intptr_t i = range.from(); i <= range.to(); i++)
        affected_registers->Set(i, zone);
      if (range.to() > max_register) max_register = range.to();
    } else {
      affected_registers->Set(action->reg(), zone);
      if (action->reg() > max_register) max_register = action->reg();
    }
  }
  return max_register;
}


void Trace::RestoreAffectedRegisters(RegExpMacroAssembler* assembler,
                                     intptr_t max_register,
                                     const OutSet& registers_to_pop,
                                     const OutSet& registers_to_clear) {
  for (intptr_t reg = max_register; reg >= 0; reg--) {
    if (registers_to_pop.Get(reg)) {
      assembler->PopRegister(reg);
    } else if (registers_to_clear.Get(reg)) {
      intptr_t clear_to = reg;
      while (reg > 0 && registers_to_clear.Get(reg - 1)) {
        reg--;
      }
      assembler->ClearRegisters(reg, clear_to);
    }
  }
}


void Trace::PerformDeferredActions(RegExpMacroAssembler* assembler,
                                   intptr_t max_register,
                                   const OutSet& affected_registers,
                                   OutSet* registers_to_pop,
                                   OutSet* registers_to_clear,
                                   Zone* zone) {
  for (intptr_t reg = 0; reg <= max_register; reg++) {
    if (!affected_registers.Get(reg)) {
      continue;
    }

    // The chronologically first deferred action in the trace
    // is used to infer the action needed to restore a register
    // to its previous state (or not, if it's safe to ignore it).
    enum DeferredActionUndoType { ACTION_IGNORE, ACTION_RESTORE, ACTION_CLEAR };
    DeferredActionUndoType undo_action = ACTION_IGNORE;

    intptr_t value = 0;
    bool absolute = false;
    bool clear = false;
    intptr_t store_position = -1;
    // This is a little tricky because we are scanning the actions in reverse
    // historical order (newest first).
    for (DeferredAction* action = actions_; action != NULL;
         action = action->next()) {
      if (action->Mentions(reg)) {
        switch (action->action_type()) {
          case ActionNode::SET_REGISTER: {
            Trace::DeferredSetRegister* psr =
                static_cast<Trace::DeferredSetRegister*>(action);
            if (!absolute) {
              value += psr->value();
              absolute = true;
            }
            // SET_REGISTER is currently only used for newly introduced loop
            // counters. They can have a significant previous value if they
            // occour in a loop. TODO(lrn): Propagate this information, so we
            // can set undo_action to ACTION_IGNORE if we know there is no
            // value to restore.
            undo_action = ACTION_RESTORE;
            ASSERT(store_position == -1);
            ASSERT(!clear);
            break;
          }
          case ActionNode::INCREMENT_REGISTER:
            if (!absolute) {
              value++;
            }
            ASSERT(store_position == -1);
            ASSERT(!clear);
            undo_action = ACTION_RESTORE;
            break;
          case ActionNode::STORE_POSITION: {
            Trace::DeferredCapture* pc =
                static_cast<Trace::DeferredCapture*>(action);
            if (!clear && store_position == -1) {
              store_position = pc->cp_offset();
            }

            // For captures we know that stores and clears alternate.
            // Other register, are never cleared, and if the occur
            // inside a loop, they might be assigned more than once.
            if (reg <= 1) {
              // Registers zero and one, aka "capture zero", is
              // always set correctly if we succeed. There is no
              // need to undo a setting on backtrack, because we
              // will set it again or fail.
              undo_action = ACTION_IGNORE;
            } else {
              undo_action = pc->is_capture() ? ACTION_CLEAR : ACTION_RESTORE;
            }
            ASSERT(!absolute);
            ASSERT(value == 0);
            break;
          }
          case ActionNode::CLEAR_CAPTURES: {
            // Since we're scanning in reverse order, if we've already
            // set the position we have to ignore historically earlier
            // clearing operations.
            if (store_position == -1) {
              clear = true;
            }
            undo_action = ACTION_RESTORE;
            ASSERT(!absolute);
            ASSERT(value == 0);
            break;
          }
          default:
            UNREACHABLE();
            break;
        }
      }
    }
    // Prepare for the undo-action (e.g., push if it's going to be popped).
    if (undo_action == ACTION_RESTORE) {
      assembler->PushRegister(reg);
      registers_to_pop->Set(reg, zone);
    } else if (undo_action == ACTION_CLEAR) {
      registers_to_clear->Set(reg, zone);
    }
    // Perform the chronologically last action (or accumulated increment)
    // for the register.
    if (store_position != -1) {
      assembler->WriteCurrentPositionToRegister(reg, store_position);
    } else if (clear) {
      assembler->ClearRegisters(reg, reg);
    } else if (absolute) {
      assembler->SetRegister(reg, value);
    } else if (value != 0) {
      assembler->AdvanceRegister(reg, value);
    }
  }
}


// This is called as we come into a loop choice node and some other tricky
// nodes.  It normalizes the state of the code generator to ensure we can
// generate generic code.
void Trace::Flush(RegExpCompiler* compiler, RegExpNode* successor) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();

  ASSERT(!is_trivial());

  if (actions_ == NULL && backtrack() == NULL) {
    // Here we just have some deferred cp advances to fix and we are back to
    // a normal situation.  We may also have to forget some information gained
    // through a quick check that was already performed.
    if (cp_offset_ != 0) assembler->AdvanceCurrentPosition(cp_offset_);
    // Create a new trivial state and generate the node with that.
    Trace new_state;
    successor->Emit(compiler, &new_state);
    return;
  }

  // Generate deferred actions here along with code to undo them again.
  OutSet affected_registers;

  if (backtrack() != NULL) {
    // Here we have a concrete backtrack location.  These are set up by choice
    // nodes and so they indicate that we have a deferred save of the current
    // position which we may need to emit here.
    assembler->PushCurrentPosition();
  }
  Zone* zone = successor->zone();
  intptr_t max_register = FindAffectedRegisters(&affected_registers, zone);
  OutSet registers_to_pop;
  OutSet registers_to_clear;
  PerformDeferredActions(assembler, max_register, affected_registers,
                         &registers_to_pop, &registers_to_clear, zone);
  if (cp_offset_ != 0) {
    assembler->AdvanceCurrentPosition(cp_offset_);
  }

  // Create a new trivial state and generate the node with that.
  BlockLabel undo;
  assembler->PushBacktrack(&undo);
  Trace new_state;
  successor->Emit(compiler, &new_state);

  // On backtrack we need to restore state.
  assembler->BindBlock(&undo);
  RestoreAffectedRegisters(assembler, max_register, registers_to_pop,
                           registers_to_clear);
  if (backtrack() == NULL) {
    assembler->Backtrack();
  } else {
    assembler->PopCurrentPosition();
    assembler->GoTo(backtrack());
  }
}


void NegativeSubmatchSuccess::Emit(RegExpCompiler* compiler, Trace* trace) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();

  // Omit flushing the trace. We discard the entire stack frame anyway.

  if (!label()->IsBound()) {
    // We are completely independent of the trace, since we ignore it,
    // so this code can be used as the generic version.
    assembler->BindBlock(label());
  }

  // Throw away everything on the backtrack stack since the start
  // of the negative submatch and restore the character position.
  assembler->ReadCurrentPositionFromRegister(current_position_register_);
  assembler->ReadStackPointerFromRegister(stack_pointer_register_);
  if (clear_capture_count_ > 0) {
    // Clear any captures that might have been performed during the success
    // of the body of the negative look-ahead.
    int clear_capture_end = clear_capture_start_ + clear_capture_count_ - 1;
    assembler->ClearRegisters(clear_capture_start_, clear_capture_end);
  }
  // Now that we have unwound the stack we find at the top of the stack the
  // backtrack that the BeginSubmatch node got.
  assembler->Backtrack();
}


void EndNode::Emit(RegExpCompiler* compiler, Trace* trace) {
  if (!trace->is_trivial()) {
    trace->Flush(compiler, this);
    return;
  }
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  if (!label()->IsBound()) {
    assembler->BindBlock(label());
  }
  switch (action_) {
    case ACCEPT:
      assembler->Succeed();
      return;
    case BACKTRACK:
      assembler->GoTo(trace->backtrack());
      return;
    case NEGATIVE_SUBMATCH_SUCCESS:
      // This case is handled in a different virtual method.
      UNREACHABLE();
  }
  UNIMPLEMENTED();
}


void GuardedAlternative::AddGuard(Guard* guard, Zone* zone) {
  if (guards_ == NULL) guards_ = new (zone) ZoneGrowableArray<Guard*>(1);
  guards_->Add(guard);
}


ActionNode* ActionNode::SetRegister(intptr_t reg,
                                    intptr_t val,
                                    RegExpNode* on_success) {
  ActionNode* result =
      new (on_success->zone()) ActionNode(SET_REGISTER, on_success);
  result->data_.u_store_register.reg = reg;
  result->data_.u_store_register.value = val;
  return result;
}


ActionNode* ActionNode::IncrementRegister(intptr_t reg,
                                          RegExpNode* on_success) {
  ActionNode* result =
      new (on_success->zone()) ActionNode(INCREMENT_REGISTER, on_success);
  result->data_.u_increment_register.reg = reg;
  return result;
}


ActionNode* ActionNode::StorePosition(intptr_t reg,
                                      bool is_capture,
                                      RegExpNode* on_success) {
  ActionNode* result =
      new (on_success->zone()) ActionNode(STORE_POSITION, on_success);
  result->data_.u_position_register.reg = reg;
  result->data_.u_position_register.is_capture = is_capture;
  return result;
}


ActionNode* ActionNode::ClearCaptures(Interval range, RegExpNode* on_success) {
  ActionNode* result =
      new (on_success->zone()) ActionNode(CLEAR_CAPTURES, on_success);
  result->data_.u_clear_captures.range_from = range.from();
  result->data_.u_clear_captures.range_to = range.to();
  return result;
}


ActionNode* ActionNode::BeginSubmatch(intptr_t stack_reg,
                                      intptr_t position_reg,
                                      RegExpNode* on_success) {
  ActionNode* result =
      new (on_success->zone()) ActionNode(BEGIN_SUBMATCH, on_success);
  result->data_.u_submatch.stack_pointer_register = stack_reg;
  result->data_.u_submatch.current_position_register = position_reg;
  return result;
}


ActionNode* ActionNode::PositiveSubmatchSuccess(intptr_t stack_reg,
                                                intptr_t position_reg,
                                                intptr_t clear_register_count,
                                                intptr_t clear_register_from,
                                                RegExpNode* on_success) {
  ActionNode* result = new (on_success->zone())
      ActionNode(POSITIVE_SUBMATCH_SUCCESS, on_success);
  result->data_.u_submatch.stack_pointer_register = stack_reg;
  result->data_.u_submatch.current_position_register = position_reg;
  result->data_.u_submatch.clear_register_count = clear_register_count;
  result->data_.u_submatch.clear_register_from = clear_register_from;
  return result;
}


ActionNode* ActionNode::EmptyMatchCheck(intptr_t start_register,
                                        intptr_t repetition_register,
                                        intptr_t repetition_limit,
                                        RegExpNode* on_success) {
  ActionNode* result =
      new (on_success->zone()) ActionNode(EMPTY_MATCH_CHECK, on_success);
  result->data_.u_empty_match_check.start_register = start_register;
  result->data_.u_empty_match_check.repetition_register = repetition_register;
  result->data_.u_empty_match_check.repetition_limit = repetition_limit;
  return result;
}


#define DEFINE_ACCEPT(Type)                                                    \
  void Type##Node::Accept(NodeVisitor* visitor) { visitor->Visit##Type(this); }
FOR_EACH_NODE_TYPE(DEFINE_ACCEPT)
#undef DEFINE_ACCEPT


void LoopChoiceNode::Accept(NodeVisitor* visitor) {
  visitor->VisitLoopChoice(this);
}


// -------------------------------------------------------------------
// Emit code.


void ChoiceNode::GenerateGuard(RegExpMacroAssembler* macro_assembler,
                               Guard* guard,
                               Trace* trace) {
  switch (guard->op()) {
    case Guard::LT:
      ASSERT(!trace->mentions_reg(guard->reg()));
      macro_assembler->IfRegisterGE(guard->reg(), guard->value(),
                                    trace->backtrack());
      break;
    case Guard::GEQ:
      ASSERT(!trace->mentions_reg(guard->reg()));
      macro_assembler->IfRegisterLT(guard->reg(), guard->value(),
                                    trace->backtrack());
      break;
  }
}


// Returns the number of characters in the equivalence class, omitting those
// that cannot occur in the source string because it is ASCII.
static intptr_t GetCaseIndependentLetters(uint16_t character,
                                          bool one_byte_subject,
                                          int32_t* letters) {
  unibrow::Mapping<unibrow::Ecma262UnCanonicalize> jsregexp_uncanonicalize;
  intptr_t length = jsregexp_uncanonicalize.get(character, '\0', letters);
  // Unibrow returns 0 or 1 for characters where case independence is
  // trivial.
  if (length == 0) {
    letters[0] = character;
    length = 1;
  }
  if (!one_byte_subject || character <= Symbols::kMaxOneCharCodeSymbol) {
    return length;
  }

  // The standard requires that non-ASCII characters cannot have ASCII
  // character codes in their equivalence class.
  // TODO(dcarney): issue 3550 this is not actually true for Latin1 anymore,
  // is it?  For example, \u00C5 is equivalent to \u212B.
  return 0;
}


static inline bool EmitSimpleCharacter(Zone* zone,
                                       RegExpCompiler* compiler,
                                       uint16_t c,
                                       BlockLabel* on_failure,
                                       intptr_t cp_offset,
                                       bool check,
                                       bool preloaded) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  bool bound_checked = false;
  if (!preloaded) {
    assembler->LoadCurrentCharacter(cp_offset, on_failure, check);
    bound_checked = true;
  }
  assembler->CheckNotCharacter(c, on_failure);
  return bound_checked;
}


// Only emits non-letters (things that don't have case).  Only used for case
// independent matches.
static inline bool EmitAtomNonLetter(Zone* zone,
                                     RegExpCompiler* compiler,
                                     uint16_t c,
                                     BlockLabel* on_failure,
                                     intptr_t cp_offset,
                                     bool check,
                                     bool preloaded) {
  RegExpMacroAssembler* macro_assembler = compiler->macro_assembler();
  bool one_byte = compiler->one_byte();
  int32_t chars[unibrow::Ecma262UnCanonicalize::kMaxWidth];
  intptr_t length = GetCaseIndependentLetters(c, one_byte, chars);
  if (length < 1) {
    // This can't match.  Must be an one-byte subject and a non-one-byte
    // character.  We do not need to do anything since the one-byte pass
    // already handled this.
    return false;  // Bounds not checked.
  }
  bool checked = false;
  // We handle the length > 1 case in a later pass.
  if (length == 1) {
    if (one_byte && c > Symbols::kMaxOneCharCodeSymbol) {
      // Can't match - see above.
      return false;  // Bounds not checked.
    }
    if (!preloaded) {
      macro_assembler->LoadCurrentCharacter(cp_offset, on_failure, check);
      checked = check;
    }
    macro_assembler->CheckNotCharacter(c, on_failure);
  }
  return checked;
}


static bool ShortCutEmitCharacterPair(RegExpMacroAssembler* macro_assembler,
                                      bool one_byte,
                                      uint16_t c1,
                                      uint16_t c2,
                                      BlockLabel* on_failure) {
  uint16_t char_mask;
  if (one_byte) {
    char_mask = Symbols::kMaxOneCharCodeSymbol;
  } else {
    char_mask = Utf16::kMaxCodeUnit;
  }
  uint16_t exor = c1 ^ c2;
  // Check whether exor has only one bit set.
  if (((exor - 1) & exor) == 0) {
    // If c1 and c2 differ only by one bit.
    // Ecma262UnCanonicalize always gives the highest number last.
    ASSERT(c2 > c1);
    uint16_t mask = char_mask ^ exor;
    macro_assembler->CheckNotCharacterAfterAnd(c1, mask, on_failure);
    return true;
  }
  ASSERT(c2 > c1);
  uint16_t diff = c2 - c1;
  if (((diff - 1) & diff) == 0 && c1 >= diff) {
    // If the characters differ by 2^n but don't differ by one bit then
    // subtract the difference from the found character, then do the or
    // trick.  We avoid the theoretical case where negative numbers are
    // involved in order to simplify code generation.
    uint16_t mask = char_mask ^ diff;
    macro_assembler->CheckNotCharacterAfterMinusAnd(c1 - diff, diff, mask,
                                                    on_failure);
    return true;
  }
  return false;
}


typedef bool EmitCharacterFunction(Zone* zone,
                                   RegExpCompiler* compiler,
                                   uint16_t c,
                                   BlockLabel* on_failure,
                                   intptr_t cp_offset,
                                   bool check,
                                   bool preloaded);

// Only emits letters (things that have case).  Only used for case independent
// matches.
static inline bool EmitAtomLetter(Zone* zone,
                                  RegExpCompiler* compiler,
                                  uint16_t c,
                                  BlockLabel* on_failure,
                                  intptr_t cp_offset,
                                  bool check,
                                  bool preloaded) {
  RegExpMacroAssembler* macro_assembler = compiler->macro_assembler();
  bool one_byte = compiler->one_byte();
  int32_t chars[unibrow::Ecma262UnCanonicalize::kMaxWidth];
  intptr_t length = GetCaseIndependentLetters(c, one_byte, chars);
  if (length <= 1) return false;
  // We may not need to check against the end of the input string
  // if this character lies before a character that matched.
  if (!preloaded) {
    macro_assembler->LoadCurrentCharacter(cp_offset, on_failure, check);
  }
  BlockLabel ok;
  ASSERT(unibrow::Ecma262UnCanonicalize::kMaxWidth == 4);
  switch (length) {
    case 2: {
      if (ShortCutEmitCharacterPair(macro_assembler, one_byte, chars[0],
                                    chars[1], on_failure)) {
      } else {
        macro_assembler->CheckCharacter(chars[0], &ok);
        macro_assembler->CheckNotCharacter(chars[1], on_failure);
        macro_assembler->BindBlock(&ok);
      }
      break;
    }
    case 4:
      macro_assembler->CheckCharacter(chars[3], &ok);
    // Fall through!
    case 3:
      macro_assembler->CheckCharacter(chars[0], &ok);
      macro_assembler->CheckCharacter(chars[1], &ok);
      macro_assembler->CheckNotCharacter(chars[2], on_failure);
      macro_assembler->BindBlock(&ok);
      break;
    default:
      UNREACHABLE();
      break;
  }
  return true;
}


static void EmitBoundaryTest(RegExpMacroAssembler* masm,
                             intptr_t border,
                             BlockLabel* fall_through,
                             BlockLabel* above_or_equal,
                             BlockLabel* below) {
  if (below != fall_through) {
    masm->CheckCharacterLT(border, below);
    if (above_or_equal != fall_through) masm->GoTo(above_or_equal);
  } else {
    masm->CheckCharacterGT(border - 1, above_or_equal);
  }
}


static void EmitDoubleBoundaryTest(RegExpMacroAssembler* masm,
                                   intptr_t first,
                                   intptr_t last,
                                   BlockLabel* fall_through,
                                   BlockLabel* in_range,
                                   BlockLabel* out_of_range) {
  if (in_range == fall_through) {
    if (first == last) {
      masm->CheckNotCharacter(first, out_of_range);
    } else {
      masm->CheckCharacterNotInRange(first, last, out_of_range);
    }
  } else {
    if (first == last) {
      masm->CheckCharacter(first, in_range);
    } else {
      masm->CheckCharacterInRange(first, last, in_range);
    }
    if (out_of_range != fall_through) masm->GoTo(out_of_range);
  }
}


// even_label is for ranges[i] to ranges[i + 1] where i - start_index is even.
// odd_label is for ranges[i] to ranges[i + 1] where i - start_index is odd.
static void EmitUseLookupTable(RegExpMacroAssembler* masm,
                               ZoneGrowableArray<int>* ranges,
                               intptr_t start_index,
                               intptr_t end_index,
                               intptr_t min_char,
                               BlockLabel* fall_through,
                               BlockLabel* even_label,
                               BlockLabel* odd_label) {
  static const intptr_t kSize = RegExpMacroAssembler::kTableSize;
  static const intptr_t kMask = RegExpMacroAssembler::kTableMask;

  intptr_t base = (min_char & ~kMask);

  // Assert that everything is on one kTableSize page.
  for (intptr_t i = start_index; i <= end_index; i++) {
    ASSERT((ranges->At(i) & ~kMask) == base);
  }
  ASSERT(start_index == 0 || (ranges->At(start_index - 1) & ~kMask) <= base);

  char templ[kSize];
  BlockLabel* on_bit_set;
  BlockLabel* on_bit_clear;
  intptr_t bit;
  if (even_label == fall_through) {
    on_bit_set = odd_label;
    on_bit_clear = even_label;
    bit = 1;
  } else {
    on_bit_set = even_label;
    on_bit_clear = odd_label;
    bit = 0;
  }
  for (intptr_t i = 0; i < (ranges->At(start_index) & kMask) && i < kSize;
       i++) {
    templ[i] = bit;
  }
  intptr_t j = 0;
  bit ^= 1;
  for (intptr_t i = start_index; i < end_index; i++) {
    for (j = (ranges->At(i) & kMask); j < (ranges->At(i + 1) & kMask); j++) {
      templ[j] = bit;
    }
    bit ^= 1;
  }
  for (intptr_t i = j; i < kSize; i++) {
    templ[i] = bit;
  }
  // TODO(erikcorry): Cache these.
  const TypedData& ba = TypedData::ZoneHandle(
      masm->zone(), TypedData::New(kTypedDataUint8ArrayCid, kSize, Heap::kOld));
  for (intptr_t i = 0; i < kSize; i++) {
    ba.SetUint8(i, templ[i]);
  }
  masm->CheckBitInTable(ba, on_bit_set);
  if (on_bit_clear != fall_through) masm->GoTo(on_bit_clear);
}


static void CutOutRange(RegExpMacroAssembler* masm,
                        ZoneGrowableArray<int>* ranges,
                        intptr_t start_index,
                        intptr_t end_index,
                        intptr_t cut_index,
                        BlockLabel* even_label,
                        BlockLabel* odd_label) {
  bool odd = (((cut_index - start_index) & 1) == 1);
  BlockLabel* in_range_label = odd ? odd_label : even_label;
  BlockLabel dummy;
  EmitDoubleBoundaryTest(masm, ranges->At(cut_index),
                         ranges->At(cut_index + 1) - 1, &dummy, in_range_label,
                         &dummy);
  ASSERT(!dummy.IsLinked());
  // Cut out the single range by rewriting the array.  This creates a new
  // range that is a merger of the two ranges on either side of the one we
  // are cutting out.  The oddity of the labels is preserved.
  for (intptr_t j = cut_index; j > start_index; j--) {
    (*ranges)[j] = ranges->At(j - 1);
  }
  for (intptr_t j = cut_index + 1; j < end_index; j++) {
    (*ranges)[j] = ranges->At(j + 1);
  }
}


// Unicode case.  Split the search space into kSize spaces that are handled
// with recursion.
static void SplitSearchSpace(ZoneGrowableArray<int>* ranges,
                             intptr_t start_index,
                             intptr_t end_index,
                             intptr_t* new_start_index,
                             intptr_t* new_end_index,
                             intptr_t* border) {
  static const intptr_t kSize = RegExpMacroAssembler::kTableSize;
  static const intptr_t kMask = RegExpMacroAssembler::kTableMask;

  intptr_t first = ranges->At(start_index);
  intptr_t last = ranges->At(end_index) - 1;

  *new_start_index = start_index;
  *border = (ranges->At(start_index) & ~kMask) + kSize;
  while (*new_start_index < end_index) {
    if (ranges->At(*new_start_index) > *border) break;
    (*new_start_index)++;
  }
  // new_start_index is the index of the first edge that is beyond the
  // current kSize space.

  // For very large search spaces we do a binary chop search of the non-Latin1
  // space instead of just going to the end of the current kSize space.  The
  // heuristics are complicated a little by the fact that any 128-character
  // encoding space can be quickly tested with a table lookup, so we don't
  // wish to do binary chop search at a smaller granularity than that.  A
  // 128-character space can take up a lot of space in the ranges array if,
  // for example, we only want to match every second character (eg. the lower
  // case characters on some Unicode pages).
  intptr_t binary_chop_index = (end_index + start_index) / 2;
  // The first test ensures that we get to the code that handles the Latin1
  // range with a single not-taken branch, speeding up this important
  // character range (even non-Latin1 charset-based text has spaces and
  // punctuation).
  if (*border - 1 > Symbols::kMaxOneCharCodeSymbol &&  // Latin1 case.
      end_index - start_index > (*new_start_index - start_index) * 2 &&
      last - first > kSize * 2 && binary_chop_index > *new_start_index &&
      ranges->At(binary_chop_index) >= first + 2 * kSize) {
    intptr_t scan_forward_for_section_border = binary_chop_index;
    intptr_t new_border = (ranges->At(binary_chop_index) | kMask) + 1;

    while (scan_forward_for_section_border < end_index) {
      if (ranges->At(scan_forward_for_section_border) > new_border) {
        *new_start_index = scan_forward_for_section_border;
        *border = new_border;
        break;
      }
      scan_forward_for_section_border++;
    }
  }

  ASSERT(*new_start_index > start_index);
  *new_end_index = *new_start_index - 1;
  if (ranges->At(*new_end_index) == *border) {
    (*new_end_index)--;
  }
  if (*border >= ranges->At(end_index)) {
    *border = ranges->At(end_index);
    *new_start_index = end_index;  // Won't be used.
    *new_end_index = end_index - 1;
  }
}


// Gets a series of segment boundaries representing a character class.  If the
// character is in the range between an even and an odd boundary (counting from
// start_index) then go to even_label, otherwise go to odd_label.  We already
// know that the character is in the range of min_char to max_char inclusive.
// Either label can be NULL indicating backtracking.  Either label can also be
// equal to the fall_through label.
static void GenerateBranches(RegExpMacroAssembler* masm,
                             ZoneGrowableArray<int>* ranges,
                             intptr_t start_index,
                             intptr_t end_index,
                             uint16_t min_char,
                             uint16_t max_char,
                             BlockLabel* fall_through,
                             BlockLabel* even_label,
                             BlockLabel* odd_label) {
  intptr_t first = ranges->At(start_index);
  intptr_t last = ranges->At(end_index) - 1;

  ASSERT(min_char < first);

  // Just need to test if the character is before or on-or-after
  // a particular character.
  if (start_index == end_index) {
    EmitBoundaryTest(masm, first, fall_through, even_label, odd_label);
    return;
  }

  // Another almost trivial case:  There is one interval in the middle that is
  // different from the end intervals.
  if (start_index + 1 == end_index) {
    EmitDoubleBoundaryTest(masm, first, last, fall_through, even_label,
                           odd_label);
    return;
  }

  // It's not worth using table lookup if there are very few intervals in the
  // character class.
  if (end_index - start_index <= 6) {
    // It is faster to test for individual characters, so we look for those
    // first, then try arbitrary ranges in the second round.
    static intptr_t kNoCutIndex = -1;
    intptr_t cut = kNoCutIndex;
    for (intptr_t i = start_index; i < end_index; i++) {
      if (ranges->At(i) == ranges->At(i + 1) - 1) {
        cut = i;
        break;
      }
    }
    if (cut == kNoCutIndex) cut = start_index;
    CutOutRange(masm, ranges, start_index, end_index, cut, even_label,
                odd_label);
    ASSERT(end_index - start_index >= 2);
    GenerateBranches(masm, ranges, start_index + 1, end_index - 1, min_char,
                     max_char, fall_through, even_label, odd_label);
    return;
  }

  // If there are a lot of intervals in the regexp, then we will use tables to
  // determine whether the character is inside or outside the character class.
  static const intptr_t kBits = RegExpMacroAssembler::kTableSizeBits;

  if ((max_char >> kBits) == (min_char >> kBits)) {
    EmitUseLookupTable(masm, ranges, start_index, end_index, min_char,
                       fall_through, even_label, odd_label);
    return;
  }

  if ((min_char >> kBits) != (first >> kBits)) {
    masm->CheckCharacterLT(first, odd_label);
    GenerateBranches(masm, ranges, start_index + 1, end_index, first, max_char,
                     fall_through, odd_label, even_label);
    return;
  }

  intptr_t new_start_index = 0;
  intptr_t new_end_index = 0;
  intptr_t border = 0;

  SplitSearchSpace(ranges, start_index, end_index, &new_start_index,
                   &new_end_index, &border);

  BlockLabel handle_rest;
  BlockLabel* above = &handle_rest;
  if (border == last + 1) {
    // We didn't find any section that started after the limit, so everything
    // above the border is one of the terminal labels.
    above = (end_index & 1) != (start_index & 1) ? odd_label : even_label;
    ASSERT(new_end_index == end_index - 1);
  }

  ASSERT(start_index <= new_end_index);
  ASSERT(new_start_index <= end_index);
  ASSERT(start_index < new_start_index);
  ASSERT(new_end_index < end_index);
  ASSERT(new_end_index + 1 == new_start_index ||
         (new_end_index + 2 == new_start_index &&
          border == ranges->At(new_end_index + 1)));
  ASSERT(min_char < border - 1);
  ASSERT(border < max_char);
  ASSERT(ranges->At(new_end_index) < border);
  ASSERT(border < ranges->At(new_start_index) ||
         (border == ranges->At(new_start_index) &&
          new_start_index == end_index && new_end_index == end_index - 1 &&
          border == last + 1));
  ASSERT(new_start_index == 0 || border >= ranges->At(new_start_index - 1));

  masm->CheckCharacterGT(border - 1, above);
  BlockLabel dummy;
  GenerateBranches(masm, ranges, start_index, new_end_index, min_char,
                   border - 1, &dummy, even_label, odd_label);

  if (handle_rest.IsLinked()) {
    masm->BindBlock(&handle_rest);
    bool flip = (new_start_index & 1) != (start_index & 1);
    GenerateBranches(masm, ranges, new_start_index, end_index, border, max_char,
                     &dummy, flip ? odd_label : even_label,
                     flip ? even_label : odd_label);
  }
}


static void EmitCharClass(RegExpMacroAssembler* macro_assembler,
                          RegExpCharacterClass* cc,
                          bool one_byte,
                          BlockLabel* on_failure,
                          intptr_t cp_offset,
                          bool check_offset,
                          bool preloaded,
                          Zone* zone) {
  ZoneGrowableArray<CharacterRange>* ranges = cc->ranges();
  if (!CharacterRange::IsCanonical(ranges)) {
    CharacterRange::Canonicalize(ranges);
  }

  intptr_t max_char;
  if (one_byte) {
    max_char = Symbols::kMaxOneCharCodeSymbol;
  } else {
    max_char = Utf16::kMaxCodeUnit;
  }

  intptr_t range_count = ranges->length();

  intptr_t last_valid_range = range_count - 1;
  while (last_valid_range >= 0) {
    CharacterRange& range = (*ranges)[last_valid_range];
    if (range.from() <= max_char) {
      break;
    }
    last_valid_range--;
  }

  if (last_valid_range < 0) {
    if (!cc->is_negated()) {
      macro_assembler->GoTo(on_failure);
    }
    if (check_offset) {
      macro_assembler->CheckPosition(cp_offset, on_failure);
    }
    return;
  }

  if (last_valid_range == 0 && ranges->At(0).IsEverything(max_char)) {
    if (cc->is_negated()) {
      macro_assembler->GoTo(on_failure);
    } else {
      // This is a common case hit by non-anchored expressions.
      if (check_offset) {
        macro_assembler->CheckPosition(cp_offset, on_failure);
      }
    }
    return;
  }
  if (last_valid_range == 0 && !cc->is_negated() &&
      ranges->At(0).IsEverything(max_char)) {
    // This is a common case hit by non-anchored expressions.
    if (check_offset) {
      macro_assembler->CheckPosition(cp_offset, on_failure);
    }
    return;
  }

  if (!preloaded) {
    macro_assembler->LoadCurrentCharacter(cp_offset, on_failure, check_offset);
  }

  if (cc->is_standard() &&
      macro_assembler->CheckSpecialCharacterClass(cc->standard_type(),
                                                  on_failure)) {
    return;
  }


  // A new list with ascending entries.  Each entry is a code unit
  // where there is a boundary between code units that are part of
  // the class and code units that are not.  Normally we insert an
  // entry at zero which goes to the failure label, but if there
  // was already one there we fall through for success on that entry.
  // Subsequent entries have alternating meaning (success/failure).
  ZoneGrowableArray<int>* range_boundaries =
      new (zone) ZoneGrowableArray<int>(last_valid_range);

  bool zeroth_entry_is_failure = !cc->is_negated();

  for (intptr_t i = 0; i <= last_valid_range; i++) {
    CharacterRange& range = (*ranges)[i];
    if (range.from() == 0) {
      ASSERT(i == 0);
      zeroth_entry_is_failure = !zeroth_entry_is_failure;
    } else {
      range_boundaries->Add(range.from());
    }
    range_boundaries->Add(range.to() + 1);
  }
  intptr_t end_index = range_boundaries->length() - 1;
  if (range_boundaries->At(end_index) > max_char) {
    end_index--;
  }

  BlockLabel fall_through;
  GenerateBranches(macro_assembler, range_boundaries,
                   0,  // start_index.
                   end_index,
                   0,  // min_char.
                   max_char, &fall_through,
                   zeroth_entry_is_failure ? &fall_through : on_failure,
                   zeroth_entry_is_failure ? on_failure : &fall_through);
  macro_assembler->BindBlock(&fall_through);
}


RegExpNode::~RegExpNode() {}


RegExpNode::LimitResult RegExpNode::LimitVersions(RegExpCompiler* compiler,
                                                  Trace* trace) {
  // If we are generating a greedy loop then don't stop and don't reuse code.
  if (trace->stop_node() != NULL) {
    return CONTINUE;
  }

  RegExpMacroAssembler* macro_assembler = compiler->macro_assembler();
  if (trace->is_trivial()) {
    if (label_.IsBound()) {
      // We are being asked to generate a generic version, but that's already
      // been done so just go to it.
      macro_assembler->GoTo(&label_);
      return DONE;
    }
    if (compiler->recursion_depth() >= RegExpCompiler::kMaxRecursion) {
      // To avoid too deep recursion we push the node to the work queue and just
      // generate a goto here.
      compiler->AddWork(this);
      macro_assembler->GoTo(&label_);
      return DONE;
    }
    // Generate generic version of the node and bind the label for later use.
    macro_assembler->BindBlock(&label_);
    return CONTINUE;
  }

  // We are being asked to make a non-generic version.  Keep track of how many
  // non-generic versions we generate so as not to overdo it.
  trace_count_++;
  if (kRegexpOptimization && trace_count_ < kMaxCopiesCodeGenerated &&
      compiler->recursion_depth() <= RegExpCompiler::kMaxRecursion) {
    return CONTINUE;
  }

  // If we get here code has been generated for this node too many times or
  // recursion is too deep.  Time to switch to a generic version.  The code for
  // generic versions above can handle deep recursion properly.
  trace->Flush(compiler, this);
  return DONE;
}


intptr_t ActionNode::EatsAtLeast(intptr_t still_to_find,
                                 intptr_t budget,
                                 bool not_at_start) {
  if (budget <= 0) return 0;
  if (action_type_ == POSITIVE_SUBMATCH_SUCCESS) return 0;  // Rewinds input!
  return on_success()->EatsAtLeast(still_to_find, budget - 1, not_at_start);
}


void ActionNode::FillInBMInfo(intptr_t offset,
                              intptr_t budget,
                              BoyerMooreLookahead* bm,
                              bool not_at_start) {
  if (action_type_ == BEGIN_SUBMATCH) {
    bm->SetRest(offset);
  } else if (action_type_ != POSITIVE_SUBMATCH_SUCCESS) {
    on_success()->FillInBMInfo(offset, budget - 1, bm, not_at_start);
  }
  SaveBMInfo(bm, not_at_start, offset);
}


intptr_t AssertionNode::EatsAtLeast(intptr_t still_to_find,
                                    intptr_t budget,
                                    bool not_at_start) {
  if (budget <= 0) return 0;
  // If we know we are not at the start and we are asked "how many characters
  // will you match if you succeed?" then we can answer anything since false
  // implies false.  So lets just return the max answer (still_to_find) since
  // that won't prevent us from preloading a lot of characters for the other
  // branches in the node graph.
  if (assertion_type() == AT_START && not_at_start) return still_to_find;
  return on_success()->EatsAtLeast(still_to_find, budget - 1, not_at_start);
}


void AssertionNode::FillInBMInfo(intptr_t offset,
                                 intptr_t budget,
                                 BoyerMooreLookahead* bm,
                                 bool not_at_start) {
  // Match the behaviour of EatsAtLeast on this node.
  if (assertion_type() == AT_START && not_at_start) return;
  on_success()->FillInBMInfo(offset, budget - 1, bm, not_at_start);
  SaveBMInfo(bm, not_at_start, offset);
}


intptr_t BackReferenceNode::EatsAtLeast(intptr_t still_to_find,
                                        intptr_t budget,
                                        bool not_at_start) {
  if (budget <= 0) return 0;
  return on_success()->EatsAtLeast(still_to_find, budget - 1, not_at_start);
}


intptr_t TextNode::EatsAtLeast(intptr_t still_to_find,
                               intptr_t budget,
                               bool not_at_start) {
  intptr_t answer = Length();
  if (answer >= still_to_find) return answer;
  if (budget <= 0) return answer;
  // We are not at start after this node so we set the last argument to 'true'.
  return answer +
         on_success()->EatsAtLeast(still_to_find - answer, budget - 1, true);
}


intptr_t NegativeLookaheadChoiceNode::EatsAtLeast(intptr_t still_to_find,
                                                  intptr_t budget,
                                                  bool not_at_start) {
  if (budget <= 0) return 0;
  // Alternative 0 is the negative lookahead, alternative 1 is what comes
  // afterwards.
  RegExpNode* node = (*alternatives_)[1].node();
  return node->EatsAtLeast(still_to_find, budget - 1, not_at_start);
}


void NegativeLookaheadChoiceNode::GetQuickCheckDetails(
    QuickCheckDetails* details,
    RegExpCompiler* compiler,
    intptr_t filled_in,
    bool not_at_start) {
  // Alternative 0 is the negative lookahead, alternative 1 is what comes
  // afterwards.
  RegExpNode* node = (*alternatives_)[1].node();
  return node->GetQuickCheckDetails(details, compiler, filled_in, not_at_start);
}


intptr_t ChoiceNode::EatsAtLeastHelper(intptr_t still_to_find,
                                       intptr_t budget,
                                       RegExpNode* ignore_this_node,
                                       bool not_at_start) {
  if (budget <= 0) return 0;
  intptr_t min = 100;
  intptr_t choice_count = alternatives_->length();
  budget = (budget - 1) / choice_count;
  for (intptr_t i = 0; i < choice_count; i++) {
    RegExpNode* node = (*alternatives_)[i].node();
    if (node == ignore_this_node) continue;
    intptr_t node_eats_at_least =
        node->EatsAtLeast(still_to_find, budget, not_at_start);
    if (node_eats_at_least < min) min = node_eats_at_least;
    if (min == 0) return 0;
  }
  return min;
}


intptr_t LoopChoiceNode::EatsAtLeast(intptr_t still_to_find,
                                     intptr_t budget,
                                     bool not_at_start) {
  return EatsAtLeastHelper(still_to_find, budget - 1, loop_node_, not_at_start);
}


intptr_t ChoiceNode::EatsAtLeast(intptr_t still_to_find,
                                 intptr_t budget,
                                 bool not_at_start) {
  return EatsAtLeastHelper(still_to_find, budget, NULL, not_at_start);
}


// Takes the left-most 1-bit and smears it out, setting all bits to its right.
static inline uint32_t SmearBitsRight(uint32_t v) {
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  return v;
}


bool QuickCheckDetails::Rationalize(bool asc) {
  bool found_useful_op = false;
  uint32_t char_mask;
  if (asc) {
    char_mask = Symbols::kMaxOneCharCodeSymbol;
  } else {
    char_mask = Utf16::kMaxCodeUnit;
  }
  mask_ = 0;
  value_ = 0;
  intptr_t char_shift = 0;
  for (intptr_t i = 0; i < characters_; i++) {
    Position* pos = &positions_[i];
    if ((pos->mask & Symbols::kMaxOneCharCodeSymbol) != 0) {
      found_useful_op = true;
    }
    mask_ |= (pos->mask & char_mask) << char_shift;
    value_ |= (pos->value & char_mask) << char_shift;
    char_shift += asc ? 8 : 16;
  }
  return found_useful_op;
}


bool RegExpNode::EmitQuickCheck(RegExpCompiler* compiler,
                                Trace* bounds_check_trace,
                                Trace* trace,
                                bool preload_has_checked_bounds,
                                BlockLabel* on_possible_success,
                                QuickCheckDetails* details,
                                bool fall_through_on_failure) {
  if (details->characters() == 0) return false;
  GetQuickCheckDetails(details, compiler, 0,
                       trace->at_start() == Trace::FALSE_VALUE);
  if (details->cannot_match()) return false;
  if (!details->Rationalize(compiler->one_byte())) return false;
  ASSERT(details->characters() == 1 ||
         compiler->macro_assembler()->CanReadUnaligned());
  uint32_t mask = details->mask();
  uint32_t value = details->value();

  RegExpMacroAssembler* assembler = compiler->macro_assembler();

  if (trace->characters_preloaded() != details->characters()) {
    ASSERT(trace->cp_offset() == bounds_check_trace->cp_offset());
    // We are attempting to preload the minimum number of characters
    // any choice would eat, so if the bounds check fails, then none of the
    // choices can succeed, so we can just immediately backtrack, rather
    // than go to the next choice.
    assembler->LoadCurrentCharacter(
        trace->cp_offset(), bounds_check_trace->backtrack(),
        !preload_has_checked_bounds, details->characters());
  }


  bool need_mask = true;

  if (details->characters() == 1) {
    // If number of characters preloaded is 1 then we used a byte or 16 bit
    // load so the value is already masked down.
    uint32_t char_mask;
    if (compiler->one_byte()) {
      char_mask = Symbols::kMaxOneCharCodeSymbol;
    } else {
      char_mask = Utf16::kMaxCodeUnit;
    }
    if ((mask & char_mask) == char_mask) need_mask = false;
    mask &= char_mask;
  } else {
    // For 2-character preloads in one-byte mode or 1-character preloads in
    // two-byte mode we also use a 16 bit load with zero extend.
    if (details->characters() == 2 && compiler->one_byte()) {
      if ((mask & 0xffff) == 0xffff) need_mask = false;
    } else if (details->characters() == 1 && !compiler->one_byte()) {
      if ((mask & 0xffff) == 0xffff) need_mask = false;
    } else {
      if (mask == 0xffffffff) need_mask = false;
    }
  }

  if (fall_through_on_failure) {
    if (need_mask) {
      assembler->CheckCharacterAfterAnd(value, mask, on_possible_success);
    } else {
      assembler->CheckCharacter(value, on_possible_success);
    }
  } else {
    if (need_mask) {
      assembler->CheckNotCharacterAfterAnd(value, mask, trace->backtrack());
    } else {
      assembler->CheckNotCharacter(value, trace->backtrack());
    }
  }
  return true;
}


// Here is the meat of GetQuickCheckDetails (see also the comment on the
// super-class in the .h file).
//
// We iterate along the text object, building up for each character a
// mask and value that can be used to test for a quick failure to match.
// The masks and values for the positions will be combined into a single
// machine word for the current character width in order to be used in
// generating a quick check.
void TextNode::GetQuickCheckDetails(QuickCheckDetails* details,
                                    RegExpCompiler* compiler,
                                    intptr_t characters_filled_in,
                                    bool not_at_start) {
#if defined(__GNUC__) && defined(__BYTE_ORDER__)
  // TODO(zerny): Make the combination code byte-order independent.
  ASSERT(details->characters() == 1 ||
         (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__));
#endif
  ASSERT(characters_filled_in < details->characters());
  intptr_t characters = details->characters();
  intptr_t char_mask;
  if (compiler->one_byte()) {
    char_mask = Symbols::kMaxOneCharCodeSymbol;
  } else {
    char_mask = Utf16::kMaxCodeUnit;
  }
  for (intptr_t k = 0; k < elms_->length(); k++) {
    TextElement elm = elms_->At(k);
    if (elm.text_type() == TextElement::ATOM) {
      ZoneGrowableArray<uint16_t>* quarks = elm.atom()->data();
      for (intptr_t i = 0; i < characters && i < quarks->length(); i++) {
        QuickCheckDetails::Position* pos =
            details->positions(characters_filled_in);
        uint16_t c = quarks->At(i);
        if (c > char_mask) {
          // If we expect a non-Latin1 character from an one-byte string,
          // there is no way we can match. Not even case independent
          // matching can turn an Latin1 character into non-Latin1 or
          // vice versa.
          // TODO(dcarney): issue 3550.  Verify that this works as expected.
          // For example, \u0178 is uppercase of \u00ff (y-umlaut).
          details->set_cannot_match();
          pos->determines_perfectly = false;
          return;
        }
        if (compiler->ignore_case()) {
          int32_t chars[unibrow::Ecma262UnCanonicalize::kMaxWidth];
          intptr_t length =
              GetCaseIndependentLetters(c, compiler->one_byte(), chars);
          ASSERT(length != 0);  // Can only happen if c > char_mask (see above).
          if (length == 1) {
            // This letter has no case equivalents, so it's nice and simple
            // and the mask-compare will determine definitely whether we have
            // a match at this character position.
            pos->mask = char_mask;
            pos->value = c;
            pos->determines_perfectly = true;
          } else {
            uint32_t common_bits = char_mask;
            uint32_t bits = chars[0];
            for (intptr_t j = 1; j < length; j++) {
              uint32_t differing_bits = ((chars[j] & common_bits) ^ bits);
              common_bits ^= differing_bits;
              bits &= common_bits;
            }
            // If length is 2 and common bits has only one zero in it then
            // our mask and compare instruction will determine definitely
            // whether we have a match at this character position.  Otherwise
            // it can only be an approximate check.
            uint32_t one_zero = (common_bits | ~char_mask);
            if (length == 2 && ((~one_zero) & ((~one_zero) - 1)) == 0) {
              pos->determines_perfectly = true;
            }
            pos->mask = common_bits;
            pos->value = bits;
          }
        } else {
          // Don't ignore case.  Nice simple case where the mask-compare will
          // determine definitely whether we have a match at this character
          // position.
          pos->mask = char_mask;
          pos->value = c;
          pos->determines_perfectly = true;
        }
        characters_filled_in++;
        ASSERT(characters_filled_in <= details->characters());
        if (characters_filled_in == details->characters()) {
          return;
        }
      }
    } else {
      QuickCheckDetails::Position* pos =
          details->positions(characters_filled_in);
      RegExpCharacterClass* tree = elm.char_class();
      ZoneGrowableArray<CharacterRange>* ranges = tree->ranges();
      if (tree->is_negated()) {
        // A quick check uses multi-character mask and compare.  There is no
        // useful way to incorporate a negative char class into this scheme
        // so we just conservatively create a mask and value that will always
        // succeed.
        pos->mask = 0;
        pos->value = 0;
      } else {
        intptr_t first_range = 0;
        while (ranges->At(first_range).from() > char_mask) {
          first_range++;
          if (first_range == ranges->length()) {
            details->set_cannot_match();
            pos->determines_perfectly = false;
            return;
          }
        }
        CharacterRange range = ranges->At(first_range);
        uint16_t from = range.from();
        uint16_t to = range.to();
        if (to > char_mask) {
          to = char_mask;
        }
        uint32_t differing_bits = (from ^ to);
        // A mask and compare is only perfect if the differing bits form a
        // number like 00011111 with one single block of trailing 1s.
        if ((differing_bits & (differing_bits + 1)) == 0 &&
            from + differing_bits == to) {
          pos->determines_perfectly = true;
        }
        uint32_t common_bits = ~SmearBitsRight(differing_bits);
        uint32_t bits = (from & common_bits);
        for (intptr_t i = first_range + 1; i < ranges->length(); i++) {
          CharacterRange range = ranges->At(i);
          uint16_t from = range.from();
          uint16_t to = range.to();
          if (from > char_mask) continue;
          if (to > char_mask) to = char_mask;
          // Here we are combining more ranges into the mask and compare
          // value.  With each new range the mask becomes more sparse and
          // so the chances of a false positive rise.  A character class
          // with multiple ranges is assumed never to be equivalent to a
          // mask and compare operation.
          pos->determines_perfectly = false;
          uint32_t new_common_bits = (from ^ to);
          new_common_bits = ~SmearBitsRight(new_common_bits);
          common_bits &= new_common_bits;
          bits &= new_common_bits;
          uint32_t differing_bits = (from & common_bits) ^ bits;
          common_bits ^= differing_bits;
          bits &= common_bits;
        }
        pos->mask = common_bits;
        pos->value = bits;
      }
      characters_filled_in++;
      ASSERT(characters_filled_in <= details->characters());
      if (characters_filled_in == details->characters()) {
        return;
      }
    }
  }
  ASSERT(characters_filled_in != details->characters());
  if (!details->cannot_match()) {
    on_success()->GetQuickCheckDetails(details, compiler, characters_filled_in,
                                       true);
  }
}


void QuickCheckDetails::Clear() {
  for (int i = 0; i < characters_; i++) {
    positions_[i].mask = 0;
    positions_[i].value = 0;
    positions_[i].determines_perfectly = false;
  }
  characters_ = 0;
}


void QuickCheckDetails::Advance(intptr_t by, bool one_byte) {
  ASSERT(by >= 0);
  if (by >= characters_) {
    Clear();
    return;
  }
  for (intptr_t i = 0; i < characters_ - by; i++) {
    positions_[i] = positions_[by + i];
  }
  for (intptr_t i = characters_ - by; i < characters_; i++) {
    positions_[i].mask = 0;
    positions_[i].value = 0;
    positions_[i].determines_perfectly = false;
  }
  characters_ -= by;
  // We could change mask_ and value_ here but we would never advance unless
  // they had already been used in a check and they won't be used again because
  // it would gain us nothing.  So there's no point.
}


void QuickCheckDetails::Merge(QuickCheckDetails* other, intptr_t from_index) {
  ASSERT(characters_ == other->characters_);
  if (other->cannot_match_) {
    return;
  }
  if (cannot_match_) {
    *this = *other;
    return;
  }
  for (intptr_t i = from_index; i < characters_; i++) {
    QuickCheckDetails::Position* pos = positions(i);
    QuickCheckDetails::Position* other_pos = other->positions(i);
    if (pos->mask != other_pos->mask || pos->value != other_pos->value ||
        !other_pos->determines_perfectly) {
      // Our mask-compare operation will be approximate unless we have the
      // exact same operation on both sides of the alternation.
      pos->determines_perfectly = false;
    }
    pos->mask &= other_pos->mask;
    pos->value &= pos->mask;
    other_pos->value &= pos->mask;
    uint16_t differing_bits = (pos->value ^ other_pos->value);
    pos->mask &= ~differing_bits;
    pos->value &= pos->mask;
  }
}


class VisitMarker : public ValueObject {
 public:
  explicit VisitMarker(NodeInfo* info) : info_(info) {
    ASSERT(!info->visited);
    info->visited = true;
  }
  ~VisitMarker() { info_->visited = false; }

 private:
  NodeInfo* info_;
};


RegExpNode* SeqRegExpNode::FilterOneByte(intptr_t depth, bool ignore_case) {
  if (info()->replacement_calculated) return replacement();
  if (depth < 0) return this;
  ASSERT(!info()->visited);
  VisitMarker marker(info());
  return FilterSuccessor(depth - 1, ignore_case);
}


RegExpNode* SeqRegExpNode::FilterSuccessor(intptr_t depth, bool ignore_case) {
  RegExpNode* next = on_success_->FilterOneByte(depth - 1, ignore_case);
  if (next == NULL) return set_replacement(NULL);
  on_success_ = next;
  return set_replacement(this);
}


// We need to check for the following characters: 0x39c 0x3bc 0x178.
static inline bool RangeContainsLatin1Equivalents(CharacterRange range) {
  // TODO(dcarney): this could be a lot more efficient.
  return range.Contains(0x39c) || range.Contains(0x3bc) ||
         range.Contains(0x178);
}


static bool RangesContainLatin1Equivalents(
    ZoneGrowableArray<CharacterRange>* ranges) {
  for (intptr_t i = 0; i < ranges->length(); i++) {
    // TODO(dcarney): this could be a lot more efficient.
    if (RangeContainsLatin1Equivalents(ranges->At(i))) return true;
  }
  return false;
}


static uint16_t ConvertNonLatin1ToLatin1(uint16_t c) {
  ASSERT(c > Symbols::kMaxOneCharCodeSymbol);
  switch (c) {
    // This are equivalent characters in unicode.
    case 0x39c:
    case 0x3bc:
      return 0xb5;
    // This is an uppercase of a Latin-1 character
    // outside of Latin-1.
    case 0x178:
      return 0xff;
  }
  return 0;
}


RegExpNode* TextNode::FilterOneByte(intptr_t depth, bool ignore_case) {
  if (info()->replacement_calculated) return replacement();
  if (depth < 0) return this;
  ASSERT(!info()->visited);
  VisitMarker marker(info());
  intptr_t element_count = elms_->length();
  for (intptr_t i = 0; i < element_count; i++) {
    TextElement elm = elms_->At(i);
    if (elm.text_type() == TextElement::ATOM) {
      ZoneGrowableArray<uint16_t>* quarks = elm.atom()->data();
      for (intptr_t j = 0; j < quarks->length(); j++) {
        uint16_t c = quarks->At(j);
        if (c <= Symbols::kMaxOneCharCodeSymbol) continue;
        if (!ignore_case) return set_replacement(NULL);
        // Here, we need to check for characters whose upper and lower cases
        // are outside the Latin-1 range.
        uint16_t converted = ConvertNonLatin1ToLatin1(c);
        // Character is outside Latin-1 completely
        if (converted == 0) return set_replacement(NULL);
        // Convert quark to Latin-1 in place.
        (*quarks)[0] = converted;
      }
    } else {
      ASSERT(elm.text_type() == TextElement::CHAR_CLASS);
      RegExpCharacterClass* cc = elm.char_class();
      ZoneGrowableArray<CharacterRange>* ranges = cc->ranges();
      if (!CharacterRange::IsCanonical(ranges)) {
        CharacterRange::Canonicalize(ranges);
      }
      // Now they are in order so we only need to look at the first.
      intptr_t range_count = ranges->length();
      if (cc->is_negated()) {
        if (range_count != 0 && ranges->At(0).from() == 0 &&
            ranges->At(0).to() >= Symbols::kMaxOneCharCodeSymbol) {
          // This will be handled in a later filter.
          if (ignore_case && RangesContainLatin1Equivalents(ranges)) continue;
          return set_replacement(NULL);
        }
      } else {
        if (range_count == 0 ||
            ranges->At(0).from() > Symbols::kMaxOneCharCodeSymbol) {
          // This will be handled in a later filter.
          if (ignore_case && RangesContainLatin1Equivalents(ranges)) continue;
          return set_replacement(NULL);
        }
      }
    }
  }
  return FilterSuccessor(depth - 1, ignore_case);
}


RegExpNode* LoopChoiceNode::FilterOneByte(intptr_t depth, bool ignore_case) {
  if (info()->replacement_calculated) return replacement();
  if (depth < 0) return this;
  if (info()->visited) return this;
  {
    VisitMarker marker(info());

    RegExpNode* continue_replacement =
        continue_node_->FilterOneByte(depth - 1, ignore_case);
    // If we can't continue after the loop then there is no sense in doing the
    // loop.
    if (continue_replacement == NULL) return set_replacement(NULL);
  }

  return ChoiceNode::FilterOneByte(depth - 1, ignore_case);
}


RegExpNode* ChoiceNode::FilterOneByte(intptr_t depth, bool ignore_case) {
  if (info()->replacement_calculated) return replacement();
  if (depth < 0) return this;
  if (info()->visited) return this;
  VisitMarker marker(info());
  intptr_t choice_count = alternatives_->length();

  for (intptr_t i = 0; i < choice_count; i++) {
    GuardedAlternative alternative = alternatives_->At(i);
    if (alternative.guards() != NULL && alternative.guards()->length() != 0) {
      set_replacement(this);
      return this;
    }
  }

  intptr_t surviving = 0;
  RegExpNode* survivor = NULL;
  for (intptr_t i = 0; i < choice_count; i++) {
    GuardedAlternative alternative = alternatives_->At(i);
    RegExpNode* replacement =
        alternative.node()->FilterOneByte(depth - 1, ignore_case);
    ASSERT(replacement != this);  // No missing EMPTY_MATCH_CHECK.
    if (replacement != NULL) {
      (*alternatives_)[i].set_node(replacement);
      surviving++;
      survivor = replacement;
    }
  }
  if (surviving < 2) return set_replacement(survivor);

  set_replacement(this);
  if (surviving == choice_count) {
    return this;
  }
  // Only some of the nodes survived the filtering.  We need to rebuild the
  // alternatives list.
  ZoneGrowableArray<GuardedAlternative>* new_alternatives =
      new (Z) ZoneGrowableArray<GuardedAlternative>(surviving);
  for (intptr_t i = 0; i < choice_count; i++) {
    RegExpNode* replacement =
        (*alternatives_)[i].node()->FilterOneByte(depth - 1, ignore_case);
    if (replacement != NULL) {
      (*alternatives_)[i].set_node(replacement);
      new_alternatives->Add((*alternatives_)[i]);
    }
  }
  alternatives_ = new_alternatives;
  return this;
}


RegExpNode* NegativeLookaheadChoiceNode::FilterOneByte(intptr_t depth,
                                                       bool ignore_case) {
  if (info()->replacement_calculated) return replacement();
  if (depth < 0) return this;
  if (info()->visited) return this;
  VisitMarker marker(info());
  // Alternative 0 is the negative lookahead, alternative 1 is what comes
  // afterwards.
  RegExpNode* node = (*alternatives_)[1].node();
  RegExpNode* replacement = node->FilterOneByte(depth - 1, ignore_case);
  if (replacement == NULL) return set_replacement(NULL);
  (*alternatives_)[1].set_node(replacement);

  RegExpNode* neg_node = (*alternatives_)[0].node();
  RegExpNode* neg_replacement = neg_node->FilterOneByte(depth - 1, ignore_case);
  // If the negative lookahead is always going to fail then
  // we don't need to check it.
  if (neg_replacement == NULL) return set_replacement(replacement);
  (*alternatives_)[0].set_node(neg_replacement);
  return set_replacement(this);
}


void LoopChoiceNode::GetQuickCheckDetails(QuickCheckDetails* details,
                                          RegExpCompiler* compiler,
                                          intptr_t characters_filled_in,
                                          bool not_at_start) {
  if (body_can_be_zero_length_ || info()->visited) return;
  VisitMarker marker(info());
  return ChoiceNode::GetQuickCheckDetails(details, compiler,
                                          characters_filled_in, not_at_start);
}


void LoopChoiceNode::FillInBMInfo(intptr_t offset,
                                  intptr_t budget,
                                  BoyerMooreLookahead* bm,
                                  bool not_at_start) {
  if (body_can_be_zero_length_ || budget <= 0) {
    bm->SetRest(offset);
    SaveBMInfo(bm, not_at_start, offset);
    return;
  }
  ChoiceNode::FillInBMInfo(offset, budget - 1, bm, not_at_start);
  SaveBMInfo(bm, not_at_start, offset);
}


void ChoiceNode::GetQuickCheckDetails(QuickCheckDetails* details,
                                      RegExpCompiler* compiler,
                                      intptr_t characters_filled_in,
                                      bool not_at_start) {
  not_at_start = (not_at_start || not_at_start_);
  intptr_t choice_count = alternatives_->length();
  ASSERT(choice_count > 0);
  (*alternatives_)[0].node()->GetQuickCheckDetails(
      details, compiler, characters_filled_in, not_at_start);
  for (intptr_t i = 1; i < choice_count; i++) {
    QuickCheckDetails new_details(details->characters());
    RegExpNode* node = (*alternatives_)[i].node();
    node->GetQuickCheckDetails(&new_details, compiler, characters_filled_in,
                               not_at_start);
    // Here we merge the quick match details of the two branches.
    details->Merge(&new_details, characters_filled_in);
  }
}


// Check for [0-9A-Z_a-z].
static void EmitWordCheck(RegExpMacroAssembler* assembler,
                          BlockLabel* word,
                          BlockLabel* non_word,
                          bool fall_through_on_word) {
  if (assembler->CheckSpecialCharacterClass(
          fall_through_on_word ? 'w' : 'W',
          fall_through_on_word ? non_word : word)) {
    // Optimized implementation available.
    return;
  }
  assembler->CheckCharacterGT('z', non_word);
  assembler->CheckCharacterLT('0', non_word);
  assembler->CheckCharacterGT('a' - 1, word);
  assembler->CheckCharacterLT('9' + 1, word);
  assembler->CheckCharacterLT('A', non_word);
  assembler->CheckCharacterLT('Z' + 1, word);
  if (fall_through_on_word) {
    assembler->CheckNotCharacter('_', non_word);
  } else {
    assembler->CheckCharacter('_', word);
  }
}


// Emit the code to check for a ^ in multiline mode (1-character lookbehind
// that matches newline or the start of input).
static void EmitHat(RegExpCompiler* compiler,
                    RegExpNode* on_success,
                    Trace* trace) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  // We will be loading the previous character into the current character
  // register.
  Trace new_trace(*trace);
  new_trace.InvalidateCurrentCharacter();

  BlockLabel ok;
  if (new_trace.cp_offset() == 0) {
    // The start of input counts as a newline in this context, so skip to
    // ok if we are at the start.
    assembler->CheckAtStart(&ok);
  }
  // We already checked that we are not at the start of input so it must be
  // OK to load the previous character.
  assembler->LoadCurrentCharacter(new_trace.cp_offset() - 1,
                                  new_trace.backtrack(), false);
  if (!assembler->CheckSpecialCharacterClass('n', new_trace.backtrack())) {
    // Newline means \n, \r, 0x2028 or 0x2029.
    if (!compiler->one_byte()) {
      assembler->CheckCharacterAfterAnd(0x2028, 0xfffe, &ok);
    }
    assembler->CheckCharacter('\n', &ok);
    assembler->CheckNotCharacter('\r', new_trace.backtrack());
  }
  assembler->BindBlock(&ok);
  on_success->Emit(compiler, &new_trace);
}


// Emit the code to handle \b and \B (word-boundary or non-word-boundary).
void AssertionNode::EmitBoundaryCheck(RegExpCompiler* compiler, Trace* trace) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  Trace::TriBool next_is_word_character = Trace::UNKNOWN;
  bool not_at_start = (trace->at_start() == Trace::FALSE_VALUE);
  BoyerMooreLookahead* lookahead = bm_info(not_at_start);
  if (lookahead == NULL) {
    intptr_t eats_at_least =
        Utils::Minimum(kMaxLookaheadForBoyerMoore,
                       EatsAtLeast(kMaxLookaheadForBoyerMoore, kRecursionBudget,
                                   not_at_start));
    if (eats_at_least >= 1) {
      BoyerMooreLookahead* bm =
          new (Z) BoyerMooreLookahead(eats_at_least, compiler, Z);
      FillInBMInfo(0, kRecursionBudget, bm, not_at_start);
      if (bm->at(0)->is_non_word()) next_is_word_character = Trace::FALSE_VALUE;
      if (bm->at(0)->is_word()) next_is_word_character = Trace::TRUE_VALUE;
    }
  } else {
    if (lookahead->at(0)->is_non_word())
      next_is_word_character = Trace::FALSE_VALUE;
    if (lookahead->at(0)->is_word()) next_is_word_character = Trace::TRUE_VALUE;
  }
  bool at_boundary = (assertion_type_ == AssertionNode::AT_BOUNDARY);
  if (next_is_word_character == Trace::UNKNOWN) {
    BlockLabel before_non_word;
    BlockLabel before_word;
    if (trace->characters_preloaded() != 1) {
      assembler->LoadCurrentCharacter(trace->cp_offset(), &before_non_word);
    }
    // Fall through on non-word.
    EmitWordCheck(assembler, &before_word, &before_non_word, false);
    // Next character is not a word character.
    assembler->BindBlock(&before_non_word);
    BlockLabel ok;
    // Backtrack on \B (non-boundary check) if previous is a word,
    // since we know next *is not* a word and this would be a boundary.
    BacktrackIfPrevious(compiler, trace, at_boundary ? kIsNonWord : kIsWord);

    if (!assembler->IsClosed()) {
      assembler->GoTo(&ok);
    }

    assembler->BindBlock(&before_word);
    BacktrackIfPrevious(compiler, trace, at_boundary ? kIsWord : kIsNonWord);
    assembler->BindBlock(&ok);
  } else if (next_is_word_character == Trace::TRUE_VALUE) {
    BacktrackIfPrevious(compiler, trace, at_boundary ? kIsWord : kIsNonWord);
  } else {
    ASSERT(next_is_word_character == Trace::FALSE_VALUE);
    BacktrackIfPrevious(compiler, trace, at_boundary ? kIsNonWord : kIsWord);
  }
}


void AssertionNode::BacktrackIfPrevious(
    RegExpCompiler* compiler,
    Trace* trace,
    AssertionNode::IfPrevious backtrack_if_previous) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  Trace new_trace(*trace);
  new_trace.InvalidateCurrentCharacter();

  BlockLabel fall_through, dummy;

  BlockLabel* non_word = backtrack_if_previous == kIsNonWord
                             ? new_trace.backtrack()
                             : &fall_through;
  BlockLabel* word = backtrack_if_previous == kIsNonWord
                         ? &fall_through
                         : new_trace.backtrack();

  if (new_trace.cp_offset() == 0) {
    // The start of input counts as a non-word character, so the question is
    // decided if we are at the start.
    assembler->CheckAtStart(non_word);
  }
  // We already checked that we are not at the start of input so it must be
  // OK to load the previous character.
  assembler->LoadCurrentCharacter(new_trace.cp_offset() - 1, &dummy, false);
  EmitWordCheck(assembler, word, non_word, backtrack_if_previous == kIsNonWord);

  assembler->BindBlock(&fall_through);
  on_success()->Emit(compiler, &new_trace);
}


void AssertionNode::GetQuickCheckDetails(QuickCheckDetails* details,
                                         RegExpCompiler* compiler,
                                         intptr_t filled_in,
                                         bool not_at_start) {
  if (assertion_type_ == AT_START && not_at_start) {
    details->set_cannot_match();
    return;
  }
  return on_success()->GetQuickCheckDetails(details, compiler, filled_in,
                                            not_at_start);
}


void AssertionNode::Emit(RegExpCompiler* compiler, Trace* trace) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  switch (assertion_type_) {
    case AT_END: {
      BlockLabel ok;
      assembler->CheckPosition(trace->cp_offset(), &ok);
      assembler->GoTo(trace->backtrack());
      assembler->BindBlock(&ok);
      break;
    }
    case AT_START: {
      if (trace->at_start() == Trace::FALSE_VALUE) {
        assembler->GoTo(trace->backtrack());
        return;
      }
      if (trace->at_start() == Trace::UNKNOWN) {
        assembler->CheckNotAtStart(trace->backtrack());
        Trace at_start_trace = *trace;
        at_start_trace.set_at_start(true);
        on_success()->Emit(compiler, &at_start_trace);
        return;
      }
    } break;
    case AFTER_NEWLINE:
      EmitHat(compiler, on_success(), trace);
      return;
    case AT_BOUNDARY:
    case AT_NON_BOUNDARY: {
      EmitBoundaryCheck(compiler, trace);
      return;
    }
  }
  on_success()->Emit(compiler, trace);
}


static bool DeterminedAlready(QuickCheckDetails* quick_check, intptr_t offset) {
  if (quick_check == NULL) return false;
  if (offset >= quick_check->characters()) return false;
  return quick_check->positions(offset)->determines_perfectly;
}


static void UpdateBoundsCheck(intptr_t index, intptr_t* checked_up_to) {
  if (index > *checked_up_to) {
    *checked_up_to = index;
  }
}


// We call this repeatedly to generate code for each pass over the text node.
// The passes are in increasing order of difficulty because we hope one
// of the first passes will fail in which case we are saved the work of the
// later passes.  for example for the case independent regexp /%[asdfghjkl]a/
// we will check the '%' in the first pass, the case independent 'a' in the
// second pass and the character class in the last pass.
//
// The passes are done from right to left, so for example to test for /bar/
// we will first test for an 'r' with offset 2, then an 'a' with offset 1
// and then a 'b' with offset 0.  This means we can avoid the end-of-input
// bounds check most of the time.  In the example we only need to check for
// end-of-input when loading the putative 'r'.
//
// A slight complication involves the fact that the first character may already
// be fetched into a register by the previous node.  In this case we want to
// do the test for that character first.  We do this in separate passes.  The
// 'preloaded' argument indicates that we are doing such a 'pass'.  If such a
// pass has been performed then subsequent passes will have true in
// first_element_checked to indicate that that character does not need to be
// checked again.
//
// In addition to all this we are passed a Trace, which can
// contain an AlternativeGeneration object.  In this AlternativeGeneration
// object we can see details of any quick check that was already passed in
// order to get to the code we are now generating.  The quick check can involve
// loading characters, which means we do not need to recheck the bounds
// up to the limit the quick check already checked.  In addition the quick
// check can have involved a mask and compare operation which may simplify
// or obviate the need for further checks at some character positions.
void TextNode::TextEmitPass(RegExpCompiler* compiler,
                            TextEmitPassType pass,
                            bool preloaded,
                            Trace* trace,
                            bool first_element_checked,
                            intptr_t* checked_up_to) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  bool one_byte = compiler->one_byte();
  BlockLabel* backtrack = trace->backtrack();
  QuickCheckDetails* quick_check = trace->quick_check_performed();
  intptr_t element_count = elms_->length();
  for (intptr_t i = preloaded ? 0 : element_count - 1; i >= 0; i--) {
    TextElement elm = elms_->At(i);
    intptr_t cp_offset = trace->cp_offset() + elm.cp_offset();
    if (elm.text_type() == TextElement::ATOM) {
      ZoneGrowableArray<uint16_t>* quarks = elm.atom()->data();
      for (intptr_t j = preloaded ? 0 : quarks->length() - 1; j >= 0; j--) {
        if (first_element_checked && i == 0 && j == 0) continue;
        if (DeterminedAlready(quick_check, elm.cp_offset() + j)) continue;
        EmitCharacterFunction* emit_function = NULL;
        switch (pass) {
          case NON_LATIN1_MATCH:
            ASSERT(one_byte);
            if (quarks->At(j) > Symbols::kMaxOneCharCodeSymbol) {
              assembler->GoTo(backtrack);
              return;
            }
            break;
          case NON_LETTER_CHARACTER_MATCH:
            emit_function = &EmitAtomNonLetter;
            break;
          case SIMPLE_CHARACTER_MATCH:
            emit_function = &EmitSimpleCharacter;
            break;
          case CASE_CHARACTER_MATCH:
            emit_function = &EmitAtomLetter;
            break;
          default:
            break;
        }
        if (emit_function != NULL) {
          bool bound_checked = emit_function(
              Z, compiler, quarks->At(j), backtrack, cp_offset + j,
              *checked_up_to < cp_offset + j, preloaded);
          if (bound_checked) UpdateBoundsCheck(cp_offset + j, checked_up_to);
        }
      }
    } else {
      ASSERT(elm.text_type() == TextElement::CHAR_CLASS);
      if (pass == CHARACTER_CLASS_MATCH) {
        if (first_element_checked && i == 0) continue;
        if (DeterminedAlready(quick_check, elm.cp_offset())) continue;
        RegExpCharacterClass* cc = elm.char_class();
        EmitCharClass(assembler, cc, one_byte, backtrack, cp_offset,
                      *checked_up_to < cp_offset, preloaded, Z);
        UpdateBoundsCheck(cp_offset, checked_up_to);
      }
    }
  }
}


intptr_t TextNode::Length() {
  TextElement elm = elms_->Last();
  ASSERT(elm.cp_offset() >= 0);
  return elm.cp_offset() + elm.length();
}


bool TextNode::SkipPass(intptr_t intptr_t_pass, bool ignore_case) {
  TextEmitPassType pass = static_cast<TextEmitPassType>(intptr_t_pass);
  if (ignore_case) {
    return pass == SIMPLE_CHARACTER_MATCH;
  } else {
    return pass == NON_LETTER_CHARACTER_MATCH || pass == CASE_CHARACTER_MATCH;
  }
}


// This generates the code to match a text node.  A text node can contain
// straight character sequences (possibly to be matched in a case-independent
// way) and character classes.  For efficiency we do not do this in a single
// pass from left to right.  Instead we pass over the text node several times,
// emitting code for some character positions every time.  See the comment on
// TextEmitPass for details.
void TextNode::Emit(RegExpCompiler* compiler, Trace* trace) {
  LimitResult limit_result = LimitVersions(compiler, trace);
  if (limit_result == DONE) return;
  ASSERT(limit_result == CONTINUE);

  if (trace->cp_offset() + Length() > RegExpMacroAssembler::kMaxCPOffset) {
    compiler->SetRegExpTooBig();
    return;
  }

  if (compiler->one_byte()) {
    intptr_t dummy = 0;
    TextEmitPass(compiler, NON_LATIN1_MATCH, false, trace, false, &dummy);
  }

  bool first_elt_done = false;
  intptr_t bound_checked_to = trace->cp_offset() - 1;
  bound_checked_to += trace->bound_checked_up_to();

  // If a character is preloaded into the current character register then
  // check that now.
  if (trace->characters_preloaded() == 1) {
    for (intptr_t pass = kFirstRealPass; pass <= kLastPass; pass++) {
      if (!SkipPass(pass, compiler->ignore_case())) {
        TextEmitPass(compiler, static_cast<TextEmitPassType>(pass), true, trace,
                     false, &bound_checked_to);
      }
    }
    first_elt_done = true;
  }

  for (intptr_t pass = kFirstRealPass; pass <= kLastPass; pass++) {
    if (!SkipPass(pass, compiler->ignore_case())) {
      TextEmitPass(compiler, static_cast<TextEmitPassType>(pass), false, trace,
                   first_elt_done, &bound_checked_to);
    }
  }

  Trace successor_trace(*trace);
  successor_trace.set_at_start(false);
  successor_trace.AdvanceCurrentPositionInTrace(Length(), compiler);
  RecursionCheck rc(compiler);
  on_success()->Emit(compiler, &successor_trace);
}


void Trace::InvalidateCurrentCharacter() {
  characters_preloaded_ = 0;
}


void Trace::AdvanceCurrentPositionInTrace(intptr_t by,
                                          RegExpCompiler* compiler) {
  ASSERT(by > 0);
  // We don't have an instruction for shifting the current character register
  // down or for using a shifted value for anything so lets just forget that
  // we preloaded any characters into it.
  characters_preloaded_ = 0;
  // Adjust the offsets of the quick check performed information.  This
  // information is used to find out what we already determined about the
  // characters by means of mask and compare.
  quick_check_performed_.Advance(by, compiler->one_byte());
  cp_offset_ += by;
  if (cp_offset_ > RegExpMacroAssembler::kMaxCPOffset) {
    compiler->SetRegExpTooBig();
    cp_offset_ = 0;
  }
  bound_checked_up_to_ =
      Utils::Maximum(static_cast<intptr_t>(0), bound_checked_up_to_ - by);
}


void TextNode::MakeCaseIndependent(bool is_one_byte) {
  intptr_t element_count = elms_->length();
  for (intptr_t i = 0; i < element_count; i++) {
    TextElement elm = elms_->At(i);
    if (elm.text_type() == TextElement::CHAR_CLASS) {
      RegExpCharacterClass* cc = elm.char_class();
      // None of the standard character classes is different in the case
      // independent case and it slows us down if we don't know that.
      if (cc->is_standard()) continue;
      ZoneGrowableArray<CharacterRange>* ranges = cc->ranges();
      intptr_t range_count = ranges->length();
      for (intptr_t j = 0; j < range_count; j++) {
        (*ranges)[j].AddCaseEquivalents(ranges, is_one_byte, Z);
      }
    }
  }
}


intptr_t TextNode::GreedyLoopTextLength() {
  TextElement elm = elms_->At(elms_->length() - 1);
  return elm.cp_offset() + elm.length();
}


RegExpNode* TextNode::GetSuccessorOfOmnivorousTextNode(
    RegExpCompiler* compiler) {
  if (elms_->length() != 1) return NULL;
  TextElement elm = elms_->At(0);
  if (elm.text_type() != TextElement::CHAR_CLASS) return NULL;
  RegExpCharacterClass* node = elm.char_class();
  ZoneGrowableArray<CharacterRange>* ranges = node->ranges();
  if (!CharacterRange::IsCanonical(ranges)) {
    CharacterRange::Canonicalize(ranges);
  }
  if (node->is_negated()) {
    return ranges->length() == 0 ? on_success() : NULL;
  }
  if (ranges->length() != 1) return NULL;
  uint32_t max_char;
  if (compiler->one_byte()) {
    max_char = Symbols::kMaxOneCharCodeSymbol;
  } else {
    max_char = Utf16::kMaxCodeUnit;
  }
  return ranges->At(0).IsEverything(max_char) ? on_success() : NULL;
}


// Finds the fixed match length of a sequence of nodes that goes from
// this alternative and back to this choice node.  If there are variable
// length nodes or other complications in the way then return a sentinel
// value indicating that a greedy loop cannot be constructed.
intptr_t ChoiceNode::GreedyLoopTextLengthForAlternative(
    GuardedAlternative* alternative) {
  intptr_t length = 0;
  RegExpNode* node = alternative->node();
  // Later we will generate code for all these text nodes using recursion
  // so we have to limit the max number.
  intptr_t recursion_depth = 0;
  while (node != this) {
    if (recursion_depth++ > RegExpCompiler::kMaxRecursion) {
      return kNodeIsTooComplexForGreedyLoops;
    }
    intptr_t node_length = node->GreedyLoopTextLength();
    if (node_length == kNodeIsTooComplexForGreedyLoops) {
      return kNodeIsTooComplexForGreedyLoops;
    }
    length += node_length;
    SeqRegExpNode* seq_node = static_cast<SeqRegExpNode*>(node);
    node = seq_node->on_success();
  }
  return length;
}


void LoopChoiceNode::AddLoopAlternative(GuardedAlternative alt) {
  ASSERT(loop_node_ == NULL);
  AddAlternative(alt);
  loop_node_ = alt.node();
}


void LoopChoiceNode::AddContinueAlternative(GuardedAlternative alt) {
  ASSERT(continue_node_ == NULL);
  AddAlternative(alt);
  continue_node_ = alt.node();
}


void LoopChoiceNode::Emit(RegExpCompiler* compiler, Trace* trace) {
  RegExpMacroAssembler* macro_assembler = compiler->macro_assembler();
  if (trace->stop_node() == this) {
    // Back edge of greedy optimized loop node graph.
    intptr_t text_length =
        GreedyLoopTextLengthForAlternative(&((*alternatives_)[0]));
    ASSERT(text_length != kNodeIsTooComplexForGreedyLoops);
    // Update the counter-based backtracking info on the stack.  This is an
    // optimization for greedy loops (see below).
    ASSERT(trace->cp_offset() == text_length);
    macro_assembler->AdvanceCurrentPosition(text_length);
    macro_assembler->GoTo(trace->loop_label());
    return;
  }
  ASSERT(trace->stop_node() == NULL);
  if (!trace->is_trivial()) {
    trace->Flush(compiler, this);
    return;
  }
  ChoiceNode::Emit(compiler, trace);
}


intptr_t ChoiceNode::CalculatePreloadCharacters(RegExpCompiler* compiler,
                                                intptr_t eats_at_least) {
  intptr_t preload_characters =
      Utils::Minimum(static_cast<intptr_t>(4), eats_at_least);
  if (compiler->macro_assembler()->CanReadUnaligned()) {
    bool one_byte = compiler->one_byte();
    if (one_byte) {
      if (preload_characters > 4) preload_characters = 4;
      // We can't preload 3 characters because there is no machine instruction
      // to do that.  We can't just load 4 because we could be reading
      // beyond the end of the string, which could cause a memory fault.
      if (preload_characters == 3) preload_characters = 2;
    } else {
      if (preload_characters > 2) preload_characters = 2;
    }
  } else {
    if (preload_characters > 1) preload_characters = 1;
  }
  return preload_characters;
}


// This structure is used when generating the alternatives in a choice node.  It
// records the way the alternative is being code generated.
struct AlternativeGeneration {
  AlternativeGeneration()
      : possible_success(),
        expects_preload(false),
        after(),
        quick_check_details() {}
  BlockLabel possible_success;
  bool expects_preload;
  BlockLabel after;
  QuickCheckDetails quick_check_details;
};


// Creates a list of AlternativeGenerations.  If the list has a reasonable
// size then it is on the stack, otherwise the excess is on the heap.
class AlternativeGenerationList {
 public:
  explicit AlternativeGenerationList(intptr_t count) : alt_gens_(count) {
    for (intptr_t i = 0; i < count && i < kAFew; i++) {
      alt_gens_.Add(a_few_alt_gens_ + i);
    }
    for (intptr_t i = kAFew; i < count; i++) {
      alt_gens_.Add(new AlternativeGeneration());
    }
  }
  ~AlternativeGenerationList() {
    for (intptr_t i = kAFew; i < alt_gens_.length(); i++) {
      delete alt_gens_[i];
      alt_gens_[i] = NULL;
    }
  }

  AlternativeGeneration* at(intptr_t i) { return alt_gens_[i]; }

 private:
  static const intptr_t kAFew = 10;
  GrowableArray<AlternativeGeneration*> alt_gens_;
  AlternativeGeneration a_few_alt_gens_[kAFew];

  DISALLOW_ALLOCATION();
};


// The '2' variant is inclusive from and exclusive to.
// This covers \s as defined in ECMA-262 5.1, 15.10.2.12,
// which include WhiteSpace (7.2) or LineTerminator (7.3) values.
static const intptr_t kSpaceRanges[] = {
    '\t',   '\r' + 1, ' ',    ' ' + 1, 0x00A0, 0x00A1, 0x1680, 0x1681,
    0x180E, 0x180F,   0x2000, 0x200B,  0x2028, 0x202A, 0x202F, 0x2030,
    0x205F, 0x2060,   0x3000, 0x3001,  0xFEFF, 0xFF00, 0x10000};
static const intptr_t kSpaceRangeCount = ARRAY_SIZE(kSpaceRanges);
static const intptr_t kWordRanges[] = {'0',     '9' + 1, 'A',     'Z' + 1, '_',
                                       '_' + 1, 'a',     'z' + 1, 0x10000};
static const intptr_t kWordRangeCount = ARRAY_SIZE(kWordRanges);
static const intptr_t kDigitRanges[] = {'0', '9' + 1, 0x10000};
static const intptr_t kDigitRangeCount = ARRAY_SIZE(kDigitRanges);
static const intptr_t kSurrogateRanges[] = {0xd800, 0xe000, 0x10000};
static const intptr_t kSurrogateRangeCount = ARRAY_SIZE(kSurrogateRanges);
static const intptr_t kLineTerminatorRanges[] = {0x000A, 0x000B, 0x000D, 0x000E,
                                                 0x2028, 0x202A, 0x10000};
static const intptr_t kLineTerminatorRangeCount =
    ARRAY_SIZE(kLineTerminatorRanges);


void BoyerMoorePositionInfo::Set(intptr_t character) {
  SetInterval(Interval(character, character));
}


void BoyerMoorePositionInfo::SetInterval(const Interval& interval) {
  s_ = AddRange(s_, kSpaceRanges, kSpaceRangeCount, interval);
  w_ = AddRange(w_, kWordRanges, kWordRangeCount, interval);
  d_ = AddRange(d_, kDigitRanges, kDigitRangeCount, interval);
  surrogate_ =
      AddRange(surrogate_, kSurrogateRanges, kSurrogateRangeCount, interval);
  if (interval.to() - interval.from() >= kMapSize - 1) {
    if (map_count_ != kMapSize) {
      map_count_ = kMapSize;
      for (intptr_t i = 0; i < kMapSize; i++)
        (*map_)[i] = true;
    }
    return;
  }
  for (intptr_t i = interval.from(); i <= interval.to(); i++) {
    intptr_t mod_character = (i & kMask);
    if (!map_->At(mod_character)) {
      map_count_++;
      (*map_)[mod_character] = true;
    }
    if (map_count_ == kMapSize) return;
  }
}


void BoyerMoorePositionInfo::SetAll() {
  s_ = w_ = d_ = kLatticeUnknown;
  if (map_count_ != kMapSize) {
    map_count_ = kMapSize;
    for (intptr_t i = 0; i < kMapSize; i++)
      (*map_)[i] = true;
  }
}


BoyerMooreLookahead::BoyerMooreLookahead(intptr_t length,
                                         RegExpCompiler* compiler,
                                         Zone* zone)
    : length_(length), compiler_(compiler) {
  if (compiler->one_byte()) {
    max_char_ = Symbols::kMaxOneCharCodeSymbol;
  } else {
    max_char_ = Utf16::kMaxCodeUnit;
  }
  bitmaps_ = new (zone) ZoneGrowableArray<BoyerMoorePositionInfo*>(length);
  for (intptr_t i = 0; i < length; i++) {
    bitmaps_->Add(new (zone) BoyerMoorePositionInfo(zone));
  }
}


// Find the longest range of lookahead that has the fewest number of different
// characters that can occur at a given position.  Since we are optimizing two
// different parameters at once this is a tradeoff.
bool BoyerMooreLookahead::FindWorthwhileInterval(intptr_t* from, intptr_t* to) {
  intptr_t biggest_points = 0;
  // If more than 32 characters out of 128 can occur it is unlikely that we can
  // be lucky enough to step forwards much of the time.
  const intptr_t kMaxMax = 32;
  for (intptr_t max_number_of_chars = 4; max_number_of_chars < kMaxMax;
       max_number_of_chars *= 2) {
    biggest_points =
        FindBestInterval(max_number_of_chars, biggest_points, from, to);
  }
  if (biggest_points == 0) return false;
  return true;
}


// Find the highest-points range between 0 and length_ where the character
// information is not too vague.  'Too vague' means that there are more than
// max_number_of_chars that can occur at this position.  Calculates the number
// of points as the product of width-of-the-range and
// probability-of-finding-one-of-the-characters, where the probability is
// calculated using the frequency distribution of the sample subject string.
intptr_t BoyerMooreLookahead::FindBestInterval(intptr_t max_number_of_chars,
                                               intptr_t old_biggest_points,
                                               intptr_t* from,
                                               intptr_t* to) {
  intptr_t biggest_points = old_biggest_points;
  static const intptr_t kSize = RegExpMacroAssembler::kTableSize;
  for (intptr_t i = 0; i < length_;) {
    while (i < length_ && Count(i) > max_number_of_chars)
      i++;
    if (i == length_) break;
    intptr_t remembered_from = i;
    bool union_map[kSize];
    for (intptr_t j = 0; j < kSize; j++)
      union_map[j] = false;
    while (i < length_ && Count(i) <= max_number_of_chars) {
      BoyerMoorePositionInfo* map = bitmaps_->At(i);
      for (intptr_t j = 0; j < kSize; j++)
        union_map[j] |= map->at(j);
      i++;
    }
    intptr_t frequency = 0;
    for (intptr_t j = 0; j < kSize; j++) {
      if (union_map[j]) {
        // Add 1 to the frequency to give a small per-character boost for
        // the cases where our sampling is not good enough and many
        // characters have a frequency of zero.  This means the frequency
        // can theoretically be up to 2*kSize though we treat it mostly as
        // a fraction of kSize.
        frequency += compiler_->frequency_collator()->Frequency(j) + 1;
      }
    }
    // We use the probability of skipping times the distance we are skipping to
    // judge the effectiveness of this.  Actually we have a cut-off:  By
    // dividing by 2 we switch off the skipping if the probability of skipping
    // is less than 50%.  This is because the multibyte mask-and-compare
    // skipping in quickcheck is more likely to do well on this case.
    bool in_quickcheck_range =
        ((i - remembered_from < 4) ||
         (compiler_->one_byte() ? remembered_from <= 4 : remembered_from <= 2));
    // Called 'probability' but it is only a rough estimate and can actually
    // be outside the 0-kSize range.
    intptr_t probability =
        (in_quickcheck_range ? kSize / 2 : kSize) - frequency;
    intptr_t points = (i - remembered_from) * probability;
    if (points > biggest_points) {
      *from = remembered_from;
      *to = i - 1;
      biggest_points = points;
    }
  }
  return biggest_points;
}


// Take all the characters that will not prevent a successful match if they
// occur in the subject string in the range between min_lookahead and
// max_lookahead (inclusive) measured from the current position.  If the
// character at max_lookahead offset is not one of these characters, then we
// can safely skip forwards by the number of characters in the range.
intptr_t BoyerMooreLookahead::GetSkipTable(
    intptr_t min_lookahead,
    intptr_t max_lookahead,
    const TypedData& boolean_skip_table) {
  const intptr_t kSize = RegExpMacroAssembler::kTableSize;

  const intptr_t kSkipArrayEntry = 0;
  const intptr_t kDontSkipArrayEntry = 1;

  for (intptr_t i = 0; i < kSize; i++) {
    boolean_skip_table.SetUint8(i, kSkipArrayEntry);
  }
  intptr_t skip = max_lookahead + 1 - min_lookahead;

  for (intptr_t i = max_lookahead; i >= min_lookahead; i--) {
    BoyerMoorePositionInfo* map = bitmaps_->At(i);
    for (intptr_t j = 0; j < kSize; j++) {
      if (map->at(j)) {
        boolean_skip_table.SetUint8(j, kDontSkipArrayEntry);
      }
    }
  }

  return skip;
}


// See comment above on the implementation of GetSkipTable.
void BoyerMooreLookahead::EmitSkipInstructions(RegExpMacroAssembler* masm) {
  const intptr_t kSize = RegExpMacroAssembler::kTableSize;

  intptr_t min_lookahead = 0;
  intptr_t max_lookahead = 0;

  if (!FindWorthwhileInterval(&min_lookahead, &max_lookahead)) return;

  bool found_single_character = false;
  intptr_t single_character = 0;
  for (intptr_t i = max_lookahead; i >= min_lookahead; i--) {
    BoyerMoorePositionInfo* map = bitmaps_->At(i);
    if (map->map_count() > 1 ||
        (found_single_character && map->map_count() != 0)) {
      found_single_character = false;
      break;
    }
    for (intptr_t j = 0; j < kSize; j++) {
      if (map->at(j)) {
        found_single_character = true;
        single_character = j;
        break;
      }
    }
  }

  intptr_t lookahead_width = max_lookahead + 1 - min_lookahead;

  if (found_single_character && lookahead_width == 1 && max_lookahead < 3) {
    // The mask-compare can probably handle this better.
    return;
  }

  if (found_single_character) {
    BlockLabel cont, again;
    masm->BindBlock(&again);
    masm->LoadCurrentCharacter(max_lookahead, &cont, true);
    if (max_char_ > kSize) {
      masm->CheckCharacterAfterAnd(single_character,
                                   RegExpMacroAssembler::kTableMask, &cont);
    } else {
      masm->CheckCharacter(single_character, &cont);
    }
    masm->AdvanceCurrentPosition(lookahead_width);
    masm->GoTo(&again);
    masm->BindBlock(&cont);
    return;
  }

  const TypedData& boolean_skip_table = TypedData::ZoneHandle(
      compiler_->zone(),
      TypedData::New(kTypedDataUint8ArrayCid, kSize, Heap::kOld));
  intptr_t skip_distance =
      GetSkipTable(min_lookahead, max_lookahead, boolean_skip_table);
  ASSERT(skip_distance != 0);

  BlockLabel cont, again;

  masm->BindBlock(&again);
  masm->CheckPreemption(/*is_backtrack=*/false);
  masm->LoadCurrentCharacter(max_lookahead, &cont, true);
  masm->CheckBitInTable(boolean_skip_table, &cont);
  masm->AdvanceCurrentPosition(skip_distance);
  masm->GoTo(&again);
  masm->BindBlock(&cont);

  return;
}


/* Code generation for choice nodes.
 *
 * We generate quick checks that do a mask and compare to eliminate a
 * choice.  If the quick check succeeds then it jumps to the continuation to
 * do slow checks and check subsequent nodes.  If it fails (the common case)
 * it falls through to the next choice.
 *
 * Here is the desired flow graph.  Nodes directly below each other imply
 * fallthrough.  Alternatives 1 and 2 have quick checks.  Alternative
 * 3 doesn't have a quick check so we have to call the slow check.
 * Nodes are marked Qn for quick checks and Sn for slow checks.  The entire
 * regexp continuation is generated directly after the Sn node, up to the
 * next GoTo if we decide to reuse some already generated code.  Some
 * nodes expect preload_characters to be preloaded into the current
 * character register.  R nodes do this preloading.  Vertices are marked
 * F for failures and S for success (possible success in the case of quick
 * nodes).  L, V, < and > are used as arrow heads.
 *
 * ----------> R
 *             |
 *             V
 *            Q1 -----> S1
 *             |   S   /
 *            F|      /
 *             |    F/
 *             |    /
 *             |   R
 *             |  /
 *             V L
 *            Q2 -----> S2
 *             |   S   /
 *            F|      /
 *             |    F/
 *             |    /
 *             |   R
 *             |  /
 *             V L
 *            S3
 *             |
 *            F|
 *             |
 *             R
 *             |
 * backtrack   V
 * <----------Q4
 *   \    F    |
 *    \        |S
 *     \   F   V
 *      \-----S4
 *
 * For greedy loops we push the current position, then generate the code that
 * eats the input specially in EmitGreedyLoop.  The other choice (the
 * continuation) is generated by the normal code in EmitChoices, and steps back
 * in the input to the starting position when it fails to match.  The loop code
 * looks like this (U is the unwind code that steps back in the greedy loop).
 *
 *              _____
 *             /     \
 *             V     |
 * ----------> S1    |
 *            /|     |
 *           / |S    |
 *         F/  \_____/
 *         /
 *        |<-----
 *        |      \
 *        V       |S
 *        Q2 ---> U----->backtrack
 *        |  F   /
 *       S|     /
 *        V  F /
 *        S2--/
 */

GreedyLoopState::GreedyLoopState(bool not_at_start) {
  counter_backtrack_trace_.set_backtrack(&label_);
  if (not_at_start) counter_backtrack_trace_.set_at_start(false);
}


void ChoiceNode::AssertGuardsMentionRegisters(Trace* trace) {
#ifdef DEBUG
  intptr_t choice_count = alternatives_->length();
  for (intptr_t i = 0; i < choice_count - 1; i++) {
    GuardedAlternative alternative = alternatives_->At(i);
    ZoneGrowableArray<Guard*>* guards = alternative.guards();
    intptr_t guard_count = (guards == NULL) ? 0 : guards->length();
    for (intptr_t j = 0; j < guard_count; j++) {
      ASSERT(!trace->mentions_reg(guards->At(j)->reg()));
    }
  }
#endif
}


void ChoiceNode::SetUpPreLoad(RegExpCompiler* compiler,
                              Trace* current_trace,
                              PreloadState* state) {
  if (state->eats_at_least_ == PreloadState::kEatsAtLeastNotYetInitialized) {
    // Save some time by looking at most one machine word ahead.
    state->eats_at_least_ =
        EatsAtLeast(compiler->one_byte() ? 4 : 2, kRecursionBudget,
                    current_trace->at_start() == Trace::FALSE_VALUE);
  }
  state->preload_characters_ =
      CalculatePreloadCharacters(compiler, state->eats_at_least_);

  state->preload_is_current_ =
      (current_trace->characters_preloaded() == state->preload_characters_);
  state->preload_has_checked_bounds_ = state->preload_is_current_;
}


void ChoiceNode::Emit(RegExpCompiler* compiler, Trace* trace) {
  intptr_t choice_count = alternatives_->length();

  AssertGuardsMentionRegisters(trace);

  LimitResult limit_result = LimitVersions(compiler, trace);
  if (limit_result == DONE) return;
  ASSERT(limit_result == CONTINUE);

  // For loop nodes we already flushed (see LoopChoiceNode::Emit), but for
  // other choice nodes we only flush if we are out of code size budget.
  if (trace->flush_budget() == 0 && trace->actions() != NULL) {
    trace->Flush(compiler, this);
    return;
  }

  RecursionCheck rc(compiler);

  PreloadState preload;
  preload.init();
  GreedyLoopState greedy_loop_state(not_at_start());

  intptr_t text_length =
      GreedyLoopTextLengthForAlternative(&((*alternatives_)[0]));
  AlternativeGenerationList alt_gens(choice_count);

  if (choice_count > 1 && text_length != kNodeIsTooComplexForGreedyLoops) {
    trace = EmitGreedyLoop(compiler, trace, &alt_gens, &preload,
                           &greedy_loop_state, text_length);
  } else {
    // TODO(erikcorry): Delete this.  We don't need this label, but it makes us
    // match the traces produced pre-cleanup.
    BlockLabel second_choice;
    compiler->macro_assembler()->BindBlock(&second_choice);

    preload.eats_at_least_ = EmitOptimizedUnanchoredSearch(compiler, trace);

    EmitChoices(compiler, &alt_gens, 0, trace, &preload);
  }

  // At this point we need to generate slow checks for the alternatives where
  // the quick check was inlined.  We can recognize these because the associated
  // label was bound.
  intptr_t new_flush_budget = trace->flush_budget() / choice_count;
  for (intptr_t i = 0; i < choice_count; i++) {
    AlternativeGeneration* alt_gen = alt_gens.at(i);
    Trace new_trace(*trace);
    // If there are actions to be flushed we have to limit how many times
    // they are flushed.  Take the budget of the parent trace and distribute
    // it fairly amongst the children.
    if (new_trace.actions() != NULL) {
      new_trace.set_flush_budget(new_flush_budget);
    }
    bool next_expects_preload =
        i == choice_count - 1 ? false : alt_gens.at(i + 1)->expects_preload;
    EmitOutOfLineContinuation(compiler, &new_trace, alternatives_->At(i),
                              alt_gen, preload.preload_characters_,
                              next_expects_preload);
  }
}

Trace* ChoiceNode::EmitGreedyLoop(RegExpCompiler* compiler,
                                  Trace* trace,
                                  AlternativeGenerationList* alt_gens,
                                  PreloadState* preload,
                                  GreedyLoopState* greedy_loop_state,
                                  intptr_t text_length) {
  RegExpMacroAssembler* macro_assembler = compiler->macro_assembler();
  // Here we have special handling for greedy loops containing only text nodes
  // and other simple nodes.  These are handled by pushing the current
  // position on the stack and then incrementing the current position each
  // time around the switch.  On backtrack we decrement the current position
  // and check it against the pushed value.  This avoids pushing backtrack
  // information for each iteration of the loop, which could take up a lot of
  // space.
  ASSERT(trace->stop_node() == NULL);
  macro_assembler->PushCurrentPosition();
  BlockLabel greedy_match_failed;
  Trace greedy_match_trace;
  if (not_at_start()) greedy_match_trace.set_at_start(false);
  greedy_match_trace.set_backtrack(&greedy_match_failed);
  BlockLabel loop_label;
  macro_assembler->BindBlock(&loop_label);
  macro_assembler->CheckPreemption(/*is_backtrack=*/false);
  greedy_match_trace.set_stop_node(this);
  greedy_match_trace.set_loop_label(&loop_label);
  (*alternatives_)[0].node()->Emit(compiler, &greedy_match_trace);
  macro_assembler->BindBlock(&greedy_match_failed);

  BlockLabel second_choice;  // For use in greedy matches.
  macro_assembler->BindBlock(&second_choice);

  Trace* new_trace = greedy_loop_state->counter_backtrack_trace();

  EmitChoices(compiler, alt_gens, 1, new_trace, preload);

  macro_assembler->BindBlock(greedy_loop_state->label());
  // If we have unwound to the bottom then backtrack.
  macro_assembler->CheckGreedyLoop(trace->backtrack());
  // Otherwise try the second priority at an earlier position.
  macro_assembler->AdvanceCurrentPosition(-text_length);
  macro_assembler->GoTo(&second_choice);
  return new_trace;
}


intptr_t ChoiceNode::EmitOptimizedUnanchoredSearch(RegExpCompiler* compiler,
                                                   Trace* trace) {
  intptr_t eats_at_least = PreloadState::kEatsAtLeastNotYetInitialized;
  if (alternatives_->length() != 2) return eats_at_least;

  GuardedAlternative alt1 = alternatives_->At(1);
  if (alt1.guards() != NULL && alt1.guards()->length() != 0) {
    return eats_at_least;
  }
  RegExpNode* eats_anything_node = alt1.node();
  if (eats_anything_node->GetSuccessorOfOmnivorousTextNode(compiler) != this) {
    return eats_at_least;
  }

  // Really we should be creating a new trace when we execute this function,
  // but there is no need, because the code it generates cannot backtrack, and
  // we always arrive here with a trivial trace (since it's the entry to a
  // loop.  That also implies that there are no preloaded characters, which is
  // good, because it means we won't be violating any assumptions by
  // overwriting those characters with new load instructions.
  ASSERT(trace->is_trivial());

  RegExpMacroAssembler* macro_assembler = compiler->macro_assembler();
  // At this point we know that we are at a non-greedy loop that will eat
  // any character one at a time.  Any non-anchored regexp has such a
  // loop prepended to it in order to find where it starts.  We look for
  // a pattern of the form ...abc... where we can look 6 characters ahead
  // and step forwards 3 if the character is not one of abc.  Abc need
  // not be atoms, they can be any reasonably limited character class or
  // small alternation.
  BoyerMooreLookahead* bm = bm_info(false);
  if (bm == NULL) {
    eats_at_least = Utils::Minimum(
        kMaxLookaheadForBoyerMoore,
        EatsAtLeast(kMaxLookaheadForBoyerMoore, kRecursionBudget, false));
    if (eats_at_least >= 1) {
      bm = new (Z) BoyerMooreLookahead(eats_at_least, compiler, Z);
      GuardedAlternative alt0 = alternatives_->At(0);
      alt0.node()->FillInBMInfo(0, kRecursionBudget, bm, false);
    }
  }
  if (bm != NULL) {
    bm->EmitSkipInstructions(macro_assembler);
  }
  return eats_at_least;
}


void ChoiceNode::EmitChoices(RegExpCompiler* compiler,
                             AlternativeGenerationList* alt_gens,
                             intptr_t first_choice,
                             Trace* trace,
                             PreloadState* preload) {
  RegExpMacroAssembler* macro_assembler = compiler->macro_assembler();
  SetUpPreLoad(compiler, trace, preload);

  // For now we just call all choices one after the other.  The idea ultimately
  // is to use the Dispatch table to try only the relevant ones.
  intptr_t choice_count = alternatives_->length();

  intptr_t new_flush_budget = trace->flush_budget() / choice_count;

  for (intptr_t i = first_choice; i < choice_count; i++) {
    bool is_last = i == choice_count - 1;
    bool fall_through_on_failure = !is_last;
    GuardedAlternative alternative = alternatives_->At(i);
    AlternativeGeneration* alt_gen = alt_gens->at(i);
    alt_gen->quick_check_details.set_characters(preload->preload_characters_);
    ZoneGrowableArray<Guard*>* guards = alternative.guards();
    intptr_t guard_count = (guards == NULL) ? 0 : guards->length();
    Trace new_trace(*trace);
    new_trace.set_characters_preloaded(
        preload->preload_is_current_ ? preload->preload_characters_ : 0);
    if (preload->preload_has_checked_bounds_) {
      new_trace.set_bound_checked_up_to(preload->preload_characters_);
    }
    new_trace.quick_check_performed()->Clear();
    if (not_at_start_) new_trace.set_at_start(Trace::FALSE_VALUE);
    if (!is_last) {
      new_trace.set_backtrack(&alt_gen->after);
    }
    alt_gen->expects_preload = preload->preload_is_current_;
    bool generate_full_check_inline = false;
    if (kRegexpOptimization &&
        try_to_emit_quick_check_for_alternative(i == 0) &&
        alternative.node()->EmitQuickCheck(
            compiler, trace, &new_trace, preload->preload_has_checked_bounds_,
            &alt_gen->possible_success, &alt_gen->quick_check_details,
            fall_through_on_failure)) {
      // Quick check was generated for this choice.
      preload->preload_is_current_ = true;
      preload->preload_has_checked_bounds_ = true;
      // If we generated the quick check to fall through on possible success,
      // we now need to generate the full check inline.
      if (!fall_through_on_failure) {
        macro_assembler->BindBlock(&alt_gen->possible_success);
        new_trace.set_quick_check_performed(&alt_gen->quick_check_details);
        new_trace.set_characters_preloaded(preload->preload_characters_);
        new_trace.set_bound_checked_up_to(preload->preload_characters_);
        generate_full_check_inline = true;
      }
    } else if (alt_gen->quick_check_details.cannot_match()) {
      if (!fall_through_on_failure) {
        macro_assembler->GoTo(trace->backtrack());
      }
      continue;
    } else {
      // No quick check was generated.  Put the full code here.
      // If this is not the first choice then there could be slow checks from
      // previous cases that go here when they fail.  There's no reason to
      // insist that they preload characters since the slow check we are about
      // to generate probably can't use it.
      if (i != first_choice) {
        alt_gen->expects_preload = false;
        new_trace.InvalidateCurrentCharacter();
      }
      generate_full_check_inline = true;
    }
    if (generate_full_check_inline) {
      if (new_trace.actions() != NULL) {
        new_trace.set_flush_budget(new_flush_budget);
      }
      for (intptr_t j = 0; j < guard_count; j++) {
        GenerateGuard(macro_assembler, guards->At(j), &new_trace);
      }
      alternative.node()->Emit(compiler, &new_trace);
      preload->preload_is_current_ = false;
    }
    macro_assembler->BindBlock(&alt_gen->after);
  }
}


void ChoiceNode::EmitOutOfLineContinuation(RegExpCompiler* compiler,
                                           Trace* trace,
                                           GuardedAlternative alternative,
                                           AlternativeGeneration* alt_gen,
                                           intptr_t preload_characters,
                                           bool next_expects_preload) {
  if (!alt_gen->possible_success.IsLinked()) return;

  RegExpMacroAssembler* macro_assembler = compiler->macro_assembler();
  macro_assembler->BindBlock(&alt_gen->possible_success);
  Trace out_of_line_trace(*trace);
  out_of_line_trace.set_characters_preloaded(preload_characters);
  out_of_line_trace.set_quick_check_performed(&alt_gen->quick_check_details);
  if (not_at_start_) out_of_line_trace.set_at_start(Trace::FALSE_VALUE);
  ZoneGrowableArray<Guard*>* guards = alternative.guards();
  intptr_t guard_count = (guards == NULL) ? 0 : guards->length();
  if (next_expects_preload) {
    BlockLabel reload_current_char;
    out_of_line_trace.set_backtrack(&reload_current_char);
    for (intptr_t j = 0; j < guard_count; j++) {
      GenerateGuard(macro_assembler, guards->At(j), &out_of_line_trace);
    }
    alternative.node()->Emit(compiler, &out_of_line_trace);
    macro_assembler->BindBlock(&reload_current_char);
    // Reload the current character, since the next quick check expects that.
    // We don't need to check bounds here because we only get into this
    // code through a quick check which already did the checked load.
    macro_assembler->LoadCurrentCharacter(trace->cp_offset(), NULL, false,
                                          preload_characters);
    macro_assembler->GoTo(&(alt_gen->after));
  } else {
    out_of_line_trace.set_backtrack(&(alt_gen->after));
    for (intptr_t j = 0; j < guard_count; j++) {
      GenerateGuard(macro_assembler, guards->At(j), &out_of_line_trace);
    }
    alternative.node()->Emit(compiler, &out_of_line_trace);
  }
}


void ActionNode::Emit(RegExpCompiler* compiler, Trace* trace) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  LimitResult limit_result = LimitVersions(compiler, trace);
  if (limit_result == DONE) return;
  ASSERT(limit_result == CONTINUE);

  RecursionCheck rc(compiler);

  switch (action_type_) {
    case STORE_POSITION: {
      Trace::DeferredCapture new_capture(data_.u_position_register.reg,
                                         data_.u_position_register.is_capture,
                                         trace);
      Trace new_trace = *trace;
      new_trace.add_action(&new_capture);
      on_success()->Emit(compiler, &new_trace);
      break;
    }
    case INCREMENT_REGISTER: {
      Trace::DeferredIncrementRegister new_increment(
          data_.u_increment_register.reg);
      Trace new_trace = *trace;
      new_trace.add_action(&new_increment);
      on_success()->Emit(compiler, &new_trace);
      break;
    }
    case SET_REGISTER: {
      Trace::DeferredSetRegister new_set(data_.u_store_register.reg,
                                         data_.u_store_register.value);
      Trace new_trace = *trace;
      new_trace.add_action(&new_set);
      on_success()->Emit(compiler, &new_trace);
      break;
    }
    case CLEAR_CAPTURES: {
      Trace::DeferredClearCaptures new_capture(Interval(
          data_.u_clear_captures.range_from, data_.u_clear_captures.range_to));
      Trace new_trace = *trace;
      new_trace.add_action(&new_capture);
      on_success()->Emit(compiler, &new_trace);
      break;
    }
    case BEGIN_SUBMATCH:
      if (!trace->is_trivial()) {
        trace->Flush(compiler, this);
      } else {
        assembler->WriteCurrentPositionToRegister(
            data_.u_submatch.current_position_register, 0);
        assembler->WriteStackPointerToRegister(
            data_.u_submatch.stack_pointer_register);
        on_success()->Emit(compiler, trace);
      }
      break;
    case EMPTY_MATCH_CHECK: {
      intptr_t start_pos_reg = data_.u_empty_match_check.start_register;
      intptr_t stored_pos = 0;
      intptr_t rep_reg = data_.u_empty_match_check.repetition_register;
      bool has_minimum = (rep_reg != RegExpCompiler::kNoRegister);
      bool know_dist = trace->GetStoredPosition(start_pos_reg, &stored_pos);
      if (know_dist && !has_minimum && stored_pos == trace->cp_offset()) {
        // If we know we haven't advanced and there is no minimum we
        // can just backtrack immediately.
        assembler->GoTo(trace->backtrack());
      } else if (know_dist && stored_pos < trace->cp_offset()) {
        // If we know we've advanced we can generate the continuation
        // immediately.
        on_success()->Emit(compiler, trace);
      } else if (!trace->is_trivial()) {
        trace->Flush(compiler, this);
      } else {
        BlockLabel skip_empty_check;
        // If we have a minimum number of repetitions we check the current
        // number first and skip the empty check if it's not enough.
        if (has_minimum) {
          intptr_t limit = data_.u_empty_match_check.repetition_limit;
          assembler->IfRegisterLT(rep_reg, limit, &skip_empty_check);
        }
        // If the match is empty we bail out, otherwise we fall through
        // to the on-success continuation.
        assembler->IfRegisterEqPos(data_.u_empty_match_check.start_register,
                                   trace->backtrack());
        assembler->BindBlock(&skip_empty_check);
        on_success()->Emit(compiler, trace);
      }
      break;
    }
    case POSITIVE_SUBMATCH_SUCCESS: {
      if (!trace->is_trivial()) {
        trace->Flush(compiler, this);
        return;
      }
      assembler->ReadCurrentPositionFromRegister(
          data_.u_submatch.current_position_register);
      assembler->ReadStackPointerFromRegister(
          data_.u_submatch.stack_pointer_register);
      intptr_t clear_register_count = data_.u_submatch.clear_register_count;
      if (clear_register_count == 0) {
        on_success()->Emit(compiler, trace);
        return;
      }
      intptr_t clear_registers_from = data_.u_submatch.clear_register_from;
      BlockLabel clear_registers_backtrack;
      Trace new_trace = *trace;
      new_trace.set_backtrack(&clear_registers_backtrack);
      on_success()->Emit(compiler, &new_trace);

      assembler->BindBlock(&clear_registers_backtrack);
      intptr_t clear_registers_to =
          clear_registers_from + clear_register_count - 1;
      assembler->ClearRegisters(clear_registers_from, clear_registers_to);

      ASSERT(trace->backtrack() == NULL);
      assembler->Backtrack();
      return;
    }
    default:
      UNREACHABLE();
  }
}


void BackReferenceNode::Emit(RegExpCompiler* compiler, Trace* trace) {
  RegExpMacroAssembler* assembler = compiler->macro_assembler();
  if (!trace->is_trivial()) {
    trace->Flush(compiler, this);
    return;
  }

  LimitResult limit_result = LimitVersions(compiler, trace);
  if (limit_result == DONE) return;
  ASSERT(limit_result == CONTINUE);

  RecursionCheck rc(compiler);

  ASSERT(start_reg_ + 1 == end_reg_);
  if (compiler->ignore_case()) {
    assembler->CheckNotBackReferenceIgnoreCase(start_reg_, trace->backtrack());
  } else {
    assembler->CheckNotBackReference(start_reg_, trace->backtrack());
  }
  on_success()->Emit(compiler, trace);
}


// -------------------------------------------------------------------
// Dot/dotty output


#ifdef DEBUG


class DotPrinter : public NodeVisitor {
 public:
  explicit DotPrinter(bool ignore_case) {}
  void PrintNode(const char* label, RegExpNode* node);
  void Visit(RegExpNode* node);
  void PrintAttributes(RegExpNode* from);
  void PrintOnFailure(RegExpNode* from, RegExpNode* to);
#define DECLARE_VISIT(Type) virtual void Visit##Type(Type##Node* that);
  FOR_EACH_NODE_TYPE(DECLARE_VISIT)
#undef DECLARE_VISIT
};


void DotPrinter::PrintNode(const char* label, RegExpNode* node) {
  OS::Print("digraph G {\n  graph [label=\"");
  for (intptr_t i = 0; label[i]; i++) {
    switch (label[i]) {
      case '\\':
        OS::Print("\\\\");
        break;
      case '"':
        OS::Print("\"");
        break;
      default:
        OS::Print("%c", label[i]);
        break;
    }
  }
  OS::Print("\"];\n");
  Visit(node);
  OS::Print("}\n");
}


void DotPrinter::Visit(RegExpNode* node) {
  if (node->info()->visited) return;
  node->info()->visited = true;
  node->Accept(this);
}


void DotPrinter::PrintOnFailure(RegExpNode* from, RegExpNode* on_failure) {
  OS::Print("  n%p -> n%p [style=dotted];\n", from, on_failure);
  Visit(on_failure);
}


class AttributePrinter : public ValueObject {
 public:
  AttributePrinter() : first_(true) {}
  void PrintSeparator() {
    if (first_) {
      first_ = false;
    } else {
      OS::Print("|");
    }
  }
  void PrintBit(const char* name, bool value) {
    if (!value) return;
    PrintSeparator();
    OS::Print("{%s}", name);
  }
  void PrintPositive(const char* name, intptr_t value) {
    if (value < 0) return;
    PrintSeparator();
    OS::Print("{%s|%" Pd "}", name, value);
  }

 private:
  bool first_;
};


void DotPrinter::PrintAttributes(RegExpNode* that) {
  OS::Print(
      "  a%p [shape=Mrecord, color=grey, fontcolor=grey, "
      "margin=0.1, fontsize=10, label=\"{",
      that);
  AttributePrinter printer;
  NodeInfo* info = that->info();
  printer.PrintBit("NI", info->follows_newline_interest);
  printer.PrintBit("WI", info->follows_word_interest);
  printer.PrintBit("SI", info->follows_start_interest);
  BlockLabel* label = that->label();
  if (label->IsBound()) printer.PrintPositive("@", label->Position());
  OS::Print(
      "}\"];\n"
      "  a%p -> n%p [style=dashed, color=grey, arrowhead=none];\n",
      that, that);
}


void DotPrinter::VisitChoice(ChoiceNode* that) {
  OS::Print("  n%p [shape=Mrecord, label=\"?\"];\n", that);
  for (intptr_t i = 0; i < that->alternatives()->length(); i++) {
    GuardedAlternative alt = that->alternatives()->At(i);
    OS::Print("  n%p -> n%p", that, alt.node());
  }
  for (intptr_t i = 0; i < that->alternatives()->length(); i++) {
    GuardedAlternative alt = that->alternatives()->At(i);
    alt.node()->Accept(this);
  }
}


void DotPrinter::VisitText(TextNode* that) {
  OS::Print("  n%p [label=\"", that);
  for (intptr_t i = 0; i < that->elements()->length(); i++) {
    if (i > 0) OS::Print(" ");
    TextElement elm = that->elements()->At(i);
    switch (elm.text_type()) {
      case TextElement::ATOM: {
        ZoneGrowableArray<uint16_t>* data = elm.atom()->data();
        for (intptr_t i = 0; i < data->length(); i++) {
          OS::Print("%c", static_cast<char>(data->At(i)));
        }
        break;
      }
      case TextElement::CHAR_CLASS: {
        RegExpCharacterClass* node = elm.char_class();
        OS::Print("[");
        if (node->is_negated()) OS::Print("^");
        for (intptr_t j = 0; j < node->ranges()->length(); j++) {
          CharacterRange range = node->ranges()->At(j);
          PrintUtf16(range.from());
          OS::Print("-");
          PrintUtf16(range.to());
        }
        OS::Print("]");
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  OS::Print("\", shape=box, peripheries=2];\n");
  PrintAttributes(that);
  OS::Print("  n%p -> n%p;\n", that, that->on_success());
  Visit(that->on_success());
}


void DotPrinter::VisitBackReference(BackReferenceNode* that) {
  OS::Print("  n%p [label=\"$%" Pd "..$%" Pd "\", shape=doubleoctagon];\n",
            that, that->start_register(), that->end_register());
  PrintAttributes(that);
  OS::Print("  n%p -> n%p;\n", that, that->on_success());
  Visit(that->on_success());
}


void DotPrinter::VisitEnd(EndNode* that) {
  OS::Print("  n%p [style=bold, shape=point];\n", that);
  PrintAttributes(that);
}


void DotPrinter::VisitAssertion(AssertionNode* that) {
  OS::Print("  n%p [", that);
  switch (that->assertion_type()) {
    case AssertionNode::AT_END:
      OS::Print("label=\"$\", shape=septagon");
      break;
    case AssertionNode::AT_START:
      OS::Print("label=\"^\", shape=septagon");
      break;
    case AssertionNode::AT_BOUNDARY:
      OS::Print("label=\"\\b\", shape=septagon");
      break;
    case AssertionNode::AT_NON_BOUNDARY:
      OS::Print("label=\"\\B\", shape=septagon");
      break;
    case AssertionNode::AFTER_NEWLINE:
      OS::Print("label=\"(?<=\\n)\", shape=septagon");
      break;
  }
  OS::Print("];\n");
  PrintAttributes(that);
  RegExpNode* successor = that->on_success();
  OS::Print("  n%p -> n%p;\n", that, successor);
  Visit(successor);
}


void DotPrinter::VisitAction(ActionNode* that) {
  OS::Print("  n%p [", that);
  switch (that->action_type_) {
    case ActionNode::SET_REGISTER:
      OS::Print("label=\"$%" Pd ":=%" Pd "\", shape=octagon",
                that->data_.u_store_register.reg,
                that->data_.u_store_register.value);
      break;
    case ActionNode::INCREMENT_REGISTER:
      OS::Print("label=\"$%" Pd "++\", shape=octagon",
                that->data_.u_increment_register.reg);
      break;
    case ActionNode::STORE_POSITION:
      OS::Print("label=\"$%" Pd ":=$pos\", shape=octagon",
                that->data_.u_position_register.reg);
      break;
    case ActionNode::BEGIN_SUBMATCH:
      OS::Print("label=\"$%" Pd ":=$pos,begin\", shape=septagon",
                that->data_.u_submatch.current_position_register);
      break;
    case ActionNode::POSITIVE_SUBMATCH_SUCCESS:
      OS::Print("label=\"escape\", shape=septagon");
      break;
    case ActionNode::EMPTY_MATCH_CHECK:
      OS::Print("label=\"$%" Pd "=$pos?,$%" Pd "<%" Pd "?\", shape=septagon",
                that->data_.u_empty_match_check.start_register,
                that->data_.u_empty_match_check.repetition_register,
                that->data_.u_empty_match_check.repetition_limit);
      break;
    case ActionNode::CLEAR_CAPTURES: {
      OS::Print("label=\"clear $%" Pd " to $%" Pd "\", shape=septagon",
                that->data_.u_clear_captures.range_from,
                that->data_.u_clear_captures.range_to);
      break;
    }
  }
  OS::Print("];\n");
  PrintAttributes(that);
  RegExpNode* successor = that->on_success();
  OS::Print("  n%p -> n%p;\n", that, successor);
  Visit(successor);
}


void RegExpEngine::DotPrint(const char* label,
                            RegExpNode* node,
                            bool ignore_case) {
  DotPrinter printer(ignore_case);
  printer.PrintNode(label, node);
}


#endif  // DEBUG


// -------------------------------------------------------------------
// Tree to graph conversion

// The zone in which we allocate graph nodes.
#define OZ (on_success->zone())

RegExpNode* RegExpAtom::ToNode(RegExpCompiler* compiler,
                               RegExpNode* on_success) {
  ZoneGrowableArray<TextElement>* elms =
      new (OZ) ZoneGrowableArray<TextElement>(1);
  elms->Add(TextElement::Atom(this));
  return new (OZ) TextNode(elms, on_success);
}


RegExpNode* RegExpText::ToNode(RegExpCompiler* compiler,
                               RegExpNode* on_success) {
  ZoneGrowableArray<TextElement>* elms =
      new (OZ) ZoneGrowableArray<TextElement>(1);
  for (intptr_t i = 0; i < elements()->length(); i++) {
    elms->Add(elements()->At(i));
  }
  return new (OZ) TextNode(elms, on_success);
}


static bool CompareInverseRanges(ZoneGrowableArray<CharacterRange>* ranges,
                                 const intptr_t* special_class,
                                 intptr_t length) {
  length--;  // Remove final 0x10000.
  ASSERT(special_class[length] == 0x10000);
  ASSERT(ranges->length() != 0);
  ASSERT(length != 0);
  ASSERT(special_class[0] != 0);
  if (ranges->length() != (length >> 1) + 1) {
    return false;
  }
  CharacterRange range = ranges->At(0);
  if (range.from() != 0) {
    return false;
  }
  for (intptr_t i = 0; i < length; i += 2) {
    if (special_class[i] != (range.to() + 1)) {
      return false;
    }
    range = ranges->At((i >> 1) + 1);
    if (special_class[i + 1] != range.from()) {
      return false;
    }
  }
  if (range.to() != 0xffff) {
    return false;
  }
  return true;
}


static bool CompareRanges(ZoneGrowableArray<CharacterRange>* ranges,
                          const intptr_t* special_class,
                          intptr_t length) {
  length--;  // Remove final 0x10000.
  ASSERT(special_class[length] == 0x10000);
  if (ranges->length() * 2 != length) {
    return false;
  }
  for (intptr_t i = 0; i < length; i += 2) {
    CharacterRange range = ranges->At(i >> 1);
    if (range.from() != special_class[i] ||
        range.to() != special_class[i + 1] - 1) {
      return false;
    }
  }
  return true;
}


bool RegExpCharacterClass::is_standard() {
  // TODO(lrn): Remove need for this function, by not throwing away information
  // along the way.
  if (is_negated_) {
    return false;
  }
  if (set_.is_standard()) {
    return true;
  }
  if (CompareRanges(set_.ranges(), kSpaceRanges, kSpaceRangeCount)) {
    set_.set_standard_set_type('s');
    return true;
  }
  if (CompareInverseRanges(set_.ranges(), kSpaceRanges, kSpaceRangeCount)) {
    set_.set_standard_set_type('S');
    return true;
  }
  if (CompareInverseRanges(set_.ranges(), kLineTerminatorRanges,
                           kLineTerminatorRangeCount)) {
    set_.set_standard_set_type('.');
    return true;
  }
  if (CompareRanges(set_.ranges(), kLineTerminatorRanges,
                    kLineTerminatorRangeCount)) {
    set_.set_standard_set_type('n');
    return true;
  }
  if (CompareRanges(set_.ranges(), kWordRanges, kWordRangeCount)) {
    set_.set_standard_set_type('w');
    return true;
  }
  if (CompareInverseRanges(set_.ranges(), kWordRanges, kWordRangeCount)) {
    set_.set_standard_set_type('W');
    return true;
  }
  return false;
}


RegExpNode* RegExpCharacterClass::ToNode(RegExpCompiler* compiler,
                                         RegExpNode* on_success) {
  return new (OZ) TextNode(this, on_success);
}


RegExpNode* RegExpDisjunction::ToNode(RegExpCompiler* compiler,
                                      RegExpNode* on_success) {
  ZoneGrowableArray<RegExpTree*>* alternatives = this->alternatives();
  intptr_t length = alternatives->length();
  ChoiceNode* result = new (OZ) ChoiceNode(length, OZ);
  for (intptr_t i = 0; i < length; i++) {
    GuardedAlternative alternative(
        alternatives->At(i)->ToNode(compiler, on_success));
    result->AddAlternative(alternative);
  }
  return result;
}


RegExpNode* RegExpQuantifier::ToNode(RegExpCompiler* compiler,
                                     RegExpNode* on_success) {
  return ToNode(min(), max(), is_greedy(), body(), compiler, on_success);
}


// Scoped object to keep track of how much we unroll quantifier loops in the
// regexp graph generator.
class RegExpExpansionLimiter : public ValueObject {
 public:
  static const intptr_t kMaxExpansionFactor = 6;
  RegExpExpansionLimiter(RegExpCompiler* compiler, intptr_t factor)
      : compiler_(compiler),
        saved_expansion_factor_(compiler->current_expansion_factor()),
        ok_to_expand_(saved_expansion_factor_ <= kMaxExpansionFactor) {
    ASSERT(factor > 0);
    if (ok_to_expand_) {
      if (factor > kMaxExpansionFactor) {
        // Avoid integer overflow of the current expansion factor.
        ok_to_expand_ = false;
        compiler->set_current_expansion_factor(kMaxExpansionFactor + 1);
      } else {
        intptr_t new_factor = saved_expansion_factor_ * factor;
        ok_to_expand_ = (new_factor <= kMaxExpansionFactor);
        compiler->set_current_expansion_factor(new_factor);
      }
    }
  }

  ~RegExpExpansionLimiter() {
    compiler_->set_current_expansion_factor(saved_expansion_factor_);
  }

  bool ok_to_expand() { return ok_to_expand_; }

 private:
  RegExpCompiler* compiler_;
  intptr_t saved_expansion_factor_;
  bool ok_to_expand_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(RegExpExpansionLimiter);
};


RegExpNode* RegExpQuantifier::ToNode(intptr_t min,
                                     intptr_t max,
                                     bool is_greedy,
                                     RegExpTree* body,
                                     RegExpCompiler* compiler,
                                     RegExpNode* on_success,
                                     bool not_at_start) {
  // x{f, t} becomes this:
  //
  //             (r++)<-.
  //               |     `
  //               |     (x)
  //               v     ^
  //      (r=0)-->(?)---/ [if r < t]
  //               |
  //   [if r >= f] \----> ...
  //

  // 15.10.2.5 RepeatMatcher algorithm.
  // The parser has already eliminated the case where max is 0.  In the case
  // where max_match is zero the parser has removed the quantifier if min was
  // > 0 and removed the atom if min was 0.  See AddQuantifierToAtom.

  // If we know that we cannot match zero length then things are a little
  // simpler since we don't need to make the special zero length match check
  // from step 2.1.  If the min and max are small we can unroll a little in
  // this case.
  // Unroll (foo)+ and (foo){3,}
  static const intptr_t kMaxUnrolledMinMatches = 3;
  // Unroll (foo)? and (foo){x,3}
  static const intptr_t kMaxUnrolledMaxMatches = 3;
  if (max == 0) return on_success;  // This can happen due to recursion.
  bool body_can_be_empty = (body->min_match() == 0);
  intptr_t body_start_reg = RegExpCompiler::kNoRegister;
  Interval capture_registers = body->CaptureRegisters();
  bool needs_capture_clearing = !capture_registers.is_empty();
  Zone* zone = compiler->zone();

  if (body_can_be_empty) {
    body_start_reg = compiler->AllocateRegister();
  } else if (kRegexpOptimization && !needs_capture_clearing) {
    // Only unroll if there are no captures and the body can't be
    // empty.
    {
      RegExpExpansionLimiter limiter(compiler, min + ((max != min) ? 1 : 0));
      if (min > 0 && min <= kMaxUnrolledMinMatches && limiter.ok_to_expand()) {
        intptr_t new_max = (max == kInfinity) ? max : max - min;
        // Recurse once to get the loop or optional matches after the fixed
        // ones.
        RegExpNode* answer =
            ToNode(0, new_max, is_greedy, body, compiler, on_success, true);
        // Unroll the forced matches from 0 to min.  This can cause chains of
        // TextNodes (which the parser does not generate).  These should be
        // combined if it turns out they hinder good code generation.
        for (intptr_t i = 0; i < min; i++) {
          answer = body->ToNode(compiler, answer);
        }
        return answer;
      }
    }
    if (max <= kMaxUnrolledMaxMatches && min == 0) {
      ASSERT(max > 0);  // Due to the 'if' above.
      RegExpExpansionLimiter limiter(compiler, max);
      if (limiter.ok_to_expand()) {
        // Unroll the optional matches up to max.
        RegExpNode* answer = on_success;
        for (intptr_t i = 0; i < max; i++) {
          ChoiceNode* alternation = new (zone) ChoiceNode(2, zone);
          if (is_greedy) {
            alternation->AddAlternative(
                GuardedAlternative(body->ToNode(compiler, answer)));
            alternation->AddAlternative(GuardedAlternative(on_success));
          } else {
            alternation->AddAlternative(GuardedAlternative(on_success));
            alternation->AddAlternative(
                GuardedAlternative(body->ToNode(compiler, answer)));
          }
          answer = alternation;
          if (not_at_start) alternation->set_not_at_start();
        }
        return answer;
      }
    }
  }
  bool has_min = min > 0;
  bool has_max = max < RegExpTree::kInfinity;
  bool needs_counter = has_min || has_max;
  intptr_t reg_ctr = needs_counter ? compiler->AllocateRegister()
                                   : RegExpCompiler::kNoRegister;
  LoopChoiceNode* center =
      new (zone) LoopChoiceNode(body->min_match() == 0, zone);
  if (not_at_start) center->set_not_at_start();
  RegExpNode* loop_return =
      needs_counter ? static_cast<RegExpNode*>(
                          ActionNode::IncrementRegister(reg_ctr, center))
                    : static_cast<RegExpNode*>(center);
  if (body_can_be_empty) {
    // If the body can be empty we need to check if it was and then
    // backtrack.
    loop_return =
        ActionNode::EmptyMatchCheck(body_start_reg, reg_ctr, min, loop_return);
  }
  RegExpNode* body_node = body->ToNode(compiler, loop_return);
  if (body_can_be_empty) {
    // If the body can be empty we need to store the start position
    // so we can bail out if it was empty.
    body_node = ActionNode::StorePosition(body_start_reg, false, body_node);
  }
  if (needs_capture_clearing) {
    // Before entering the body of this loop we need to clear captures.
    body_node = ActionNode::ClearCaptures(capture_registers, body_node);
  }
  GuardedAlternative body_alt(body_node);
  if (has_max) {
    Guard* body_guard = new (zone) Guard(reg_ctr, Guard::LT, max);
    body_alt.AddGuard(body_guard, zone);
  }
  GuardedAlternative rest_alt(on_success);
  if (has_min) {
    Guard* rest_guard = new (zone) Guard(reg_ctr, Guard::GEQ, min);
    rest_alt.AddGuard(rest_guard, zone);
  }
  if (is_greedy) {
    center->AddLoopAlternative(body_alt);
    center->AddContinueAlternative(rest_alt);
  } else {
    center->AddContinueAlternative(rest_alt);
    center->AddLoopAlternative(body_alt);
  }
  if (needs_counter) {
    return ActionNode::SetRegister(reg_ctr, 0, center);
  } else {
    return center;
  }
}


RegExpNode* RegExpAssertion::ToNode(RegExpCompiler* compiler,
                                    RegExpNode* on_success) {
  switch (assertion_type()) {
    case START_OF_LINE:
      return AssertionNode::AfterNewline(on_success);
    case START_OF_INPUT:
      return AssertionNode::AtStart(on_success);
    case BOUNDARY:
      return AssertionNode::AtBoundary(on_success);
    case NON_BOUNDARY:
      return AssertionNode::AtNonBoundary(on_success);
    case END_OF_INPUT:
      return AssertionNode::AtEnd(on_success);
    case END_OF_LINE: {
      // Compile $ in multiline regexps as an alternation with a positive
      // lookahead in one side and an end-of-input on the other side.
      // We need two registers for the lookahead.
      intptr_t stack_pointer_register = compiler->AllocateRegister();
      intptr_t position_register = compiler->AllocateRegister();
      // The ChoiceNode to distinguish between a newline and end-of-input.
      ChoiceNode* result = new ChoiceNode(2, on_success->zone());
      // Create a newline atom.
      ZoneGrowableArray<CharacterRange>* newline_ranges =
          new ZoneGrowableArray<CharacterRange>(3);
      CharacterRange::AddClassEscape('n', newline_ranges);
      RegExpCharacterClass* newline_atom = new RegExpCharacterClass('n');
      TextNode* newline_matcher = new TextNode(
          newline_atom, ActionNode::PositiveSubmatchSuccess(
                            stack_pointer_register, position_register,
                            0,   // No captures inside.
                            -1,  // Ignored if no captures.
                            on_success));
      // Create an end-of-input matcher.
      RegExpNode* end_of_line = ActionNode::BeginSubmatch(
          stack_pointer_register, position_register, newline_matcher);
      // Add the two alternatives to the ChoiceNode.
      GuardedAlternative eol_alternative(end_of_line);
      result->AddAlternative(eol_alternative);
      GuardedAlternative end_alternative(AssertionNode::AtEnd(on_success));
      result->AddAlternative(end_alternative);
      return result;
    }
    default:
      UNREACHABLE();
  }
  return on_success;
}


RegExpNode* RegExpBackReference::ToNode(RegExpCompiler* compiler,
                                        RegExpNode* on_success) {
  return new (OZ)
      BackReferenceNode(RegExpCapture::StartRegister(index()),
                        RegExpCapture::EndRegister(index()), on_success);
}


RegExpNode* RegExpEmpty::ToNode(RegExpCompiler* compiler,
                                RegExpNode* on_success) {
  return on_success;
}


RegExpNode* RegExpLookahead::ToNode(RegExpCompiler* compiler,
                                    RegExpNode* on_success) {
  intptr_t stack_pointer_register = compiler->AllocateRegister();
  intptr_t position_register = compiler->AllocateRegister();

  const intptr_t registers_per_capture = 2;
  const intptr_t register_of_first_capture = 2;
  intptr_t register_count = capture_count_ * registers_per_capture;
  intptr_t register_start =
      register_of_first_capture + capture_from_ * registers_per_capture;

  RegExpNode* success;
  if (is_positive()) {
    RegExpNode* node = ActionNode::BeginSubmatch(
        stack_pointer_register, position_register,
        body()->ToNode(compiler,
                       ActionNode::PositiveSubmatchSuccess(
                           stack_pointer_register, position_register,
                           register_count, register_start, on_success)));
    return node;
  } else {
    // We use a ChoiceNode for a negative lookahead because it has most of
    // the characteristics we need.  It has the body of the lookahead as its
    // first alternative and the expression after the lookahead of the second
    // alternative.  If the first alternative succeeds then the
    // NegativeSubmatchSuccess will unwind the stack including everything the
    // choice node set up and backtrack.  If the first alternative fails then
    // the second alternative is tried, which is exactly the desired result
    // for a negative lookahead.  The NegativeLookaheadChoiceNode is a special
    // ChoiceNode that knows to ignore the first exit when calculating quick
    // checks.

    GuardedAlternative body_alt(
        body()->ToNode(compiler, success = new (OZ) NegativeSubmatchSuccess(
                                     stack_pointer_register, position_register,
                                     register_count, register_start, OZ)));
    ChoiceNode* choice_node = new (OZ) NegativeLookaheadChoiceNode(
        body_alt, GuardedAlternative(on_success), OZ);
    return ActionNode::BeginSubmatch(stack_pointer_register, position_register,
                                     choice_node);
  }
}


RegExpNode* RegExpCapture::ToNode(RegExpCompiler* compiler,
                                  RegExpNode* on_success) {
  return ToNode(body(), index(), compiler, on_success);
}


RegExpNode* RegExpCapture::ToNode(RegExpTree* body,
                                  intptr_t index,
                                  RegExpCompiler* compiler,
                                  RegExpNode* on_success) {
  intptr_t start_reg = RegExpCapture::StartRegister(index);
  intptr_t end_reg = RegExpCapture::EndRegister(index);
  RegExpNode* store_end = ActionNode::StorePosition(end_reg, true, on_success);
  RegExpNode* body_node = body->ToNode(compiler, store_end);
  return ActionNode::StorePosition(start_reg, true, body_node);
}


RegExpNode* RegExpAlternative::ToNode(RegExpCompiler* compiler,
                                      RegExpNode* on_success) {
  ZoneGrowableArray<RegExpTree*>* children = nodes();
  RegExpNode* current = on_success;
  for (intptr_t i = children->length() - 1; i >= 0; i--) {
    current = children->At(i)->ToNode(compiler, current);
  }
  return current;
}


static void AddClass(const intptr_t* elmv,
                     intptr_t elmc,
                     ZoneGrowableArray<CharacterRange>* ranges) {
  elmc--;
  ASSERT(elmv[elmc] == 0x10000);
  for (intptr_t i = 0; i < elmc; i += 2) {
    ASSERT(elmv[i] < elmv[i + 1]);
    ranges->Add(CharacterRange(elmv[i], elmv[i + 1] - 1));
  }
}


static void AddClassNegated(const intptr_t* elmv,
                            intptr_t elmc,
                            ZoneGrowableArray<CharacterRange>* ranges) {
  elmc--;
  ASSERT(elmv[elmc] == 0x10000);
  ASSERT(elmv[0] != 0x0000);
  ASSERT(elmv[elmc - 1] != Utf16::kMaxCodeUnit);
  uint16_t last = 0x0000;
  for (intptr_t i = 0; i < elmc; i += 2) {
    ASSERT(last <= elmv[i] - 1);
    ASSERT(elmv[i] < elmv[i + 1]);
    ranges->Add(CharacterRange(last, elmv[i] - 1));
    last = elmv[i + 1];
  }
  ranges->Add(CharacterRange(last, Utf16::kMaxCodeUnit));
}


void CharacterRange::AddClassEscape(uint16_t type,
                                    ZoneGrowableArray<CharacterRange>* ranges) {
  switch (type) {
    case 's':
      AddClass(kSpaceRanges, kSpaceRangeCount, ranges);
      break;
    case 'S':
      AddClassNegated(kSpaceRanges, kSpaceRangeCount, ranges);
      break;
    case 'w':
      AddClass(kWordRanges, kWordRangeCount, ranges);
      break;
    case 'W':
      AddClassNegated(kWordRanges, kWordRangeCount, ranges);
      break;
    case 'd':
      AddClass(kDigitRanges, kDigitRangeCount, ranges);
      break;
    case 'D':
      AddClassNegated(kDigitRanges, kDigitRangeCount, ranges);
      break;
    case '.':
      AddClassNegated(kLineTerminatorRanges, kLineTerminatorRangeCount, ranges);
      break;
    // This is not a character range as defined by the spec but a
    // convenient shorthand for a character class that matches any
    // character.
    case '*':
      ranges->Add(CharacterRange::Everything());
      break;
    // This is the set of characters matched by the $ and ^ symbols
    // in multiline mode.
    case 'n':
      AddClass(kLineTerminatorRanges, kLineTerminatorRangeCount, ranges);
      break;
    default:
      UNREACHABLE();
  }
}


void CharacterRange::AddCaseEquivalents(
    ZoneGrowableArray<CharacterRange>* ranges,
    bool is_one_byte,
    Zone* zone) {
  uint16_t bottom = from();
  uint16_t top = to();
  if (is_one_byte && !RangeContainsLatin1Equivalents(*this)) {
    if (bottom > Symbols::kMaxOneCharCodeSymbol) return;
    if (top > Symbols::kMaxOneCharCodeSymbol) {
      top = Symbols::kMaxOneCharCodeSymbol;
    }
  }

  unibrow::Mapping<unibrow::Ecma262UnCanonicalize> jsregexp_uncanonicalize;
  unibrow::Mapping<unibrow::CanonicalizationRange> jsregexp_canonrange;
  int32_t chars[unibrow::Ecma262UnCanonicalize::kMaxWidth];
  if (top == bottom) {
    // If this is a singleton we just expand the one character.
    intptr_t length =
        jsregexp_uncanonicalize.get(bottom, '\0', chars);  // NOLINT
    for (intptr_t i = 0; i < length; i++) {
      uint32_t chr = chars[i];
      if (chr != bottom) {
        ranges->Add(CharacterRange::Singleton(chars[i]));
      }
    }
  } else {
    // If this is a range we expand the characters block by block,
    // expanding contiguous subranges (blocks) one at a time.
    // The approach is as follows.  For a given start character we
    // look up the remainder of the block that contains it (represented
    // by the end point), for instance we find 'z' if the character
    // is 'c'.  A block is characterized by the property
    // that all characters uncanonicalize in the same way, except that
    // each entry in the result is incremented by the distance from the first
    // element.  So a-z is a block because 'a' uncanonicalizes to ['a', 'A'] and
    // the k'th letter uncanonicalizes to ['a' + k, 'A' + k].
    // Once we've found the end point we look up its uncanonicalization
    // and produce a range for each element.  For instance for [c-f]
    // we look up ['z', 'Z'] and produce [c-f] and [C-F].  We then only
    // add a range if it is not already contained in the input, so [c-f]
    // will be skipped but [C-F] will be added.  If this range is not
    // completely contained in a block we do this for all the blocks
    // covered by the range (handling characters that is not in a block
    // as a "singleton block").
    int32_t range[unibrow::Ecma262UnCanonicalize::kMaxWidth];
    intptr_t pos = bottom;
    while (pos <= top) {
      intptr_t length = jsregexp_canonrange.get(pos, '\0', range);
      uint16_t block_end;
      if (length == 0) {
        block_end = pos;
      } else {
        ASSERT(length == 1);
        block_end = range[0];
      }
      intptr_t end = (block_end > top) ? top : block_end;
      length = jsregexp_uncanonicalize.get(block_end, '\0', range);  // NOLINT
      for (intptr_t i = 0; i < length; i++) {
        uint32_t c = range[i];
        uint16_t range_from = c - (block_end - pos);
        uint16_t range_to = c - (block_end - end);
        if (!(bottom <= range_from && range_to <= top)) {
          ranges->Add(CharacterRange(range_from, range_to));
        }
      }
      pos = end + 1;
    }
  }
}


bool CharacterRange::IsCanonical(ZoneGrowableArray<CharacterRange>* ranges) {
  ASSERT(ranges != NULL);
  intptr_t n = ranges->length();
  if (n <= 1) return true;
  intptr_t max = ranges->At(0).to();
  for (intptr_t i = 1; i < n; i++) {
    CharacterRange next_range = ranges->At(i);
    if (next_range.from() <= max + 1) return false;
    max = next_range.to();
  }
  return true;
}


ZoneGrowableArray<CharacterRange>* CharacterSet::ranges() {
  if (ranges_ == NULL) {
    ranges_ = new ZoneGrowableArray<CharacterRange>(2);
    CharacterRange::AddClassEscape(standard_set_type_, ranges_);
  }
  return ranges_;
}


// Move a number of elements in a zone array to another position
// in the same array. Handles overlapping source and target areas.
static void MoveRanges(ZoneGrowableArray<CharacterRange>* list,
                       intptr_t from,
                       intptr_t to,
                       intptr_t count) {
  // Ranges are potentially overlapping.
  if (from < to) {
    for (intptr_t i = count - 1; i >= 0; i--) {
      (*list)[to + i] = list->At(from + i);
    }
  } else {
    for (intptr_t i = 0; i < count; i++) {
      (*list)[to + i] = list->At(from + i);
    }
  }
}


static intptr_t InsertRangeInCanonicalList(
    ZoneGrowableArray<CharacterRange>* list,
    intptr_t count,
    CharacterRange insert) {
  // Inserts a range into list[0..count[, which must be sorted
  // by from value and non-overlapping and non-adjacent, using at most
  // list[0..count] for the result. Returns the number of resulting
  // canonicalized ranges. Inserting a range may collapse existing ranges into
  // fewer ranges, so the return value can be anything in the range 1..count+1.
  uint16_t from = insert.from();
  uint16_t to = insert.to();
  intptr_t start_pos = 0;
  intptr_t end_pos = count;
  for (intptr_t i = count - 1; i >= 0; i--) {
    CharacterRange current = list->At(i);
    if (current.from() > to + 1) {
      end_pos = i;
    } else if (current.to() + 1 < from) {
      start_pos = i + 1;
      break;
    }
  }

  // Inserted range overlaps, or is adjacent to, ranges at positions
  // [start_pos..end_pos[. Ranges before start_pos or at or after end_pos are
  // not affected by the insertion.
  // If start_pos == end_pos, the range must be inserted before start_pos.
  // if start_pos < end_pos, the entire range from start_pos to end_pos
  // must be merged with the insert range.

  if (start_pos == end_pos) {
    // Insert between existing ranges at position start_pos.
    if (start_pos < count) {
      MoveRanges(list, start_pos, start_pos + 1, count - start_pos);
    }
    (*list)[start_pos] = insert;
    return count + 1;
  }
  if (start_pos + 1 == end_pos) {
    // Replace single existing range at position start_pos.
    CharacterRange to_replace = list->At(start_pos);
    intptr_t new_from = Utils::Minimum(to_replace.from(), from);
    intptr_t new_to = Utils::Maximum(to_replace.to(), to);
    (*list)[start_pos] = CharacterRange(new_from, new_to);
    return count;
  }
  // Replace a number of existing ranges from start_pos to end_pos - 1.
  // Move the remaining ranges down.

  intptr_t new_from = Utils::Minimum(list->At(start_pos).from(), from);
  intptr_t new_to = Utils::Maximum(list->At(end_pos - 1).to(), to);
  if (end_pos < count) {
    MoveRanges(list, end_pos, start_pos + 1, count - end_pos);
  }
  (*list)[start_pos] = CharacterRange(new_from, new_to);
  return count - (end_pos - start_pos) + 1;
}


void CharacterSet::Canonicalize() {
  // Special/default classes are always considered canonical. The result
  // of calling ranges() will be sorted.
  if (ranges_ == NULL) return;
  CharacterRange::Canonicalize(ranges_);
}


void CharacterRange::Canonicalize(
    ZoneGrowableArray<CharacterRange>* character_ranges) {
  if (character_ranges->length() <= 1) return;
  // Check whether ranges are already canonical (increasing, non-overlapping,
  // non-adjacent).
  intptr_t n = character_ranges->length();
  intptr_t max = character_ranges->At(0).to();
  intptr_t i = 1;
  while (i < n) {
    CharacterRange current = character_ranges->At(i);
    if (current.from() <= max + 1) {
      break;
    }
    max = current.to();
    i++;
  }
  // Canonical until the i'th range. If that's all of them, we are done.
  if (i == n) return;

  // The ranges at index i and forward are not canonicalized. Make them so by
  // doing the equivalent of insertion sort (inserting each into the previous
  // list, in order).
  // Notice that inserting a range can reduce the number of ranges in the
  // result due to combining of adjacent and overlapping ranges.
  intptr_t read = i;           // Range to insert.
  intptr_t num_canonical = i;  // Length of canonicalized part of list.
  do {
    num_canonical = InsertRangeInCanonicalList(character_ranges, num_canonical,
                                               character_ranges->At(read));
    read++;
  } while (read < n);
  character_ranges->TruncateTo(num_canonical);

  ASSERT(CharacterRange::IsCanonical(character_ranges));
}


void CharacterRange::Negate(ZoneGrowableArray<CharacterRange>* ranges,
                            ZoneGrowableArray<CharacterRange>* negated_ranges) {
  ASSERT(CharacterRange::IsCanonical(ranges));
  ASSERT(negated_ranges->length() == 0);
  intptr_t range_count = ranges->length();
  uint16_t from = 0;
  intptr_t i = 0;
  if (range_count > 0 && ranges->At(0).from() == 0) {
    from = ranges->At(0).to();
    i = 1;
  }
  while (i < range_count) {
    CharacterRange range = ranges->At(i);
    negated_ranges->Add(CharacterRange(from + 1, range.from() - 1));
    from = range.to();
    i++;
  }
  if (from < Utf16::kMaxCodeUnit) {
    negated_ranges->Add(CharacterRange(from + 1, Utf16::kMaxCodeUnit));
  }
}


// -------------------------------------------------------------------
// Splay tree


// Workaround for the fact that ZoneGrowableArray does not have contains().
static bool ArrayContains(ZoneGrowableArray<unsigned>* array, unsigned value) {
  for (intptr_t i = 0; i < array->length(); i++) {
    if (array->At(i) == value) {
      return true;
    }
  }
  return false;
}


void OutSet::Set(unsigned value, Zone* zone) {
  if (value < kFirstLimit) {
    first_ |= (1 << value);
  } else {
    if (remaining_ == NULL)
      remaining_ = new (zone) ZoneGrowableArray<unsigned>(1);

    bool remaining_contains_value = ArrayContains(remaining_, value);
    if (remaining_->is_empty() || !remaining_contains_value) {
      remaining_->Add(value);
    }
  }
}


bool OutSet::Get(unsigned value) const {
  if (value < kFirstLimit) {
    return (first_ & (1 << value)) != 0;
  } else if (remaining_ == NULL) {
    return false;
  } else {
    return ArrayContains(remaining_, value);
  }
}


// -------------------------------------------------------------------
// Analysis


void Analysis::EnsureAnalyzed(RegExpNode* that) {
  if (that->info()->been_analyzed || that->info()->being_analyzed) return;
  that->info()->being_analyzed = true;
  that->Accept(this);
  that->info()->being_analyzed = false;
  that->info()->been_analyzed = true;
}


void Analysis::VisitEnd(EndNode* that) {
  // nothing to do
}


void TextNode::CalculateOffsets() {
  intptr_t element_count = elements()->length();
  // Set up the offsets of the elements relative to the start.  This is a fixed
  // quantity since a TextNode can only contain fixed-width things.
  intptr_t cp_offset = 0;
  for (intptr_t i = 0; i < element_count; i++) {
    TextElement& elm = (*elements())[i];
    elm.set_cp_offset(cp_offset);
    cp_offset += elm.length();
  }
}


void Analysis::VisitText(TextNode* that) {
  if (ignore_case_) {
    that->MakeCaseIndependent(is_one_byte_);
  }
  EnsureAnalyzed(that->on_success());
  if (!has_failed()) {
    that->CalculateOffsets();
  }
}


void Analysis::VisitAction(ActionNode* that) {
  RegExpNode* target = that->on_success();
  EnsureAnalyzed(target);
  if (!has_failed()) {
    // If the next node is interested in what it follows then this node
    // has to be interested too so it can pass the information on.
    that->info()->AddFromFollowing(target->info());
  }
}


void Analysis::VisitChoice(ChoiceNode* that) {
  NodeInfo* info = that->info();
  for (intptr_t i = 0; i < that->alternatives()->length(); i++) {
    RegExpNode* node = (*that->alternatives())[i].node();
    EnsureAnalyzed(node);
    if (has_failed()) return;
    // Anything the following nodes need to know has to be known by
    // this node also, so it can pass it on.
    info->AddFromFollowing(node->info());
  }
}


void Analysis::VisitLoopChoice(LoopChoiceNode* that) {
  NodeInfo* info = that->info();
  for (intptr_t i = 0; i < that->alternatives()->length(); i++) {
    RegExpNode* node = (*that->alternatives())[i].node();
    if (node != that->loop_node()) {
      EnsureAnalyzed(node);
      if (has_failed()) return;
      info->AddFromFollowing(node->info());
    }
  }
  // Check the loop last since it may need the value of this node
  // to get a correct result.
  EnsureAnalyzed(that->loop_node());
  if (!has_failed()) {
    info->AddFromFollowing(that->loop_node()->info());
  }
}


void Analysis::VisitBackReference(BackReferenceNode* that) {
  EnsureAnalyzed(that->on_success());
}


void Analysis::VisitAssertion(AssertionNode* that) {
  EnsureAnalyzed(that->on_success());
}


void BackReferenceNode::FillInBMInfo(intptr_t offset,
                                     intptr_t budget,
                                     BoyerMooreLookahead* bm,
                                     bool not_at_start) {
  // Working out the set of characters that a backreference can match is too
  // hard, so we just say that any character can match.
  bm->SetRest(offset);
  SaveBMInfo(bm, not_at_start, offset);
}


COMPILE_ASSERT(BoyerMoorePositionInfo::kMapSize ==
               RegExpMacroAssembler::kTableSize);


void ChoiceNode::FillInBMInfo(intptr_t offset,
                              intptr_t budget,
                              BoyerMooreLookahead* bm,
                              bool not_at_start) {
  ZoneGrowableArray<GuardedAlternative>* alts = alternatives();
  budget = (budget - 1) / alts->length();
  for (intptr_t i = 0; i < alts->length(); i++) {
    GuardedAlternative& alt = (*alts)[i];
    if (alt.guards() != NULL && alt.guards()->length() != 0) {
      bm->SetRest(offset);  // Give up trying to fill in info.
      SaveBMInfo(bm, not_at_start, offset);
      return;
    }
    alt.node()->FillInBMInfo(offset, budget, bm, not_at_start);
  }
  SaveBMInfo(bm, not_at_start, offset);
}


void TextNode::FillInBMInfo(intptr_t initial_offset,
                            intptr_t budget,
                            BoyerMooreLookahead* bm,
                            bool not_at_start) {
  if (initial_offset >= bm->length()) return;
  intptr_t offset = initial_offset;
  intptr_t max_char = bm->max_char();
  for (intptr_t i = 0; i < elements()->length(); i++) {
    if (offset >= bm->length()) {
      if (initial_offset == 0) set_bm_info(not_at_start, bm);
      return;
    }
    TextElement text = elements()->At(i);
    if (text.text_type() == TextElement::ATOM) {
      RegExpAtom* atom = text.atom();
      for (intptr_t j = 0; j < atom->length(); j++, offset++) {
        if (offset >= bm->length()) {
          if (initial_offset == 0) set_bm_info(not_at_start, bm);
          return;
        }
        uint16_t character = atom->data()->At(j);
        if (bm->compiler()->ignore_case()) {
          int32_t chars[unibrow::Ecma262UnCanonicalize::kMaxWidth];
          intptr_t length = GetCaseIndependentLetters(
              character, bm->max_char() == Symbols::kMaxOneCharCodeSymbol,
              chars);
          for (intptr_t j = 0; j < length; j++) {
            bm->Set(offset, chars[j]);
          }
        } else {
          if (character <= max_char) bm->Set(offset, character);
        }
      }
    } else {
      ASSERT(text.text_type() == TextElement::CHAR_CLASS);
      RegExpCharacterClass* char_class = text.char_class();
      ZoneGrowableArray<CharacterRange>* ranges = char_class->ranges();
      if (char_class->is_negated()) {
        bm->SetAll(offset);
      } else {
        for (intptr_t k = 0; k < ranges->length(); k++) {
          CharacterRange& range = (*ranges)[k];
          if (range.from() > max_char) continue;
          intptr_t to =
              Utils::Minimum(max_char, static_cast<intptr_t>(range.to()));
          bm->SetInterval(offset, Interval(range.from(), to));
        }
      }
      offset++;
    }
  }
  if (offset >= bm->length()) {
    if (initial_offset == 0) set_bm_info(not_at_start, bm);
    return;
  }
  on_success()->FillInBMInfo(offset, budget - 1, bm,
                             true);  // Not at start after a text node.
  if (initial_offset == 0) set_bm_info(not_at_start, bm);
}


#if !defined(DART_PRECOMPILED_RUNTIME)
RegExpEngine::CompilationResult RegExpEngine::CompileIR(
    RegExpCompileData* data,
    const ParsedFunction* parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    intptr_t osr_id) {
  ASSERT(!FLAG_interpret_irregexp);
  Zone* zone = Thread::Current()->zone();

  const Function& function = parsed_function->function();
  const intptr_t specialization_cid = function.string_specialization_cid();
  const intptr_t is_sticky = function.is_sticky_specialization();
  const bool is_one_byte = (specialization_cid == kOneByteStringCid ||
                            specialization_cid == kExternalOneByteStringCid);
  RegExp& regexp = RegExp::Handle(zone, function.regexp());
  const String& pattern = String::Handle(zone, regexp.pattern());

  ASSERT(!regexp.IsNull());
  ASSERT(!pattern.IsNull());

  const bool ignore_case = regexp.is_ignore_case();
  const bool is_global = regexp.is_global();

  RegExpCompiler compiler(data->capture_count, ignore_case, is_one_byte);

  // TODO(zerny): Frequency sampling is currently disabled because of several
  // issues. We do not want to store subject strings in the regexp object since
  // they might be long and we should not prevent their garbage collection.
  // Passing them to this function explicitly does not help, since we must
  // generate exactly the same IR for both the unoptimizing and optimizing
  // pipelines (otherwise it gets confused when i.e. deopt id's differ).
  // An option would be to store sampling results in the regexp object, but
  // I'm not sure the performance gains are relevant enough.

  // Wrap the body of the regexp in capture #0.
  RegExpNode* captured_body =
      RegExpCapture::ToNode(data->tree, 0, &compiler, compiler.accept());

  RegExpNode* node = captured_body;
  const bool is_end_anchored = data->tree->IsAnchoredAtEnd();
  const bool is_start_anchored = data->tree->IsAnchoredAtStart();
  intptr_t max_length = data->tree->max_match();
  if (!is_start_anchored && !is_sticky) {
    // Add a .*? at the beginning, outside the body capture, unless
    // this expression is anchored at the beginning or is sticky.
    RegExpNode* loop_node = RegExpQuantifier::ToNode(
        0, RegExpTree::kInfinity, false, new (zone) RegExpCharacterClass('*'),
        &compiler, captured_body, data->contains_anchor);

    if (data->contains_anchor) {
      // Unroll loop once, to take care of the case that might start
      // at the start of input.
      ChoiceNode* first_step_node = new (zone) ChoiceNode(2, zone);
      first_step_node->AddAlternative(GuardedAlternative(captured_body));
      first_step_node->AddAlternative(GuardedAlternative(new (zone) TextNode(
          new (zone) RegExpCharacterClass('*'), loop_node)));
      node = first_step_node;
    } else {
      node = loop_node;
    }
  }
  if (is_one_byte) {
    node = node->FilterOneByte(RegExpCompiler::kMaxRecursion, ignore_case);
    // Do it again to propagate the new nodes to places where they were not
    // put because they had not been calculated yet.
    if (node != NULL) {
      node = node->FilterOneByte(RegExpCompiler::kMaxRecursion, ignore_case);
    }
  }

  if (node == NULL) node = new (zone) EndNode(EndNode::BACKTRACK, zone);
  data->node = node;
  Analysis analysis(ignore_case, is_one_byte);
  analysis.EnsureAnalyzed(node);
  if (analysis.has_failed()) {
    const char* error_message = analysis.error_message();
    return CompilationResult(error_message);
  }

  // Native regexp implementation.

  IRRegExpMacroAssembler* macro_assembler = new (zone)
      IRRegExpMacroAssembler(specialization_cid, data->capture_count,
                             parsed_function, ic_data_array, osr_id, zone);

  // Inserted here, instead of in Assembler, because it depends on information
  // in the AST that isn't replicated in the Node structure.
  static const intptr_t kMaxBacksearchLimit = 1024;
  if (is_end_anchored && !is_start_anchored && !is_sticky &&
      max_length < kMaxBacksearchLimit) {
    macro_assembler->SetCurrentPositionFromEnd(max_length);
  }

  if (is_global) {
    macro_assembler->set_global_mode(
        (data->tree->min_match() > 0)
            ? RegExpMacroAssembler::GLOBAL_NO_ZERO_LENGTH_CHECK
            : RegExpMacroAssembler::GLOBAL);
  }

  RegExpEngine::CompilationResult result =
      compiler.Assemble(macro_assembler, node, data->capture_count, pattern);

  if (FLAG_trace_irregexp) {
    macro_assembler->PrintBlocks();
  }

  return result;
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)


RegExpEngine::CompilationResult RegExpEngine::CompileBytecode(
    RegExpCompileData* data,
    const RegExp& regexp,
    bool is_one_byte,
    bool is_sticky,
    Zone* zone) {
  ASSERT(FLAG_interpret_irregexp);
  const String& pattern = String::Handle(zone, regexp.pattern());

  ASSERT(!regexp.IsNull());
  ASSERT(!pattern.IsNull());

  const bool ignore_case = regexp.is_ignore_case();
  const bool is_global = regexp.is_global();

  RegExpCompiler compiler(data->capture_count, ignore_case, is_one_byte);

  // TODO(zerny): Frequency sampling is currently disabled because of several
  // issues. We do not want to store subject strings in the regexp object since
  // they might be long and we should not prevent their garbage collection.
  // Passing them to this function explicitly does not help, since we must
  // generate exactly the same IR for both the unoptimizing and optimizing
  // pipelines (otherwise it gets confused when i.e. deopt id's differ).
  // An option would be to store sampling results in the regexp object, but
  // I'm not sure the performance gains are relevant enough.

  // Wrap the body of the regexp in capture #0.
  RegExpNode* captured_body =
      RegExpCapture::ToNode(data->tree, 0, &compiler, compiler.accept());

  RegExpNode* node = captured_body;
  bool is_end_anchored = data->tree->IsAnchoredAtEnd();
  bool is_start_anchored = data->tree->IsAnchoredAtStart();
  intptr_t max_length = data->tree->max_match();
  if (!is_start_anchored && !is_sticky) {
    // Add a .*? at the beginning, outside the body capture, unless
    // this expression is anchored at the beginning.
    RegExpNode* loop_node = RegExpQuantifier::ToNode(
        0, RegExpTree::kInfinity, false, new (zone) RegExpCharacterClass('*'),
        &compiler, captured_body, data->contains_anchor);

    if (data->contains_anchor) {
      // Unroll loop once, to take care of the case that might start
      // at the start of input.
      ChoiceNode* first_step_node = new (zone) ChoiceNode(2, zone);
      first_step_node->AddAlternative(GuardedAlternative(captured_body));
      first_step_node->AddAlternative(GuardedAlternative(new (zone) TextNode(
          new (zone) RegExpCharacterClass('*'), loop_node)));
      node = first_step_node;
    } else {
      node = loop_node;
    }
  }
  if (is_one_byte) {
    node = node->FilterOneByte(RegExpCompiler::kMaxRecursion, ignore_case);
    // Do it again to propagate the new nodes to places where they were not
    // put because they had not been calculated yet.
    if (node != NULL) {
      node = node->FilterOneByte(RegExpCompiler::kMaxRecursion, ignore_case);
    }
  }

  if (node == NULL) node = new (zone) EndNode(EndNode::BACKTRACK, zone);
  data->node = node;
  Analysis analysis(ignore_case, is_one_byte);
  analysis.EnsureAnalyzed(node);
  if (analysis.has_failed()) {
    const char* error_message = analysis.error_message();
    return CompilationResult(error_message);
  }

  // Bytecode regexp implementation.

  ZoneGrowableArray<uint8_t> buffer(zone, 1024);
  BytecodeRegExpMacroAssembler* macro_assembler =
      new (zone) BytecodeRegExpMacroAssembler(&buffer, zone);

  // Inserted here, instead of in Assembler, because it depends on information
  // in the AST that isn't replicated in the Node structure.
  static const intptr_t kMaxBacksearchLimit = 1024;
  if (is_end_anchored && !is_start_anchored && !is_sticky &&
      max_length < kMaxBacksearchLimit) {
    macro_assembler->SetCurrentPositionFromEnd(max_length);
  }

  if (is_global) {
    macro_assembler->set_global_mode(
        (data->tree->min_match() > 0)
            ? RegExpMacroAssembler::GLOBAL_NO_ZERO_LENGTH_CHECK
            : RegExpMacroAssembler::GLOBAL);
  }

  RegExpEngine::CompilationResult result =
      compiler.Assemble(macro_assembler, node, data->capture_count, pattern);

  if (FLAG_trace_irregexp) {
    macro_assembler->PrintBlocks();
  }

  return result;
}


static void CreateSpecializedFunction(Thread* thread,
                                      Zone* zone,
                                      const RegExp& regexp,
                                      intptr_t specialization_cid,
                                      bool sticky,
                                      const Object& owner) {
  const intptr_t kParamCount = RegExpMacroAssembler::kParamCount;

  Function& fn =
      Function::Handle(zone, Function::New(Symbols::ColonMatcher(),
                                           RawFunction::kIrregexpFunction,
                                           true,   // Static.
                                           false,  // Not const.
                                           false,  // Not abstract.
                                           false,  // Not external.
                                           false,  // Not native.
                                           owner, TokenPosition::kMinSource));

  // TODO(zerny): Share these arrays between all irregexp functions.
  fn.set_num_fixed_parameters(kParamCount);
  fn.set_parameter_types(
      Array::Handle(zone, Array::New(kParamCount, Heap::kOld)));
  fn.set_parameter_names(
      Array::Handle(zone, Array::New(kParamCount, Heap::kOld)));
  fn.SetParameterTypeAt(RegExpMacroAssembler::kParamRegExpIndex,
                        Object::dynamic_type());
  fn.SetParameterNameAt(RegExpMacroAssembler::kParamRegExpIndex,
                        Symbols::This());
  fn.SetParameterTypeAt(RegExpMacroAssembler::kParamStringIndex,
                        Object::dynamic_type());
  fn.SetParameterNameAt(RegExpMacroAssembler::kParamStringIndex,
                        Symbols::string_param());
  fn.SetParameterTypeAt(RegExpMacroAssembler::kParamStartOffsetIndex,
                        Object::dynamic_type());
  fn.SetParameterNameAt(RegExpMacroAssembler::kParamStartOffsetIndex,
                        Symbols::start_index_param());
  fn.set_result_type(Type::Handle(zone, Type::ArrayType()));

  // Cache the result.
  regexp.set_function(specialization_cid, sticky, fn);

  fn.SetRegExpData(regexp, specialization_cid, sticky);
  fn.set_is_debuggable(false);

  // The function is compiled lazily during the first call.
}


RawRegExp* RegExpEngine::CreateRegExp(Thread* thread,
                                      const String& pattern,
                                      bool multi_line,
                                      bool ignore_case) {
  Zone* zone = thread->zone();
  const RegExp& regexp = RegExp::Handle(RegExp::New());

  regexp.set_pattern(pattern);

  if (multi_line) {
    regexp.set_is_multi_line();
  }
  if (ignore_case) {
    regexp.set_is_ignore_case();
  }

  // TODO(zerny): We might want to use normal string searching algorithms
  // for simple patterns.
  regexp.set_is_complex();
  regexp.set_is_global();  // All dart regexps are global.

  if (!FLAG_interpret_irregexp) {
    const Library& lib = Library::Handle(zone, Library::CoreLibrary());
    const Class& owner =
        Class::Handle(zone, lib.LookupClass(Symbols::RegExp()));

    for (intptr_t cid = kOneByteStringCid; cid <= kExternalTwoByteStringCid;
         cid++) {
      CreateSpecializedFunction(thread, zone, regexp, cid, /*sticky=*/false,
                                owner);
      CreateSpecializedFunction(thread, zone, regexp, cid, /*sticky=*/true,
                                owner);
    }
  }

  return regexp.raw();
}


}  // namespace dart
