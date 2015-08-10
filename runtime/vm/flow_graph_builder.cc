// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_builder.h"

#include "lib/invocation_mirror.h"
#include "vm/ast_printer.h"
#include "vm/bit_vector.h"
#include "vm/class_finalizer.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/heap.h"
#include "vm/il_printer.h"
#include "vm/intermediate_language.h"
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

DEFINE_FLAG(bool, eliminate_type_checks, true,
            "Eliminate type checks when allowed by static type analysis.");
DEFINE_FLAG(bool, print_ast, false, "Print abstract syntax tree.");
DEFINE_FLAG(bool, print_scopes, false, "Print scopes of local variables.");
DEFINE_FLAG(bool, support_debugger, true, "Emit code needed for debugging");
DEFINE_FLAG(bool, trace_type_check_elimination, false,
            "Trace type check elimination at compile time.");
DEFINE_FLAG(bool, precompile_collect_closures, false,
            "Collect all closure functions referenced from compiled code.");

DECLARE_FLAG(int, optimization_counter_threshold);
DECLARE_FLAG(bool, profile_vm);
DECLARE_FLAG(bool, warn_on_javascript_compatibility);
DECLARE_FLAG(bool, use_field_guards);

// Quick access to the locally defined zone() method.
#define Z (zone())

// TODO(srdjan): Allow compiler to add constants as they are encountered in
// the compilation.
const double kCommonDoubleConstants[] =
    {-1.0, -0.5, -0.1, 0.0, 0.1, 0.5, 1.0, 2.0, 4.0, 5.0,
     10.0, 20.0, 30.0, 64.0, 255.0, NAN,
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


#define RECOGNIZE_FACTORY(test_factory_symbol, cid, fp)                        \
  { Symbols::k##test_factory_symbol##Id, cid,                                  \
    fp, #test_factory_symbol ", " #cid },

static struct {
  intptr_t symbold_id;
  intptr_t cid;
  intptr_t finger_print;
  const char* name;
} factory_recognizer_list[] = {
  RECOGNIZED_LIST_FACTORY_LIST(RECOGNIZE_FACTORY)
  { Symbols::kIllegal, -1, -1, NULL }
};

#undef RECOGNIZE_FACTORY

intptr_t FactoryRecognizer::ResultCid(const Function& factory) {
  ASSERT(factory.IsFactory());
  const Class& function_class = Class::Handle(factory.Owner());
  const Library& lib = Library::Handle(function_class.library());
  ASSERT((lib.raw() == Library::CoreLibrary()) ||
         (lib.raw() == Library::TypedDataLibrary()));
  const String& factory_name = String::Handle(factory.name());
  for (intptr_t i = 0;
       factory_recognizer_list[i].symbold_id != Symbols::kIllegal;
       i++) {
    if (String::EqualsIgnoringPrivateKey(
            factory_name,
            Symbols::Symbol(factory_recognizer_list[i].symbold_id))) {
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


intptr_t FlowGraphBuilder::context_level() const {
  return (nesting_stack() == NULL) ? 0 : nesting_stack()->ContextLevel();
}


JoinEntryInstr* NestedStatement::BreakTargetFor(SourceLabel* label) {
  if (label != label_) return NULL;
  if (break_target_ == NULL) {
    break_target_ =
        new(owner()->zone()) JoinEntryInstr(owner()->AllocateBlockId(),
                                            owner()->try_index());
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
      : NestedStatement(owner, NULL), context_level_(context_level) { }

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

  virtual ~NestedLoop() {
    owner()->DecrementLoopDepth();
  }

  JoinEntryInstr* continue_target() const { return continue_target_; }

  virtual JoinEntryInstr* ContinueTargetFor(SourceLabel* label);

 private:
  JoinEntryInstr* continue_target_;
};


JoinEntryInstr* NestedLoop::ContinueTargetFor(SourceLabel* label) {
  if (label != this->label()) return NULL;
  if (continue_target_ == NULL) {
    continue_target_ =
        new(owner()->zone()) JoinEntryInstr(owner()->AllocateBlockId(),
                                               try_index());
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
      case_targets_[i] =
          new(owner()->zone()) JoinEntryInstr(owner()->AllocateBlockId(),
                                                 try_index());
    }
    return case_targets_[i];
  }
  return NULL;
}


FlowGraphBuilder::FlowGraphBuilder(
    const ParsedFunction& parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    InlineExitCollector* exit_collector,
    intptr_t osr_id) :
        parsed_function_(parsed_function),
        ic_data_array_(ic_data_array),
        num_copied_params_(parsed_function.num_copied_params()),
        // All parameters are copied if any parameter is.
        num_non_copied_params_((num_copied_params_ == 0)
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
        await_joins_(new(Z) ZoneGrowableArray<JoinEntryInstr*>()),
        await_levels_(new(Z) ZoneGrowableArray<intptr_t>()) { }


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
  double scale_factor = static_cast<double>(call_->CallCount())
      / static_cast<double>(caller_graph_->graph_entry()->entry_count());
  for (BlockIterator block_it = callee_graph->postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
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
}


void InlineExitCollector::AddExit(ReturnInstr* exit) {
  Data data = { NULL, exit };
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
    JoinEntryInstr* join =
        new(Z) JoinEntryInstr(join_id, try_index);

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
      GotoInstr* goto_instr = new(Z) GotoInstr(join);
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
      PhiInstr* phi = new(Z) PhiInstr(join, num_exits);
      phi->set_ssa_temp_index(caller_graph_->alloc_ssa_temp_index());
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
    TargetEntryInstr* false_block =
        new(Z) TargetEntryInstr(caller_graph_->allocate_block_id(),
                                call_block->try_index());
    false_block->InheritDeoptTargetAfter(caller_graph_, call_, NULL);
    false_block->LinkTo(call_->next());
    call_block->ReplaceAsPredecessorWith(false_block);

    ConstantInstr* true_const = caller_graph_->GetConstant(Bool::True());
    BranchInstr* branch =
        new(Z) BranchInstr(
            new(Z) StrictCompareInstr(call_block->start_pos(),
                                      Token::kEQ_STRICT,
                                      new(Z) Value(true_const),
                                      new(Z) Value(true_const),
                                      false));  // No number check.
    branch->InheritDeoptTarget(zone(), call_);
    *branch->true_successor_address() = callee_entry;
    *branch->false_successor_address() = false_block;

    call_->previous()->AppendInstruction(branch);
    call_block->set_last_instruction(branch);

    // Update dominator tree.
    call_block->AddDominatedBlock(callee_entry);
    call_block->AddDominatedBlock(false_block);

  } else {
    Definition* callee_result = JoinReturns(&callee_exit,
                                            &callee_last_instruction,
                                            call_block->try_index());
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
  return new(Z) Value(definition);
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


void EffectGraphVisitor::AddReturnExit(intptr_t token_pos, Value* value) {
  ASSERT(is_open());
  ReturnInstr* return_instr = new(Z) ReturnInstr(token_pos, value);
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
    entry_ = new(Z) GotoInstr(join);
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
        new(Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index());
    true_exit->Goto(join);
    false_exit->Goto(join);
    exit_ = join;
  }
}


void EffectGraphVisitor::TieLoop(
    intptr_t token_pos,
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
        new(Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index());
    CheckStackOverflowInstr* check =
        new(Z) CheckStackOverflowInstr(token_pos, owner()->loop_depth());
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
  PushArgumentInstr* result = new(Z) PushArgumentInstr(value);
  AddInstruction(result);
  return result;
}


Definition* EffectGraphVisitor::BuildStoreTemp(const LocalVariable& local,
                                               Value* value) {
  ASSERT(!local.is_captured());
  return new(Z) StoreLocalInstr(local, value);
}


Definition* EffectGraphVisitor::BuildStoreExprTemp(Value* value) {
  return BuildStoreTemp(*owner()->parsed_function().expression_temp_var(),
                        value);
}


Definition* EffectGraphVisitor::BuildLoadExprTemp() {
  return BuildLoadLocal(*owner()->parsed_function().expression_temp_var());
}


Definition* EffectGraphVisitor::BuildStoreLocal(const LocalVariable& local,
                                                Value* value) {
  if (local.is_captured()) {
    LocalVariable* tmp_var = EnterTempLocalScope(value);
    intptr_t delta =
        owner()->context_level() - local.owner()->context_level();
    ASSERT(delta >= 0);
    Value* context = Bind(BuildCurrentContext());
    while (delta-- > 0) {
      context = Bind(new(Z) LoadFieldInstr(
          context, Context::parent_offset(), Type::ZoneHandle(Z, Type::null()),
          Scanner::kNoSourcePos));
    }
    Value* tmp_val = Bind(new(Z) LoadLocalInstr(*tmp_var));
    StoreInstanceFieldInstr* store =
        new(Z) StoreInstanceFieldInstr(Context::variable_offset(local.index()),
                                       context,
                                       tmp_val,
                                       kEmitStoreBarrier,
                                       Scanner::kNoSourcePos);
    Do(store);
    return ExitTempLocalScope(tmp_var);
  } else {
    return new(Z) StoreLocalInstr(local, value);
  }
}


Definition* EffectGraphVisitor::BuildLoadLocal(const LocalVariable& local) {
  if (local.IsConst()) {
    return new(Z) ConstantInstr(*local.ConstValue());
  } else if (local.is_captured()) {
    intptr_t delta =
        owner()->context_level() - local.owner()->context_level();
    ASSERT(delta >= 0);
    Value* context = Bind(BuildCurrentContext());
    while (delta-- > 0) {
      context = Bind(new(Z) LoadFieldInstr(
          context, Context::parent_offset(), Type::ZoneHandle(Z, Type::null()),
          Scanner::kNoSourcePos));
    }
    return new(Z) LoadFieldInstr(context,
                              Context::variable_offset(local.index()),
                              local.type(),
                              Scanner::kNoSourcePos);
  } else {
    return new(Z) LoadLocalInstr(local);
  }
}


// Stores current context into the 'variable'
void EffectGraphVisitor::BuildSaveContext(const LocalVariable& variable) {
  Value* context = Bind(BuildCurrentContext());
  Do(BuildStoreLocal(variable, context));
}


// Loads context saved in 'context_variable' into the current context.
void EffectGraphVisitor::BuildRestoreContext(const LocalVariable& variable) {
  Value* load_saved_context = Bind(BuildLoadLocal(variable));
  Do(BuildStoreContext(load_saved_context));
}


Definition* EffectGraphVisitor::BuildStoreContext(Value* value) {
  return new(Z) StoreLocalInstr(
      *owner()->parsed_function().current_context_var(), value);
}


Definition* EffectGraphVisitor::BuildCurrentContext() {
  return new(Z) LoadLocalInstr(
      *owner()->parsed_function().current_context_var());
}


void TestGraphVisitor::ConnectBranchesTo(
    const GrowableArray<TargetEntryInstr**>& branches,
    JoinEntryInstr* join) const {
  ASSERT(!branches.is_empty());
  for (intptr_t i = 0; i < branches.length(); i++) {
    TargetEntryInstr* target =
        new(Z) TargetEntryInstr(owner()->AllocateBlockId(),
                                owner()->try_index());
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
    TargetEntryInstr* target =
        new(Z) TargetEntryInstr(owner()->AllocateBlockId(),
                                owner()->try_index());
    *(branches[0]) = target;
    return target;
  }

  JoinEntryInstr* join =
      new(Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index());
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
  if (isolate->flags().type_checks() ||
      isolate->flags().asserts()) {
    value = Bind(new(Z) AssertBooleanInstr(condition_token_pos(), value));
  }
  Value* constant_true = Bind(new(Z) ConstantInstr(Bool::True()));
  StrictCompareInstr* comp =
      new(Z) StrictCompareInstr(condition_token_pos(),
                                Token::kEQ_STRICT,
                                value,
                                constant_true,
                                false);  // No number check.
  BranchInstr* branch = new(Z) BranchInstr(comp);
  AddInstruction(branch);
  CloseFragment();

  true_successor_addresses_.Add(branch->true_successor_address());
  false_successor_addresses_.Add(branch->false_successor_address());
}


void TestGraphVisitor::MergeBranchWithComparison(ComparisonInstr* comp) {
  BranchInstr* branch;
  if (Token::IsStrictEqualityOperator(comp->kind())) {
    ASSERT(comp->IsStrictCompare());
    branch = new(Z) BranchInstr(comp);
  } else if (Token::IsEqualityOperator(comp->kind()) &&
             (comp->left()->BindsToConstantNull() ||
              comp->right()->BindsToConstantNull())) {
    branch = new(Z) BranchInstr(new(Z) StrictCompareInstr(
        comp->token_pos(),
        (comp->kind() == Token::kEQ) ? Token::kEQ_STRICT : Token::kNE_STRICT,
        comp->left(),
        comp->right(),
        false));  // No number check.
  } else {
    branch = new(Z) BranchInstr(comp);
    branch->set_is_checked(Isolate::Current()->flags().type_checks());
  }
  AddInstruction(branch);
  CloseFragment();
  true_successor_addresses_.Add(branch->true_successor_address());
  false_successor_addresses_.Add(branch->false_successor_address());
}


void TestGraphVisitor::MergeBranchWithNegate(BooleanNegateInstr* neg) {
  ASSERT(!Isolate::Current()->flags().type_checks());
  Value* constant_true = Bind(new(Z) ConstantInstr(Bool::True()));
  StrictCompareInstr* comp =
      new(Z) StrictCompareInstr(condition_token_pos(),
                             Token::kNE_STRICT,
                             neg->value(),
                             constant_true,
                             false);  // No number check.
  BranchInstr* branch = new(Z) BranchInstr(comp);
  AddInstruction(branch);
  CloseFragment();
  true_successor_addresses_.Add(branch->true_successor_address());
  false_successor_addresses_.Add(branch->false_successor_address());
}


void TestGraphVisitor::ReturnDefinition(Definition* definition) {
  ComparisonInstr* comp = definition->AsComparison();
  if (comp != NULL) {
    MergeBranchWithComparison(comp);
    return;
  }
  if (!Isolate::Current()->flags().type_checks()) {
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
  if (FLAG_support_debugger &&
      (node->token_pos() != Scanner::kNoSourcePos) && !function.is_native()) {
    AddInstruction(new(Z) DebugStepCheckInstr(node->token_pos(),
                                              RawPcDescriptors::kRuntimeCall));
  }

  NestedContextAdjustment context_adjustment(owner(), owner()->context_level());

  if (node->inlined_finally_list_length() > 0) {
    LocalVariable* temp = owner()->parsed_function().finally_return_temp_var();
    ASSERT(temp != NULL);
    Do(BuildStoreLocal(*temp, return_value));
    for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
      InlineBailout("EffectGraphVisitor::VisitReturnNode (exception)");
      EffectGraphVisitor for_effect(owner());
      node->InlinedFinallyNodeAt(i)->Visit(&for_effect);
      Append(for_effect);
      if (!is_open()) {
        return;
      }
    }
    return_value = Bind(BuildLoadLocal(*temp));
  }

  if (Isolate::Current()->flags().type_checks()) {
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
      return_value = BuildAssignableValue(node->value()->token_pos(),
                                          return_value,
                                          dst_type,
                                          Symbols::FunctionResult());
    }
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
    Do(BuildStoreExprTemp(return_value));

    LocalVariable* rcv_var =
        node->scope()->LookupVariable(Symbols::AsyncCompleter(), false);
    ASSERT(rcv_var != NULL && rcv_var->is_captured());
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);
    Value* rcv_value = Bind(BuildLoadLocal(*rcv_var));
    arguments->Add(PushArgument(rcv_value));
    Value* returned_value = Bind(BuildLoadExprTemp());
    arguments->Add(PushArgument(returned_value));
    InstanceCallInstr* call = new(Z) InstanceCallInstr(
        Scanner::kNoSourcePos,
        Symbols::CompleterComplete(),
        Token::kILLEGAL,
        arguments,
        Object::null_array(),
        1,
        owner()->ic_data_array());
    Do(call);

    // Rebind the return value for the actual return call to be null.
    return_value = BuildNullValue();
  }

  intptr_t current_context_level = owner()->context_level();
  ASSERT(current_context_level >= 0);
  if (HasContextScope()) {
    UnchainContexts(current_context_level);
  }

  AddReturnExit(node->token_pos(), return_value);

  if ((function.IsAsyncClosure() ||
      function.IsSyncGenClosure() ||
      function.IsAsyncGenClosure()) &&
      (node->return_type() == ReturnNode::kContinuationTarget)) {
    JoinEntryInstr* const join = new(Z) JoinEntryInstr(
        owner()->AllocateBlockId(), owner()->try_index());
    owner()->await_joins()->Add(join);
    exit_ = join;
  }
}


// <Expression> ::= Literal { literal: Instance }
void EffectGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  ReturnDefinition(new(Z) ConstantInstr(node->literal()));
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
    ReturnDefinition(new(Z) ConstantInstr(type));
  } else {
    const Class& instantiator_class = Class::ZoneHandle(
        Z, owner()->function().Owner());
    Value* instantiator_value = BuildInstantiatorTypeArguments(
        node->token_pos(), instantiator_class, NULL);
    ReturnDefinition(new(Z) InstantiateTypeInstr(
        node->token_pos(), type, instantiator_class, instantiator_value));
  }
}


// Returns true if the type check can be skipped, for example, if the
// destination type is dynamic or if the compile type of the value is a subtype
// of the destination type.
bool EffectGraphVisitor::CanSkipTypeCheck(intptr_t token_pos,
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

  // Any type is more specific than the dynamic type and than the Object type.
  if (dst_type.IsDynamicType() || dst_type.IsObjectType()) {
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
    FlowGraphPrinter::PrintTypeCheck(owner()->parsed_function(),
                                     token_pos,
                                     value,
                                     dst_type,
                                     dst_name,
                                     eliminated);
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
  Definition* checked_value;
  if (CanSkipTypeCheck(node->expr()->token_pos(),
                       for_value.value(),
                       node->type(),
                       node->dst_name())) {
    // Drop the value and 0 additional temporaries.
    checked_value = new(Z) DropTempsInstr(0, for_value.value());
  } else {
    checked_value = BuildAssertAssignable(node->expr()->token_pos(),
                                          for_value.value(),
                                          node->type(),
                                          node->dst_name());
  }
  ReturnDefinition(checked_value);
}


void ValueGraphVisitor::VisitAssignableNode(AssignableNode* node) {
  ValueGraphVisitor for_value(owner());
  node->expr()->Visit(&for_value);
  Append(for_value);
  ReturnValue(BuildAssignableValue(node->expr()->token_pos(),
                                   for_value.value(),
                                   node->type(),
                                   node->dst_name()));
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
    if (isolate->flags().type_checks() ||
        isolate->flags().asserts()) {
      ValueGraphVisitor for_right(owner());
      node->right()->Visit(&for_right);
      Value* right_value = for_right.value();
      for_right.Do(new(Z) AssertBooleanInstr(node->right()->token_pos(),
                                             right_value));
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
  } else if (node->kind() == Token::kIFNULL) {
    // left ?? right. This operation cannot be overloaded.
    // temp = left; temp === null ? right : temp
    ValueGraphVisitor for_left_value(owner());
    node->left()->Visit(&for_left_value);
    Append(for_left_value);
    Do(BuildStoreExprTemp(for_left_value.value()));

    LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
    LoadLocalNode* load_temp =
        new(Z) LoadLocalNode(Scanner::kNoSourcePos, temp_var);
    LiteralNode* null_constant =
        new(Z) LiteralNode(Scanner::kNoSourcePos, Object::null_instance());
    ComparisonNode* check_is_null =
        new(Z) ComparisonNode(Scanner::kNoSourcePos,
                              Token::kEQ_STRICT,
                              load_temp,
                              null_constant);
    TestGraphVisitor for_test(owner(), Scanner::kNoSourcePos);
    check_is_null->Visit(&for_test);

    ValueGraphVisitor for_right_value(owner());
    node->right()->Visit(&for_right_value);
    for_right_value.Do(BuildStoreExprTemp(for_right_value.value()));

    ValueGraphVisitor for_temp(owner());
    // Nothing to do, left value is already loaded into temp.

    Join(for_test, for_right_value, for_temp);
    return;
  }
  ValueGraphVisitor for_left_value(owner());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  PushArgumentInstr* push_left = PushArgument(for_left_value.value());

  ValueGraphVisitor for_right_value(owner());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  PushArgumentInstr* push_right = PushArgument(for_right_value.value());

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  arguments->Add(push_left);
  arguments->Add(push_right);
  const String& name = String::ZoneHandle(Z, Symbols::New(node->TokenName()));
  const intptr_t kNumArgsChecked = 2;
  InstanceCallInstr* call = new(Z) InstanceCallInstr(node->token_pos(),
                                                     name,
                                                     node->kind(),
                                                     arguments,
                                                     Object::null_array(),
                                                     kNumArgsChecked,
                                                     owner()->ic_data_array());
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
    if (isolate->flags().type_checks() ||
        isolate->flags().asserts()) {
      right_value =
          for_right.Bind(new(Z) AssertBooleanInstr(node->right()->token_pos(),
                                                   right_value));
    }
    Value* constant_true = for_right.Bind(new(Z) ConstantInstr(Bool::True()));
    Value* compare =
        for_right.Bind(new(Z) StrictCompareInstr(node->token_pos(),
                                                 Token::kEQ_STRICT,
                                                 right_value,
                                                 constant_true,
                                                 false));  // No number check.
    for_right.Do(BuildStoreExprTemp(compare));

    if (node->kind() == Token::kAND) {
      ValueGraphVisitor for_false(owner());
      Value* constant_false =
          for_false.Bind(new(Z) ConstantInstr(Bool::False()));
      for_false.Do(BuildStoreExprTemp(constant_false));
      Join(for_test, for_right, for_false);
    } else {
      ASSERT(node->kind() == Token::kOR);
      ValueGraphVisitor for_true(owner());
      Value* constant_true = for_true.Bind(new(Z) ConstantInstr(Bool::True()));
      for_true.Do(BuildStoreExprTemp(constant_true));
      Join(for_test, for_true, for_right);
    }
    ReturnDefinition(BuildLoadExprTemp());
    return;
  } else if (node->kind() == Token::kIFNULL) {
    // left ?? right. This operation cannot be overloaded.
    // temp = left; temp === null ? right : temp
    ValueGraphVisitor for_left_value(owner());
    node->left()->Visit(&for_left_value);
    Append(for_left_value);
    Do(BuildStoreExprTemp(for_left_value.value()));

    LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
    LoadLocalNode* load_temp =
        new(Z) LoadLocalNode(Scanner::kNoSourcePos, temp_var);
    LiteralNode* null_constant =
        new(Z) LiteralNode(Scanner::kNoSourcePos, Object::null_instance());
    ComparisonNode* check_is_null =
        new(Z) ComparisonNode(Scanner::kNoSourcePos,
                              Token::kEQ_STRICT,
                              load_temp,
                              null_constant);
    TestGraphVisitor for_test(owner(), Scanner::kNoSourcePos);
    check_is_null->Visit(&for_test);

    ValueGraphVisitor for_right_value(owner());
    node->right()->Visit(&for_right_value);
    for_right_value.Do(BuildStoreExprTemp(for_right_value.value()));

    ValueGraphVisitor for_temp(owner());
    // Nothing to do, left value is already loaded into temp.

    Join(for_test, for_right_value, for_temp);
    ReturnDefinition(BuildLoadExprTemp());
    return;
  }

  EffectGraphVisitor::VisitBinaryOpNode(node);
}


static const String& BinaryOpAndMaskName(BinaryOpNode* node) {
  if (node->kind() == Token::kSHL) {
    return Library::PrivateCoreLibName(Symbols::_leftShiftWithMask32());
  }
  UNIMPLEMENTED();
  return String::ZoneHandle(Thread::Current()->zone(), String::null());
}


// <Expression> :: BinaryOp { kind:  Token::Kind
//                            left:  <Expression>
//                            right: <Expression>
//                            mask32: constant }
void EffectGraphVisitor::VisitBinaryOpWithMask32Node(
    BinaryOpWithMask32Node* node) {
  ASSERT((node->kind() != Token::kAND) && (node->kind() != Token::kOR));
  ValueGraphVisitor for_left_value(owner());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  PushArgumentInstr* push_left = PushArgument(for_left_value.value());

  ValueGraphVisitor for_right_value(owner());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  PushArgumentInstr* push_right = PushArgument(for_right_value.value());

  Value* mask_value = Bind(new(Z) ConstantInstr(
      Integer::ZoneHandle(Z, Integer::New(node->mask32(), Heap::kOld))));
  PushArgumentInstr* push_mask = PushArgument(mask_value);

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(3);
  arguments->Add(push_left);
  arguments->Add(push_right);
  // Call to special method 'BinaryOpAndMaskName(node)'.
  arguments->Add(push_mask);
  const intptr_t kNumArgsChecked = 2;
  InstanceCallInstr* call = new(Z) InstanceCallInstr(node->token_pos(),
                                                     BinaryOpAndMaskName(node),
                                                     Token::kILLEGAL,
                                                     arguments,
                                                     Object::null_array(),
                                                     kNumArgsChecked,
                                                     owner()->ic_data_array());
  ReturnDefinition(call);
}


void EffectGraphVisitor::BuildTypecheckPushArguments(
    intptr_t token_pos,
    PushArgumentInstr** push_instantiator_result,
    PushArgumentInstr** push_instantiator_type_arguments_result) {
  const Class& instantiator_class = Class::Handle(
      Z, owner()->function().Owner());
  // Since called only when type tested against is not instantiated.
  ASSERT(instantiator_class.NumTypeParameters() > 0);
  Value* instantiator_type_arguments = NULL;
  Value* instantiator = BuildInstantiator(instantiator_class);
  if (instantiator == NULL) {
    // No instantiator when inside factory.
    *push_instantiator_result = PushArgument(BuildNullValue());
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_pos, instantiator_class, NULL);
  } else {
    instantiator = Bind(BuildStoreExprTemp(instantiator));
    *push_instantiator_result = PushArgument(instantiator);
    Value* loaded = Bind(BuildLoadExprTemp());
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_pos, instantiator_class, loaded);
  }
  *push_instantiator_type_arguments_result =
      PushArgument(instantiator_type_arguments);
}



