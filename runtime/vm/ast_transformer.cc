// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast_transformer.h"

#include "vm/parser.h"

namespace dart {

// Quick access to the locally defined isolate() method.
#define I (isolate())

// Nodes that are unreachable from already parsed expressions.
#define FOR_EACH_UNREACHABLE_NODE(V)                                           \
  V(Case)                                                                      \
  V(CatchClause)                                                               \
  V(CloneContext)                                                              \
  V(ClosureCall)                                                               \
  V(DoWhile)                                                                   \
  V(If)                                                                        \
  V(InlinedFinally)                                                            \
  V(For)                                                                       \
  V(Jump)                                                                      \
  V(LoadInstanceField)                                                         \
  V(NativeBody)                                                                \
  V(Primary)                                                                   \
  V(Return)                                                                    \
  V(Sequence)                                                                  \
  V(StoreInstanceField)                                                        \
  V(Switch)                                                                    \
  V(TryCatch)                                                                  \
  V(While)

#define DEFINE_UNREACHABLE(BaseName)                                           \
void AwaitTransformer::Visit##BaseName##Node(BaseName##Node* node) {           \
  UNREACHABLE();                                                               \
}

FOR_EACH_UNREACHABLE_NODE(DEFINE_UNREACHABLE)
#undef DEFINE_UNREACHABLE


AstNode* AwaitTransformer::Transform(AstNode* expr) {
  expr->Visit(this);
  return result_;
}


LocalVariable* AwaitTransformer::EnsureCurrentTempVar() {
  const char* await_temp_prefix = ":await_temp_var_";
  const String& cnt_str = String::ZoneHandle(
      I, String::NewFormatted("%s%d", await_temp_prefix, temp_cnt_));
  const String& symbol = String::ZoneHandle(I, Symbols::New(cnt_str));
  ASSERT(!symbol.IsNull());
  LocalVariable* await_tmp =
      parsed_function_->await_temps_scope()->LookupVariable(symbol, false);
  if (await_tmp == NULL) {
    await_tmp = new(I) LocalVariable(
        Scanner::kNoSourcePos,
        symbol,
        Type::ZoneHandle(I, Type::DynamicType()));
    parsed_function_->await_temps_scope()->AddVariable(await_tmp);
  }
  return await_tmp;
}


LocalVariable* AwaitTransformer::AddToPreambleNewTempVar(AstNode* node) {
  LocalVariable* tmp_var = EnsureCurrentTempVar();
  preamble_->Add(new(I) StoreLocalNode(Scanner::kNoSourcePos, tmp_var, node));
  NextTempVar();
  return tmp_var;
}


void AwaitTransformer::VisitLiteralNode(LiteralNode* node) {
  result_ = node;
}


void AwaitTransformer::VisitTypeNode(TypeNode* node) {
  result_ = new(I) TypeNode(node->token_pos(), node->type());
}



