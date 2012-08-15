// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_builder.h"

#include "vm/ast_printer.h"
#include "vm/bit_vector.h"
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
DECLARE_FLAG(bool, use_ssa);


FlowGraphBuilder::FlowGraphBuilder(const ParsedFunction& parsed_function)
  : parsed_function_(parsed_function),
    copied_parameter_count_(parsed_function.copied_parameter_count()),
    // All parameters are copied if any parameter is.
    non_copied_parameter_count_((copied_parameter_count_ == 0)
        ? parsed_function.function().num_fixed_parameters()
        : 0),
    stack_local_count_(parsed_function.stack_local_count()),
    preorder_block_entries_(),
    postorder_block_entries_(),
    context_level_(0),
    last_used_try_index_(CatchClauseNode::kInvalidTryIndex),
    try_index_(CatchClauseNode::kInvalidTryIndex),
    graph_entry_(NULL),
    current_ssa_temp_index_(0) { }


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


UseVal* EffectGraphVisitor::Bind(Computation* computation) {
  ASSERT(is_open());
  DeallocateTempIndex(computation->InputCount());
  BindInstr* bind_instr = new BindInstr(BindInstr::kUsed, computation);
  bind_instr->set_temp_index(AllocateTempIndex());
  if (is_empty()) {
    entry_ = bind_instr;
  } else {
    exit()->set_next(bind_instr);
  }
  exit_ = bind_instr;
  return new UseVal(bind_instr);
}


void EffectGraphVisitor::Do(Computation* computation) {
  ASSERT(is_open());
  DeallocateTempIndex(computation->InputCount());
  BindInstr* do_instr = new BindInstr(BindInstr::kUnused, computation);
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
  TargetEntryInstr* true_entry = new TargetEntryInstr();
  *test_fragment.true_successor_address() = true_entry;
  Instruction* true_exit = AppendFragment(true_entry, true_fragment);

  TargetEntryInstr* false_entry = new TargetEntryInstr();
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
    JoinEntryInstr* join = new JoinEntryInstr();
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
  TargetEntryInstr* body_entry = new TargetEntryInstr();
  *test_fragment.true_successor_address() = body_entry;
  Instruction* body_exit = AppendFragment(body_entry, body_fragment);

  // 2. Connect the test to this graph, including the body if reachable and
  // using a fresh join node if the body is reachable and has an open exit.
  if (body_exit == NULL) {
    Append(test_fragment);
  } else {
    JoinEntryInstr* join = new JoinEntryInstr();
    join->set_next(test_fragment.entry());
    Goto(join);
    body_exit->Goto(join);
  }

  // 3. Set the exit to the graph to be the false successor of the test, a
  // fresh target node
  exit_ = *test_fragment.false_successor_address() = new TargetEntryInstr();
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
    value = Bind(new AssertBooleanComp(condition_token_pos(),
                                       owner()->try_index(),
                                       value));
  }
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  Value* constant_true = Bind(new ConstantVal(bool_true));
  BranchInstr* branch = new BranchInstr(condition_token_pos(),
                                        owner()->try_index(),
                                        value,
                                        constant_true,
                                        Token::kEQ_STRICT);
  AddInstruction(branch);
  CloseFragment();
  true_successor_address_ = branch->true_successor_address();
  false_successor_address_ = branch->false_successor_address();
}


void TestGraphVisitor::MergeBranchWithComparison(ComparisonComp* comp) {
  ASSERT(!FLAG_enable_type_checks);
  BranchInstr* branch = new BranchInstr(condition_token_pos(),
                                        owner()->try_index(),
                                        comp->left(),
                                        comp->right(),
                                        comp->kind());
  AddInstruction(branch);
  CloseFragment();
  true_successor_address_ = branch->true_successor_address();
  false_successor_address_ = branch->false_successor_address();
}


void TestGraphVisitor::MergeBranchWithNegate(BooleanNegateComp* comp) {
  ASSERT(!FLAG_enable_type_checks);
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  Value* constant_true = Bind(new ConstantVal(bool_true));
  BranchInstr* branch = new BranchInstr(condition_token_pos(),
                                        owner()->try_index(),
                                        comp->value(),
                                        constant_true,
                                        Token::kNE_STRICT);
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


// <Statement> ::= Return { value:                <Expression>
//                          inlined_finally_list: <InlinedFinally>* }
void EffectGraphVisitor::VisitReturnNode(ReturnNode* node) {
  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);

  for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
    EffectGraphVisitor for_effect(owner(), temp_index());
    node->InlinedFinallyNodeAt(i)->Visit(&for_effect);
    Append(for_effect);
    if (!is_open()) return;
  }

  Value* return_value = for_value.value();
  if (FLAG_enable_type_checks) {
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

  AddInstruction(new ReturnInstr(node->token_pos(), return_value));
  CloseFragment();
}


// <Expression> ::= Literal { literal: Instance }
void EffectGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  return;
}


void ValueGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  ReturnComputation(new ConstantVal(node->literal()));
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
  UNREACHABLE();
}


void ValueGraphVisitor::VisitAssignableNode(AssignableNode* node) {
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
                                                owner()->try_index(),
                                                name,
                                                node->kind(),
                                                arguments,
                                                Array::ZoneHandle(),
                                                2);
  ReturnComputation(call);
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
                                               owner()->try_index(),
                                               right_value));
    }
    Value* constant_true = for_right.Bind(new ConstantVal(bool_true));
    Value* compare =
        for_right.Bind(new StrictCompareComp(Token::kEQ_STRICT,
                                             right_value,
                                             constant_true));
    for_right.Do(BuildStoreLocal(
        *owner()->parsed_function().expression_temp_var(),
        compare));

    if (node->kind() == Token::kAND) {
      ValueGraphVisitor for_false(owner(), temp_index());
      Value* constant_false = for_false.Bind(new ConstantVal(bool_false));
      for_false.Do(BuildStoreLocal(
          *owner()->parsed_function().expression_temp_var(),
          constant_false));
      Join(for_test, for_right, for_false);
    } else {
      ASSERT(node->kind() == Token::kOR);
      ValueGraphVisitor for_true(owner(), temp_index());
      Value* constant_true = for_true.Bind(new ConstantVal(bool_true));
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
  return Bind(new ConstantVal(Object::ZoneHandle()));
}


