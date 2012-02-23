// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_builder.h"

#include "vm/flags.h"
#include "vm/intermediate_language.h"
#include "vm/longjump.h"
#include "vm/os.h"
#include "vm/parser.h"

namespace dart {

DEFINE_FLAG(bool, print_flow_graph, false, "Print the IR flow graph.");
DECLARE_FLAG(bool, enable_type_checks);

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

  // 2. Connect the true and false bodies to the test if they are reachable,
  // and if so record their exits (if any).
  if (test_fragment.can_be_true()) {
    Instruction* true_exit = NULL;
    Instruction* false_exit = NULL;
    TargetEntryInstr* true_entry = new TargetEntryInstr();
    *test_fragment.true_successor_address() = true_entry;
    true_entry->SetSuccessor(true_fragment.entry());
    true_exit = true_fragment.is_empty() ? true_entry : true_fragment.exit();

    TargetEntryInstr* false_entry = new TargetEntryInstr();
    *test_fragment.false_successor_address() = false_entry;
    false_entry->SetSuccessor(false_fragment.entry());
    false_exit =
        false_fragment.is_empty() ? false_entry : false_fragment.exit();

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
  if (test_fragment.can_be_true()) {
    TargetEntryInstr* body_entry = new TargetEntryInstr();
    *test_fragment.true_successor_address() = body_entry;
    body_entry->SetSuccessor(body_fragment.entry());
    body_exit = body_fragment.is_empty() ? body_entry : body_fragment.exit();
  }

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

  // 3. Set the exit to the graph to be empty or a fresh target node
  // depending on whether the false branch of the test is reachable.
  if (test_fragment.can_be_false()) {
    exit_ = *test_fragment.false_successor_address() = new TargetEntryInstr();
  } else {
    exit_ = NULL;
  }
}


void TestGraphVisitor::BranchOnValue(Value* value) {
  BranchInstr* branch = new BranchInstr(value);
  AddInstruction(branch);
  CloseFragment();
  true_successor_address_ = branch->true_successor_address();
  false_successor_address_ = branch->false_successor_address();
}


void EffectGraphVisitor::Bailout(const char* reason) {
  owner()->Bailout(reason);
}


// 'bailout' is a statement (without a semicolon), typically a return.
#define CHECK_ALIVE(bailout)                            \
  do {                                                  \
    if (!is_open()) {                                   \
      bailout;                                          \
    }                                                   \
  } while (false)


// <Statement> ::= Return { value:                <Expression>
//                          inlined_finally_list: <InlinedFinally>* }
void EffectGraphVisitor::VisitReturnNode(ReturnNode* node) {
  ValueGraphVisitor for_value(owner(), temp_index());
  node->value()->Visit(&for_value);
  Append(for_value);
  CHECK_ALIVE(return);

  for (intptr_t i = 0; i < node->inlined_finally_list_length(); i++) {
    EffectGraphVisitor for_effect(owner(), for_value.temp_index());
    node->InlinedFinallyNodeAt(i)->Visit(&for_effect);
    Append(for_effect);
    CHECK_ALIVE(return);
  }

  Value* return_value = for_value.value();
  if (FLAG_enable_type_checks) {
    const RawFunction::Kind kind = owner()->parsed_function().function().kind();
    // Implicit getters do not need a type check at return.
    if ((kind != RawFunction::kImplicitGetter) &&
        (kind != RawFunction::kConstImplicitGetter)) {
      const AbstractType& type =
          AbstractType::ZoneHandle(
              owner()->parsed_function().function().result_type());
      AssertAssignableComp* assert =
          new AssertAssignableComp(return_value, type);
      AddInstruction(new BindInstr(temp_index(), assert));
      return_value = new TempValue(temp_index());
    }
  }

  AddInstruction(new ReturnInstr(return_value));
  CloseFragment();
}

void ValueGraphVisitor::VisitReturnNode(ReturnNode* node) { UNREACHABLE(); }
void TestGraphVisitor::VisitReturnNode(ReturnNode* node) { UNREACHABLE(); }


// <Expression> ::= Literal { literal: Instance }
void EffectGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  return;
}

void ValueGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  ReturnValue(new ConstantValue(node->literal()));
}

void TestGraphVisitor::VisitLiteralNode(LiteralNode* node) {
  BranchOnValue(new ConstantValue(node->literal()));
}


// Type nodes only occur as the right-hand side of instanceof comparisons,
// and they are handled specially in that context.
void EffectGraphVisitor::VisitTypeNode(TypeNode* node) { UNREACHABLE(); }
void ValueGraphVisitor::VisitTypeNode(TypeNode* node) { UNREACHABLE(); }
void TestGraphVisitor::VisitTypeNode(TypeNode* node) { UNREACHABLE(); }


// <Expression> :: Assignable { expr:     <Expression>
//                              type:     AbstractType
//                              dst_name: String }
AssertAssignableComp* EffectGraphVisitor::TranslateAssignable(
    const AssignableNode& node) {
  ValueGraphVisitor for_value(owner(), temp_index());
  node.expr()->Visit(&for_value);
  Append(for_value);
  CHECK_ALIVE(return NULL);

  return new AssertAssignableComp(for_value.value(), node.type());
}

void EffectGraphVisitor::VisitAssignableNode(AssignableNode* node) {
  AssertAssignableComp* assert = TranslateAssignable(*node);
  CHECK_ALIVE(return);
  DoComputation(assert);
}

void ValueGraphVisitor::VisitAssignableNode(AssignableNode* node) {
  AssertAssignableComp* assert = TranslateAssignable(*node);
  CHECK_ALIVE(return);
  ReturnValueOf(assert);
}


void TestGraphVisitor::VisitAssignableNode(AssignableNode* node) {
  AssertAssignableComp* assert = TranslateAssignable(*node);
  CHECK_ALIVE(return);
  BranchOnValueOf(assert);
}


// <Expression> :: BinaryOp { kind:  Token::Kind
//                            left:  <Expression>
//                            right: <Expression> }
InstanceCallComp* EffectGraphVisitor::TranslateBinaryOp(
    const BinaryOpNode& node) {
  // Operators "&&" and "||" cannot be overloaded therefore do not call
  // operator.
  if ((node.kind() == Token::kAND) || (node.kind() == Token::kOR)) {
    Bailout("EffectGraphVisitor::VisitBinaryOpNode AND/OR");
  }
  ValueGraphVisitor for_left_value(owner(), temp_index());
  node.left()->Visit(&for_left_value);
  Append(for_left_value);
  CHECK_ALIVE(return NULL);
  ValueGraphVisitor for_right_value(owner(), for_left_value.temp_index());
  node.right()->Visit(&for_right_value);
  Append(for_right_value);
  CHECK_ALIVE(return NULL);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(for_left_value.value());
  arguments->Add(for_right_value.value());
  return new InstanceCallComp(node.Name(), arguments);
}

void EffectGraphVisitor::VisitBinaryOpNode(BinaryOpNode* node) {
  InstanceCallComp* call = TranslateBinaryOp(*node);
  CHECK_ALIVE(return);
  DoComputation(call);
}

void ValueGraphVisitor::VisitBinaryOpNode(BinaryOpNode* node) {
  InstanceCallComp* call = TranslateBinaryOp(*node);
  CHECK_ALIVE(return);
  ReturnValueOf(call);
}

void TestGraphVisitor::VisitBinaryOpNode(BinaryOpNode* node) {
  InstanceCallComp* call = TranslateBinaryOp(*node);
  CHECK_ALIVE(return);
  BranchOnValueOf(call);
}


void EffectGraphVisitor::VisitStringConcatNode(StringConcatNode* node) {
  Bailout("EffectGraphVisitor::VisitStringConcatNode");
}
void ValueGraphVisitor::VisitStringConcatNode(StringConcatNode* node) {
  Bailout("ValueGraphVisitor::VisitStringConcatNode");
}
void TestGraphVisitor::VisitStringConcatNode(StringConcatNode* node) {
  Bailout("TestGraphVisitor::VisitStringConcatNode");
}


