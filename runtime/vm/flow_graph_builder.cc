// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_builder.h"

#include "vm/ast_printer.h"
#include "vm/code_descriptors.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/il_printer.h"
#include "vm/intermediate_language.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, eliminate_type_checks, true,
            "Eliminate type checks when allowed by static type analysis.");
DEFINE_FLAG(bool, print_ast, false, "Print abstract syntax tree.");
DEFINE_FLAG(bool, print_flow_graph, false, "Print the IR flow graph.");
DEFINE_FLAG(bool, trace_type_check_elimination, false,
            "Trace type check elimination at compile time.");
DECLARE_FLAG(bool, enable_type_checks);


FlowGraphBuilder::FlowGraphBuilder(const ParsedFunction& parsed_function)
  : parsed_function_(parsed_function),
    copied_parameter_count_(parsed_function.copied_parameter_count()),
    // All parameters are copied if any parameter is.
    non_copied_parameter_count_((copied_parameter_count_ == 0)
        ? parsed_function.function().num_fixed_parameters()
        : 0),
    stack_local_count_(parsed_function.stack_local_count()),
    context_level_(0),
    last_used_try_index_(CatchClauseNode::kInvalidTryIndex),
    try_index_(CatchClauseNode::kInvalidTryIndex),
    graph_entry_(NULL),
    inlining_context_(kNotInlining),
    exits_(NULL) { }


void FlowGraphBuilder::AddCatchEntry(TargetEntryInstr* entry) {
  graph_entry_->AddCatchEntry(entry);
}


void EffectGraphVisitor::Append(const EffectGraphVisitor& other_fragment) {
  ASSERT(is_open());
  if (other_fragment.is_empty()) return;
  if (is_empty()) {
    entry_ = other_fragment.entry();
    exit_ = other_fragment.exit();
  } else {
    exit()->set_next(other_fragment.entry());
    exit_ = other_fragment.exit();
  }
  temp_index_ = other_fragment.temp_index();
}


Value* EffectGraphVisitor::Bind(Computation* computation) {
  ASSERT(is_open());
  DeallocateTempIndex(computation->InputCount());
  BindInstr* bind_instr = new BindInstr(Definition::kValue, computation);
  bind_instr->set_temp_index(AllocateTempIndex());
  if (is_empty()) {
    entry_ = bind_instr;
  } else {
    exit()->set_next(bind_instr);
  }
  exit_ = bind_instr;
  return new Value(bind_instr);
}


void EffectGraphVisitor::Do(Computation* computation) {
  ASSERT(is_open());
  DeallocateTempIndex(computation->InputCount());
  BindInstr* do_instr = new BindInstr(Definition::kEffect, computation);
  if (is_empty()) {
    entry_ = do_instr;
  } else {
    exit()->set_next(do_instr);
  }
  exit_ = do_instr;
}


void EffectGraphVisitor::AddInstruction(Instruction* instruction) {
  ASSERT(is_open());
  ASSERT(!instruction->IsBind());
  ASSERT(!instruction->IsBlockEntry());
  DeallocateTempIndex(instruction->InputCount());
  if (is_empty()) {
    entry_ = exit_ = instruction;
  } else {
    exit()->set_next(instruction);
    exit_ = instruction;
  }
}


void EffectGraphVisitor::Goto(JoinEntryInstr* join) {
  ASSERT(is_open());
  if (is_empty()) {
    entry_ = new GotoInstr(join);
  } else {
    exit()->Goto(join);
  }
  exit_ = NULL;
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
  entry->set_next(fragment.entry());
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
  TargetEntryInstr* true_entry = new TargetEntryInstr(owner()->try_index());
  *test_fragment.true_successor_address() = true_entry;
  Instruction* true_exit = AppendFragment(true_entry, true_fragment);

  TargetEntryInstr* false_entry = new TargetEntryInstr(owner()->try_index());
  *test_fragment.false_successor_address() = false_entry;
  Instruction* false_exit = AppendFragment(false_entry, false_fragment);

  // 3. Add a join or select one (or neither) of the arms as exit.
  if (true_exit == NULL) {
    exit_ = false_exit;  // May be NULL.
    if (false_exit != NULL) temp_index_ = false_fragment.temp_index();
  } else if (false_exit == NULL) {
    exit_ = true_exit;
    temp_index_ = true_fragment.temp_index();
  } else {
    JoinEntryInstr* join = new JoinEntryInstr(owner()->try_index());
    true_exit->Goto(join);
    false_exit->Goto(join);
    exit_ = join;
    ASSERT(true_fragment.temp_index() == false_fragment.temp_index());
    temp_index_ = true_fragment.temp_index();
  }
}


void EffectGraphVisitor::TieLoop(const TestGraphVisitor& test_fragment,
                                 const EffectGraphVisitor& body_fragment) {
  // We have: a test graph fragment with zero, one, or two available exits;
  // and an effect graph fragment with zero or one available exits.  We want
  // to append the 'while loop' consisting of the test graph fragment as
  // condition and the effect graph fragment as body.
  ASSERT(is_open());

  // 1. Connect the body to the test if it is reachable, and if so record
  // its exit (if any).
  TargetEntryInstr* body_entry = new TargetEntryInstr(owner()->try_index());
  *test_fragment.true_successor_address() = body_entry;
  Instruction* body_exit = AppendFragment(body_entry, body_fragment);

  // 2. Connect the test to this graph, including the body if reachable and
  // using a fresh join node if the body is reachable and has an open exit.
  if (body_exit == NULL) {
    Append(test_fragment);
  } else {
    JoinEntryInstr* join = new JoinEntryInstr(owner()->try_index());
    join->set_next(test_fragment.entry());
    Goto(join);
    body_exit->Goto(join);
  }

  // 3. Set the exit to the graph to be the false successor of the test, a
  // fresh target node
  exit_ = *test_fragment.false_successor_address() =
      new TargetEntryInstr(owner()->try_index());
}


PushArgumentInstr* EffectGraphVisitor::PushArgument(Value* value) {
  PushArgumentInstr* result = new PushArgumentInstr(value);
  AddInstruction(result);
  return result;
}


Computation* EffectGraphVisitor::BuildStoreLocal(
    const LocalVariable& local, Value* value) {
  if (local.is_captured()) {
    intptr_t delta = owner()->context_level() -
                     local.owner()->context_level();
    ASSERT(delta >= 0);
    Value* context = Bind(new CurrentContextComp());
    while (delta-- > 0) {
      context = Bind(new LoadVMFieldComp(
          context, Context::parent_offset(), Type::ZoneHandle()));
    }
    return new StoreVMFieldComp(
        context,
        Context::variable_offset(local.index()),
        value,
        local.type());
  } else {
    return new StoreLocalComp(local, value, owner()->context_level());
  }
}


Computation* EffectGraphVisitor::BuildLoadLocal(const LocalVariable& local) {
  if (local.is_captured()) {
    intptr_t delta = owner()->context_level() -
                     local.owner()->context_level();
    ASSERT(delta >= 0);
    Value* context = Bind(new CurrentContextComp());
    while (delta-- > 0) {
      context = Bind(new LoadVMFieldComp(
          context, Context::parent_offset(), Type::ZoneHandle()));
    }
    return new LoadVMFieldComp(context,
                               Context::variable_offset(local.index()),
                               local.type());
  } else {
    return new LoadLocalComp(local, owner()->context_level());
  }
}


// Stores current context into the 'variable'
void EffectGraphVisitor::BuildStoreContext(const LocalVariable& variable) {
  Value* context = Bind(new CurrentContextComp());
  Do(BuildStoreLocal(variable, context));
}


// Loads context saved in 'context_variable' into the current context.
void EffectGraphVisitor::BuildLoadContext(const LocalVariable& variable) {
  Value* load_saved_context = Bind(BuildLoadLocal(variable));
  Do(new StoreContextComp(load_saved_context));
}


void TestGraphVisitor::ReturnValue(Value* value) {
  if (FLAG_enable_type_checks) {
    value = Bind(new AssertBooleanComp(condition_token_pos(), value));
  }
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  Value* constant_true = Bind(new ConstantComp(bool_true));
  StrictCompareComp* comp =
      new StrictCompareComp(Token::kEQ_STRICT, value, constant_true);
  BranchInstr* branch = new BranchInstr(comp);
  AddInstruction(branch);
  CloseFragment();
  true_successor_address_ = branch->true_successor_address();
  false_successor_address_ = branch->false_successor_address();
}


void TestGraphVisitor::MergeBranchWithComparison(ComparisonComp* comp) {
  ASSERT(!FLAG_enable_type_checks);
  ControlInstruction* branch;
  if (Token::IsStrictEqualityOperator(comp->kind())) {
    branch = new BranchInstr(new StrictCompareComp(comp->kind(),
                                                   comp->left(),
                                                   comp->right()));
  } else if (Token::IsEqualityOperator(comp->kind()) &&
             (comp->left()->BindsToConstantNull() ||
              comp->right()->BindsToConstantNull())) {
    branch = new BranchInstr(new StrictCompareComp(
        (comp->kind() == Token::kEQ) ? Token::kEQ_STRICT : Token::kNE_STRICT,
        comp->left(),
        comp->right()));
  } else {
    branch = new BranchInstr(comp);
  }
  AddInstruction(branch);
  CloseFragment();
  true_successor_address_ = branch->true_successor_address();
  false_successor_address_ = branch->false_successor_address();
}


void TestGraphVisitor::MergeBranchWithNegate(BooleanNegateComp* comp) {
  ASSERT(!FLAG_enable_type_checks);
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  Value* constant_true = Bind(new ConstantComp(bool_true));
  BranchInstr* branch = new BranchInstr(
      new StrictCompareComp(Token::kNE_STRICT,
                            comp->value(),
                            constant_true));
  AddInstruction(branch);
  CloseFragment();
  true_successor_address_ = branch->true_successor_address();
  false_successor_address_ = branch->false_successor_address();
}


void TestGraphVisitor::ReturnComputation(Computation* computation) {
  if (!FLAG_enable_type_checks) {
    if (computation->AsComparison() != NULL) {
      MergeBranchWithComparison(computation->AsComparison());
      return;
    }
    if (computation->IsBooleanNegate()) {
      MergeBranchWithNegate(computation->AsBooleanNegate());
      return;
    }
  }
  ReturnValue(Bind(computation));
}


