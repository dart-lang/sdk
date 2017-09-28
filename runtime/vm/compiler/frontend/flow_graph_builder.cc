// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/frontend/flow_graph_builder.h"

#include "lib/invocation_mirror.h"
#include "vm/ast_printer.h"
#include "vm/bit_vector.h"
#include "vm/class_finalizer.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/report.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/token.h"
#include "vm/zone.h"

namespace dart {

DEFINE_FLAG(bool,
            eliminate_type_checks,
            true,
            "Eliminate type checks when allowed by static type analysis.");
DEFINE_FLAG(bool, print_ast, false, "Print abstract syntax tree.");
DEFINE_FLAG(bool, print_scopes, false, "Print scopes of local variables.");
DEFINE_FLAG(bool,
            trace_type_check_elimination,
            false,
            "Trace type check elimination at compile time.");

DECLARE_FLAG(bool, profile_vm);

// Quick access to the locally defined zone() method.
#define Z (zone())

// Quick access to the locally defined thread() method.
#define T (thread())

// Quick synthetic token position.
#define ST(token_pos) ((token_pos).ToSynthetic())

// TODO(srdjan): Allow compiler to add constants as they are encountered in
// the compilation.
const double kCommonDoubleConstants[] = {
    -1.0, -0.5, -0.1, 0.0, 0.1, 0.5, 1.0, 2.0, 4.0, 5.0, 10.0, 20.0, 30.0, 64.0,
    255.0, NAN,
    // From dart:math
    2.718281828459045, 2.302585092994046, 0.6931471805599453,
    1.4426950408889634, 0.4342944819032518, 3.1415926535897932,
    0.7071067811865476, 1.4142135623730951};

uword FlowGraphBuilder::FindDoubleConstant(double value) {
  intptr_t len = sizeof(kCommonDoubleConstants) / sizeof(double);  // NOLINT
  for (intptr_t i = 0; i < len; i++) {
    if (Utils::DoublesBitEqual(value, kCommonDoubleConstants[i])) {
      return reinterpret_cast<uword>(&kCommonDoubleConstants[i]);
    }
  }
  return 0;
}

#define RECOGNIZE_FACTORY(symbol, class_name, constructor_name, cid, fp)       \
  {Symbols::k##symbol##Id, cid, fp, #symbol ", " #cid},  // NOLINT

static struct {
  intptr_t symbol_id;
  intptr_t cid;
  intptr_t finger_print;
  const char* name;
} factory_recognizer_list[] = {RECOGNIZED_LIST_FACTORY_LIST(RECOGNIZE_FACTORY){
    Symbols::kIllegal, -1, -1, NULL}};

#undef RECOGNIZE_FACTORY

intptr_t FactoryRecognizer::ResultCid(const Function& factory) {
  ASSERT(factory.IsFactory());
  const Class& function_class = Class::Handle(factory.Owner());
  const Library& lib = Library::Handle(function_class.library());
  ASSERT((lib.raw() == Library::CoreLibrary()) ||
         (lib.raw() == Library::TypedDataLibrary()));
  const String& factory_name = String::Handle(factory.name());
  for (intptr_t i = 0;
       factory_recognizer_list[i].symbol_id != Symbols::kIllegal; i++) {
    if (String::EqualsIgnoringPrivateKey(
            factory_name,
            Symbols::Symbol(factory_recognizer_list[i].symbol_id))) {
      return factory_recognizer_list[i].cid;
    }
  }
  return kDynamicCid;
}

// Base class for a stack of enclosing statements of interest (e.g.,
// blocks (breakable) and loops (continuable)).
class NestedStatement : public ValueObject {
 public:
  FlowGraphBuilder* owner() const { return owner_; }
  const SourceLabel* label() const { return label_; }
  NestedStatement* outer() const { return outer_; }
  JoinEntryInstr* break_target() const { return break_target_; }

  virtual intptr_t ContextLevel() const;
  virtual void AdjustContextLevel(intptr_t context_level);

  virtual JoinEntryInstr* BreakTargetFor(SourceLabel* label);
  virtual JoinEntryInstr* ContinueTargetFor(SourceLabel* label);

 protected:
  NestedStatement(FlowGraphBuilder* owner, const SourceLabel* label)
      : owner_(owner),
        label_(label),
        outer_(owner->nesting_stack_),
        break_target_(NULL),
        try_index_(owner->try_index()) {
    // Push on the owner's nesting stack.
    owner->nesting_stack_ = this;
  }

  intptr_t try_index() const { return try_index_; }

  virtual ~NestedStatement() {
    // Pop from the owner's nesting stack.
    ASSERT(owner_->nesting_stack_ == this);
    owner_->nesting_stack_ = outer_;
  }

 private:
  FlowGraphBuilder* owner_;
  const SourceLabel* label_;
  NestedStatement* outer_;

  JoinEntryInstr* break_target_;
  const intptr_t try_index_;
};

intptr_t NestedStatement::ContextLevel() const {
  // Context level is determined by the innermost nested statement having one.
  return (outer() == NULL) ? 0 : outer()->ContextLevel();
}

void NestedStatement::AdjustContextLevel(intptr_t context_level) {
  // There must be a NestedContextAdjustment on the nesting stack.
  ASSERT(outer() != NULL);
  outer()->AdjustContextLevel(context_level);
}

intptr_t FlowGraphBuilder::GetNextDeoptId() const {
  intptr_t deopt_id = thread()->GetNextDeoptId();
  if (context_level_array_ != NULL) {
    intptr_t level = context_level();
    context_level_array_->Add(deopt_id);
    context_level_array_->Add(level);
  }
  return deopt_id;
}

intptr_t FlowGraphBuilder::context_level() const {
  return (nesting_stack() == NULL) ? 0 : nesting_stack()->ContextLevel();
}

JoinEntryInstr* NestedStatement::BreakTargetFor(SourceLabel* label) {
  if (label != label_) return NULL;
  if (break_target_ == NULL) {
    break_target_ = new (owner()->zone()) JoinEntryInstr(
        owner()->AllocateBlockId(), try_index(), owner()->GetNextDeoptId());
  }
  return break_target_;
}

JoinEntryInstr* NestedStatement::ContinueTargetFor(SourceLabel* label) {
  return NULL;
}

// A nested statement that has its own context level.
class NestedBlock : public NestedStatement {
 public:
  NestedBlock(FlowGraphBuilder* owner, SequenceNode* node)
      : NestedStatement(owner, node->label()), scope_(node->scope()) {}

  virtual intptr_t ContextLevel() const;

 private:
  LocalScope* scope_;
};

intptr_t NestedBlock::ContextLevel() const {
  return ((scope_ == NULL) || (scope_->num_context_variables() == 0))
             ? NestedStatement::ContextLevel()
             : scope_->context_level();
}

// A nested statement reflecting a context level adjustment.
class NestedContextAdjustment : public NestedStatement {
 public:
  NestedContextAdjustment(FlowGraphBuilder* owner, intptr_t context_level)
      : NestedStatement(owner, NULL), context_level_(context_level) {}

  virtual intptr_t ContextLevel() const { return context_level_; }

  virtual void AdjustContextLevel(intptr_t context_level) {
    ASSERT(context_level <= context_level_);
    context_level_ = context_level;
  }

 private:
  intptr_t context_level_;
};

// A nested statement that can be the target of a continue as well as a
// break.
class NestedLoop : public NestedStatement {
 public:
  NestedLoop(FlowGraphBuilder* owner, SourceLabel* label)
      : NestedStatement(owner, label), continue_target_(NULL) {
    owner->IncrementLoopDepth();
  }

  virtual ~NestedLoop() { owner()->DecrementLoopDepth(); }

  JoinEntryInstr* continue_target() const { return continue_target_; }

  virtual JoinEntryInstr* ContinueTargetFor(SourceLabel* label);

 private:
  JoinEntryInstr* continue_target_;
};

JoinEntryInstr* NestedLoop::ContinueTargetFor(SourceLabel* label) {
  if (label != this->label()) return NULL;
  if (continue_target_ == NULL) {
    continue_target_ = new (owner()->zone()) JoinEntryInstr(
        owner()->AllocateBlockId(), try_index(), owner()->GetNextDeoptId());
  }
  return continue_target_;
}

// A nested switch which can be the target of a break if labeled, and whose
// cases can be the targets of continues.
class NestedSwitch : public NestedStatement {
 public:
  NestedSwitch(FlowGraphBuilder* owner, SwitchNode* node);

  virtual JoinEntryInstr* ContinueTargetFor(SourceLabel* label);

 private:
  GrowableArray<SourceLabel*> case_labels_;
  GrowableArray<JoinEntryInstr*> case_targets_;
};

NestedSwitch::NestedSwitch(FlowGraphBuilder* owner, SwitchNode* node)
    : NestedStatement(owner, node->label()),
      case_labels_(node->body()->length()),
      case_targets_(node->body()->length()) {
  SequenceNode* body = node->body();
  for (intptr_t i = 0; i < body->length(); ++i) {
    CaseNode* case_node = body->NodeAt(i)->AsCaseNode();
    if (case_node != NULL) {
      case_labels_.Add(case_node->label());
      case_targets_.Add(NULL);
    }
  }
}

JoinEntryInstr* NestedSwitch::ContinueTargetFor(SourceLabel* label) {
  // Allocate a join for a case clause that matches the label.  This block
  // is not necessarily targeted by a continue, but we always use a join in
  // the graph anyway.
  for (intptr_t i = 0; i < case_labels_.length(); ++i) {
    if (label != case_labels_[i]) continue;
    if (case_targets_[i] == NULL) {
      case_targets_[i] = new (owner()->zone()) JoinEntryInstr(
          owner()->AllocateBlockId(), try_index(), owner()->GetNextDeoptId());
    }
    return case_targets_[i];
  }
  return NULL;
}

FlowGraphBuilder::FlowGraphBuilder(
    const ParsedFunction& parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    ZoneGrowableArray<intptr_t>* context_level_array,
    InlineExitCollector* exit_collector,
    intptr_t osr_id)
    : parsed_function_(parsed_function),
      ic_data_array_(ic_data_array),
      context_level_array_(context_level_array),
      num_copied_params_(parsed_function.num_copied_params()),
      // All parameters are copied if any parameter is.
      num_non_copied_params_(
          (num_copied_params_ == 0)
              ? parsed_function.function().num_fixed_parameters()
              : 0),
      num_stack_locals_(parsed_function.num_stack_locals()),
      exit_collector_(exit_collector),
      last_used_block_id_(0),  // 0 is used for the graph entry.
      try_index_(CatchClauseNode::kInvalidTryIndex),
      catch_try_index_(CatchClauseNode::kInvalidTryIndex),
      loop_depth_(0),
      graph_entry_(NULL),
      temp_count_(0),
      args_pushed_(0),
      nesting_stack_(NULL),
      osr_id_(osr_id),
      jump_count_(0),
      await_joins_(new (Z) ZoneGrowableArray<JoinEntryInstr*>()),
      await_token_positions_(new (Z) ZoneGrowableArray<TokenPosition>()) {}

void FlowGraphBuilder::AddCatchEntry(CatchBlockEntryInstr* entry) {
  graph_entry_->AddCatchEntry(entry);
}

void InlineExitCollector::PrepareGraphs(FlowGraph* callee_graph) {
  ASSERT(callee_graph->graph_entry()->SuccessorCount() == 1);
  ASSERT(callee_graph->max_block_id() > caller_graph_->max_block_id());
  ASSERT(callee_graph->max_virtual_register_number() >
         caller_graph_->max_virtual_register_number());

  // Adjust the caller's maximum block id and current SSA temp index.
  caller_graph_->set_max_block_id(callee_graph->max_block_id());
  caller_graph_->set_current_ssa_temp_index(
      callee_graph->max_virtual_register_number());

  // Attach the outer environment on each instruction in the callee graph.
  ASSERT(call_->env() != NULL);
  // Scale the edge weights by the call count for the inlined function.
  double scale_factor =
      static_cast<double>(call_->CallCount()) /
      static_cast<double>(caller_graph_->graph_entry()->entry_count());
  for (BlockIterator block_it = callee_graph->postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    if (block->IsTargetEntry()) {
      block->AsTargetEntry()->adjust_edge_weight(scale_factor);
    }
    Instruction* instr = block;
    if (block->env() != NULL) {
      call_->env()->DeepCopyToOuter(callee_graph->zone(), block);
    }
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      instr = it.Current();
      // TODO(zerny): Avoid creating unnecessary environments. Note that some
      // optimizations need deoptimization info for non-deoptable instructions,
      // eg, LICM on GOTOs.
      if (instr->env() != NULL) {
        call_->env()->DeepCopyToOuter(callee_graph->zone(), instr);
      }
    }
    if (instr->IsGoto()) {
      instr->AsGoto()->adjust_edge_weight(scale_factor);
    }
  }

  RemoveUnreachableExits(callee_graph);
}

void InlineExitCollector::AddExit(ReturnInstr* exit) {
  Data data = {NULL, exit};
  exits_.Add(data);
}

void InlineExitCollector::Union(const InlineExitCollector* other) {
  // It doesn't make sense to combine different calls or calls from
  // different graphs.
  ASSERT(caller_graph_ == other->caller_graph_);
  ASSERT(call_ == other->call_);
  exits_.AddArray(other->exits_);
}

int InlineExitCollector::LowestBlockIdFirst(const Data* a, const Data* b) {
  return (a->exit_block->block_id() - b->exit_block->block_id());
}

void InlineExitCollector::RemoveUnreachableExits(FlowGraph* callee_graph) {
  const GrowableArray<BlockEntryInstr*>& postorder = callee_graph->postorder();
  int j = 0;
  for (int i = 0; i < exits_.length(); ++i) {
    BlockEntryInstr* block = exits_[i].exit_return->GetBlock();
    if ((block != NULL) && (0 <= block->postorder_number()) &&
        (block->postorder_number() < postorder.length()) &&
        (postorder[block->postorder_number()] == block)) {
      if (i != j) {
        exits_[j] = exits_[i];
      }
      j++;
    }
  }
  exits_.TruncateTo(j);
}

void InlineExitCollector::SortExits() {
  // Assign block entries here because we did not necessarily know them when
  // the return exit was added to the array.
  for (int i = 0; i < exits_.length(); ++i) {
    exits_[i].exit_block = exits_[i].exit_return->GetBlock();
  }
  exits_.Sort(LowestBlockIdFirst);
}

Definition* InlineExitCollector::JoinReturns(BlockEntryInstr** exit_block,
                                             Instruction** last_instruction,
                                             intptr_t try_index) {
  // First sort the list of exits by block id (caching return instruction
  // block entries as a side effect).
  SortExits();
  intptr_t num_exits = exits_.length();
  if (num_exits == 1) {
    ReturnAt(0)->UnuseAllInputs();
    *exit_block = ExitBlockAt(0);
    *last_instruction = LastInstructionAt(0);
    return call_->HasUses() ? ValueAt(0)->definition() : NULL;
  } else {
    ASSERT(num_exits > 1);
    // Create a join of the returns.
    intptr_t join_id = caller_graph_->max_block_id() + 1;
    caller_graph_->set_max_block_id(join_id);
    JoinEntryInstr* join = new (Z)
        JoinEntryInstr(join_id, try_index, Thread::Current()->GetNextDeoptId());

    // The dominator set of the join is the intersection of the dominator
    // sets of all the predecessors.  If we keep the dominator sets ordered
    // by height in the dominator tree, we can also get the immediate
    // dominator of the join node from the intersection.
    //
    // block_dominators is the dominator set for each block, ordered from
    // the immediate dominator to the root of the dominator tree.  This is
    // the order we collect them in (adding at the end).
    //
    // join_dominators is the join's dominators ordered from the root of the
    // dominator tree to the immediate dominator.  This order supports
    // removing during intersection by truncating the list.
    GrowableArray<BlockEntryInstr*> block_dominators;
    GrowableArray<BlockEntryInstr*> join_dominators;
    for (intptr_t i = 0; i < num_exits; ++i) {
      // Add the control-flow edge.
      GotoInstr* goto_instr =
          new (Z) GotoInstr(join, Thread::Current()->GetNextDeoptId());
      goto_instr->InheritDeoptTarget(zone(), ReturnAt(i));
      LastInstructionAt(i)->LinkTo(goto_instr);
      ExitBlockAt(i)->set_last_instruction(LastInstructionAt(i)->next());
      join->predecessors_.Add(ExitBlockAt(i));

      // Collect the block's dominators.
      block_dominators.Clear();
      BlockEntryInstr* dominator = ExitBlockAt(i)->dominator();
      while (dominator != NULL) {
        block_dominators.Add(dominator);
        dominator = dominator->dominator();
      }

      if (i == 0) {
        // The initial dominator set is the first predecessor's dominator
        // set.  Reverse it.
        for (intptr_t j = block_dominators.length() - 1; j >= 0; --j) {
          join_dominators.Add(block_dominators[j]);
        }
      } else {
        // Intersect the block's dominators with the join's dominators so far.
        intptr_t last = block_dominators.length() - 1;
        for (intptr_t j = 0; j < join_dominators.length(); ++j) {
          intptr_t k = last - j;  // Corresponding index in block_dominators.
          if ((k < 0) || (join_dominators[j] != block_dominators[k])) {
            // We either exhausted the dominators for this block before
            // exhausting the current intersection, or else we found a block
            // on the path from the root of the tree that is not in common.
            // I.e., there cannot be an empty set of dominators.
            ASSERT(j > 0);
            join_dominators.TruncateTo(j);
            break;
          }
        }
      }
    }
    // The immediate dominator of the join is the last one in the ordered
    // intersection.
    join_dominators.Last()->AddDominatedBlock(join);
    *exit_block = join;
    *last_instruction = join;

    // If the call has uses, create a phi of the returns.
    if (call_->HasUses()) {
      // Add a phi of the return values.
      PhiInstr* phi = new (Z) PhiInstr(join, num_exits);
      caller_graph_->AllocateSSAIndexes(phi);
      phi->mark_alive();
      for (intptr_t i = 0; i < num_exits; ++i) {
        ReturnAt(i)->RemoveEnvironment();
        phi->SetInputAt(i, ValueAt(i));
      }
      join->InsertPhi(phi);
      join->InheritDeoptTargetAfter(caller_graph_, call_, phi);
      return phi;
    } else {
      // In the case that the result is unused, remove the return value uses
      // from their definition's use list.
      for (intptr_t i = 0; i < num_exits; ++i) {
        ReturnAt(i)->UnuseAllInputs();
      }
      join->InheritDeoptTargetAfter(caller_graph_, call_, NULL);
      return NULL;
    }
  }
}

void InlineExitCollector::ReplaceCall(TargetEntryInstr* callee_entry) {
  ASSERT(call_->previous() != NULL);
  ASSERT(call_->next() != NULL);
  BlockEntryInstr* call_block = call_->GetBlock();

  // Insert the callee graph into the caller graph.
  BlockEntryInstr* callee_exit = NULL;
  Instruction* callee_last_instruction = NULL;

  if (exits_.length() == 0) {
    // Handle the case when there are no normal return exits from the callee
    // (i.e. the callee unconditionally throws) by inserting an artificial
    // branch (true === true).
    // The true successor is the inlined body, the false successor
    // goes to the rest of the caller graph. It is removed as unreachable code
    // by the constant propagation.
    TargetEntryInstr* false_block = new (Z) TargetEntryInstr(
        caller_graph_->allocate_block_id(), call_block->try_index(),
        Thread::Current()->GetNextDeoptId());
    false_block->InheritDeoptTargetAfter(caller_graph_, call_, NULL);
    false_block->LinkTo(call_->next());
    call_block->ReplaceAsPredecessorWith(false_block);

    ConstantInstr* true_const = caller_graph_->GetConstant(Bool::True());
    BranchInstr* branch = new (Z)
        BranchInstr(new (Z) StrictCompareInstr(
                        TokenPosition::kNoSource, Token::kEQ_STRICT,
                        new (Z) Value(true_const), new (Z) Value(true_const),
                        false, Thread::Current()->GetNextDeoptId()),
                    Thread::Current()->GetNextDeoptId());  // No number check.
    branch->InheritDeoptTarget(zone(), call_);
    *branch->true_successor_address() = callee_entry;
    *branch->false_successor_address() = false_block;

    call_->previous()->AppendInstruction(branch);
    call_block->set_last_instruction(branch);

    // Replace uses of the return value with null to maintain valid
    // SSA form - even though the rest of the caller is unreachable.
    call_->ReplaceUsesWith(caller_graph_->constant_null());

    // Update dominator tree.
    call_block->AddDominatedBlock(callee_entry);
    call_block->AddDominatedBlock(false_block);

  } else {
    Definition* callee_result = JoinReturns(
        &callee_exit, &callee_last_instruction, call_block->try_index());
    if (callee_result != NULL) {
      call_->ReplaceUsesWith(callee_result);
    }
    if (callee_last_instruction == callee_entry) {
      // There are no instructions in the inlined function (e.g., it might be
      // a return of a parameter or a return of a constant defined in the
      // initial definitions).
      call_->previous()->LinkTo(call_->next());
    } else {
      call_->previous()->LinkTo(callee_entry->next());
      callee_last_instruction->LinkTo(call_->next());
    }
    if (callee_exit != callee_entry) {
      // In case of control flow, locally update the predecessors, phis and
      // dominator tree.
      //
      // Pictorially, the graph structure is:
      //
      //   Bc : call_block      Bi : callee_entry
      //     before_call          inlined_head
      //     call               ... other blocks ...
      //     after_call         Be : callee_exit
      //                          inlined_foot
      // And becomes:
      //
      //   Bc : call_block
      //     before_call
      //     inlined_head
      //   ... other blocks ...
      //   Be : callee_exit
      //    inlined_foot
      //    after_call
      //
      // For successors of 'after_call', the call block (Bc) is replaced as a
      // predecessor by the callee exit (Be).
      call_block->ReplaceAsPredecessorWith(callee_exit);
      // For successors of 'inlined_head', the callee entry (Bi) is replaced
      // as a predecessor by the call block (Bc).
      callee_entry->ReplaceAsPredecessorWith(call_block);

      // The callee exit is now the immediate dominator of blocks whose
      // immediate dominator was the call block.
      ASSERT(callee_exit->dominated_blocks().is_empty());
      for (intptr_t i = 0; i < call_block->dominated_blocks().length(); ++i) {
        BlockEntryInstr* block = call_block->dominated_blocks()[i];
        callee_exit->AddDominatedBlock(block);
      }
      // The call block is now the immediate dominator of blocks whose
      // immediate dominator was the callee entry.
      call_block->ClearDominatedBlocks();
      for (intptr_t i = 0; i < callee_entry->dominated_blocks().length(); ++i) {
        BlockEntryInstr* block = callee_entry->dominated_blocks()[i];
        call_block->AddDominatedBlock(block);
      }
    }

    // Callee entry in not in the graph anymore. Remove it from use lists.
    callee_entry->UnuseAllInputs();
  }
  // Neither call nor the graph entry (if present) are in the
  // graph at this point. Remove them from use lists.
  if (callee_entry->PredecessorCount() > 0) {
    callee_entry->PredecessorAt(0)->AsGraphEntry()->UnuseAllInputs();
  }
  call_->UnuseAllInputs();
}

void EffectGraphVisitor::Append(const EffectGraphVisitor& other_fragment) {
  ASSERT(is_open());
  if (other_fragment.is_empty()) return;
  if (is_empty()) {
    entry_ = other_fragment.entry();
  } else {
    exit()->LinkTo(other_fragment.entry());
  }
  exit_ = other_fragment.exit();
}

Value* EffectGraphVisitor::Bind(Definition* definition) {
  ASSERT(is_open());
  owner()->DeallocateTemps(definition->InputCount());
  owner()->add_args_pushed(-definition->ArgumentCount());
  definition->set_temp_index(owner()->AllocateTemp());
  if (is_empty()) {
    entry_ = definition;
  } else {
    exit()->LinkTo(definition);
  }
  exit_ = definition;
  return new (Z) Value(definition);
}

void EffectGraphVisitor::Do(Definition* definition) {
  ASSERT(is_open());
  owner()->DeallocateTemps(definition->InputCount());
  owner()->add_args_pushed(-definition->ArgumentCount());
  if (is_empty()) {
    entry_ = definition;
  } else {
    exit()->LinkTo(definition);
  }
  exit_ = definition;
}

void EffectGraphVisitor::AddInstruction(Instruction* instruction) {
  ASSERT(is_open());
  ASSERT(instruction->IsPushArgument() || !instruction->IsDefinition());
  ASSERT(!instruction->IsBlockEntry());
  owner()->DeallocateTemps(instruction->InputCount());
  owner()->add_args_pushed(-instruction->ArgumentCount());
  if (is_empty()) {
    entry_ = exit_ = instruction;
  } else {
    exit()->LinkTo(instruction);
    exit_ = instruction;
  }
}

void EffectGraphVisitor::AddReturnExit(TokenPosition token_pos, Value* value) {
  ASSERT(is_open());
  ReturnInstr* return_instr =
      new (Z) ReturnInstr(token_pos, value, owner()->GetNextDeoptId());
  AddInstruction(return_instr);
  InlineExitCollector* exit_collector = owner()->exit_collector();
  if (exit_collector != NULL) {
    exit_collector->AddExit(return_instr);
  }
  CloseFragment();
}

void EffectGraphVisitor::Goto(JoinEntryInstr* join) {
  ASSERT(is_open());
  if (is_empty()) {
    entry_ = new (Z) GotoInstr(join, owner()->GetNextDeoptId());
  } else {
    exit()->Goto(join);
  }
  CloseFragment();
}

// Appends a graph fragment to a block entry instruction.  Returns the entry
// instruction if the fragment was empty or else the exit of the fragment if
// it was non-empty (so NULL if the fragment is closed).
//
// Note that the fragment is no longer a valid fragment after calling this
// function -- the fragment is closed at its entry because the entry has a
// predecessor in the graph.
static Instruction* AppendFragment(BlockEntryInstr* entry,
                                   const EffectGraphVisitor& fragment) {
  if (fragment.is_empty()) return entry;
  entry->LinkTo(fragment.entry());
  return fragment.exit();
}

void EffectGraphVisitor::Join(const TestGraphVisitor& test_fragment,
                              const EffectGraphVisitor& true_fragment,
                              const EffectGraphVisitor& false_fragment) {
  // We have: a test graph fragment with zero, one, or two available exits;
  // and a pair of effect graph fragments with zero or one available exits.
  // We want to append the branch and (if necessary) a join node to this
  // graph fragment.
  ASSERT(is_open());

  // 1. Connect the test to this graph.
  Append(test_fragment);

  // 2. Connect the true and false bodies to the test and record their exits
  // (if any).
  BlockEntryInstr* true_entry = test_fragment.CreateTrueSuccessor();
  Instruction* true_exit = AppendFragment(true_entry, true_fragment);

  BlockEntryInstr* false_entry = test_fragment.CreateFalseSuccessor();
  Instruction* false_exit = AppendFragment(false_entry, false_fragment);

  // 3. Add a join or select one (or neither) of the arms as exit.
  if (true_exit == NULL) {
    exit_ = false_exit;  // May be NULL.
  } else if (false_exit == NULL) {
    exit_ = true_exit;
  } else {
    JoinEntryInstr* join =
        new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                               owner()->GetNextDeoptId());
    true_exit->Goto(join);
    false_exit->Goto(join);
    exit_ = join;
  }
}