// <Expression> :: Comparison { kind:  Token::Kind
//                              left:  <Expression>
//                              right: <Expression> }
InstanceCallComp* EffectGraphVisitor::TranslateComparison(
    const ComparisonNode& node) {
  if (Token::IsInstanceofOperator(node.kind()) ||
      Token::IsEqualityOperator(node.kind())) {
    Bailout("Some kind of comparison we don't handle yet");
    return NULL;
  }
  ValueGraphVisitor for_left_value(owner(), temp_index());
  node.left()->Visit(&for_left_value);
  Append(for_left_value);
  CHECK_ALIVE(return NULL);
  ValueGraphVisitor for_right_value(owner(), for_left_value.temp_index());
  node.right()->Visit(&for_right_value);
  Append(for_right_value);
  CHECK_ALIVE(return NULL);
  ZoneGrowableArray<Value*>* arguments = new ZoneGrowableArray<Value*>(2);
  arguments->Add(for_left_value.value());
  arguments->Add(for_right_value.value());
  return new InstanceCallComp(node.Name(), arguments);
}

void EffectGraphVisitor::VisitComparisonNode(ComparisonNode* node) {
  InstanceCallComp* call = TranslateComparison(*node);
  CHECK_ALIVE(return);
  DoComputation(call);
}

void ValueGraphVisitor::VisitComparisonNode(ComparisonNode* node) {
  InstanceCallComp* call = TranslateComparison(*node);
  CHECK_ALIVE(return);
  ReturnValueOf(call);
}

void TestGraphVisitor::VisitComparisonNode(ComparisonNode* node) {
  InstanceCallComp* call = TranslateComparison(*node);
  CHECK_ALIVE(return);
  BranchOnValueOf(call);
}



InstanceCallComp* EffectGraphVisitor::TranslateUnaryOp(
    const UnaryOpNode& node) {
  // "!" cannot be overloaded, therefore do not call operator.
  if (node.kind() == Token::kNOT) {
    Bailout("EffectGraphVisitor::VisitUnaryOpNode NOT");
  }
  ValueGraphVisitor for_value(owner(), temp_index());
  node.operand()->Visit(&for_value);
  Append(for_value);
  ZoneGrowableArray<Value*>* argument = new ZoneGrowableArray<Value*>(1);
  argument->Add(for_value.value());
  return new InstanceCallComp(node.Name(), argument);
}


void EffectGraphVisitor::VisitUnaryOpNode(UnaryOpNode* node) {
  InstanceCallComp* call = TranslateUnaryOp(*node);
  DoComputation(call);
}
void ValueGraphVisitor::VisitUnaryOpNode(UnaryOpNode* node) {
  InstanceCallComp* call = TranslateUnaryOp(*node);
  ReturnValueOf(call);
}
void TestGraphVisitor::VisitUnaryOpNode(UnaryOpNode* node) {
  InstanceCallComp* call = TranslateUnaryOp(*node);
  BranchOnValueOf(call);
}


void EffectGraphVisitor::VisitIncrOpLocalNode(IncrOpLocalNode* node) {
  Bailout("EffectGraphVisitor::VisitIncrOpLocalNode");
}
void ValueGraphVisitor::VisitIncrOpLocalNode(IncrOpLocalNode* node) {
  Bailout("ValueGraphVisitor::VisitIncrOpLocalNode");
}
void TestGraphVisitor::VisitIncrOpLocalNode(IncrOpLocalNode* node) {
  Bailout("TestGraphVisitor::VisitIncrOpLocalNode");
}


void EffectGraphVisitor::VisitIncrOpInstanceFieldNode(
    IncrOpInstanceFieldNode* node) {
  Bailout("EffectGraphVisitor::VisitIncrOpInstanceFieldNode");
}
void ValueGraphVisitor::VisitIncrOpInstanceFieldNode(
    IncrOpInstanceFieldNode* node) {
  Bailout("ValueGraphVisitor::VisitIncrOpInstanceFieldNode");
}
void TestGraphVisitor::VisitIncrOpInstanceFieldNode(
    IncrOpInstanceFieldNode* node) {
  Bailout("TestGraphVisitor::VisitIncrOpInstanceFieldNode");
}