void EffectGraphVisitor::BuildTypecheckArguments(
    intptr_t token_pos,
    Value** instantiator_result,
    Value** instantiator_type_arguments_result) {
  Value* instantiator = NULL;
  Value* instantiator_type_arguments = NULL;
  const Class& instantiator_class = Class::Handle(
      Z, owner()->function().Owner());
  // Since called only when type tested against is not instantiated.
  ASSERT(instantiator_class.NumTypeParameters() > 0);
  instantiator = BuildInstantiator(instantiator_class);
  if (instantiator == NULL) {
    // No instantiator when inside factory.
    instantiator = BuildNullValue();
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_pos, instantiator_class, NULL);
  } else {
    // Preserve instantiator.
    instantiator = Bind(BuildStoreExprTemp(instantiator));
    Value* loaded = Bind(BuildLoadExprTemp());
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_pos, instantiator_class, loaded);
  }
  *instantiator_result = instantiator;
  *instantiator_type_arguments_result = instantiator_type_arguments;
}


Value* EffectGraphVisitor::BuildNullValue() {
  return Bind(new(Z) ConstantInstr(Object::ZoneHandle(Z, Object::null())));
}


// Used for testing incoming arguments.
AssertAssignableInstr* EffectGraphVisitor::BuildAssertAssignable(
    intptr_t token_pos,
    Value* value,
    const AbstractType& dst_type,
    const String& dst_name) {
  // Build the type check computation.
  Value* instantiator = NULL;
  Value* instantiator_type_arguments = NULL;
  if (dst_type.IsInstantiated()) {
    instantiator = BuildNullValue();
    instantiator_type_arguments = BuildNullValue();
  } else {
    BuildTypecheckArguments(token_pos,
                            &instantiator,
                            &instantiator_type_arguments);
  }

  const intptr_t deopt_id = Isolate::Current()->GetNextDeoptId();
  return new(Z) AssertAssignableInstr(token_pos,
                                      value,
                                      instantiator,
                                      instantiator_type_arguments,
                                      dst_type,
                                      dst_name,
                                      deopt_id);
}


