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

namespace dart {

DEFINE_FLAG(bool, print_flow_graph, false, "Print the IR flow graph.");
DECLARE_FLAG(bool, enable_type_checks);
DEFINE_FLAG(bool, print_ast, false, "Print abstract syntax tree.");


FlowGraphBuilder::FlowGraphBuilder(const ParsedFunction& parsed_function)
  : parsed_function_(parsed_function),
    preorder_block_entries_(),
    postorder_block_entries_(),
    context_level_(0),
    last_used_try_index_(CatchClauseNode::kInvalidTryIndex),
    try_index_(CatchClauseNode::kInvalidTryIndex),
    graph_entry_(NULL) { }


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
    exit()->SetSuccessor(other_fragment.entry());
    exit_ = other_fragment.exit();
  }
  temp_index_ = other_fragment.temp_index();
}


void EffectGraphVisitor::AddInstruction(Instruction* instruction) {
  ASSERT(is_open());
  DeallocateTempIndex(instruction->InputCount());
  if (instruction->IsDefinition()) {
    instruction->AsDefinition()->set_temp_index(AllocateTempIndex());
  }
  if (is_empty()) {
    entry_ = exit_ = instruction;
  } else {
    exit()->SetSuccessor(instruction);
    exit_ = instruction;
  }
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
  Instruction* true_exit = NULL;
  Instruction* false_exit = NULL;
  TargetEntryInstr* true_entry = new TargetEntryInstr();
  *test_fragment.true_successor_address() = true_entry;
  true_entry->SetSuccessor(true_fragment.entry());
  true_exit = true_fragment.is_empty() ? true_entry : true_fragment.exit();

  TargetEntryInstr* false_entry = new TargetEntryInstr();
  *test_fragment.false_successor_address() = false_entry;
  false_entry->SetSuccessor(false_fragment.entry());
  false_exit = false_fragment.is_empty() ? false_entry : false_fragment.exit();

  // 3. Add a join or select one (or neither) of the arms as exit.
  if (true_exit == NULL) {
    exit_ = false_exit;  // May be NULL.
    if (false_exit != NULL) temp_index_ = false_fragment.temp_index();
  } else if (false_exit == NULL) {
    exit_ = true_exit;
    temp_index_ = true_fragment.temp_index();
  } else {
    exit_ = new JoinEntryInstr();
    true_exit->SetSuccessor(exit_);
    false_exit->SetSuccessor(exit_);
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
  Instruction* body_exit = NULL;
  TargetEntryInstr* body_entry = new TargetEntryInstr();
  *test_fragment.true_successor_address() = body_entry;
  body_entry->SetSuccessor(body_fragment.entry());
  body_exit = body_fragment.is_empty() ? body_entry : body_fragment.exit();

  // 2. Connect the test to this graph, including the body if reachable and
  // using a fresh join node if the body is reachable and has an open exit.
  if (body_exit == NULL) {
    Append(test_fragment);
  } else {
    JoinEntryInstr* join = new JoinEntryInstr();
    AddInstruction(join);
    join->SetSuccessor(test_fragment.entry());
    body_exit->SetSuccessor(join);
  }

  // 3. Set the exit to the graph to be the false successor of the test, a
  // fresh target node
  exit_ = *test_fragment.false_successor_address() = new TargetEntryInstr();
}


Computation* EffectGraphVisitor::BuildStoreLocal(
    const LocalVariable& local, Value* value) {
  if (local.is_captured()) {
    intptr_t delta = owner()->context_level() -
                     local.owner()->context_level();
    ASSERT(delta >= 0);
    BindInstr* context = new BindInstr(new CurrentContextComp());
    AddInstruction(context);
    Value* context_value = new UseVal(context);
    while (delta-- > 0) {
      BindInstr* load = new BindInstr(new NativeLoadFieldComp(
          context_value, Context::parent_offset()));
      AddInstruction(load);
      context_value = new UseVal(load);
    }
    Computation* store = new NativeStoreFieldComp(
        context_value, Context::variable_offset(local.index()), value);
    return store;
  } else {
    return new StoreLocalComp(local, value, owner()->context_level());
  }
}


Computation* EffectGraphVisitor::BuildLoadLocal(const LocalVariable& local) {
  if (local.is_captured()) {
    intptr_t delta = owner()->context_level() -
                     local.owner()->context_level();
    ASSERT(delta >= 0);
    BindInstr* context = new BindInstr(new CurrentContextComp());
    AddInstruction(context);
    Value* context_value = new UseVal(context);
    while (delta-- > 0) {
      BindInstr* load = new BindInstr(new NativeLoadFieldComp(
          context_value, Context::parent_offset()));
      AddInstruction(load);
      context_value = new UseVal(load);
    }
    Computation* store = new NativeLoadFieldComp(
        context_value, Context::variable_offset(local.index()));
    return store;
  } else {
    return new LoadLocalComp(local, owner()->context_level());
  }
}


// Stores current context into the 'variable'
void EffectGraphVisitor::BuildStoreContext(const LocalVariable& variable) {
  BindInstr* context = new BindInstr(new CurrentContextComp());
  AddInstruction(context);
  Computation* store_context = BuildStoreLocal(variable, new UseVal(context));
  AddInstruction(new DoInstr(store_context));
}


// Loads context saved in 'context_variable' into the current context.
void EffectGraphVisitor::BuildLoadContext(const LocalVariable& variable) {
  BindInstr* load_saved_context = new BindInstr(BuildLoadLocal(variable));
  AddInstruction(load_saved_context);
  DoInstr* store_context =
      new DoInstr(new StoreContextComp(new UseVal(load_saved_context)));
  AddInstruction(store_context);
}



void TestGraphVisitor::ReturnValue(Value* value) {
  if (FLAG_enable_type_checks) {
    BindInstr* assert_boolean =
        new BindInstr(new AssertBooleanComp(condition_token_index(),
                                            owner()->try_index(),
                                            value));
    AddInstruction(assert_boolean);
    value = new UseVal(assert_boolean);
  }
  BranchInstr* branch = new BranchInstr(value);
  AddInstruction(branch);
  CloseFragment();
  true_successor_address_ = branch->true_successor_address();
  false_successor_address_ = branch->false_successor_address();
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
    const RawFunction::Kind kind = owner()->parsed_function().function().kind();
    const bool is_implicit_getter =
        (kind == RawFunction::kImplicitGetter) ||
        (kind == RawFunction::kConstImplicitGetter);
    const bool is_static = owner()->parsed_function().function().is_static();
    // Implicit getters do not need a type check at return, unless they compute
    // the initial value of a static field.
    if (is_static || !is_implicit_getter) {
      const AbstractType& dst_type =
          AbstractType::ZoneHandle(
              owner()->parsed_function().function().result_type());
      const String& dst_name =
          String::ZoneHandle(String::NewSymbol("function result"));
      return_value = BuildAssignableValue(node->value(),
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

  AddInstruction(
      new ReturnInstr(node->token_index(), return_value));
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


// Returns true if the type check can be skipped, for example, if the type is
// Dynamic or if the value is a compile time constant and an instance of type.
static bool CanSkipTypeCheck(AstNode* value, const AbstractType& dst_type) {
  ASSERT(FLAG_enable_type_checks);
  ASSERT(!dst_type.IsNull());
  ASSERT(dst_type.IsFinalized());

  // Any expression is assignable to the Dynamic type and to the Object type.
  // Skip the test.
  if (!dst_type.IsMalformed() &&
      (dst_type.IsDynamicType() || dst_type.IsObjectType())) {
    return true;
  }

  // It is a compile-time error to explicitly return a value (including null)
  // from a void function. However, functions that do not explicitly return a
  // value, implicitly return null. This includes void functions. Therefore, we
  // skip the type test here and trust the parser to only return null in void
  // function.
  if (dst_type.IsVoidType()) {
    return true;
  }

  // Eliminate the test if it can be performed successfully at compile time.
  if ((value != NULL) && value->IsLiteralNode()) {
    const Instance& literal_value = value->AsLiteralNode()->literal();
    const Class& cls = Class::Handle(literal_value.clazz());
    if (cls.IsNullClass()) {
      // There are only three instances that can be of Class Null:
      // Object::null(), Object::sentinel(), and Object::transition_sentinel().
      // The inline code and run time code performing the type check will never
      // encounter the 2 sentinel values. The type check of a sentinel value
      // will always be eliminated here, because these sentinel values can only
      // be encountered as constants, never as actual value of an heap object
      // being type checked.
      ASSERT(literal_value.IsNull() ||
             (literal_value.raw() == Object::sentinel()) ||
             (literal_value.raw() == Object::transition_sentinel()));
      return true;
    }
    Error& malformed_error = Error::Handle();
    if (!dst_type.IsMalformed() &&
        dst_type.IsInstantiated() &&
        literal_value.IsInstanceOf(dst_type,
                                   TypeArguments::Handle(),
                                   &malformed_error)) {
      return true;
    }
  }

  return false;
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
  ReturnValue(BuildAssignableValue(node->expr(),
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
                              node->left()->token_index());
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
  ValueGraphVisitor for_right_value(owner(), temp_index());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(for_left_value.value());
  arguments->Add(for_right_value.value());
  const String& name = String::ZoneHandle(String::NewSymbol(node->Name()));
  InstanceCallComp* call = new InstanceCallComp(node->token_index(),
                                                owner()->try_index(),
                                                name,
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
                              node->left()->token_index());
    node->left()->Visit(&for_test);

    ValueGraphVisitor for_right(owner(), temp_index());
    node->right()->Visit(&for_right);
    Value* right_value = for_right.value();
    if (FLAG_enable_type_checks) {
      BindInstr* assert_boolean =
          new BindInstr(new AssertBooleanComp(node->right()->token_index(),
                                              owner()->try_index(),
                                              right_value));
      for_right.AddInstruction(assert_boolean);
      right_value = new UseVal(assert_boolean);
    }
    BindInstr* constant_true = new BindInstr(new ConstantVal(bool_true));
    for_right.AddInstruction(constant_true);
    BindInstr* comp =
        new BindInstr(new StrictCompareComp(Token::kEQ_STRICT,
                                            right_value,
                                            new UseVal(constant_true)));
    for_right.AddInstruction(comp);
    for_right.AddInstruction(
        new DoInstr(BuildStoreLocal(
            *owner()->parsed_function().expression_temp_var(),
            new UseVal(comp))));

    if (node->kind() == Token::kAND) {
      ValueGraphVisitor for_false(owner(), temp_index());
      BindInstr* constant_false = new BindInstr(new ConstantVal(bool_false));
      for_false.AddInstruction(constant_false);
      for_false.AddInstruction(
          new DoInstr(BuildStoreLocal(
              *owner()->parsed_function().expression_temp_var(),
              new UseVal(constant_false))));
      Join(for_test, for_right, for_false);
    } else {
      ASSERT(node->kind() == Token::kOR);
      ValueGraphVisitor for_true(owner(), temp_index());
      BindInstr* constant_true = new BindInstr(new ConstantVal(bool_true));
      for_true.AddInstruction(constant_true);
      for_true.AddInstruction(
          new DoInstr(BuildStoreLocal(
              *owner()->parsed_function().expression_temp_var(),
              new UseVal(constant_true))));
      Join(for_test, for_true, for_right);
    }
    ReturnComputation(
        BuildLoadLocal(*owner()->parsed_function().expression_temp_var()));
    return;
  }
  EffectGraphVisitor::VisitBinaryOpNode(node);
}


void EffectGraphVisitor::CompiletimeStringInterpolation(
    const Function& interpol_func, const Array& literals) {
  // Do nothing.
}


void ValueGraphVisitor::CompiletimeStringInterpolation(
    const Function& interpol_func, const Array& literals) {
  // Build argument array to pass to the interpolation function.
  GrowableArray<const Object*> interpolate_arg;
  interpolate_arg.Add(&literals);
  const Array& kNoArgumentNames = Array::Handle();
  // Call the interpolation function.
  String& concatenated = String::ZoneHandle();
  concatenated ^= DartEntry::InvokeStatic(interpol_func,
                                          interpolate_arg,
                                          kNoArgumentNames);
  if (concatenated.IsUnhandledException()) {
    // TODO(srdjan): Remove this node and this UNREACHABLE.
    UNREACHABLE();
  }
  ASSERT(!concatenated.IsNull());
  concatenated = String::NewSymbol(concatenated);
  ReturnComputation(new ConstantVal(concatenated));
}



// TODO(srdjan): Remove this node once the "+" string operator has been
// eliminated.
void EffectGraphVisitor::VisitStringConcatNode(StringConcatNode* node) {
  const String& cls_name = String::Handle(String::NewSymbol("StringBase"));
  const Library& core_lib = Library::Handle(
      Isolate::Current()->object_store()->core_library());
  const Class& cls = Class::Handle(core_lib.LookupClass(cls_name));
  ASSERT(!cls.IsNull());
  const String& func_name = String::Handle(String::NewSymbol("_interpolate"));
  const int number_of_parameters = 1;
  const Function& interpol_func = Function::ZoneHandle(
      Resolver::ResolveStatic(cls, func_name,
                              number_of_parameters,
                              Array::Handle(),
                              Resolver::kIsQualified));
  ASSERT(!interpol_func.IsNull());

  // First try to concatenate and canonicalize the values at compile time.
  bool compile_time_interpolation = true;
  Array& literals = Array::Handle(Array::New(node->values()->length()));
  for (int i = 0; i < node->values()->length(); i++) {
    if (node->values()->ElementAt(i)->IsLiteralNode()) {
      LiteralNode* lit = node->values()->ElementAt(i)->AsLiteralNode();
      literals.SetAt(i, lit->literal());
    } else {
      compile_time_interpolation = false;
      break;
    }
  }
  if (compile_time_interpolation) {
    // Not needed for effect, only for value
    CompiletimeStringInterpolation(interpol_func, literals);
    return;
  }
  // Runtime string interpolation.
  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>();
  ArgumentListNode* interpol_arg = new ArgumentListNode(node->token_index());
  interpol_arg->Add(node->values());
  TranslateArgumentList(*interpol_arg, values);
  StaticCallComp* call =
      new StaticCallComp(node->token_index(),
                         owner()->try_index(),
                         interpol_func,
                         interpol_arg->names(),
                         values);
  ReturnComputation(call);
}


void EffectGraphVisitor::BuildAssertAssignable(intptr_t token_index,
                                               Value* value,
                                               const AbstractType& dst_type,
                                               const String& dst_name) {
  // Build the type check computation.
  Value* instantiator_type_arguments = NULL;
  if (!dst_type.IsInstantiated()) {
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_index);
  }
  AssertAssignableComp* assert_assignable =
      new AssertAssignableComp(token_index,
                               owner()->try_index(),
                               value,
                               instantiator_type_arguments,
                               dst_type,
                               dst_name);
  AddInstruction(new DoInstr(assert_assignable));
}


Value* EffectGraphVisitor::BuildAssignableValue(AstNode* value_node,
                                                Value* value,
                                                const AbstractType& dst_type,
                                                const String& dst_name) {
  if (CanSkipTypeCheck(value_node, dst_type)) {
    return value;
  }

  // Build the type check computation.
  Value* instantiator_type_arguments = NULL;
  if (!dst_type.IsInstantiated()) {
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(value_node->token_index());
  }
  BindInstr* assert_assignable =
      new BindInstr(new AssertAssignableComp(value_node->token_index(),
                                             owner()->try_index(),
                                             value,
                                             instantiator_type_arguments,
                                             dst_type,
                                             dst_name));
  AddInstruction(assert_assignable);
  return new UseVal(assert_assignable);
}


void EffectGraphVisitor::BuildInstanceOf(ComparisonNode* node) {
  ASSERT(Token::IsInstanceofOperator(node->kind()));
  EffectGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
}


void ValueGraphVisitor::BuildInstanceOf(ComparisonNode* node) {
  ASSERT(Token::IsInstanceofOperator(node->kind()));
  const Bool& bool_true = Bool::ZoneHandle(Bool::True());
  const Bool& bool_false = Bool::ZoneHandle(Bool::False());
  const AbstractType& type = node->right()->AsTypeNode()->type();
  ASSERT(type.IsFinalized() && !type.IsMalformed());
  const bool negate_result = (node->kind() == Token::kISNOT);
  // All objects are instances of type T if Object type is a subtype of type T.
  const Type& object_type =
      Type::Handle(Isolate::Current()->object_store()->object_type());
  Error& malformed_error = Error::Handle();
  if (type.IsInstantiated() &&
      object_type.IsSubtypeOf(type, &malformed_error)) {
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
      Error& malformed_error = Error::Handle();
      if (literal_value.IsInstanceOf(type,
                                     TypeArguments::Handle(),
                                     &malformed_error)) {
        result = new ConstantVal(negate_result ? bool_false : bool_true);
      } else {
        ASSERT(malformed_error.IsNull());
        result = new ConstantVal(negate_result ? bool_true : bool_false);
      }
    }
    ReturnComputation(result);
    return;
  }

  ValueGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  Value* type_arguments = NULL;
  if (!type.IsInstantiated()) {
    type_arguments =
        BuildInstantiatorTypeArguments(node->token_index());
  }
  InstanceOfComp* instance_of =
      new InstanceOfComp(node->token_index(),
                         owner()->try_index(),
                         for_left_value.value(),
                         type_arguments,
                         node->right()->AsTypeNode()->type(),
                         (node->kind() == Token::kISNOT));
  ReturnComputation(instance_of);
}


// <Expression> :: Comparison { kind:  Token::Kind
//                              left:  <Expression>
//                              right: <Expression> }
// TODO(srdjan): Implement new equality.
void EffectGraphVisitor::VisitComparisonNode(ComparisonNode* node) {
  if (Token::IsInstanceofOperator(node->kind())) {
    BuildInstanceOf(node);
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
    EqualityCompareComp* comp = new EqualityCompareComp(
        node->token_index(), owner()->try_index(),
        for_left_value.value(), for_right_value.value());
    if (node->kind() == Token::kEQ) {
      ReturnComputation(comp);
    } else {
      Definition* eq_result = new BindInstr(comp);
      AddInstruction(eq_result);
      if (FLAG_enable_type_checks) {
        eq_result =
            new BindInstr(new AssertBooleanComp(node->token_index(),
                                                owner()->try_index(),
                                                new UseVal(eq_result)));
        AddInstruction(eq_result);
      }
      BooleanNegateComp* negate = new BooleanNegateComp(new UseVal(eq_result));
      ReturnComputation(negate);
    }
    return;
  }

  ValueGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  ValueGraphVisitor for_right_value(owner(), temp_index());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(for_left_value.value());
  arguments->Add(for_right_value.value());
  const String& name = String::ZoneHandle(String::NewSymbol(node->Name()));
  InstanceCallComp* call = new InstanceCallComp(
      node->token_index(), owner()->try_index(), name,
      arguments, Array::ZoneHandle(), 2);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitUnaryOpNode(UnaryOpNode* node) {
  // "!" cannot be overloaded, therefore do not call operator.
  if (node->kind() == Token::kNOT) {
    ValueGraphVisitor for_value(owner(), temp_index());
    node->operand()->Visit(&for_value);
    Append(for_value);
    Value* value = for_value.value();
    if (FLAG_enable_type_checks) {
      BindInstr* assert_boolean =
          new BindInstr(new AssertBooleanComp(node->operand()->token_index(),
                                              owner()->try_index(),
                                              value));
      AddInstruction(assert_boolean);
      value = new UseVal(assert_boolean);
    }
    BooleanNegateComp* negate = new BooleanNegateComp(value);
    ReturnComputation(negate);
    return;
  }
  ValueGraphVisitor for_value(owner(), temp_index());
  node->operand()->Visit(&for_value);
  Append(for_value);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(1);
  arguments->Add(for_value.value());
  const String& name =
      String::ZoneHandle(String::NewSymbol((node->kind() == Token::kSUB)
                                               ? Token::Str(Token::kNEGATE)
                                               : node->Name()));
  InstanceCallComp* call = new InstanceCallComp(
      node->token_index(), owner()->try_index(), name,
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_index());
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
                            node->condition()->token_index());
  node->condition()->Visit(&for_test);

  ValueGraphVisitor for_true(owner(), temp_index());
  node->true_expr()->Visit(&for_true);
  ASSERT(for_true.is_open());
  for_true.AddInstruction(new DoInstr(BuildStoreLocal(
      *owner()->parsed_function().expression_temp_var(), for_true.value())));

  ValueGraphVisitor for_false(owner(), temp_index());
  node->false_expr()->Visit(&for_false);
  ASSERT(for_false.is_open());
  for_false.AddInstruction(new DoInstr(BuildStoreLocal(
      *owner()->parsed_function().expression_temp_var(), for_false.value())));

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
                            node->condition()->token_index());
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
    if (is_open()) {
      AddInstruction(node->label()->join_for_break());
    } else {
      exit_ = node->label()->join_for_break();
    }
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
  const bool needs_join_at_statement_entry =
      (len > 1) || ((len > 0) && (node->contains_default()));
  EffectGraphVisitor for_case_statements(owner(), temp_index());
  // Compute start of statements fragment.
  BlockEntryInstr* statement_start = NULL;
  if ((node->label() != NULL) && (node->label()->is_continue_target())) {
    // Since a labeled jump continue statement occur in a different case node,
    // allocate JoinNode here and use it as statement start.
    if (node->label()->join_for_continue() == NULL) {
      node->label()->set_join_for_continue(new JoinEntryInstr());
    }
    statement_start = node->label()->join_for_continue();
  } else if (needs_join_at_statement_entry) {
    statement_start = new JoinEntryInstr();
  } else {
    statement_start = new TargetEntryInstr();
  }
  for_case_statements.AddInstruction(statement_start);
  node->statements()->Visit(&for_case_statements);
  if (is_open() && (len == 0)) {
    ASSERT(node->contains_default());
    // Default only case node.
    Append(for_case_statements);
    return;
  }

  // Generate instructions for all case expressions and collect data to
  // connect them.
  GrowableArray<TargetEntryInstr**> case_true_addresses;
  GrowableArray<TargetEntryInstr**> case_false_addresses;
  GrowableArray<TargetEntryInstr*> case_entries;
  for (intptr_t i = 0; i < len; i++) {
    AstNode* case_expr = node->case_expressions()->NodeAt(i);
    TestGraphVisitor for_case_expression(owner(),
                                         temp_index(),
                                         case_expr->token_index());
    if (i == 0) {
      case_entries.Add(NULL);  // Not to be used
      case_expr->Visit(&for_case_expression);
      // Append only the first one, everything else is connected from it.
      Append(for_case_expression);
    } else {
      TargetEntryInstr* case_entry_target = new TargetEntryInstr();
      case_entries.Add(case_entry_target);
      for_case_expression.AddInstruction(case_entry_target);
      case_expr->Visit(&for_case_expression);
    }
    case_true_addresses.Add(for_case_expression.true_successor_address());
    case_false_addresses.Add(for_case_expression.false_successor_address());
  }

  // Once a test fragment has been added, this fragment is closed.
  ASSERT(!is_open());

  // Connect all test cases except the last one.
  for (intptr_t i = 0; i < (len - 1); i++) {
    ASSERT(needs_join_at_statement_entry);
    *case_false_addresses[i] = case_entries[i + 1];
    TargetEntryInstr* true_target = new TargetEntryInstr();
    *case_true_addresses[i] = true_target;
    true_target->SetSuccessor(statement_start);
  }

  BlockEntryInstr* exit_instruction = NULL;
  // Handle last (or only) case: false goes to exit or to statement if this
  // node contains default.
  if (len > 0) {
    if (statement_start->IsTargetEntry()) {
      *case_true_addresses[len - 1] = statement_start->AsTargetEntry();
    } else {
      TargetEntryInstr* true_target = new TargetEntryInstr();
      *case_true_addresses[len - 1] = true_target;
      true_target->SetSuccessor(statement_start);
    }
    TargetEntryInstr* false_target = new TargetEntryInstr();
    *case_false_addresses[len - 1] = false_target;
    if (node->contains_default()) {
      // True and false go to statement start.
      false_target->SetSuccessor(statement_start);
      if (for_case_statements.is_open()) {
        exit_instruction = new TargetEntryInstr();
        for_case_statements.exit()->SetSuccessor(exit_instruction);
      }
    } else {
      if (for_case_statements.is_open()) {
        exit_instruction = new JoinEntryInstr();
        for_case_statements.exit()->SetSuccessor(exit_instruction);
      } else {
        exit_instruction = new TargetEntryInstr();
      }
      false_target->SetSuccessor(exit_instruction);
    }
  } else {
    // A CaseNode without case expressions must contain default.
    ASSERT(node->contains_default());
    AddInstruction(statement_start);
  }

  ASSERT(!is_open());
  exit_ = exit_instruction;
}


// <Statement> ::= While { label:     SourceLabel
//                         condition: <Expression>
//                         body:      <Sequence> }
// The fragment is composed as follows:
// a) continue-join (optional)
// b) loop-join
// c) [ test ] -> (body-entry-target, loop-exit-target)
// d) body-entry-target
// e) [ body ] -> (loop-join)
// f) loop-exit-target
// g) break-join (optional)
void EffectGraphVisitor::VisitWhileNode(WhileNode* node) {
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_index());
  node->condition()->Visit(&for_test);
  ASSERT(!for_test.is_empty());  // Language spec.

  EffectGraphVisitor for_body(owner(), temp_index());
  node->body()->Visit(&for_body);

  // Labels are set after body traversal.
  SourceLabel* lbl = node->label();
  ASSERT(lbl != NULL);
  if (lbl->join_for_continue() != NULL) {
    AddInstruction(lbl->join_for_continue());
  }
  TieLoop(for_test, for_body);
  if (lbl->join_for_break() != NULL) {
    AddInstruction(lbl->join_for_break());
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
  node->body()->Visit(&for_body);

  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->token_index());
  node->condition()->Visit(&for_test);
  ASSERT(is_open());

  // Tie do-while loop (test is after the body).
  JoinEntryInstr* body_entry_join = new JoinEntryInstr();
  AddInstruction(body_entry_join);
  body_entry_join->SetSuccessor(for_body.entry());
  Instruction* body_exit =
      for_body.is_empty() ? body_entry_join : for_body.exit();

  if (for_body.is_open() || (node->label()->join_for_continue() != NULL)) {
    BlockEntryInstr* test_entry = NULL;
    if (node->label()->join_for_continue() == NULL) {
      test_entry = new TargetEntryInstr();
    } else {
      test_entry = node->label()->join_for_continue();
    }
    test_entry->SetSuccessor(for_test.entry());
    if (body_exit != NULL) {
      body_exit->SetSuccessor(test_entry);
    }
  }

  TargetEntryInstr* back_target_entry = new TargetEntryInstr();
  *for_test.true_successor_address() = back_target_entry;
  back_target_entry->SetSuccessor(body_entry_join);
  TargetEntryInstr* loop_exit_target = new TargetEntryInstr();
  *for_test.false_successor_address() = loop_exit_target;
  if (node->label()->join_for_break() == NULL) {
    exit_ = loop_exit_target;
  } else {
    loop_exit_target->SetSuccessor(node->label()->join_for_break());
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
  TargetEntryInstr* body_entry = new TargetEntryInstr();
  for_body.AddInstruction(body_entry);
  node->body()->Visit(&for_body);

  // Join loop body, increment and compute their end instruction.
  ASSERT(!for_body.is_empty());
  Instruction* loop_increment_end = NULL;
  EffectGraphVisitor for_increment(owner(), temp_index());
  if ((node->label()->join_for_continue() == NULL) && for_body.is_open()) {
    // Do not insert an extra basic block.
    node->increment()->Visit(&for_increment);
    for_body.Append(for_increment);
    loop_increment_end = for_body.exit();
    // 'for_body' contains at least the TargetInstruction 'body_entry'.
    ASSERT(loop_increment_end != NULL);
  } else if (node->label()->join_for_continue() != NULL) {
    // Insert join between body and increment.
    if (for_body.is_open()) {
      for_body.exit()->SetSuccessor(node->label()->join_for_continue());
    }
    for_increment.AddInstruction(node->label()->join_for_continue());
    node->increment()->Visit(&for_increment);
    loop_increment_end = for_increment.exit();
    ASSERT(loop_increment_end != NULL);
  } else {
    loop_increment_end = NULL;
    ASSERT(!for_body.is_open() && node->label()->join_for_continue() == NULL);
  }

  // 'loop_increment_end' is NULL only if there is no join for continue and the
  // body is not open, i.e., no backward branch exists.
  if (loop_increment_end != NULL) {
    JoinEntryInstr* loop_start = new JoinEntryInstr();
    AddInstruction(loop_start);
    loop_increment_end->SetSuccessor(loop_start);
  }

  if (node->condition() == NULL) {
    // Endless loop, no test.
    Append(for_body);
    if (node->label()->join_for_break() == NULL) {
      CloseFragment();
    } else {
      // Control flow of ForLoop continues into join_for_break.
      exit_ = node->label()->join_for_break();
    }
  } else {
    TargetEntryInstr* loop_exit = new TargetEntryInstr();
    TestGraphVisitor for_test(owner(),
                              temp_index(),
                              node->condition()->token_index());
    node->condition()->Visit(&for_test);
    Append(for_test);
    *for_test.true_successor_address() = body_entry;
    *for_test.false_successor_address() = loop_exit;
    if (node->label()->join_for_break() == NULL) {
      exit_ = loop_exit;
    } else {
      loop_exit->SetSuccessor(node->label()->join_for_break());
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

  Instruction* jump_target = NULL;
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
  AddInstruction(jump_target);
  CloseFragment();
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
    values->Add(for_value.value());
  }
  Value* element_type = new UseVal(
      BuildInstantiatedTypeArguments(node->token_index(),
                                     node->type_arguments()));
  CreateArrayComp* create = new CreateArrayComp(node->token_index(),
                                                owner()->try_index(),
                                                values,
                                                element_type);
  ReturnComputation(create);
}


void EffectGraphVisitor::VisitClosureNode(ClosureNode* node) {
  const Function& function = node->function();

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
  } else if (function.IsImplicitInstanceClosureFunction()) {
    ValueGraphVisitor for_receiver(owner(), temp_index());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
  }
  ASSERT(function.context_scope() != ContextScope::null());

  // The function type of a closure may have type arguments. In that case, pass
  // the type arguments of the instantiator.
  const Class& cls = Class::Handle(function.signature_class());
  ASSERT(!cls.IsNull());
  const bool requires_type_arguments = cls.HasTypeArguments();
  Value* type_arguments = NULL;
  if (requires_type_arguments) {
    ASSERT(!function.IsImplicitStaticClosureFunction());
    type_arguments =
        BuildInstantiatorTypeArguments(node->token_index());
  }

  CreateClosureComp* create =
      new CreateClosureComp(node, owner()->try_index(), type_arguments);
  ReturnComputation(create);
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

void EffectGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  ArgumentListNode* arguments = node->arguments();
  int length = arguments->length();
  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>(length + 1);

  ValueGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  values->Add(for_receiver.value());

  TranslateArgumentList(*arguments, values);
  InstanceCallComp* call = new InstanceCallComp(
      node->token_index(), owner()->try_index(),
      node->function_name(), values,
                           arguments->names(), 1);
  ReturnComputation(call);
}


// <Expression> ::= StaticCall { function: Function
//                               arguments: <ArgumentList> }
void EffectGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  int length = node->arguments()->length();
  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>(length);
  TranslateArgumentList(*node->arguments(), values);
  StaticCallComp* call =
      new StaticCallComp(node->token_index(),
                         owner()->try_index(),
                         node->function(),
                         node->arguments()->names(),
                         values);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  // Context is saved around the call, it's treated as an extra operand
  // consumed by the call (but not an argument).
  BindInstr* context = new BindInstr(new CurrentContextComp());
  AddInstruction(context);

  ValueGraphVisitor for_closure(owner(), temp_index());
  node->closure()->Visit(&for_closure);
  Append(for_closure);

  ZoneGrowableArray<Value*>* arguments =
      new ZoneGrowableArray<Value*>(node->arguments()->length());
  arguments->Add(for_closure.value());
  TranslateArgumentList(*node->arguments(), arguments);
  // First operand is the saved context, consumed by the call.
  ClosureCallComp* call =  new ClosureCallComp(node,
                                               owner()->try_index(),
                                               new UseVal(context),
                                               arguments);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  BindInstr* context = new BindInstr(new CurrentContextComp());
  AddInstruction(context);
  BindInstr* clone =
      new BindInstr(new CloneContextComp(node->token_index(),
                                         owner()->try_index(),
                                         new UseVal(context)));
  AddInstruction(clone);
  ReturnComputation(new StoreContextComp(new UseVal(clone)));
}