void EffectGraphVisitor::VisitIncrOpStaticFieldNode(
    IncrOpStaticFieldNode* node) {
  Bailout("EffectGraphVisitor::VisitIncrOpStaticFieldNode");
}
void ValueGraphVisitor::VisitIncrOpStaticFieldNode(
    IncrOpStaticFieldNode* node) {
  Bailout("ValueGraphVisitor::VisitIncrOpStaticFieldNode");
}
void TestGraphVisitor::VisitIncrOpStaticFieldNode(IncrOpStaticFieldNode* node) {
  Bailout("TestGraphVisitor::VisitIncrOpStaticFieldNode");
}


void EffectGraphVisitor::VisitIncrOpIndexedNode(IncrOpIndexedNode* node) {
  Bailout("EffectGraphVisitor::VisitIncrOpIndexedNode");
}
void ValueGraphVisitor::VisitIncrOpIndexedNode(IncrOpIndexedNode* node) {
  Bailout("ValueGraphVisitor::VisitIncrOpIndexedNode");
}
void TestGraphVisitor::VisitIncrOpIndexedNode(IncrOpIndexedNode* node) {
  Bailout("TestGraphVisitor::VisitIncrOpIndexedNode");
}


void EffectGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  Bailout("EffectGraphVisitor::VisitConditionalExprNode");
}
void ValueGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  Bailout("ValueGraphVisitor::VisitConditionalExprNode");
}
void TestGraphVisitor::VisitConditionalExprNode(ConditionalExprNode* node) {
  Bailout("TestGraphVisitor::VisitConditionalExprNode");
}


// <Statement> ::= If { condition: <Expression>
//                      true_branch: <Sequence>
//                      false_branch: <Sequence> }
void EffectGraphVisitor::VisitIfNode(IfNode* node) {
  TestGraphVisitor for_test(owner(), temp_index());
  node->condition()->Visit(&for_test);
  Append(for_test);

  EffectGraphVisitor for_true(owner(), temp_index());
  EffectGraphVisitor for_false(owner(), temp_index());

  if (for_test.can_be_true()) {
    node->true_branch()->Visit(&for_true);
    // The for_false graph fragment will be empty (default graph fragment)
    // if we do not call Visit.
    if (node->false_branch() != NULL) node->false_branch()->Visit(&for_false);
  }
  Join(for_test, for_true, for_false);
}

void ValueGraphVisitor::VisitIfNode(IfNode* node) { UNREACHABLE(); }
void TestGraphVisitor::VisitIfNode(IfNode* node) { UNREACHABLE(); }


void EffectGraphVisitor::VisitSwitchNode(SwitchNode* node) {
  Bailout("EffectGraphVisitor::VisitSwitchNode");
}
void ValueGraphVisitor::VisitSwitchNode(SwitchNode* node) {
  Bailout("ValueGraphVisitor::VisitSwitchNode");
}
void TestGraphVisitor::VisitSwitchNode(SwitchNode* node) {
  Bailout("TestGraphVisitor::VisitSwitchNode");
}


void EffectGraphVisitor::VisitCaseNode(CaseNode* node) {
  Bailout("EffectGraphVisitor::VisitCaseNode");
}
void ValueGraphVisitor::VisitCaseNode(CaseNode* node) {
  Bailout("ValueGraphVisitor::VisitCaseNode");
}
void TestGraphVisitor::VisitCaseNode(CaseNode* node) {
  Bailout("TestGraphVisitor::VisitCaseNode");
}


// <Statement> ::= While { label:     SourceLabel
//                         condition: <Expression>
//                         body:      <Sequence> }
void EffectGraphVisitor::VisitWhileNode(WhileNode* node) {
  TestGraphVisitor for_test(owner(), temp_index());
  node->condition()->Visit(&for_test);

  EffectGraphVisitor for_body(owner(), temp_index());
  if (for_test.can_be_true()) node->body()->Visit(&for_body);
  TieLoop(for_test, for_body);
}

void ValueGraphVisitor::VisitWhileNode(WhileNode* node) { UNREACHABLE(); }
void TestGraphVisitor::VisitWhileNode(WhileNode* node) { UNREACHABLE(); }