// Used for testing incoming arguments.
AssertAssignableComp* EffectGraphVisitor::BuildAssertAssignable(
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
  return new AssertAssignableComp(token_pos,
                                  owner()->try_index(),
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
  if (CanSkipTypeCheck(token_pos, value, dst_type, dst_name)) {
    return value;
  }
  return Bind(BuildAssertAssignable(token_pos, value, dst_type, dst_name));
}


void EffectGraphVisitor::BuildTypeTest(ComparisonNode* node) {
  ASSERT(Token::IsTypeTestOperator(node->kind()));
  EffectGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
}


void EffectGraphVisitor::BuildTypeCast(ComparisonNode* node) {
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
    ReturnComputation(new ConstantVal(negate_result ? bool_false : bool_true));
    return;
  }

  // Eliminate the test if it can be performed successfully at compile time.
  if ((node->left() != NULL) &&
      node->left()->IsLiteralNode() &&
      type.IsInstantiated()) {
    const Instance& literal_value = node->left()->AsLiteralNode()->literal();
    const Class& cls = Class::Handle(literal_value.clazz());
    ConstantVal* result = NULL;
    if (cls.IsNullClass()) {
      // A null object is only an instance of Object and Dynamic, which has
      // already been checked above (if the type is instantiated). So we can
      // return false here if the instance is null (and if the type is
      // instantiated).
      result = new ConstantVal(negate_result ? bool_true : bool_false);
    } else {
      if (literal_value.IsInstanceOf(type, TypeArguments::Handle(), NULL)) {
        result = new ConstantVal(negate_result ? bool_false : bool_true);
      } else {
        result = new ConstantVal(negate_result ? bool_true : bool_false);
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
                         owner()->try_index(),
                         for_left_value.value(),
                         instantiator,
                         instantiator_type_arguments,
                         node->right()->AsTypeNode()->type(),
                         (node->kind() == Token::kISNOT));
  ReturnComputation(instance_of);
}


void ValueGraphVisitor::BuildTypeCast(ComparisonNode* node) {
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
          node->token_pos(), owner()->try_index(),
          Token::kEQ, for_left_value.value(), for_right_value.value());
      if (node->kind() == Token::kEQ) {
        ReturnComputation(comp);
      } else {
        Value* eq_result = Bind(comp);
        eq_result = Bind(new AssertBooleanComp(node->token_pos(),
                                               owner()->try_index(),
                                               eq_result));
        ReturnComputation(new BooleanNegateComp(eq_result));
      }
    } else {
      EqualityCompareComp* comp = new EqualityCompareComp(
          node->token_pos(), owner()->try_index(),
          node->kind(), for_left_value.value(), for_right_value.value());
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
                                                owner()->try_index(),
                                                node->kind(),
                                                for_left_value.value(),
                                                for_right_value.value());
  ReturnComputation(comp);
}


void EffectGraphVisitor::VisitUnaryOpNode(UnaryOpNode* node) {
  // "!" cannot be overloaded, therefore do not call operator.
  if (node->kind() == Token::kNOT) {
    ValueGraphVisitor for_value(owner(), temp_index());
    node->operand()->Visit(&for_value);
    Append(for_value);
    Value* value = for_value.value();
    if (FLAG_enable_type_checks) {
      value =
          Bind(new AssertBooleanComp(node->operand()->token_pos(),
                                     owner()->try_index(),
                                     value));
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
      node->token_pos(), owner()->try_index(), name, node->kind(),
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
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
      statement_start = new JoinEntryInstr();
      node->label()->set_join_for_continue(statement_start);
    }
  } else {
    statement_start = new JoinEntryInstr();
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
      TargetEntryInstr* case_entry_target = new TargetEntryInstr();
      AppendFragment(case_entry_target, for_case_expression);
      *previous_false_address = case_entry_target;
    }
    TargetEntryInstr* true_target = new TargetEntryInstr();
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
    TargetEntryInstr* false_target = new TargetEntryInstr();
    *previous_false_address = false_target;
    if (node->contains_default()) {
      // True and false go to statement start.
      false_target->Goto(statement_start);
      exit_instruction = statement_exit;
    } else {
      if (statement_exit != NULL) {
        JoinEntryInstr* join = new JoinEntryInstr();
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
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_pos());
  node->condition()->Visit(&for_test);
  ASSERT(!for_test.is_empty());  // Language spec.

  EffectGraphVisitor for_body(owner(), temp_index());
  for_body.Do(
      new CheckStackOverflowComp(node->token_pos(), owner()->try_index()));
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
  // Traverse body first in order to generate continue and break labels.
  EffectGraphVisitor for_body(owner(), temp_index());
  for_body.Do(
      new CheckStackOverflowComp(node->token_pos(), owner()->try_index()));
  node->body()->Visit(&for_body);

  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_pos());
  node->condition()->Visit(&for_test);
  ASSERT(is_open());

  // Tie do-while loop (test is after the body).
  JoinEntryInstr* body_entry_join = new JoinEntryInstr();
  Goto(body_entry_join);
  Instruction* body_exit = AppendFragment(body_entry_join, for_body);

  JoinEntryInstr* join = node->label()->join_for_continue();
  if ((body_exit != NULL) || (join != NULL)) {
    if (join == NULL) join = new JoinEntryInstr();
    join->set_next(for_test.entry());
    if (body_exit != NULL) {
      body_exit->Goto(join);
    }
  }

  TargetEntryInstr* back_target_entry = new TargetEntryInstr();
  *for_test.true_successor_address() = back_target_entry;
  back_target_entry->Goto(body_entry_join);
  TargetEntryInstr* loop_exit_target = new TargetEntryInstr();
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
  EffectGraphVisitor for_initializer(owner(), temp_index());
  node->initializer()->Visit(&for_initializer);
  Append(for_initializer);
  ASSERT(is_open());

  // Compose body to set any jump labels.
  EffectGraphVisitor for_body(owner(), temp_index());
  for_body.Do(
      new CheckStackOverflowComp(node->token_pos(), owner()->try_index()));
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
    JoinEntryInstr* loop_start = new JoinEntryInstr();
    Goto(loop_start);
    loop_increment_end->Goto(loop_start);
    exit_ = loop_start;
  }

  if (node->condition() == NULL) {
    // Endless loop, no test.
    JoinEntryInstr* body_entry = new JoinEntryInstr();
    AppendFragment(body_entry, for_body);
    Goto(body_entry);
    if (node->label()->join_for_break() != NULL) {
      // Control flow of ForLoop continues into join_for_break.
      exit_ = node->label()->join_for_break();
    }
  } else {
    TargetEntryInstr* loop_exit = new TargetEntryInstr();
    TestGraphVisitor for_test(owner(),
                              temp_index(),
                              node->condition()->token_pos());
    node->condition()->Visit(&for_test);
    Append(for_test);
    TargetEntryInstr* body_entry = new TargetEntryInstr();
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
      node->label()->set_join_for_break(new JoinEntryInstr());
    }
    jump_target = node->label()->join_for_break();
  } else {
    if (node->label()->join_for_continue() == NULL) {
      node->label()->set_join_for_continue(new JoinEntryInstr());
    }
    jump_target = node->label()->join_for_continue();
  }
  Goto(jump_target);
}