void EffectGraphVisitor::BuildSyncYieldJump(LocalVariable* old_context,
                                            LocalVariable* iterator_param,
                                            const intptr_t old_ctx_level,
                                            JoinEntryInstr* target) {
  // Building a jump consists of the following actions:
  // * Load the generator body's iterator parameter (:iterator)
  //   from the current context into a temporary.
  // * Restore the old context from :await_cxt_var.
  // * Copy the iterator saved above into the restored context.
  // * Append a Goto to the target's join.
  ASSERT((iterator_param != NULL) && iterator_param->is_captured());
  ASSERT((old_context != NULL) && old_context->is_captured());
  // Before restoring the context we need to temporarily save the
  // iterator parameter.
  LocalVariable* temp_iterator_var =
      EnterTempLocalScope(Bind(BuildLoadLocal(*iterator_param)));

  // Restore the saved continuation context, i.e. the context that was
  // saved into :await_ctx_var before the closure suspended.
  BuildRestoreContext(*old_context);

  // Store the continuation result and continuation error values into
  // the restored context.

  // FlowGraphBuilder is at top context level, but the continuation
  // target has possibly been recorded in a nested context (old_ctx_level).
  // We need to unroll manually here.
  intptr_t delta =
      old_ctx_level - iterator_param->owner()->context_level();
  ASSERT(delta >= 0);
  Value* context = Bind(BuildCurrentContext());
  while (delta-- > 0) {
    context = Bind(new(Z) LoadFieldInstr(
        context, Context::parent_offset(), Type::ZoneHandle(Z, Type::null()),
        Scanner::kNoSourcePos));
  }
  LocalVariable* temp_context_var = EnterTempLocalScope(context);

  Value* context_val = Bind(new(Z) LoadLocalInstr(*temp_context_var));
  Value* store_val = Bind(new(Z) LoadLocalInstr(*temp_iterator_var));
  StoreInstanceFieldInstr* store = new(Z) StoreInstanceFieldInstr(
      Context::variable_offset(iterator_param->index()),
      context_val,
      store_val,
      kEmitStoreBarrier,
      Scanner::kNoSourcePos);
  Do(store);

  Do(ExitTempLocalScope(temp_context_var));
  Do(ExitTempLocalScope(temp_iterator_var));

  // Goto saved join.
  Goto(target);
}


void EffectGraphVisitor::BuildAsyncJump(LocalVariable* old_context,
                                        LocalVariable* continuation_result,
                                        LocalVariable* continuation_error,
                                        LocalVariable* continuation_stack_trace,
                                        const intptr_t old_ctx_level,
                                        JoinEntryInstr* target) {
  // Building a jump consists of the following actions:
  // * Load the current continuation result parameter (:async_result)
  //   and continuation error parameter (:async_error_param) from
  //   the current context into temporaries.
  // * Restore the old context from :await_cxt_var.
  // * Copy the result and error parameters saved above into the restored
  //   context.
  // * Append a Goto to the target's join.
  ASSERT((continuation_result != NULL) && continuation_result->is_captured());
  ASSERT((continuation_error != NULL) && continuation_error->is_captured());
  ASSERT((old_context != NULL) && old_context->is_captured());
  // Before restoring the continuation context we need to temporary save the
  // result and error parameter.
  LocalVariable* temp_result_var =
      EnterTempLocalScope(Bind(BuildLoadLocal(*continuation_result)));
  LocalVariable* temp_error_var =
      EnterTempLocalScope(Bind(BuildLoadLocal(*continuation_error)));
  LocalVariable* temp_stack_trace_var =
      EnterTempLocalScope(Bind(BuildLoadLocal(*continuation_stack_trace)));

  // Restore the saved continuation context, i.e. the context that was
  // saved into :await_ctx_var before the closure suspended.
  BuildRestoreContext(*old_context);

  // Store the continuation result and continuation error values into
  // the restored context.

  // FlowGraphBuilder is at top context level, but the await target has possibly
  // been recorded in a nested context (old_ctx_level). We need to unroll
  // manually here.
  intptr_t delta =
      old_ctx_level - continuation_result->owner()->context_level();
  ASSERT(delta >= 0);
  Value* context = Bind(BuildCurrentContext());
  while (delta-- > 0) {
    context = Bind(new(Z) LoadFieldInstr(
        context, Context::parent_offset(), Type::ZoneHandle(Z, Type::null()),
        Scanner::kNoSourcePos));
  }
  LocalVariable* temp_context_var = EnterTempLocalScope(context);

  Value* context_val = Bind(new(Z) LoadLocalInstr(*temp_context_var));
  Value* store_val = Bind(new(Z) LoadLocalInstr(*temp_result_var));
  StoreInstanceFieldInstr* store = new(Z) StoreInstanceFieldInstr(
      Context::variable_offset(continuation_result->index()),
      context_val,
      store_val,
      kEmitStoreBarrier,
      Scanner::kNoSourcePos);
  Do(store);
  context_val = Bind(new(Z) LoadLocalInstr(*temp_context_var));
  store_val = Bind(new(Z) LoadLocalInstr(*temp_error_var));
  StoreInstanceFieldInstr* store2 = new(Z) StoreInstanceFieldInstr(
      Context::variable_offset(continuation_error->index()),
      context_val,
      store_val,
      kEmitStoreBarrier,
      Scanner::kNoSourcePos);
  Do(store2);

  context_val = Bind(new(Z) LoadLocalInstr(*temp_context_var));
  store_val = Bind(new(Z) LoadLocalInstr(*temp_stack_trace_var));
  StoreInstanceFieldInstr* store3 = new(Z) StoreInstanceFieldInstr(
      Context::variable_offset(continuation_stack_trace->index()),
      context_val,
      store_val,
      kEmitStoreBarrier,
      Scanner::kNoSourcePos);
  Do(store3);

  Do(ExitTempLocalScope(temp_context_var));
  Do(ExitTempLocalScope(temp_stack_trace_var));
  Do(ExitTempLocalScope(temp_error_var));
  Do(ExitTempLocalScope(temp_result_var));

  // Goto saved join.
  Goto(target);
}


// Used for type casts and to test assignments.
Value* EffectGraphVisitor::BuildAssignableValue(intptr_t token_pos,
                                                Value* value,
                                                const AbstractType& dst_type,
                                                const String& dst_name) {
  if (CanSkipTypeCheck(token_pos, value, dst_type, dst_name)) {
    return value;
  }
  return Bind(BuildAssertAssignable(token_pos, value, dst_type, dst_name));
}


bool FlowGraphBuilder::WarnOnJSIntegralNumTypeTest(
    AstNode* node, const AbstractType& type) const {
  if (!(node->IsLiteralNode() && (type.IsIntType() || type.IsDoubleType()))) {
    return false;
  }
  const Instance& instance = node->AsLiteralNode()->literal();
  if (type.IsIntType()) {
    if (instance.IsDouble()) {
      const Double& double_instance = Double::Cast(instance);
      double value = double_instance.value();
      if (floor(value) == value) {
        return true;
      }
    }
  } else {
    ASSERT(type.IsDoubleType());
    if (instance.IsInteger()) {
      return true;
    }
  }
  return false;
}


void EffectGraphVisitor::BuildTypeTest(ComparisonNode* node) {
  ASSERT(Token::IsTypeTestOperator(node->kind()));
  const AbstractType& type = node->right()->AsTypeNode()->type();
  ASSERT(type.IsFinalized() && !type.IsMalformedOrMalbounded());
  const bool negate_result = (node->kind() == Token::kISNOT);
  // All objects are instances of type T if Object type is a subtype of type T.
  const Type& object_type = Type::Handle(Z, Type::ObjectType());
  if (type.IsInstantiated() && object_type.IsSubtypeOf(type, NULL)) {
    // Must evaluate left side.
    EffectGraphVisitor for_left_value(owner());
    node->left()->Visit(&for_left_value);
    Append(for_left_value);
    ReturnDefinition(new(Z) ConstantInstr(Bool::Get(!negate_result)));
    return;
  }
  ValueGraphVisitor for_left_value(owner());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);

  if (!FLAG_warn_on_javascript_compatibility) {
    if (type.IsNumberType() || type.IsIntType() || type.IsDoubleType() ||
        type.IsSmiType() || type.IsStringType()) {
      String& method_name = String::ZoneHandle(Z);
      if (type.IsNumberType()) {
        method_name = Symbols::_instanceOfNum().raw();
      } else if (type.IsIntType()) {
        method_name = Symbols::_instanceOfInt().raw();
      } else if (type.IsDoubleType()) {
        method_name = Symbols::_instanceOfDouble().raw();
      } else if (type.IsSmiType()) {
        method_name = Symbols::_instanceOfSmi().raw();
      } else if (type.IsStringType()) {
        method_name = Symbols::_instanceOfString().raw();
      }
      ASSERT(!method_name.IsNull());
      PushArgumentInstr* push_left = PushArgument(for_left_value.value());
      ZoneGrowableArray<PushArgumentInstr*>* arguments =
          new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);
      arguments->Add(push_left);
      const Bool& negate = Bool::Get(node->kind() == Token::kISNOT);
      Value* negate_arg = Bind(new(Z) ConstantInstr(negate));
      arguments->Add(PushArgument(negate_arg));
      const intptr_t kNumArgsChecked = 1;
      InstanceCallInstr* call = new(Z) InstanceCallInstr(
          node->token_pos(),
          Library::PrivateCoreLibName(method_name),
          node->kind(),
          arguments,
          Object::null_array(),  // No argument names.
          kNumArgsChecked,
          owner()->ic_data_array());
      ReturnDefinition(call);
      return;
    }
  }

  PushArgumentInstr* push_left = PushArgument(for_left_value.value());
  PushArgumentInstr* push_instantiator = NULL;
  PushArgumentInstr* push_type_args = NULL;
  if (type.IsInstantiated()) {
    push_instantiator = PushArgument(BuildNullValue());
    push_type_args = PushArgument(BuildNullValue());
  } else {
    BuildTypecheckPushArguments(node->token_pos(),
                                &push_instantiator,
                                &push_type_args);
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(5);
  arguments->Add(push_left);
  arguments->Add(push_instantiator);
  arguments->Add(push_type_args);
  ASSERT(!node->right()->AsTypeNode()->type().IsNull());
  Value* type_const = Bind(new(Z) ConstantInstr(type));
  arguments->Add(PushArgument(type_const));
  const Bool& negate = Bool::Get(node->kind() == Token::kISNOT);
  Value* negate_arg = Bind(new(Z) ConstantInstr(negate));
  arguments->Add(PushArgument(negate_arg));
  const intptr_t kNumArgsChecked = 1;
  InstanceCallInstr* call = new(Z) InstanceCallInstr(
      node->token_pos(),
      Library::PrivateCoreLibName(Symbols::_instanceOf()),
      node->kind(),
      arguments,
      Object::null_array(),  // No argument names.
      kNumArgsChecked,
      owner()->ic_data_array());
  ReturnDefinition(call);
}


void EffectGraphVisitor::BuildTypeCast(ComparisonNode* node) {
  ASSERT(Token::IsTypeCastOperator(node->kind()));
  ASSERT(!node->right()->AsTypeNode()->type().IsNull());
  const AbstractType& type = node->right()->AsTypeNode()->type();
  ASSERT(type.IsFinalized() && !type.IsMalformed() && !type.IsMalbounded());
  ValueGraphVisitor for_value(owner());
  node->left()->Visit(&for_value);
  Append(for_value);
  const String& dst_name = String::ZoneHandle(
      Z, Symbols::New(Exceptions::kCastErrorDstName));
  if (CanSkipTypeCheck(node->token_pos(),
                       for_value.value(),
                       type,
                       dst_name)) {
    // Check for javascript compatibility.
    // Do not skip type check if javascript compatibility warning is required.
    if (!FLAG_warn_on_javascript_compatibility ||
        !owner()->WarnOnJSIntegralNumTypeTest(node->left(), type)) {
      ReturnValue(for_value.value());
      return;
    }
  }
  PushArgumentInstr* push_left = PushArgument(for_value.value());
  PushArgumentInstr* push_instantiator = NULL;
  PushArgumentInstr* push_type_args = NULL;
  if (type.IsInstantiated()) {
    push_instantiator = PushArgument(BuildNullValue());
    push_type_args = PushArgument(BuildNullValue());
  } else {
    BuildTypecheckPushArguments(node->token_pos(),
                                &push_instantiator,
                                &push_type_args);
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(4);
  arguments->Add(push_left);
  arguments->Add(push_instantiator);
  arguments->Add(push_type_args);
  Value* type_arg = Bind(new(Z) ConstantInstr(type));
  arguments->Add(PushArgument(type_arg));
  const intptr_t kNumArgsChecked = 1;
  InstanceCallInstr* call = new(Z) InstanceCallInstr(
      node->token_pos(),
      Library::PrivateCoreLibName(Symbols::_as()),
      node->kind(),
      arguments,
      Object::null_array(),  // No argument names.
      kNumArgsChecked,
      owner()->ic_data_array());
  ReturnDefinition(call);
}


StrictCompareInstr* EffectGraphVisitor::BuildStrictCompare(AstNode* left,
                                                           AstNode* right,
                                                           Token::Kind kind,
                                                           intptr_t token_pos) {
  ValueGraphVisitor for_left_value(owner());
  left->Visit(&for_left_value);
  Append(for_left_value);
  ValueGraphVisitor for_right_value(owner());
  right->Visit(&for_right_value);
  Append(for_right_value);
  StrictCompareInstr* comp = new(Z) StrictCompareInstr(token_pos,
                                                    kind,
                                                    for_left_value.value(),
                                                    for_right_value.value(),
                                                    true);  // Number check.
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
      StrictCompareInstr* compare =
          BuildStrictCompare(node->left(), node->right(),
                             kind, node->token_pos());
      ReturnDefinition(compare);
      return;
    }

    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);

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

    const intptr_t kNumArgsChecked = 2;
    Definition* result = new(Z) InstanceCallInstr(
        node->token_pos(),
        Symbols::EqualOperator(),
        Token::kEQ,  // Result is negated later for kNE.
        arguments,
        Object::null_array(),
        kNumArgsChecked,
        owner()->ic_data_array());
    if (node->kind() == Token::kNE) {
      Isolate* isolate = Isolate::Current();
      if (isolate->flags().type_checks() ||
          isolate->flags().asserts()) {
        Value* value = Bind(result);
        result = new(Z) AssertBooleanInstr(node->token_pos(), value);
      }
      Value* value = Bind(result);
      result = new(Z) BooleanNegateInstr(value);
    }
    ReturnDefinition(result);
    return;
  }

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);

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
  InstanceCallInstr* comp = new(Z) InstanceCallInstr(
      node->token_pos(),
      String::ZoneHandle(Z, Symbols::New(node->TokenName())),
      node->kind(),
      arguments,
      Object::null_array(),
      2,
      owner()->ic_data_array());
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
    if (isolate->flags().type_checks() ||
        isolate->flags().asserts()) {
      value =
          Bind(new(Z) AssertBooleanInstr(node->operand()->token_pos(), value));
    }
    BooleanNegateInstr* negate = new(Z) BooleanNegateInstr(value);
    ReturnDefinition(negate);
    return;
  }

  ValueGraphVisitor for_value(owner());
  node->operand()->Visit(&for_value);
  Append(for_value);
  PushArgumentInstr* push_value = PushArgument(for_value.value());
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(1);
  arguments->Add(push_value);
  InstanceCallInstr* call = new(Z) InstanceCallInstr(
      node->token_pos(),
      String::ZoneHandle(Z, Symbols::New(node->TokenName())),
      node->kind(),
      arguments,
      Object::null_array(),
      1,
      owner()->ic_data_array());
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
  for_true.Do(BuildStoreExprTemp(for_true.value()));

  ValueGraphVisitor for_false(owner());
  node->false_expr()->Visit(&for_false);
  ASSERT(for_false.is_open());
  for_false.Do(BuildStoreExprTemp(for_false.value()));

  Join(for_test, for_true, for_false);
  ReturnDefinition(BuildLoadExprTemp());
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
    statement_start = new(Z) JoinEntryInstr(owner()->AllocateBlockId(),
                                            owner()->try_index());
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
        JoinEntryInstr* join = new(Z) JoinEntryInstr(owner()->AllocateBlockId(),
                                                     owner()->try_index());
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
      new(Z) JoinEntryInstr(owner()->AllocateBlockId(),
                            owner()->try_index());
  Goto(body_entry_join);
  Instruction* body_exit = AppendFragment(body_entry_join, for_body);

  JoinEntryInstr* join = nested_loop.continue_target();
  if ((body_exit != NULL) || (join != NULL)) {
    if (join == NULL) {
      join = new(Z) JoinEntryInstr(owner()->AllocateBlockId(),
                                   owner()->try_index());
    }
    CheckStackOverflowInstr* check = new(Z) CheckStackOverflowInstr(
        node->token_pos(), owner()->loop_depth());
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
        new(Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index());
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
    AddInstruction(
        new(Z) CheckStackOverflowInstr(node->token_pos(),
                                       owner()->loop_depth()));
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
  ASSERT(node->scope() != NULL);
  LocalVariable* jump_var = node->scope()->LookupVariable(
      Symbols::AwaitJumpVar(), false);
  LocalVariable* ctx_var = node->scope()->LookupVariable(
      Symbols::AwaitContextVar(), false);
  ASSERT((jump_var != NULL) && jump_var->is_captured());
  ASSERT((ctx_var != NULL) && ctx_var->is_captured());
  const intptr_t jump_count = owner()->next_await_counter();
  ASSERT(jump_count >= 0);
  // Sanity check that we always add a JoinEntryInstr before adding a new
  // state.
  ASSERT(jump_count == owner()->await_joins()->length());
  // Store the counter in :await_jump_var.
  Value* jump_val = Bind(new(Z) ConstantInstr(
      Smi::ZoneHandle(Z, Smi::New(jump_count))));
  Do(BuildStoreLocal(*jump_var, jump_val));
  // Save the current context for resuming.
  BuildSaveContext(*ctx_var);
  owner()->await_levels()->Add(owner()->context_level());
}


