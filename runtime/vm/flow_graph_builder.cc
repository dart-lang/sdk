// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_builder.h"

#include "vm/ast_printer.h"
#include "vm/code_descriptors.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
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
    catch_entries_() {}


void FlowGraphBuilder::AddCatchEntry(intptr_t try_index, Instruction* entry) {
  catch_entries_.Add(entry);
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
}


void EffectGraphVisitor::AddInstruction(Instruction* instruction) {
  ASSERT(is_open());
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
  } else if (false_exit == NULL) {
    exit_ = true_exit;
  } else {
    exit_ = new JoinEntryInstr();
    true_exit->SetSuccessor(exit_);
    false_exit->SetSuccessor(exit_);
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


// Stores current context into the 'variable'
void EffectGraphVisitor::BuildStoreContext(const LocalVariable& variable) {
  BindInstr* context = new BindInstr(temp_index(), new CurrentContextComp());
  AddInstruction(context);
  StoreLocalComp* store_context =
      new StoreLocalComp(variable, new UseVal(context),
                         owner()->context_level());
  AddInstruction(new DoInstr(store_context));
}


// Loads context saved in 'context_variable' into the current context.
void EffectGraphVisitor::BuildLoadContext(const LocalVariable& variable) {
  BindInstr* load_saved_context =
      new BindInstr(temp_index(),
                    new LoadLocalComp(variable, owner()->context_level()));
  AddInstruction(load_saved_context);
  DoInstr* store_context =
      new DoInstr(new StoreContextComp(new UseVal(load_saved_context)));
  AddInstruction(store_context);
}



void TestGraphVisitor::ReturnValue(Value* value) {
  if (FLAG_enable_type_checks) {
    BindInstr* assert_boolean =
        new BindInstr(temp_index(),
                      new AssertBooleanComp(condition_node_id(),
                                            condition_token_index(),
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


void ArgumentGraphVisitor::ReturnValue(Value* value) {
  value_ = value;
  if (value->IsConstant()) {
    BindInstr* defn = new BindInstr(temp_index(), value);
    AddInstruction(defn);
    value_ = new UseVal(defn);
    AllocateTempIndex();
  }
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
    EffectGraphVisitor for_effect(owner(), for_value.temp_index());
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
      return_value = BuildAssignableValue(node->id(),
                                          node->value()->token_index(),
                                          return_value,
                                          dst_type,
                                          dst_name,
                                          temp_index());
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
      new ReturnInstr(node->id(), node->token_index(), return_value));
  CloseFragment();
}


// <Expression> ::= Literal { literal: Instance }
void EffectGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  return;
}

void ValueGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  ReturnValue(new ConstantVal(node->literal()));
}

void TestGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  ReturnValue(new ConstantVal(node->literal()));
}


// Type nodes only occur as the right-hand side of instanceof comparisons,
// and they are handled specially in that context.
void EffectGraphVisitor::VisitTypeNode(TypeNode* node) { UNREACHABLE(); }


// Returns true if the type check can be skipped, for example, if the type is
// Dynamic or if the value is a compile time constant and an instance of type.
static bool CanSkipTypeCheck(Value* value, const AbstractType& dst_type) {
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
  if ((value != NULL) && value->IsConstant()) {
    Instance& literal_value = Instance::Handle();
    literal_value ^= value->AsConstant()->value().raw();
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
  ReturnValue(BuildAssignableValue(node->id(),
                                   node->token_index(),
                                   for_value.value(),
                                   node->type(),
                                   node->dst_name(),
                                   temp_index()));
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
                              node->left()->id(),
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
  ArgumentGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  ArgumentGraphVisitor for_right_value(owner(), for_left_value.temp_index());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(for_left_value.value());
  arguments->Add(for_right_value.value());
  const String& name = String::ZoneHandle(String::NewSymbol(node->Name()));
  InstanceCallComp* call = new InstanceCallComp(node->id(),
                                                node->token_index(),
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
                              node->left()->id(),
                              node->left()->token_index());
    node->left()->Visit(&for_test);

    ValueGraphVisitor for_right(owner(), temp_index());
    node->right()->Visit(&for_right);
    Value* right_value = for_right.value();
    if (FLAG_enable_type_checks) {
      AssertBooleanComp* assert_boolean =
          new AssertBooleanComp(node->right()->id(),
                                node->right()->token_index(),
                                owner()->try_index(),
                                right_value);
      for_right.AddInstruction(new BindInstr(temp_index(), assert_boolean));
      right_value = new TempVal(temp_index());
    }
    StrictCompareComp* comp = new StrictCompareComp(Token::kEQ_STRICT,
        right_value, new ConstantVal(bool_true));
    for_right.AddInstruction(new BindInstr(temp_index(), comp));

    if (node->kind() == Token::kAND) {
      ValueGraphVisitor for_false(owner(), temp_index());
      for_false.AddInstruction(
          new BindInstr(temp_index(), new ConstantVal(bool_false)));
      Join(for_test, for_right, for_false);
    } else {
      ASSERT(node->kind() == Token::kOR);
      ValueGraphVisitor for_true(owner(), temp_index());
      for_true.AddInstruction(
          new BindInstr(temp_index(), new ConstantVal(bool_true)));
      Join(for_test, for_true, for_right);
    }
    ReturnValue(new TempVal(AllocateTempIndex()));
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
  ReturnValue(new ConstantVal(concatenated));
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
  TranslateArgumentList(*interpol_arg, temp_index(), values);
  StaticCallComp* call =
      new StaticCallComp(node->token_index(),
                         owner()->try_index(),
                         interpol_func,
                         interpol_arg->names(),
                         values);
  ReturnComputation(call);
}


void EffectGraphVisitor::BuildAssertAssignable(intptr_t node_id,
                                               intptr_t token_index,
                                               Value* value,
                                               const AbstractType& dst_type,
                                               const String& dst_name,
                                               intptr_t start_index) {
  // We should not call this function if the type check can be skipped.
  ASSERT(!CanSkipTypeCheck(value, dst_type));

  // Build the type check computation.
  Value* instantiator_type_arguments = NULL;
  if (!dst_type.IsInstantiated()) {
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_index, start_index + 1);
  }
  AssertAssignableComp* assert_assignable =
      new AssertAssignableComp(node_id,
                               token_index,
                               owner()->try_index(),
                               value,
                               instantiator_type_arguments,
                               dst_type,
                               dst_name);
  AddInstruction(new DoInstr(assert_assignable));
}


Value* EffectGraphVisitor::BuildAssignableValue(intptr_t node_id,
                                                intptr_t token_index,
                                                Value* value,
                                                const AbstractType& dst_type,
                                                const String& dst_name,
                                                intptr_t start_index) {
  if (CanSkipTypeCheck(value, dst_type)) {
    return value;
  }

  // Build the type check computation.
  Value* instantiator_type_arguments = NULL;
  if (!dst_type.IsInstantiated()) {
    instantiator_type_arguments =
        BuildInstantiatorTypeArguments(token_index, start_index + 1);
  }
  BindInstr* assert_assignable =
      new BindInstr(start_index,
                    new AssertAssignableComp(node_id,
                                             token_index,
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
    ReturnValue(new ConstantVal(negate_result ? bool_false : bool_true));
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
    ReturnValue(result);
    return;
  }

  ArgumentGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  Value* type_arguments = NULL;
  if (!type.IsInstantiated()) {
    type_arguments = BuildInstantiatorTypeArguments(
        node->token_index(), for_left_value.temp_index());
  }
  InstanceOfComp* instance_of =
      new InstanceOfComp(node->id(),
                         node->token_index(),
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
    ValueGraphVisitor for_right_value(owner(), for_left_value.temp_index());
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
    ValueGraphVisitor for_right_value(owner(), for_left_value.temp_index());
    node->right()->Visit(&for_right_value);
    Append(for_right_value);
    EqualityCompareComp* comp = new EqualityCompareComp(
        node->id(), node->token_index(), owner()->try_index(),
        for_left_value.value(), for_right_value.value());
    if (node->kind() == Token::kEQ) {
      ReturnComputation(comp);
    } else {
      Definition* eq_result = new BindInstr(temp_index(), comp);
      AddInstruction(eq_result);
      if (FLAG_enable_type_checks) {
        eq_result =
            new BindInstr(temp_index(),
                          new AssertBooleanComp(node->id(),
                                                node->token_index(),
                                                owner()->try_index(),
                                                new UseVal(eq_result)));
        AddInstruction(eq_result);
      }
      BooleanNegateComp* negate = new BooleanNegateComp(new UseVal(eq_result));
      ReturnComputation(negate);
    }
    return;
  }

  ArgumentGraphVisitor for_left_value(owner(), temp_index());
  node->left()->Visit(&for_left_value);
  Append(for_left_value);
  ArgumentGraphVisitor for_right_value(owner(), for_left_value.temp_index());
  node->right()->Visit(&for_right_value);
  Append(for_right_value);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(for_left_value.value());
  arguments->Add(for_right_value.value());
  const String& name = String::ZoneHandle(String::NewSymbol(node->Name()));
  InstanceCallComp* call = new InstanceCallComp(
      node->id(), node->token_index(), owner()->try_index(), name,
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
          new BindInstr(temp_index(),
                        new AssertBooleanComp(node->operand()->id(),
                                              node->operand()->token_index(),
                                              owner()->try_index(),
                                              value));
      AddInstruction(assert_boolean);
      value = new UseVal(assert_boolean);
    }
    BooleanNegateComp* negate = new BooleanNegateComp(value);
    ReturnComputation(negate);
    return;
  }
  ArgumentGraphVisitor for_value(owner(), temp_index());
  node->operand()->Visit(&for_value);
  Append(for_value);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(1);
  arguments->Add(for_value.value());
  const String& name =
      String::ZoneHandle(String::NewSymbol((node->kind() == Token::kSUB)
                                               ? Token::Str(Token::kNEGATE)
                                               : node->Name()));
  InstanceCallComp* call = new InstanceCallComp(
      node->id(), node->token_index(), owner()->try_index(), name,
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitIncrOpLocalNode(IncrOpLocalNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  // In an effect context, treat postincrement as if it were preincrement
  // because its value is not needed.

  // 1. Load the value.
  BindInstr* load =
      new BindInstr(temp_index(),
                    new LoadLocalComp(node->local(), owner()->context_level()));
  AddInstruction(load);
  AllocateTempIndex();
  // 2. Increment.
  Definition* incr =
      BuildIncrOpIncrement(node->kind(), node->id(), node->token_index(),
                           new UseVal(load));
  // 3. Perform the store, resulting in the new value.
  DeallocateTempIndex();  // Consuming incr.
  StoreLocalComp* store = new StoreLocalComp(
      node->local(), new UseVal(incr), owner()->context_level());
  ReturnComputation(store);
}


void ValueGraphVisitor::VisitIncrOpLocalNode(IncrOpLocalNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  if (node->prefix()) {
    // Base class handles preincrement.
    EffectGraphVisitor::VisitIncrOpLocalNode(node);
    return;
  }
  // For postincrement, duplicate the original value to use one copy as the
  // result.
  //
  // 1. Load the value.
  BindInstr* load =
      new BindInstr(temp_index(),
                    new LoadLocalComp(node->local(), owner()->context_level()));
  AddInstruction(load);
  AllocateTempIndex();
  // 2. Duplicate it to increment.
  PickTempInstr* duplicate =
      new PickTempInstr(temp_index(), load->temp_index());
  AddInstruction(duplicate);
  AllocateTempIndex();
  // 3. Increment.
  Definition* incr =
      BuildIncrOpIncrement(node->kind(), node->id(), node->token_index(),
                           new UseVal(duplicate));
  // 4. Perform the store and return the original value.
  DeallocateTempIndex();  // Consuming incr.
  StoreLocalComp* store = new StoreLocalComp(
      node->local(), new UseVal(incr), owner()->context_level());
  AddInstruction(new DoInstr(store));
  ReturnValue(new UseVal(load));
}


Definition* EffectGraphVisitor::BuildIncrOpFieldLoad(
    IncrOpInstanceFieldNode* node,
    Value** receiver) {
  // Evaluate the receiver and duplicate it (it has two uses).
  //   t_n   <- ... receiver ...
  //   t_n+1 <- Pick(t_n)
  ArgumentGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  AllocateTempIndex();
  ASSERT(temp_index() == for_receiver.temp_index());
  PickTempInstr* duplicate =
      new PickTempInstr(temp_index(), temp_index() - 1);
  AddInstruction(duplicate);

  // Load the value.
  //   t_n+1 <- InstanceCall(get:name, t_n+1)
  const String& getter_name =
      String::ZoneHandle(Field::GetterSymbol(node->field_name()));
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(1);
  arguments->Add(new UseVal(duplicate));
  BindInstr* load =
      new BindInstr(temp_index(),
                    new InstanceCallComp(
                        node->getter_id(), node->token_index(),
                        owner()->try_index(), getter_name, arguments,
                        Array::ZoneHandle(), 1));
  AddInstruction(load);
  AllocateTempIndex();

  *receiver = for_receiver.value();
  return load;
}


Definition* EffectGraphVisitor::BuildIncrOpIncrement(Token::Kind kind,
                                                     intptr_t node_id,
                                                     intptr_t token_index,
                                                     Value* original) {
  ASSERT((kind == Token::kINCR) || (kind == Token::kDECR));
  // Assumed that t_n-1 (where n is start_index) is the field value.
  //   t_n   <- #1
  //   t_n-1 <- InstanceCall(op, t_n-1, t_n)
  BindInstr* one =
      new BindInstr(temp_index(),
                    new ConstantVal(Smi::ZoneHandle(Smi::New(1))));
  AddInstruction(one);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(original);
  arguments->Add(new UseVal(one));
  const String& op_name =
      String::ZoneHandle(String::NewSymbol((kind == Token::kINCR) ? "+" : "-"));
  DeallocateTempIndex();  // Consuming original.
  BindInstr* add =
      new BindInstr(temp_index(),
                    new InstanceCallComp(
                        node_id, token_index, owner()->try_index(), op_name,
                        arguments, Array::ZoneHandle(), 2));
  AddInstruction(add);
  AllocateTempIndex();
  return add;
}


void EffectGraphVisitor::VisitIncrOpInstanceFieldNode(
    IncrOpInstanceFieldNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  // In an effect context, treat postincrement as if it were preincrement
  // because its value is not needed.

  // 1. Load the value.
  Value* receiver = NULL;
  Definition* load = BuildIncrOpFieldLoad(node, &receiver);
  // 2. Increment.
  Definition* incr =
      BuildIncrOpIncrement(node->kind(), node->operator_id(),
                           node->token_index(), new UseVal(load));
  // 3. Perform the store, returning the stored value.
  InstanceSetterComp* store =
      new InstanceSetterComp(node->setter_id(),
                             node->token_index(),
                             owner()->try_index(),
                             node->field_name(),
                             receiver,
                             new UseVal(incr));
  DeallocateTempIndex();  // Consuming incr.
  DeallocateTempIndex();  // Consuming receiver.
  ReturnComputation(store);
}


void ValueGraphVisitor::VisitIncrOpInstanceFieldNode(
    IncrOpInstanceFieldNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  if (node->prefix()) {
    // Base class handles preincrement.
    EffectGraphVisitor::VisitIncrOpInstanceFieldNode(node);
    return;
  }
  // For postincrement, preallocate a temporary to preserve the original
  // value.
  //
  // 1. Name a placeholder.
  BindInstr* placeholder =
      new BindInstr(temp_index(),
                    new ConstantVal(Smi::ZoneHandle(Smi::New(0))));
  AddInstruction(placeholder);
  AllocateTempIndex();
  // 2. Load the value.
  Value* receiver = NULL;
  Definition* load = BuildIncrOpFieldLoad(node, &receiver);
  // 3. Preserve the original value.
  AddInstruction(new TuckTempInstr(placeholder->temp_index(),
                                   load->temp_index()));
  // 4. Increment.
  Definition* incr =
      BuildIncrOpIncrement(node->kind(), node->operator_id(),
                           node->token_index(), new UseVal(load));
  // 5. Perform the store and return the original value.
  const String& setter_name =
      String::ZoneHandle(Field::SetterSymbol(node->field_name()));
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(receiver);
  arguments->Add(new UseVal(incr));
  InstanceCallComp* store = new InstanceCallComp(
      node->setter_id(), node->token_index(), owner()->try_index(),
      setter_name, arguments, Array::ZoneHandle(), 1);
  DeallocateTempIndex();  // Consuming incr.
  DeallocateTempIndex();  // Consuming receiver.
  AddInstruction(new DoInstr(store));
  ReturnValue(new UseVal(placeholder));
}


Definition* EffectGraphVisitor::BuildIncrOpIndexedLoad(
    IncrOpIndexedNode* node,
    Value** receiver,
    Value** index) {
  // Evaluate the receiver and index.
  //   t_n   <- ... receiver ...
  //   t_n+1 <- ... index ...
  ArgumentGraphVisitor for_receiver(owner(), temp_index());
  node->array()->Visit(&for_receiver);
  Append(for_receiver);
  AllocateTempIndex();
  ASSERT(temp_index() == for_receiver.temp_index());

  ArgumentGraphVisitor for_index(owner(), temp_index());
  node->index()->Visit(&for_index);
  Append(for_index);
  AllocateTempIndex();
  ASSERT(temp_index() == for_index.temp_index());

  // Duplicate the receiver and index values, load the value.
  //   t_n+2 <- Pick(t_n)
  //   t_n+3 <- Pick(t_n+1)
  //   t_n+2 <- InstanceCall([], t_n+2, t_n+3)
  PickTempInstr* duplicate_receiver =
      new PickTempInstr(temp_index(), temp_index() - 2);
  AddInstruction(duplicate_receiver);
  PickTempInstr* duplicate_index =
      new PickTempInstr(temp_index() + 1, temp_index() - 1);
  AddInstruction(duplicate_index);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(new UseVal(duplicate_receiver));
  arguments->Add(new UseVal(duplicate_index));
  const String& load_name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kINDEX)));
  BindInstr* load =
      new BindInstr(temp_index(),
                    new InstanceCallComp(
                        node->load_id(), node->token_index(),
                        owner()->try_index(), load_name, arguments,
                        Array::ZoneHandle(), 1));
  AddInstruction(load);
  AllocateTempIndex();

  *receiver = for_receiver.value();
  *index = for_index.value();
  return load;
}