void EffectGraphVisitor::VisitArgumentListNode(ArgumentListNode* node) {
  UNREACHABLE();
}


void EffectGraphVisitor::VisitArrayNode(ArrayNode* node) {
  // Translate the array elements and collect their values.
  ZoneGrowableArray<Value*>* values =
      new ZoneGrowableArray<Value*>(node->length());
  for (int i = 0; i < node->length(); ++i) {
    ValueGraphVisitor for_value(owner(), temp_index());
    node->ElementAt(i)->Visit(&for_value);
    Append(for_value);
    PushArgument(for_value.value());
    values->Add(for_value.value());
  }
  Value* element_type = BuildInstantiatedTypeArguments(node->token_pos(),
                                                       node->type_arguments());
  CreateArrayComp* create = new CreateArrayComp(node->token_pos(),
                                                owner()->try_index(),
                                                values,
                                                element_type);
  ReturnComputation(create);
}


void EffectGraphVisitor::VisitClosureNode(ClosureNode* node) {
  const Function& function = node->function();

  Value* receiver = NULL;
  if (function.IsNonImplicitClosureFunction()) {
    // The context scope may have already been set by the non-optimizing
    // compiler.  If it was not, set it here.
    if (function.context_scope() == ContextScope::null()) {
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
  ReturnComputation(
      new CreateClosureComp(node, owner()->try_index(), arguments));
}


void EffectGraphVisitor::TranslateArgumentList(
    const ArgumentListNode& node,
    ZoneGrowableArray<Value*>* values) {
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
  for (intptr_t i = 0; i < node.length(); ++i) {
    ValueGraphVisitor for_argument(owner(), temp_index());
    node.NodeAt(i)->Visit(&for_argument);
    Append(for_argument);
    PushArgumentInstr* push_arg = PushArgument(for_argument.value());
    values->Add(push_arg);
  }
}


void EffectGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
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
      node->token_pos(), owner()->try_index(),
      node->function_name(), Token::kILLEGAL, arguments,
      node->arguments()->names(), 1);
  ReturnComputation(call);
}


// <Expression> ::= StaticCall { function: Function
//                               arguments: <ArgumentList> }
void EffectGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(node->arguments()->length());
  BuildPushArguments(*node->arguments(), arguments);
  StaticCallComp* call =
      new StaticCallComp(node->token_pos(),
                         owner()->try_index(),
                         node->function(),
                         node->arguments()->names(),
                         arguments);
  ReturnComputation(call);
}


ClosureCallComp* EffectGraphVisitor::BuildClosureCall(
    ClosureCallNode* node) {
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
  return new ClosureCallComp(node, owner()->try_index(), arguments);
}


void EffectGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  Do(BuildClosureCall(node));
  // Restore context from saved location.
  BuildLoadContext(*owner()->parsed_function().expression_temp_var());
}


void ValueGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  Value* result = Bind(BuildClosureCall(node));
  // Restore context from temp.
  BuildLoadContext(*owner()->parsed_function().expression_temp_var());
  ReturnValue(result);
}


void EffectGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  Value* context = Bind(new CurrentContextComp());
  Value* clone = Bind(new CloneContextComp(node->token_pos(),
                                           owner()->try_index(),
                                           context));
  ReturnComputation(new StoreContextComp(clone));
}