void EffectGraphVisitor::Bailout(const char* reason) {
  owner()->Bailout(reason);
}


void EffectGraphVisitor::InlineBailout(const char* reason) {
  if (owner()->InInliningContext()) owner()->Bailout(reason);
}


// <Statement> ::= Return { value:                <Expression>
//                          inlined_finally_list: <InlinedFinally>* }
void EffectGraphVisitor::VisitReturnNode(ReturnNode* node) {
  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);

  for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
    InlineBailout("EffectGraphVisitor::VisitReturnNode (finally)");
    EffectGraphVisitor for_effect(owner(), temp_index());
    node->InlinedFinallyNodeAt(i)->Visit(&for_effect);
    Append(for_effect);
    if (!is_open()) return;
  }

  Value* return_value = for_value.value();
  if (FLAG_enable_type_checks) {
    InlineBailout("EffectGraphVisitor::VisitReturnNode (type check)");
    const Function& function = owner()->parsed_function().function();
    const bool is_implicit_dynamic_getter =
        (!function.is_static() &&
        ((function.kind() == RawFunction::kImplicitGetter) ||
         (function.kind() == RawFunction::kConstImplicitGetter)));
    // Implicit getters do not need a type check at return, unless they compute
    // the initial value of a static field.
    // The body of a constructor cannot modify the type of the
    // constructed instance, which is passed in as an implicit parameter.
    // However, factories may create an instance of the wrong type.
    if (!is_implicit_dynamic_getter && !function.IsConstructor()) {
      const AbstractType& dst_type =
          AbstractType::ZoneHandle(
              owner()->parsed_function().function().result_type());
      const String& dst_name =
          String::ZoneHandle(Symbols::New("function result"));
      return_value = BuildAssignableValue(node->value()->token_pos(),
                                          return_value,
                                          dst_type,
                                          dst_name);
    }
  }

  intptr_t current_context_level = owner()->context_level();
  ASSERT(current_context_level >= 0);
  if (owner()->parsed_function().saved_context_var() != NULL) {
    // CTX on entry was saved, but not linked as context parent.
    BuildLoadContext(*owner()->parsed_function().saved_context_var());
  } else {
    while (current_context_level-- > 0) {
      UnchainContext();
    }
  }

  ReturnInstr* return_instr = new ReturnInstr(node->token_pos(), return_value);
  AddReturnExit(return_instr);
  AddInstruction(return_instr);
  CloseFragment();
}


// <Expression> ::= Literal { literal: Instance }
void EffectGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  return;
}


void ValueGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  ReturnComputation(new ConstantComp(node->literal()));
}


// Type nodes only occur as the right-hand side of instanceof comparisons,
// and they are handled specially in that context.
void EffectGraphVisitor::VisitTypeNode(TypeNode* node) { UNREACHABLE(); }


// Returns true if the type check can be skipped, for example, if the
// destination type is Dynamic or if the compile type of the value is a subtype
// of the destination type.
bool EffectGraphVisitor::CanSkipTypeCheck(intptr_t token_pos,
                                          Value* value,
                                          const AbstractType& dst_type,
                                          const String& dst_name) {
  InlineBailout("EffectGraphVisitor::CanSkipTypeCheck");
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());

  // If the destination type is malformed, a dynamic type error must be thrown
  // at run time.
  if (dst_type.IsMalformed()) {
    return false;
  }

  // Any type is more specific than the Dynamic type and than the Object type.
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

  // Propagated types are not set yet.
  // More checks will possibly be eliminated during type propagation.
  const bool eliminated = value->CompileTypeIsMoreSpecificThan(dst_type);
  // Note: 'eliminated' is true for a null constant value, since its type,
  // i.e. bottom type, is more specific than any type.
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
  InlineBailout("EffectGraphVisitor::VisitAssignableNode");
  UNREACHABLE();
}


void ValueGraphVisitor::VisitAssignableNode(AssignableNode* node) {
  InlineBailout("ValueGraphVisitor::VisitAssignableNode");
  ValueGraphVisitor for_value(owner(), temp_index());
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
  InlineBailout("EffectGraphVisitor::VisitBinaryOpNode");
  // Operators "&&" and "||" cannot be overloaded therefore do not call
  // operator.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    // See ValueGraphVisitor::VisitBinaryOpNode.
    TestGraphVisitor for_left(owner(),
                              temp_index(),
                              node->left()->token_pos());
    node->left()->Visit(&for_left);
    EffectGraphVisitor for_right(owner(), temp_index());
    node->right()->Visit(&for_right);
    EffectGraphVisitor empty(owner(), temp_index());
    if (node->kind() == Token::kAND) {
      Join(for_left, for_right, empty);
    } else {
      Join(for_left, empty, for_right);
    }
    return;
  }
  ValueGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  PushArgumentInstr* push_left = PushArgument(for_left_value.value());

  ValueGraphVisitor for_right_value(owner(), temp_index());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  PushArgumentInstr* push_right = PushArgument(for_right_value.value());

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  arguments->Add(push_left);
  arguments->Add(push_right);
  const String& name = String::ZoneHandle(Symbols::New(node->Name()));
  InstanceCallComp* call = new InstanceCallComp(node->token_pos(),
                                                name,
                                                node->kind(),
                                                arguments,
                                                Array::ZoneHandle(),
                                                2);
  ReturnComputation(call);
}


// Special handling for AND/OR.
void ValueGraphVisitor::VisitBinaryOpNode(BinaryOpNode* node) {
  InlineBailout("ValueGraphVisitor::VisitBinaryOpNode");
  // Operators "&&" and "||" cannot be overloaded therefore do not call
  // operator.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    // Implement short-circuit logic: do not evaluate right if evaluation
    // of left is sufficient.
    // AND:  left ? right === true : false;
    // OR:   left ? true : right === true;
    const Bool& bool_true = Bool::ZoneHandle(Bool::True());
    const Bool& bool_false = Bool::ZoneHandle(Bool::False());

    TestGraphVisitor for_test(owner(),
                              temp_index(),
                              node->left()->token_pos());
    node->left()->Visit(&for_test);

    ValueGraphVisitor for_right(owner(), temp_index());
    node->right()->Visit(&for_right);
    Value* right_value = for_right.value();
    if (FLAG_enable_type_checks) {
      right_value =
          for_right.Bind(new AssertBooleanComp(node->right()->token_pos(),
                                               right_value));
    }
    Value* constant_true = for_right.Bind(new ConstantComp(bool_true));
    Value* compare =
        for_right.Bind(new StrictCompareComp(Token::kEQ_STRICT,
                                             right_value,
                                             constant_true));
    for_right.Do(BuildStoreLocal(
        *owner()->parsed_function().expression_temp_var(),
        compare));

    if (node->kind() == Token::kAND) {
      ValueGraphVisitor for_false(owner(), temp_index());
      Value* constant_false = for_false.Bind(new ConstantComp(bool_false));
      for_false.Do(BuildStoreLocal(
          *owner()->parsed_function().expression_temp_var(),
          constant_false));
      Join(for_test, for_right, for_false);
    } else {
      ASSERT(node->kind() == Token::kOR);
      ValueGraphVisitor for_true(owner(), temp_index());
      Value* constant_true = for_true.Bind(new ConstantComp(bool_true));
      for_true.Do(BuildStoreLocal(
          *owner()->parsed_function().expression_temp_var(),
          constant_true));
      Join(for_test, for_true, for_right);
    }
    ReturnComputation(
        BuildLoadLocal(*owner()->parsed_function().expression_temp_var()));
    return;
  }
  EffectGraphVisitor::VisitBinaryOpNode(node);
}


void EffectGraphVisitor::BuildTypecheckArguments(
    intptr_t token_pos,
    Value** instantiator_result,
    Value** instantiator_type_arguments_result) {
  InlineBailout("EffectGraphVisitor::VisitBinaryOpNode");
  Value* instantiator = NULL;
  Value* instantiator_type_arguments = NULL;
  const Class& instantiator_class = Class::Handle(
      owner()->parsed_function().function().Owner());
  // Since called only when type tested against is not instantiated.
  ASSERT(instantiator_class.NumTypeParameters() > 0);
  instantiator = BuildInstantiator();
  if (instantiator == NULL) {
    // No instantiator when inside factory.
    instantiator = BuildNullValue();
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_pos, NULL);
  } else {
    // Preserve instantiator.
    const LocalVariable& expr_temp =
        *owner()->parsed_function().expression_temp_var();
    instantiator = Bind(BuildStoreLocal(expr_temp, instantiator));
    Value* loaded = Bind(BuildLoadLocal(expr_temp));
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_pos, loaded);
  }
  *instantiator_result = instantiator;
  *instantiator_type_arguments_result = instantiator_type_arguments;
}


Value* EffectGraphVisitor::BuildNullValue() {
  InlineBailout("EffectGraphVisitor::BuildNullValue");
  return Bind(new ConstantComp(Object::ZoneHandle()));
}


// Used for testing incoming arguments.
AssertAssignableComp* EffectGraphVisitor::BuildAssertAssignable(
    intptr_t token_pos,
    Value* value,
    const AbstractType& dst_type,
    const String& dst_name) {
  InlineBailout("EffectGraphVisitor::BuildAssertAssignable");
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
  return new AssertAssignableComp(token_pos,
                                  value,
                                  instantiator,
                                  instantiator_type_arguments,
                                  dst_type,
                                  dst_name);
}


// Used for type casts and to test assignments.
Value* EffectGraphVisitor::BuildAssignableValue(intptr_t token_pos,
                                                Value* value,
                                                const AbstractType& dst_type,
                                                const String& dst_name) {
  InlineBailout("EffectGraphVisitor::BuildAssignableValue");
  if (CanSkipTypeCheck(token_pos, value, dst_type, dst_name)) {
    return value;
  }
  return Bind(BuildAssertAssignable(token_pos, value, dst_type, dst_name));
}


void EffectGraphVisitor::BuildTypeTest(ComparisonNode* node) {
  InlineBailout("EffectGraphVisitor::BuildTypeTest");
  ASSERT(Token::IsTypeTestOperator(node->kind()));
  EffectGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
}