void EffectGraphVisitor::VisitIncrOpIndexedNode(IncrOpIndexedNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  // In an effect context, treat postincrement as if it were preincrement
  // because its value is not needed.

  // 1. Load the value.
  Value* receiver = NULL;
  Value* index = NULL;
  Definition* load = BuildIncrOpIndexedLoad(node, &receiver, &index);
  // 2. Increment.
  Definition* incr =
      BuildIncrOpIncrement(node->kind(), node->operator_id(),
                           node->token_index(), new UseVal(load));
  // 3. Perform the store, returning the stored value.
  StoreIndexedComp* store = new StoreIndexedComp(node->store_id(),
                                                 node->token_index(),
                                                 owner()->try_index(),
                                                 receiver,
                                                 index,
                                                 new UseVal(incr));
  DeallocateTempIndex();  // Consuming incr.
  DeallocateTempIndex();  // Consuming index.
  DeallocateTempIndex();  // Consuming receiver.
  ReturnComputation(store);
}


void ValueGraphVisitor::VisitIncrOpIndexedNode(IncrOpIndexedNode* node) {
  ASSERT((node->kind() == Token::kINCR) || (node->kind() == Token::kDECR));
  if (node->prefix()) {
    // Base class handles preincrement.
    EffectGraphVisitor::VisitIncrOpIndexedNode(node);
    return;
  }
  // For postincrement, preallocate a temporary to preserve the original
  // value.
  //
  // 1. Name a placeholder.
  BindInstr* placeholder =
      new BindInstr(temp_index(),
                    new ConstantVal(Smi::ZoneHandle(Smi::New(0))));
  AddInstruction(placeholder);
  AllocateTempIndex();
  // 2. Load the value.
  Value* receiver = NULL;
  Value* index = NULL;
  Definition* load = BuildIncrOpIndexedLoad(node, &receiver, &index);
  // 3. Preserve the original value.
  AddInstruction(new TuckTempInstr(placeholder->temp_index(),
                                   load->temp_index()));
  // 4. Increment.
  Definition* incr =
      BuildIncrOpIncrement(node->kind(), node->operator_id(),
                           node->token_index(), new UseVal(load));
  // 5. Perform the store and return the original value.
  const String& store_name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kASSIGN_INDEX)));
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(3);
  arguments->Add(receiver);
  arguments->Add(index);
  arguments->Add(new UseVal(incr));
  InstanceCallComp* store = new InstanceCallComp(
      node->store_id(), node->token_index(), owner()->try_index(),
      store_name, arguments, Array::ZoneHandle(), 1);
  DeallocateTempIndex();  // Consuming incr.
  DeallocateTempIndex();  // Consuming index.
  DeallocateTempIndex();  // Consuming receiver.
  AddInstruction(new DoInstr(store));
  ReturnValue(new UseVal(placeholder));
}


void EffectGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->id(),
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
                            node->condition()->id(),
                            node->condition()->token_index());
  node->condition()->Visit(&for_test);

  // Ensure that the value of the true/false subexpressions are named with
  // the same temporary name.
  ValueGraphVisitor for_true(owner(), temp_index());
  node->true_expr()->Visit(&for_true);
  ASSERT(for_true.is_open());
  if (for_true.value()->IsTemp()) {
    ASSERT(for_true.value()->AsTemp()->index() == temp_index());
  } else {
    for_true.AddInstruction(new BindInstr(temp_index(), for_true.value()));
  }

  ValueGraphVisitor for_false(owner(), temp_index());
  node->false_expr()->Visit(&for_false);
  ASSERT(for_false.is_open());
  if (for_false.value()->IsTemp()) {
    ASSERT(for_false.value()->AsTemp()->index() == temp_index());
  } else {
    for_false.AddInstruction(new BindInstr(temp_index(), for_false.value()));
  }

  Join(for_test, for_true, for_false);
  ReturnValue(new TempVal(AllocateTempIndex()));
}


// <Statement> ::= If { condition: <Expression>
//                      true_branch: <Sequence>
//                      false_branch: <Sequence> }
void EffectGraphVisitor::VisitIfNode(IfNode* node) {
  TestGraphVisitor for_test(owner(),
                            temp_index(),
                            node->condition()->id(),
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
                                         case_expr->id(),
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
                            node->condition()->id(),
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
                            node->condition()->id(),
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
                              node->condition()->id(),
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
  int index = temp_index();
  for (int i = 0; i < node->length(); ++i) {
    ValueGraphVisitor for_value(owner(), index);
    node->ElementAt(i)->Visit(&for_value);
    Append(for_value);
    values->Add(for_value.value());
    index = for_value.temp_index();
  }
  CreateArrayComp* create = new CreateArrayComp(node,
                                                owner()->try_index(),
                                                values);
  ReturnComputation(create);
}


void EffectGraphVisitor::VisitClosureNode(ClosureNode* node) {
  const Function& function = node->function();

  int next_index = temp_index();
  if (function.IsNonImplicitClosureFunction()) {
    const ContextScope& context_scope = ContextScope::ZoneHandle(
        node->scope()->PreserveOuterScope(owner()->context_level()));
    ASSERT(!function.HasCode());
    ASSERT(function.context_scope() == ContextScope::null());
    function.set_context_scope(context_scope);
  } else if (function.IsImplicitInstanceClosureFunction()) {
    ValueGraphVisitor for_receiver(owner(), temp_index());
    node->receiver()->Visit(&for_receiver);
    Append(for_receiver);
    if (!for_receiver.value()->IsTemp()) {
      AddInstruction(new BindInstr(temp_index(), for_receiver.value()));
    }
    ++next_index;
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
        BuildInstantiatorTypeArguments(node->token_index(), temp_index());
  }

  CreateClosureComp* create =
      new CreateClosureComp(node, owner()->try_index(), type_arguments);
  ReturnComputation(create);
}


void EffectGraphVisitor::TranslateArgumentList(
    const ArgumentListNode& node,
    intptr_t next_temp_index,
    ZoneGrowableArray<Value*>* values) {
  for (intptr_t i = 0; i < node.length(); ++i) {
    ArgumentGraphVisitor for_argument(owner(), next_temp_index);
    node.NodeAt(i)->Visit(&for_argument);
    Append(for_argument);
    next_temp_index = for_argument.temp_index();
    values->Add(for_argument.value());
  }
}

void EffectGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  ArgumentListNode* arguments = node->arguments();
  int length = arguments->length();
  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>(length + 1);

  ArgumentGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  values->Add(for_receiver.value());

  TranslateArgumentList(*arguments, for_receiver.temp_index(), values);
  InstanceCallComp* call = new InstanceCallComp(
      node->id(), node->token_index(), owner()->try_index(),
      node->function_name(), values,
                           arguments->names(), 1);
  ReturnComputation(call);
}