Value* EffectGraphVisitor::BuildObjectAllocation(
    ConstructorCallNode* node) {
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
                                                          owner()->try_index(),
                                                          type_arguments,
                                                          instantiator);
  } else {
    ZoneGrowableArray<PushArgumentInstr*>* allocate_arguments =
        new ZoneGrowableArray<PushArgumentInstr*>();

    if (requires_type_arguments) {
      BuildConstructorTypeArguments(node, NULL, NULL, allocate_arguments);
    }

    allocate_comp = new AllocateObjectComp(node,
                                           owner()->try_index(),
                                           allocate_arguments);
  }
  return Bind(allocate_comp);
}


void EffectGraphVisitor::BuildConstructorCall(
    ConstructorCallNode* node,
    PushArgumentInstr* push_alloc_value) {
  Value* ctor_arg = Bind(
      new ConstantVal(Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll))));
  PushArgumentInstr* push_ctor_arg = PushArgument(ctor_arg);

  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  arguments->Add(push_alloc_value);
  arguments->Add(push_ctor_arg);

  BuildPushArguments(*node->arguments(), arguments);
  Do(new StaticCallComp(node->token_pos(),
                        owner()->try_index(),
                        node->constructor(),
                        node->arguments()->names(),
                        arguments));
}


void EffectGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
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
                           owner()->try_index(),
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
    return Bind(new ConstantVal(type_arguments));
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
  if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
    return Bind(new ConstantVal(type_arguments));
  }
  // The type arguments are uninstantiated.
  Value* instantiator_value =
      BuildInstantiatorTypeArguments(token_pos, NULL);
  return Bind(new InstantiateTypeArgumentsComp(token_pos,
                                               owner()->try_index(),
                                               type_arguments,
                                               instantiator_value));
}


void EffectGraphVisitor::BuildConstructorTypeArguments(
    ConstructorCallNode* node,
    Value** type_arguments,
    Value** instantiator,
    ZoneGrowableArray<PushArgumentInstr*>* call_arguments) {
  const Class& cls = Class::ZoneHandle(node->constructor().Owner());
  ASSERT(cls.HasTypeArguments() && !node->constructor().IsFactory());
  if (node->type_arguments().IsNull() ||
      node->type_arguments().IsInstantiated()) {
    Value* type_arguments_val = Bind(new ConstantVal(node->type_arguments()));
    if (call_arguments != NULL) {
      ASSERT(type_arguments == NULL);
      call_arguments->Add(PushArgument(type_arguments_val));
    } else {
      ASSERT(type_arguments != NULL);
      *type_arguments = type_arguments_val;
    }

    // No instantiator required.
    Value* instantiator_val = Bind(
        new ConstantVal(Smi::ZoneHandle(Smi::New(StubCode::kNoInstantiator))));
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
  ASSERT(instantiator_type_arguments->IsUse());
  Value* stored_instantiator =
      Bind(BuildStoreLocal(t1, instantiator_type_arguments));
  // t1: instantiator type arguments.

  Value* extract_type_arguments = Bind(
      new ExtractConstructorTypeArgumentsComp(
          node->token_pos(),
          owner()->try_index(),
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
      node->token_pos(), owner()->try_index(), name, Token::kGET,
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::BuildInstanceSetterArguments(
    InstanceSetterNode* node,
    ZoneGrowableArray<PushArgumentInstr*>* arguments,
    bool result_is_needed) {
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
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildInstanceSetterArguments(node, arguments, false);  // Value not used.
  const String& name =
      String::ZoneHandle(Field::SetterSymbol(node->field_name()));
  InstanceCallComp* call = new InstanceCallComp(node->token_pos(),
                                                owner()->try_index(),
                                                name,
                                                Token::kSET,
                                                arguments,
                                                Array::ZoneHandle(),
                                                1);  // Checked argument count.
  ReturnComputation(call);
}


void ValueGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  ZoneGrowableArray<PushArgumentInstr*>* arguments =
      new ZoneGrowableArray<PushArgumentInstr*>(2);
  BuildInstanceSetterArguments(node, arguments, true);  // Value used.
  const String& name =
      String::ZoneHandle(Field::SetterSymbol(node->field_name()));
  Do(new InstanceCallComp(node->token_pos(),
                          owner()->try_index(),
                          name,
                          Token::kSET,
                          arguments,
                          Array::ZoneHandle(),
                          1));  // Checked argument count.
  ReturnComputation(
       BuildLoadLocal(*owner()->parsed_function().expression_temp_var()));
}


void EffectGraphVisitor::VisitStaticGetterNode(StaticGetterNode* node) {
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
                                            owner()->try_index(),
                                            getter_function,
                                            Array::ZoneHandle(),  // No names.
                                            arguments);
  ReturnComputation(call);
}


void EffectGraphVisitor::BuildStaticSetter(StaticSetterNode* node,
                                           bool result_is_needed) {
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
                                            owner()->try_index(),
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
  BuildStaticSetter(node, false);  // Result not needed.
}


void ValueGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  BuildStaticSetter(node, true);  // Result needed.
}


void EffectGraphVisitor::VisitNativeBodyNode(NativeBodyNode* node) {
  NativeCallComp* native_call =
      new NativeCallComp(node, owner()->try_index());
  ReturnComputation(native_call);
}


void EffectGraphVisitor::VisitPrimaryNode(PrimaryNode* node) {
  // PrimaryNodes are temporary during parsing.
  UNREACHABLE();
}


// <Expression> ::= LoadLocal { local: LocalVariable }
void EffectGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  if (node->HasPseudo()) {
    EffectGraphVisitor for_pseudo(owner(), temp_index());
    node->pseudo()->Visit(&for_pseudo);
    Append(for_pseudo);
  }
}


void ValueGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  EffectGraphVisitor::VisitLoadLocalNode(node);
  Computation* load = BuildLoadLocal(node->local());
  ReturnComputation(load);
}