void EffectGraphVisitor::BuildTypeCast(ComparisonNode* node) {
  InlineBailout("EffectGraphVisitor::BuildTypeCast");
  ASSERT(Token::IsTypeCastOperator(node->kind()));
  const AbstractType& type = node->right()->AsTypeNode()->type();
  ASSERT(type.IsFinalized());  // The type in a type cast may be malformed.
  ValueGraphVisitor for_value(owner(), temp_index());
  node->left()->Visit(&for_value);
  Append(for_value);
  const String& dst_name = String::ZoneHandle(
      Symbols::New(Exceptions::kCastExceptionDstName));
  if (!CanSkipTypeCheck(node->token_pos(), for_value.value(), type, dst_name)) {
    Do(BuildAssertAssignable(
        node->token_pos(), for_value.value(), type, dst_name));
  }
}


void ValueGraphVisitor::BuildTypeTest(ComparisonNode* node) {
  InlineBailout("ValueGraphVisitor::BuildTypeTest");
  ASSERT(Token::IsTypeTestOperator(node->kind()));
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  const AbstractType& type = node->right()->AsTypeNode()->type();
  ASSERT(type.IsFinalized() && !type.IsMalformed());
  const bool negate_result = (node->kind() == Token::kISNOT);
  // All objects are instances of type T if Object type is a subtype of type T.
  const Type& object_type = Type::Handle(Type::ObjectType());
  if (type.IsInstantiated() && object_type.IsSubtypeOf(type, NULL)) {
    // Must evaluate left side.
    EffectGraphVisitor for_left_value(owner(), temp_index());
    node->left()->Visit(&for_left_value);
    Append(for_left_value);
    ReturnComputation(new ConstantComp(negate_result ? bool_false : bool_true));
    return;
  }

  // Eliminate the test if it can be performed successfully at compile time.
  if ((node->left() != NULL) &&
      node->left()->IsLiteralNode() &&
      type.IsInstantiated()) {
    const Instance& literal_value = node->left()->AsLiteralNode()->literal();
    const Class& cls = Class::Handle(literal_value.clazz());
    ConstantComp* result = NULL;
    if (cls.IsNullClass()) {
      // A null object is only an instance of Object and Dynamic, which has
      // already been checked above (if the type is instantiated). So we can
      // return false here if the instance is null (and if the type is
      // instantiated).
      result = new ConstantComp(negate_result ? bool_true : bool_false);
    } else {
      if (literal_value.IsInstanceOf(type, TypeArguments::Handle(), NULL)) {
        result = new ConstantComp(negate_result ? bool_false : bool_true);
      } else {
        result = new ConstantComp(negate_result ? bool_true : bool_false);
      }
    }
    ReturnComputation(result);
    return;
  }

  ValueGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  Value* instantiator = NULL;
  Value* instantiator_type_arguments = NULL;
  if (type.IsInstantiated()) {
    instantiator = BuildNullValue();
    instantiator_type_arguments = BuildNullValue();
  } else {
    BuildTypecheckArguments(node->token_pos(),
                            &instantiator,
                            &instantiator_type_arguments);
  }
  InstanceOfComp* instance_of =
      new InstanceOfComp(node->token_pos(),
                         for_left_value.value(),
                         instantiator,
                         instantiator_type_arguments,
                         node->right()->AsTypeNode()->type(),
                         (node->kind() == Token::kISNOT));
  ReturnComputation(instance_of);
}


void ValueGraphVisitor::BuildTypeCast(ComparisonNode* node) {
  InlineBailout("ValueGraphVisitor::BuildTypeCast");
  ASSERT(Token::IsTypeCastOperator(node->kind()));
  const AbstractType& type = node->right()->AsTypeNode()->type();
  ASSERT(type.IsFinalized());  // The type in a type cast may be malformed.
  ValueGraphVisitor for_value(owner(), temp_index());
  node->left()->Visit(&for_value);
  Append(for_value);
  const String& dst_name = String::ZoneHandle(
      Symbols::New(Exceptions::kCastExceptionDstName));
  ReturnValue(BuildAssignableValue(node->token_pos(),
                                   for_value.value(),
                                   type,
                                   dst_name));
}


// <Expression> :: Comparison { kind:  Token::Kind
//                              left:  <Expression>
//                              right: <Expression> }
// TODO(srdjan): Implement new equality.
void EffectGraphVisitor::VisitComparisonNode(ComparisonNode* node) {
  InlineBailout("EffectGraphVisitor::VisitComparisonNode");
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
    ValueGraphVisitor for_left_value(owner(), temp_index());
    node->left()->Visit(&for_left_value);
    Append(for_left_value);
    ValueGraphVisitor for_right_value(owner(), temp_index());
    node->right()->Visit(&for_right_value);
    Append(for_right_value);
    StrictCompareComp* comp = new StrictCompareComp(
        node->kind(), for_left_value.value(), for_right_value.value());
    ReturnComputation(comp);
    return;
  }

  if ((node->kind() == Token::kEQ) || (node->kind() == Token::kNE)) {
    ValueGraphVisitor for_left_value(owner(), temp_index());
    node->left()->Visit(&for_left_value);
    Append(for_left_value);
    ValueGraphVisitor for_right_value(owner(), temp_index());
    node->right()->Visit(&for_right_value);
    Append(for_right_value);
    if (FLAG_enable_type_checks) {
      EqualityCompareComp* comp = new EqualityCompareComp(
          node->token_pos(),
          Token::kEQ,
          for_left_value.value(),
          for_right_value.value());
      if (node->kind() == Token::kEQ) {
        ReturnComputation(comp);
      } else {
        Value* eq_result = Bind(comp);
        eq_result = Bind(new AssertBooleanComp(node->token_pos(), eq_result));
        ReturnComputation(new BooleanNegateComp(eq_result));
      }
    } else {
      EqualityCompareComp* comp = new EqualityCompareComp(
          node->token_pos(),
          node->kind(),
          for_left_value.value(),
          for_right_value.value());
      ReturnComputation(comp);
    }
    return;
  }

  ValueGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  ValueGraphVisitor for_right_value(owner(), temp_index());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  RelationalOpComp* comp = new RelationalOpComp(node->token_pos(),
                                                node->kind(),
                                                for_left_value.value(),
                                                for_right_value.value());
  ReturnComputation(comp);
}


void EffectGraphVisitor::VisitUnaryOpNode(UnaryOpNode* node) {
  InlineBailout("EffectGraphVisitor::VisitUnaryOpNode");
  // "!" cannot be overloaded, therefore do not call operator.
  if (node->kind() == Token::kNOT) {
    ValueGraphVisitor for_value(owner(), temp_index());
    node->operand()->Visit(&for_value);
    Append(for_value);
    Value* value = for_value.value();
    if (FLAG_enable_type_checks) {
      value =
          Bind(new AssertBooleanComp(node->operand()->token_pos(), value));
    }
    BooleanNegateComp* negate = new BooleanNegateComp(value);
    ReturnComputation(negate);
    return;
  }
  ValueGraphVisitor for_value(owner(), temp_index());
  node->operand()->Visit(&for_value);
  Append(for_value);
  PushArgumentInstr* push_value = PushArgument(for_value.value());
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(1);
  arguments->Add(push_value);
  String& name = String::ZoneHandle();
  if (node->kind() == Token::kSUB) {
    name = Symbols::New("unary-");
  } else {
    name = Symbols::New(Token::Str(node->kind()));
  }
  InstanceCallComp* call = new InstanceCallComp(
      node->token_pos(), name, node->kind(),
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  InlineBailout("EffectGraphVisitor::VisitConditionalExprNode");
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_pos());
  node->condition()->Visit(&for_test);

  // Translate the subexpressions for their effects.
  EffectGraphVisitor for_true(owner(), temp_index());
  node->true_expr()->Visit(&for_true);
  EffectGraphVisitor for_false(owner(), temp_index());
  node->false_expr()->Visit(&for_false);

  Join(for_test, for_true, for_false);
}


void ValueGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  InlineBailout("ValueGraphVisitor::VisitConditionalExprNode");
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_pos());
  node->condition()->Visit(&for_test);

  ValueGraphVisitor for_true(owner(), temp_index());
  node->true_expr()->Visit(&for_true);
  ASSERT(for_true.is_open());
  for_true.Do(BuildStoreLocal(
      *owner()->parsed_function().expression_temp_var(), for_true.value()));

  ValueGraphVisitor for_false(owner(), temp_index());
  node->false_expr()->Visit(&for_false);
  ASSERT(for_false.is_open());
  for_false.Do(BuildStoreLocal(
      *owner()->parsed_function().expression_temp_var(), for_false.value()));

  Join(for_test, for_true, for_false);
  ReturnComputation(
      BuildLoadLocal(*owner()->parsed_function().expression_temp_var()));
}


// <Statement> ::= If { condition: <Expression>
//                      true_branch: <Sequence>
//                      false_branch: <Sequence> }
void EffectGraphVisitor::VisitIfNode(IfNode* node) {
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_pos());
  node->condition()->Visit(&for_test);

  EffectGraphVisitor for_true(owner(), temp_index());
  EffectGraphVisitor for_false(owner(), temp_index());

  node->true_branch()->Visit(&for_true);
  // The for_false graph fragment will be empty (default graph fragment) if
  // we do not call Visit.
  if (node->false_branch() != NULL) node->false_branch()->Visit(&for_false);
  Join(for_test, for_true, for_false);
}