intptr_t EffectGraphVisitor::GetCurrentTempLocalIndex() const {
  return kFirstLocalSlotFromFp
      - owner()->num_stack_locals()
      - owner()->num_copied_params()
      - owner()->args_pushed()
      - owner()->temp_count() + 1;
}


LocalVariable* EffectGraphVisitor::EnterTempLocalScope(Value* value) {
  Do(new(Z) PushTempInstr(value));
  owner()->AllocateTemp();

  ASSERT(value->definition()->temp_index() == (owner()->temp_count() - 1));
  intptr_t index = GetCurrentTempLocalIndex();
  char name[64];
  OS::SNPrint(name, 64, ":tmp_local%" Pd, index);
  LocalVariable*  var =
      new(Z) LocalVariable(0,
                           String::ZoneHandle(Z, Symbols::New(name)),
                           *value->Type()->ToAbstractType());
  var->set_index(index);
  return var;
}


Definition* EffectGraphVisitor::ExitTempLocalScope(LocalVariable* var) {
  Value* tmp = Bind(new(Z) LoadLocalInstr(*var));
  owner()->DeallocateTemps(1);
  ASSERT(GetCurrentTempLocalIndex() == var->index());
  return new(Z) DropTempsInstr(1, tmp);
}


void EffectGraphVisitor::BuildLetTempExpressions(LetNode* node) {
  intptr_t num_temps = node->num_temps();
  for (intptr_t i = 0; i < num_temps; ++i) {
    ValueGraphVisitor for_value(owner());
    node->InitializerAt(i)->Visit(&for_value);
    Append(for_value);
    Value* temp_val = for_value.value();
    ASSERT(!node->TempAt(i)->HasIndex() ||
           (node->TempAt(i)->index() == GetCurrentTempLocalIndex()));
    node->TempAt(i)->set_index(GetCurrentTempLocalIndex());
    Do(new(Z) PushTempInstr(temp_val));
    owner()->AllocateTemp();
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
    Do(new(Z) DropTempsInstr(num_temps, NULL));
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
    ReturnDefinition(new(Z) DropTempsInstr(num_temps, result_value));
  } else {
    ReturnValue(result_value);
  }
}


void EffectGraphVisitor::VisitArrayNode(ArrayNode* node) {
  const TypeArguments& type_args =
      TypeArguments::ZoneHandle(Z, node->type().arguments());
  Value* element_type = BuildInstantiatedTypeArguments(node->token_pos(),
                                                       type_args);
  Value* num_elements =
      Bind(new(Z) ConstantInstr(Smi::ZoneHandle(Z, Smi::New(node->length()))));
  CreateArrayInstr* create = new(Z) CreateArrayInstr(node->token_pos(),
                                                     element_type,
                                                     num_elements);
  Value* array_val = Bind(create);

  { LocalVariable* tmp_var = EnterTempLocalScope(array_val);
    const intptr_t class_id = kArrayCid;
    const intptr_t deopt_id = Isolate::kNoDeoptId;
    for (int i = 0; i < node->length(); ++i) {
      Value* array = Bind(new(Z) LoadLocalInstr(*tmp_var));
      Value* index =
          Bind(new(Z) ConstantInstr(Smi::ZoneHandle(Z, Smi::New(i))));
      ValueGraphVisitor for_value(owner());
      node->ElementAt(i)->Visit(&for_value);
      Append(for_value);
      // No store barrier needed for constants.
      const StoreBarrierType emit_store_barrier =
          for_value.value()->BindsToConstant()
              ? kNoStoreBarrier
              : kEmitStoreBarrier;
      const intptr_t index_scale = Instance::ElementSizeFor(class_id);
      StoreIndexedInstr* store = new(Z) StoreIndexedInstr(
          array, index, for_value.value(), emit_store_barrier,
          index_scale, class_id, deopt_id, node->token_pos());
      Do(store);
    }
    ReturnDefinition(ExitTempLocalScope(tmp_var));
  }
}


void EffectGraphVisitor::VisitStringInterpolateNode(
    StringInterpolateNode* node) {
  ValueGraphVisitor for_argument(owner());
  ArrayNode* arguments = node->value();
  if (arguments->length() == 1) {
    ZoneGrowableArray<PushArgumentInstr*>* values =
        new(Z) ZoneGrowableArray<PushArgumentInstr*>(1);
    arguments->ElementAt(0)->Visit(&for_argument);
    Append(for_argument);
    PushArgumentInstr* push_arg = PushArgument(for_argument.value());
    values->Add(push_arg);
    const int kNumberOfArguments = 1;
    const Array& kNoArgumentNames = Object::null_array();
    const Class& cls =
        Class::Handle(Library::LookupCoreClass(Symbols::StringBase()));
    ASSERT(!cls.IsNull());
    const Function& function = Function::ZoneHandle(
        Z,
        Resolver::ResolveStatic(
            cls,
            Library::PrivateCoreLibName(Symbols::InterpolateSingle()),
            kNumberOfArguments,
            kNoArgumentNames));
    StaticCallInstr* call =
        new(Z) StaticCallInstr(node->token_pos(),
                               function,
                               kNoArgumentNames,
                               values,
                               owner()->ic_data_array());
    ReturnDefinition(call);
    return;
  }
  arguments->Visit(&for_argument);
  Append(for_argument);
  StringInterpolateInstr* instr =
      new(Z) StringInterpolateInstr(for_argument.value(), node->token_pos());
  ReturnDefinition(instr);
}


// TODO(rmacnak): De-dup closures in inlined-finally and track down other
// stragglers to use Class::closures instead.
static void CollectClosureFunction(const Function& function) {
  if (function.HasCode()) return;

  Isolate* isolate = Isolate::Current();
  if (isolate->collected_closures() == GrowableObjectArray::null()) {
    isolate->set_collected_closures(
        GrowableObjectArray::Handle(GrowableObjectArray::New()));
  }
  const GrowableObjectArray& functions =
      GrowableObjectArray::Handle(isolate, isolate->collected_closures());
  functions.Add(function);
}


void EffectGraphVisitor::VisitClosureNode(ClosureNode* node) {
  const Function& function = node->function();
  if (FLAG_precompile_collect_closures) {
    CollectClosureFunction(function);
  }

  if (function.IsImplicitStaticClosureFunction()) {
    const Instance& closure =
        Instance::ZoneHandle(Z, function.ImplicitStaticClosure());
    ReturnDefinition(new(Z) ConstantInstr(closure));
    return;
  }
  const bool is_implicit = function.IsImplicitInstanceClosureFunction();
  ASSERT(is_implicit || function.IsNonImplicitClosureFunction());
  // The context scope may have already been set by the non-optimizing
  // compiler.  If it was not, set it here.
  if (function.context_scope() == ContextScope::null()) {
    ASSERT(!is_implicit);
    const ContextScope& context_scope = ContextScope::ZoneHandle(
        Z, node->scope()->PreserveOuterScope(owner()->context_level()));
    ASSERT(!function.HasCode());
    ASSERT(function.context_scope() == ContextScope::null());
    function.set_context_scope(context_scope);
    const Class& cls = Class::Handle(Z, owner()->function().Owner());
    // The closure is now properly setup, add it to the lookup table.
    // It is possible that the compiler creates more than one function
    // object for the same closure, e.g. when inlining nodes from
    // finally clauses. If we already have a function object for the
    // same closure, do not add a second one. We compare the origin
    // class, token position, and parent function to detect duplicates.
    // Note that we can have two different closure object for the same
    // source text representation of the closure: one with a non-closurized
    // parent, and one with a closurized parent function.

    const Function& found_func = Function::Handle(
        Z, cls.LookupClosureFunction(function.token_pos()));

    if (found_func.IsNull() ||
        (found_func.token_pos() != function.token_pos()) ||
        (found_func.script() != function.script()) ||
        (found_func.parent_function() != function.parent_function())) {
      cls.AddClosureFunction(function);
    }
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(1);
  ASSERT(function.context_scope() != ContextScope::null());

  // The function type of a closure may have type arguments. In that case,
  // pass the type arguments of the instantiator.
  const Class& cls = Class::ZoneHandle(Z, function.signature_class());
  ASSERT(!cls.IsNull());
  const bool requires_type_arguments = cls.NumTypeArguments() > 0;
  Value* type_arguments = NULL;
  if (requires_type_arguments) {
    ASSERT(cls.type_arguments_field_offset() ==
           Closure::type_arguments_offset());
    ASSERT(cls.instance_size() == Closure::InstanceSize());
    const Class& instantiator_class = Class::Handle(
        Z, owner()->function().Owner());
    type_arguments = BuildInstantiatorTypeArguments(node->token_pos(),
                                                    instantiator_class,
                                                    NULL);
    arguments->Add(PushArgument(type_arguments));
  }
  AllocateObjectInstr* alloc = new(Z) AllocateObjectInstr(node->token_pos(),
                                                          cls,
                                                          arguments);
  alloc->set_closure_function(function);

  Value* closure_val = Bind(alloc);
  { LocalVariable* closure_tmp_var = EnterTempLocalScope(closure_val);
    // Store function.
    Value* closure_tmp_val = Bind(new(Z) LoadLocalInstr(*closure_tmp_var));
    Value* func_val =
        Bind(new(Z) ConstantInstr(Function::ZoneHandle(Z, function.raw())));
    Do(new(Z) StoreInstanceFieldInstr(Closure::function_offset(),
                                      closure_tmp_val,
                                      func_val,
                                      kEmitStoreBarrier,
                                      node->token_pos()));
    if (is_implicit) {
      // Create new context containing the receiver.
      const intptr_t kNumContextVariables = 1;  // The receiver.
      Value* allocated_context =
          Bind(new(Z) AllocateContextInstr(node->token_pos(),
                                           kNumContextVariables));
      { LocalVariable* context_tmp_var = EnterTempLocalScope(allocated_context);
        // Store receiver in context.
        Value* context_tmp_val = Bind(new(Z) LoadLocalInstr(*context_tmp_var));
        ValueGraphVisitor for_receiver(owner());
        node->receiver()->Visit(&for_receiver);
        Append(for_receiver);
        Value* receiver = for_receiver.value();
        Do(new(Z) StoreInstanceFieldInstr(Context::variable_offset(0),
                                          context_tmp_val,
                                          receiver,
                                          kEmitStoreBarrier,
                                          node->token_pos()));
        // Store new context in closure.
        closure_tmp_val = Bind(new(Z) LoadLocalInstr(*closure_tmp_var));
        context_tmp_val = Bind(new(Z) LoadLocalInstr(*context_tmp_var));
        Do(new(Z) StoreInstanceFieldInstr(Closure::context_offset(),
                                          closure_tmp_val,
                                          context_tmp_val,
                                          kEmitStoreBarrier,
                                          node->token_pos()));
        Do(ExitTempLocalScope(context_tmp_var));
      }
    } else {
      // Store current context in closure.
      closure_tmp_val = Bind(new(Z) LoadLocalInstr(*closure_tmp_var));
      Value* context = Bind(BuildCurrentContext());
      Do(new(Z) StoreInstanceFieldInstr(Closure::context_offset(),
                                        closure_tmp_val,
                                        context,
                                        kEmitStoreBarrier,
                                        node->token_pos()));
    }
    ReturnDefinition(ExitTempLocalScope(closure_tmp_var));
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
  LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
  LoadLocalNode* load_temp =
      new(Z) LoadLocalNode(Scanner::kNoSourcePos, temp_var);

  LiteralNode* null_constant =
      new(Z) LiteralNode(Scanner::kNoSourcePos, Object::null_instance());
  ComparisonNode* check_is_null =
      new(Z) ComparisonNode(Scanner::kNoSourcePos,
                            Token::kEQ,
                            load_temp,
                            null_constant);
  TestGraphVisitor for_test(owner(), Scanner::kNoSourcePos);
  check_is_null->Visit(&for_test);

  EffectGraphVisitor for_true(owner());
  EffectGraphVisitor for_false(owner());

  StoreLocalNode* store_null =
      new(Z) StoreLocalNode(Scanner::kNoSourcePos, temp_var, null_constant);
  store_null->Visit(&for_true);

  InstanceCallNode* call =
      new(Z) InstanceCallNode(node->token_pos(),
                              load_temp,
                              node->function_name(),
                              node->arguments());
  StoreLocalNode* store_result =
      new(Z) StoreLocalNode(Scanner::kNoSourcePos, temp_var, call);
  store_result->Visit(&for_false);

  Join(for_test, for_true, for_false);
}


void ValueGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  if (node->is_conditional()) {
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value()));
    BuildInstanceCallConditional(node);
    ReturnDefinition(BuildLoadExprTemp());
  } else {
    EffectGraphVisitor::VisitInstanceCallNode(node);
  }
}


void EffectGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  ValueGraphVisitor for_receiver(owner());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  if (node->is_conditional()) {
    Do(BuildStoreExprTemp(for_receiver.value()));
    BuildInstanceCallConditional(node);
  } else {
    PushArgumentInstr* push_receiver = PushArgument(for_receiver.value());
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new(Z) ZoneGrowableArray<PushArgumentInstr*>(
            node->arguments()->length() + 1);
    arguments->Add(push_receiver);

    BuildPushArguments(*node->arguments(), arguments);
    InstanceCallInstr* call = new(Z) InstanceCallInstr(
        node->token_pos(),
        node->function_name(),
        Token::kILLEGAL,
        arguments,
        node->arguments()->names(),
        1,
        owner()->ic_data_array());
    ReturnDefinition(call);
  }
}


static intptr_t GetResultCidOfNativeFactory(const Function& function) {
  const Class& function_class = Class::Handle(function.Owner());
  if (function_class.library() == Library::TypedDataLibrary()) {
    const String& function_name = String::Handle(function.name());
    if (!String::EqualsIgnoringPrivateKey(function_name, Symbols::_New())) {
      return kDynamicCid;
    }
    switch (function_class.id()) {
      case kTypedDataInt8ArrayCid:
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kTypedDataInt16ArrayCid:
      case kTypedDataUint16ArrayCid:
      case kTypedDataInt32ArrayCid:
      case kTypedDataUint32ArrayCid:
      case kTypedDataInt64ArrayCid:
      case kTypedDataUint64ArrayCid:
      case kTypedDataFloat32ArrayCid:
      case kTypedDataFloat64ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
      case kTypedDataInt32x4ArrayCid:
        return function_class.id();
      default:
        return kDynamicCid;  // Unknown.
    }
  }
  return kDynamicCid;
}


// <Expression> ::= StaticCall { function: Function
//                               arguments: <ArgumentList> }
void EffectGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(node->arguments()->length());
  BuildPushArguments(*node->arguments(), arguments);
  StaticCallInstr* call =
      new(Z) StaticCallInstr(node->token_pos(),
                             node->function(),
                             node->arguments()->names(),
                             arguments,
                             owner()->ic_data_array());
  if (node->function().is_native()) {
    const intptr_t result_cid = GetResultCidOfNativeFactory(node->function());
    if (result_cid != kDynamicCid) {
      call->set_result_cid(result_cid);
      call->set_is_native_list_factory(true);
    }
  }
  ReturnDefinition(call);
}


void EffectGraphVisitor::BuildClosureCall(
    ClosureCallNode* node, bool result_needed) {
  ValueGraphVisitor for_closure(owner());
  node->closure()->Visit(&for_closure);
  Append(for_closure);

  LocalVariable* tmp_var = EnterTempLocalScope(for_closure.value());

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(node->arguments()->length());
  Value* closure_val = Bind(new(Z) LoadLocalInstr(*tmp_var));
  PushArgumentInstr* push_closure = PushArgument(closure_val);
  arguments->Add(push_closure);
  BuildPushArguments(*node->arguments(), arguments);

  closure_val = Bind(new(Z) LoadLocalInstr(*tmp_var));
  LoadFieldInstr* function_load = new(Z) LoadFieldInstr(
      closure_val,
      Closure::function_offset(),
      AbstractType::ZoneHandle(Z, AbstractType::null()),
      node->token_pos());
  function_load->set_is_immutable(true);
  Value* function_val = Bind(function_load);

  Definition* closure_call =
      new(Z) ClosureCallInstr(function_val, node, arguments);
  if (result_needed) {
    Value* result = Bind(closure_call);
    Do(new(Z) StoreLocalInstr(*tmp_var, result));
  } else {
    Do(closure_call);
  }
  ReturnDefinition(ExitTempLocalScope(tmp_var));
}


void EffectGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  BuildClosureCall(node, false);
}


void ValueGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  BuildClosureCall(node, true);
}


void EffectGraphVisitor::VisitInitStaticFieldNode(InitStaticFieldNode* node) {
  Value* field = Bind(new(Z) ConstantInstr(node->field()));
  AddInstruction(new(Z) InitStaticFieldInstr(field, node->field()));
}


void EffectGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  Value* context = Bind(BuildCurrentContext());
  Value* clone = Bind(new(Z) CloneContextInstr(node->token_pos(), context));
  Do(BuildStoreContext(clone));
}


Value* EffectGraphVisitor::BuildObjectAllocation(ConstructorCallNode* node) {
  const Class& cls = Class::ZoneHandle(Z, node->constructor().Owner());
  const bool cls_is_parameterized = cls.NumTypeArguments() > 0;

  ZoneGrowableArray<PushArgumentInstr*>* allocate_arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(
          cls_is_parameterized ? 1 : 0);
  if (cls_is_parameterized) {
    Value* type_args = BuildInstantiatedTypeArguments(node->token_pos(),
                                                      node->type_arguments());
    allocate_arguments->Add(PushArgument(type_args));
  }

  Definition* allocation = new(Z) AllocateObjectInstr(
      node->token_pos(),
      Class::ZoneHandle(Z, node->constructor().Owner()),
      allocate_arguments);

  return Bind(allocation);
}


void EffectGraphVisitor::BuildConstructorCall(
    ConstructorCallNode* node,
    PushArgumentInstr* push_alloc_value) {
  Value* ctor_arg = Bind(new(Z) ConstantInstr(
      Smi::ZoneHandle(Z, Smi::New(Function::kCtorPhaseAll))));
  PushArgumentInstr* push_ctor_arg = PushArgument(ctor_arg);

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  arguments->Add(push_alloc_value);
  arguments->Add(push_ctor_arg);

  BuildPushArguments(*node->arguments(), arguments);
  Do(new(Z) StaticCallInstr(node->token_pos(),
                            node->constructor(),
                            node->arguments()->names(),
                            arguments,
                            owner()->ic_data_array()));
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
  return kDynamicCid;   // Not a known list constructor.
}


void EffectGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  if (node->constructor().IsFactory()) {
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new(Z) ZoneGrowableArray<PushArgumentInstr*>();
    PushArgumentInstr* push_type_arguments = PushArgument(
        BuildInstantiatedTypeArguments(node->token_pos(),
                                       node->type_arguments()));
    arguments->Add(push_type_arguments);
    ASSERT(arguments->length() == 1);
    BuildPushArguments(*node->arguments(), arguments);
    StaticCallInstr* call =
        new(Z) StaticCallInstr(node->token_pos(),
                               node->constructor(),
                               node->arguments()->names(),
                               arguments,
                               owner()->ic_data_array());
    const intptr_t result_cid = GetResultCidOfListFactory(node);
    if (result_cid != kDynamicCid) {
      call->set_result_cid(result_cid);
      call->set_is_known_list_constructor(true);
      // Recognized fixed length array factory must have two arguments:
      // (0) type-arguments, (1) length.
      ASSERT(!LoadFieldInstr::IsFixedLengthArrayCid(result_cid) ||
             arguments->length() == 2);
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


Value* EffectGraphVisitor::BuildInstantiator(const Class& instantiator_class) {
  ASSERT(instantiator_class.NumTypeParameters() > 0);
  Function& outer_function = Function::Handle(Z, owner()->function().raw());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  if (outer_function.IsFactory()) {
    return NULL;
  }

  LocalVariable* instantiator = owner()->parsed_function().instantiator();
  ASSERT(instantiator != NULL);
  Value* result = Bind(BuildLoadLocal(*instantiator));
  return result;
}


// 'expression_temp_var' may not be used inside this method if 'instantiator'
// is not NULL.
Value* EffectGraphVisitor::BuildInstantiatorTypeArguments(
    intptr_t token_pos,
    const Class& instantiator_class,
    Value* instantiator) {
  if (instantiator_class.NumTypeParameters() == 0) {
    // The type arguments are compile time constants.
    TypeArguments& type_arguments =
        TypeArguments::ZoneHandle(Z, TypeArguments::null());
    // Type is temporary. Only its type arguments are preserved.
    Type& type = Type::Handle(
        Z,
        Type::New(instantiator_class, type_arguments, token_pos, Heap::kNew));
    type ^= ClassFinalizer::FinalizeType(
        instantiator_class, type, ClassFinalizer::kFinalize);
    ASSERT(!type.IsMalformedOrMalbounded());
    type_arguments = type.arguments();
    type_arguments = type_arguments.Canonicalize();
    return Bind(new(Z) ConstantInstr(type_arguments));
  }
  Function& outer_function = Function::Handle(Z, owner()->function().raw());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  if (outer_function.IsFactory()) {
    // No instantiator for factories.
    ASSERT(instantiator == NULL);
    LocalVariable* instantiator_var =
        owner()->parsed_function().instantiator();
    ASSERT(instantiator_var != NULL);
    return Bind(BuildLoadLocal(*instantiator_var));
  }
  if (instantiator == NULL) {
    instantiator = BuildInstantiator(instantiator_class);
  }
  // The instantiator is the receiver of the caller, which is not a factory.
  // The receiver cannot be null; extract its TypeArguments object.
  // Note that in the factory case, the instantiator is the first parameter
  // of the factory, i.e. already a TypeArguments object.
  intptr_t type_arguments_field_offset =
      instantiator_class.type_arguments_field_offset();
  ASSERT(type_arguments_field_offset != Class::kNoTypeArguments);

  return Bind(new(Z) LoadFieldInstr(
      instantiator,
      type_arguments_field_offset,
      Type::ZoneHandle(Z, Type::null()),  // Not an instance, no type.
      Scanner::kNoSourcePos));
}


Value* EffectGraphVisitor::BuildInstantiatedTypeArguments(
    intptr_t token_pos,
    const TypeArguments& type_arguments) {
  if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
    return Bind(new(Z) ConstantInstr(type_arguments));
  }
  // The type arguments are uninstantiated.
  const Class& instantiator_class = Class::ZoneHandle(
      Z, owner()->function().Owner());
  Value* instantiator_value =
      BuildInstantiatorTypeArguments(token_pos, instantiator_class, NULL);
  const bool use_instantiator_type_args =
      type_arguments.IsUninstantiatedIdentity() ||
      type_arguments.CanShareInstantiatorTypeArguments(instantiator_class);
  if (use_instantiator_type_args) {
    return instantiator_value;
  } else {
    return Bind(new(Z) InstantiateTypeArgumentsInstr(token_pos,
                                                  type_arguments,
                                                  instantiator_class,
                                                  instantiator_value));
  }
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
  { LocalVariable* tmp_var = EnterTempLocalScope(allocate);
    Value* allocated_tmp = Bind(new(Z) LoadLocalInstr(*tmp_var));
    PushArgumentInstr* push_allocated_value = PushArgument(allocated_tmp);
    BuildConstructorCall(node, push_allocated_value);
    ReturnDefinition(ExitTempLocalScope(tmp_var));
  }
}



void EffectGraphVisitor::BuildInstanceGetterConditional(
    InstanceGetterNode* node) {
  LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
  LoadLocalNode* load_temp =
      new(Z) LoadLocalNode(Scanner::kNoSourcePos, temp_var);

  LiteralNode* null_constant =
      new(Z) LiteralNode(Scanner::kNoSourcePos, Object::null_instance());
  ComparisonNode* check_is_null =
      new(Z) ComparisonNode(Scanner::kNoSourcePos,
                            Token::kEQ,
                            load_temp,
                            null_constant);
  TestGraphVisitor for_test(owner(), Scanner::kNoSourcePos);
  check_is_null->Visit(&for_test);

  EffectGraphVisitor for_true(owner());
  EffectGraphVisitor for_false(owner());

  StoreLocalNode* store_null =
      new(Z) StoreLocalNode(Scanner::kNoSourcePos, temp_var, null_constant);
  store_null->Visit(&for_true);

  InstanceGetterNode* getter =
      new(Z) InstanceGetterNode(node->token_pos(),
                                load_temp,
                                node->field_name());
  StoreLocalNode* store_getter =
      new(Z) StoreLocalNode(Scanner::kNoSourcePos, temp_var, getter);
  store_getter->Visit(&for_false);

  Join(for_test, for_true, for_false);
}


void ValueGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  if (node->is_conditional()) {
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value()));
    BuildInstanceGetterConditional(node);
    ReturnDefinition(BuildLoadExprTemp());
  } else {
    EffectGraphVisitor::VisitInstanceGetterNode(node);
  }
}


void EffectGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  ValueGraphVisitor for_receiver(owner());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  if (node->is_conditional()) {
    Do(BuildStoreExprTemp(for_receiver.value()));
    BuildInstanceGetterConditional(node);
  } else {
    PushArgumentInstr* push_receiver = PushArgument(for_receiver.value());
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new(Z) ZoneGrowableArray<PushArgumentInstr*>(1);
    arguments->Add(push_receiver);
    const String& name =
        String::ZoneHandle(Z, Field::GetterSymbol(node->field_name()));
    InstanceCallInstr* call = new(Z) InstanceCallInstr(
        node->token_pos(),
        name,
        Token::kGET,
        arguments, Object::null_array(),
        1,
        owner()->ic_data_array());
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
    value = Bind(BuildStoreExprTemp(for_value.value()));
  } else {
    value = for_value.value();
  }
  arguments->Add(PushArgument(value));
}


void EffectGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  if (node->is_conditional()) {
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value()));

    LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
    LoadLocalNode* load_temp =
        new(Z) LoadLocalNode(Scanner::kNoSourcePos, temp_var);
    LiteralNode* null_constant =
        new(Z) LiteralNode(Scanner::kNoSourcePos, Object::null_instance());
    ComparisonNode* check_is_null =
        new(Z) ComparisonNode(Scanner::kNoSourcePos,
                              Token::kEQ,
                              load_temp,
                              null_constant);
    TestGraphVisitor for_test(owner(), Scanner::kNoSourcePos);
    check_is_null->Visit(&for_test);

    EffectGraphVisitor for_true(owner());
    EffectGraphVisitor for_false(owner());

    InstanceSetterNode* setter =
        new(Z) InstanceSetterNode(node->token_pos(),
                                  load_temp,
                                  node->field_name(),
                                  node->value());
    setter->Visit(&for_false);
    Join(for_test, for_true, for_false);
    return;
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildInstanceSetterArguments(node, arguments, kResultNotNeeded);
  const String& name =
      String::ZoneHandle(Z, Field::SetterSymbol(node->field_name()));
  const intptr_t kNumArgsChecked = 1;  // Do not check value type.
  InstanceCallInstr* call = new(Z) InstanceCallInstr(node->token_pos(),
                                                     name,
                                                     Token::kSET,
                                                     arguments,
                                                     Object::null_array(),
                                                     kNumArgsChecked,
                                                     owner()->ic_data_array());
  ReturnDefinition(call);
}


void ValueGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  if (node->is_conditional()) {
    ValueGraphVisitor for_receiver(owner());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    Do(BuildStoreExprTemp(for_receiver.value()));

    LocalVariable* temp_var = owner()->parsed_function().expression_temp_var();
    LoadLocalNode* load_temp =
        new(Z) LoadLocalNode(Scanner::kNoSourcePos, temp_var);
    LiteralNode* null_constant =
        new(Z) LiteralNode(Scanner::kNoSourcePos, Object::null_instance());
    ComparisonNode* check_is_null =
        new(Z) ComparisonNode(Scanner::kNoSourcePos,
                              Token::kEQ,
                              load_temp,
                              null_constant);
    TestGraphVisitor for_test(owner(), Scanner::kNoSourcePos);
    check_is_null->Visit(&for_test);

    ValueGraphVisitor for_true(owner());
    null_constant->Visit(&for_true);
    for_true.Do(BuildStoreExprTemp(for_true.value()));

    ValueGraphVisitor for_false(owner());
    InstanceSetterNode* setter =
        new(Z) InstanceSetterNode(node->token_pos(),
                                  load_temp,
                                  node->field_name(),
                                  node->value());
    setter->Visit(&for_false);
    for_false.Do(BuildStoreExprTemp(for_false.value()));

    Join(for_test, for_true, for_false);
    ReturnDefinition(BuildLoadExprTemp());
    return;
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildInstanceSetterArguments(node, arguments, kResultNeeded);
  const String& name =
      String::ZoneHandle(Z, Field::SetterSymbol(node->field_name()));
  const intptr_t kNumArgsChecked = 1;  // Do not check value type.
  Do(new(Z) InstanceCallInstr(node->token_pos(),
                              name,
                              Token::kSET,
                              arguments,
                              Object::null_array(),
                              kNumArgsChecked,
                              owner()->ic_data_array()));
  ReturnDefinition(BuildLoadExprTemp());
}


void EffectGraphVisitor::VisitStaticGetterNode(StaticGetterNode* node) {
  const String& getter_name =
      String::ZoneHandle(Z, Field::GetterSymbol(node->field_name()));
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>();
  Function& getter_function = Function::ZoneHandle(Z, Function::null());
  if (node->is_super_getter()) {
    // Statically resolved instance getter, i.e. "super getter".
    ASSERT(node->receiver() != NULL);
    getter_function = Resolver::ResolveDynamicAnyArgs(node->cls(), getter_name);
    if (getter_function.IsNull()) {
      // Resolve and call noSuchMethod.
      ArgumentListNode* arguments = new(Z) ArgumentListNode(node->token_pos());
      arguments->Add(node->receiver());
      StaticCallInstr* call =
          BuildStaticNoSuchMethodCall(node->cls(),
                                      node->receiver(),
                                      getter_name,
                                      arguments,
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
          node->token_pos(),
          node->cls(),
          getter_name,
          NULL,  // No Arguments to getter.
          InvocationMirror::EncodeType(
              node->cls().IsTopLevel() ?
                  InvocationMirror::kTopLevel :
                  InvocationMirror::kStatic,
              InvocationMirror::kGetter));
      ReturnDefinition(call);
      return;
    }
  }
  ASSERT(!getter_function.IsNull());
  StaticCallInstr* call = new(Z) StaticCallInstr(
      node->token_pos(),
      getter_function,
      Object::null_array(),  // No names
      arguments,
      owner()->ic_data_array());
  ReturnDefinition(call);
}


void EffectGraphVisitor::BuildStaticSetter(StaticSetterNode* node,
                                           bool result_is_needed) {
  const String& setter_name =
      String::ZoneHandle(Z, Field::SetterSymbol(node->field_name()));
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(1);
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
      ArgumentListNode* arguments = new(Z) ArgumentListNode(node->token_pos());
      arguments->Add(node->receiver());
      arguments->Add(node->value());
      call = BuildStaticNoSuchMethodCall(
          node->cls(),
          node->receiver(),
          setter_name,
          arguments,
          result_is_needed,  // Save last arg if result is needed.
          true);  // Super invocation.
    } else {
      // Throw a NoSuchMethodError.
      ArgumentListNode* arguments = new(Z) ArgumentListNode(node->token_pos());
      arguments->Add(node->value());
      call = BuildThrowNoSuchMethodError(
          node->token_pos(),
          node->cls(),
          setter_name,
          arguments,  // Argument is the value passed to the setter.
          InvocationMirror::EncodeType(
            node->cls().IsTopLevel() ?
                InvocationMirror::kTopLevel :
                InvocationMirror::kStatic,
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
      value = Bind(BuildStoreExprTemp(for_value.value()));
    } else {
      value = for_value.value();
    }
    arguments->Add(PushArgument(value));

    call = new(Z) StaticCallInstr(node->token_pos(),
                                  setter_function,
                                  Object::null_array(),  // No names.
                                  arguments,
                                  owner()->ic_data_array());
  }
  if (result_is_needed) {
    Do(call);
    ReturnDefinition(BuildLoadExprTemp());
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


LoadLocalInstr* EffectGraphVisitor::BuildLoadThisVar(LocalScope* scope) {
  LocalVariable* receiver_var = scope->LookupVariable(Symbols::This(),
                                                      true);  // Test only.
  return new(Z) LoadLocalInstr(*receiver_var);
}


LoadFieldInstr* EffectGraphVisitor::BuildNativeGetter(
    NativeBodyNode* node,
    MethodRecognizer::Kind kind,
    intptr_t offset,
    const Type& type,
    intptr_t class_id) {
  Value* receiver = Bind(BuildLoadThisVar(node->scope()));
  LoadFieldInstr* load = new(Z) LoadFieldInstr(receiver,
                                               offset,
                                               type,
                                               node->token_pos());
  load->set_result_cid(class_id);
  load->set_recognized_kind(kind);
  return load;
}


ConstantInstr* EffectGraphVisitor::DoNativeSetterStoreValue(
    NativeBodyNode* node,
    intptr_t offset,
    StoreBarrierType emit_store_barrier) {
  Value* receiver = Bind(BuildLoadThisVar(node->scope()));
  LocalVariable* value_var =
      node->scope()->LookupVariable(Symbols::Value(), true);
  Value* value = Bind(new(Z) LoadLocalInstr(*value_var));
  StoreInstanceFieldInstr* store = new(Z) StoreInstanceFieldInstr(
      offset,
      receiver,
      value,
      emit_store_barrier,
      node->token_pos());
  Do(store);
  return new(Z) ConstantInstr(Object::ZoneHandle(Z, Object::null()));
}


void EffectGraphVisitor::VisitNativeBodyNode(NativeBodyNode* node) {
  const Function& function = owner()->function();
  if (!function.IsClosureFunction()) {
    MethodRecognizer::Kind kind = MethodRecognizer::RecognizeKind(function);
    switch (kind) {
      case MethodRecognizer::kObjectEquals: {
        Value* receiver = Bind(BuildLoadThisVar(node->scope()));
        LocalVariable* other_var =
            node->scope()->LookupVariable(Symbols::Other(),
                                          true);  // Test only.
        Value* other = Bind(new(Z) LoadLocalInstr(*other_var));
        // Receiver is not a number because numbers override equality.
        const bool kNoNumberCheck = false;
        StrictCompareInstr* compare =
            new(Z) StrictCompareInstr(node->token_pos(),
                                      Token::kEQ_STRICT,
                                      receiver,
                                      other,
                                      kNoNumberCheck);
        return ReturnDefinition(compare);
      }
      case MethodRecognizer::kStringBaseLength:
      case MethodRecognizer::kStringBaseIsEmpty: {
        // Treat length loads as mutable (i.e. affected by side effects) to
        // avoid hoisting them since we can't hoist the preceding class-check.
        // This is because of externalization of strings that affects their
        // class-id.
        LoadFieldInstr* load = BuildNativeGetter(
            node, MethodRecognizer::kStringBaseLength, String::length_offset(),
            Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
        if (kind == MethodRecognizer::kStringBaseLength) {
          return ReturnDefinition(load);
        }
        ASSERT(kind == MethodRecognizer::kStringBaseIsEmpty);
        Value* zero_val = Bind(new(Z) ConstantInstr(
            Smi::ZoneHandle(Z, Smi::New(0))));
        Value* load_val = Bind(load);
        StrictCompareInstr* compare =
            new(Z) StrictCompareInstr(node->token_pos(),
                                   Token::kEQ_STRICT,
                                   load_val,
                                   zero_val,
                                   false);  // No number check.
        return ReturnDefinition(compare);
      }
      case MethodRecognizer::kGrowableArrayLength:
      case MethodRecognizer::kObjectArrayLength:
      case MethodRecognizer::kImmutableArrayLength:
      case MethodRecognizer::kTypedDataLength: {
        LoadFieldInstr* load = BuildNativeGetter(
            node, kind, OffsetForLengthGetter(kind),
            Type::ZoneHandle(Z, Type::SmiType()), kSmiCid);
        load->set_is_immutable(kind != MethodRecognizer::kGrowableArrayLength);
        return ReturnDefinition(load);
      }
      case MethodRecognizer::kClassIDgetID: {
        LocalVariable* value_var =
            node->scope()->LookupVariable(Symbols::Value(), true);
        Value* value = Bind(new(Z) LoadLocalInstr(*value_var));
        LoadClassIdInstr* load = new(Z) LoadClassIdInstr(value);
        return ReturnDefinition(load);
      }
      case MethodRecognizer::kGrowableArrayCapacity: {
        Value* receiver = Bind(BuildLoadThisVar(node->scope()));
        LoadFieldInstr* data_load = new(Z) LoadFieldInstr(
            receiver,
            Array::data_offset(),
            Type::ZoneHandle(Z, Type::DynamicType()),
            node->token_pos());
        data_load->set_result_cid(kArrayCid);
        Value* data = Bind(data_load);
        LoadFieldInstr* length_load = new(Z) LoadFieldInstr(
            data,
            Array::length_offset(),
            Type::ZoneHandle(Z, Type::SmiType()),
            node->token_pos());
        length_load->set_result_cid(kSmiCid);
        length_load->set_recognized_kind(MethodRecognizer::kObjectArrayLength);
        return ReturnDefinition(length_load);
      }
      case MethodRecognizer::kObjectArrayAllocate: {
        LocalVariable* type_args_parameter =
            node->scope()->LookupVariable(Symbols::TypeArgumentsParameter(),
                                          true);
        Value* element_type = Bind(new(Z) LoadLocalInstr(*type_args_parameter));
        LocalVariable* length_parameter =
            node->scope()->LookupVariable(Symbols::Length(), true);
        Value* length = Bind(new(Z) LoadLocalInstr(*length_parameter));
        CreateArrayInstr* create_array =
            new CreateArrayInstr(node->token_pos(), element_type, length);
        return ReturnDefinition(create_array);
      }
      case MethodRecognizer::kBigint_getDigits: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, Bigint::digits_offset(),
            Type::ZoneHandle(Z, Type::DynamicType()),
            kTypedDataUint32ArrayCid));
      }
      case MethodRecognizer::kBigint_getUsed: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, Bigint::used_offset(),
            Type::ZoneHandle(Z, Type::SmiType()), kSmiCid));
      }
      case MethodRecognizer::kLinkedHashMap_getIndex: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, LinkedHashMap::index_offset(),
            Type::ZoneHandle(Z, Type::DynamicType()),
            kDynamicCid));
      }
      case MethodRecognizer::kLinkedHashMap_setIndex: {
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::index_offset(), kEmitStoreBarrier));
      }
      case MethodRecognizer::kLinkedHashMap_getData: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, LinkedHashMap::data_offset(),
            Type::ZoneHandle(Z, Type::DynamicType()),
            kArrayCid));
      }
      case MethodRecognizer::kLinkedHashMap_setData: {
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::data_offset(), kEmitStoreBarrier));
      }
      case MethodRecognizer::kLinkedHashMap_getHashMask: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, LinkedHashMap::hash_mask_offset(),
            Type::ZoneHandle(Z, Type::SmiType()),
            kSmiCid));
      }
      case MethodRecognizer::kLinkedHashMap_setHashMask: {
        // Smi field; no barrier needed.
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::hash_mask_offset(), kNoStoreBarrier));
      }
      case MethodRecognizer::kLinkedHashMap_getUsedData: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, LinkedHashMap::used_data_offset(),
            Type::ZoneHandle(Z, Type::SmiType()),
            kSmiCid));
      }
      case MethodRecognizer::kLinkedHashMap_setUsedData: {
        // Smi field; no barrier needed.
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::used_data_offset(), kNoStoreBarrier));
      }
      case MethodRecognizer::kLinkedHashMap_getDeletedKeys: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, LinkedHashMap::deleted_keys_offset(),
            Type::ZoneHandle(Z, Type::SmiType()),
            kSmiCid));
      }
      case MethodRecognizer::kLinkedHashMap_setDeletedKeys: {
        // Smi field; no barrier needed.
        return ReturnDefinition(DoNativeSetterStoreValue(
            node, LinkedHashMap::deleted_keys_offset(), kNoStoreBarrier));
      }
      case MethodRecognizer::kBigint_getNeg: {
        return ReturnDefinition(BuildNativeGetter(
            node, kind, Bigint::neg_offset(),
            Type::ZoneHandle(Z, Type::BoolType()), kBoolCid));
      }
      default:
        break;
    }
  }
  InlineBailout("EffectGraphVisitor::VisitNativeBodyNode");
  NativeCallInstr* native_call = new(Z) NativeCallInstr(node);
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
  Definition* load = BuildLoadLocal(node->local());
  ReturnDefinition(load);
}