// <Expression> ::= StoreLocal { local: LocalVariable
//                               value: <Expression> }
void EffectGraphVisitor::VisitStoreLocalNode(StoreLocalNode* node) {
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
  ValueGraphVisitor for_instance(owner(), temp_index());
  node->instance()->Visit(&for_instance);
  Append(for_instance);
  LoadInstanceFieldComp* load = new LoadInstanceFieldComp(
      node->field(), for_instance.value(), NULL);
  ReturnComputation(load);
}


void EffectGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
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
      node->field(), for_instance.value(), store_value, NULL);
  ReturnComputation(store);
}


// StoreInstanceFieldNode does not return result.
void ValueGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  UNIMPLEMENTED();
}


void EffectGraphVisitor::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  LoadStaticFieldComp* load = new LoadStaticFieldComp(node->field());
  ReturnComputation(load);
}


void EffectGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
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
                                                owner()->try_index(),
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
                                                 owner()->try_index(),
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
  ReturnComputation(BuildStoreIndexedValues(node,
                                            false));  // Result not needed.
}


void ValueGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  ReturnComputation(BuildStoreIndexedValues(node,
                                            true));  // Result is needed.
}


bool EffectGraphVisitor::MustSaveRestoreContext(SequenceNode* node) const {
  return (node == owner()->parsed_function().node_sequence()) &&
         (owner()->parsed_function().saved_context_var() != NULL);
}


void EffectGraphVisitor::UnchainContext() {
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
    // The loop local scope declares variables that are captured.
    // Allocate and chain a new context.
    // Allocate context computation (uses current CTX)
    Value* allocated_context =
        Bind(new AllocateContextComp(node->token_pos(),
                                     owner()->try_index(),
                                     num_context_variables));

    // If this node_sequence is the body of the function being compiled, and if
    // this function is not a closure, do not link the current context as the
    // parent of the newly allocated context, as it is not accessible. Instead,
    // save it in a pre-allocated variable and restore it on exit.
    if (MustSaveRestoreContext(node)) {
      Value* current_context = Bind(new CurrentContextComp());
      Do(BuildStoreLocal(*owner()->parsed_function().saved_context_var(),
                         current_context));
      Value* null_context = Bind(new ConstantVal(Object::ZoneHandle()));
      Do(new StoreContextComp(null_context));
    }

    Do(new ChainContextComp(allocated_context));
    owner()->set_context_level(scope->context_level());

    // If this node_sequence is the body of the function being compiled, copy
    // the captured parameters from the frame into the context.
    if (node == owner()->parsed_function().node_sequence()) {
      ASSERT(scope->context_level() == 1);
      const Function& function = owner()->parsed_function().function();
      const int num_params = function.NumberOfParameters();
      int param_frame_index = (num_params == function.num_fixed_parameters()) ?
          (1 + num_params) : ParsedFunction::kFirstLocalSlotIndex;
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
          Value* null_constant = Bind(new ConstantVal(Object::ZoneHandle()));
          Do(BuildStoreLocal(*temp_local, null_constant));
        }
      }
    }
  }

  if (FLAG_enable_type_checks &&
      (node == owner()->parsed_function().node_sequence())) {
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
        if (FLAG_use_ssa) {
          parameter_value = Bind(assert_assignable);
          // Store the type checked argument back to its corresponding local
          // variable so that ssa renaming detects the dependency and makes use
          // of the checked type in type propagation.
          Do(BuildStoreLocal(parameter, parameter_value));
        } else {
          // No need to store the check parameter value back when not using ssa.
          Do(assert_assignable);
        }
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
  intptr_t old_try_index = owner()->try_index();
  intptr_t try_index = owner()->AllocateTryIndex();
  owner()->set_try_index(try_index);

  // Preserve CTX into local variable '%saved_context'.
  BuildStoreContext(node->context_var());

  EffectGraphVisitor for_try_block(owner(), temp_index());
  node->try_block()->Visit(&for_try_block);
  Append(for_try_block);

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
    TargetEntryInstr* catch_entry = new TargetEntryInstr(try_index);
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
  ValueGraphVisitor for_exception(owner(), temp_index());
  node->exception()->Visit(&for_exception);
  Append(for_exception);
  PushArgument(for_exception.value());
  Instruction* instr = NULL;
  if (node->stacktrace() == NULL) {
    instr = new ThrowInstr(node->token_pos(), owner()->try_index());
  } else {
    ValueGraphVisitor for_stack_trace(owner(), temp_index());
    node->stacktrace()->Visit(&for_stack_trace);
    Append(for_stack_trace);
    PushArgument(for_stack_trace.value());
    instr = new ReThrowInstr(node->token_pos(), owner()->try_index());
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
  ReturnComputation(new ConstantVal(Instance::ZoneHandle()));
}


void EffectGraphVisitor::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  const intptr_t try_index = owner()->try_index();
  if (try_index >= 0) {
    // We are about to generate code for an inlined finally block. Exceptions
    // thrown in this block of code should be treated as though they are
    // thrown not from the current try block but the outer try block if any.
    owner()->set_try_index((try_index - 1));
  }
  BuildLoadContext(node->context_var());
  EffectGraphVisitor for_finally_block(owner(), temp_index());
  node->finally_block()->Visit(&for_finally_block);
  Append(for_finally_block);
  if (try_index >= 0) {
    owner()->set_try_index(try_index);
  }
}