void EffectGraphVisitor::VisitDoWhileNode(DoWhileNode* node) {
  Bailout("EffectGraphVisitor::VisitDoWhileNode");
}
void ValueGraphVisitor::VisitDoWhileNode(DoWhileNode* node) {
  Bailout("ValueGraphVisitor::VisitDoWhileNode");
}
void TestGraphVisitor::VisitDoWhileNode(DoWhileNode* node) {
  Bailout("TestGraphVisitor::VisitDoWhileNode");
}


void EffectGraphVisitor::VisitForNode(ForNode* node) {
  Bailout("EffectGraphVisitor::VisitForNode");
}
void ValueGraphVisitor::VisitForNode(ForNode* node) {
  Bailout("ValueGraphVisitor::VisitForNode");
}
void TestGraphVisitor::VisitForNode(ForNode* node) {
  Bailout("TestGraphVisitor::VisitForNode");
}


void EffectGraphVisitor::VisitJumpNode(JumpNode* node) {
  Bailout("EffectGraphVisitor::VisitJumpNode");
}
void ValueGraphVisitor::VisitJumpNode(JumpNode* node) {
  Bailout("ValueGraphVisitor::VisitJumpNode");
}
void TestGraphVisitor::VisitJumpNode(JumpNode* node) {
  Bailout("TestGraphVisitor::VisitJumpNode");
}


void EffectGraphVisitor::VisitArgumentListNode(ArgumentListNode* node) {
  UNREACHABLE();
}
void ValueGraphVisitor::VisitArgumentListNode(ArgumentListNode* node) {
  UNREACHABLE();
}
void TestGraphVisitor::VisitArgumentListNode(ArgumentListNode* node) {
  UNREACHABLE();
}


void EffectGraphVisitor::VisitArrayNode(ArrayNode* node) {
  Bailout("EffectGraphVisitor::VisitArrayNode");
}
void ValueGraphVisitor::VisitArrayNode(ArrayNode* node) {
  Bailout("ValueGraphVisitor::VisitArrayNode");
}
void TestGraphVisitor::VisitArrayNode(ArrayNode* node) {
  Bailout("TestGraphVisitor::VisitArrayNode");
}


void EffectGraphVisitor::VisitClosureNode(ClosureNode* node) {
  Bailout("EffectGraphVisitor::VisitClosureNode");
}
void ValueGraphVisitor::VisitClosureNode(ClosureNode* node) {
  Bailout("ValueGraphVisitor::VisitClosureNode");
}
void TestGraphVisitor::VisitClosureNode(ClosureNode* node) {
  Bailout("TestGraphVisitor::VisitClosureNode");
}


void EffectGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  Bailout("EffectGraphVisitor::VisitInstanceCallNode");
}
void ValueGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  Bailout("ValueGraphVisitor::VisitInstanceCallNode");
}
void TestGraphVisitor::VisitInstanceCallNode(InstanceCallNode* node) {
  Bailout("TestGraphVisitor::VisitInstanceCallNode");
}


// <Expression> ::= StaticCall { function: Function
//                               arguments: <ArgumentList> }
StaticCallComp* EffectGraphVisitor::TranslateStaticCall(
    const StaticCallNode& node) {
  ArgumentListNode* arguments = node.arguments();
  int length = arguments->length();
  ZoneGrowableArray<Value*>* values = new ZoneGrowableArray<Value*>(length);
  int index = temp_index();
  for (intptr_t i = 0; i < length; ++i) {
    ValueGraphVisitor for_value(owner(), index);
    arguments->NodeAt(i)->Visit(&for_value);
    Append(for_value);
    CHECK_ALIVE(return NULL);
    values->Add(for_value.value());
    index = for_value.temp_index();
  }
  return new StaticCallComp(node.function(), values);
}

void EffectGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  StaticCallComp* call = TranslateStaticCall(*node);
  CHECK_ALIVE(return);
  DoComputation(call);
}

void ValueGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  StaticCallComp* call = TranslateStaticCall(*node);
  CHECK_ALIVE(return);
  ReturnValueOf(call);
}