// <Expression> ::= StoreLocal { local: LocalVariable
//                               value: <Expression> }
void EffectGraphVisitor::VisitStoreLocalNode(StoreLocalNode* node) {
  // If the right hand side is an expression that does not contain
  // a safe point for the debugger to stop, add an explicit stub
  // call. Exception: don't do this when assigning to or from internal
  // variables, or for generated code that has no source position.
  if (FLAG_support_debugger) {
    if ((node->value()->IsLiteralNode() ||
        (node->value()->IsLoadLocalNode() &&
            !node->value()->AsLoadLocalNode()->local().IsInternal()) ||
        node->value()->IsClosureNode()) &&
        !node->local().IsInternal() &&
        (node->token_pos() != Scanner::kNoSourcePos)) {
      AddInstruction(new(Z) DebugStepCheckInstr(
          node->token_pos(), RawPcDescriptors::kRuntimeCall));
    }
  }

  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = for_value.value();
  if (Isolate::Current()->flags().type_checks()) {
    store_value = BuildAssignableValue(node->value()->token_pos(),
                                       store_value,
                                       node->local().type(),
                                       node->local().name());
  }
  Definition* store = BuildStoreLocal(node->local(), store_value);
  ReturnDefinition(store);
}


void EffectGraphVisitor::VisitLoadInstanceFieldNode(
    LoadInstanceFieldNode* node) {
  ValueGraphVisitor for_instance(owner());
  node->instance()->Visit(&for_instance);
  Append(for_instance);
  LoadFieldInstr* load = new(Z) LoadFieldInstr(
      for_instance.value(),
      &node->field(),
      AbstractType::ZoneHandle(Z, node->field().type()),
      node->token_pos());
  if (node->field().guarded_cid() != kIllegalCid) {
    if (!node->field().is_nullable() ||
        (node->field().guarded_cid() == kNullCid)) {
      load->set_result_cid(node->field().guarded_cid());
    }
    FlowGraph::AddToGuardedFields(owner()->guarded_fields(), &node->field());
  }
  ReturnDefinition(load);
}


void EffectGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  ValueGraphVisitor for_instance(owner());
  node->instance()->Visit(&for_instance);
  Append(for_instance);
  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = for_value.value();
  if (Isolate::Current()->flags().type_checks()) {
    const AbstractType& type =
        AbstractType::ZoneHandle(Z, node->field().type());
    const String& dst_name = String::ZoneHandle(Z, node->field().name());
    store_value = BuildAssignableValue(node->value()->token_pos(),
                                       store_value,
                                       type,
                                       dst_name);
  }

  if (FLAG_use_field_guards) {
    store_value = Bind(BuildStoreExprTemp(store_value));
    GuardFieldClassInstr* guard_field_class =
        new(Z) GuardFieldClassInstr(store_value,
                                 node->field(),
                                 isolate()->GetNextDeoptId());
    AddInstruction(guard_field_class);
    store_value = Bind(BuildLoadExprTemp());
    GuardFieldLengthInstr* guard_field_length =
        new(Z) GuardFieldLengthInstr(store_value,
                                     node->field(),
                                     isolate()->GetNextDeoptId());
    AddInstruction(guard_field_length);
    store_value = Bind(BuildLoadExprTemp());
  }
  StoreInstanceFieldInstr* store =
      new(Z) StoreInstanceFieldInstr(node->field(),
                                     for_instance.value(),
                                     store_value,
                                     kEmitStoreBarrier,
                                     node->token_pos());
  // Maybe initializing unboxed store.
  store->set_is_potential_unboxed_initialization(true);
  ReturnDefinition(store);
}


void EffectGraphVisitor::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  if (node->field().is_const()) {
    ASSERT(node->field().value() != Object::sentinel().raw());
    ASSERT(node->field().value() != Object::transition_sentinel().raw());
    Definition* result =
        new(Z) ConstantInstr(Instance::ZoneHandle(Z, node->field().value()));
    return ReturnDefinition(result);
  }
  Value* field_value = Bind(new(Z) ConstantInstr(node->field()));
  LoadStaticFieldInstr* load = new(Z) LoadStaticFieldInstr(field_value);
  ReturnDefinition(load);
}


Definition* EffectGraphVisitor::BuildStoreStaticField(
  StoreStaticFieldNode* node, bool result_is_needed) {
  ValueGraphVisitor for_value(owner());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = NULL;
  if (result_is_needed) {
    store_value = Bind(BuildStoreExprTemp(for_value.value()));
  } else {
    store_value = for_value.value();
  }
  StoreStaticFieldInstr* store =
      new(Z) StoreStaticFieldInstr(node->field(), store_value);

  if (result_is_needed) {
    Do(store);
    return BuildLoadExprTemp();
  } else {
    return store;
  }
}


void EffectGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  ReturnDefinition(BuildStoreStaticField(node, kResultNotNeeded));
}


void ValueGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  ReturnDefinition(BuildStoreStaticField(node, kResultNeeded));
}


void EffectGraphVisitor::VisitLoadIndexedNode(LoadIndexedNode* node) {
  Function* super_function = NULL;
  if (node->IsSuperLoad()) {
    // Resolve the load indexed operator in the super class.
    super_function = &Function::ZoneHandle(
          Z, Resolver::ResolveDynamicAnyArgs(node->super_class(),
                                             Symbols::IndexToken()));
    if (super_function->IsNull()) {
      // Could not resolve super operator. Generate call noSuchMethod() of the
      // super class instead.
      ArgumentListNode* arguments = new(Z) ArgumentListNode(node->token_pos());
      arguments->Add(node->array());
      arguments->Add(node->index_expr());
      StaticCallInstr* call =
          BuildStaticNoSuchMethodCall(node->super_class(),
                                      node->array(),
                                      Symbols::IndexToken(),
                                      arguments,
                                      false,  // Don't save last arg.
                                      true);  // Super invocation.
      ReturnDefinition(call);
      return;
    }
  }
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  ValueGraphVisitor for_array(owner());
  node->array()->Visit(&for_array);
  Append(for_array);
  arguments->Add(PushArgument(for_array.value()));

  ValueGraphVisitor for_index(owner());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  arguments->Add(PushArgument(for_index.value()));

  if (super_function != NULL) {
    // Generate static call to super operator.
    StaticCallInstr* load = new(Z) StaticCallInstr(node->token_pos(),
                                                   *super_function,
                                                   Object::null_array(),
                                                   arguments,
                                                   owner()->ic_data_array());
    ReturnDefinition(load);
  } else {
    // Generate dynamic call to index operator.
    const intptr_t checked_argument_count = 1;
    InstanceCallInstr* load = new(Z) InstanceCallInstr(
        node->token_pos(),
        Symbols::IndexToken(),
        Token::kINDEX,
        arguments,
        Object::null_array(),
        checked_argument_count,
        owner()->ic_data_array());
    ReturnDefinition(load);
  }
}