void FlowGraphBuilder::BuildGraph(bool for_optimized, bool use_ssa) {
  if (FLAG_print_ast) {
    // Print the function ast before IL generation.
    AstPrinter::PrintFunctionNodes(parsed_function());
  }
  // Compilation can be nested, preserve the computation-id.
  const Function& function = parsed_function().function();
  TargetEntryInstr* normal_entry = new TargetEntryInstr();
  graph_entry_ = new GraphEntryInstr(normal_entry);
  EffectGraphVisitor for_effect(this, 0);
  // TODO(kmillikin): We can eliminate stack checks in some cases (e.g., the
  // stack check on entry for leaf routines).
  for_effect.Do(new CheckStackOverflowComp(function.token_pos(),
                                           CatchClauseNode::kInvalidTryIndex));
  parsed_function().node_sequence()->Visit(&for_effect);
  AppendFragment(normal_entry, for_effect);
  // Check that the graph is properly terminated.
  ASSERT(!for_effect.is_open());
  GrowableArray<intptr_t> parent;
  GrowableArray<BitVector*> assigned_vars;

  // Perform a depth-first traversal of the graph to build preorder and
  // postorder block orders.
  graph_entry_->DiscoverBlocks(NULL,  // Entry block predecessor.
                               &preorder_block_entries_,
                               &postorder_block_entries_,
                               &parent,
                               &assigned_vars,
                               variable_count(),
                               non_copied_parameter_count_);
  // Number blocks in reverse postorder.
  intptr_t block_count = postorder_block_entries_.length();
  for (intptr_t i = 0; i < block_count; ++i) {
    postorder_block_entries_[i]->set_block_id(block_count - i - 1);
  }

  if (for_optimized) {
    // Link instructions backwards for optimized compilation.
    for (intptr_t i = 0; i < block_count; ++i) {
      BlockEntryInstr* entry = postorder_block_entries_[i];
      Instruction* previous = entry;
      for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
        Instruction* current = it.Current();
        current->set_previous(previous);
        previous = current;
      }
    }
  }

  if (for_optimized && use_ssa) {
    GrowableArray<BitVector*> dominance_frontier;
    ComputeDominators(&preorder_block_entries_, &parent, &dominance_frontier);
    InsertPhis(preorder_block_entries_,
               assigned_vars,
               dominance_frontier);

    GrowableArray<PhiInstr*> live_phis;

    // Rename uses to reference inserted phis where appropriate.
    // Collect phis that reach a non-environment use.
    Rename(&live_phis);

    // Propagate alive mark transitively from alive phis.
    MarkLivePhis(&live_phis);
  }
  if (FLAG_print_flow_graph || (Dart::flow_graph_writer() != NULL)) {
    intptr_t length = postorder_block_entries_.length();
    GrowableArray<BlockEntryInstr*> reverse_postorder(length);
    for (intptr_t i = length - 1; i >= 0; --i) {
      reverse_postorder.Add(postorder_block_entries_[i]);
    }
    if (FLAG_print_flow_graph) {
      // Print flow graph to stdout.
      FlowGraphPrinter printer(function, reverse_postorder);
      printer.PrintBlocks();
    }
    if (Dart::flow_graph_writer() != NULL) {
      // Write flow graph to file.
      FlowGraphVisualizer printer(function, reverse_postorder);
      printer.PrintFunction();
    }
  }
}


// Compute immediate dominators and the dominance frontier for each basic
// block.  As a side effect of the algorithm, sets the immediate dominator
// of each basic block.
//
// preorder: an input list of basic block entries in preorder.  The
//     algorithm relies on the block ordering.
//
// parent: an input parameter encoding a depth-first spanning tree of
//     the control flow graph.  The array maps the preorder block
//     number of a block to the preorder block number of its spanning
//     tree parent.
//
// dominance_frontier: an output parameter encoding the dominance frontier.
//     The array maps the preorder block number of a block to the set of
//     (preorder block numbers of) blocks in the dominance frontier.
void FlowGraphBuilder::ComputeDominators(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<intptr_t>* parent,
    GrowableArray<BitVector*>* dominance_frontier) {
  // Use the SEMI-NCA algorithm to compute dominators.  This is a two-pass
  // version of the Lengauer-Tarjan algorithm (LT is normally three passes)
  // that eliminates a pass by using nearest-common ancestor (NCA) to
  // compute immediate dominators from semidominators.  It also removes a
  // level of indirection in the link-eval forest data structure.
  //
  // The algorithm is described in Georgiadis, Tarjan, and Werneck's
  // "Finding Dominators in Practice".
  // See http://www.cs.princeton.edu/~rwerneck/dominators/ .

  // All arrays are maps between preorder basic-block numbers.
  intptr_t size = parent->length();
  GrowableArray<intptr_t> idom(size);  // Immediate dominator.
  GrowableArray<intptr_t> semi(size);  // Semidominator.
  GrowableArray<intptr_t> label(size);  // Label for link-eval forest.

  // 1. First pass: compute semidominators as in Lengauer-Tarjan.
  // Semidominators are computed from a depth-first spanning tree and are an
  // approximation of immediate dominators.

  // Use a link-eval data structure with path compression.  Implement path
  // compression in place by mutating the parent array.  Each block has a
  // label, which is the minimum block number on the compressed path.

  // Initialize idom, semi, and label used by SEMI-NCA.  Initialize the
  // dominance frontier output array.
  for (intptr_t i = 0; i < size; ++i) {
    idom.Add((*parent)[i]);
    semi.Add(i);
    label.Add(i);
    dominance_frontier->Add(new BitVector(size));
  }

  // Loop over the blocks in reverse preorder (not including the graph
  // entry).
  for (intptr_t block_index = size - 1; block_index >= 1; --block_index) {
    // Loop over the predecessors.
    BlockEntryInstr* block = (*preorder)[block_index];
    for (intptr_t i = 0, count = block->PredecessorCount(); i < count; ++i) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ASSERT(pred != NULL);

      // Look for the semidominator by ascending the semidominator path
      // starting from pred.
      intptr_t pred_index = pred->preorder_number();
      intptr_t best = pred_index;
      if (pred_index > block_index) {
        CompressPath(block_index, pred_index, parent, &label);
        best = label[pred_index];
      }

      // Update the semidominator if we've found a better one.
      semi[block_index] = Utils::Minimum(semi[block_index], semi[best]);
    }

    // Now use label for the semidominator.
    label[block_index] = semi[block_index];
  }

  // 2. Compute the immediate dominators as the nearest common ancestor of
  // spanning tree parent and semidominator, for all blocks except the entry.
  for (intptr_t block_index = 1; block_index < size; ++block_index) {
    intptr_t dom_index = idom[block_index];
    while (dom_index > semi[block_index]) {
      dom_index = idom[dom_index];
    }
    idom[block_index] = dom_index;
    (*preorder)[block_index]->set_dominator((*preorder)[dom_index]);
    (*preorder)[dom_index]->AddDominatedBlock((*preorder)[block_index]);
  }

  // 3. Now compute the dominance frontier for all blocks.  This is
  // algorithm in "A Simple, Fast Dominance Algorithm" (Figure 5), which is
  // attributed to a paper by Ferrante et al.  There is no bookkeeping
  // required to avoid adding a block twice to the same block's dominance
  // frontier because we use a set to represent the dominance frontier.
  for (intptr_t block_index = 0; block_index < size; ++block_index) {
    BlockEntryInstr* block = (*preorder)[block_index];
    intptr_t count = block->PredecessorCount();
    if (count <= 1) continue;
    for (intptr_t i = 0; i < count; ++i) {
      BlockEntryInstr* runner = block->PredecessorAt(i);
      while (runner != block->dominator()) {
        (*dominance_frontier)[runner->preorder_number()]->Add(block_index);
        runner = runner->dominator();
      }
    }
  }
}