void EffectGraphVisitor::VisitSwitchNode(SwitchNode* node) {
  InlineBailout("EffectGraphVisitor::VisitSwitchNode");
  EffectGraphVisitor switch_body(owner(), temp_index());
  node->body()->Visit(&switch_body);
  Append(switch_body);
  if ((node->label() != NULL) && (node->label()->join_for_break() != NULL)) {
    if (is_open()) Goto(node->label()->join_for_break());
    exit_ = node->label()->join_for_break();
  }
  // No continue label allowed.
  ASSERT((node->label() == NULL) ||
         (node->label()->join_for_continue() == NULL));
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
  InlineBailout("EffectGraphVisitor::VisitCaseNode");
  const intptr_t len = node->case_expressions()->length();
  // Create case statements instructions.
  EffectGraphVisitor for_case_statements(owner(), temp_index());
  // Compute start of statements fragment.
  JoinEntryInstr* statement_start = NULL;
  if ((node->label() != NULL) && node->label()->is_continue_target()) {
    // Since a labeled jump continue statement occur in a different case node,
    // allocate JoinNode here and use it as statement start.
    statement_start = node->label()->join_for_continue();
    if (statement_start == NULL) {
      statement_start = new JoinEntryInstr(owner()->try_index());
      node->label()->set_join_for_continue(statement_start);
    }
  } else {
    statement_start = new JoinEntryInstr(owner()->try_index());
  }
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
  TargetEntryInstr** previous_false_address = NULL;
  for (intptr_t i = 0; i < len; i++) {
    AstNode* case_expr = node->case_expressions()->NodeAt(i);
    TestGraphVisitor for_case_expression(owner(),
                                         temp_index(),
                                         case_expr->token_pos());
    case_expr->Visit(&for_case_expression);
    if (i == 0) {
      // Append only the first one, everything else is connected from it.
      Append(for_case_expression);
    } else {
      TargetEntryInstr* case_entry_target =
          new TargetEntryInstr(owner()->try_index());
      AppendFragment(case_entry_target, for_case_expression);
      *previous_false_address = case_entry_target;
    }
    TargetEntryInstr* true_target =
        new TargetEntryInstr(owner()->try_index());
    *for_case_expression.true_successor_address() = true_target;
    true_target->Goto(statement_start);
    previous_false_address = for_case_expression.false_successor_address();
  }

  // Once a test fragment has been added, this fragment is closed.
  ASSERT(!is_open());

  Instruction* exit_instruction = NULL;
  // Handle last (or only) case: false goes to exit or to statement if this
  // node contains default.
  if (len > 0) {
    TargetEntryInstr* false_target =
        new TargetEntryInstr(owner()->try_index());
    *previous_false_address = false_target;
    if (node->contains_default()) {
      // True and false go to statement start.
      false_target->Goto(statement_start);
      exit_instruction = statement_exit;
    } else {
      if (statement_exit != NULL) {
        JoinEntryInstr* join = new JoinEntryInstr(owner()->try_index());
        statement_exit->Goto(join);
        false_target->Goto(join);
        exit_instruction = join;
      } else {
        exit_instruction = false_target;
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
// b) [ test ] -> (body-entry-target, loop-exit-target)
// c) body-entry-target
// d) [ body ] -> (continue-join)
// e) continue-join -> (loop-join)
// f) loop-exit-target
// g) break-join (optional)
void EffectGraphVisitor::VisitWhileNode(WhileNode* node) {
  InlineBailout("EffectGraphVisitor::VisitWhileNode");
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_pos());
  node->condition()->Visit(&for_test);
  ASSERT(!for_test.is_empty());  // Language spec.

  EffectGraphVisitor for_body(owner(), temp_index());
  for_body.Do(
      new CheckStackOverflowComp(node->token_pos()));
  node->body()->Visit(&for_body);

  // Labels are set after body traversal.
  SourceLabel* lbl = node->label();
  ASSERT(lbl != NULL);
  JoinEntryInstr* join = lbl->join_for_continue();
  if (join != NULL) {
    if (for_body.is_open()) for_body.Goto(join);
    for_body.exit_ = join;
  }
  TieLoop(for_test, for_body);
  join = lbl->join_for_break();
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
  InlineBailout("EffectGraphVisitor::VisitDoWhileNode");
  // Traverse body first in order to generate continue and break labels.
  EffectGraphVisitor for_body(owner(), temp_index());
  for_body.Do(
      new CheckStackOverflowComp(node->token_pos()));
  node->body()->Visit(&for_body);

  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_pos());
  node->condition()->Visit(&for_test);
  ASSERT(is_open());

  // Tie do-while loop (test is after the body).
  JoinEntryInstr* body_entry_join = new JoinEntryInstr(owner()->try_index());
  Goto(body_entry_join);
  Instruction* body_exit = AppendFragment(body_entry_join, for_body);

  JoinEntryInstr* join = node->label()->join_for_continue();
  if ((body_exit != NULL) || (join != NULL)) {
    if (join == NULL) join = new JoinEntryInstr(owner()->try_index());
    join->set_next(for_test.entry());
    if (body_exit != NULL) {
      body_exit->Goto(join);
    }
  }

  TargetEntryInstr* back_target_entry =
      new TargetEntryInstr(owner()->try_index());
  *for_test.true_successor_address() = back_target_entry;
  back_target_entry->Goto(body_entry_join);
  TargetEntryInstr* loop_exit_target =
      new TargetEntryInstr(owner()->try_index());
  *for_test.false_successor_address() = loop_exit_target;
  if (node->label()->join_for_break() == NULL) {
    exit_ = loop_exit_target;
  } else {
    loop_exit_target->Goto(node->label()->join_for_break());
    exit_ = node->label()->join_for_break();
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
  InlineBailout("EffectGraphVisitor::VisitForNode");
  EffectGraphVisitor for_initializer(owner(), temp_index());
  node->initializer()->Visit(&for_initializer);
  Append(for_initializer);
  ASSERT(is_open());

  // Compose body to set any jump labels.
  EffectGraphVisitor for_body(owner(), temp_index());
  for_body.Do(
      new CheckStackOverflowComp(node->token_pos()));
  node->body()->Visit(&for_body);

  // Join loop body, increment and compute their end instruction.
  ASSERT(!for_body.is_empty());
  Instruction* loop_increment_end = NULL;
  EffectGraphVisitor for_increment(owner(), temp_index());
  node->increment()->Visit(&for_increment);
  JoinEntryInstr* join = node->label()->join_for_continue();
  if (join != NULL) {
    // Insert the join between the body and increment.
    if (for_body.is_open()) for_body.Goto(join);
    loop_increment_end = AppendFragment(join, for_increment);
    ASSERT(loop_increment_end != NULL);
  } else if (for_body.is_open()) {
    // Do not insert an extra basic block.
    for_body.Append(for_increment);
    loop_increment_end = for_body.exit();
    // 'for_body' contains at least the stack check.
    ASSERT(loop_increment_end != NULL);
  } else {
    loop_increment_end = NULL;
  }

  // 'loop_increment_end' is NULL only if there is no join for continue and the
  // body is not open, i.e., no backward branch exists.
  if (loop_increment_end != NULL) {
    JoinEntryInstr* loop_start = new JoinEntryInstr(owner()->try_index());
    Goto(loop_start);
    loop_increment_end->Goto(loop_start);
    exit_ = loop_start;
  }

  if (node->condition() == NULL) {
    // Endless loop, no test.
    JoinEntryInstr* body_entry = new JoinEntryInstr(owner()->try_index());
    AppendFragment(body_entry, for_body);
    Goto(body_entry);
    if (node->label()->join_for_break() != NULL) {
      // Control flow of ForLoop continues into join_for_break.
      exit_ = node->label()->join_for_break();
    }
  } else {
    TargetEntryInstr* loop_exit = new TargetEntryInstr(owner()->try_index());
    TestGraphVisitor for_test(owner(),
                              temp_index(),
                              node->condition()->token_pos());
    node->condition()->Visit(&for_test);
    Append(for_test);
    TargetEntryInstr* body_entry = new TargetEntryInstr(owner()->try_index());
    AppendFragment(body_entry, for_body);
    *for_test.true_successor_address() = body_entry;
    *for_test.false_successor_address() = loop_exit;
    if (node->label()->join_for_break() == NULL) {
      exit_ = loop_exit;
    } else {
      loop_exit->Goto(node->label()->join_for_break());
      exit_ = node->label()->join_for_break();
    }
  }
}


void EffectGraphVisitor::VisitJumpNode(JumpNode* node) {
  InlineBailout("EffectGraphVisitor::VisitJumpNode");
  for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
    EffectGraphVisitor for_effect(owner(), temp_index());
    node->InlinedFinallyNodeAt(i)->Visit(&for_effect);
    Append(for_effect);
    if (!is_open()) return;
  }

  // Unchain the context(s) up to the outer context level of the scope which
  // contains the destination label.
  SourceLabel* label = node->label();
  ASSERT(label->owner() != NULL);
  int target_context_level = 0;
  LocalScope* target_scope = label->owner();
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
  while (current_context_level-- > target_context_level) {
    UnchainContext();
  }

  JoinEntryInstr* jump_target = NULL;
  if (node->kind() == Token::kBREAK) {
    if (node->label()->join_for_break() == NULL) {
      node->label()->set_join_for_break(
          new JoinEntryInstr(owner()->try_index()));
    }
    jump_target = node->label()->join_for_break();
  } else {
    if (node->label()->join_for_continue() == NULL) {
      node->label()->set_join_for_continue(
          new JoinEntryInstr(owner()->try_index()));
    }
    jump_target = node->label()->join_for_continue();
  }
  Goto(jump_target);
}


void EffectGraphVisitor::VisitArgumentListNode(ArgumentListNode* node) {
  InlineBailout("EffectGraphVisitor::VisitArgumentListNode");
  UNREACHABLE();
}


void EffectGraphVisitor::VisitArgumentDefinitionTestNode(
    ArgumentDefinitionTestNode* node) {
  Computation* load = BuildLoadLocal(node->saved_arguments_descriptor());
  Value* arguments_descriptor = Bind(load);
  ArgumentDefinitionTestComp* arg_def_test =
      new ArgumentDefinitionTestComp(node, arguments_descriptor);
  ReturnComputation(arg_def_test);
}


void EffectGraphVisitor::VisitArrayNode(ArrayNode* node) {
  InlineBailout("EffectGraphVisitor::VisitArrayNode");
  // Translate the array elements and collect their values.
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(node->length());
  for (int i = 0; i < node->length(); ++i) {
    ValueGraphVisitor for_value(owner(), temp_index());
    node->ElementAt(i)->Visit(&for_value);
    Append(for_value);
    arguments->Add(PushArgument(for_value.value()));
  }
  const AbstractTypeArguments& type_args =
      AbstractTypeArguments::ZoneHandle(node->type().arguments());
  Value* element_type = BuildInstantiatedTypeArguments(node->token_pos(),
                                                       type_args);
  CreateArrayComp* create = new CreateArrayComp(node->token_pos(),
                                                arguments,
                                                node->type(),
                                                element_type);
  ReturnComputation(create);
}


void EffectGraphVisitor::VisitClosureNode(ClosureNode* node) {
  InlineBailout("EffectGraphVisitor::VisitClosureNode");
  const Function& function = node->function();

  Value* receiver = NULL;
  if (function.IsNonImplicitClosureFunction()) {
    // The context scope may have already been set by the non-optimizing
    // compiler.  If it was not, set it here.
    if (function.context_scope() == ContextScope::null()) {
      // TODO(regis): Why are we not doing this in the parser?
      const ContextScope& context_scope = ContextScope::ZoneHandle(
          node->scope()->PreserveOuterScope(owner()->context_level()));
      ASSERT(!function.HasCode());
      ASSERT(function.context_scope() == ContextScope::null());
      function.set_context_scope(context_scope);
    }
    receiver = BuildNullValue();
  } else if (function.IsImplicitInstanceClosureFunction()) {
    ValueGraphVisitor for_receiver(owner(), temp_index());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    receiver = for_receiver.value();
  } else {
    receiver = BuildNullValue();
  }
  PushArgumentInstr* push_receiver = PushArgument(receiver);
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  arguments->Add(push_receiver);
  ASSERT(function.context_scope() != ContextScope::null());

  // The function type of a closure may have type arguments. In that case, pass
  // the type arguments of the instantiator. Otherwise, pass null object.
  const Class& cls = Class::Handle(function.signature_class());
  ASSERT(!cls.IsNull());
  const bool requires_type_arguments = cls.HasTypeArguments();
  Value* type_arguments = NULL;
  if (requires_type_arguments) {
    ASSERT(!function.IsImplicitStaticClosureFunction());
    type_arguments = BuildInstantiatorTypeArguments(node->token_pos(), NULL);
  } else {
    type_arguments = BuildNullValue();
  }
  PushArgumentInstr* push_type_arguments = PushArgument(type_arguments);
  arguments->Add(push_type_arguments);
  ReturnComputation(new CreateClosureComp(node, arguments));
}


void EffectGraphVisitor::TranslateArgumentList(
    const ArgumentListNode& node,
    ZoneGrowableArray<Value*>* values) {
  InlineBailout("EffectGraphVisitor::TranslateArgumentList");
  for (intptr_t i = 0; i < node.length(); ++i) {
    ValueGraphVisitor for_argument(owner(), temp_index());
    node.NodeAt(i)->Visit(&for_argument);
    Append(for_argument);
    values->Add(for_argument.value());
  }
}


void EffectGraphVisitor::BuildPushArguments(
    const ArgumentListNode& node,
    ZoneGrowableArray<PushArgumentInstr*>* values) {
  InlineBailout("EffectGraphVisitor::BuildPushArguments");
  for (intptr_t i = 0; i < node.length(); ++i) {
    ValueGraphVisitor for_argument(owner(), temp_index());
    node.NodeAt(i)->Visit(&for_argument);
    Append(for_argument);
    PushArgumentInstr* push_arg = PushArgument(for_argument.value());
    values->Add(push_arg);
  }
}


void EffectGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  InlineBailout("EffectGraphVisitor::VisitInstanceCallNode");
  ValueGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  PushArgumentInstr* push_receiver = PushArgument(for_receiver.value());
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(
          node->arguments()->length() + 1);
  arguments->Add(push_receiver);

  BuildPushArguments(*node->arguments(), arguments);
  InstanceCallComp* call = new InstanceCallComp(
      node->token_pos(),
      node->function_name(), Token::kILLEGAL, arguments,
      node->arguments()->names(), 1);
  ReturnComputation(call);
}


// <Expression> ::= StaticCall { function: Function
//                               arguments: <ArgumentList> }
void EffectGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  InlineBailout("EffectGraphVisitor::VisitStaticCallNode");
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(node->arguments()->length());
  BuildPushArguments(*node->arguments(), arguments);
  StaticCallComp* call =
      new StaticCallComp(node->token_pos(),
                         node->function(),
                         node->arguments()->names(),
                         arguments);
  ReturnComputation(call);
}