void EffectGraphVisitor::TieLoop(
    TokenPosition token_pos,
    const TestGraphVisitor& test_fragment,
    const EffectGraphVisitor& body_fragment,
    const EffectGraphVisitor& test_preamble_fragment) {
  // We have: a test graph fragment with zero, one, or two available exits;
  // and an effect graph fragment with zero or one available exits.  We want
  // to append the 'while loop' consisting of the test graph fragment as
  // condition and the effect graph fragment as body.
  ASSERT(is_open());

  // 1. Connect the body to the test if it is reachable, and if so record
  // its exit (if any).
  BlockEntryInstr* body_entry = test_fragment.CreateTrueSuccessor();
  Instruction* body_exit = AppendFragment(body_entry, body_fragment);

  // 2. Connect the test to this graph, including the body if reachable and
  // using a fresh join node if the body is reachable and has an open exit.
  if (body_exit == NULL) {
    Append(test_preamble_fragment);
    Append(test_fragment);
  } else {
    JoinEntryInstr* join =
        new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                               owner()->GetNextDeoptId());
    CheckStackOverflowInstr* check = new (Z) CheckStackOverflowInstr(
        token_pos, owner()->loop_depth(), owner()->GetNextDeoptId());
    join->LinkTo(check);
    if (!test_preamble_fragment.is_empty()) {
      check->LinkTo(test_preamble_fragment.entry());
      test_preamble_fragment.exit()->LinkTo(test_fragment.entry());
    } else {
      check->LinkTo(test_fragment.entry());
    }
    Goto(join);
    body_exit->Goto(join);
  }

  // 3. Set the exit to the graph to be the false successor of the test, a
  // fresh target node
  exit_ = test_fragment.CreateFalseSuccessor();
}

PushArgumentInstr* EffectGraphVisitor::PushArgument(Value* value) {
  owner_->add_args_pushed(1);
  PushArgumentInstr* result = new (Z) PushArgumentInstr(value);
  AddInstruction(result);
  return result;
}

Definition* EffectGraphVisitor::BuildStoreTemp(const LocalVariable& local,
                                               Value* value,
                                               TokenPosition token_pos) {
  ASSERT(!local.is_captured());
  ASSERT(!token_pos.IsClassifying());
  return new (Z) StoreLocalInstr(local, value, ST(token_pos));
}

Definition* EffectGraphVisitor::BuildStoreExprTemp(Value* value,
                                                   TokenPosition token_pos) {
  return BuildStoreTemp(*owner()->parsed_function().expression_temp_var(),
                        value, token_pos);
}

Definition* EffectGraphVisitor::BuildLoadExprTemp(TokenPosition token_pos) {
  ASSERT(!token_pos.IsClassifying());
  return BuildLoadLocal(*owner()->parsed_function().expression_temp_var(),
                        token_pos);
}

Definition* EffectGraphVisitor::BuildStoreLocal(const LocalVariable& local,
                                                Value* value,
                                                TokenPosition token_pos) {
  if (local.is_captured()) {
    LocalVariable* tmp_var = EnterTempLocalScope(value);
    intptr_t delta = owner()->context_level() - local.owner()->context_level();
    ASSERT(delta >= 0);
    Value* context = Bind(BuildCurrentContext(token_pos));
    while (delta-- > 0) {
      context = Bind(new (Z) LoadFieldInstr(context, Context::parent_offset(),
                                            Type::ZoneHandle(Z, Type::null()),
                                            token_pos));
    }
    Value* tmp_val = Bind(new (Z) LoadLocalInstr(*tmp_var, token_pos));
    StoreInstanceFieldInstr* store = new (Z)
        StoreInstanceFieldInstr(Context::variable_offset(local.index()),
                                context, tmp_val, kEmitStoreBarrier, token_pos);
    Do(store);
    return ExitTempLocalScope(value);
  } else {
    return new (Z) StoreLocalInstr(local, value, token_pos);
  }
}

Definition* EffectGraphVisitor::BuildLoadLocal(const LocalVariable& local,
                                               TokenPosition token_pos) {
  if (local.IsConst()) {
    return new (Z) ConstantInstr(*local.ConstValue(), token_pos);
  } else if (local.is_captured()) {
    intptr_t delta = owner()->context_level() - local.owner()->context_level();
    ASSERT(delta >= 0);
    Value* context = Bind(BuildCurrentContext(token_pos));
    while (delta-- > 0) {
      context = Bind(new (Z) LoadFieldInstr(context, Context::parent_offset(),
                                            Type::ZoneHandle(Z, Type::null()),
                                            token_pos));
    }
    LoadFieldInstr* load =
        new (Z) LoadFieldInstr(context, Context::variable_offset(local.index()),
                               local.type(), token_pos);
    load->set_is_immutable(local.is_final());
    return load;
  } else {
    return new (Z) LoadLocalInstr(local, token_pos);
  }
}

// Stores current context into the 'variable'
void EffectGraphVisitor::BuildSaveContext(const LocalVariable& variable,
                                          TokenPosition token_pos) {
  ASSERT(token_pos.IsSynthetic() || token_pos.IsNoSource());
  Value* context = Bind(BuildCurrentContext(token_pos));
  Do(BuildStoreLocal(variable, context, token_pos));
}

// Loads context saved in 'context_variable' into the current context.
void EffectGraphVisitor::BuildRestoreContext(const LocalVariable& variable,
                                             TokenPosition token_pos) {
  Value* load_saved_context = Bind(BuildLoadLocal(variable, token_pos));
  Do(BuildStoreContext(load_saved_context, token_pos));
}

Definition* EffectGraphVisitor::BuildStoreContext(Value* value,
                                                  TokenPosition token_pos) {
  return new (Z) StoreLocalInstr(
      *owner()->parsed_function().current_context_var(), value, token_pos);
}

Definition* EffectGraphVisitor::BuildCurrentContext(TokenPosition token_pos) {
  return new (Z) LoadLocalInstr(
      *owner()->parsed_function().current_context_var(), token_pos);
}

void TestGraphVisitor::ConnectBranchesTo(
    const GrowableArray<TargetEntryInstr**>& branches,
    JoinEntryInstr* join) const {
  ASSERT(!branches.is_empty());
  for (intptr_t i = 0; i < branches.length(); i++) {
    TargetEntryInstr* target = new (Z)
        TargetEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                         owner()->GetNextDeoptId());
    *(branches[i]) = target;
    target->Goto(join);
  }
}

void TestGraphVisitor::IfTrueGoto(JoinEntryInstr* join) const {
  ConnectBranchesTo(true_successor_addresses_, join);
}

void TestGraphVisitor::IfFalseGoto(JoinEntryInstr* join) const {
  ConnectBranchesTo(false_successor_addresses_, join);
}

BlockEntryInstr* TestGraphVisitor::CreateSuccessorFor(
    const GrowableArray<TargetEntryInstr**>& branches) const {
  ASSERT(!branches.is_empty());

  if (branches.length() == 1) {
    TargetEntryInstr* target = new (Z)
        TargetEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                         owner()->GetNextDeoptId());
    *(branches[0]) = target;
    return target;
  }

  JoinEntryInstr* join =
      new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                             owner()->GetNextDeoptId());
  ConnectBranchesTo(branches, join);
  return join;
}

BlockEntryInstr* TestGraphVisitor::CreateTrueSuccessor() const {
  return CreateSuccessorFor(true_successor_addresses_);
}

BlockEntryInstr* TestGraphVisitor::CreateFalseSuccessor() const {
  return CreateSuccessorFor(false_successor_addresses_);
}

void TestGraphVisitor::ReturnValue(Value* value) {
  Isolate* isolate = Isolate::Current();
  if (isolate->type_checks() || isolate->asserts()) {
    value = Bind(new (Z) AssertBooleanInstr(condition_token_pos(), value,
                                            owner()->GetNextDeoptId()));
  }
  Value* constant_true = Bind(new (Z) ConstantInstr(Bool::True()));
  StrictCompareInstr* comp = new (Z) StrictCompareInstr(
      condition_token_pos(), Token::kEQ_STRICT, value, constant_true, false,
      owner()->GetNextDeoptId());  // No number check.
  BranchInstr* branch = new (Z) BranchInstr(comp, owner()->GetNextDeoptId());
  AddInstruction(branch);
  CloseFragment();

  true_successor_addresses_.Add(branch->true_successor_address());
  false_successor_addresses_.Add(branch->false_successor_address());
}

void TestGraphVisitor::MergeBranchWithStrictCompare(StrictCompareInstr* comp) {
  BranchInstr* branch = new (Z) BranchInstr(comp, owner()->GetNextDeoptId());
  AddInstruction(branch);
  CloseFragment();
  true_successor_addresses_.Add(branch->true_successor_address());
  false_successor_addresses_.Add(branch->false_successor_address());
}

void TestGraphVisitor::MergeBranchWithNegate(BooleanNegateInstr* neg) {
  ASSERT(!Isolate::Current()->type_checks());
  Value* constant_true = Bind(new (Z) ConstantInstr(Bool::True()));
  StrictCompareInstr* comp = new (Z) StrictCompareInstr(
      condition_token_pos(), Token::kNE_STRICT, neg->value(), constant_true,
      false, owner()->GetNextDeoptId());  // No number check.
  BranchInstr* branch = new (Z) BranchInstr(comp, owner()->GetNextDeoptId());
  AddInstruction(branch);
  CloseFragment();
  true_successor_addresses_.Add(branch->true_successor_address());
  false_successor_addresses_.Add(branch->false_successor_address());
}

void TestGraphVisitor::ReturnDefinition(Definition* definition) {
  StrictCompareInstr* comp = definition->AsStrictCompare();
  if (comp != NULL) {
    MergeBranchWithStrictCompare(comp);
    return;
  }
  if (!Isolate::Current()->type_checks()) {
    BooleanNegateInstr* neg = definition->AsBooleanNegate();
    if (neg != NULL) {
      MergeBranchWithNegate(neg);
      return;
    }
  }
  ReturnValue(Bind(definition));
}

// Special handling for AND/OR.
void TestGraphVisitor::VisitBinaryOpNode(BinaryOpNode* node) {
  // Operators "&&" and "||" cannot be overloaded therefore do not call
  // operator.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    TestGraphVisitor for_left(owner(), node->left()->token_pos());
    node->left()->Visit(&for_left);

    TestGraphVisitor for_right(owner(), node->right()->token_pos());
    node->right()->Visit(&for_right);

    Append(for_left);

    if (node->kind() == Token::kAND) {
      AppendFragment(for_left.CreateTrueSuccessor(), for_right);
      true_successor_addresses_.AddArray(for_right.true_successor_addresses_);
      false_successor_addresses_.AddArray(for_left.false_successor_addresses_);
      false_successor_addresses_.AddArray(for_right.false_successor_addresses_);
    } else {
      ASSERT(node->kind() == Token::kOR);
      AppendFragment(for_left.CreateFalseSuccessor(), for_right);
      false_successor_addresses_.AddArray(for_right.false_successor_addresses_);
      true_successor_addresses_.AddArray(for_left.true_successor_addresses_);
      true_successor_addresses_.AddArray(for_right.true_successor_addresses_);
    }
    CloseFragment();
    return;
  }
  ValueGraphVisitor::VisitBinaryOpNode(node);
}

void EffectGraphVisitor::Bailout(const char* reason) const {
  owner()->Bailout(reason);
}

void EffectGraphVisitor::InlineBailout(const char* reason) const {
  owner()->function().set_is_inlinable(false);
  if (owner()->IsInlining()) owner()->Bailout(reason);
}

// <Statement> ::= Return { value:                <Expression>
//                          inlined_finally_list: <InlinedFinally>* }
void EffectGraphVisitor::VisitReturnNode(ReturnNode* node) {
  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* return_value = for_value.value();

  // Call to stub that checks whether the debugger is in single
  // step mode. This call must happen before the contexts are
  // unchained so that captured variables can be inspected.
  // No debugger check is done in native functions or for return
  // statements for which there is no associated source position.
  const Function& function = owner()->function();
#if !defined(PRODUCT)
  if (node->token_pos().IsDebugPause() && !function.is_native()) {
    AddInstruction(new (Z) DebugStepCheckInstr(node->token_pos(),
                                               RawPcDescriptors::kRuntimeCall,
                                               owner()->GetNextDeoptId()));
  }
#endif

  NestedContextAdjustment context_adjustment(owner(), owner()->context_level());

  if (node->inlined_finally_list_length() > 0) {
    LocalVariable* temp = owner()->parsed_function().finally_return_temp_var();
    ASSERT(temp != NULL);
    Do(BuildStoreLocal(*temp, return_value, node->token_pos()));
    for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
      InlineBailout("EffectGraphVisitor::VisitReturnNode (exception)");
      EffectGraphVisitor for_effect(owner());
      node->InlinedFinallyNodeAt(i)->Visit(&for_effect);
      Append(for_effect);
      if (!is_open()) {
        return;
      }
    }
    return_value = Bind(BuildLoadLocal(*temp, node->token_pos()));
  }

  if (Isolate::Current()->type_checks()) {
    const bool is_implicit_dynamic_getter =
        (!function.is_static() &&
         ((function.kind() == RawFunction::kImplicitGetter) ||
          (function.kind() == RawFunction::kImplicitStaticFinalGetter)));
    // Implicit getters do not need a type check at return, unless they compute
    // the initial value of a static field.
    // The body of a constructor cannot modify the type of the
    // constructed instance, which is passed in as an implicit parameter.
    // However, factories may create an instance of the wrong type.
    if (!is_implicit_dynamic_getter && !function.IsGenerativeConstructor()) {
      const AbstractType& dst_type =
          AbstractType::ZoneHandle(Z, function.result_type());
      return_value =
          BuildAssignableValue(node->value()->token_pos(), return_value,
                               dst_type, Symbols::FunctionResult());
    }
  }

  if (FLAG_causal_async_stacks &&
      (function.IsAsyncClosure() || function.IsAsyncGenClosure())) {
    // We are returning from an asynchronous closure. Before we do that, be
    // sure to clear the thread's asynchronous stack trace.
    const Function& async_clear_thread_stack_trace = Function::ZoneHandle(
        Z, isolate()->object_store()->async_clear_thread_stack_trace());
    ZoneGrowableArray<PushArgumentInstr*>* no_arguments =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(0);
    const int kTypeArgsLen = 0;
    StaticCallInstr* call_async_clear_thread_stack_trace =
        new (Z) StaticCallInstr(node->token_pos().ToSynthetic(),
                                async_clear_thread_stack_trace, kTypeArgsLen,
                                Object::null_array(), no_arguments,
                                owner()->ic_data_array(),
                                owner()->GetNextDeoptId(), ICData::kStatic);
    Do(call_async_clear_thread_stack_trace);
  }

  // Async functions contain two types of return statements:
  // 1) Returns that should complete the completer once all finally blocks have
  //    been inlined (call: :async_completer.complete(return_value)). These
  //    returns end up returning null in the end.
  // 2) "Continuation" returns that should not complete the completer but return
  //    the value.
  //
  // We distinguish those kinds of nodes via is_regular_return().
  //
  if (function.IsAsyncClosure() &&
      (node->return_type() == ReturnNode::kRegular)) {
    // Temporary store the computed return value.
    Do(BuildStoreExprTemp(return_value, node->token_pos()));

    LocalVariable* rcv_var =
        node->scope()->LookupVariable(Symbols::AsyncCompleter(), false);
    ASSERT(rcv_var != NULL && rcv_var->is_captured());
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
    Value* rcv_value = Bind(BuildLoadLocal(*rcv_var, node->token_pos()));
    arguments->Add(PushArgument(rcv_value));
    Value* returned_value = Bind(BuildLoadExprTemp(node->token_pos()));
    arguments->Add(PushArgument(returned_value));
    // Call a helper function to complete the completer. The debugger
    // uses the helper function to know when to step-out.
    const Function& complete_on_async_return = Function::ZoneHandle(
        Z, isolate()->object_store()->complete_on_async_return());
    ASSERT(!complete_on_async_return.IsNull());
    const int kTypeArgsLen = 0;
    StaticCallInstr* call = new (Z) StaticCallInstr(
        node->token_pos().ToSynthetic(), complete_on_async_return, kTypeArgsLen,
        Object::null_array(), arguments, owner()->ic_data_array(),
        owner()->GetNextDeoptId(), ICData::kStatic);
    Do(call);

    // Rebind the return value for the actual return call to be null.
    return_value = BuildNullValue(node->token_pos());
  }

  intptr_t current_context_level = owner()->context_level();
  ASSERT(current_context_level >= 0);
  if (HasContextScope()) {
    UnchainContexts(current_context_level);
  }

  AddReturnExit(node->token_pos(), return_value);

  if ((function.IsAsyncClosure() || function.IsSyncGenClosure() ||
       function.IsAsyncGenClosure()) &&
      (node->return_type() == ReturnNode::kContinuationTarget)) {
    JoinEntryInstr* const join =
        new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                               owner()->GetNextDeoptId());
    owner()->await_joins()->Add(join);
    exit_ = join;
  }
}