void FlowGraphBuilder::CompressPath(intptr_t start_index,
                                    intptr_t current_index,
                                    GrowableArray<intptr_t>* parent,
                                    GrowableArray<intptr_t>* label) {
  intptr_t next_index = (*parent)[current_index];
  if (next_index > start_index) {
    CompressPath(start_index, next_index, parent, label);
    (*label)[current_index] =
        Utils::Minimum((*label)[current_index], (*label)[next_index]);
    (*parent)[current_index] = (*parent)[next_index];
  }
}


void FlowGraphBuilder::InsertPhis(
    const GrowableArray<BlockEntryInstr*>& preorder,
    const GrowableArray<BitVector*>& assigned_vars,
    const GrowableArray<BitVector*>& dom_frontier) {
  const intptr_t block_count = preorder.length();
  // Map preorder block number to the highest variable index that has a phi
  // in that block.  Use it to avoid inserting multiple phis for the same
  // variable.
  GrowableArray<intptr_t> has_already(block_count);
  // Map preorder block number to the highest variable index for which the
  // block went on the worklist.  Use it to avoid adding the same block to
  // the worklist more than once for the same variable.
  GrowableArray<intptr_t> work(block_count);

  // Initialize has_already and work.
  for (intptr_t block_index = 0; block_index < block_count; ++block_index) {
    has_already.Add(-1);
    work.Add(-1);
  }

  // Insert phis for each variable in turn.
  GrowableArray<BlockEntryInstr*> worklist;
  for (intptr_t var_index = 0; var_index < variable_count(); ++var_index) {
    // Add to the worklist each block containing an assignment.
    for (intptr_t block_index = 0; block_index < block_count; ++block_index) {
      if (assigned_vars[block_index]->Contains(var_index)) {
        work[block_index] = var_index;
        worklist.Add(preorder[block_index]);
      }
    }

    while (!worklist.is_empty()) {
      BlockEntryInstr* current = worklist.Last();
      worklist.RemoveLast();
      // Ensure a phi for each block in the dominance frontier of current.
      for (BitVector::Iterator it(dom_frontier[current->preorder_number()]);
           !it.Done();
           it.Advance()) {
        int index = it.Current();
        if (has_already[index] < var_index) {
          BlockEntryInstr* block = preorder[index];
          ASSERT(block->IsJoinEntry());
          block->AsJoinEntry()->InsertPhi(var_index, variable_count());
          has_already[index] = var_index;
          if (work[index] < var_index) {
            work[index] = var_index;
            worklist.Add(block);
          }
        }
      }
    }
  }
}


void FlowGraphBuilder::Rename(GrowableArray<PhiInstr*>* live_phis) {
  // TODO(fschneider): Support catch-entry.
  if (graph_entry_->SuccessorCount() > 1) {
    Bailout("Catch-entry support in SSA.");
  }

  // Initialize start environment.
  GrowableArray<Value*> start_env(variable_count());
  for (intptr_t i = 0; i < parameter_count(); ++i) {
    ParameterInstr* param = new ParameterInstr(i);
    param->set_ssa_temp_index(alloc_ssa_temp_index());  // New SSA temp.
    start_env.Add(new UseVal(param));
  }

  // All locals are initialized with #null.
  Value* null_value = new ConstantVal(Object::ZoneHandle());
  while (start_env.length() < variable_count()) {
    start_env.Add(null_value);
  }
  graph_entry_->set_start_env(
      new Environment(start_env, non_copied_parameter_count_));

  BlockEntryInstr* normal_entry = graph_entry_->SuccessorAt(0);
  ASSERT(normal_entry != NULL);  // Must have entry.
  GrowableArray<Value*> env(variable_count());
  env.AddArray(start_env);
  RenameRecursive(normal_entry, &env, live_phis);
}


// Helper to a copy a value iff it is a UseVal.
static Value* CopyValue(Value* value) {
  return value->IsUse()
      ? new UseVal(value->AsUse()->definition())
      : value;
}