ClosureCallComp* EffectGraphVisitor::BuildClosureCall(
    ClosureCallNode* node) {
  InlineBailout("EffectGraphVisitor::BuildClosureCall");
  ValueGraphVisitor for_closure(owner(), temp_index());
  node->closure()->Visit(&for_closure);
  Append(for_closure);
  PushArgumentInstr* push_closure = PushArgument(for_closure.value());

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(node->arguments()->length());
  arguments->Add(push_closure);
  BuildPushArguments(*node->arguments(), arguments);

  // Save context around the call.
  BuildStoreContext(*owner()->parsed_function().expression_temp_var());
  return new ClosureCallComp(node, arguments);
}


void EffectGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  InlineBailout("EffectGraphVisitor::VisitClosureCallNode");
  Do(BuildClosureCall(node));
  // Restore context from saved location.
  BuildLoadContext(*owner()->parsed_function().expression_temp_var());
}


void ValueGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  InlineBailout("ValueGraphVisitor::VisitClosureCallNode");
  Value* result = Bind(BuildClosureCall(node));
  // Restore context from temp.
  BuildLoadContext(*owner()->parsed_function().expression_temp_var());
  ReturnValue(result);
}


void EffectGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  InlineBailout("EffectGraphVisitor::VisitCloneContextNode");
  Value* context = Bind(new CurrentContextComp());
  Value* clone = Bind(new CloneContextComp(node->token_pos(), context));
  ReturnComputation(new StoreContextComp(clone));
}


Value* EffectGraphVisitor::BuildObjectAllocation(
    ConstructorCallNode* node) {
  InlineBailout("EffectGraphVisitor::BuildObjectAllocation");
  const Class& cls = Class::ZoneHandle(node->constructor().Owner());
  const bool requires_type_arguments = cls.HasTypeArguments();

  // In checked mode, if the type arguments are uninstantiated, they may need to
  // be checked against declared bounds at run time.
  Computation* allocate_comp = NULL;
  if (FLAG_enable_type_checks &&
      requires_type_arguments &&
      !node->type_arguments().IsNull() &&
      !node->type_arguments().IsInstantiated() &&
      !node->type_arguments().IsWithinBoundsOf(cls,
                                               node->type_arguments(),
                                               NULL)) {
    Value* type_arguments = NULL;
    Value* instantiator = NULL;
    BuildConstructorTypeArguments(node, &type_arguments, &instantiator, NULL);

    // The uninstantiated type arguments cannot be verified to be within their
    // bounds at compile time, so verify them at runtime.
    // Although the type arguments may be uninstantiated at compile time, they
    // may represent the identity vector and may be replaced by the instantiated
    // type arguments of the instantiator at run time.
    allocate_comp = new AllocateObjectWithBoundsCheckComp(node,
                                                          type_arguments,
                                                          instantiator);
  } else {
    ZoneGrowableArray<PushArgumentInstr*>* allocate_arguments =
        new ZoneGrowableArray<PushArgumentInstr*>();

    if (requires_type_arguments) {
      BuildConstructorTypeArguments(node, NULL, NULL, allocate_arguments);
    }

    allocate_comp = new AllocateObjectComp(node, allocate_arguments);
  }
  return Bind(allocate_comp);
}


void EffectGraphVisitor::BuildConstructorCall(
    ConstructorCallNode* node,
    PushArgumentInstr* push_alloc_value) {
  InlineBailout("EffectGraphVisitor::BuildConstructorCall");
  Value* ctor_arg = Bind(
      new ConstantComp(Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll))));
  PushArgumentInstr* push_ctor_arg = PushArgument(ctor_arg);

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  arguments->Add(push_alloc_value);
  arguments->Add(push_ctor_arg);

  BuildPushArguments(*node->arguments(), arguments);
  Do(new StaticCallComp(node->token_pos(),
                        node->constructor(),
                        node->arguments()->names(),
                        arguments));
}


void EffectGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  InlineBailout("EffectGraphVisitor::VisitConstructorCallNode");
  if (node->constructor().IsFactory()) {
    ZoneGrowableArray<PushArgumentInstr*>* arguments =
        new ZoneGrowableArray<PushArgumentInstr*>();
    PushArgumentInstr* push_type_arguments = PushArgument(
        BuildInstantiatedTypeArguments(node->token_pos(),
                                       node->type_arguments()));
    arguments->Add(push_type_arguments);
    ASSERT(arguments->length() == 1);
    BuildPushArguments(*node->arguments(), arguments);
    StaticCallComp* call =
        new StaticCallComp(node->token_pos(),
                           node->constructor(),
                           node->arguments()->names(),
                           arguments);
    ReturnComputation(call);
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


Value* EffectGraphVisitor::BuildInstantiator() {
  InlineBailout("EffectGraphVisitor::BuildInstantiator");
  const Class& instantiator_class = Class::Handle(
      owner()->parsed_function().function().Owner());
  if (instantiator_class.NumTypeParameters() == 0) {
    return NULL;
  }
  Function& outer_function =
      Function::Handle(owner()->parsed_function().function().raw());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  if (outer_function.IsFactory()) {
    return NULL;
  }

  ASSERT(owner()->parsed_function().instantiator() != NULL);
  ValueGraphVisitor for_instantiator(owner(), temp_index());
  owner()->parsed_function().instantiator()->Visit(&for_instantiator);
  Append(for_instantiator);
  return for_instantiator.value();
}


// 'expression_temp_var' may not be used inside this method if 'instantiator'
// is not NULL.
Value* EffectGraphVisitor::BuildInstantiatorTypeArguments(
    intptr_t token_pos, Value* instantiator) {
  InlineBailout("EffectGraphVisitor::BuildInstantiatorTypeArguments");
  const Class& instantiator_class = Class::Handle(
      owner()->parsed_function().function().Owner());
  if (instantiator_class.NumTypeParameters() == 0) {
    // The type arguments are compile time constants.
    AbstractTypeArguments& type_arguments = AbstractTypeArguments::ZoneHandle();
    // Type is temporary. Only its type arguments are preserved.
    Type& type = Type::Handle(
        Type::New(instantiator_class, type_arguments, token_pos, Heap::kNew));
    type ^= ClassFinalizer::FinalizeType(
        instantiator_class, type, ClassFinalizer::kFinalize);
    ASSERT(!type.IsMalformed());
    type_arguments = type.arguments();
    type_arguments = type_arguments.Canonicalize();
    return Bind(new ConstantComp(type_arguments));
  }
  Function& outer_function =
      Function::Handle(owner()->parsed_function().function().raw());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  if (outer_function.IsFactory()) {
    // No instantiator for factories.
    ASSERT(instantiator == NULL);
    ASSERT(owner()->parsed_function().instantiator() != NULL);
    ValueGraphVisitor for_instantiator(owner(), temp_index());
    owner()->parsed_function().instantiator()->Visit(&for_instantiator);
    Append(for_instantiator);
    return for_instantiator.value();
  }
  if (instantiator == NULL) {
    instantiator = BuildInstantiator();
  }
  // The instantiator is the receiver of the caller, which is not a factory.
  // The receiver cannot be null; extract its AbstractTypeArguments object.
  // Note that in the factory case, the instantiator is the first parameter
  // of the factory, i.e. already an AbstractTypeArguments object.
  intptr_t type_arguments_instance_field_offset =
      instantiator_class.type_arguments_instance_field_offset();
  ASSERT(type_arguments_instance_field_offset != Class::kNoTypeArguments);

  return Bind(new LoadVMFieldComp(
      instantiator,
      type_arguments_instance_field_offset,
      Type::ZoneHandle()));  // Not an instance, no type.
}


Value* EffectGraphVisitor::BuildInstantiatedTypeArguments(
    intptr_t token_pos,
    const AbstractTypeArguments& type_arguments) {
  InlineBailout("EffectGraphVisitor::BuildInstantiatedTypeArguments");
  if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
    return Bind(new ConstantComp(type_arguments));
  }
  // The type arguments are uninstantiated.
  Value* instantiator_value =
      BuildInstantiatorTypeArguments(token_pos, NULL);
  return Bind(new InstantiateTypeArgumentsComp(token_pos,
                                               type_arguments,
                                               instantiator_value));
}