// <Expression> ::= Literal { literal: Instance }
void EffectGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  ReturnDefinition(new (Z) ConstantInstr(node->literal(), node->token_pos()));
}

// Type nodes are used when a type is referenced as a literal. Type nodes
// can also be used for the right-hand side of instanceof comparisons,
// but they are handled specially in that context, not here.
void EffectGraphVisitor::VisitTypeNode(TypeNode* node) {
  return;
}

void ValueGraphVisitor::VisitTypeNode(TypeNode* node) {
  const AbstractType& type = node->type();
  // Type may be malbounded, but not malformed.
  ASSERT(type.IsFinalized() && !type.IsMalformed());
  if (type.IsInstantiated()) {
    ReturnDefinition(new (Z) ConstantInstr(type));
    return;
  }
  const TokenPosition token_pos = node->token_pos();
  Value* instantiator_type_arguments = NULL;
  if (type.IsInstantiated(kCurrentClass)) {
    instantiator_type_arguments = BuildNullValue(token_pos);
  } else {
    instantiator_type_arguments = BuildInstantiatorTypeArguments(token_pos);
  }
  Value* function_type_arguments = NULL;
  if (type.IsInstantiated(kFunctions)) {
    function_type_arguments = BuildNullValue(token_pos);
  } else {
    function_type_arguments = BuildFunctionTypeArguments(token_pos);
  }
  ReturnDefinition(new (Z) InstantiateTypeInstr(
      token_pos, type, instantiator_type_arguments, function_type_arguments,
      owner()->GetNextDeoptId()));
}

// Returns true if the type check can be skipped, for example, if the
// destination type is dynamic or if the compile type of the value is a subtype
// of the destination type.
bool EffectGraphVisitor::CanSkipTypeCheck(TokenPosition token_pos,
                                          Value* value,
                                          const AbstractType& dst_type,
                                          const String& dst_name) {
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());

  // If the destination type is malformed or malbounded, a dynamic type error
  // must be thrown at run time.
  if (dst_type.IsMalformedOrMalbounded()) {
    return false;
  }

  // Any type is more specific than the dynamic type, the Object type, or void.
  if (dst_type.IsDynamicType() || dst_type.IsObjectType() ||
      dst_type.IsVoidType()) {
    return true;
  }

  // Do not perform type check elimination if this optimization is turned off.
  if (!FLAG_eliminate_type_checks) {
    return false;
  }

  // If nothing is known about the value, as is the case for passed-in
  // parameters, and since dst_type is not one of the tested cases above, then
  // the type test cannot be eliminated.
  if (value == NULL) {
    return false;
  }

  const bool eliminated = value->Type()->IsAssignableTo(dst_type);
  if (FLAG_trace_type_check_elimination) {
    FlowGraphPrinter::PrintTypeCheck(owner()->parsed_function(), token_pos,
                                     value, dst_type, dst_name, eliminated);
  }
  return eliminated;
}

// <Expression> :: Assignable { expr:     <Expression>
//                              type:     AbstractType
//                              dst_name: String }
void EffectGraphVisitor::VisitAssignableNode(AssignableNode* node) {
  ValueGraphVisitor for_value(owner());
  node->expr()->Visit(&for_value);
  Append(for_value);
  if (CanSkipTypeCheck(node->expr()->token_pos(), for_value.value(),
                       node->type(), node->dst_name())) {
    ReturnValue(for_value.value());
  } else {
    ReturnDefinition(BuildAssertAssignable(node->expr()->token_pos(),
                                           for_value.value(), node->type(),
                                           node->dst_name()));
  }
}

void ValueGraphVisitor::VisitAssignableNode(AssignableNode* node) {
  ValueGraphVisitor for_value(owner());
  node->expr()->Visit(&for_value);
  Append(for_value);
  ReturnValue(BuildAssignableValue(node->expr()->token_pos(), for_value.value(),
                                   node->type(), node->dst_name()));
}

// <Expression> :: BinaryOp { kind:  Token::Kind
//                            left:  <Expression>
//                            right: <Expression> }
void EffectGraphVisitor::VisitBinaryOpNode(BinaryOpNode* node) {
  // Operators "&&" and "||" cannot be overloaded therefore do not call
  // operator.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    // See ValueGraphVisitor::VisitBinaryOpNode.
    TestGraphVisitor for_left(owner(), node->left()->token_pos());
    node->left()->Visit(&for_left);
    EffectGraphVisitor empty(owner());
    Isolate* isolate = Isolate::Current();
    if (isolate->type_checks() || isolate->asserts()) {
      ValueGraphVisitor for_right(owner());
      node->right()->Visit(&for_right);
      Value* right_value = for_right.value();
      for_right.Do(new (Z) AssertBooleanInstr(
          node->right()->token_pos(), right_value, owner()->GetNextDeoptId()));
      if (node->kind() == Token::kAND) {
        Join(for_left, for_right, empty);
      } else {
        Join(for_left, empty, for_right);
      }
    } else {
      EffectGraphVisitor for_right(owner());
      node->right()->Visit(&for_right);
      if (node->kind() == Token::kAND) {
        Join(for_left, for_right, empty);
      } else {
        Join(for_left, empty, for_right);
      }
    }
    return;
  }
  ASSERT(node->kind() != Token::kIFNULL);
  ValueGraphVisitor for_left_value(owner());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  PushArgumentInstr* push_left = PushArgument(for_left_value.value());

  ValueGraphVisitor for_right_value(owner());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  PushArgumentInstr* push_right = PushArgument(for_right_value.value());

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  arguments->Add(push_left);
  arguments->Add(push_right);
  const String& name = Symbols::Token(node->kind());
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgsChecked = 2;
  InstanceCallInstr* call = new (Z)
      InstanceCallInstr(node->token_pos(), name, node->kind(), arguments,
                        kTypeArgsLen, Object::null_array(), kNumArgsChecked,
                        owner()->ic_data_array(), owner()->GetNextDeoptId());
  ReturnDefinition(call);
}

// Special handling for AND/OR.
void ValueGraphVisitor::VisitBinaryOpNode(BinaryOpNode* node) {
  // Operators "&&" and "||" cannot be overloaded therefore do not call
  // operator.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    // Implement short-circuit logic: do not evaluate right if evaluation
    // of left is sufficient.
    // AND:  left ? right === true : false;
    // OR:   left ? true : right === true;

    TestGraphVisitor for_test(owner(), node->left()->token_pos());
    node->left()->Visit(&for_test);

    ValueGraphVisitor for_right(owner());
    node->right()->Visit(&for_right);
    Value* right_value = for_right.value();
    Isolate* isolate = Isolate::Current();
    if (isolate->type_checks() || isolate->asserts()) {
      right_value = for_right.Bind(new (Z) AssertBooleanInstr(
          node->right()->token_pos(), right_value, owner()->GetNextDeoptId()));
    }
    Value* constant_true = for_right.Bind(new (Z) ConstantInstr(Bool::True()));
    Value* compare = for_right.Bind(new (Z) StrictCompareInstr(
        node->token_pos(), Token::kEQ_STRICT, right_value, constant_true, false,
        owner()->GetNextDeoptId()));  // No number check.
    for_right.Do(BuildStoreExprTemp(compare, node->token_pos()));

    if (node->kind() == Token::kAND) {
      ValueGraphVisitor for_false(owner());
      Value* constant_false =
          for_false.Bind(new (Z) ConstantInstr(Bool::False()));
      for_false.Do(BuildStoreExprTemp(constant_false, node->token_pos()));
      Join(for_test, for_right, for_false);
    } else {
      ASSERT(node->kind() == Token::kOR);
      ValueGraphVisitor for_true(owner());
      Value* constant_true = for_true.Bind(new (Z) ConstantInstr(Bool::True()));
      for_true.Do(BuildStoreExprTemp(constant_true, node->token_pos()));
      Join(for_test, for_true, for_right);
    }
    ReturnDefinition(BuildLoadExprTemp(node->token_pos()));
    return;
  }

  EffectGraphVisitor::VisitBinaryOpNode(node);
}

PushArgumentInstr* EffectGraphVisitor::PushInstantiatorTypeArguments(
    const AbstractType& type,
    TokenPosition token_pos) {
  if (type.IsInstantiated(kCurrentClass)) {
    return PushArgument(BuildNullValue(token_pos));
  } else {
    Value* instantiator_type_args = BuildInstantiatorTypeArguments(token_pos);
    return PushArgument(instantiator_type_args);
  }
}

PushArgumentInstr* EffectGraphVisitor::PushFunctionTypeArguments(
    const AbstractType& type,
    TokenPosition token_pos) {
  if (type.IsInstantiated(kFunctions)) {
    return PushArgument(BuildNullValue(token_pos));
  } else {
    Value* function_type_args = BuildFunctionTypeArguments(token_pos);
    return PushArgument(function_type_args);
  }
}

Value* EffectGraphVisitor::BuildNullValue(TokenPosition token_pos) {
  return Bind(
      new (Z) ConstantInstr(Object::ZoneHandle(Z, Object::null()), token_pos));
}

Value* EffectGraphVisitor::BuildEmptyTypeArguments(TokenPosition token_pos) {
  return Bind(new (Z) ConstantInstr(
      TypeArguments::ZoneHandle(Z, Object::empty_type_arguments().raw()),
      token_pos));
}

// Used for testing incoming arguments.
AssertAssignableInstr* EffectGraphVisitor::BuildAssertAssignable(
    TokenPosition token_pos,
    Value* value,
    const AbstractType& dst_type,
    const String& dst_name) {
  // Build the type check computation.
  Value* instantiator_type_arguments = NULL;
  Value* function_type_arguments = NULL;
  if (dst_type.IsInstantiated(kCurrentClass)) {
    instantiator_type_arguments = BuildNullValue(token_pos);
  } else {
    instantiator_type_arguments = BuildInstantiatorTypeArguments(token_pos);
  }
  if (dst_type.IsInstantiated(kFunctions)) {
    function_type_arguments = BuildNullValue(token_pos);
  } else {
    function_type_arguments = BuildFunctionTypeArguments(token_pos);
  }

  const intptr_t deopt_id = owner()->GetNextDeoptId();
  return new (Z) AssertAssignableInstr(
      token_pos, value, instantiator_type_arguments, function_type_arguments,
      dst_type, dst_name, deopt_id);
}

// Used for type casts and to test assignments.
Value* EffectGraphVisitor::BuildAssignableValue(TokenPosition token_pos,
                                                Value* value,
                                                const AbstractType& dst_type,
                                                const String& dst_name) {
  if (CanSkipTypeCheck(token_pos, value, dst_type, dst_name)) {
    return value;
  }
  return Bind(BuildAssertAssignable(token_pos, value, dst_type, dst_name));
}

void EffectGraphVisitor::BuildTypeTest(ComparisonNode* node) {
  ASSERT(Token::IsTypeTestOperator(node->kind()));
  const AbstractType& type = node->right()->AsTypeNode()->type();
  ASSERT(type.IsFinalized() && !type.IsMalformedOrMalbounded());
  const bool negate_result = (node->kind() == Token::kISNOT);
  // All objects are instances of type T if Object type is a subtype of type T.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());
  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, NULL, NULL, Heap::kOld)) {
    // Must evaluate left side.
    EffectGraphVisitor for_left_value(owner());
    node->left()->Visit(&for_left_value);
    Append(for_left_value);
    ReturnDefinition(new (Z) ConstantInstr(Bool::Get(!negate_result)));
    return;
  }
  ValueGraphVisitor for_left_value(owner());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);

  // We now know type is a real class (!num, !int, !smi, !string)
  // and the type check could NOT be removed at compile time.
  PushArgumentInstr* push_left = PushArgument(for_left_value.value());
  if (FlowGraphBuilder::SimpleInstanceOfType(type)) {
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
    arguments->Add(push_left);
    Value* type_const = Bind(new (Z) ConstantInstr(type));
    arguments->Add(PushArgument(type_const));
    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 2;
    Definition* result = new (Z) InstanceCallInstr(
        node->token_pos(),
        Library::PrivateCoreLibName(Symbols::_simpleInstanceOf()), node->kind(),
        arguments, kTypeArgsLen,
        Object::null_array(),  // No argument names.
        kNumArgsChecked, owner()->ic_data_array(), owner()->GetNextDeoptId());
    if (negate_result) {
      result = new (Z) BooleanNegateInstr(Bind(result));
    }
    ReturnDefinition(result);
    return;
  }

  PushArgumentInstr* push_instantiator_type_args =
      PushInstantiatorTypeArguments(type, node->token_pos());
  PushArgumentInstr* push_function_type_args =
      PushFunctionTypeArguments(type, node->token_pos());
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(4);
  arguments->Add(push_left);
  arguments->Add(push_instantiator_type_args);
  arguments->Add(push_function_type_args);
  Value* type_const = Bind(new (Z) ConstantInstr(type));
  arguments->Add(PushArgument(type_const));
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgsChecked = 1;
  Definition* result = new (Z) InstanceCallInstr(
      node->token_pos(), Library::PrivateCoreLibName(Symbols::_instanceOf()),
      node->kind(), arguments, kTypeArgsLen,
      Object::null_array(),  // No argument names.
      kNumArgsChecked, owner()->ic_data_array(), owner()->GetNextDeoptId());
  if (negate_result) {
    result = new (Z) BooleanNegateInstr(Bind(result));
  }
  ReturnDefinition(result);
}

void EffectGraphVisitor::BuildTypeCast(ComparisonNode* node) {
  ASSERT(Token::IsTypeCastOperator(node->kind()));
  ASSERT(!node->right()->AsTypeNode()->type().IsNull());
  const AbstractType& type = node->right()->AsTypeNode()->type();
  ASSERT(type.IsFinalized() && !type.IsMalformed() && !type.IsMalbounded());
  ValueGraphVisitor for_value(owner());
  node->left()->Visit(&for_value);
  Append(for_value);
  if (CanSkipTypeCheck(node->token_pos(), for_value.value(), type,
                       Symbols::InTypeCast())) {
    ReturnValue(for_value.value());
    return;
  }
  PushArgumentInstr* push_left = PushArgument(for_value.value());
  PushArgumentInstr* push_instantiator_type_args =
      PushInstantiatorTypeArguments(type, node->token_pos());
  PushArgumentInstr* push_function_type_args =
      PushFunctionTypeArguments(type, node->token_pos());
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(4);
  arguments->Add(push_left);
  arguments->Add(push_instantiator_type_args);
  arguments->Add(push_function_type_args);
  Value* type_arg = Bind(new (Z) ConstantInstr(type));
  arguments->Add(PushArgument(type_arg));
  const int kTypeArgsLen = 0;
  const intptr_t kNumArgsChecked = 1;
  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      node->token_pos(), Library::PrivateCoreLibName(Symbols::_as()),
      node->kind(), arguments, kTypeArgsLen,
      Object::null_array(),  // No argument names.
      kNumArgsChecked, owner()->ic_data_array(), owner()->GetNextDeoptId());
  ReturnDefinition(call);
}

StrictCompareInstr* EffectGraphVisitor::BuildStrictCompare(
    AstNode* left,
    AstNode* right,
    Token::Kind kind,
    TokenPosition token_pos) {
  ValueGraphVisitor for_left_value(owner());
  left->Visit(&for_left_value);
  Append(for_left_value);
  ValueGraphVisitor for_right_value(owner());
  right->Visit(&for_right_value);
  Append(for_right_value);
  StrictCompareInstr* comp = new (Z) StrictCompareInstr(
      token_pos, kind, for_left_value.value(), for_right_value.value(), true,
      owner()->GetNextDeoptId());  // Number check.
  return comp;
}

// <Expression> :: Comparison { kind:  Token::Kind
//                              left:  <Expression>
//                              right: <Expression> }
void EffectGraphVisitor::VisitComparisonNode(ComparisonNode* node) {
  if (Token::IsTypeTestOperator(node->kind())) {
    BuildTypeTest(node);
    return;
  }
  if (Token::IsTypeCastOperator(node->kind())) {
    BuildTypeCast(node);
    return;
  }

  if ((node->kind() == Token::kEQ_STRICT) ||
      (node->kind() == Token::kNE_STRICT)) {
    ReturnDefinition(BuildStrictCompare(node->left(), node->right(),
                                        node->kind(), node->token_pos()));
    return;
  }

  if ((node->kind() == Token::kEQ) || (node->kind() == Token::kNE)) {
    // Eagerly fold null-comparisons.
    LiteralNode* left_lit = node->left()->AsLiteralNode();
    LiteralNode* right_lit = node->right()->AsLiteralNode();
    if (((left_lit != NULL) && left_lit->literal().IsNull()) ||
        ((right_lit != NULL) && right_lit->literal().IsNull())) {
      Token::Kind kind =
          (node->kind() == Token::kEQ) ? Token::kEQ_STRICT : Token::kNE_STRICT;
      StrictCompareInstr* compare = BuildStrictCompare(
          node->left(), node->right(), kind, node->token_pos());
      ReturnDefinition(compare);
      return;
    }

    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);

    ValueGraphVisitor for_left_value(owner());
    node->left()->Visit(&for_left_value);
    Append(for_left_value);
    PushArgumentInstr* push_left = PushArgument(for_left_value.value());
    arguments->Add(push_left);

    ValueGraphVisitor for_right_value(owner());
    node->right()->Visit(&for_right_value);
    Append(for_right_value);
    PushArgumentInstr* push_right = PushArgument(for_right_value.value());
    arguments->Add(push_right);

    const intptr_t kTypeArgsLen = 0;
    const intptr_t kNumArgsChecked = 2;
    Definition* result = new (Z) InstanceCallInstr(
        node->token_pos(), Symbols::EqualOperator(),
        Token::kEQ,  // Result is negated later for kNE.
        arguments, kTypeArgsLen, Object::null_array(), kNumArgsChecked,
        owner()->ic_data_array(), owner()->GetNextDeoptId());
    if (node->kind() == Token::kNE) {
      Isolate* isolate = Isolate::Current();
      if (isolate->type_checks() || isolate->asserts()) {
        Value* value = Bind(result);
        result = new (Z) AssertBooleanInstr(node->token_pos(), value,
                                            owner()->GetNextDeoptId());
      }
      Value* value = Bind(result);
      result = new (Z) BooleanNegateInstr(value);
    }
    ReturnDefinition(result);
    return;
  }

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);

  ValueGraphVisitor for_left_value(owner());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  PushArgumentInstr* push_left = PushArgument(for_left_value.value());
  arguments->Add(push_left);

  ValueGraphVisitor for_right_value(owner());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  PushArgumentInstr* push_right = PushArgument(for_right_value.value());
  arguments->Add(push_right);

  ASSERT(Token::IsRelationalOperator(node->kind()));
  const intptr_t kTypeArgsLen = 0;
  InstanceCallInstr* comp = new (Z) InstanceCallInstr(
      node->token_pos(), Symbols::Token(node->kind()), node->kind(), arguments,
      kTypeArgsLen, Object::null_array(), 2, owner()->ic_data_array(),
      owner()->GetNextDeoptId());
  ReturnDefinition(comp);
}

void EffectGraphVisitor::VisitUnaryOpNode(UnaryOpNode* node) {
  // "!" cannot be overloaded, therefore do not call operator.
  if (node->kind() == Token::kNOT) {
    ValueGraphVisitor for_value(owner());
    node->operand()->Visit(&for_value);
    Append(for_value);
    Value* value = for_value.value();
    Isolate* isolate = Isolate::Current();
    if (isolate->type_checks() || isolate->asserts()) {
      value = Bind(new (Z) AssertBooleanInstr(
          node->operand()->token_pos(), value, owner()->GetNextDeoptId()));
    }
    BooleanNegateInstr* negate = new (Z) BooleanNegateInstr(value);
    ReturnDefinition(negate);
    return;
  }

  ValueGraphVisitor for_value(owner());
  node->operand()->Visit(&for_value);
  Append(for_value);
  PushArgumentInstr* push_value = PushArgument(for_value.value());
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(1);
  arguments->Add(push_value);
  const intptr_t kTypeArgsLen = 0;
  InstanceCallInstr* call = new (Z) InstanceCallInstr(
      node->token_pos(), Symbols::Token(node->kind()), node->kind(), arguments,
      kTypeArgsLen, Object::null_array(), 1, owner()->ic_data_array(),
      owner()->GetNextDeoptId());
  ReturnDefinition(call);
}

void EffectGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  TestGraphVisitor for_test(owner(), node->condition()->token_pos());
  node->condition()->Visit(&for_test);

  // Translate the subexpressions for their effects.
  EffectGraphVisitor for_true(owner());
  node->true_expr()->Visit(&for_true);
  EffectGraphVisitor for_false(owner());
  node->false_expr()->Visit(&for_false);

  Join(for_test, for_true, for_false);
}

void ValueGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  TestGraphVisitor for_test(owner(), node->condition()->token_pos());
  node->condition()->Visit(&for_test);

  ValueGraphVisitor for_true(owner());
  node->true_expr()->Visit(&for_true);
  ASSERT(for_true.is_open());
  for_true.Do(
      BuildStoreExprTemp(for_true.value(), node->true_expr()->token_pos()));

  ValueGraphVisitor for_false(owner());
  node->false_expr()->Visit(&for_false);
  ASSERT(for_false.is_open());
  for_false.Do(
      BuildStoreExprTemp(for_false.value(), node->false_expr()->token_pos()));

  Join(for_test, for_true, for_false);
  ReturnDefinition(BuildLoadExprTemp(node->token_pos()));
}

// <Statement> ::= If { condition: <Expression>
//                      true_branch: <Sequence>
//                      false_branch: <Sequence> }
void EffectGraphVisitor::VisitIfNode(IfNode* node) {
  TestGraphVisitor for_test(owner(), node->condition()->token_pos());
  node->condition()->Visit(&for_test);

  EffectGraphVisitor for_true(owner());
  EffectGraphVisitor for_false(owner());

  node->true_branch()->Visit(&for_true);
  // The for_false graph fragment will be empty (default graph fragment) if
  // we do not call Visit.
  if (node->false_branch() != NULL) node->false_branch()->Visit(&for_false);
  Join(for_test, for_true, for_false);
}

void EffectGraphVisitor::VisitSwitchNode(SwitchNode* node) {
  NestedSwitch nested_switch(owner(), node);
  EffectGraphVisitor switch_body(owner());
  node->body()->Visit(&switch_body);
  Append(switch_body);
  if (nested_switch.break_target() != NULL) {
    if (is_open()) Goto(nested_switch.break_target());
    exit_ = nested_switch.break_target();
  }
}

// A case node contains zero or more case expressions, can contain default
// and a case statement body.
// Compose fragment as follows:
// - if no case expressions, must have default:
//   a) target
//   b) [ case-statements ]
//
// - if has 1 or more case statements
//   a) target-0
//   b) [ case-expression-0 ] -> (true-target-0, target-1)
//   c) target-1
//   d) [ case-expression-1 ] -> (true-target-1, exit-target)
//   e) true-target-0 -> case-statements-join
//   f) true-target-1 -> case-statements-join
//   g) case-statements-join
//   h) [ case-statements ] -> exit-join
//   i) exit-target -> exit-join
//   j) exit-join
//
// Note: The specification of switch/case is under discussion and may change
// drastically.
void EffectGraphVisitor::VisitCaseNode(CaseNode* node) {
  const intptr_t len = node->case_expressions()->length();
  // Create case statements instructions.
  EffectGraphVisitor for_case_statements(owner());
  // Compute the start of the statements fragment.
  JoinEntryInstr* statement_start = NULL;
  if (node->label() == NULL) {
    statement_start =
        new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                               owner()->GetNextDeoptId());
  } else {
    // The case nodes are nested inside a SequenceNode that is the body of a
    // SwitchNode.  The SwitchNode on the nesting stack contains the
    // continue labels for all the case clauses.
    statement_start =
        owner()->nesting_stack()->outer()->ContinueTargetFor(node->label());
  }
  ASSERT(statement_start != NULL);
  node->statements()->Visit(&for_case_statements);
  Instruction* statement_exit =
      AppendFragment(statement_start, for_case_statements);
  if (is_open() && (len == 0)) {
    ASSERT(node->contains_default());
    // Default only case node.
    Goto(statement_start);
    exit_ = statement_exit;
    return;
  }

  // Generate instructions for all case expressions.
  TargetEntryInstr* next_target = NULL;
  for (intptr_t i = 0; i < len; i++) {
    AstNode* case_expr = node->case_expressions()->NodeAt(i);
    TestGraphVisitor for_case_expression(owner(), case_expr->token_pos());
    case_expr->Visit(&for_case_expression);
    if (i == 0) {
      // Append only the first one, everything else is connected from it.
      Append(for_case_expression);
    } else {
      ASSERT(next_target != NULL);
      AppendFragment(next_target, for_case_expression);
    }
    for_case_expression.IfTrueGoto(statement_start);
    next_target = for_case_expression.CreateFalseSuccessor()->AsTargetEntry();
  }

  // Once a test fragment has been added, this fragment is closed.
  ASSERT(!is_open());

  Instruction* exit_instruction = NULL;
  // Handle last (or only) case: false goes to exit or to statement if this
  // node contains default.
  if (len > 0) {
    ASSERT(next_target != NULL);
    if (node->contains_default()) {
      // True and false go to statement start.
      next_target->Goto(statement_start);
      exit_instruction = statement_exit;
    } else {
      if (statement_exit != NULL) {
        JoinEntryInstr* join = new (Z)
            JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                           owner()->GetNextDeoptId());
        statement_exit->Goto(join);
        next_target->Goto(join);
        exit_instruction = join;
      } else {
        exit_instruction = next_target;
      }
    }
  } else {
    // A CaseNode without case expressions must contain default.
    ASSERT(node->contains_default());
    Goto(statement_start);
    exit_instruction = statement_exit;
  }

  ASSERT(!is_open());
  exit_ = exit_instruction;
}

// <Statement> ::= While { label:     SourceLabel
//                         condition: <Expression>
//                         body:      <Sequence> }
// The fragment is composed as follows:
// a) loop-join
// b) [ test_preamble ]?
// c) [ test ] -> (body-entry-target, loop-exit-target)
// d) body-entry-target
// e) [ body ] -> (continue-join)
// f) continue-join -> (loop-join)
// g) loop-exit-target
// h) break-join (optional)
void EffectGraphVisitor::VisitWhileNode(WhileNode* node) {
  NestedLoop nested_loop(owner(), node->label());

  EffectGraphVisitor for_preamble(owner());
  if (node->condition_preamble() != NULL) {
    node->condition_preamble()->Visit(&for_preamble);
  }

  TestGraphVisitor for_test(owner(), node->condition()->token_pos());
  node->condition()->Visit(&for_test);
  ASSERT(!for_test.is_empty());  // Language spec.

  EffectGraphVisitor for_body(owner());
  node->body()->Visit(&for_body);

  // Labels are set after body traversal.
  JoinEntryInstr* join = nested_loop.continue_target();
  if (join != NULL) {
    if (for_body.is_open()) for_body.Goto(join);
    for_body.exit_ = join;
  }
  TieLoop(node->token_pos(), for_test, for_body, for_preamble);
  join = nested_loop.break_target();
  if (join != NULL) {
    Goto(join);
    exit_ = join;
  }
}

// The fragment is composed as follows:
// a) body-entry-join
// b) [ body ]
// c) test-entry (continue-join or body-exit-target)
// d) [ test-entry ] -> (back-target, loop-exit-target)
// e) back-target -> (body-entry-join)
// f) loop-exit-target
// g) break-join
void EffectGraphVisitor::VisitDoWhileNode(DoWhileNode* node) {
  NestedLoop nested_loop(owner(), node->label());

  // Traverse the body first in order to generate continue and break labels.
  EffectGraphVisitor for_body(owner());
  node->body()->Visit(&for_body);

  TestGraphVisitor for_test(owner(), node->condition()->token_pos());
  node->condition()->Visit(&for_test);
  ASSERT(is_open());

  // Tie do-while loop (test is after the body).
  JoinEntryInstr* body_entry_join =
      new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                             owner()->GetNextDeoptId());
  Goto(body_entry_join);
  Instruction* body_exit = AppendFragment(body_entry_join, for_body);

  JoinEntryInstr* join = nested_loop.continue_target();
  if ((body_exit != NULL) || (join != NULL)) {
    if (join == NULL) {
      join = new (Z)
          JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                         owner()->GetNextDeoptId());
    }
    CheckStackOverflowInstr* check = new (Z) CheckStackOverflowInstr(
        node->token_pos(), owner()->loop_depth(), owner()->GetNextDeoptId());
    join->LinkTo(check);
    check->LinkTo(for_test.entry());
    if (body_exit != NULL) {
      body_exit->Goto(join);
    }
  }

  for_test.IfTrueGoto(body_entry_join);
  join = nested_loop.break_target();
  if (join == NULL) {
    exit_ = for_test.CreateFalseSuccessor();
  } else {
    for_test.IfFalseGoto(join);
    exit_ = join;
  }
}

// A ForNode can contain break and continue jumps. 'break' joins to
// ForNode exit, 'continue' joins at increment entry. The fragment is composed
// as follows:
// a) [ initializer ]
// b) loop-join
// c) [ test ] -> (body-entry-target, loop-exit-target)
// d) body-entry-target
// e) [ body ]
// f) continue-join (optional)
// g) [ increment ] -> (loop-join)
// h) loop-exit-target
// i) break-join
void EffectGraphVisitor::VisitForNode(ForNode* node) {
  EffectGraphVisitor for_initializer(owner());
  node->initializer()->Visit(&for_initializer);
  Append(for_initializer);
  ASSERT(is_open());

  NestedLoop nested_loop(owner(), node->label());
  // Compose body to set any jump labels.
  EffectGraphVisitor for_body(owner());
  node->body()->Visit(&for_body);

  EffectGraphVisitor for_increment(owner());
  node->increment()->Visit(&for_increment);

  // Join the loop body and increment and then tie the loop.
  JoinEntryInstr* continue_join = nested_loop.continue_target();
  if ((continue_join != NULL) || for_body.is_open()) {
    JoinEntryInstr* loop_entry =
        new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                               owner()->GetNextDeoptId());
    if (continue_join != NULL) {
      if (for_body.is_open()) for_body.Goto(continue_join);
      Instruction* current = AppendFragment(continue_join, for_increment);
      current->Goto(loop_entry);
    } else {
      for_body.Append(for_increment);
      for_body.Goto(loop_entry);
    }
    Goto(loop_entry);
    exit_ = loop_entry;
    // Note: the stack overflow check happens on the back branch that jumps
    // to the increment instruction. The token position for the overflow
    // check must match the position of the increment expression, so that
    // the context level (if any) matches the that of the increment
    // expression.
    AddInstruction(new (Z) CheckStackOverflowInstr(
        node->increment()->token_pos(), owner()->loop_depth(),
        owner()->GetNextDeoptId()));
  }

  if (node->condition() == NULL) {
    // Endless loop, no test.
    Append(for_body);
    exit_ = nested_loop.break_target();  // May be NULL.
  } else {
    EffectGraphVisitor for_test_preamble(owner());
    if (node->condition_preamble() != NULL) {
      node->condition_preamble()->Visit(&for_test_preamble);
      Append(for_test_preamble);
    }

    TestGraphVisitor for_test(owner(), node->condition()->token_pos());
    node->condition()->Visit(&for_test);
    Append(for_test);

    BlockEntryInstr* body_entry = for_test.CreateTrueSuccessor();
    AppendFragment(body_entry, for_body);

    if (nested_loop.break_target() == NULL) {
      exit_ = for_test.CreateFalseSuccessor();
    } else {
      for_test.IfFalseGoto(nested_loop.break_target());
      exit_ = nested_loop.break_target();
    }
  }
}

void EffectGraphVisitor::VisitJumpNode(JumpNode* node) {
#if !defined(PRODUCT)
  if (owner()->function().is_debuggable()) {
    AddInstruction(new (Z) DebugStepCheckInstr(node->token_pos(),
                                               RawPcDescriptors::kRuntimeCall,
                                               owner()->GetNextDeoptId()));
  }
#endif

  NestedContextAdjustment context_adjustment(owner(), owner()->context_level());

  for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
    EffectGraphVisitor for_effect(owner());
    node->InlinedFinallyNodeAt(i)->Visit(&for_effect);
    Append(for_effect);
    if (!is_open()) return;
  }

  // Unchain the context(s) up to the outer context level of the scope which
  // contains the destination label.
  SourceLabel* label = node->label();
  ASSERT(label->owner() != NULL);
  AdjustContextLevel(label->owner());

  JoinEntryInstr* jump_target = NULL;
  NestedStatement* current = owner()->nesting_stack();
  while (current != NULL) {
    jump_target = (node->kind() == Token::kBREAK)
                      ? current->BreakTargetFor(node->label())
                      : current->ContinueTargetFor(node->label());
    if (jump_target != NULL) break;
    current = current->outer();
  }
  ASSERT(jump_target != NULL);
  Goto(jump_target);
}

void EffectGraphVisitor::VisitArgumentListNode(ArgumentListNode* node) {
  UNREACHABLE();
}

void EffectGraphVisitor::VisitAwaitNode(AwaitNode* node) {
  // Await nodes are temporary during parsing.
  UNREACHABLE();
}

void EffectGraphVisitor::VisitAwaitMarkerNode(AwaitMarkerNode* node) {
  // We need to create a new await state which involves:
  // * Increase the jump counter. Sanity check against the list of targets.
  // * Save the current context for resuming.
  ASSERT(node->token_pos().IsSynthetic() || node->token_pos().IsNoSource());
  ASSERT(node->async_scope() != NULL);
  ASSERT(node->await_scope() != NULL);
  LocalVariable* jump_var =
      node->async_scope()->LookupVariable(Symbols::AwaitJumpVar(), false);
  LocalVariable* ctx_var =
      node->async_scope()->LookupVariable(Symbols::AwaitContextVar(), false);
  ASSERT((jump_var != NULL) && jump_var->is_captured());
  ASSERT((ctx_var != NULL) && ctx_var->is_captured());
  const intptr_t jump_count = owner()->next_await_counter();
  ASSERT(jump_count >= 0);
  // Sanity check that we always add a JoinEntryInstr before adding a new
  // state.
  ASSERT(jump_count == owner()->await_joins()->length());
  // Store the counter in :await_jump_var.
  Value* jump_val = Bind(new (Z) ConstantInstr(
      Smi::ZoneHandle(Z, Smi::New(jump_count)), node->token_pos()));
  Do(BuildStoreLocal(*jump_var, jump_val, node->token_pos()));
  // Add a mapping from jump_count -> token_position.
  owner()->AppendAwaitTokenPosition(node->token_pos());
  // Save the current context for resuming.
  BuildSaveContext(*ctx_var, node->token_pos());
}

intptr_t EffectGraphVisitor::GetCurrentTempLocalIndex() const {
  return kFirstLocalSlotFromFp - owner()->num_stack_locals() -
         owner()->num_copied_params() - owner()->args_pushed() -
         owner()->temp_count() + 1;
}

LocalVariable* EffectGraphVisitor::EnterTempLocalScope(Value* value) {
  ASSERT(value->definition()->temp_index() == (owner()->temp_count() - 1));
  intptr_t index = GetCurrentTempLocalIndex();
  char name[64];
  OS::SNPrint(name, 64, ":tmp_local%" Pd, index);
  LocalVariable* var =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            String::ZoneHandle(Z, Symbols::New(T, name)),
                            *value->Type()->ToAbstractType());
  var->set_index(index);
  return var;
}

Definition* EffectGraphVisitor::ExitTempLocalScope(Value* value) {
  return new (Z) DropTempsInstr(0, value);
}

void EffectGraphVisitor::BuildLetTempExpressions(LetNode* node) {
  intptr_t num_temps = node->num_temps();
  for (intptr_t i = 0; i < num_temps; ++i) {
    ValueGraphVisitor for_value(owner());
    node->InitializerAt(i)->Visit(&for_value);
    Append(for_value);
    ASSERT(!node->TempAt(i)->HasIndex() ||
           (node->TempAt(i)->index() == GetCurrentTempLocalIndex()));
    node->TempAt(i)->set_index(GetCurrentTempLocalIndex());
  }
}

void EffectGraphVisitor::VisitLetNode(LetNode* node) {
  BuildLetTempExpressions(node);

  // Visit body.
  for (intptr_t i = 0; i < node->nodes().length(); ++i) {
    EffectGraphVisitor for_effect(owner());
    node->nodes()[i]->Visit(&for_effect);
    Append(for_effect);
  }

  intptr_t num_temps = node->num_temps();
  if (num_temps > 0) {
    owner()->DeallocateTemps(num_temps);
    Do(new (Z) DropTempsInstr(num_temps, NULL));
  }
}

void ValueGraphVisitor::VisitLetNode(LetNode* node) {
  BuildLetTempExpressions(node);

  // Visit body.
  for (intptr_t i = 0; i < node->nodes().length() - 1; ++i) {
    EffectGraphVisitor for_effect(owner());
    node->nodes()[i]->Visit(&for_effect);
    Append(for_effect);
  }
  // Visit the last body expression for value.
  ValueGraphVisitor for_value(owner());
  node->nodes().Last()->Visit(&for_value);
  Append(for_value);
  Value* result_value = for_value.value();

  intptr_t num_temps = node->num_temps();
  if (num_temps > 0) {
    owner()->DeallocateTemps(num_temps);
    ReturnDefinition(new (Z) DropTempsInstr(num_temps, result_value));
  } else {
    ReturnValue(result_value);
  }
}

void EffectGraphVisitor::VisitArrayNode(ArrayNode* node) {
  const TypeArguments& type_args =
      TypeArguments::ZoneHandle(Z, node->type().arguments());
  Value* element_type =
      BuildInstantiatedTypeArguments(node->token_pos(), type_args);
  Value* num_elements =
      Bind(new (Z) ConstantInstr(Smi::ZoneHandle(Z, Smi::New(node->length()))));
  CreateArrayInstr* create = new (Z) CreateArrayInstr(
      node->token_pos(), element_type, num_elements, owner()->GetNextDeoptId());
  Value* array_val = Bind(create);

  {
    LocalVariable* tmp_var = EnterTempLocalScope(array_val);
    const intptr_t class_id = kArrayCid;
    const intptr_t deopt_id = Thread::kNoDeoptId;
    for (int i = 0; i < node->length(); ++i) {
      Value* array = Bind(new (Z) LoadLocalInstr(*tmp_var, node->token_pos()));
      Value* index = Bind(new (Z) ConstantInstr(Smi::ZoneHandle(Z, Smi::New(i)),
                                                node->token_pos()));
      ValueGraphVisitor for_value(owner());
      node->ElementAt(i)->Visit(&for_value);
      Append(for_value);
      // No store barrier needed for constants.
      const StoreBarrierType emit_store_barrier =
          for_value.value()->BindsToConstant() ? kNoStoreBarrier
                                               : kEmitStoreBarrier;
      const intptr_t index_scale = Instance::ElementSizeFor(class_id);
      StoreIndexedInstr* store = new (Z) StoreIndexedInstr(
          array, index, for_value.value(), emit_store_barrier, index_scale,
          class_id, kAlignedAccess, deopt_id, node->token_pos());
      Do(store);
    }
    ReturnDefinition(ExitTempLocalScope(array_val));
  }
}