// <Expression> ::= StaticCall { function: Function
//                               arguments: <ArgumentList> }
void EffectGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  int length = node->arguments()->length();
  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>(length);
  TranslateArgumentList(*node->arguments(), temp_index(), values);
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
  BindInstr* context = new BindInstr(temp_index(), new CurrentContextComp());
  AddInstruction(context);

  ArgumentGraphVisitor for_closure(owner(), temp_index() + 1);
  node->closure()->Visit(&for_closure);
  Append(for_closure);

  ZoneGrowableArray<Value*>* arguments =
      new ZoneGrowableArray<Value*>(node->arguments()->length());
  arguments->Add(for_closure.value());
  TranslateArgumentList(*node->arguments(), temp_index() + 2, arguments);
  // First operand is the saved context, consumed by the call.
  ClosureCallComp* call =  new ClosureCallComp(node,
                                               owner()->try_index(),
                                               new UseVal(context),
                                               arguments);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  BindInstr* context = new BindInstr(temp_index(), new CurrentContextComp());
  AddInstruction(context);
  BindInstr* clone =
      new BindInstr(temp_index(),
                    new CloneContextComp(node->id(),
                                         node->token_index(),
                                         owner()->try_index(),
                                         new UseVal(context)));
  AddInstruction(clone);
  ReturnComputation(new StoreContextComp(new UseVal(clone)));
}