Definition* EffectGraphVisitor::BuildObjectAllocation(
    ConstructorCallNode* node) {
  const Class& cls = Class::ZoneHandle(node->constructor().owner());
  const bool requires_type_arguments = cls.HasTypeArguments();

  ZoneGrowableArray<Value*>* allocate_arguments =
      new ZoneGrowableArray<Value*>();
  if (requires_type_arguments) {
    BuildConstructorTypeArguments(node, allocate_arguments);
  }
  // In checked mode, if the type arguments are uninstantiated, they may need to
  // be checked against declared bounds at run time.
  Computation* allocate_comp = NULL;
  Error& malformed_error = Error::Handle();
  if (FLAG_enable_type_checks &&
      requires_type_arguments &&
      !node->type_arguments().IsNull() &&
      !node->type_arguments().IsInstantiated() &&
      !node->type_arguments().IsWithinBoundsOf(cls,
                                               node->type_arguments(),
                                               &malformed_error)) {
    // The uninstantiated type arguments cannot be verified to be within their
    // bounds at compile time, so verify them at runtime.
    // Although the type arguments may be uninstantiated at compile time, they
    // may represent the identity vector and may be replaced by the instantiated
    // type arguments of the instantiator at run time.
    allocate_comp = new AllocateObjectWithBoundsCheckComp(node,
                                                          owner()->try_index(),
                                                          allocate_arguments);
  } else {
    allocate_comp = new AllocateObjectComp(node,
                                           owner()->try_index(),
                                           allocate_arguments);
  }
  BindInstr* allocate = new BindInstr(allocate_comp);
  AddInstruction(allocate);
  return allocate;
}