void EffectGraphVisitor::VisitStringInterpolateNode(
    StringInterpolateNode* node) {
  ValueGraphVisitor for_argument(owner());
  ArrayNode* arguments = node->value();
  if (arguments->length() == 1) {
    ZoneGrowableArray<PushArgumentInstr*>* values =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(1);
    arguments->ElementAt(0)->Visit(&for_argument);
    Append(for_argument);
    PushArgumentInstr* push_arg = PushArgument(for_argument.value());
    values->Add(push_arg);
    const int kTypeArgsLen = 0;
    const int kNumberOfArguments = 1;
    const Array& kNoArgumentNames = Object::null_array();
    const Class& cls =
        Class::Handle(Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    const Function& function = Function::ZoneHandle(
        Z, Resolver::ResolveStatic(
               cls, Library::PrivateCoreLibName(Symbols::InterpolateSingle()),
               kTypeArgsLen, kNumberOfArguments, kNoArgumentNames));
    StaticCallInstr* call = new (Z) StaticCallInstr(
        node->token_pos(), function, kTypeArgsLen, kNoArgumentNames, values,
        owner()->ic_data_array(), owner()->GetNextDeoptId(), ICData::kStatic);
    ReturnDefinition(call);
    return;
  }
  arguments->Visit(&for_argument);
  Append(for_argument);
  StringInterpolateInstr* instr = new (Z) StringInterpolateInstr(
      for_argument.value(), node->token_pos(), owner()->GetNextDeoptId());
  ReturnDefinition(instr);
}

void EffectGraphVisitor::VisitClosureNode(ClosureNode* node) {
  const Function& function = node->function();
  if (function.IsImplicitStaticClosureFunction()) {
    const Instance& closure =
        Instance::ZoneHandle(Z, function.ImplicitStaticClosure());
    ReturnDefinition(new (Z) ConstantInstr(closure));
    return;
  }

  const bool is_implicit = function.IsImplicitInstanceClosureFunction();
  ASSERT(is_implicit || function.IsNonImplicitClosureFunction());
  // The context scope may have already been set by the non-optimizing
  // compiler.  If it was not, set it here.
  if (function.context_scope() == ContextScope::null()) {
    ASSERT(!is_implicit);
    ASSERT(node->scope() != NULL);
    const ContextScope& context_scope = ContextScope::ZoneHandle(
        Z, node->scope()->PreserveOuterScope(owner()->context_level()));
    ASSERT(!function.HasCode());
    ASSERT(function.context_scope() == ContextScope::null());
    function.set_context_scope(context_scope);

    // The closure is now properly setup, add it to the lookup table.
    // It is possible that the compiler creates more than one function
    // object for the same closure, e.g. when inlining nodes from
    // finally clauses. If we already have a function object for the
    // same closure, do not add a second one. We compare token position,
    // and parent function to detect duplicates.
    const Function& parent = Function::Handle(function.parent_function());
    const Function& found_func = Function::Handle(
        Z, isolate()->LookupClosureFunction(parent, function.token_pos()));
    if (found_func.IsNull()) {
      isolate()->AddClosureFunction(function);
    }
  }
  ASSERT(function.context_scope() != ContextScope::null());

  // The function type of a closure may have type arguments. In that case,
  // pass the type arguments of the instantiator.
  const Class& closure_class =
      Class::ZoneHandle(Z, isolate()->object_store()->closure_class());
  ZoneGrowableArray<PushArgumentInstr*>* no_arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(0);
  AllocateObjectInstr* alloc = new (Z)
      AllocateObjectInstr(node->token_pos(), closure_class, no_arguments);
  alloc->set_closure_function(function);

  Value* closure_val = Bind(alloc);
  {
    LocalVariable* closure_tmp_var = EnterTempLocalScope(closure_val);
    // Store instantiator type arguments if signature is class-uninstantiated.
    if (!function.HasInstantiatedSignature(kCurrentClass)) {
      Value* closure_tmp_val =
          Bind(new (Z) LoadLocalInstr(*closure_tmp_var, node->token_pos()));
      Value* type_arguments = BuildInstantiatorTypeArguments(node->token_pos());
      Do(new (Z) StoreInstanceFieldInstr(
          Closure::instantiator_type_arguments_offset(), closure_tmp_val,
          type_arguments, kEmitStoreBarrier, node->token_pos()));
    }

    // Store function type arguments if signature is function-uninstantiated.
    if (!function.HasInstantiatedSignature(kFunctions)) {
      Value* closure_tmp_val =
          Bind(new (Z) LoadLocalInstr(*closure_tmp_var, node->token_pos()));
      Value* type_arguments = BuildFunctionTypeArguments(node->token_pos());
      Do(new (Z) StoreInstanceFieldInstr(
          Closure::function_type_arguments_offset(), closure_tmp_val,
          type_arguments, kEmitStoreBarrier, node->token_pos()));
    }

    // Store function.
    Value* closure_tmp_val =
        Bind(new (Z) LoadLocalInstr(*closure_tmp_var, node->token_pos()));
    Value* func_val =
        Bind(new (Z) ConstantInstr(Function::ZoneHandle(Z, function.raw())));
    Do(new (Z) StoreInstanceFieldInstr(Closure::function_offset(),
                                       closure_tmp_val, func_val,
                                       kEmitStoreBarrier, node->token_pos()));
    if (is_implicit) {
      // Create new context containing the receiver.
      const intptr_t kNumContextVariables = 1;  // The receiver.
      Value* allocated_context = Bind(new (Z) AllocateContextInstr(
          node->token_pos(), kNumContextVariables));
      {
        LocalVariable* context_tmp_var = EnterTempLocalScope(allocated_context);
        // Store receiver in context.
        Value* context_tmp_val =
            Bind(new (Z) LoadLocalInstr(*context_tmp_var, node->token_pos()));
        ValueGraphVisitor for_receiver(owner());
        node->receiver()->Visit(&for_receiver);
        Append(for_receiver);
        Value* receiver = for_receiver.value();
        Do(new (Z) StoreInstanceFieldInstr(
            Context::variable_offset(0), context_tmp_val, receiver,
            kEmitStoreBarrier, node->token_pos()));
        // Store new context in closure.
        closure_tmp_val =
            Bind(new (Z) LoadLocalInstr(*closure_tmp_var, node->token_pos()));
        context_tmp_val =
            Bind(new (Z) LoadLocalInstr(*context_tmp_var, node->token_pos()));
        Do(new (Z) StoreInstanceFieldInstr(
            Closure::context_offset(), closure_tmp_val, context_tmp_val,
            kEmitStoreBarrier, node->token_pos()));
        Do(ExitTempLocalScope(allocated_context));
      }
    } else {
      // Store current context in closure.
      closure_tmp_val =
          Bind(new (Z) LoadLocalInstr(*closure_tmp_var, node->token_pos()));
      Value* context = Bind(BuildCurrentContext(node->token_pos()));
      Do(new (Z) StoreInstanceFieldInstr(Closure::context_offset(),
                                         closure_tmp_val, context,
                                         kEmitStoreBarrier, node->token_pos()));
    }
    ReturnDefinition(ExitTempLocalScope(closure_val));
  }
}

void EffectGraphVisitor::BuildPushTypeArguments(
    const ArgumentListNode& node,
    ZoneGrowableArray<PushArgumentInstr*>* values) {
  if (node.type_args_len() > 0) {
    Value* type_args_val;
    if (node.type_args_var() != NULL) {
      type_args_val =
          Bind(new (Z) LoadLocalInstr(*node.type_args_var(), node.token_pos()));
    } else {
      const TypeArguments& type_args = node.type_arguments();
      ASSERT(!type_args.IsNull() && type_args.IsCanonical() &&
             (type_args.Length() == node.type_args_len()));
      type_args_val =
          BuildInstantiatedTypeArguments(node.token_pos(), type_args);
    }
    PushArgumentInstr* push_type_args = PushArgument(type_args_val);
    values->Add(push_type_args);
  }
}

void EffectGraphVisitor::BuildPushArguments(
    const ArgumentListNode& node,
    ZoneGrowableArray<PushArgumentInstr*>* values) {
  for (intptr_t i = 0; i < node.length(); ++i) {
    ValueGraphVisitor for_argument(owner());
    node.NodeAt(i)->Visit(&for_argument);
    Append(for_argument);
    PushArgumentInstr* push_arg = PushArgument(for_argument.value());
    values->Add(push_arg);
  }
}

void EffectGraphVisitor::BuildInstanceCallConditional(InstanceCallNode* node) {
  const TokenPosition token_pos = node->token_pos();
  LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
  LoadLocalNode* load_temp = new (Z) LoadLocalNode(token_pos, temp_var);

  LiteralNode* null_constant =
      new (Z) LiteralNode(ST(token_pos), Object::null_instance());
  ComparisonNode* check_is_null = new (Z)
      ComparisonNode(ST(token_pos), Token::kEQ, load_temp, null_constant);
  TestGraphVisitor for_test(owner(), ST(token_pos));
  check_is_null->Visit(&for_test);

  EffectGraphVisitor for_true(owner());
  EffectGraphVisitor for_false(owner());

  StoreLocalNode* store_null =
      new (Z) StoreLocalNode(ST(token_pos), temp_var, null_constant);
  store_null->Visit(&for_true);

  InstanceCallNode* call = new (Z) InstanceCallNode(
      token_pos, load_temp, node->function_name(), node->arguments());
  StoreLocalNode* store_result =
      new (Z) StoreLocalNode(ST(token_pos), temp_var, call);
  store_result->Visit(&for_false);

  Join(for_test, for_true, for_false);
}

void ValueGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  if (node->is_conditional()) {
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value(), node->token_pos()));
    BuildInstanceCallConditional(node);
    ReturnDefinition(BuildLoadExprTemp(node->token_pos()));
  } else {
    EffectGraphVisitor::VisitInstanceCallNode(node);
  }
}

void EffectGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  if (node->is_conditional()) {
    ASSERT(node->arguments()->type_args_len() == 0);
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value(), node->token_pos()));
    BuildInstanceCallConditional(node);
  } else {
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(
            node->arguments()->LengthWithTypeArgs() + 1);
    BuildPushTypeArguments(*node->arguments(), arguments);
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    PushArgumentInstr* push_receiver = PushArgument(for_receiver.value());
    arguments->Add(push_receiver);
    BuildPushArguments(*node->arguments(), arguments);
    InstanceCallInstr* call = new (Z) InstanceCallInstr(
        node->token_pos(), node->function_name(), Token::kILLEGAL, arguments,
        node->arguments()->type_args_len(), node->arguments()->names(), 1,
        owner()->ic_data_array(), owner()->GetNextDeoptId());
    ReturnDefinition(call);
  }
}

static ICData::RebindRule ConvertRebindRule(
    StaticCallNode::RebindRule rebind_rule_ast) {
  switch (rebind_rule_ast) {
    case StaticCallNode::kNoRebind:
      return ICData::kNoRebind;
    case StaticCallNode::kNSMDispatch:
      return ICData::kNSMDispatch;
    case StaticCallNode::kSuper:
      return ICData::kSuper;
    case StaticCallNode::kStatic:
      return ICData::kStatic;
    default:
      UNREACHABLE();
      return ICData::kStatic;
  }
}

static ICData::RebindRule ConvertRebindRule(
    StaticGetterSetter::RebindRule rebind_rule_ast) {
  switch (rebind_rule_ast) {
    case StaticGetterSetter::kSuper:
      return ICData::kSuper;
    case StaticGetterSetter::kStatic:
      return ICData::kStatic;
    default:
      UNREACHABLE();
      return ICData::kStatic;
  }
}

// <Expression> ::= StaticCall { function: Function
//                               arguments: <ArgumentList> }
void EffectGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(
          node->arguments()->LengthWithTypeArgs());
  BuildPushTypeArguments(*node->arguments(), arguments);
  BuildPushArguments(*node->arguments(), arguments);
  StaticCallInstr* call = new (Z) StaticCallInstr(
      node->token_pos(), node->function(), node->arguments()->type_args_len(),
      node->arguments()->names(), arguments, owner()->ic_data_array(),
      owner()->GetNextDeoptId(), ConvertRebindRule(node->rebind_rule()));
  if (node->function().recognized_kind() != MethodRecognizer::kUnknown) {
    call->set_result_cid(MethodRecognizer::ResultCid(node->function()));
  }
  ReturnDefinition(call);
}

void EffectGraphVisitor::BuildClosureCall(ClosureCallNode* node,
                                          bool result_needed) {
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(
          node->arguments()->LengthWithTypeArgs() + 1);

  ValueGraphVisitor for_closure(owner());
  node->closure()->Visit(&for_closure);
  Append(for_closure);
  Value* closure_value = for_closure.value();
  LocalVariable* tmp_var = EnterTempLocalScope(closure_value);

  BuildPushTypeArguments(*node->arguments(), arguments);
  Value* closure_val =
      Bind(new (Z) LoadLocalInstr(*tmp_var, node->token_pos()));
  PushArgumentInstr* push_closure = PushArgument(closure_val);
  arguments->Add(push_closure);
  BuildPushArguments(*node->arguments(), arguments);

  closure_val = Bind(new (Z) LoadLocalInstr(*tmp_var, node->token_pos()));
  LoadFieldInstr* function_load = new (Z) LoadFieldInstr(
      closure_val, Closure::function_offset(),
      AbstractType::ZoneHandle(Z, AbstractType::null()), node->token_pos());
  function_load->set_is_immutable(true);
  Value* function_val = Bind(function_load);

  Definition* closure_call = new (Z) ClosureCallInstr(
      function_val, node, arguments, owner()->GetNextDeoptId());
  if (result_needed) {
    Value* result = Bind(closure_call);
    Do(new (Z) StoreLocalInstr(*tmp_var, result, ST(node->token_pos())));
  } else {
    Do(closure_call);
  }
  ReturnDefinition(ExitTempLocalScope(closure_value));
}

void EffectGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  BuildClosureCall(node, false);
}

void ValueGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  BuildClosureCall(node, true);
}

void EffectGraphVisitor::VisitInitStaticFieldNode(InitStaticFieldNode* node) {
  Value* field = Bind(
      new (Z) ConstantInstr(Field::ZoneHandle(Z, node->field().Original())));
  AddInstruction(new (Z) InitStaticFieldInstr(field, node->field(),
                                              owner()->GetNextDeoptId()));
}

void EffectGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  Value* context = Bind(BuildCurrentContext(node->token_pos()));
  Value* clone = Bind(new (Z) CloneContextInstr(node->token_pos(), context,
                                                owner()->GetNextDeoptId()));
  Do(BuildStoreContext(clone, node->token_pos()));
}

Value* EffectGraphVisitor::BuildObjectAllocation(ConstructorCallNode* node) {
  const Class& cls = Class::ZoneHandle(Z, node->constructor().Owner());
  const bool cls_is_parameterized = cls.NumTypeArguments() > 0;

  ZoneGrowableArray<PushArgumentInstr*>* allocate_arguments = new (Z)
      ZoneGrowableArray<PushArgumentInstr*>(cls_is_parameterized ? 1 : 0);
  if (cls_is_parameterized) {
    Value* type_args = BuildInstantiatedTypeArguments(node->token_pos(),
                                                      node->type_arguments());
    allocate_arguments->Add(PushArgument(type_args));
  }

  Definition* allocation = new (Z) AllocateObjectInstr(
      node->token_pos(), Class::ZoneHandle(Z, node->constructor().Owner()),
      allocate_arguments);

  return Bind(allocation);
}

void EffectGraphVisitor::BuildConstructorCall(
    ConstructorCallNode* node,
    PushArgumentInstr* push_alloc_value) {
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  arguments->Add(push_alloc_value);

  BuildPushArguments(*node->arguments(), arguments);
  const intptr_t kTypeArgsLen = 0;
  Do(new (Z) StaticCallInstr(node->token_pos(), node->constructor(),
                             kTypeArgsLen, node->arguments()->names(),
                             arguments, owner()->ic_data_array(),
                             owner()->GetNextDeoptId(), ICData::kStatic));
}

static intptr_t GetResultCidOfListFactory(ConstructorCallNode* node) {
  const Function& function = node->constructor();
  const Class& function_class = Class::Handle(function.Owner());

  if ((function_class.library() != Library::CoreLibrary()) &&
      (function_class.library() != Library::TypedDataLibrary())) {
    return kDynamicCid;
  }

  if (node->constructor().IsFactory()) {
    if ((function_class.Name() == Symbols::List().raw()) &&
        (function.name() == Symbols::ListFactory().raw())) {
      // Special recognition of 'new List()' vs 'new List(n)'.
      if (node->arguments()->length() == 0) {
        return kGrowableObjectArrayCid;
      }
      return kArrayCid;
    }
    return FactoryRecognizer::ResultCid(function);
  }
  return kDynamicCid;  // Not a known list constructor.
}

void EffectGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  if (node->constructor().IsFactory()) {
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>();
    PushArgumentInstr* push_type_arguments =
        PushArgument(BuildInstantiatedTypeArguments(node->token_pos(),
                                                    node->type_arguments()));
    arguments->Add(push_type_arguments);
    ASSERT(arguments->length() == 1);
    BuildPushArguments(*node->arguments(), arguments);
    const int kTypeArgsLen = 0;
    StaticCallInstr* call = new (Z) StaticCallInstr(
        node->token_pos(), node->constructor(), kTypeArgsLen,
        node->arguments()->names(), arguments, owner()->ic_data_array(),
        owner()->GetNextDeoptId(), ICData::kStatic);
    const intptr_t result_cid = GetResultCidOfListFactory(node);
    if (result_cid != kDynamicCid) {
      call->set_result_cid(result_cid);
      call->set_is_known_list_constructor(true);
      // Recognized fixed length array factory must have two arguments:
      // (0) type-arguments, (1) length.
      ASSERT(!LoadFieldInstr::IsFixedLengthArrayCid(result_cid) ||
             arguments->length() == 2);
    } else if (node->constructor().recognized_kind() !=
               MethodRecognizer::kUnknown) {
      call->set_result_cid(MethodRecognizer::ResultCid(node->constructor()));
    }
    ReturnDefinition(call);
    return;
  }
  // t_n contains the allocated and initialized object.
  //   t_n      <- AllocateObject(class)
  //   t_n+1    <- ctor-arg
  //   t_n+2... <- constructor arguments start here
  //   StaticCall(constructor, t_n+1, t_n+2, ...)
  // No need to preserve allocated value (simpler than in ValueGraphVisitor).
  Value* allocated_value = BuildObjectAllocation(node);
  PushArgumentInstr* push_allocated_value = PushArgument(allocated_value);
  BuildConstructorCall(node, push_allocated_value);
}

Value* EffectGraphVisitor::BuildInstantiator(TokenPosition token_pos) {
  Function& outer_function = Function::Handle(Z, owner()->function().raw());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  if (outer_function.IsFactory()) {
    return NULL;
  }

  LocalVariable* instantiator = owner()->parsed_function().instantiator();
  ASSERT(instantiator != NULL);
  Value* result = Bind(BuildLoadLocal(*instantiator, token_pos));
  return result;
}

Value* EffectGraphVisitor::BuildInstantiatorTypeArguments(
    TokenPosition token_pos) {
  const Class& instantiator_class =
      Class::Handle(Z, owner()->function().Owner());
  if (!instantiator_class.IsGeneric()) {
    // The type arguments are compile time constants.
    TypeArguments& type_arguments =
        TypeArguments::ZoneHandle(Z, TypeArguments::null());
    // Type is temporary. Only its type arguments are preserved.
    Type& type = Type::Handle(Z, Type::New(instantiator_class, type_arguments,
                                           token_pos, Heap::kNew));
    type ^= ClassFinalizer::FinalizeType(instantiator_class, type,
                                         ClassFinalizer::kFinalize);
    ASSERT(!type.IsMalformedOrMalbounded());
    type_arguments = type.arguments();
    type_arguments = type_arguments.Canonicalize();
    return Bind(new (Z) ConstantInstr(type_arguments));
  }
  Function& outer_function = Function::Handle(Z, owner()->function().raw());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  if (outer_function.IsFactory()) {
    // Note that in the factory case, the instantiator is the first parameter
    // of the factory, i.e. already a TypeArguments object.
    LocalVariable* instantiator_var = owner()->parsed_function().instantiator();
    ASSERT(instantiator_var != NULL);
    return Bind(BuildLoadLocal(*instantiator_var, token_pos));
  }
  // The instantiator is the receiver of the caller, which is not a factory.
  // The receiver cannot be null; extract its TypeArguments object.
  Value* instantiator = BuildInstantiator(token_pos);
  intptr_t type_arguments_field_offset =
      instantiator_class.type_arguments_field_offset();
  ASSERT(type_arguments_field_offset != Class::kNoTypeArguments);

  return Bind(new (Z) LoadFieldInstr(
      instantiator, type_arguments_field_offset,
      Type::ZoneHandle(Z, Type::null()),  // Not an instance, no type.
      token_pos));
}

Value* EffectGraphVisitor::BuildFunctionTypeArguments(TokenPosition token_pos) {
  LocalVariable* function_type_arguments_var =
      owner()->parsed_function().function_type_arguments();
  if (function_type_arguments_var == NULL) {
    // We encountered an uninstantiated type referring to type parameters of a
    // signature that is local to the function being compiled. The type remains
    // uninstantiated. Example: Foo(f<T>(T t)) => null;
    // Foo is non-generic, but takes a generic function f as argument.
    // The uninstantiated function type of f cannot be instantiated from within
    // Foo and should not be instantiated. It is used in uninstantiated form to
    // check incoming closures for assignability. We pass an empty function
    // type argument vector.
    return BuildEmptyTypeArguments(token_pos);

    // Note that the function type could also get partially instantiated:
    // Bar<B>(B g<T>(T t)) => null;
    // In this case, function_type_arguments_var will not be null, since Bar
    // is generic, and will be used to partially instantiate the type of g, more
    // specifically the result type of g. Note that the instantiator vector will
    // have length 1, and type parameters with indices above 0, e.g. T, must
    // remain uninstantiated.
  }
  return Bind(BuildLoadLocal(*function_type_arguments_var, token_pos));
}

Value* EffectGraphVisitor::BuildInstantiatedTypeArguments(
    TokenPosition token_pos,
    const TypeArguments& type_arguments) {
  if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
    return Bind(new (Z) ConstantInstr(type_arguments));
  }
  // The type arguments are uninstantiated.
  const Class& instantiator_class =
      Class::ZoneHandle(Z, owner()->function().Owner());
  Value* instantiator_type_args = NULL;
  if (type_arguments.IsInstantiated(kCurrentClass)) {
    instantiator_type_args = BuildNullValue(token_pos);
  } else {
    instantiator_type_args = BuildInstantiatorTypeArguments(token_pos);
    const bool use_instantiator_type_args =
        type_arguments.IsUninstantiatedIdentity() ||
        type_arguments.CanShareInstantiatorTypeArguments(instantiator_class);
    if (use_instantiator_type_args) {
      return instantiator_type_args;
    }
  }
  Value* function_type_args = NULL;
  if (type_arguments.IsInstantiated(kFunctions)) {
    function_type_args = BuildNullValue(token_pos);
  } else {
    function_type_args = BuildFunctionTypeArguments(token_pos);
  }
  return Bind(new (Z) InstantiateTypeArgumentsInstr(
      token_pos, type_arguments, instantiator_class, instantiator_type_args,
      function_type_args, owner()->GetNextDeoptId()));
}

void ValueGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  if (node->constructor().IsFactory()) {
    EffectGraphVisitor::VisitConstructorCallNode(node);
    return;
  }

  // t_n contains the allocated and initialized object.
  //   t_n      <- AllocateObject(class)
  //   t_n      <- StoreLocal(temp, t_n);
  //   t_n+1    <- ctor-arg
  //   t_n+2... <- constructor arguments start here
  //   StaticCall(constructor, t_n, t_n+1, ...)
  //   tn       <- LoadLocal(temp)

  Value* allocate = BuildObjectAllocation(node);
  {
    LocalVariable* tmp_var = EnterTempLocalScope(allocate);
    Value* allocated_tmp =
        Bind(new (Z) LoadLocalInstr(*tmp_var, node->token_pos()));
    PushArgumentInstr* push_allocated_value = PushArgument(allocated_tmp);
    BuildConstructorCall(node, push_allocated_value);
    ReturnDefinition(ExitTempLocalScope(allocate));
  }
}

void EffectGraphVisitor::BuildInstanceGetterConditional(
    InstanceGetterNode* node) {
  const TokenPosition token_pos = node->token_pos();
  LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
  LoadLocalNode* load_temp = new (Z) LoadLocalNode(token_pos, temp_var);

  LiteralNode* null_constant =
      new (Z) LiteralNode(ST(token_pos), Object::null_instance());
  ComparisonNode* check_is_null = new (Z)
      ComparisonNode(ST(token_pos), Token::kEQ, load_temp, null_constant);
  TestGraphVisitor for_test(owner(), ST(token_pos));
  check_is_null->Visit(&for_test);

  EffectGraphVisitor for_true(owner());
  EffectGraphVisitor for_false(owner());

  StoreLocalNode* store_null =
      new (Z) StoreLocalNode(ST(token_pos), temp_var, null_constant);
  store_null->Visit(&for_true);

  InstanceGetterNode* getter =
      new (Z) InstanceGetterNode(token_pos, load_temp, node->field_name());
  StoreLocalNode* store_getter =
      new (Z) StoreLocalNode(ST(token_pos), temp_var, getter);
  store_getter->Visit(&for_false);

  Join(for_test, for_true, for_false);
}

void ValueGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  if (node->is_conditional()) {
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value(), node->token_pos()));
    BuildInstanceGetterConditional(node);
    ReturnDefinition(BuildLoadExprTemp(node->token_pos()));
  } else {
    EffectGraphVisitor::VisitInstanceGetterNode(node);
  }
}

void EffectGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  ValueGraphVisitor for_receiver(owner());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  if (node->is_conditional()) {
    Do(BuildStoreExprTemp(for_receiver.value(), node->token_pos()));
    BuildInstanceGetterConditional(node);
  } else {
    PushArgumentInstr* push_receiver = PushArgument(for_receiver.value());
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(1);
    arguments->Add(push_receiver);
    const String& name =
        String::ZoneHandle(Z, Field::GetterSymbol(node->field_name()));
    const intptr_t kTypeArgsLen = 0;
    InstanceCallInstr* call = new (Z)
        InstanceCallInstr(node->token_pos(), name, Token::kGET, arguments,
                          kTypeArgsLen, Object::null_array(), 1,
                          owner()->ic_data_array(), owner()->GetNextDeoptId());
    ReturnDefinition(call);
  }
}

void EffectGraphVisitor::BuildInstanceSetterArguments(
    InstanceSetterNode* node,
    ZoneGrowableArray<PushArgumentInstr*>* arguments,
    bool result_is_needed) {
  ValueGraphVisitor for_receiver(owner());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  arguments->Add(PushArgument(for_receiver.value()));

  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);

  Value* value = NULL;
  if (result_is_needed) {
    value = Bind(BuildStoreExprTemp(for_value.value(), node->token_pos()));
  } else {
    value = for_value.value();
  }
  arguments->Add(PushArgument(value));
}

void EffectGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  const TokenPosition token_pos = node->token_pos();
  if (node->is_conditional()) {
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value(), token_pos));

    LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
    LoadLocalNode* load_temp = new (Z) LoadLocalNode(ST(token_pos), temp_var);
    LiteralNode* null_constant =
        new (Z) LiteralNode(ST(token_pos), Object::null_instance());
    ComparisonNode* check_is_null = new (Z)
        ComparisonNode(ST(token_pos), Token::kEQ, load_temp, null_constant);
    TestGraphVisitor for_test(owner(), ST(token_pos));
    check_is_null->Visit(&for_test);

    EffectGraphVisitor for_true(owner());
    EffectGraphVisitor for_false(owner());

    InstanceSetterNode* setter = new (Z) InstanceSetterNode(
        token_pos, load_temp, node->field_name(), node->value());
    setter->Visit(&for_false);
    Join(for_test, for_true, for_false);
    return;
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildInstanceSetterArguments(node, arguments, kResultNotNeeded);
  const String& name =
      String::ZoneHandle(Z, Field::SetterSymbol(node->field_name()));
  const int kTypeArgsLen = 0;
  const intptr_t kNumArgsChecked = 1;  // Do not check value type.
  InstanceCallInstr* call = new (Z)
      InstanceCallInstr(token_pos, name, Token::kSET, arguments, kTypeArgsLen,
                        Object::null_array(), kNumArgsChecked,
                        owner()->ic_data_array(), owner()->GetNextDeoptId());
  ReturnDefinition(call);
}

void ValueGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  const TokenPosition token_pos = node->token_pos();
  if (node->is_conditional()) {
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value(), token_pos));

    LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
    LoadLocalNode* load_temp = new (Z) LoadLocalNode(ST(token_pos), temp_var);
    LiteralNode* null_constant =
        new (Z) LiteralNode(ST(token_pos), Object::null_instance());
    ComparisonNode* check_is_null = new (Z)
        ComparisonNode(ST(token_pos), Token::kEQ, load_temp, null_constant);
    TestGraphVisitor for_test(owner(), ST(token_pos));
    check_is_null->Visit(&for_test);

    ValueGraphVisitor for_true(owner());
    null_constant->Visit(&for_true);
    for_true.Do(BuildStoreExprTemp(for_true.value(), token_pos));

    ValueGraphVisitor for_false(owner());
    InstanceSetterNode* setter = new (Z) InstanceSetterNode(
        token_pos, load_temp, node->field_name(), node->value());
    setter->Visit(&for_false);
    for_false.Do(BuildStoreExprTemp(for_false.value(), token_pos));

    Join(for_test, for_true, for_false);
    ReturnDefinition(BuildLoadExprTemp(token_pos));
    return;
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildInstanceSetterArguments(node, arguments, kResultNeeded);
  const String& name =
      String::ZoneHandle(Z, Field::SetterSymbol(node->field_name()));
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kNumArgsChecked = 1;  // Do not check value type.
  Do(new (Z) InstanceCallInstr(token_pos, name, Token::kSET, arguments,
                               kTypeArgsLen, Object::null_array(),
                               kNumArgsChecked, owner()->ic_data_array(),
                               owner()->GetNextDeoptId()));
  ReturnDefinition(BuildLoadExprTemp(token_pos));
}

void EffectGraphVisitor::VisitStaticGetterNode(StaticGetterNode* node) {
  const String& getter_name =
      String::ZoneHandle(Z, Field::GetterSymbol(node->field_name()));
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>();
  Function& getter_function = Function::ZoneHandle(Z, Function::null());
  if (node->is_super_getter()) {
    // Statically resolved instance getter, i.e. "super getter".
    ASSERT(node->receiver() != NULL);
    getter_function =
        Resolver::ResolveDynamicAnyArgs(Z, node->cls(), getter_name);
    if (getter_function.IsNull()) {
      // Resolve and call noSuchMethod.
      ArgumentListNode* arguments = new (Z) ArgumentListNode(node->token_pos());
      arguments->Add(node->receiver());
      StaticCallInstr* call = BuildStaticNoSuchMethodCall(
          node->cls(), node->receiver(), getter_name, arguments,
          false,  // Don't save last argument.
          true);  // Super invocation.
      ReturnDefinition(call);
      return;
    } else {
      ValueGraphVisitor receiver_value(owner());
      node->receiver()->Visit(&receiver_value);
      Append(receiver_value);
      arguments->Add(PushArgument(receiver_value.value()));
    }
  } else {
    getter_function = node->cls().LookupStaticFunction(getter_name);
    if (getter_function.IsNull()) {
      // When the parser encounters a reference to a static field materialized
      // only by a static setter, but no corresponding static getter, it creates
      // a StaticGetterNode ast node referring to the non-existing static getter
      // for the case this field reference appears in a left hand side
      // expression (the parser has not distinguished between left and right
      // hand side yet at this stage). If the parser establishes later that the
      // field access is part of a left hand side expression, the
      // StaticGetterNode is transformed into a StaticSetterNode referring to
      // the existing static setter.
      // However, if the field reference appears in a right hand side
      // expression, no such transformation occurs and we land here with a
      // StaticGetterNode missing a getter function, so we throw a
      // NoSuchMethodError.

      // Throw a NoSuchMethodError.
      StaticCallInstr* call = BuildThrowNoSuchMethodError(
          node->token_pos(), node->cls(), getter_name,
          NULL,  // No Arguments to getter.
          InvocationMirror::EncodeType(node->cls().IsTopLevel()
                                           ? InvocationMirror::kTopLevel
                                           : InvocationMirror::kStatic,
                                       InvocationMirror::kGetter));
      ReturnDefinition(call);
      return;
    }
  }
  ASSERT(!getter_function.IsNull());
  const intptr_t kTypeArgsLen = 0;
  StaticCallInstr* call = new (Z) StaticCallInstr(
      node->token_pos(), getter_function, kTypeArgsLen,
      Object::null_array(),  // No names
      arguments, owner()->ic_data_array(), owner()->GetNextDeoptId(),
      ConvertRebindRule(node->rebind_rule()));
  ReturnDefinition(call);
}

void EffectGraphVisitor::BuildStaticSetter(StaticSetterNode* node,
                                           bool result_is_needed) {
  const String& setter_name =
      String::ZoneHandle(Z, Field::SetterSymbol(node->field_name()));
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(1);
  const TokenPosition token_pos = node->token_pos();
  // A super setter is an instance setter whose setter function is
  // resolved at compile time (in the caller instance getter's super class).
  // Unlike a static getter, a super getter has a receiver parameter.
  const bool is_super_setter = (node->receiver() != NULL);
  const Function& setter_function = node->function();
  StaticCallInstr* call;
  if (setter_function.IsNull()) {
    if (is_super_setter) {
      ASSERT(node->receiver() != NULL);
      // Resolve and call noSuchMethod.
      ArgumentListNode* arguments = new (Z) ArgumentListNode(token_pos);
      arguments->Add(node->receiver());
      arguments->Add(node->value());
      call = BuildStaticNoSuchMethodCall(
          node->cls(), node->receiver(), setter_name, arguments,
          result_is_needed,  // Save last arg if result is needed.
          true);             // Super invocation.
    } else {
      // Throw a NoSuchMethodError.
      ArgumentListNode* arguments = new (Z) ArgumentListNode(token_pos);
      arguments->Add(node->value());
      call = BuildThrowNoSuchMethodError(
          token_pos, node->cls(), setter_name,
          arguments,  // Argument is the value passed to the setter.
          InvocationMirror::EncodeType(node->cls().IsTopLevel()
                                           ? InvocationMirror::kTopLevel
                                           : InvocationMirror::kStatic,
                                       InvocationMirror::kSetter));
    }
  } else {
    if (is_super_setter) {
      // Add receiver of instance getter.
      ValueGraphVisitor for_receiver(owner());
      node->receiver()->Visit(&for_receiver);
      Append(for_receiver);
      arguments->Add(PushArgument(for_receiver.value()));
    }
    ValueGraphVisitor for_value(owner());
    node->value()->Visit(&for_value);
    Append(for_value);
    Value* value = NULL;
    if (result_is_needed) {
      value = Bind(BuildStoreExprTemp(for_value.value(), token_pos));
    } else {
      value = for_value.value();
    }
    arguments->Add(PushArgument(value));
    const intptr_t kTypeArgsLen = 0;
    call = new (Z) StaticCallInstr(token_pos, setter_function, kTypeArgsLen,
                                   Object::null_array(),  // No names.
                                   arguments, owner()->ic_data_array(),
                                   owner()->GetNextDeoptId(),
                                   ConvertRebindRule(node->rebind_rule()));
  }
  if (result_is_needed) {
    Do(call);
    ReturnDefinition(BuildLoadExprTemp(token_pos));
  } else {
    ReturnDefinition(call);
  }
}

void EffectGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  BuildStaticSetter(node, false);  // Result not needed.
}

void ValueGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  BuildStaticSetter(node, true);  // Result needed.
}

static intptr_t OffsetForLengthGetter(MethodRecognizer::Kind kind) {
  switch (kind) {
    case MethodRecognizer::kObjectArrayLength:
    case MethodRecognizer::kImmutableArrayLength:
      return Array::length_offset();
    case MethodRecognizer::kTypedDataLength:
      // .length is defined in _TypedList which is the base class for internal
      // and external typed data.
      ASSERT(TypedData::length_offset() == ExternalTypedData::length_offset());
      return TypedData::length_offset();
    case MethodRecognizer::kGrowableArrayLength:
      return GrowableObjectArray::length_offset();
    default:
      UNREACHABLE();
      return 0;
  }
}

LoadLocalInstr* EffectGraphVisitor::BuildLoadThisVar(LocalScope* scope,
                                                     TokenPosition token_pos) {
  LocalVariable* receiver_var = scope->LookupVariable(Symbols::This(),
                                                      true);  // Test only.
  return new (Z) LoadLocalInstr(*receiver_var, token_pos);
}

LoadFieldInstr* EffectGraphVisitor::BuildNativeGetter(
    NativeBodyNode* node,
    MethodRecognizer::Kind kind,
    intptr_t offset,
    const Type& type,
    intptr_t class_id) {
  Value* receiver = Bind(BuildLoadThisVar(node->scope(), node->token_pos()));
  LoadFieldInstr* load =
      new (Z) LoadFieldInstr(receiver, offset, type, node->token_pos());
  load->set_result_cid(class_id);
  load->set_recognized_kind(kind);
  return load;
}

ConstantInstr* EffectGraphVisitor::DoNativeSetterStoreValue(
    NativeBodyNode* node,
    intptr_t offset,
    StoreBarrierType emit_store_barrier) {
  Value* receiver = Bind(BuildLoadThisVar(node->scope(), node->token_pos()));
  LocalVariable* value_var =
      node->scope()->LookupVariable(Symbols::Value(), true);
  Value* value = Bind(new (Z) LoadLocalInstr(*value_var, node->token_pos()));
  StoreInstanceFieldInstr* store = new (Z) StoreInstanceFieldInstr(
      offset, receiver, value, emit_store_barrier, node->token_pos());
  Do(store);
  return new (Z) ConstantInstr(Object::ZoneHandle(Z, Object::null()));
}

void EffectGraphVisitor::VisitNativeBodyNode(NativeBodyNode* node) {
  const Function& function = owner()->function();
  const TokenPosition token_pos = node->token_pos();
  if (!function.IsClosureFunction()) {
    MethodRecognizer::Kind kind = MethodRecognizer::RecognizeKind(function);
    switch (kind) {
      case MethodRecognizer::kObjectEquals: {
        Value* receiver = Bind(BuildLoadThisVar(node->scope(), token_pos));
        LocalVariable* other_var =
            node->scope()->LookupVariable(Symbols::Other(),
                                          true);  // Test only.
        Value* other = Bind(new (Z) LoadLocalInstr(*other_var, token_pos));
        // Receiver is not a number because numbers override equality.
        const bool kNoNumberCheck = false;
        StrictCompareInstr* compare = new (Z)
            StrictCompareInstr(token_pos, Token::kEQ_STRICT, receiver, other,
                               kNoNumberCheck, owner()->GetNextDeoptId());
        return ReturnDefinition(compare);
      }
      case MethodRecognizer::kStringBaseLength:
      case MethodRecognizer::kStringBaseIsEmpty: {
        LoadFieldInstr* load = BuildNativeGetter(
            node, MethodRecognizer::kStringBaseLength, String::length_offset(),
            Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
        load->set_is_immutable(true);
        if (kind == MethodRecognizer::kStringBaseLength) {
          return ReturnDefinition(load);
        }
        ASSERT(kind == MethodRecognizer::kStringBaseIsEmpty);
        Value* zero_val =
            Bind(new (Z) ConstantInstr(Smi::ZoneHandle(Z, Smi::New(0))));
        Value* load_val = Bind(load);
        StrictCompareInstr* compare = new (Z) StrictCompareInstr(
            token_pos, Token::kEQ_STRICT, load_val, zero_val, false,
            owner()->GetNextDeoptId());  // No number check.
        return ReturnDefinition(compare);
      }
      case MethodRecognizer::kGrowableArrayLength:
      case MethodRecognizer::kObjectArrayLength:
      case MethodRecognizer::kImmutableArrayLength:
      case MethodRecognizer::kTypedDataLength: {
        LoadFieldInstr* load =
            BuildNativeGetter(node, kind, OffsetForLengthGetter(kind),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
        load->set_is_immutable(kind != MethodRecognizer::kGrowableArrayLength);
        return ReturnDefinition(load);
      }
      case MethodRecognizer::kClassIDgetID: {
        LocalVariable* value_var =
            node->scope()->LookupVariable(Symbols::Value(), true);
        Value* value = Bind(new (Z) LoadLocalInstr(*value_var, token_pos));
        LoadClassIdInstr* load = new (Z) LoadClassIdInstr(value);
        return ReturnDefinition(load);
      }
      case MethodRecognizer::kGrowableArrayCapacity: {
        Value* receiver = Bind(BuildLoadThisVar(node->scope(), token_pos));
        LoadFieldInstr* data_load =
            new (Z) LoadFieldInstr(receiver, Array::data_offset(),
                                   Object::dynamic_type(), node->token_pos());
        data_load->set_result_cid(kArrayCid);
        Value* data = Bind(data_load);
        LoadFieldInstr* length_load = new (Z) LoadFieldInstr(
            data, Array::length_offset(), Type::ZoneHandle(Z, Type::SmiType()),
            node->token_pos());
        length_load->set_result_cid(kSmiCid);
        length_load->set_recognized_kind(MethodRecognizer::kObjectArrayLength);
        return ReturnDefinition(length_load);
      }
      case MethodRecognizer::kObjectArrayAllocate: {
        LocalVariable* type_args_parameter = node->scope()->LookupVariable(
            Symbols::TypeArgumentsParameter(), true);
        Value* element_type =
            Bind(new (Z) LoadLocalInstr(*type_args_parameter, token_pos));
        LocalVariable* length_parameter =
            node->scope()->LookupVariable(Symbols::Length(), true);
        Value* length =
            Bind(new (Z) LoadLocalInstr(*length_parameter, token_pos));
        CreateArrayInstr* create_array = new CreateArrayInstr(
            token_pos, element_type, length, owner()->GetNextDeoptId());
        return ReturnDefinition(create_array);
      }
      case MethodRecognizer::kBigint_getDigits: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, Bigint::digits_offset(), Object::dynamic_type(),
            kTypedDataUint32ArrayCid));
      }
      case MethodRecognizer::kBigint_getUsed: {
        return ReturnDefinition(
            BuildNativeGetter(node, kind, Bigint::used_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid));
      }
      case MethodRecognizer::kLinkedHashMap_getIndex: {
        return ReturnDefinition(
            BuildNativeGetter(node, kind, LinkedHashMap::index_offset(),
                              Object::dynamic_type(), kDynamicCid));
      }
      case MethodRecognizer::kLinkedHashMap_setIndex: {
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::index_offset(), kEmitStoreBarrier));
      }
      case MethodRecognizer::kLinkedHashMap_getData: {
        return ReturnDefinition(
            BuildNativeGetter(node, kind, LinkedHashMap::data_offset(),
                              Object::dynamic_type(), kArrayCid));
      }
      case MethodRecognizer::kLinkedHashMap_setData: {
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::data_offset(), kEmitStoreBarrier));
      }
      case MethodRecognizer::kLinkedHashMap_getHashMask: {
        return ReturnDefinition(
            BuildNativeGetter(node, kind, LinkedHashMap::hash_mask_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid));
      }
      case MethodRecognizer::kLinkedHashMap_setHashMask: {
        // Smi field; no barrier needed.
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::hash_mask_offset(), kNoStoreBarrier));
      }
      case MethodRecognizer::kLinkedHashMap_getUsedData: {
        return ReturnDefinition(
            BuildNativeGetter(node, kind, LinkedHashMap::used_data_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid));
      }
      case MethodRecognizer::kLinkedHashMap_setUsedData: {
        // Smi field; no barrier needed.
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::used_data_offset(), kNoStoreBarrier));
      }
      case MethodRecognizer::kLinkedHashMap_getDeletedKeys: {
        return ReturnDefinition(
            BuildNativeGetter(node, kind, LinkedHashMap::deleted_keys_offset(),
                              Type::ZoneHandle(Z, Type::SmiType()), kSmiCid));
      }
      case MethodRecognizer::kLinkedHashMap_setDeletedKeys: {
        // Smi field; no barrier needed.
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::deleted_keys_offset(), kNoStoreBarrier));
      }
      case MethodRecognizer::kBigint_getNeg: {
        return ReturnDefinition(
            BuildNativeGetter(node, kind, Bigint::neg_offset(),
                              Type::ZoneHandle(Z, Type::BoolType()), kBoolCid));
      }
      default:
        break;
    }
  }
  InlineBailout("EffectGraphVisitor::VisitNativeBodyNode");
  NativeCallInstr* native_call = new (Z) NativeCallInstr(node);
  ReturnDefinition(native_call);
}

void EffectGraphVisitor::VisitPrimaryNode(PrimaryNode* node) {
  // PrimaryNodes are temporary during parsing.
  UNREACHABLE();
}

// <Expression> ::= LoadLocal { local: LocalVariable }
void EffectGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  // Nothing to do.
}

void ValueGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  Definition* load = BuildLoadLocal(node->local(), node->token_pos());
  ReturnDefinition(load);
}

// <Expression> ::= StoreLocal { local: LocalVariable
//                               value: <Expression> }
void EffectGraphVisitor::VisitStoreLocalNode(StoreLocalNode* node) {
#if !defined(PRODUCT)
  // If the right hand side is an expression that does not contain
  // a safe point for the debugger to stop, add an explicit stub
  // call. Exception: don't do this when assigning to or from internal
  // variables, or for generated code that has no source position.
  AstNode* rhs = node->value();
  if (rhs->IsAssignableNode()) {
    rhs = rhs->AsAssignableNode()->expr();
  }
  if ((rhs->IsLiteralNode() || rhs->IsLoadStaticFieldNode() ||
       (rhs->IsLoadLocalNode() &&
        !rhs->AsLoadLocalNode()->local().IsInternal()) ||
       rhs->IsClosureNode()) &&
      !node->local().IsInternal() && node->token_pos().IsDebugPause()) {
    AddInstruction(new (Z) DebugStepCheckInstr(node->token_pos(),
                                               RawPcDescriptors::kRuntimeCall,
                                               owner()->GetNextDeoptId()));
  }
#endif

  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = for_value.value();
  if (Isolate::Current()->type_checks()) {
    store_value =
        BuildAssignableValue(node->value()->token_pos(), store_value,
                             node->local().type(), node->local().name());
  }
  Definition* store =
      BuildStoreLocal(node->local(), store_value, node->token_pos());
  ReturnDefinition(store);
}