void AwaitTransformer::VisitAwaitNode(AwaitNode* node) {
  // Await transformation:
  //
  //   :await_temp_var_X = <expr>;
  //   :result_param = :await_temp_var_X;
  //   if (:result_param is Future) {
  //     // :result_param.then(:async_op);
  //   }
  //   :await_temp_var_(X+1) = :result_param;

  LocalVariable* async_op = preamble_->scope()->LookupVariable(
      Symbols::AsyncOperation(), false);
  ASSERT(async_op != NULL);
  LocalVariable* result_param = preamble_->scope()->LookupVariable(
      Symbols::AsyncOperationParam(), false);
  ASSERT(result_param != NULL);

  node->expr()->Visit(this);
  preamble_->Add(new(I) StoreLocalNode(Scanner::kNoSourcePos,
                                       result_param,
                                       result_));
  LoadLocalNode* load_result_param = new(I) LoadLocalNode(
      Scanner::kNoSourcePos, result_param);
  SequenceNode* is_future_branch = new(I) SequenceNode(
      Scanner::kNoSourcePos, preamble_->scope());
  ArgumentListNode* args = new(I) ArgumentListNode(Scanner::kNoSourcePos);
  args->Add(new(I) LoadLocalNode(Scanner::kNoSourcePos, async_op));
  // TODO(mlippautz): Once continuations are supported, just call .then().
  // is_future_branch->Add(new(I) InstanceCallNode(
  // Scanner::kNoSourcePos, load_result_param, Symbols::FutureThen(), args));
  //
  // For now, throw an exception.
  const String& exception = String::ZoneHandle(
      I, String::New("awaitable futures not yet supported", Heap::kOld));
  is_future_branch->Add(new(I) ThrowNode(
      Scanner::kNoSourcePos,
      new(I) LiteralNode(
          Scanner::kNoSourcePos,
          String::ZoneHandle(I, Symbols::New(exception))),
      NULL));
  const Class& cls = Class::ZoneHandle(
      I, library_.LookupClass(Symbols::Future()));
  const AbstractType& future_type = AbstractType::ZoneHandle(I,
      cls.RareType());
  ASSERT(!future_type.IsNull());
  TypeNode* future_type_node = new(I) TypeNode(
      Scanner::kNoSourcePos, future_type);
  IfNode* is_future_if = new(I) IfNode(
      Scanner::kNoSourcePos,
      new(I) ComparisonNode(Scanner::kNoSourcePos,
                            Token::kIS,
                            load_result_param,
                            future_type_node),
      is_future_branch,
      NULL);
  preamble_->Add(is_future_if);

  // TODO(mlippautz): Join for await needs to happen here.

  LocalVariable* result = AddToPreambleNewTempVar(new(I) LoadLocalNode(
      Scanner::kNoSourcePos, result_param));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


// Transforms boolean expressions into a sequence of evaluatons that only lazily
// evaluate subexpressions.
//
// Example:
//
//   (a || b) only evaluates b if a is false
//
// Transformation (roughly):
//
//   t_1 = a;
//   if (!t_1) {
//     t_2 = b;
//   }
//   t_3 = t_1 || t_2;  // Compiler takes care that lazy evaluation takes place
//                         on this level.
AstNode* AwaitTransformer::LazyTransform(const Token::Kind logical_op,
                                         AstNode* new_left,
                                         AstNode* right) {
  ASSERT(logical_op == Token::kAND || logical_op == Token::kOR);
  AstNode* result = NULL;
  const Token::Kind compare_logical_op = (logical_op == Token::kAND) ?
      Token::kEQ : Token::kNE;
  SequenceNode* eval = new(I) SequenceNode(
      Scanner::kNoSourcePos, preamble_->scope());
  SequenceNode* saved_preamble = preamble_;
  preamble_ = eval;
  result = Transform(right);
  preamble_ = saved_preamble;
  IfNode* right_body = new(I) IfNode(
      Scanner::kNoSourcePos,
      new(I) ComparisonNode(
          Scanner::kNoSourcePos,
          compare_logical_op,
          new_left,
          new(I) LiteralNode(Scanner::kNoSourcePos, Bool::True())),
      eval,
      NULL);
  preamble_->Add(right_body);
  return result;
}


void AwaitTransformer::VisitBinaryOpNode(BinaryOpNode* node) {
  node->left()->Visit(this);
  AstNode* new_left = result_;
  AstNode* new_right = NULL;
  // Preserve lazy evaluaton.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    new_right = LazyTransform(node->kind(), new_left, node->right());
  } else {
    new_right = Transform(node->right());
  }
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) BinaryOpNode(node->token_pos(),
                          node->kind(),
                          new_left,
                          new_right));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitBinaryOpWithMask32Node(
    BinaryOpWithMask32Node* node) {
  node->left()->Visit(this);
  AstNode* new_left = result_;
  AstNode* new_right = NULL;
  // Preserve lazy evaluaton.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    new_right = LazyTransform(node->kind(), new_left, node->right());
  } else {
    new_right = Transform(node->right());
  }
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) BinaryOpWithMask32Node(node->token_pos(),
                                    node->kind(),
                                    new_left,
                                    new_right,
                                    node->mask32()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitComparisonNode(ComparisonNode* node) {
  AstNode* new_left = Transform(node->left());
  AstNode* new_right = Transform(node->right());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) ComparisonNode(node->token_pos(),
                            node->kind(),
                            new_left,
                            new_right));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitUnaryOpNode(UnaryOpNode* node) {
  AstNode* new_operand = Transform(node->operand());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) UnaryOpNode(node->token_pos(), node->kind(), new_operand));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


// ::= (<condition>) ? <true-branch> : <false-branch>
//
void AwaitTransformer::VisitConditionalExprNode(ConditionalExprNode* node) {
  AstNode* new_condition = Transform(node->condition());
  SequenceNode* new_true = new(I) SequenceNode(
      Scanner::kNoSourcePos, preamble_->scope());
  SequenceNode* saved_preamble = preamble_;
  preamble_ = new_true;
  AstNode* new_true_result = Transform(node->true_expr());
  SequenceNode* new_false = new(I) SequenceNode(
      Scanner::kNoSourcePos, preamble_->scope());
  preamble_ = new_false;
  AstNode* new_false_result = Transform(node->false_expr());
  preamble_ = saved_preamble;
  IfNode* new_if = new(I) IfNode(Scanner::kNoSourcePos,
                                 new_condition,
                                 new_true,
                                 new_false);
  preamble_->Add(new_if);
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) ConditionalExprNode(Scanner::kNoSourcePos,
                                 new_condition,
                                 new_true_result,
                                 new_false_result));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitArgumentListNode(ArgumentListNode* node) {
  ArgumentListNode* new_args = new(I) ArgumentListNode(node->token_pos());
  for (intptr_t i = 0; i < node->length(); i++) {
    new_args->Add(Transform(node->NodeAt(i)));
  }
  result_ = new_args;
}


void AwaitTransformer::VisitArrayNode(ArrayNode* node) {
  GrowableArray<AstNode*> new_elements;
  for (intptr_t i = 0; i < node->length(); i++) {
    new_elements.Add(Transform(node->ElementAt(i)));
  }
  result_ = new(I) ArrayNode(node->token_pos(), node->type(), new_elements);
}