void FlowGraphBuilder::RenameRecursive(BlockEntryInstr* block_entry,
                                       GrowableArray<Value*>* env,
                                       GrowableArray<PhiInstr*>* live_phis) {
  // 1. Process phis first.
  if (block_entry->IsJoinEntry()) {
    JoinEntryInstr* join = block_entry->AsJoinEntry();
    if (join->phis() != NULL) {
      for (intptr_t i = 0; i < join->phis()->length(); ++i) {
        PhiInstr* phi = (*join->phis())[i];
        if (phi != NULL) {
          (*env)[i] = new UseVal(phi);
          phi->set_ssa_temp_index(alloc_ssa_temp_index());  // New SSA temp.
        }
      }
    }
  }

  // 2. Process normal instructions.
  for (ForwardInstructionIterator it(block_entry); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();
    // Attach current environment to the instruction. First, each instruction
    // gets a full copy of the environment. Later we optimize this by
    // eliminating unnecessary environments.
    current->set_env(new Environment(*env, non_copied_parameter_count_));

    // 2a. Handle uses:
    // Update expression stack environment for each use.
    // For each use of a LoadLocal or StoreLocal: Replace it with the value
    // from the environment.
    for (intptr_t i = current->InputCount() - 1; i >= 0; --i) {
      Value* v = current->InputAt(i);
      if (!v->IsUse()) continue;
      // Update expression stack.
      ASSERT(env->length() > variable_count());

      Value* input_value = env->Last();
      ASSERT(input_value->IsUse());
      env->RemoveLast();

      BindInstr* as_bind = v->AsUse()->definition()->AsBind();
      if ((as_bind != NULL) &&
          (as_bind->computation()->IsLoadLocal() ||
           as_bind->computation()->IsStoreLocal())) {
        current->SetInputAt(i, CopyValue(input_value));
      }
    }

    // Drop pushed arguments for calls.
    for (intptr_t j = 0; j < current->ArgumentCount(); j++) {
      env->RemoveLast();
    }

    // 2b. Handle LoadLocal and StoreLocal.
    // For each LoadLocal: Remove it from the graph.
    // For each StoreLocal: Remove it from the graph and update the environment.
    BindInstr* bind = current->AsBind();
    if (bind != NULL) {
      LoadLocalComp* load = bind->computation()->AsLoadLocal();
      StoreLocalComp* store = bind->computation()->AsStoreLocal();
      if ((load != NULL) || (store != NULL)) {
        intptr_t index;
        if (store != NULL) {
          index = store->local().BitIndexIn(non_copied_parameter_count_);
          // Update renaming environment.
          (*env)[index] = store->value();
        } else {
          // The graph construction ensures we do not have an unused LoadLocal
          // computation.
          ASSERT(bind->is_used());
          index = load->local().BitIndexIn(non_copied_parameter_count_);

          Value* value = (*env)[index];
          if (value->IsUse()) {
            PhiInstr* phi = value->AsUse()->definition()->AsPhi();
            if ((phi != NULL) && !phi->is_alive()) {
              phi->mark_alive();
              live_phis->Add(phi);
            }
          }
        }
        // Update expression stack and remove from graph.
        if (bind->is_used()) {
          env->Add(CopyValue((*env)[index]));
        }
        it.RemoveCurrentFromGraph();
      } else {
        // Not a load or store.
        if (bind->is_used()) {
          // Assign fresh SSA temporary and update expression stack.
          bind->set_ssa_temp_index(alloc_ssa_temp_index());
          env->Add(new UseVal(bind));
        }
      }
    }

    // 2c. Handle pushed argument.
    PushArgumentInstr* push = current->AsPushArgument();
    if (push != NULL) {
      env->Add(new UseVal(push));
    }
  }

  // 3. Process dominated blocks.
  for (intptr_t i = 0; i < block_entry->dominated_blocks().length(); ++i) {
    BlockEntryInstr* block = block_entry->dominated_blocks()[i];
    GrowableArray<Value*> new_env(env->length());
    new_env.AddArray(*env);
    RenameRecursive(block, &new_env, live_phis);
  }

  // 4. Process successor block. We have edge-split form, so that only blocks
  // with one successor can have a join block as successor.
  if ((block_entry->last_instruction()->SuccessorCount() == 1) &&
      block_entry->last_instruction()->SuccessorAt(0)->IsJoinEntry()) {
    JoinEntryInstr* successor =
        block_entry->last_instruction()->SuccessorAt(0)->AsJoinEntry();
    intptr_t pred_index = successor->IndexOfPredecessor(block_entry);
    ASSERT(pred_index >= 0);
    if (successor->phis() != NULL) {
      for (intptr_t i = 0; i < successor->phis()->length(); ++i) {
        PhiInstr* phi = (*successor->phis())[i];
        if (phi != NULL) {
          // Rename input operand and make a copy if it is a UseVal.
          Value* new_val = (*env)[i]->IsUse()
              ? new UseVal((*env)[i]->AsUse()->definition())
              : (*env)[i];
          phi->SetInputAt(pred_index, new_val);
        }
      }
    }
  }
}


void FlowGraphBuilder::MarkLivePhis(GrowableArray<PhiInstr*>* live_phis) {
  while (!live_phis->is_empty()) {
    PhiInstr* phi = live_phis->Last();
    live_phis->RemoveLast();
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Value* val = phi->InputAt(i);
      if (!val->IsUse()) continue;
      PhiInstr* used_phi = val->AsUse()->definition()->AsPhi();
      if ((used_phi != NULL) && !used_phi->is_alive()) {
        used_phi->mark_alive();
        live_phis->Add(used_phi);
      }
    }
  }
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