void EffectGraphVisitor::VisitLoadInstanceFieldNode(
    LoadInstanceFieldNode* node) {
  ValueGraphVisitor for_instance(owner());
  node->instance()->Visit(&for_instance);
  Append(for_instance);
  LoadFieldInstr* load =
      new (Z) LoadFieldInstr(for_instance.value(), &node->field(),
                             AbstractType::ZoneHandle(Z, node->field().type()),
                             node->token_pos(), &owner()->parsed_function());
  ReturnDefinition(load);
}

void EffectGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  const TokenPosition token_pos = node->token_pos();
  ValueGraphVisitor for_instance(owner());
  node->instance()->Visit(&for_instance);
  Append(for_instance);
  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = for_value.value();
  if (isolate()->type_checks()) {
    const AbstractType& type =
        AbstractType::ZoneHandle(Z, node->field().type());
    const String& dst_name = String::ZoneHandle(Z, node->field().name());
    store_value = BuildAssignableValue(node->value()->token_pos(), store_value,
                                       type, dst_name);
  }

  if (isolate()->use_field_guards()) {
    store_value = Bind(BuildStoreExprTemp(store_value, token_pos));
    GuardFieldClassInstr* guard_field_class = new (Z) GuardFieldClassInstr(
        store_value, node->field(), thread()->GetNextDeoptId());
    AddInstruction(guard_field_class);
    store_value = Bind(BuildLoadExprTemp(token_pos));
    GuardFieldLengthInstr* guard_field_length = new (Z) GuardFieldLengthInstr(
        store_value, node->field(), thread()->GetNextDeoptId());
    AddInstruction(guard_field_length);
    store_value = Bind(BuildLoadExprTemp(token_pos));
  }
  StoreInstanceFieldInstr* store = new (Z)
      StoreInstanceFieldInstr(node->field(), for_instance.value(), store_value,
                              kEmitStoreBarrier, token_pos);
  // Maybe initializing unboxed store.
  store->set_is_initialization(node->is_initializer());
  ReturnDefinition(store);
}

void EffectGraphVisitor::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  const TokenPosition token_pos = node->token_pos();
  if (node->field().is_const()) {
    ASSERT(node->field().StaticValue() != Object::sentinel().raw());
    ASSERT(node->field().StaticValue() != Object::transition_sentinel().raw());
    Definition* result = new (Z) ConstantInstr(
        Instance::ZoneHandle(Z, node->field().StaticValue()), token_pos);
    return ReturnDefinition(result);
  }
  Value* field_value = Bind(new (Z) ConstantInstr(
      Field::ZoneHandle(Z, node->field().Original()), token_pos));
  LoadStaticFieldInstr* load =
      new (Z) LoadStaticFieldInstr(field_value, token_pos);
  ReturnDefinition(load);
}

Definition* EffectGraphVisitor::BuildStoreStaticField(
    StoreStaticFieldNode* node,
    bool result_is_needed,
    TokenPosition token_pos) {
#if !defined(PRODUCT)
  // If the right hand side is an expression that does not contain
  // a safe point for the debugger to stop, add an explicit stub
  // call.
  AstNode* rhs = node->value();
  if (rhs->IsAssignableNode()) {
    rhs = rhs->AsAssignableNode()->expr();
  }
  if ((rhs->IsLiteralNode() || rhs->IsLoadLocalNode() ||
       rhs->IsLoadStaticFieldNode() || rhs->IsClosureNode()) &&
      node->token_pos().IsDebugPause()) {
    AddInstruction(new (Z) DebugStepCheckInstr(node->token_pos(),
                                               RawPcDescriptors::kRuntimeCall,
                                               owner()->GetNextDeoptId()));
  }
#endif

  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = NULL;
  if (result_is_needed) {
    store_value = Bind(BuildStoreExprTemp(for_value.value(), token_pos));
  } else {
    store_value = for_value.value();
  }
  StoreStaticFieldInstr* store =
      new (Z) StoreStaticFieldInstr(node->field(), store_value, token_pos);

  if (result_is_needed) {
    Do(store);
    return BuildLoadExprTemp(token_pos);
  } else {
    return store;
  }
}

void EffectGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  ReturnDefinition(
      BuildStoreStaticField(node, kResultNotNeeded, node->token_pos()));
}

void ValueGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  ReturnDefinition(
      BuildStoreStaticField(node, kResultNeeded, node->token_pos()));
}

void EffectGraphVisitor::VisitLoadIndexedNode(LoadIndexedNode* node) {
  Function* super_function = NULL;
  if (node->IsSuperLoad()) {
    // Resolve the load indexed operator in the super class.
    super_function = &Function::ZoneHandle(
        Z, Resolver::ResolveDynamicAnyArgs(Z, node->super_class(),
                                           Symbols::IndexToken()));
    if (super_function->IsNull()) {
      // Could not resolve super operator. Generate call noSuchMethod() of the
      // super class instead.
      ArgumentListNode* arguments = new (Z) ArgumentListNode(node->token_pos());
      arguments->Add(node->array());
      arguments->Add(node->index_expr());
      StaticCallInstr* call = BuildStaticNoSuchMethodCall(
          node->super_class(), node->array(), Symbols::IndexToken(), arguments,
          false,  // Don't save last arg.
          true);  // Super invocation.
      ReturnDefinition(call);
      return;
    }
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  ValueGraphVisitor for_array(owner());
  node->array()->Visit(&for_array);
  Append(for_array);
  arguments->Add(PushArgument(for_array.value()));

  ValueGraphVisitor for_index(owner());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  arguments->Add(PushArgument(for_index.value()));

  const intptr_t kTypeArgsLen = 0;
  if (super_function != NULL) {
    // Generate static call to super operator.
    StaticCallInstr* load = new (Z) StaticCallInstr(
        node->token_pos(), *super_function, kTypeArgsLen, Object::null_array(),
        arguments, owner()->ic_data_array(), owner()->GetNextDeoptId(),
        ICData::kStatic);
    ReturnDefinition(load);
  } else {
    // Generate dynamic call to index operator.
    const intptr_t checked_argument_count = 1;
    InstanceCallInstr* load = new (Z) InstanceCallInstr(
        node->token_pos(), Symbols::IndexToken(), Token::kINDEX, arguments,
        kTypeArgsLen, Object::null_array(), checked_argument_count,
        owner()->ic_data_array(), owner()->GetNextDeoptId());
    ReturnDefinition(load);
  }
}

Definition* EffectGraphVisitor::BuildStoreIndexedValues(StoreIndexedNode* node,
                                                        bool result_is_needed) {
  Function* super_function = NULL;
  const TokenPosition token_pos = node->token_pos();
  if (node->IsSuperStore()) {
    // Resolve the store indexed operator in the super class.
    super_function = &Function::ZoneHandle(
        Z, Resolver::ResolveDynamicAnyArgs(Z, node->super_class(),
                                           Symbols::AssignIndexToken()));
    if (super_function->IsNull()) {
      // Could not resolve super operator. Generate call noSuchMethod() of the
      // super class instead.
      ArgumentListNode* arguments = new (Z) ArgumentListNode(token_pos);
      arguments->Add(node->array());
      arguments->Add(node->index_expr());
      arguments->Add(node->value());
      StaticCallInstr* call = BuildStaticNoSuchMethodCall(
          node->super_class(), node->array(), Symbols::AssignIndexToken(),
          arguments,
          result_is_needed,  // Save last arg if result is needed.
          true);             // Super invocation.
      if (result_is_needed) {
        Do(call);
        // BuildStaticNoSuchMethodCall stores the value in expression_temp.
        return BuildLoadExprTemp(token_pos);
      } else {
        return call;
      }
    }
  }

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(3);
  ValueGraphVisitor for_array(owner());
  node->array()->Visit(&for_array);
  Append(for_array);
  arguments->Add(PushArgument(for_array.value()));

  ValueGraphVisitor for_index(owner());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  arguments->Add(PushArgument(for_index.value()));

  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* value = NULL;
  if (result_is_needed) {
    value = Bind(BuildStoreExprTemp(for_value.value(), token_pos));
  } else {
    value = for_value.value();
  }
  arguments->Add(PushArgument(value));

  const intptr_t kTypeArgsLen = 0;
  if (super_function != NULL) {
    // Generate static call to super operator []=.

    StaticCallInstr* store = new (Z) StaticCallInstr(
        token_pos, *super_function, kTypeArgsLen, Object::null_array(),
        arguments, owner()->ic_data_array(), owner()->GetNextDeoptId(),
        ICData::kStatic);
    if (result_is_needed) {
      Do(store);
      return BuildLoadExprTemp(token_pos);
    } else {
      return store;
    }
  } else {
    // Generate dynamic call to operator []=.
    const intptr_t checked_argument_count = 2;  // Do not check for value type.
    InstanceCallInstr* store = new (Z) InstanceCallInstr(
        token_pos, Symbols::AssignIndexToken(), Token::kASSIGN_INDEX, arguments,
        kTypeArgsLen, Object::null_array(), checked_argument_count,
        owner()->ic_data_array(), owner()->GetNextDeoptId());
    if (result_is_needed) {
      Do(store);
      return BuildLoadExprTemp(token_pos);
    } else {
      return store;
    }
  }
}

void EffectGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  ReturnDefinition(BuildStoreIndexedValues(node, kResultNotNeeded));
}

void ValueGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  ReturnDefinition(BuildStoreIndexedValues(node, kResultNeeded));
}

bool EffectGraphVisitor::HasContextScope() const {
  const ContextScope& context_scope =
      ContextScope::Handle(owner()->function().context_scope());
  return !context_scope.IsNull() && (context_scope.num_variables() > 0);
}

void EffectGraphVisitor::UnchainContexts(intptr_t n) {
  // TODO(johnmccutchan): Pass this in.
  const TokenPosition token_pos = TokenPosition::kContext;
  if (n > 0) {
    Value* context = Bind(BuildCurrentContext(token_pos));
    while (n-- > 0) {
      context = Bind(new (Z) LoadFieldInstr(context, Context::parent_offset(),
                                            // Not an instance, no type.
                                            Type::ZoneHandle(Z, Type::null()),
                                            token_pos));
    }
    Do(BuildStoreContext(context, token_pos));
  }
}

void EffectGraphVisitor::AdjustContextLevel(LocalScope* target_scope) {
  ASSERT(target_scope != NULL);
  intptr_t target_context_level = 0;
  if (target_scope->num_context_variables() > 0) {
    // The scope of the target label allocates a context, therefore its outer
    // scope is at a lower context level.
    target_context_level = target_scope->context_level() - 1;
  } else {
    // The scope of the target label does not allocate a context, so its outer
    // scope is at the same context level. Find it.
    while ((target_scope != NULL) &&
           (target_scope->num_context_variables() == 0)) {
      target_scope = target_scope->parent();
    }
    if (target_scope != NULL) {
      target_context_level = target_scope->context_level();
    }
  }
  ASSERT(target_context_level >= 0);
  intptr_t current_context_level = owner()->context_level();
  ASSERT(current_context_level >= target_context_level);
  UnchainContexts(current_context_level - target_context_level);
  // Record adjusted context level.
  owner()->nesting_stack()->AdjustContextLevel(target_context_level);
}

// <Statement> ::= Sequence { scope: LocalScope
//                            nodes: <Statement>*
//                            label: SourceLabel }
void EffectGraphVisitor::VisitSequenceNode(SequenceNode* node) {
  LocalScope* scope = node->scope();
  const Function& function = owner()->function();
  const intptr_t num_context_variables =
      (scope != NULL) ? scope->num_context_variables() : 0;
  const bool is_top_level_sequence =
      node == owner()->parsed_function().node_sequence();
  // The outermost function sequence cannot contain a label.
  ASSERT((node->label() == NULL) || !is_top_level_sequence);
  NestedBlock nested_block(owner(), node);

  if (num_context_variables > 0) {
    // The local scope declares variables that are captured.
    // Allocate and chain a new context (Except don't chain when at the function
    // entry if the function does not capture any variables from outer scopes).
    Value* allocated_context = Bind(
        new (Z) AllocateContextInstr(node->token_pos(), num_context_variables));
    {
      LocalVariable* tmp_var = EnterTempLocalScope(allocated_context);
      if (!is_top_level_sequence || HasContextScope()) {
        ASSERT(is_top_level_sequence ||
               (nested_block.ContextLevel() ==
                nested_block.outer()->ContextLevel() + 1));
        Value* tmp_val =
            Bind(new (Z) LoadLocalInstr(*tmp_var, node->token_pos()));
        Value* parent_context = Bind(BuildCurrentContext(node->token_pos()));
        Do(new (Z) StoreInstanceFieldInstr(Context::parent_offset(), tmp_val,
                                           parent_context, kEmitStoreBarrier,
                                           node->token_pos()));
      }
      Do(BuildStoreContext(Bind(ExitTempLocalScope(allocated_context)),
                           node->token_pos()));
    }

    // If this node_sequence is the body of the function being compiled, copy
    // the captured parameters from the frame into the context.
    if (is_top_level_sequence) {
      ASSERT(scope->context_level() == 1);
      const int num_params = function.NumParameters();
      int param_frame_index = (num_params == function.num_fixed_parameters())
                                  ? (kParamEndSlotFromFp + num_params)
                                  : kFirstLocalSlotFromFp;
      for (int pos = 0; pos < num_params; param_frame_index--, pos++) {
        const LocalVariable& parameter = *scope->VariableAt(pos);
        ASSERT(parameter.owner() == scope);
        if (parameter.is_captured()) {
          // Create a temporary local describing the original position.
          const String& temp_name = Symbols::TempParam();
          LocalVariable* temp_local =
              new (Z) LocalVariable(TokenPosition::kNoSource,  // Token index.
                                    TokenPosition::kNoSource,  // Token index.
                                    temp_name,
                                    Object::dynamic_type());  // Type.
          temp_local->set_index(param_frame_index);

          // Mark this local as captured parameter so that the optimizer
          // correctly handles these when compiling try-catch: Captured
          // parameters are not in the stack environment, therefore they
          // must be skipped when emitting sync-code in try-blocks.
          temp_local->set_is_captured_parameter(true);

          // Copy parameter from local frame to current context.
          Value* load = Bind(BuildLoadLocal(*temp_local, node->token_pos()));
          Do(BuildStoreLocal(parameter, load, ST(node->token_pos())));
          // Write NULL to the source location to detect buggy accesses and
          // allow GC of passed value if it gets overwritten by a new value in
          // the function.
          Value* null_constant = Bind(
              new (Z) ConstantInstr(Object::ZoneHandle(Z, Object::null())));
          Do(BuildStoreLocal(*temp_local, null_constant,
                             ST(node->token_pos())));
        }
      }
    }
  }

  // Load the passed-in type argument vector from the temporary stack slot,
  // prepend the function type arguments of the generic parent function, and
  // store it to the final location, possibly in the context.
  if (FLAG_reify_generic_functions && is_top_level_sequence &&
      function.IsGeneric()) {
    const ParsedFunction& parsed_function = owner()->parsed_function();
    LocalVariable* type_args_var = parsed_function.function_type_arguments();
    ASSERT(type_args_var->owner() == scope);
    LocalVariable* parent_type_args_var =
        parsed_function.parent_type_arguments();
    if (type_args_var->is_captured() || (parent_type_args_var != NULL)) {
      // Create a temporary local describing the original position.
      const String& temp_name = Symbols::TempParam();
      LocalVariable* temp_local =
          new (Z) LocalVariable(TokenPosition::kNoSource,  // Token index.
                                TokenPosition::kNoSource,  // Token index.
                                temp_name,
                                Object::dynamic_type());  // Type.
      temp_local->set_index(parsed_function.first_stack_local_index());

      // Mark this local as captured parameter so that the optimizer
      // correctly handles these when compiling try-catch: Captured
      // parameters are not in the stack environment, therefore they
      // must be skipped when emitting sync-code in try-blocks.
      temp_local->set_is_captured_parameter(true);  // TODO(regis): Correct?

      Value* type_args_val =
          Bind(BuildLoadLocal(*temp_local, node->token_pos()));
      if (parent_type_args_var != NULL) {
        ASSERT(parent_type_args_var->owner() != scope);
        // Call the runtime to concatenate both vectors.
        ZoneGrowableArray<PushArgumentInstr*>* arguments =
            new (Z) ZoneGrowableArray<PushArgumentInstr*>(3);
        arguments->Add(PushArgument(type_args_val));
        Value* parent_type_args_val =
            Bind(BuildLoadLocal(*parent_type_args_var, node->token_pos()));
        arguments->Add(PushArgument(parent_type_args_val));
        Value* len_const = Bind(new (Z) ConstantInstr(
            Smi::ZoneHandle(Z, Smi::New(function.NumTypeParameters() +
                                        function.NumParentTypeParameters()))));
        arguments->Add(PushArgument(len_const));
        const Library& dart_internal =
            Library::Handle(Z, Library::InternalLibrary());
        const Function& prepend_function =
            Function::ZoneHandle(Z, dart_internal.LookupFunctionAllowPrivate(
                                        Symbols::PrependTypeArguments()));
        ASSERT(!prepend_function.IsNull());
        const intptr_t kTypeArgsLen = 0;
        type_args_val = Bind(new (Z) StaticCallInstr(
            node->token_pos(), prepend_function, kTypeArgsLen,
            Object::null_array(),  // No names.
            arguments, owner()->ic_data_array(), owner()->GetNextDeoptId(),
            ICData::kStatic));
      }
      Do(BuildStoreLocal(*type_args_var, type_args_val, ST(node->token_pos())));
      if (type_args_var->is_captured()) {
        // Write NULL to the source location to detect buggy accesses and
        // allow GC of passed value if it gets overwritten by a new value in
        // the function.
        Value* null_constant =
            Bind(new (Z) ConstantInstr(Object::ZoneHandle(Z, Object::null())));
        Do(BuildStoreLocal(*temp_local, null_constant, ST(node->token_pos())));
      } else {
        // Do not write NULL, since the temp is also the final location.
        ASSERT(temp_local->index() == type_args_var->index());
      }
    } else {
      // The type args slot is the final location. No copy needed.
      ASSERT(type_args_var->index() ==
             parsed_function.first_stack_local_index());
    }
  }

  if (FLAG_causal_async_stacks && is_top_level_sequence &&
      (function.IsAsyncClosure() || function.IsAsyncGenClosure())) {
    LocalScope* top_scope = node->scope();
    // Fetch the :async_stack_trace variable and store it into the thread.
    LocalVariable* async_stack_trace_var =
        top_scope->LookupVariable(Symbols::AsyncStackTraceVar(), false);
    ASSERT((async_stack_trace_var != NULL) &&
           async_stack_trace_var->is_captured());
    // Load :async_stack_trace
    Value* async_stack_trace_value = Bind(BuildLoadLocal(
        *async_stack_trace_var, node->token_pos().ToSynthetic()));
    // Setup arguments for _asyncSetThreadStackTrace.
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new (Z) ZoneGrowableArray<PushArgumentInstr*>(1);
    arguments->Add(PushArgument(async_stack_trace_value));

    const Function& async_set_thread_stack_trace = Function::ZoneHandle(
        Z, isolate()->object_store()->async_set_thread_stack_trace());
    ASSERT(!async_set_thread_stack_trace.IsNull());
    // Call _asyncSetThreadStackTrace
    const intptr_t kTypeArgsLen = 0;
    StaticCallInstr* call_async_set_thread_stack_trace =
        new (Z) StaticCallInstr(node->token_pos().ToSynthetic(),
                                async_set_thread_stack_trace, kTypeArgsLen,
                                Object::null_array(), arguments,
                                owner()->ic_data_array(),
                                owner()->GetNextDeoptId(), ICData::kStatic);
    Do(call_async_set_thread_stack_trace);
  }

#if !defined(PRODUCT)
  if (is_top_level_sequence && function.is_debuggable()) {
    // Place a debug check at method entry to ensure breaking on a method always
    // happens, even if there are no assignments/calls/runtimecalls in the first
    // basic block. Place this check at the last parameter to ensure parameters
    // are in scope in the debugger at method entry.
    const int num_params = function.NumParameters();
    TokenPosition check_pos = TokenPosition::kNoSource;
    if (num_params > 0) {
      const LocalVariable& parameter = *scope->VariableAt(num_params - 1);
      check_pos = parameter.token_pos();
    }

    if (check_pos.IsNoSource() || (check_pos.Pos() < node->token_pos().Pos())) {
      // No parameters or synthetic parameters, e.g. 'this'.
      check_pos = node->token_pos();
      ASSERT(check_pos.IsDebugPause());
    }
    AddInstruction(new (Z) DebugStepCheckInstr(
        check_pos, RawPcDescriptors::kRuntimeCall, owner()->GetNextDeoptId()));
  }
#endif

  // This check may be deleted if the generated code is leaf.
  // Native functions don't need a stack check at entry.
  if (is_top_level_sequence && !function.is_native()) {
    // Always allocate CheckOverflowInstr so that deopt-ids match regardless
    // if we inline or not.
    if (!function.IsImplicitGetterFunction() &&
        !function.IsImplicitSetterFunction()) {
      // We want the stack overlow error to be reported at the opening '{' or
      // at the '=>' location. So, we get the sequence node corresponding to the
      // body inside |node| and use its token position.
      ASSERT(node->length() > 0);
      CheckStackOverflowInstr* check = new (Z) CheckStackOverflowInstr(
          node->NodeAt(0)->token_pos(), 0, owner()->GetNextDeoptId());
      // If we are inlining don't actually attach the stack check. We must still
      // create the stack check in order to allocate a deopt id.
      if (!owner()->IsInlining()) {
        AddInstruction(check);
      }
    }
  }

  if (Isolate::Current()->type_checks() && is_top_level_sequence) {
    const int num_params = function.NumParameters();
    int pos = 0;
    if (function.IsFactory() || function.IsDynamicFunction() ||
        function.IsGenerativeConstructor()) {
      // Skip type checking of type arguments for factory functions.
      // Skip type checking of receiver for instance functions and constructors.
      pos = 1;
    }
    while (pos < num_params) {
      const LocalVariable& parameter = *scope->VariableAt(pos);
      ASSERT(parameter.owner() == scope);
      if (!CanSkipTypeCheck(parameter.token_pos(), NULL, parameter.type(),
                            parameter.name())) {
        Value* parameter_value =
            Bind(BuildLoadLocal(parameter, parameter.token_pos()));
        Do(BuildAssertAssignable(parameter.token_pos(), parameter_value,
                                 parameter.type(), parameter.name()));
      }
      pos++;
    }
  }

  // Continuation part:
  // If this node sequence is the body of a function with continuations,
  // leave room for a preamble.
  // The preamble is generated after visiting the body.
  GotoInstr* preamble_start = NULL;
  if (is_top_level_sequence &&
      (function.IsAsyncClosure() || function.IsSyncGenClosure() ||
       function.IsAsyncGenClosure())) {
    JoinEntryInstr* preamble_end =
        new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                               owner()->GetNextDeoptId());
    ASSERT(exit() != NULL);
    exit()->Goto(preamble_end);
    ASSERT(exit()->next()->IsGoto());
    preamble_start = exit()->next()->AsGoto();
    ASSERT(preamble_start->IsGoto());
    exit_ = preamble_end;
  }

  intptr_t i = 0;
  while (is_open() && (i < node->length())) {
    EffectGraphVisitor for_effect(owner());
    node->NodeAt(i++)->Visit(&for_effect);
    Append(for_effect);
    if (!is_open()) {
      // E.g., because of a JumpNode.
      break;
    }
  }

  // Continuation part:
  // After generating the CFG for the body we can create the preamble
  // because we know exactly how many continuation states we need.
  if (is_top_level_sequence &&
      (function.IsAsyncClosure() || function.IsSyncGenClosure() ||
       function.IsAsyncGenClosure())) {
    ASSERT(preamble_start != NULL);
    // We are at the top level. Fetch the corresponding scope.
    LocalScope* top_scope = node->scope();
    LocalVariable* jump_var =
        top_scope->LookupVariable(Symbols::AwaitJumpVar(), false);
    ASSERT(jump_var != NULL && jump_var->is_captured());
    Instruction* saved_entry = entry_;
    Instruction* saved_exit = exit_;
    entry_ = NULL;
    exit_ = NULL;

    LoadLocalNode* load_jump_count =
        new (Z) LoadLocalNode(node->token_pos(), jump_var);
    ComparisonNode* check_jump_count;
    const intptr_t num_await_states = owner()->await_joins()->length();

    LocalVariable* old_context =
        top_scope->LookupVariable(Symbols::AwaitContextVar(), false);
    for (intptr_t i = 0; i < num_await_states; i++) {
      check_jump_count = new (Z)
          ComparisonNode(ST(node->token_pos()), Token::kEQ, load_jump_count,
                         new (Z) LiteralNode(ST(node->token_pos()),
                                             Smi::ZoneHandle(Z, Smi::New(i))));
      TestGraphVisitor for_test(owner(), ST(node->token_pos()));
      check_jump_count->Visit(&for_test);
      EffectGraphVisitor for_true(owner());
      EffectGraphVisitor for_false(owner());

      // Build async jump or sync yield jump.
      ASSERT(function.IsAsyncClosure() || function.IsAsyncGenClosure() ||
             function.IsSyncGenClosure());

      // Restore the saved continuation context, i.e. the context that was
      // saved into :await_ctx_var before the closure suspended.
      for_true.BuildRestoreContext(*old_context, ST(node->token_pos()));

      // Goto saved join.
      for_true.Goto((*owner()->await_joins())[i]);

      Join(for_test, for_true, for_false);
      if (i == 0) {
        // Manually link up the preamble start.
        preamble_start->previous()->set_next(for_test.entry());
        for_test.entry()->set_previous(preamble_start->previous());
      }
      if (i == (num_await_states - 1)) {
        // Link up preamble end.
        if (exit_ == NULL) {
          exit_ = preamble_start;
        } else {
          exit_->LinkTo(preamble_start);
        }
      }
    }
    entry_ = saved_entry;
    exit_ = saved_exit;
  }

  if (is_open() && (num_context_variables > 0) &&
      (!is_top_level_sequence || HasContextScope())) {
    UnchainContexts(1);
  }

  // If this node sequence is labeled, a break out of the sequence will have
  // taken care of unchaining the context.
  if (nested_block.break_target() != NULL) {
    if (is_open()) Goto(nested_block.break_target());
    exit_ = nested_block.break_target();
  }
}