void EffectGraphVisitor::BuildConstructorTypeArguments(
    ConstructorCallNode* node,
    Value** type_arguments,
    Value** instantiator,
    ZoneGrowableArray<PushArgumentInstr*>* call_arguments) {
  InlineBailout("EffectGraphVisitor::BuildConstructorTypeArguments");
  const Class& cls = Class::ZoneHandle(node->constructor().Owner());
  ASSERT(cls.HasTypeArguments() && !node->constructor().IsFactory());
  if (node->type_arguments().IsNull() ||
      node->type_arguments().IsInstantiated()) {
    Value* type_arguments_val = Bind(new ConstantComp(node->type_arguments()));
    if (call_arguments != NULL) {
      ASSERT(type_arguments == NULL);
      call_arguments->Add(PushArgument(type_arguments_val));
    } else {
      ASSERT(type_arguments != NULL);
      *type_arguments = type_arguments_val;
    }

    // No instantiator required.
    Value* instantiator_val = Bind(new ConstantComp(
        Smi::ZoneHandle(Smi::New(StubCode::kNoInstantiator))));
    if (call_arguments != NULL) {
      ASSERT(instantiator == NULL);
      call_arguments->Add(PushArgument(instantiator_val));
    } else {
      ASSERT(instantiator != NULL);
      *instantiator = instantiator_val;
    }
    return;
  }
  // The type arguments are uninstantiated. The generated pseudo code:
  //   t1 = InstantiatorTypeArguments();
  //   t2 = ExtractConstructorTypeArguments(t1);
  //   t1 = ExtractConstructorInstantiator(t1);
  //   t_n   <- t2
  //   t_n+1 <- t1
  // Use expression_temp_var and node->allocated_object_var() locals to keep
  // intermediate results around (t1 and t2 above).
  ASSERT(owner()->parsed_function().expression_temp_var() != NULL);
  const LocalVariable& t1 = *owner()->parsed_function().expression_temp_var();
  const LocalVariable& t2 = node->allocated_object_var();
  Value* instantiator_type_arguments = BuildInstantiatorTypeArguments(
      node->token_pos(), NULL);
  Value* stored_instantiator =
      Bind(BuildStoreLocal(t1, instantiator_type_arguments));
  // t1: instantiator type arguments.

  Value* extract_type_arguments = Bind(
      new ExtractConstructorTypeArgumentsComp(
          node->token_pos(),
          node->type_arguments(),
          stored_instantiator));

  Do(BuildStoreLocal(t2, extract_type_arguments));
  // t2: extracted constructor type arguments.
  Value* load_instantiator = Bind(BuildLoadLocal(t1));

  Value* extract_instantiator =
      Bind(new ExtractConstructorInstantiatorComp(node, load_instantiator));
  Do(BuildStoreLocal(t1, extract_instantiator));
  // t2: extracted constructor type arguments.
  // t1: extracted constructor instantiator.
  Value* type_arguments_val = Bind(BuildLoadLocal(t2));
  if (call_arguments != NULL) {
    ASSERT(type_arguments == NULL);
    call_arguments->Add(PushArgument(type_arguments_val));
  } else {
    ASSERT(type_arguments != NULL);
    *type_arguments = type_arguments_val;
  }

  Value* instantiator_val = Bind(BuildLoadLocal(t1));
  if (call_arguments != NULL) {
    ASSERT(instantiator == NULL);
    call_arguments->Add(PushArgument(instantiator_val));
  } else {
    ASSERT(instantiator != NULL);
    *instantiator = instantiator_val;
  }
}


void ValueGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  InlineBailout("ValueGraphVisitor::VisitConstructorCallNode");
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
  Computation* store_allocated = BuildStoreLocal(
      node->allocated_object_var(),
      allocate);
  Value* allocated_value = Bind(store_allocated);
  PushArgumentInstr* push_allocated_value = PushArgument(allocated_value);
  BuildConstructorCall(node, push_allocated_value);
  Computation* load_allocated = BuildLoadLocal(
      node->allocated_object_var());
  allocated_value = Bind(load_allocated);
  ReturnValue(allocated_value);
}


void EffectGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  InlineBailout("EffectGraphVisitor::VisitConstructorCallNode");
  ValueGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  PushArgumentInstr* push_receiver = PushArgument(for_receiver.value());
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(1);
  arguments->Add(push_receiver);
  const String& name =
      String::ZoneHandle(Field::GetterSymbol(node->field_name()));
  InstanceCallComp* call = new InstanceCallComp(
      node->token_pos(), name, Token::kGET,
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::BuildInstanceSetterArguments(
    InstanceSetterNode* node,
    ZoneGrowableArray<PushArgumentInstr*>* arguments,
    bool result_is_needed) {
  InlineBailout("EffectGraphVisitor::BuildInstanceSetterArguments");
  ValueGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  arguments->Add(PushArgument(for_receiver.value()));

  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);

  Value* value = NULL;
  if (result_is_needed) {
    value = Bind(
        BuildStoreLocal(*owner()->parsed_function().expression_temp_var(),
                        for_value.value()));
  } else {
    value = for_value.value();
  }
  arguments->Add(PushArgument(value));
}


void EffectGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  InlineBailout("EffectGraphVisitor::VisitInstanceSetterNode");
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildInstanceSetterArguments(node, arguments, false);  // Value not used.
  const String& name =
      String::ZoneHandle(Field::SetterSymbol(node->field_name()));
  InstanceCallComp* call = new InstanceCallComp(node->token_pos(),
                                                name,
                                                Token::kSET,
                                                arguments,
                                                Array::ZoneHandle(),
                                                1);  // Checked argument count.
  ReturnComputation(call);
}


void ValueGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  InlineBailout("ValueGraphVisitor::VisitInstanceSetterNode");
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildInstanceSetterArguments(node, arguments, true);  // Value used.
  const String& name =
      String::ZoneHandle(Field::SetterSymbol(node->field_name()));
  Do(new InstanceCallComp(node->token_pos(),
                          name,
                          Token::kSET,
                          arguments,
                          Array::ZoneHandle(),
                          1));  // Checked argument count.
  ReturnComputation(
       BuildLoadLocal(*owner()->parsed_function().expression_temp_var()));
}


void EffectGraphVisitor::VisitStaticGetterNode(StaticGetterNode* node) {
  InlineBailout("EffectGraphVisitor::VisitStaticGetterNode");
  const String& getter_name =
      String::Handle(Field::GetterName(node->field_name()));
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>();
  Function& getter_function = Function::ZoneHandle();
  if (node->is_super_getter()) {
    // Statically resolved instance getter, i.e. "super getter".
    getter_function =
    Resolver::ResolveDynamicAnyArgs(node->cls(), getter_name);
    ASSERT(!getter_function.IsNull());
    ASSERT(node->receiver() != NULL);
    ValueGraphVisitor receiver_value(owner(), temp_index());
    node->receiver()->Visit(&receiver_value);
    Append(receiver_value);
    arguments->Add(PushArgument(receiver_value.value()));
  } else {
    getter_function = node->cls().LookupStaticFunction(getter_name);
    ASSERT(!getter_function.IsNull());
  }
  StaticCallComp* call = new StaticCallComp(node->token_pos(),
                                            getter_function,
                                            Array::ZoneHandle(),  // No names.
                                            arguments);
  ReturnComputation(call);
}


void EffectGraphVisitor::BuildStaticSetter(StaticSetterNode* node,
                                           bool result_is_needed) {
  InlineBailout("EffectGraphVisitor::BuildStaticSetter");
  const String& setter_name =
      String::Handle(Field::SetterName(node->field_name()));
  // A super setter is an instance setter whose setter function is
  // resolved at compile time (in the caller instance getter's super class).
  // Unlike a static getter, a super getter has a receiver parameter.
  const bool is_super_setter = (node->receiver() != NULL);
  const Function& setter_function =
      Function::ZoneHandle(is_super_setter
          ? Resolver::ResolveDynamicAnyArgs(node->cls(), setter_name)
          : node->cls().LookupStaticFunction(setter_name));
  ASSERT(!setter_function.IsNull());

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(1);
  if (is_super_setter) {
    // Add receiver of instance getter.
    ValueGraphVisitor for_receiver(owner(), temp_index());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    arguments->Add(PushArgument(for_receiver.value()));
  }
  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* value = NULL;
  if (result_is_needed) {
    value = Bind(
        BuildStoreLocal(*owner()->parsed_function().expression_temp_var(),
                        for_value.value()));
  } else {
    value = for_value.value();
  }
  arguments->Add(PushArgument(value));

  StaticCallComp* call = new StaticCallComp(node->token_pos(),
                                            setter_function,
                                            Array::ZoneHandle(),  // No names.
                                            arguments);
  if (result_is_needed) {
    Do(call);
    ReturnComputation(
         BuildLoadLocal(*owner()->parsed_function().expression_temp_var()));
  } else {
    ReturnComputation(call);
  }
}


void EffectGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  InlineBailout("EffectGraphVisitor::VisitStaticSetterNode");
  BuildStaticSetter(node, false);  // Result not needed.
}


void ValueGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  InlineBailout("ValueGraphVisitor::VisitStaticSetterNode");
  BuildStaticSetter(node, true);  // Result needed.
}


void EffectGraphVisitor::VisitNativeBodyNode(NativeBodyNode* node) {
  InlineBailout("EffectGraphVisitor::VisitNativeBodyNode");
  NativeCallComp* native_call = new NativeCallComp(node);
  ReturnComputation(native_call);
}


void EffectGraphVisitor::VisitPrimaryNode(PrimaryNode* node) {
  InlineBailout("EffectGraphVisitor::VisitPrimaryNode");
  // PrimaryNodes are temporary during parsing.
  UNREACHABLE();
}


// <Expression> ::= LoadLocal { local: LocalVariable }
void EffectGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  InlineBailout("EffectGraphVisitor::VisitLoadLocalNode");
  if (node->HasPseudo()) {
    EffectGraphVisitor for_pseudo(owner(), temp_index());
    node->pseudo()->Visit(&for_pseudo);
    Append(for_pseudo);
  }
}


void ValueGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  InlineBailout("ValueGraphVisitor::VisitLoadLocalNode");
  EffectGraphVisitor::VisitLoadLocalNode(node);
  Computation* load = BuildLoadLocal(node->local());
  ReturnComputation(load);
}


// <Expression> ::= StoreLocal { local: LocalVariable
//                               value: <Expression> }
void EffectGraphVisitor::VisitStoreLocalNode(StoreLocalNode* node) {
  InlineBailout("EffectGraphVisitor::VisitStoreLocalNode");
  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = for_value.value();
  if (FLAG_enable_type_checks) {
    store_value = BuildAssignableValue(node->value()->token_pos(),
                                       store_value,
                                       node->local().type(),
                                       node->local().name());
  }
  Computation* store = BuildStoreLocal(node->local(), store_value);
  ReturnComputation(store);
}


void EffectGraphVisitor::VisitLoadInstanceFieldNode(
    LoadInstanceFieldNode* node) {
  InlineBailout("EffectGraphVisitor::VisitLoadInstanceFieldNode");
  ValueGraphVisitor for_instance(owner(), temp_index());
  node->instance()->Visit(&for_instance);
  Append(for_instance);
  LoadInstanceFieldComp* load = new LoadInstanceFieldComp(
      node->field(), for_instance.value());
  ReturnComputation(load);
}


void EffectGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  InlineBailout("EffectGraphVisitor::VisitStoreInstanceFieldNode");
  ValueGraphVisitor for_instance(owner(), temp_index());
  node->instance()->Visit(&for_instance);
  Append(for_instance);
  ValueGraphVisitor for_value(owner(), for_instance.temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = for_value.value();
  if (FLAG_enable_type_checks) {
    const AbstractType& type = AbstractType::ZoneHandle(node->field().type());
    const String& dst_name = String::ZoneHandle(node->field().name());
    store_value = BuildAssignableValue(node->value()->token_pos(),
                                       store_value,
                                       type,
                                       dst_name);
  }
  StoreInstanceFieldComp* store = new StoreInstanceFieldComp(
      node->field(), for_instance.value(), store_value);
  ReturnComputation(store);
}


// StoreInstanceFieldNode does not return result.
void ValueGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  InlineBailout("ValueGraphVisitor::VisitStoreInstanceFieldNode");
  UNIMPLEMENTED();
}


void EffectGraphVisitor::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  InlineBailout("EffectGraphVisitor::VisitLoadStaticFieldNode");
  LoadStaticFieldComp* load = new LoadStaticFieldComp(node->field());
  ReturnComputation(load);
}


void EffectGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  InlineBailout("EffectGraphVisitor::VisitStoreStaticFieldNode");
  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* store_value = for_value.value();
  if (FLAG_enable_type_checks) {
    const AbstractType& type = AbstractType::ZoneHandle(node->field().type());
    const String& dst_name = String::ZoneHandle(node->field().name());
    store_value = BuildAssignableValue(node->value()->token_pos(),
                                       store_value,
                                       type,
                                       dst_name);
  }
  StoreStaticFieldComp* store =
      new StoreStaticFieldComp(node->field(), store_value);
  ReturnComputation(store);
}


void EffectGraphVisitor::VisitLoadIndexedNode(LoadIndexedNode* node) {
  InlineBailout("EffectGraphVisitor::VisitLoadIndexedNode");
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  ValueGraphVisitor for_array(owner(), temp_index());
  node->array()->Visit(&for_array);
  Append(for_array);
  arguments->Add(PushArgument(for_array.value()));

  ValueGraphVisitor for_index(owner(), temp_index());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  arguments->Add(PushArgument(for_index.value()));

  const intptr_t checked_argument_count = 1;
  const String& name =
      String::ZoneHandle(Symbols::New(Token::Str(Token::kINDEX)));
  InstanceCallComp* load = new InstanceCallComp(node->token_pos(),
                                                name,
                                                Token::kINDEX,
                                                arguments,
                                                Array::ZoneHandle(),
                                                checked_argument_count);
  ReturnComputation(load);
}


Computation* EffectGraphVisitor::BuildStoreIndexedValues(
    StoreIndexedNode* node,
    bool result_is_needed) {
  InlineBailout("EffectGraphVisitor::BuildStoreIndexedValues");
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(3);
  ValueGraphVisitor for_array(owner(), temp_index());
  node->array()->Visit(&for_array);
  Append(for_array);
  arguments->Add(PushArgument(for_array.value()));

  ValueGraphVisitor for_index(owner(), temp_index());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  arguments->Add(PushArgument(for_index.value()));

  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  Value* value = NULL;
  if (result_is_needed) {
    value = Bind(
        BuildStoreLocal(*owner()->parsed_function().expression_temp_var(),
                        for_value.value()));
  } else {
    value = for_value.value();
  }
  arguments->Add(PushArgument(value));

  const intptr_t checked_argument_count = 1;
  const String& name =
      String::ZoneHandle(Symbols::New(Token::Str(Token::kASSIGN_INDEX)));
  InstanceCallComp* store = new InstanceCallComp(node->token_pos(),
                                                 name,
                                                 Token::kASSIGN_INDEX,
                                                 arguments,
                                                 Array::ZoneHandle(),
                                                 checked_argument_count);
  if (result_is_needed) {
    Do(store);
    return BuildLoadLocal(*owner()->parsed_function().expression_temp_var());
  } else {
    return store;
  }
}


void EffectGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  InlineBailout("EffectGraphVisitor::VisitStoreIndexedNode");
  ReturnComputation(BuildStoreIndexedValues(node,
                                            false));  // Result not needed.
}


void ValueGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  InlineBailout("ValueGraphVisitor::VisitStoreIndexedNode");
  ReturnComputation(BuildStoreIndexedValues(node,
                                            true));  // Result is needed.
}


bool EffectGraphVisitor::MustSaveRestoreContext(SequenceNode* node) const {
  return (node == owner()->parsed_function().node_sequence()) &&
         (owner()->parsed_function().saved_context_var() != NULL);
}


void EffectGraphVisitor::UnchainContext() {
  InlineBailout("EffectGraphVisitor::UnchainContext");
  Value* context = Bind(new CurrentContextComp());
  Value* parent = Bind(
      new LoadVMFieldComp(context,
                          Context::parent_offset(),
                          Type::ZoneHandle()));  // Not an instance, no type.
  Do(new StoreContextComp(parent));
}