void TestGraphVisitor::VisitStaticCallNode(StaticCallNode* node) {
  StaticCallComp* call = TranslateStaticCall(*node);
  CHECK_ALIVE(return);
  BranchOnValueOf(call);
}


void EffectGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  Bailout("EffectGraphVisitor::VisitClosureCallNode");
}
void ValueGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  Bailout("ValueGraphVisitor::VisitClosureCallNode");
}
void TestGraphVisitor::VisitClosureCallNode(ClosureCallNode* node) {
  Bailout("TestGraphVisitor::VisitClosureCallNode");
}


void EffectGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  Bailout("EffectGraphVisitor::VisitCloneContextNode");
}
void ValueGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  Bailout("ValueGraphVisitor::VisitCloneContextNode");
}
void TestGraphVisitor::VisitCloneContextNode(CloneContextNode* node) {
  Bailout("TestGraphVisitor::VisitCloneContextNode");
}


void EffectGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  Bailout("EffectGraphVisitor::VisitConstructorCallNode");
}
void ValueGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  Bailout("ValueGraphVisitor::VisitConstructorCallNode");
}
void TestGraphVisitor::VisitConstructorCallNode(ConstructorCallNode* node) {
  Bailout("TestGraphVisitor::VisitConstructorCallNode");
}


void EffectGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  Bailout("EffectGraphVisitor::VisitInstanceGetterNode");
}
void ValueGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  Bailout("ValueGraphVisitor::VisitInstanceGetterNode");
}
void TestGraphVisitor::VisitInstanceGetterNode(InstanceGetterNode* node) {
  Bailout("TestGraphVisitor::VisitInstanceGetterNode");
}


void EffectGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  Bailout("EffectGraphVisitor::VisitInstanceSetterNode");
}
void ValueGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  Bailout("ValueGraphVisitor::VisitInstanceSetterNode");
}
void TestGraphVisitor::VisitInstanceSetterNode(InstanceSetterNode* node) {
  Bailout("TestGraphVisitor::VisitInstanceSetterNode");
}


void EffectGraphVisitor::VisitStaticGetterNode(StaticGetterNode* node) {
  Bailout("EffectGraphVisitor::VisitStaticGetterNode");
}
void ValueGraphVisitor::VisitStaticGetterNode(StaticGetterNode* node) {
  Bailout("ValueGraphVisitor::VisitStaticGetterNode");
}
void TestGraphVisitor::VisitStaticGetterNode(StaticGetterNode* node) {
  Bailout("TestGraphVisitor::VisitStaticGetterNode");
}


void EffectGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  Bailout("EffectGraphVisitor::VisitStaticSetterNode");
}
void ValueGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  Bailout("ValueGraphVisitor::VisitStaticSetterNode");
}
void TestGraphVisitor::VisitStaticSetterNode(StaticSetterNode* node) {
  Bailout("TestGraphVisitor::VisitStaticSetterNode");
}


void EffectGraphVisitor::VisitNativeBodyNode(NativeBodyNode* node) {
  Bailout("EffectGraphVisitor::VisitNativeBodyNode");
}
void ValueGraphVisitor::VisitNativeBodyNode(NativeBodyNode* node) {
  Bailout("ValueGraphVisitor::VisitNativeBodyNode");
}
void TestGraphVisitor::VisitNativeBodyNode(NativeBodyNode* node) {
  Bailout("TestGraphVisitor::VisitNativeBodyNode");
}


void EffectGraphVisitor::VisitPrimaryNode(PrimaryNode* node) {
  Bailout("EffectGraphVisitor::VisitPrimaryNode");
}
void ValueGraphVisitor::VisitPrimaryNode(PrimaryNode* node) {
  Bailout("ValueGraphVisitor::VisitPrimaryNode");
}
void TestGraphVisitor::VisitPrimaryNode(PrimaryNode* node) {
  Bailout("TestGraphVisitor::VisitPrimaryNode");
}


// <Expression> ::= LoadLocal { local: LocalVariable }
void EffectGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  return;
}

void ValueGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  LoadLocalComp* load = new LoadLocalComp(node->local());
  ReturnValueOf(load);
}