TempVal* EffectGraphVisitor::BuildObjectAllocation(ConstructorCallNode* node,
                                                   int start_index) {
  const Class& cls = Class::ZoneHandle(node->constructor().owner());
  const bool requires_type_arguments = cls.HasTypeArguments();

  ZoneGrowableArray<Value*>* allocate_arguments =
      new ZoneGrowableArray<Value*>();
  if (requires_type_arguments) {
    BuildConstructorTypeArguments(node, start_index, allocate_arguments);
  }
  AllocateObjectComp* alloc_comp =
      new AllocateObjectComp(node,
                             owner()->try_index(),
                             allocate_arguments);
  AddInstruction(new BindInstr(start_index, alloc_comp));
  return new TempVal(start_index);
}


void EffectGraphVisitor::BuildConstructorCall(ConstructorCallNode* node,
                                              int start_index,
                                              Value* alloc_value) {
  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>();
  values->Add(alloc_value);
  const Smi& ctor_arg = Smi::ZoneHandle(Smi::New(Function::kCtorPhaseAll));
  TempVal* ctor_arg_value = new TempVal(start_index);
  AddInstruction(
      new BindInstr(ctor_arg_value->index(), new ConstantVal(ctor_arg)));
  values->Add(ctor_arg_value);
  TranslateArgumentList(*node->arguments(), start_index + 1, values);
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
    factory_arguments->Add(BuildFactoryTypeArguments(node, temp_index()));
    ASSERT(factory_arguments->length() == 1);
    TranslateArgumentList(*node->arguments(),
                          temp_index() + 1,
                          factory_arguments);
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
  TempVal* alloc_value = BuildObjectAllocation(node, temp_index());
  BuildConstructorCall(node, alloc_value->index() + 1, alloc_value);
}


Value* EffectGraphVisitor::BuildInstantiatorTypeArguments(
    intptr_t token_index, intptr_t start_index) {
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
    BindInstr* args =
        new BindInstr(temp_index(), new ConstantVal(type_arguments));
    AddInstruction(args);
    return new UseVal(args);
  }
  ASSERT(owner()->parsed_function().instantiator() != NULL);
  ValueGraphVisitor for_instantiator(owner(), start_index);
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

  NativeLoadFieldComp* load = new NativeLoadFieldComp(
      for_instantiator.value(), type_arguments_instance_field_offset);
  AddInstruction(new BindInstr(start_index, load));
  return new TempVal(start_index);
}


Value* EffectGraphVisitor::BuildFactoryTypeArguments(
    ConstructorCallNode* node, intptr_t start_index) {
  ASSERT(node->constructor().IsFactory());
  if (node->type_arguments().IsNull() ||
      node->type_arguments().IsInstantiated()) {
    AddInstruction(
        new BindInstr(start_index, new ConstantVal(node->type_arguments())));
    return new TempVal(start_index);
  }
  // The type arguments are uninstantiated.
  Value* instantiator_value =
      BuildInstantiatorTypeArguments(node->token_index(), start_index);
  ExtractFactoryTypeArgumentsComp* extract =
      new ExtractFactoryTypeArgumentsComp(node,
                                          owner()->try_index(),
                                          instantiator_value);
  AddInstruction(new BindInstr(start_index, extract));
  return new TempVal(start_index);
}


void EffectGraphVisitor::BuildConstructorTypeArguments(
    ConstructorCallNode* node,
    intptr_t start_index,
    ZoneGrowableArray<Value*>* args) {
  const Class& cls = Class::ZoneHandle(node->constructor().owner());
  ASSERT(cls.HasTypeArguments() && !node->constructor().IsFactory());
  if (node->type_arguments().IsNull() ||
      node->type_arguments().IsInstantiated()) {
    AddInstruction(
        new BindInstr(start_index, new ConstantVal(node->type_arguments())));
    args->Add(new TempVal(start_index));
    // No instantiator required.
    const Smi& no_instantiator =
        Smi::ZoneHandle(Smi::New(StubCode::kNoInstantiator));
    AddInstruction(new BindInstr(
        start_index + 1, new ConstantVal(no_instantiator)));
    args->Add(new TempVal(start_index + 1));
    return;
  }
  // The type arguments are uninstantiated.
  // Place holder to hold uninstantiated constructor type arguments.
  AddInstruction(new BindInstr(start_index,
                               new ConstantVal(Object::ZoneHandle())));
  Value* instantiator_value =
      BuildInstantiatorTypeArguments(node->token_index(), start_index + 1);
  AddInstruction(new PickTempInstr(start_index + 2, start_index + 1));
  Value* dup_instantiator_value = new TempVal(start_index + 2);
  ExtractConstructorTypeArgumentsComp* extract_type_arguments =
      new ExtractConstructorTypeArgumentsComp(node, dup_instantiator_value);
  AddInstruction(new BindInstr(start_index + 2, extract_type_arguments));
  AddInstruction(new TuckTempInstr(start_index, start_index + 2));
  Value* constructor_type_arguments_value = new TempVal(start_index);
  args->Add(constructor_type_arguments_value);
  Value* discard_value = new TempVal(start_index + 2);
  ExtractConstructorInstantiatorComp* extract_instantiator =
      new ExtractConstructorInstantiatorComp(node,
                                             instantiator_value,
                                             discard_value);
  AddInstruction(new BindInstr(start_index + 1, extract_instantiator));
  Value* constructor_instantiator_value = new TempVal(start_index + 1);
  args->Add(constructor_instantiator_value);
}


void ValueGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  if (node->constructor().IsFactory()) {
    EffectGraphVisitor::VisitConstructorCallNode(node);
    return;
  }

  // t_n contains the allocated and initialized object.
  //   t_n      <- AllocateObject(class)
  //   t_n+1    <- Pick(t_n)
  //   t_n+2    <- ctor-arg
  //   t_n+3... <- constructor arguments start here
  //   StaticCall(constructor, t_n+1, t_n+2, ...)

  TempVal* alloc_value = BuildObjectAllocation(node, temp_index());
  intptr_t result_index = AllocateTempIndex();

  TempVal* dup_alloc_value = new TempVal(result_index + 1);
  AddInstruction(
      new PickTempInstr(dup_alloc_value->index(), alloc_value->index()));

  BuildConstructorCall(node, dup_alloc_value->index() + 1, dup_alloc_value);
  ReturnValue(alloc_value);
}


void EffectGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  ArgumentGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(1);
  arguments->Add(for_receiver.value());
  const String& name =
      String::ZoneHandle(Field::GetterSymbol(node->field_name()));
  InstanceCallComp* call = new InstanceCallComp(
      node->id(), node->token_index(), owner()->try_index(), name,
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  ArgumentGraphVisitor for_receiver(owner(), temp_index());
  node->receiver()->Visit(&for_receiver);
  Append(for_receiver);
  ArgumentGraphVisitor for_value(owner(), for_receiver.temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  InstanceSetterComp* setter =
      new InstanceSetterComp(node->id(),
                             node->token_index(),
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
  ArgumentGraphVisitor for_value(owner(), temp_index());
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
  return;
}


void ValueGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  LoadLocalComp* load = new LoadLocalComp(node->local(),
                                          owner()->context_level());
  ReturnComputation(load);
}


void TestGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  LoadLocalComp* load = new LoadLocalComp(node->local(),
                                          owner()->context_level());
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
    store_value = BuildAssignableValue(node->id(),
                                       node->value()->token_index(),
                                       store_value,
                                       node->local().type(),
                                       node->local().name(),
                                       temp_index());
  }
  StoreLocalComp* store =
      new StoreLocalComp(node->local(), store_value, owner()->context_level());
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
    store_value = BuildAssignableValue(node->id(),
                                       node->value()->token_index(),
                                       store_value,
                                       type,
                                       dst_name,
                                       for_instance.temp_index());
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
    store_value = BuildAssignableValue(node->id(),
                                       node->value()->token_index(),
                                       store_value,
                                       type,
                                       dst_name,
                                       temp_index());
  }
  StoreStaticFieldComp* store =
      new StoreStaticFieldComp(node->field(), store_value);
  ReturnComputation(store);
}


void EffectGraphVisitor::VisitLoadIndexedNode(LoadIndexedNode* node) {
  ArgumentGraphVisitor for_array(owner(), temp_index());
  node->array()->Visit(&for_array);
  Append(for_array);
  ArgumentGraphVisitor for_index(owner(), for_array.temp_index());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(for_array.value());
  arguments->Add(for_index.value());
  const String& name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kINDEX)));
  InstanceCallComp* call = new InstanceCallComp(
      node->id(), node->token_index(), owner()->try_index(), name,
      arguments, Array::ZoneHandle(), 1);
  ReturnComputation(call);
}


void EffectGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  ArgumentGraphVisitor for_array(owner(), temp_index());
  node->array()->Visit(&for_array);
  Append(for_array);
  ArgumentGraphVisitor for_index(owner(), for_array.temp_index());
  node->index_expr()->Visit(&for_index);
  Append(for_index);
  ArgumentGraphVisitor for_value(owner(), for_index.temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  StoreIndexedComp* store = new StoreIndexedComp(node->id(),
                                                 node->token_index(),
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
  BindInstr* context = new BindInstr(temp_index(), new CurrentContextComp());
  AddInstruction(context);
  BindInstr* parent =
      new BindInstr(temp_index(),
                    new NativeLoadFieldComp(
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
        new BindInstr(temp_index(),
                      new AllocateContextComp(node->token_index(),
                                              owner()->try_index(),
                                              num_context_variables));
    AddInstruction(allocated_context);

    // If this node_sequence is the body of the function being compiled, and if
    // this function is not a closure, do not link the current context as the
    // parent of the newly allocated context, as it is not accessible. Instead,
    // save it in a pre-allocated variable and restore it on exit.
    if (MustSaveRestoreContext(node)) {
      BindInstr* current_context =
          new BindInstr(temp_index() + 1, new CurrentContextComp());
      AddInstruction(current_context);
      StoreLocalComp* store_local = new StoreLocalComp(
          *owner()->parsed_function().saved_context_var(),
          new UseVal(current_context),
          0);
      AddInstruction(new DoInstr(store_local));
      StoreContextComp* store_context =
          new StoreContextComp(new ConstantVal(Object::ZoneHandle()));
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
      int param_frame_index =
          (num_params == function.num_fixed_parameters()) ? 1 + num_params : -1;
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
          BindInstr* load =
              new BindInstr(temp_index(),
                            new LoadLocalComp(*temp_local,
                                              owner()->context_level()));
          AddInstruction(load);
          StoreLocalComp* store_local = new StoreLocalComp(
              parameter,
              new UseVal(load),
              owner()->context_level());
          AddInstruction(new DoInstr(store_local));
          // Write NULL to the source location to detect buggy accesses and
          // allow GC of passed value if it gets overwritten by a new value in
          // the function.
          StoreLocalComp* clear_local = new StoreLocalComp(
              *temp_local,
              new ConstantVal(Object::ZoneHandle()),
              owner()->context_level());
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
        BindInstr* load =
            new BindInstr(temp_index(),
                          new LoadLocalComp(parameter,
                                            owner()->context_level()));
        AddInstruction(load);
        BuildAssertAssignable(node->ParameterIdAt(pos),
                              parameter.token_index(),
                              new UseVal(load),
                              parameter.type(),
                              parameter.name(),
                              temp_index());
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
    for_catch_block.AddInstruction(new TargetEntryInstr(try_index));
    catch_block->Visit(&for_catch_block);
    owner()->AddCatchEntry(try_index, for_catch_block.entry());
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
    instr = new ThrowInstr(node->id(),
                           node->token_index(),
                           owner()->try_index(),
                           for_exception.value());
  } else {
    ValueGraphVisitor for_stack_trace(owner(), temp_index() + 1);
    node->stacktrace()->Visit(&for_stack_trace);
    Append(for_stack_trace);
    instr = new ReThrowInstr(node->id(),
                             node->token_index(),
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
  ReturnValue(new ConstantVal(Instance::ZoneHandle()));
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


// Graph printing.
class FlowGraphPrinter : public FlowGraphVisitor {
 public:
  FlowGraphPrinter(const Function& function,
                   const GrowableArray<BlockEntryInstr*>& block_order)
      : FlowGraphVisitor(block_order), function_(function) { }

  virtual ~FlowGraphPrinter() {}

  // Print the instructions in a block terminated by newlines.  Add "goto N"
  // to the end of the block if it ends with an unconditional jump to
  // another block and that block is not next in reverse postorder.
  void VisitBlocks();

  // Visiting a computation prints it with no indentation or newline.
#define DECLARE_VISIT_COMPUTATION(ShortName, ClassName)                        \
  virtual void Visit##ShortName(ClassName* comp);

  // Visiting an instruction prints it with a four space indent and no
  // trailing newline.  Basic block entries are labeled with their block
  // number.
#define DECLARE_VISIT_INSTRUCTION(ShortName)                                   \
  virtual void Visit##ShortName(ShortName##Instr* instr);

  FOR_EACH_COMPUTATION(DECLARE_VISIT_COMPUTATION)
  FOR_EACH_INSTRUCTION(DECLARE_VISIT_INSTRUCTION)

#undef DECLARE_VISIT_COMPUTATION
#undef DECLARE_VISIT_INSTRUCTION

 private:
  const Function& function_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphPrinter);
};


void FlowGraphPrinter::VisitBlocks() {
  OS::Print("==== %s\n", function_.ToFullyQualifiedCString());

  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    // Print the block entry.
    Instruction* current = block_order_[i]->Accept(this);
    // And all the successors until an exit, branch, or a block entry.
    while ((current != NULL) && !current->IsBlockEntry()) {
      OS::Print("\n");
      current = current->Accept(this);
    }
    BlockEntryInstr* successor =
        (current == NULL) ? NULL : current->AsBlockEntry();
    if (successor != NULL) {
      // For readability label blocks with their reverse postorder index,
      // not their postorder block number, so the first block is 0 (not
      // n-1).
      OS::Print(" goto %d", reverse_index(successor->postorder_number()));
    }
    OS::Print("\n");
  }
}


void FlowGraphPrinter::VisitTemp(TempVal* val) {
  OS::Print("t%d", val->index());
}


void FlowGraphPrinter::VisitUse(UseVal* val) {
  OS::Print("s%d", val->definition()->temp_index());
}


void FlowGraphPrinter::VisitConstant(ConstantVal* val) {
  OS::Print("#%s", val->value().ToCString());
}


void FlowGraphPrinter::VisitAssertAssignable(AssertAssignableComp* comp) {
  OS::Print("AssertAssignable(");
  comp->value()->Accept(this);
  OS::Print(", %s, '%s'",
            String::Handle(comp->dst_type().Name()).ToCString(),
            comp->dst_name().ToCString());
  if (comp->instantiator_type_arguments() != NULL) {
    OS::Print(" (instantiator:");
    comp->instantiator_type_arguments()->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitAssertBoolean(AssertBooleanComp* comp) {
  OS::Print("AssertBoolean(");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitCurrentContext(CurrentContextComp* comp) {
  OS::Print("CurrentContext");
}


void FlowGraphPrinter::VisitClosureCall(ClosureCallComp* comp) {
  OS::Print("ClosureCall(");
  comp->context()->Accept(this);
  for (intptr_t i = 0; i < comp->ArgumentCount(); ++i) {
    OS::Print(", ");
    comp->ArgumentAt(i)->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitInstanceCall(InstanceCallComp* comp) {
  OS::Print("InstanceCall(%s", comp->function_name().ToCString());
  for (intptr_t i = 0; i < comp->ArgumentCount(); ++i) {
    OS::Print(", ");
    comp->ArgumentAt(i)->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitStrictCompare(StrictCompareComp* comp) {
  OS::Print("StrictCompare(%s, ", Token::Str(comp->kind()));
  comp->left()->Accept(this);
  OS::Print(", ");
  comp->right()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitEqualityCompare(EqualityCompareComp* comp) {
  comp->left()->Accept(this);
  OS::Print(" == ");
  comp->right()->Accept(this);
}


void FlowGraphPrinter::VisitStaticCall(StaticCallComp* comp) {
  OS::Print("StaticCall(%s",
            String::Handle(comp->function().name()).ToCString());
  for (intptr_t i = 0; i < comp->ArgumentCount(); ++i) {
    OS::Print(", ");
    comp->ArgumentAt(i)->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitLoadLocal(LoadLocalComp* comp) {
  OS::Print("LoadLocal(%s lvl:%d)",
      comp->local().name().ToCString(), comp->context_level());
}


void FlowGraphPrinter::VisitStoreLocal(StoreLocalComp* comp) {
  OS::Print("StoreLocal(%s, ", comp->local().name().ToCString());
  comp->value()->Accept(this);
  OS::Print(", lvl: %d)", comp->context_level());
}


void FlowGraphPrinter::VisitNativeCall(NativeCallComp* comp) {
  OS::Print("NativeCall(%s)", comp->native_name().ToCString());
}


void FlowGraphPrinter::VisitLoadInstanceField(LoadInstanceFieldComp* comp) {
  OS::Print("LoadInstanceField(%s, ",
      String::Handle(comp->field().name()).ToCString());
  comp->instance()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitStoreInstanceField(StoreInstanceFieldComp* comp) {
  OS::Print("StoreInstanceField(%s, ",
            String::Handle(comp->field().name()).ToCString());
  comp->instance()->Accept(this);
  OS::Print(", ");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitLoadStaticField(LoadStaticFieldComp* comp) {
  OS::Print("LoadStaticField(%s)",
            String::Handle(comp->field().name()).ToCString());
}


void FlowGraphPrinter::VisitStoreStaticField(StoreStaticFieldComp* comp) {
  OS::Print("StoreStaticField(%s, ",
            String::Handle(comp->field().name()).ToCString());
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitStoreIndexed(StoreIndexedComp* comp) {
  OS::Print("StoreIndexed(");
  comp->array()->Accept(this);
  OS::Print(", ");
  comp->index()->Accept(this);
  OS::Print(", ");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitInstanceSetter(InstanceSetterComp* comp) {
  OS::Print("InstanceSetter(");
  comp->receiver()->Accept(this);
  OS::Print(", ");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitStaticSetter(StaticSetterComp* comp) {
  OS::Print("StaticSetter(");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitBooleanNegate(BooleanNegateComp* comp) {
  OS::Print("! ");
  comp->value()->Accept(this);
}


void FlowGraphPrinter::VisitInstanceOf(InstanceOfComp* comp) {
  comp->value()->Accept(this);
  OS::Print(" %s %s",
            comp->negate_result() ? "ISNOT" : "IS",
            String::Handle(comp->type().Name()).ToCString());
  if (comp->type_arguments() != NULL) {
    OS::Print(" (type-arg:");
    comp->type_arguments()->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitAllocateObject(AllocateObjectComp* comp) {
  OS::Print("AllocateObject(%s",
            Class::Handle(comp->constructor().owner()).ToCString());
  for (intptr_t i = 0; i < comp->arguments().length(); i++) {
    OS::Print(", ");
    comp->arguments()[i]->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitCreateArray(CreateArrayComp* comp) {
  OS::Print("CreateArray(");
  for (int i = 0; i < comp->ElementCount(); ++i) {
    if (i != 0) OS::Print(", ");
    comp->ElementAt(i)->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitCreateClosure(CreateClosureComp* comp) {
  OS::Print("CreateClosure(%s", comp->function().ToCString());
  if (comp->type_arguments() != NULL) {
    OS::Print(", ");
    comp->type_arguments()->Accept(this);
  }
  OS::Print(")");
}


void FlowGraphPrinter::VisitNativeLoadField(NativeLoadFieldComp* comp) {
  OS::Print("NativeLoadField(");
  comp->value()->Accept(this);
  OS::Print(", %d)", comp->offset_in_bytes());
}


void FlowGraphPrinter::VisitExtractFactoryTypeArguments(
    ExtractFactoryTypeArgumentsComp* comp) {
  OS::Print("ExtractFactoryTypeArguments(");
  comp->instantiator()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitExtractConstructorTypeArguments(
    ExtractConstructorTypeArgumentsComp* comp) {
  OS::Print("ExtractConstructorTypeArguments(");
  comp->instantiator()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitExtractConstructorInstantiator(
    ExtractConstructorInstantiatorComp* comp) {
  OS::Print("ExtractConstructorInstantiator(");
  comp->instantiator()->Accept(this);
  OS::Print(", ");
  comp->discard_value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitAllocateContext(AllocateContextComp* comp) {
  OS::Print("AllocateContext(%d)", comp->num_context_variables());
}


void FlowGraphPrinter::VisitChainContext(ChainContextComp* comp) {
  OS::Print("ChainContext(");
  comp->context_value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitCloneContext(CloneContextComp* comp) {
  OS::Print("CloneContext(");
  comp->context_value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitCatchEntry(CatchEntryComp* comp) {
  OS::Print("CatchEntry(%s, %s)",
            comp->exception_var().name().ToCString(),
            comp->stacktrace_var().name().ToCString());
}


void FlowGraphPrinter::VisitStoreContext(StoreContextComp* comp) {
  OS::Print("StoreContext(");
  comp->value()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitJoinEntry(JoinEntryInstr* instr) {
  OS::Print("%2d: [join]", reverse_index(instr->postorder_number()));
}


void FlowGraphPrinter::VisitTargetEntry(TargetEntryInstr* instr) {
  OS::Print("%2d: [target", reverse_index(instr->postorder_number()));
  if (instr->HasTryIndex()) {
    OS::Print(" catch %d]", instr->try_index());
  } else {
    OS::Print("]");
  }
}


void FlowGraphPrinter::VisitDo(DoInstr* instr) {
  OS::Print("    ");
  instr->computation()->Accept(this);
}


void FlowGraphPrinter::VisitBind(BindInstr* instr) {
  OS::Print("    t%d <- ", instr->temp_index());
  instr->computation()->Accept(this);
}


void FlowGraphPrinter::VisitPickTemp(PickTempInstr* instr) {
  OS::Print("    t%d <- Pick(t%d)", instr->temp_index(), instr->source());
}


void FlowGraphPrinter::VisitTuckTemp(TuckTempInstr* instr) {
  OS::Print("    t%d := t%d", instr->destination(), instr->source());
}


void FlowGraphPrinter::VisitReturn(ReturnInstr* instr) {
  OS::Print("    return ");
  instr->value()->Accept(this);
}


void FlowGraphPrinter::VisitThrow(ThrowInstr* instr) {
  OS::Print("Throw(");
  instr->exception()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitReThrow(ReThrowInstr* instr) {
  OS::Print("ReThrow(");
  instr->exception()->Accept(this);
  OS::Print(", ");
  instr->stack_trace()->Accept(this);
  OS::Print(")");
}


void FlowGraphPrinter::VisitBranch(BranchInstr* instr) {
  OS::Print("    if ");
  instr->value()->Accept(this);
  OS::Print(" goto(%d, %d)",
            reverse_index(instr->true_successor()->postorder_number()),
            reverse_index(instr->false_successor()->postorder_number()));
}


void FlowGraphBuilder::BuildGraph() {
  if (FLAG_print_ast) {
    // Print the function ast before IL generation.
    AstPrinter::PrintFunctionNodes(parsed_function());
  }
  TimerScope timer(FLAG_compiler_stats, &CompilerStats::graphbuilder_timer);
  const Function& function = parsed_function().function();
  EffectGraphVisitor for_effect(this, 0);
  for_effect.AddInstruction(new TargetEntryInstr());
  parsed_function().node_sequence()->Visit(&for_effect);
  // Check that the graph is properly terminated.
  ASSERT(!for_effect.is_open());
  GrowableArray<intptr_t> parent;
  for (intptr_t i = 0; i < catch_entries_.length(); i++) {
    Instruction* entry = catch_entries_[i];
    entry->DiscoverBlocks(NULL,  // Entry block predecessor.
                          &preorder_block_entries_,
                          &postorder_block_entries_,
                          &parent);
    ComputeDominators(&preorder_block_entries_, &parent);
  }
  if (for_effect.entry() != NULL) {
    // Perform a depth-first traversal of the graph to build preorder and
    // postorder block orders.
    for_effect.entry()->DiscoverBlocks(NULL,  // Entry block predecessor.
                                       &preorder_block_entries_,
                                       &postorder_block_entries_,
                                       &parent);
    ComputeDominators(&preorder_block_entries_, &parent);
  }
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


void FlowGraphBuilder::ComputeDominators(
    GrowableArray<BlockEntryInstr*>* preorder,
    GrowableArray<intptr_t>* parent) {
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

  // Initialize idom, semi, and label.
  for (intptr_t i = 0; i < size; ++i) {
    idom.Add((*parent)[i]);
    semi.Add(i);
    label.Add(i);
  }

  // Loop over the blocks in reverse preorder (not including the graph
  // entry).
  for (intptr_t block_index = size - 1; block_index >= 1; --block_index) {
    // Loop over the predecessors.
    BlockEntryInstr* block = (*preorder)[block_index];
    for (intptr_t i = 0; i < block->PredecessorCount(); ++i) {
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
  // spanning tree parent and semidominator, for all nodes except the entry.
  for (intptr_t block_index = 1; block_index < size; ++block_index) {
    intptr_t dom_index = idom[block_index];
    while (dom_index > semi[block_index]) {
      dom_index = idom[dom_index];
    }
    idom[block_index] = dom_index;
    (*preorder)[block_index]->set_dominator((*preorder)[dom_index]);
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