void EffectGraphVisitor::VisitCatchClauseNode(CatchClauseNode* node) {
  InlineBailout("EffectGraphVisitor::VisitCatchClauseNode (exception)");
  // Restores current context from local variable ':saved_try_context_var'.
  BuildRestoreContext(node->context_var(), node->token_pos());

  EffectGraphVisitor for_catch(owner());
  node->VisitChildren(&for_catch);
  Append(for_catch);
}

void EffectGraphVisitor::VisitTryCatchNode(TryCatchNode* node) {
  InlineBailout("EffectGraphVisitor::VisitTryCatchNode (exception)");
  CatchClauseNode* catch_block = node->catch_block();
  SequenceNode* finally_block = node->finally_block();
  if ((finally_block != NULL) && (finally_block->length() == 0)) {
    SequenceNode* catch_sequence = catch_block->sequence();
    if (catch_sequence->length() == 1) {
      // Check for a single rethrow statement. This only matches the synthetic
      // catch-clause generated for try-finally.
      ThrowNode* throw_node = catch_sequence->NodeAt(0)->AsThrowNode();
      if ((throw_node != NULL) && (throw_node->stacktrace() != NULL)) {
        // Empty finally-block in a try-finally can be optimized away.
        EffectGraphVisitor for_try(owner());
        node->try_block()->Visit(&for_try);
        Append(for_try);
        return;
      }
    }
  }

  const intptr_t original_handler_index = owner()->try_index();
  const intptr_t try_handler_index = node->try_index();
  ASSERT(try_handler_index != original_handler_index);
  owner()->set_try_index(try_handler_index);

  // Preserve current context into local variable ':saved_try_context_var'.
  BuildSaveContext(node->context_var(), ST(node->token_pos()));

  EffectGraphVisitor for_try(owner());
  node->try_block()->Visit(&for_try);

  if (for_try.is_open()) {
    JoinEntryInstr* after_try = new (Z)
        JoinEntryInstr(owner()->AllocateBlockId(), original_handler_index,
                       owner()->GetNextDeoptId());
    for_try.Goto(after_try);
    for_try.exit_ = after_try;
  }

  JoinEntryInstr* try_entry = new (Z) JoinEntryInstr(
      owner()->AllocateBlockId(), try_handler_index, owner()->GetNextDeoptId());

  Goto(try_entry);
  AppendFragment(try_entry, for_try);
  exit_ = for_try.exit_;

  // We are done generating code for the try block.
  owner()->set_try_index(original_handler_index);

  // If there is a finally block, it is the handler for code in the catch
  // block.
  const intptr_t catch_handler_index = (finally_block == NULL)
                                           ? original_handler_index
                                           : catch_block->catch_handler_index();

  const intptr_t prev_catch_try_index = owner()->catch_try_index();

  owner()->set_try_index(catch_handler_index);
  owner()->set_catch_try_index(try_handler_index);
  EffectGraphVisitor for_catch(owner());
  catch_block->Visit(&for_catch);
  owner()->set_catch_try_index(prev_catch_try_index);

  // NOTE: The implicit variables ':saved_try_context_var', ':exception_var'
  // and ':stack_trace_var' can never be captured variables.
  ASSERT(!catch_block->context_var().is_captured());
  ASSERT(!catch_block->exception_var().is_captured());
  ASSERT(!catch_block->stacktrace_var().is_captured());

  CatchBlockEntryInstr* catch_entry = new (Z) CatchBlockEntryInstr(
      catch_block->token_pos(), (node->token_pos() == TokenPosition::kNoSource),
      owner()->AllocateBlockId(), catch_handler_index, owner()->graph_entry(),
      catch_block->handler_types(), try_handler_index,
      catch_block->exception_var(), catch_block->stacktrace_var(),
      catch_block->needs_stacktrace(), owner()->GetNextDeoptId());
  owner()->AddCatchEntry(catch_entry);
  AppendFragment(catch_entry, for_catch);

  if (for_catch.is_open()) {
    JoinEntryInstr* join = new (Z)
        JoinEntryInstr(owner()->AllocateBlockId(), original_handler_index,
                       owner()->GetNextDeoptId());
    for_catch.Goto(join);
    if (is_open()) Goto(join);
    exit_ = join;
  }

  if (finally_block != NULL) {
    ASSERT(node->rethrow_clause() != NULL);
    // Create a handler for the code in the catch block, containing the
    // code in the finally block.
    owner()->set_try_index(original_handler_index);
    EffectGraphVisitor for_finally(owner());
    for_finally.BuildRestoreContext(catch_block->context_var(),
                                    finally_block->token_pos());

    node->rethrow_clause()->Visit(&for_finally);
    if (for_finally.is_open()) {
      // Rethrow the exception.  Manually build the graph for rethrow.
      Value* exception = for_finally.Bind(for_finally.BuildLoadLocal(
          catch_block->rethrow_exception_var(), finally_block->token_pos()));
      for_finally.PushArgument(exception);
      Value* stacktrace = for_finally.Bind(for_finally.BuildLoadLocal(
          catch_block->rethrow_stacktrace_var(), finally_block->token_pos()));
      for_finally.PushArgument(stacktrace);
      for_finally.AddInstruction(
          new (Z) ReThrowInstr(catch_block->token_pos(), catch_handler_index,
                               owner()->GetNextDeoptId()));
      for_finally.CloseFragment();
    }
    ASSERT(!for_finally.is_open());

    const Array& types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
    types.SetAt(0, Object::dynamic_type());
    CatchBlockEntryInstr* finally_entry = new (Z) CatchBlockEntryInstr(
        finally_block->token_pos(),
        true,  // this is not a catch block from user code.
        owner()->AllocateBlockId(), original_handler_index,
        owner()->graph_entry(), types, catch_handler_index,
        catch_block->exception_var(), catch_block->stacktrace_var(),
        catch_block->needs_stacktrace(), owner()->GetNextDeoptId());
    owner()->AddCatchEntry(finally_entry);
    AppendFragment(finally_entry, for_finally);
  }

  // Generate code for the finally block if one exists.
  if ((finally_block != NULL) && is_open()) {
    EffectGraphVisitor for_finally_block(owner());
    finally_block->Visit(&for_finally_block);
    Append(for_finally_block);
  }
}

// Looks up dynamic method noSuchMethod in target_class
// (including its super class chain) and builds a static call to it.
StaticCallInstr* EffectGraphVisitor::BuildStaticNoSuchMethodCall(
    const Class& target_class,
    AstNode* receiver,
    const String& method_name,
    ArgumentListNode* method_arguments,
    bool save_last_arg,
    bool is_super_invocation) {
  TokenPosition args_pos = method_arguments->token_pos();
  LocalVariable* temp = NULL;
  if (save_last_arg) {
    temp = owner()->parsed_function().expression_temp_var();
  }
  ArgumentListNode* args = Parser::BuildNoSuchMethodArguments(
      args_pos, method_name, *method_arguments, temp, is_super_invocation);
  // Make sure we resolve to a compatible noSuchMethod, otherwise call
  // noSuchMethod of class Object.
  const int kTypeArgsLen = 0;
  const int kNumArguments = 2;
  ArgumentsDescriptor args_desc(Array::ZoneHandle(
      Z, ArgumentsDescriptor::New(kTypeArgsLen, kNumArguments)));
  Function& no_such_method_func = Function::ZoneHandle(
      Z, Resolver::ResolveDynamicForReceiverClass(
             target_class, Symbols::NoSuchMethod(), args_desc));
  if (no_such_method_func.IsNull()) {
    const Class& object_class =
        Class::ZoneHandle(Z, isolate()->object_store()->object_class());
    no_such_method_func = Resolver::ResolveDynamicForReceiverClass(
        object_class, Symbols::NoSuchMethod(), args_desc);
  }
  // We are guaranteed to find noSuchMethod of class Object.
  ASSERT(!no_such_method_func.IsNull());
  ZoneGrowableArray<PushArgumentInstr*>* push_arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildPushArguments(*args, push_arguments);
  return new (Z) StaticCallInstr(args_pos, no_such_method_func, kTypeArgsLen,
                                 Object::null_array(), push_arguments,
                                 owner()->ic_data_array(),
                                 owner()->GetNextDeoptId(), ICData::kStatic);
}

StaticCallInstr* EffectGraphVisitor::BuildThrowNoSuchMethodError(
    TokenPosition token_pos,
    const Class& function_class,
    const String& function_name,
    ArgumentListNode* function_arguments,
    int invocation_type) {
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new (Z) ZoneGrowableArray<PushArgumentInstr*>();
  // Object receiver, actually a class literal of the unresolved method's owner.
  AbstractType& type = Type::ZoneHandle(
      Z, Type::New(function_class, Object::null_type_arguments(), token_pos,
                   Heap::kOld));
  type ^= ClassFinalizer::FinalizeType(function_class, type);
  Value* receiver_value = Bind(new (Z) ConstantInstr(type));
  arguments->Add(PushArgument(receiver_value));
  // String memberName.
  const String& member_name =
      String::ZoneHandle(Z, Symbols::New(T, function_name));
  Value* member_name_value = Bind(new (Z) ConstantInstr(member_name));
  arguments->Add(PushArgument(member_name_value));
  // Smi invocation_type.
  Value* invocation_type_value = Bind(
      new (Z) ConstantInstr(Smi::ZoneHandle(Z, Smi::New(invocation_type))));
  arguments->Add(PushArgument(invocation_type_value));
  // Object typeArguments.
  Value* type_arguments_value = Bind(new (Z) ConstantInstr(
      function_arguments == NULL
          ? TypeArguments::ZoneHandle(Z, TypeArguments::null())
          : function_arguments->type_arguments()));
  arguments->Add(PushArgument(type_arguments_value));
  // List arguments.
  if (function_arguments == NULL) {
    Value* arguments_value =
        Bind(new (Z) ConstantInstr(Array::ZoneHandle(Z, Array::null())));
    arguments->Add(PushArgument(arguments_value));
  } else {
    ValueGraphVisitor array_val(owner());
    ArrayNode* array =
        new (Z) ArrayNode(token_pos, Type::ZoneHandle(Z, Type::ArrayType()),
                          function_arguments->nodes());
    array->Visit(&array_val);
    Append(array_val);
    arguments->Add(PushArgument(array_val.value()));
  }
  // List argumentNames.
  ConstantInstr* cinstr = new (Z) ConstantInstr(
      (function_arguments == NULL) ? Array::ZoneHandle(Z, Array::null())
                                   : function_arguments->names());
  Value* argument_names_value = Bind(cinstr);
  arguments->Add(PushArgument(argument_names_value));

  // Resolve and call NoSuchMethodError._throwNew.
  const Library& core_lib = Library::Handle(Z, Library::CoreLibrary());
  const Class& cls =
      Class::Handle(Z, core_lib.LookupClass(Symbols::NoSuchMethodError()));
  ASSERT(!cls.IsNull());
  const intptr_t kTypeArgsLen = 0;
  const Function& func = Function::ZoneHandle(
      Z, Resolver::ResolveStatic(
             cls, Library::PrivateCoreLibName(Symbols::ThrowNew()),
             kTypeArgsLen, arguments->length(), Object::null_array()));
  ASSERT(!func.IsNull());
  return new (Z) StaticCallInstr(token_pos, func, kTypeArgsLen,
                                 Object::null_array(),  // No names.
                                 arguments, owner()->ic_data_array(),
                                 owner()->GetNextDeoptId(), ICData::kStatic);
}

void EffectGraphVisitor::BuildThrowNode(ThrowNode* node) {
#if !defined(PRODUCT)
  if (node->exception()->IsLiteralNode() ||
      node->exception()->IsLoadLocalNode() ||
      node->exception()->IsLoadStaticFieldNode() ||
      node->exception()->IsClosureNode()) {
    AddInstruction(new (Z) DebugStepCheckInstr(node->token_pos(),
                                               RawPcDescriptors::kRuntimeCall,
                                               owner()->GetNextDeoptId()));
  }
#endif
  ValueGraphVisitor for_exception(owner());
  node->exception()->Visit(&for_exception);
  Append(for_exception);
  PushArgument(for_exception.value());
  Instruction* instr = NULL;
  if (node->stacktrace() == NULL) {
    instr = new (Z) ThrowInstr(node->token_pos(), owner()->GetNextDeoptId());
  } else {
    ValueGraphVisitor for_stack_trace(owner());
    node->stacktrace()->Visit(&for_stack_trace);
    Append(for_stack_trace);
    PushArgument(for_stack_trace.value());
    instr = new (Z) ReThrowInstr(node->token_pos(), owner()->catch_try_index(),
                                 owner()->GetNextDeoptId());
  }
  AddInstruction(instr);
}

void EffectGraphVisitor::VisitThrowNode(ThrowNode* node) {
  BuildThrowNode(node);
  CloseFragment();
}

// A throw cannot be part of an expression, however, the parser may replace
// certain expression nodes with a throw. In that case generate a literal null
// so that the fragment is not closed in the middle of an expression.
void ValueGraphVisitor::VisitThrowNode(ThrowNode* node) {
  BuildThrowNode(node);
  ReturnDefinition(
      new (Z) ConstantInstr(Instance::ZoneHandle(Z, Instance::null())));
}

void EffectGraphVisitor::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  InlineBailout("EffectGraphVisitor::VisitInlinedFinallyNode (exception)");
  const intptr_t try_index = owner()->try_index();
  if (try_index >= 0) {
    // We are about to generate code for an inlined finally block. Exceptions
    // thrown in this block of code should be treated as though they are
    // thrown not from the current try block but the outer try block if any.
    intptr_t outer_try_index = node->try_index();
    owner()->set_try_index(outer_try_index);
  }

  // Note: do not restore the saved_try_context here since the inlined
  // code is not reached via an exception handler, therefore the context is
  // always properly set on entry. In other words, the inlined finally clause is
  // never the target of a long jump that would find an uninitialized current
  // context variable.

  JoinEntryInstr* finally_entry =
      new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                             owner()->GetNextDeoptId());
  EffectGraphVisitor for_finally_block(owner());
  for_finally_block.AdjustContextLevel(node->finally_block()->scope());
  node->finally_block()->Visit(&for_finally_block);

  if (try_index >= 0) {
    owner()->set_try_index(try_index);
  }

  if (for_finally_block.is_open()) {
    JoinEntryInstr* after_finally =
        new (Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index(),
                               owner()->GetNextDeoptId());
    for_finally_block.Goto(after_finally);
    for_finally_block.exit_ = after_finally;
  }

  Goto(finally_entry);
  AppendFragment(finally_entry, for_finally_block);
  exit_ = for_finally_block.exit_;
}

void EffectGraphVisitor::VisitStopNode(StopNode* node) {
  AddInstruction(new (Z) StopInstr(node->message()));
}

FlowGraph* FlowGraphBuilder::BuildGraph() {
  VMTagScope tagScope(thread(), VMTag::kCompileFlowGraphBuilderTagId,
                      FLAG_profile_vm);
  if (FLAG_support_ast_printer && FLAG_print_ast &&
      FlowGraphPrinter::ShouldPrint(parsed_function().function())) {
    // Print the function ast before IL generation.
    AstPrinter ast_printer;
    ast_printer.PrintFunctionNodes(parsed_function());
  }
  if (FLAG_support_ast_printer && FLAG_print_scopes &&
      FlowGraphPrinter::ShouldPrint(parsed_function().function())) {
    AstPrinter ast_printer;
    ast_printer.PrintFunctionScope(parsed_function());
  }
  TargetEntryInstr* normal_entry = new (Z) TargetEntryInstr(
      AllocateBlockId(), CatchClauseNode::kInvalidTryIndex, GetNextDeoptId());
  graph_entry_ =
      new (Z) GraphEntryInstr(parsed_function(), normal_entry, osr_id_);
  EffectGraphVisitor for_effect(this);
  parsed_function().node_sequence()->Visit(&for_effect);
  AppendFragment(normal_entry, for_effect);
  // Check that the graph is properly terminated.
  ASSERT(!for_effect.is_open());

  // When compiling for OSR, use a depth first search to find the OSR
  // entry and make graph entry jump to it instead of normal entry.
  // Catch entries are always considered reachable, even if they
  // become unreachable after OSR.
  if (osr_id_ != Compiler::kNoOSRDeoptId) {
    graph_entry_->RelinkToOsrEntry(Z, last_used_block_id_);
  }

  FlowGraph* graph =
      new (Z) FlowGraph(parsed_function(), graph_entry_, last_used_block_id_);
  graph->set_await_token_positions(await_token_positions_);
  return graph;
}

void FlowGraphBuilder::AppendAwaitTokenPosition(TokenPosition token_pos) {
  await_token_positions_->Add(token_pos);
}

void FlowGraphBuilder::Bailout(const char* reason) const {
  parsed_function_.Bailout("FlowGraphBuilder", reason);
}

bool FlowGraphBuilder::SimpleInstanceOfType(const AbstractType& type) {
  // Bail if the type is still uninstantiated at compile time.
  if (!type.IsInstantiated()) return false;

  // Bail if the type is a function or a Dart Function type.
  if (type.IsFunctionType() || type.IsDartFunctionType()) return false;

  ASSERT(type.HasResolvedTypeClass());
  const Class& type_class = Class::Handle(type.type_class());
  // Bail if the type has any type parameters.
  if (type_class.IsGeneric()) return false;

  // Finally a simple class for instance of checking.
  return true;
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