void TestGraphVisitor::VisitLoadLocalNode(LoadLocalNode* node) {
  LoadLocalComp* load = new LoadLocalComp(node->local());
  BranchOnValueOf(load);
}


// <Expression> ::= StoreLocal { local: LocalVariable
//                               value: <Expression> }
StoreLocalComp* EffectGraphVisitor::TranslateStoreLocal(
    const StoreLocalNode& node) {
  ValueGraphVisitor for_value(owner(), temp_index());
  node.value()->Visit(&for_value);
  Append(for_value);
  CHECK_ALIVE(return NULL);
  return new StoreLocalComp(node.local(), for_value.value());
}

void EffectGraphVisitor::VisitStoreLocalNode(StoreLocalNode* node) {
  StoreLocalComp* store = TranslateStoreLocal(*node);
  CHECK_ALIVE(return);
  DoComputation(store);
}

void ValueGraphVisitor::VisitStoreLocalNode(StoreLocalNode* node) {
  StoreLocalComp* store = TranslateStoreLocal(*node);
  CHECK_ALIVE(return);
  ReturnValueOf(store);
}

void TestGraphVisitor::VisitStoreLocalNode(StoreLocalNode* node) {
  StoreLocalComp* store = TranslateStoreLocal(*node);
  CHECK_ALIVE(return);
  BranchOnValueOf(store);
}


void EffectGraphVisitor::VisitLoadInstanceFieldNode(
    LoadInstanceFieldNode* node) {
  Bailout("EffectGraphVisitor::VisitLoadInstanceFieldNode");
}
void ValueGraphVisitor::VisitLoadInstanceFieldNode(
    LoadInstanceFieldNode* node) {
  Bailout("ValueGraphVisitor::VisitLoadInstanceFieldNode");
}
void TestGraphVisitor::VisitLoadInstanceFieldNode(LoadInstanceFieldNode* node) {
  Bailout("TestGraphVisitor::VisitLoadInstanceFieldNode");
}


void EffectGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  Bailout("EffectGraphVisitor::VisitStoreInstanceFieldNode");
}
void ValueGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  Bailout("ValueGraphVisitor::VisitStoreInstanceFieldNode");
}
void TestGraphVisitor::VisitStoreInstanceFieldNode(
    StoreInstanceFieldNode* node) {
  Bailout("TestGraphVisitor::VisitStoreInstanceFieldNode");
}


void EffectGraphVisitor::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  Bailout("EffectGraphVisitor::VisitLoadStaticFieldNode");
}
void ValueGraphVisitor::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  Bailout("ValueGraphVisitor::VisitLoadStaticFieldNode");
}
void TestGraphVisitor::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  Bailout("TestGraphVisitor::VisitLoadStaticFieldNode");
}


void EffectGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  Bailout("EffectGraphVisitor::VisitStoreStaticFieldNode");
}
void ValueGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  Bailout("ValueGraphVisitor::VisitStoreStaticFieldNode");
}
void TestGraphVisitor::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  Bailout("TestGraphVisitor::VisitStoreStaticFieldNode");
}


void EffectGraphVisitor::VisitLoadIndexedNode(LoadIndexedNode* node) {
  Bailout("EffectGraphVisitor::VisitLoadIndexedNode");
}
void ValueGraphVisitor::VisitLoadIndexedNode(LoadIndexedNode* node) {
  Bailout("ValueGraphVisitor::VisitLoadIndexedNode");
}
void TestGraphVisitor::VisitLoadIndexedNode(LoadIndexedNode* node) {
  Bailout("TestGraphVisitor::VisitLoadIndexedNode");
}


void EffectGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  Bailout("EffectGraphVisitor::VisitStoreIndexedNode");
}
void ValueGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  Bailout("ValueGraphVisitor::VisitStoreIndexedNode");
}
void TestGraphVisitor::VisitStoreIndexedNode(StoreIndexedNode* node) {
  Bailout("TestGraphVisitor::VisitStoreIndexedNode");
}