void EffectGraphVisitor::BuildConstructorCall(ConstructorCallNode* node,
                                              Value* alloc_value) {
  BindInstr* ctor_arg =
      new BindInstr(new ConstantVal(
                        Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll))));
  AddInstruction(ctor_arg);

  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>();
  values->Add(alloc_value);
  values->Add(new UseVal(ctor_arg));

  TranslateArgumentList(*node->arguments(), values);
  StaticCallComp* call =
      new StaticCallComp(node->token_index(),
                         owner()->try_index(),
                         node->constructor(),
                         node->arguments()->names(),
                         values);
  AddInstruction(new DoInstr(call));
}


void EffectGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  if (node->constructor().IsFactory()) {
    ZoneGrowableArray<Value*>* factory_arguments =
        new ZoneGrowableArray<Value*>();
    factory_arguments->Add(
        new UseVal(BuildInstantiatedTypeArguments(node->token_index(),
                                                  node->type_arguments())));
    ASSERT(factory_arguments->length() == 1);
    TranslateArgumentList(*node->arguments(), factory_arguments);
    StaticCallComp* call =
        new StaticCallComp(node->token_index(),
                           owner()->try_index(),
                           node->constructor(),
                           node->arguments()->names(),
                           factory_arguments);
    ReturnComputation(call);
    return;
  }
  // t_n contains the allocated and initialized object.
  //   t_n      <- AllocateObject(class)
  //   t_n+1    <- ctor-arg
  //   t_n+2... <- constructor arguments start here
  //   StaticCall(constructor, t_n+1, t_n+2, ...)
  // No need to preserve allocated value (simpler than in ValueGraphVisitor).
  Definition* allocate = BuildObjectAllocation(node);
  BuildConstructorCall(node, new UseVal(allocate));
}