void AwaitTransformer::VisitStringInterpolateNode(StringInterpolateNode* node) {
  ArrayNode* new_value = Transform(node->value())->AsArrayNode();
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) StringInterpolateNode(node->token_pos(),
                                   new_value));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitClosureNode(ClosureNode* node) {
  AstNode* new_receiver = node->receiver();
  if (new_receiver != NULL) {
    new_receiver = Transform(new_receiver);
  }
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) ClosureNode(node->token_pos(),
                         node->function(),
                         new_receiver,
                         node->scope()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitInstanceCallNode(InstanceCallNode* node) {
  AstNode* new_receiver = Transform(node->receiver());
  ArgumentListNode* new_args =
      Transform(node->arguments())->AsArgumentListNode();
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) InstanceCallNode(node->token_pos(),
                              new_receiver,
                              node->function_name(),
                              new_args));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitStaticCallNode(StaticCallNode* node) {
  ArgumentListNode* new_args =
      Transform(node->arguments())->AsArgumentListNode();
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) StaticCallNode(node->token_pos(),
                            node->function(),
                            new_args));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitConstructorCallNode(ConstructorCallNode* node) {
  ArgumentListNode* new_args =
      Transform(node->arguments())->AsArgumentListNode();
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) ConstructorCallNode(node->token_pos(),
                                 node->type_arguments(),
                                 node->constructor(),
                                 new_args));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitInstanceGetterNode(InstanceGetterNode* node) {
  AstNode* new_receiver = Transform(node->receiver());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) InstanceGetterNode(node->token_pos(),
                                new_receiver,
                                node->field_name()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitInstanceSetterNode(InstanceSetterNode* node) {
  AstNode* new_receiver = node->receiver();
  if (new_receiver != NULL) {
    new_receiver = Transform(new_receiver);
  }
  AstNode* new_value = Transform(node->value());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) InstanceSetterNode(node->token_pos(),
                                new_receiver,
                                node->field_name(),
                                new_value));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitStaticGetterNode(StaticGetterNode* node) {
  AstNode* new_receiver = node->receiver();
  if (new_receiver != NULL) {
    new_receiver = Transform(new_receiver);
  }
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) StaticGetterNode(node->token_pos(),
                              new_receiver,
                              node->is_super_getter(),
                              node->cls(),
                              node->field_name()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitStaticSetterNode(StaticSetterNode* node) {
  AstNode* new_receiver = node->receiver();
  if (new_receiver != NULL) {
    new_receiver = Transform(new_receiver);
  }
  AstNode* new_value = Transform(node->value());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) StaticSetterNode(node->token_pos(),
                              new_receiver,
                              node->cls(),
                              node->field_name(),
                              new_value));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitLoadLocalNode(LoadLocalNode* node) {
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) LoadLocalNode(node->token_pos(), &node->local()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitStoreLocalNode(StoreLocalNode* node) {
  AstNode* new_value = Transform(node->value());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) StoreLocalNode(node->token_pos(),
                            &node->local(),
                            new_value));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) LoadStaticFieldNode(node->token_pos(),
                                 node->field()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  AstNode* new_value = Transform(node->value());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) StoreStaticFieldNode(node->token_pos(),
                                  node->field(),
                                  new_value));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitLoadIndexedNode(LoadIndexedNode* node) {
  AstNode* new_array = Transform(node->array());
  AstNode* new_index = Transform(node->index_expr());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) LoadIndexedNode(node->token_pos(),
                             new_array,
                             new_index,
                             node->super_class()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitStoreIndexedNode(StoreIndexedNode* node) {
  AstNode* new_array = Transform(node->array());
  AstNode* new_index = Transform(node->index_expr());
  AstNode* new_value = Transform(node->value());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) StoreIndexedNode(node->token_pos(),
                              new_array,
                              new_index,
                              new_value,
                              node->super_class()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitAssignableNode(AssignableNode* node) {
  AstNode* new_expr = Transform(node->expr());
  LocalVariable* result = AddToPreambleNewTempVar(
      new(I) AssignableNode(node->token_pos(),
                            new_expr,
                            node->type(),
                            node->dst_name()));
  result_ = new(I) LoadLocalNode(Scanner::kNoSourcePos, result);
}


void AwaitTransformer::VisitLetNode(LetNode* node) {
  // TODO(mlippautz): Check initializers and their temps.
  LetNode* result = new(I) LetNode(node->token_pos());
  for (intptr_t i = 0; i < node->nodes().length(); i++) {
    result->AddNode(Transform(node->nodes()[i]));
  }
  result_ = result;
}


void AwaitTransformer::VisitThrowNode(ThrowNode* node) {
  // TODO(mlippautz): Check if relevant.
  AstNode* new_exception = Transform(node->exception());
  AstNode* new_stacktrace = Transform(node->stacktrace());
  result_ = new(I) ThrowNode(node->token_pos(),
                             new_exception,
                             new_stacktrace);
}

}  // namespace dart