Definition* EffectGraphVisitor::BuildStoreIndexedValues(
    StoreIndexedNode* node,
    bool result_is_needed) {
  Function* super_function = NULL;
  if (node->IsSuperStore()) {
    // Resolve the store indexed operator in the super class.
    super_function = &Function::ZoneHandle(
        Z, Resolver::ResolveDynamicAnyArgs(node->super_class(),
                                           Symbols::AssignIndexToken()));
    if (super_function->IsNull()) {
      // Could not resolve super operator. Generate call noSuchMethod() of the
      // super class instead.
      ArgumentListNode* arguments = new(Z) ArgumentListNode(node->token_pos());
      arguments->Add(node->array());
      arguments->Add(node->index_expr());
      arguments->Add(node->value());
      StaticCallInstr* call = BuildStaticNoSuchMethodCall(
          node->super_class(),
          node->array(),
          Symbols::AssignIndexToken(),
          arguments,
          result_is_needed,  // Save last arg if result is needed.
          true);  // Super invocation.
      if (result_is_needed) {
        Do(call);
        // BuildStaticNoSuchMethodCall stores the value in expression_temp.
        return BuildLoadExprTemp();
      } else {
        return call;
      }
    }
  }

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(3);
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
    value = Bind(BuildStoreExprTemp(for_value.value()));
  } else {
    value = for_value.value();
  }
  arguments->Add(PushArgument(value));

  if (super_function != NULL) {
    // Generate static call to super operator []=.

    StaticCallInstr* store =
        new(Z) StaticCallInstr(node->token_pos(),
                               *super_function,
                               Object::null_array(),
                               arguments,
                               owner()->ic_data_array());
    if (result_is_needed) {
      Do(store);
      return BuildLoadExprTemp();
    } else {
      return store;
    }
  } else {
    // Generate dynamic call to operator []=.
    const intptr_t checked_argument_count = 2;  // Do not check for value type.
    const String& name =
        String::ZoneHandle(Z, Symbols::New(Token::Str(Token::kASSIGN_INDEX)));
    InstanceCallInstr* store =
        new(Z) InstanceCallInstr(node->token_pos(),
                                 name,
                                 Token::kASSIGN_INDEX,
                                 arguments,
                                 Object::null_array(),
                                 checked_argument_count,
                                 owner()->ic_data_array());
    if (result_is_needed) {
      Do(store);
      return BuildLoadExprTemp();
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
  const ContextScope& context_scope = ContextScope::Handle(
      owner()->function().context_scope());
  return !context_scope.IsNull() && (context_scope.num_variables() > 0);
}


void EffectGraphVisitor::UnchainContexts(intptr_t n) {
  if (n > 0) {
    Value* context = Bind(BuildCurrentContext());
    while (n-- > 0) {
      context = Bind(
          new(Z) LoadFieldInstr(context,
                                Context::parent_offset(),
                                // Not an instance, no type.
                                Type::ZoneHandle(Z, Type::null()),
                                Scanner::kNoSourcePos));
    }
    Do(BuildStoreContext(context));
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

  if (FLAG_support_debugger && is_top_level_sequence) {
    AddInstruction(new(Z) DebugStepCheckInstr(function.token_pos(),
                                              RawPcDescriptors::kRuntimeCall));
  }

  if (num_context_variables > 0) {
    // The local scope declares variables that are captured.
    // Allocate and chain a new context (Except don't chain when at the function
    // entry if the function does not capture any variables from outer scopes).
    Value* allocated_context =
        Bind(new(Z) AllocateContextInstr(node->token_pos(),
                                         num_context_variables));
    { LocalVariable* tmp_var = EnterTempLocalScope(allocated_context);
      if (!is_top_level_sequence || HasContextScope()) {
        ASSERT(is_top_level_sequence ||
               (nested_block.ContextLevel() ==
                nested_block.outer()->ContextLevel() + 1));
        Value* tmp_val = Bind(new(Z) LoadLocalInstr(*tmp_var));
        Value* parent_context = Bind(BuildCurrentContext());
        Do(new(Z) StoreInstanceFieldInstr(Context::parent_offset(),
                                          tmp_val,
                                          parent_context,
                                          kEmitStoreBarrier,
                                          Scanner::kNoSourcePos));
      }
      Do(BuildStoreContext(Bind(ExitTempLocalScope(tmp_var))));
    }

    // If this node_sequence is the body of the function being compiled, copy
    // the captured parameters from the frame into the context.
    if (is_top_level_sequence) {
      ASSERT(scope->context_level() == 1);
      const int num_params = function.NumParameters();
      int param_frame_index = (num_params == function.num_fixed_parameters()) ?
          (kParamEndSlotFromFp + num_params) : kFirstLocalSlotFromFp;
      for (int pos = 0; pos < num_params; param_frame_index--, pos++) {
        const LocalVariable& parameter = *scope->VariableAt(pos);
        ASSERT(parameter.owner() == scope);
        if (parameter.is_captured()) {
          // Create a temporary local describing the original position.
          const String& temp_name = Symbols::TempParam();
          LocalVariable* temp_local = new(Z) LocalVariable(
              0,  // Token index.
              temp_name,
              Type::ZoneHandle(Z, Type::DynamicType()));  // Type.
          temp_local->set_index(param_frame_index);

          // Mark this local as captured parameter so that the optimizer
          // correctly handles these when compiling try-catch: Captured
          // parameters are not in the stack environment, therefore they
          // must be skipped when emitting sync-code in try-blocks.
          temp_local->set_is_captured_parameter(true);

          // Copy parameter from local frame to current context.
          Value* load = Bind(BuildLoadLocal(*temp_local));
          Do(BuildStoreLocal(parameter, load));
          // Write NULL to the source location to detect buggy accesses and
          // allow GC of passed value if it gets overwritten by a new value in
          // the function.
          Value* null_constant = Bind(new(Z) ConstantInstr(
              Object::ZoneHandle(Z, Object::null())));
          Do(BuildStoreLocal(*temp_local, null_constant));
        }
      }
    }
  }

  // This check may be deleted if the generated code is leaf.
  // Native functions don't need a stack check at entry.
  if (is_top_level_sequence && !function.is_native()) {
    // Always allocate CheckOverflowInstr so that deopt-ids match regardless
    // if we inline or not.
    if (!function.IsImplicitGetterFunction() &&
        !function.IsImplicitSetterFunction()) {
      CheckStackOverflowInstr* check =
          new(Z) CheckStackOverflowInstr(function.token_pos(), 0);
      // If we are inlining don't actually attach the stack check. We must still
      // create the stack check in order to allocate a deopt id.
      if (!owner()->IsInlining()) {
        AddInstruction(check);
      }
    }
  }

  if (Isolate::Current()->flags().type_checks() && is_top_level_sequence) {
    const int num_params = function.NumParameters();
    int pos = 0;
    if (function.IsGenerativeConstructor()) {
      // Skip type checking of receiver and phase for constructor functions.
      pos = 2;
    } else if (function.IsFactory() || function.IsDynamicFunction()) {
      // Skip type checking of type arguments for factory functions.
      // Skip type checking of receiver for instance functions.
      pos = 1;
    }
    while (pos < num_params) {
      const LocalVariable& parameter = *scope->VariableAt(pos);
      ASSERT(parameter.owner() == scope);
      if (!CanSkipTypeCheck(parameter.token_pos(),
                            NULL,
                            parameter.type(),
                            parameter.name())) {
        Value* parameter_value = Bind(BuildLoadLocal(parameter));
        Do(BuildAssertAssignable(parameter.token_pos(),
                                 parameter_value,
                                 parameter.type(),
                                 parameter.name()));
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
      (function.IsAsyncClosure() ||
          function.IsSyncGenClosure() ||
          function.IsAsyncGenClosure())) {
    JoinEntryInstr* preamble_end = new(Z) JoinEntryInstr(
        owner()->AllocateBlockId(), owner()->try_index());
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
      (function.IsAsyncClosure() ||
          function.IsSyncGenClosure() ||
          function.IsAsyncGenClosure())) {
    ASSERT(preamble_start != NULL);
    // We are at the top level. Fetch the corresponding scope.
    LocalScope* top_scope = node->scope();
    LocalVariable* jump_var = top_scope->LookupVariable(
        Symbols::AwaitJumpVar(), false);
    ASSERT(jump_var != NULL && jump_var->is_captured());
    Instruction* saved_entry = entry_;
    Instruction* saved_exit = exit_;
    entry_ = NULL;
    exit_ = NULL;

    LoadLocalNode* load_jump_count =
        new(Z) LoadLocalNode(Scanner::kNoSourcePos, jump_var);
    ComparisonNode* check_jump_count;
    const intptr_t num_await_states = owner()->await_joins()->length();

    LocalVariable* old_context = top_scope->LookupVariable(
        Symbols::AwaitContextVar(), false);
    for (intptr_t i = 0; i < num_await_states; i++) {
      check_jump_count = new(Z) ComparisonNode(
          Scanner::kNoSourcePos,
          Token::kEQ,
          load_jump_count,
          new(Z) LiteralNode(
              Scanner::kNoSourcePos, Smi::ZoneHandle(Z, Smi::New(i))));
      TestGraphVisitor for_test(owner(), Scanner::kNoSourcePos);
      check_jump_count->Visit(&for_test);
      EffectGraphVisitor for_true(owner());
      EffectGraphVisitor for_false(owner());

      if (function.IsAsyncClosure() || function.IsAsyncGenClosure()) {
        LocalVariable* result_param =
            top_scope->LookupVariable(Symbols::AsyncOperationParam(), false);
        LocalVariable* error_param =
            top_scope->LookupVariable(Symbols::AsyncOperationErrorParam(),
                                      false);
        LocalVariable* stack_trace_param =
            top_scope->LookupVariable(Symbols::AsyncOperationStackTraceParam(),
                                      false);
        for_true.BuildAsyncJump(old_context,
                                result_param,
                                error_param,
                                stack_trace_param,
                                (*owner()->await_levels())[i],
                                (*owner()->await_joins())[i]);
      } else {
        ASSERT(function.IsSyncGenClosure());
        LocalVariable* iterator_param =
            top_scope->LookupVariable(Symbols::IteratorParameter(), false);
        for_true.BuildSyncYieldJump(old_context,
                                    iterator_param,
                                    (*owner()->await_levels())[i],
                                    (*owner()->await_joins())[i]);
      }

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

  if (is_open() &&
      (num_context_variables > 0) &&
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
  BuildRestoreContext(node->context_var());

  EffectGraphVisitor for_catch(owner());
  node->VisitChildren(&for_catch);
  Append(for_catch);
}


void EffectGraphVisitor::VisitTryCatchNode(TryCatchNode* node) {
  InlineBailout("EffectGraphVisitor::VisitTryCatchNode (exception)");
  intptr_t original_handler_index = owner()->try_index();
  const intptr_t try_handler_index = node->try_index();
  ASSERT(try_handler_index != original_handler_index);
  owner()->set_try_index(try_handler_index);

  // Preserve current context into local variable ':saved_try_context_var'.
  BuildSaveContext(node->context_var());

  EffectGraphVisitor for_try(owner());
  node->try_block()->Visit(&for_try);

  if (for_try.is_open()) {
    JoinEntryInstr* after_try =
        new(Z) JoinEntryInstr(owner()->AllocateBlockId(),
                              original_handler_index);
    for_try.Goto(after_try);
    for_try.exit_ = after_try;
  }

  JoinEntryInstr* try_entry =
      new(Z) JoinEntryInstr(owner()->AllocateBlockId(), try_handler_index);

  Goto(try_entry);
  AppendFragment(try_entry, for_try);
  exit_ = for_try.exit_;

  // We are done generating code for the try block.
  owner()->set_try_index(original_handler_index);

  CatchClauseNode* catch_block = node->catch_block();
  SequenceNode* finally_block = node->finally_block();

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

  CatchBlockEntryInstr* catch_entry =
      new(Z) CatchBlockEntryInstr(owner()->AllocateBlockId(),
                                  catch_handler_index,
                                  catch_block->handler_types(),
                                  try_handler_index,
                                  catch_block->exception_var(),
                                  catch_block->stacktrace_var(),
                                  catch_block->needs_stacktrace());
  owner()->AddCatchEntry(catch_entry);
  AppendFragment(catch_entry, for_catch);

  if (for_catch.is_open()) {
    JoinEntryInstr* join = new(Z) JoinEntryInstr(owner()->AllocateBlockId(),
                                                 original_handler_index);
    for_catch.Goto(join);
    if (is_open()) Goto(join);
    exit_ = join;
  }

  if (finally_block != NULL) {
    // Create a handler for the code in the catch block, containing the
    // code in the finally block.
    owner()->set_try_index(original_handler_index);
    EffectGraphVisitor for_finally(owner());
    for_finally.BuildRestoreContext(catch_block->context_var());

    finally_block->Visit(&for_finally);
    if (for_finally.is_open()) {
      // Rethrow the exception.  Manually build the graph for rethrow.
      Value* exception = for_finally.Bind(
          for_finally.BuildLoadLocal(catch_block->rethrow_exception_var()));
      for_finally.PushArgument(exception);
      Value* stacktrace = for_finally.Bind(
          for_finally.BuildLoadLocal(catch_block->rethrow_stacktrace_var()));
      for_finally.PushArgument(stacktrace);
      for_finally.AddInstruction(
          new(Z) ReThrowInstr(catch_block->token_pos(), catch_handler_index));
      for_finally.CloseFragment();
    }
    ASSERT(!for_finally.is_open());

    const Array& types = Array::ZoneHandle(Z, Array::New(1, Heap::kOld));
    types.SetAt(0, Type::Handle(Z, Type::DynamicType()));
    CatchBlockEntryInstr* finally_entry =
        new(Z) CatchBlockEntryInstr(owner()->AllocateBlockId(),
                                    original_handler_index,
                                    types,
                                    catch_handler_index,
                                    catch_block->exception_var(),
                                    catch_block->stacktrace_var(),
                                    catch_block->needs_stacktrace());
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
  intptr_t args_pos = method_arguments->token_pos();
  LocalVariable* temp = NULL;
  if (save_last_arg) {
    temp = owner()->parsed_function().expression_temp_var();
  }
  ArgumentListNode* args =
      Parser::BuildNoSuchMethodArguments(args_pos,
                                         method_name,
                                         *method_arguments,
                                         temp,
                                         is_super_invocation);
  const Function& no_such_method_func = Function::ZoneHandle(Z,
      Resolver::ResolveDynamicAnyArgs(target_class, Symbols::NoSuchMethod()));
  // We are guaranteed to find noSuchMethod of class Object.
  ASSERT(!no_such_method_func.IsNull());
  ZoneGrowableArray<PushArgumentInstr*>* push_arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildPushArguments(*args, push_arguments);
  return new(Z) StaticCallInstr(args_pos,
                                no_such_method_func,
                                Object::null_array(),
                                push_arguments,
                                owner()->ic_data_array());
}


StaticCallInstr* EffectGraphVisitor::BuildThrowNoSuchMethodError(
    intptr_t token_pos,
    const Class& function_class,
    const String& function_name,
    ArgumentListNode* function_arguments,
    int invocation_type) {
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new(Z) ZoneGrowableArray<PushArgumentInstr*>();
  // Object receiver, actually a class literal of the unresolved method's owner.
  Type& type = Type::ZoneHandle(
      Z,
      Type::New(function_class,
                TypeArguments::Handle(Z, TypeArguments::null()),
                token_pos,
                Heap::kOld));
  type ^= ClassFinalizer::FinalizeType(
      function_class, type, ClassFinalizer::kCanonicalize);
  Value* receiver_value = Bind(new(Z) ConstantInstr(type));
  arguments->Add(PushArgument(receiver_value));
  // String memberName.
  const String& member_name =
      String::ZoneHandle(Z, Symbols::New(function_name));
  Value* member_name_value = Bind(new(Z) ConstantInstr(member_name));
  arguments->Add(PushArgument(member_name_value));
  // Smi invocation_type.
  Value* invocation_type_value = Bind(new(Z) ConstantInstr(
      Smi::ZoneHandle(Z, Smi::New(invocation_type))));
  arguments->Add(PushArgument(invocation_type_value));
  // List arguments.
  if (function_arguments == NULL) {
    Value* arguments_value = Bind(
        new(Z) ConstantInstr(Array::ZoneHandle(Z, Array::null())));
    arguments->Add(PushArgument(arguments_value));
  } else {
    ValueGraphVisitor array_val(owner());
    ArrayNode* array =
        new(Z) ArrayNode(token_pos, Type::ZoneHandle(Z, Type::ArrayType()),
                      function_arguments->nodes());
    array->Visit(&array_val);
    Append(array_val);
    arguments->Add(PushArgument(array_val.value()));
  }
  // List argumentNames.
  ConstantInstr* cinstr = new(Z) ConstantInstr(
      (function_arguments == NULL) ? Array::ZoneHandle(Z, Array::null())
                                   : function_arguments->names());
  Value* argument_names_value = Bind(cinstr);
  arguments->Add(PushArgument(argument_names_value));

  // List existingArgumentNames.
  Value* existing_argument_names_value =
      Bind(new(Z) ConstantInstr(Array::ZoneHandle(Z, Array::null())));
  arguments->Add(PushArgument(existing_argument_names_value));
  // Resolve and call NoSuchMethodError._throwNew.
  const Library& core_lib = Library::Handle(Z, Library::CoreLibrary());
  const Class& cls = Class::Handle(
      Z, core_lib.LookupClass(Symbols::NoSuchMethodError()));
  ASSERT(!cls.IsNull());
  const Function& func = Function::ZoneHandle(
      Z,
      Resolver::ResolveStatic(cls,
                              Library::PrivateCoreLibName(Symbols::ThrowNew()),
                              arguments->length(),
                              Object::null_array()));
  ASSERT(!func.IsNull());
  return new(Z) StaticCallInstr(token_pos,
                                func,
                                Object::null_array(),  // No names.
                                arguments,
                                owner()->ic_data_array());
}


void EffectGraphVisitor::BuildThrowNode(ThrowNode* node) {
  if (FLAG_support_debugger) {
    if (node->exception()->IsLiteralNode() ||
        node->exception()->IsLoadLocalNode() ||
        node->exception()->IsClosureNode()) {
      AddInstruction(new(Z) DebugStepCheckInstr(
          node->token_pos(), RawPcDescriptors::kRuntimeCall));
    }
  }
  ValueGraphVisitor for_exception(owner());
  node->exception()->Visit(&for_exception);
  Append(for_exception);
  PushArgument(for_exception.value());
  Instruction* instr = NULL;
  if (node->stacktrace() == NULL) {
    instr = new(Z) ThrowInstr(node->token_pos());
  } else {
    ValueGraphVisitor for_stack_trace(owner());
    node->stacktrace()->Visit(&for_stack_trace);
    Append(for_stack_trace);
    PushArgument(for_stack_trace.value());
    instr = new(Z) ReThrowInstr(node->token_pos(), owner()->catch_try_index());
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
  ReturnDefinition(new(Z) ConstantInstr(
      Instance::ZoneHandle(Z, Instance::null())));
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
      new(Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index());
  EffectGraphVisitor for_finally_block(owner());
  for_finally_block.AdjustContextLevel(node->finally_block()->scope());
  node->finally_block()->Visit(&for_finally_block);

  if (try_index >= 0) {
    owner()->set_try_index(try_index);
  }

  if (for_finally_block.is_open()) {
    JoinEntryInstr* after_finally =
        new(Z) JoinEntryInstr(owner()->AllocateBlockId(), owner()->try_index());
    for_finally_block.Goto(after_finally);
    for_finally_block.exit_ = after_finally;
  }

  Goto(finally_entry);
  AppendFragment(finally_entry, for_finally_block);
  exit_ = for_finally_block.exit_;
}


void EffectGraphVisitor::VisitStopNode(StopNode* node) {
  AddInstruction(new(Z) StopInstr(node->message()));
}


FlowGraph* FlowGraphBuilder::BuildGraph() {
  VMTagScope tagScope(Thread::Current(),
                      VMTag::kCompileFlowGraphBuilderTagId,
                      FLAG_profile_vm);
  if (FLAG_print_ast) {
    // Print the function ast before IL generation.
    AstPrinter::PrintFunctionNodes(parsed_function());
  }
  if (FLAG_print_scopes) {
    AstPrinter::PrintFunctionScope(parsed_function());
  }
  TargetEntryInstr* normal_entry =
      new(Z) TargetEntryInstr(AllocateBlockId(),
                              CatchClauseNode::kInvalidTryIndex);
  graph_entry_ =
      new(Z) GraphEntryInstr(parsed_function(), normal_entry, osr_id_);
  EffectGraphVisitor for_effect(this);
  parsed_function().node_sequence()->Visit(&for_effect);
  AppendFragment(normal_entry, for_effect);
  // Check that the graph is properly terminated.
  ASSERT(!for_effect.is_open());

  // When compiling for OSR, use a depth first search to prune instructions
  // unreachable from the OSR entry. Catch entries are always considered
  // reachable, even if they become unreachable after OSR.
  if (osr_id_ != Isolate::kNoDeoptId) {
    PruneUnreachable();
  }

  FlowGraph* graph =
      new(Z) FlowGraph(parsed_function(), graph_entry_, last_used_block_id_);
  return graph;
}


void FlowGraphBuilder::PruneUnreachable() {
  ASSERT(osr_id_ != Isolate::kNoDeoptId);
  BitVector* block_marks = new(Z) BitVector(Z, last_used_block_id_ + 1);
  bool found = graph_entry_->PruneUnreachable(this, graph_entry_, NULL, osr_id_,
                                              block_marks);
  ASSERT(found);
}


void FlowGraphBuilder::Bailout(const char* reason) const {
  const Function& function = parsed_function_.function();
  Report::MessageF(Report::kBailout,
                   Script::Handle(function.script()),
                   function.token_pos(),
                   "FlowGraphBuilder Bailout: %s %s",
                   String::Handle(function.name()).ToCString(),
                   reason);
  UNREACHABLE();
}

}  // namespace dart