// <Statement> ::= Sequence { scope: LocalScope
//                            nodes: <Statement>*
//                            label: SourceLabel }
void EffectGraphVisitor::VisitSequenceNode(SequenceNode* node) {
  if ((node->scope() != NULL) &&
      (node->scope()->num_context_variables() != 0)) {
    Bailout("Sequence needs a context.  Gotta have a context.");
  }
  for (intptr_t i = 0; i < node->length(); ++i) {
    EffectGraphVisitor for_effect(owner(), temp_index());
    node->NodeAt(i)->Visit(&for_effect);
    Append(for_effect);
    CHECK_ALIVE(return);
  }
}

void ValueGraphVisitor::VisitSequenceNode(SequenceNode* node) { UNREACHABLE(); }
void TestGraphVisitor::VisitSequenceNode(SequenceNode* node) { UNREACHABLE(); }


void EffectGraphVisitor::VisitCatchClauseNode(CatchClauseNode* node) {
  Bailout("EffectGraphVisitor::VisitCatchClauseNode");
}
void ValueGraphVisitor::VisitCatchClauseNode(CatchClauseNode* node) {
  Bailout("ValueGraphVisitor::VisitCatchClauseNode");
}
void TestGraphVisitor::VisitCatchClauseNode(CatchClauseNode* node) {
  Bailout("TestGraphVisitor::VisitCatchClauseNode");
}


void EffectGraphVisitor::VisitTryCatchNode(TryCatchNode* node) {
  Bailout("EffectGraphVisitor::VisitTryCatchNode");
}
void ValueGraphVisitor::VisitTryCatchNode(TryCatchNode* node) {
  Bailout("ValueGraphVisitor::VisitTryCatchNode");
}
void TestGraphVisitor::VisitTryCatchNode(TryCatchNode* node) {
  Bailout("TestGraphVisitor::VisitTryCatchNode");
}


void EffectGraphVisitor::VisitThrowNode(ThrowNode* node) {
  Bailout("EffectGraphVisitor::VisitThrowNode");
}
void ValueGraphVisitor::VisitThrowNode(ThrowNode* node) {
  Bailout("ValueGraphVisitor::VisitThrowNode");
}
void TestGraphVisitor::VisitThrowNode(ThrowNode* node) {
  Bailout("TestGraphVisitor::VisitThrowNode");
}


void EffectGraphVisitor::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  Bailout("EffectGraphVisitor::VisitInlinedFinallyNode");
}
void ValueGraphVisitor::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  Bailout("ValueGraphVisitor::VisitInlinedFinallyNode");
}
void TestGraphVisitor::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  Bailout("TestGraphVisitor::VisitInlinedFinallyNode");
}


void FlowGraphBuilder::PrintGraph() const {
  OS::Print("==== %s\n",
            parsed_function().function().ToFullyQualifiedCString());

  for (intptr_t i = postorder_block_entries_.length() - 1; i >= 0; --i) {
    // Print the block entry.
    Instruction* current = postorder_block_entries_[i]->Print();
    // And all the successors until an exit, branch, or a block entry.
    while ((current != NULL) && !current->IsBlockEntry()) {
      OS::Print("\n");
      current = current->Print();
    }
    if (current != NULL && current->IsBlockEntry()) {
      OS::Print(" goto %d", current->GetBlockNumber());
    }
    OS::Print("\n");
  }
}


void FlowGraphBuilder::BuildGraph() {
  EffectGraphVisitor for_effect(this, 0);
  for_effect.AddInstruction(new TargetEntryInstr());
  parsed_function().node_sequence()->Visit(&for_effect);
  if (for_effect.entry() != NULL) {
    // Accumulate basic block entries via postorder traversal.
    for_effect.entry()->Postorder(&postorder_block_entries_);
    // Number the blocks in reverse postorder starting with 0.
    intptr_t last_index = postorder_block_entries_.length() - 1;
    for (intptr_t i = last_index; i >= 0; --i) {
      postorder_block_entries_[i]->SetBlockNumber(last_index - i);
    }
  }
  if (FLAG_print_flow_graph) {
    PrintGraph();
  }
}


void FlowGraphBuilder::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphBuilder Bailout: %s";
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


}  // namespace dart