Value* EffectGraphVisitor::BuildInstantiatorTypeArguments(
    intptr_t token_index) {
  const Class& instantiator_class = Class::Handle(
      owner()->parsed_function().function().owner());
  if (instantiator_class.NumTypeParameters() == 0) {
    // The type arguments are compile time constants.
    AbstractTypeArguments& type_arguments = AbstractTypeArguments::ZoneHandle();
    // TODO(regis): Temporary type should be allocated in new gen heap.
    Type& type = Type::Handle(
        Type::New(instantiator_class, type_arguments, token_index));
    type ^= ClassFinalizer::FinalizeType(
        instantiator_class, type, ClassFinalizer::kFinalizeWellFormed);
    type_arguments = type.arguments();
    BindInstr* args = new BindInstr(new ConstantVal(type_arguments));
    AddInstruction(args);
    return new UseVal(args);
  }
  ASSERT(owner()->parsed_function().instantiator() != NULL);
  ValueGraphVisitor for_instantiator(owner(), temp_index());
  owner()->parsed_function().instantiator()->Visit(&for_instantiator);
  Append(for_instantiator);
  Function& outer_function =
      Function::Handle(owner()->parsed_function().function().raw());
  while (outer_function.IsLocalFunction()) {
    outer_function = outer_function.parent_function();
  }
  if (outer_function.IsFactory()) {
    // All OK.
    return for_instantiator.value();
  }

  // The instantiator is the receiver of the caller, which is not a factory.
  // The receiver cannot be null; extract its AbstractTypeArguments object.
  // Note that in the factory case, the instantiator is the first parameter
  // of the factory, i.e. already an AbstractTypeArguments object.
  intptr_t type_arguments_instance_field_offset =
      instantiator_class.type_arguments_instance_field_offset();
  ASSERT(type_arguments_instance_field_offset != Class::kNoTypeArguments);

  BindInstr* load =
      new BindInstr(new NativeLoadFieldComp(
                        for_instantiator.value(),
                        type_arguments_instance_field_offset));
  AddInstruction(load);
  return new UseVal(load);
}