// <Statement> ::= Sequence { scope: LocalScope
//                            nodes: <Statement>*
//                            label: SourceLabel }
void EffectGraphVisitor::VisitSequenceNode(SequenceNode* node) {
  LocalScope* scope = node->scope();
  const intptr_t num_context_variables =
      (scope != NULL) ? scope->num_context_variables() : 0;
  int previous_context_level = owner()->context_level();
  if (num_context_variables > 0) {
    InlineBailout("EffectGraphVisitor::VisitSequenceNode (captured vars)");
    // The loop local scope declares variables that are captured.
    // Allocate and chain a new context.
    // Allocate context computation (uses current CTX)
    Value* allocated_context =
        Bind(new AllocateContextComp(node->token_pos(), num_context_variables));

    // If this node_sequence is the body of the function being compiled, and if
    // this function is not a closure, do not link the current context as the
    // parent of the newly allocated context, as it is not accessible. Instead,
    // save it in a pre-allocated variable and restore it on exit.
    if (MustSaveRestoreContext(node)) {
      Value* current_context = Bind(new CurrentContextComp());
      Do(BuildStoreLocal(*owner()->parsed_function().saved_context_var(),
                         current_context));
      Value* null_context = Bind(new ConstantComp(Object::ZoneHandle()));
      Do(new StoreContextComp(null_context));
    }

    Do(new ChainContextComp(allocated_context));
    owner()->set_context_level(scope->context_level());

    // If this node_sequence is the body of the function being compiled, copy
    // the captured parameters from the frame into the context.
    if (node == owner()->parsed_function().node_sequence()) {
      ASSERT(scope->context_level() == 1);
      const Function& function = owner()->parsed_function().function();
      int num_params = function.NumberOfParameters();
      int param_frame_index = (num_params == function.num_fixed_parameters()) ?
          (1 + num_params) : ParsedFunction::kFirstLocalSlotIndex;
      // Handle the saved arguments descriptor as an additional parameter.
      if (owner()->parsed_function().GetSavedArgumentsDescriptorVar() != NULL) {
        ASSERT(param_frame_index == ParsedFunction::kFirstLocalSlotIndex);
        num_params++;
      }
      for (int pos = 0; pos < num_params; param_frame_index--, pos++) {
        const LocalVariable& parameter = *scope->VariableAt(pos);
        ASSERT(parameter.owner() == scope);
        if (parameter.is_captured()) {
          // Create a temporary local describing the original position.
          const String& temp_name = String::ZoneHandle(String::Concat(
              parameter.name(), String::Handle(Symbols::New("-orig"))));
          LocalVariable* temp_local = new LocalVariable(
              0,  // Token index.
              temp_name,
              Type::ZoneHandle(Type::DynamicType()));  // Type.
          temp_local->set_index(param_frame_index);

          // Copy parameter from local frame to current context.
          Value* load = Bind(BuildLoadLocal(*temp_local));
          Do(BuildStoreLocal(parameter, load));
          // Write NULL to the source location to detect buggy accesses and
          // allow GC of passed value if it gets overwritten by a new value in
          // the function.
          Value* null_constant =
              Bind(new ConstantComp(Object::ZoneHandle()));
          Do(BuildStoreLocal(*temp_local, null_constant));
        }
      }
    }
  }

  if (FLAG_enable_type_checks &&
      (node == owner()->parsed_function().node_sequence())) {
    InlineBailout("EffectGraphVisitor::VisitSequenceNode (type check)");
    const Function& function = owner()->parsed_function().function();
    const int num_params = function.NumberOfParameters();
    int pos = 0;
    if (function.IsConstructor()) {
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
        AssertAssignableComp* assert_assignable =
            BuildAssertAssignable(parameter.token_pos(),
                                  parameter_value,
                                  parameter.type(),
                                  parameter.name());
        parameter_value = Bind(assert_assignable);
        // Store the type checked argument back to its corresponding local
        // variable so that ssa renaming detects the dependency and makes use
        // of the checked type in type propagation.
        Do(BuildStoreLocal(parameter, parameter_value));
      }
      pos++;
    }
  }

  intptr_t i = 0;
  while (is_open() && (i < node->length())) {
    EffectGraphVisitor for_effect(owner(), temp_index());
    node->NodeAt(i++)->Visit(&for_effect);
    Append(for_effect);
    if (!is_open()) {
      // E.g., because of a JumpNode.
      break;
    }
  }

  if (is_open()) {
    if (MustSaveRestoreContext(node)) {
      ASSERT(num_context_variables > 0);
      BuildLoadContext(*owner()->parsed_function().saved_context_var());
    } else if (num_context_variables > 0) {
      UnchainContext();
    }
  }

  // No continue on sequence allowed.
  ASSERT((node->label() == NULL) ||
         (node->label()->join_for_continue() == NULL));
  // If this node sequence is labeled, a break out of the sequence will have
  // taken care of unchaining the context.
  if ((node->label() != NULL) &&
      (node->label()->join_for_break() != NULL)) {
    if (is_open()) Goto(node->label()->join_for_break());
    exit_ = node->label()->join_for_break();
  }

  // The outermost function sequence cannot contain a label.
  ASSERT((node->label() == NULL) ||
         (node != owner()->parsed_function().node_sequence()));
  owner()->set_context_level(previous_context_level);
}


void EffectGraphVisitor::VisitCatchClauseNode(CatchClauseNode* node) {
  InlineBailout("EffectGraphVisitor::VisitCatchClauseNode");
  // NOTE: The implicit variables ':saved_context', ':exception_var'
  // and ':stacktrace_var' can never be captured variables.
  // Restores CTX from local variable ':saved_context'.
  Do(new CatchEntryComp(node->exception_var(), node->stacktrace_var()));
  BuildLoadContext(node->context_var());

  EffectGraphVisitor for_catch(owner(), temp_index());
  node->VisitChildren(&for_catch);
  Append(for_catch);
}


void EffectGraphVisitor::VisitTryCatchNode(TryCatchNode* node) {
  InlineBailout("EffectGraphVisitor::VisitTryCatchNode");
  intptr_t old_try_index = owner()->try_index();
  intptr_t try_index = owner()->AllocateTryIndex();
  owner()->set_try_index(try_index);

  // Preserve CTX into local variable '%saved_context'.
  BuildStoreContext(node->context_var());

  EffectGraphVisitor for_try_block(owner(), temp_index());
  node->try_block()->Visit(&for_try_block);

  if (for_try_block.is_open()) {
    JoinEntryInstr* after_try = new JoinEntryInstr(old_try_index);
    for_try_block.Goto(after_try);
    for_try_block.exit_ = after_try;
  }

  JoinEntryInstr* try_entry = new JoinEntryInstr(try_index);

  Goto(try_entry);
  AppendFragment(try_entry, for_try_block);
  exit_ = for_try_block.exit_;

  // We are done generating code for the try block.
  owner()->set_try_index(old_try_index);

  CatchClauseNode* catch_block = node->catch_block();
  if (catch_block != NULL) {
    // Set the corresponding try index for this catch block so
    // that we can set the appropriate handler pc when we generate
    // code for this catch block.
    catch_block->set_try_index(try_index);
    EffectGraphVisitor for_catch_block(owner(), temp_index());
    catch_block->Visit(&for_catch_block);
    TargetEntryInstr* catch_entry = new TargetEntryInstr(old_try_index,
                                                         try_index);
    owner()->AddCatchEntry(catch_entry);
    ASSERT(!for_catch_block.is_open());
    AppendFragment(catch_entry, for_catch_block);
    if (node->end_catch_label() != NULL) {
      JoinEntryInstr* join = node->end_catch_label()->join_for_continue();
      if (join != NULL) {
        if (is_open()) Goto(join);
        exit_ = join;
      }
    }
  }

  // Generate code for the finally block if one exists.
  if ((node->finally_block() != NULL) && is_open()) {
    EffectGraphVisitor for_finally_block(owner(), temp_index());
    node->finally_block()->Visit(&for_finally_block);
    Append(for_finally_block);
  }
}


void EffectGraphVisitor::BuildThrowNode(ThrowNode* node) {
  InlineBailout("EffectGraphVisitor::BuildThrowNode");
  ValueGraphVisitor for_exception(owner(), temp_index());
  node->exception()->Visit(&for_exception);
  Append(for_exception);
  PushArgument(for_exception.value());
  Instruction* instr = NULL;
  if (node->stacktrace() == NULL) {
    instr = new ThrowInstr(node->token_pos());
  } else {
    ValueGraphVisitor for_stack_trace(owner(), temp_index());
    node->stacktrace()->Visit(&for_stack_trace);
    Append(for_stack_trace);
    PushArgument(for_stack_trace.value());
    instr = new ReThrowInstr(node->token_pos());
  }
  AddInstruction(instr);
}


void EffectGraphVisitor::VisitThrowNode(ThrowNode* node) {
  InlineBailout("EffectGraphVisitor::VisitThrowNode");
  BuildThrowNode(node);
  CloseFragment();
}


// A throw cannot be part of an expression, however, the parser may replace
// certain expression nodes with a throw. In that case generate a literal null
// so that the fragment is not closed in the middle of an expression.
void ValueGraphVisitor::VisitThrowNode(ThrowNode* node) {
  InlineBailout("ValueGraphVisitor::VisitThrowNode");
  BuildThrowNode(node);
  ReturnComputation(new ConstantComp(Instance::ZoneHandle()));
}


void EffectGraphVisitor::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  InlineBailout("EffectGraphVisitor::VisitInlinedFinallyNode");
  const intptr_t try_index = owner()->try_index();
  if (try_index >= 0) {
    // We are about to generate code for an inlined finally block. Exceptions
    // thrown in this block of code should be treated as though they are
    // thrown not from the current try block but the outer try block if any.
    owner()->set_try_index((try_index - 1));
  }
  BuildLoadContext(node->context_var());

  JoinEntryInstr* finally_entry = new JoinEntryInstr(owner()->try_index());
  EffectGraphVisitor for_finally_block(owner(), temp_index());
  node->finally_block()->Visit(&for_finally_block);

  if (try_index >= 0) {
    owner()->set_try_index(try_index);
  }

  if (for_finally_block.is_open()) {
    JoinEntryInstr* after_finally = new JoinEntryInstr(owner()->try_index());
    for_finally_block.Goto(after_finally);
    for_finally_block.exit_ = after_finally;
  }

  Goto(finally_entry);
  AppendFragment(finally_entry, for_finally_block);
  exit_ = for_finally_block.exit_;
}


FlowGraph* FlowGraphBuilder::BuildGraph() {
  if (FLAG_print_ast) {
    // Print the function ast before IL generation.
    AstPrinter::PrintFunctionNodes(parsed_function());
  }
  // Compilation can be nested, preserve the computation-id.
  const Function& function = parsed_function().function();
  TargetEntryInstr* normal_entry = new TargetEntryInstr(
      CatchClauseNode::kInvalidTryIndex);
  graph_entry_ = new GraphEntryInstr(normal_entry);
  EffectGraphVisitor for_effect(this, 0);
  // TODO(kmillikin): We can eliminate stack checks in some cases (e.g., the
  // stack check on entry for leaf routines).
  for_effect.Do(new CheckStackOverflowComp(function.token_pos()));
  parsed_function().node_sequence()->Visit(&for_effect);
  AppendFragment(normal_entry, for_effect);
  // Check that the graph is properly terminated.
  ASSERT(!for_effect.is_open());
  return new FlowGraph(*this, graph_entry_);
}


FlowGraph* FlowGraphBuilder::BuildGraphForInlining(InliningContext context) {
  ASSERT(inlining_context_ == kNotInlining);
  inlining_context_ = context;
  exits_ = new ZoneGrowableArray<ReturnInstr*>();
  TargetEntryInstr* normal_entry = new TargetEntryInstr(
      CatchClauseNode::kInvalidTryIndex);
  graph_entry_ = new GraphEntryInstr(normal_entry);
  EffectGraphVisitor for_effect(this, 0);
  parsed_function().node_sequence()->Visit(&for_effect);
  AppendFragment(normal_entry, for_effect);
  ASSERT(!for_effect.is_open());
  FlowGraph* graph = new FlowGraph(*this, graph_entry_);
  graph->set_exits(exits_);
  return graph;
}


void FlowGraphBuilder::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphBuilder Bailout: %s %s";
  const char* function_name = parsed_function_.function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = Isolate::Current()->current_zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


}  // namespace dart