Definition* EffectGraphVisitor::BuildInstantiatedTypeArguments(
    intptr_t token_index,
    const AbstractTypeArguments& type_arguments) {
  if (type_arguments.IsNull() || type_arguments.IsInstantiated()) {
    BindInstr* type_args =
        new BindInstr(new ConstantVal(type_arguments));
    AddInstruction(type_args);
    return type_args;
  }
  // The type arguments are uninstantiated.
  Value* instantiator_value = BuildInstantiatorTypeArguments(token_index);
  BindInstr* instantiate =
      new BindInstr(new InstantiateTypeArgumentsComp(token_index,
                                                     owner()->try_index(),
                                                     type_arguments,
                                                     instantiator_value));
  AddInstruction(instantiate);
  return instantiate;
}


void EffectGraphVisitor::BuildConstructorTypeArguments(
    ConstructorCallNode* node,
    ZoneGrowableArray<Value*>* args) {
  const Class& cls = Class::ZoneHandle(node->constructor().owner());
  ASSERT(cls.HasTypeArguments() && !node->constructor().IsFactory());
  if (node->type_arguments().IsNull() ||
      node->type_arguments().IsInstantiated()) {
    BindInstr* type_args =
        new BindInstr(new ConstantVal(node->type_arguments()));
    AddInstruction(type_args);
    // No instantiator required.
    BindInstr* no_instantiator =
        new BindInstr(new ConstantVal(
                          Smi::ZoneHandle(Smi::New(
                              StubCode::kNoInstantiator))));
    AddInstruction(no_instantiator);
    args->Add(new UseVal(type_args));
    args->Add(new UseVal(no_instantiator));
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
  Value* instantiator = BuildInstantiatorTypeArguments(node->token_index());
  ASSERT(instantiator->IsUse());
  Definition* stored_instantiator = new BindInstr(
      BuildStoreLocal(t1, instantiator));
  AddInstruction(stored_instantiator);
  // t1: instantiator type arguments.

  BindInstr* extract_type_arguments = new BindInstr(
      new ExtractConstructorTypeArgumentsComp(
          node->token_index(),
          owner()->try_index(),
          node->type_arguments(),
          new UseVal(stored_instantiator)));
  AddInstruction(extract_type_arguments);

  Instruction* stored_type_arguments = new DoInstr(
      BuildStoreLocal(t2, new UseVal(extract_type_arguments)));
  AddInstruction(stored_type_arguments);
  // t2: extracted constructor type arguments.
  Definition* load_instantiator = new BindInstr(BuildLoadLocal(t1));
  AddInstruction(load_instantiator);

  BindInstr* extract_instantiator =
      new BindInstr(new ExtractConstructorInstantiatorComp(
                        node,
                        new UseVal(load_instantiator)));
  AddInstruction(extract_instantiator);
  AddInstruction(new DoInstr(
      BuildStoreLocal(t1, new UseVal(extract_instantiator))));
  // t2: extracted constructor type arguments.
  // t1: extracted constructor instantiator.
  Definition* load_0 = new BindInstr(BuildLoadLocal(t2));
  AddInstruction(load_0);
  Definition* load_1 = new BindInstr(BuildLoadLocal(t1));
  AddInstruction(load_1);
  args->Add(new UseVal(load_0));
  args->Add(new UseVal(load_1));
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

  Definition* allocate = BuildObjectAllocation(node);
  Computation* store_allocated = BuildStoreLocal(
      node->allocated_object_var(),
      new UseVal(allocate));
  Definition* allocated_value = new BindInstr(store_allocated);
  AddInstruction(allocated_value);
  BuildConstructorCall(node, new UseVal(allocated_value));
  Computation* load_allocated = BuildLoadLocal(
      node->allocated_object_var());
  allocated_value = new BindInstr(load_allocated);
  AddInstruction(allocated_value);
  ReturnValue(new UseVal(allocated_value));
}


void EffectGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  ValueGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(1);
  arguments->Add(for_receiver.value());
  const String& name =
      String::ZoneHandle(Field::GetterSymbol(node->field_name()));
  InstanceCallComp* call = new InstanceCallComp(
      node->token_index(), owner()->try_index(), name,
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  ValueGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  ValueGraphVisitor for_value(owner(), for_receiver.temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  InstanceSetterComp* setter =
      new InstanceSetterComp(node->token_index(),
                             owner()->try_index(),
                             node->field_name(),
                             for_receiver.value(),
                             for_value.value());
  ReturnComputation(setter);
}


void EffectGraphVisitor::VisitStaticGetterNode(StaticGetterNode* node) {
  const String& getter_name =
      String::Handle(Field::GetterName(node->field_name()));
  const Function& getter_function =
      Function::ZoneHandle(node->cls().LookupStaticFunction(getter_name));
  ASSERT(!getter_function.IsNull());
  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>();
  StaticCallComp* call = new StaticCallComp(node->token_index(),
                                            owner()->try_index(),
                                            getter_function,
                                            Array::ZoneHandle(),  // No names.
                                            values);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  const String& setter_name =
      String::Handle(Field::SetterName(node->field_name()));
  const Function& setter_function =
      Function::ZoneHandle(node->cls().LookupStaticFunction(setter_name));
  ASSERT(!setter_function.IsNull());
  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  StaticSetterComp* call = new StaticSetterComp(node->token_index(),
                                                owner()->try_index(),
                                                setter_function,
                                                for_value.value());
  ReturnComputation(call);
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
    store_value = BuildAssignableValue(node->value(),
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
  LoadInstanceFieldComp* load =
      new LoadInstanceFieldComp(node, for_instance.value());
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
    store_value = BuildAssignableValue(node->value(),
                                       store_value,
                                       type,
                                       dst_name);
  }
  StoreInstanceFieldComp* store =
      new StoreInstanceFieldComp(node, for_instance.value(), store_value);
  ReturnComputation(store);
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
    store_value = BuildAssignableValue(node->value(),
                                       store_value,
                                       type,
                                       dst_name);
  }
  StoreStaticFieldComp* store =
      new StoreStaticFieldComp(node->field(), store_value);
  ReturnComputation(store);
}


void EffectGraphVisitor::VisitLoadIndexedNode(LoadIndexedNode* node) {
  ValueGraphVisitor for_array(owner(), temp_index());
  node->array()->Visit(&for_array);
  Append(for_array);
  ValueGraphVisitor for_index(owner(), for_array.temp_index());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(for_array.value());
  arguments->Add(for_index.value());
  const String& name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kINDEX)));
  InstanceCallComp* call = new InstanceCallComp(
      node->token_index(), owner()->try_index(), name,
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  ValueGraphVisitor for_array(owner(), temp_index());
  node->array()->Visit(&for_array);
  Append(for_array);
  ValueGraphVisitor for_index(owner(), for_array.temp_index());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  ValueGraphVisitor for_value(owner(), for_index.temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  StoreIndexedComp* store = new StoreIndexedComp(node->token_index(),
                                                 owner()->try_index(),
                                                 for_array.value(),
                                                 for_index.value(),
                                                 for_value.value());
  ReturnComputation(store);
}


bool EffectGraphVisitor::MustSaveRestoreContext(SequenceNode* node) const {
  return (node == owner()->parsed_function().node_sequence()) &&
         (owner()->parsed_function().saved_context_var() != NULL);
}


void EffectGraphVisitor::UnchainContext() {
  BindInstr* context = new BindInstr(new CurrentContextComp());
  AddInstruction(context);
  BindInstr* parent =
      new BindInstr(new NativeLoadFieldComp(
                        new UseVal(context), Context::parent_offset()));
  AddInstruction(parent);
  AddInstruction(new DoInstr(new StoreContextComp(new UseVal(parent))));
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
    BindInstr* allocated_context =
        new BindInstr(new AllocateContextComp(node->token_index(),
                                              owner()->try_index(),
                                              num_context_variables));
    AddInstruction(allocated_context);

    // If this node_sequence is the body of the function being compiled, and if
    // this function is not a closure, do not link the current context as the
    // parent of the newly allocated context, as it is not accessible. Instead,
    // save it in a pre-allocated variable and restore it on exit.
    if (MustSaveRestoreContext(node)) {
      BindInstr* current_context = new BindInstr(new CurrentContextComp());
      AddInstruction(current_context);
      Computation* store_local = BuildStoreLocal(
          *owner()->parsed_function().saved_context_var(),
          new UseVal(current_context));
      AddInstruction(new DoInstr(store_local));
      BindInstr* null_context =
          new BindInstr(new ConstantVal(Object::ZoneHandle()));
      AddInstruction(null_context);
      StoreContextComp* store_context =
          new StoreContextComp(new UseVal(null_context));
      AddInstruction(new DoInstr(store_context));
    }

    ChainContextComp* chain_context =
        new ChainContextComp(new UseVal(allocated_context));
    AddInstruction(new DoInstr(chain_context));
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
              parameter.name(), String::Handle(String::NewSymbol("-orig"))));
          LocalVariable* temp_local = new LocalVariable(
              0,  // Token index.
              temp_name,
              Type::ZoneHandle(Type::DynamicType()));  // Type.
          temp_local->set_index(param_frame_index);

          // Copy parameter from local frame to current context.
          BindInstr* load = new BindInstr(BuildLoadLocal(*temp_local));
          AddInstruction(load);
          Computation* store_local =
              BuildStoreLocal(parameter, new UseVal(load));
          AddInstruction(new DoInstr(store_local));
          // Write NULL to the source location to detect buggy accesses and
          // allow GC of passed value if it gets overwritten by a new value in
          // the function.
          BindInstr* null_constant =
              new BindInstr(new ConstantVal(Object::ZoneHandle()));
          AddInstruction(null_constant);
          Computation* clear_local =
              BuildStoreLocal(*temp_local, new UseVal(null_constant));
          AddInstruction(new DoInstr(clear_local));
        }
      }
    }
  }

  if (FLAG_enable_type_checks &&
      (node == owner()->parsed_function().node_sequence())) {
    const int num_params =
        owner()->parsed_function().function().NumberOfParameters();
    for (int pos = 0; pos < num_params; pos++) {
      const LocalVariable& parameter = *scope->VariableAt(pos);
      ASSERT(parameter.owner() == scope);
      if (!CanSkipTypeCheck(NULL, parameter.type())) {
        BindInstr* load = new BindInstr(BuildLoadLocal(parameter));
        AddInstruction(load);
        BuildAssertAssignable(parameter.token_index(),
                              new UseVal(load),
                              parameter.type(),
                              parameter.name());
      }
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
    if (is_open()) {
      AddInstruction(node->label()->join_for_break());
    } else {
      exit_ = node->label()->join_for_break();
    }
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
  CatchEntryComp* catch_entry = new CatchEntryComp(node->exception_var(),
                                                   node->stacktrace_var());
  AddInstruction(new DoInstr(catch_entry));
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
    TargetEntryInstr* catch_entry = new TargetEntryInstr(try_index);
    for_catch_block.AddInstruction(catch_entry);
    catch_block->Visit(&for_catch_block);
    owner()->AddCatchEntry(catch_entry);
    ASSERT(!for_catch_block.is_open());
    if ((node->end_catch_label() != NULL) &&
        (node->end_catch_label()->join_for_continue() != NULL)) {
      if (is_open()) {
        AddInstruction(node->end_catch_label()->join_for_continue());
      } else {
        exit_ = node->end_catch_label()->join_for_continue();
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
  Instruction* instr = NULL;
  if (node->stacktrace() == NULL) {
    instr = new ThrowInstr(node->token_index(),
                           owner()->try_index(),
                           for_exception.value());
  } else {
    ValueGraphVisitor for_stack_trace(owner(), temp_index());
    node->stacktrace()->Visit(&for_stack_trace);
    Append(for_stack_trace);
    instr = new ReThrowInstr(node->token_index(),
                             owner()->try_index(),
                             for_exception.value(),
                             for_stack_trace.value());
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


void FlowGraphBuilder::BuildGraph(bool for_optimized) {
  if (FLAG_print_ast) {
    // Print the function ast before IL generation.
    AstPrinter::PrintFunctionNodes(parsed_function());
  }
  // Compilation can be nested, preserve the computation-id.
  Isolate* isolate = Isolate::Current();
  const intptr_t prev_cid = isolate->computation_id();
  isolate->set_computation_id(0);
  const Function& function = parsed_function().function();
  TargetEntryInstr* normal_entry = new TargetEntryInstr();
  graph_entry_ = new GraphEntryInstr(normal_entry);
  EffectGraphVisitor for_effect(this, 0);
  for_effect.AddInstruction(normal_entry);
  parsed_function().node_sequence()->Visit(&for_effect);
  // Check that the graph is properly terminated.
  ASSERT(!for_effect.is_open());
  GrowableArray<intptr_t> parent;
  GrowableArray<BitVector*> assigned_vars;
  intptr_t variable_count = parsed_function_.function().num_fixed_parameters() +
      parsed_function_.copied_parameter_count() +
      parsed_function_.stack_local_count();
  // Perform a depth-first traversal of the graph to build preorder and
  // postorder block orders.
  graph_entry_->DiscoverBlocks(NULL,  // Entry block predecessor.
                               &preorder_block_entries_,
                               &postorder_block_entries_,
                               &parent,
                               &assigned_vars,
                               variable_count);
  if (for_optimized) {
    GrowableArray<BitVector*> dominance_frontier;
    ComputeDominators(&preorder_block_entries_, &parent, &dominance_frontier);
  }
  isolate->set_computation_id(prev_cid);
  if (FLAG_print_flow_graph) {
    intptr_t length = postorder_block_entries_.length();
    GrowableArray<BlockEntryInstr*> reverse_postorder(length);
    for (intptr_t i = length - 1; i >= 0; --i) {
      reverse_postorder.Add(postorder_block_entries_[i]);
    }
    FlowGraphPrinter printer(function, reverse_postorder);
    printer.VisitBlocks();
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


void FlowGraphBuilder::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphBuilder Bailout: %s %s";
  const char* function_name = parsed_function_.function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


}  // namespace dart
