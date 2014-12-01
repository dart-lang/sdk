// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast_transformer.h"

#include "vm/object_store.h"
#include "vm/parser.h"

namespace dart {

// Quick access to the locally defined isolate() method.
#define I (isolate())

// Nodes that are unreachable from already parsed expressions.
#define FOR_EACH_UNREACHABLE_NODE(V)                                           \
  V(AwaitMarker)                                                               \
  V(Case)                                                                      \
  V(CatchClause)                                                               \
  V(CloneContext)                                                              \
  V(ClosureCall)                                                               \
  V(DoWhile)                                                                   \
  V(If)                                                                        \
  V(InitStaticField)                                                           \
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

AwaitTransformer::AwaitTransformer(SequenceNode* preamble,
                                   ParsedFunction* const parsed_function,
                                   LocalScope* function_top)
    : preamble_(preamble),
      temp_cnt_(0),
      parsed_function_(parsed_function),
      function_top_(function_top),
      isolate_(Isolate::Current()) {
  ASSERT(function_top_ != NULL);
}


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
  // Look up the variable through the preamble scope.
  LocalVariable* await_tmp = preamble_->scope()->LookupVariable(symbol, false);
  if (await_tmp == NULL) {
    // If we need a new temp variable, we add it to the function's top scope.
    await_tmp = new (I) LocalVariable(
        Scanner::kNoSourcePos, symbol, Type::ZoneHandle(Type::DynamicType()));
    function_top_->AddVariable(await_tmp);
    // After adding it to the top scope, we can look it up from the preamble.
    // The following call includes an ASSERT check.
    await_tmp = GetVariableInScope(preamble_->scope(), symbol);
  }
  return await_tmp;
}


LocalVariable* AwaitTransformer::GetVariableInScope(LocalScope* scope,
                                                    const String& symbol) {
  LocalVariable* var = scope->LookupVariable(symbol, false);
  ASSERT(var != NULL);
  return var;
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
  //   if (:result_param is !Future) {
  //     :result_param = Future.value(:result_param);
  //   }
  //   AwaitMarker(kNewContinuationState);
  //   :result_param = :result_param.then(:async_op);
  //   _asyncCatchHelper(:result_param.catchError, :async_op);
  //   return;  // (return_type() == kContinuationTarget)
  //
  //   :saved_try_ctx_var = :await_saved_try_ctx_var_y;
  //   :await_temp_var_(X+1) = :result_param;

  LocalVariable* async_op = GetVariableInScope(
      preamble_->scope(), Symbols::AsyncOperation());
  LocalVariable* result_param = GetVariableInScope(
      preamble_->scope(), Symbols::AsyncOperationParam());
  LocalVariable* error_param = GetVariableInScope(
      preamble_->scope(), Symbols::AsyncOperationErrorParam());

  AstNode* transformed_expr = Transform(node->expr());
  preamble_->Add(new(I) StoreLocalNode(
      Scanner::kNoSourcePos, result_param, transformed_expr));

  LoadLocalNode* load_result_param = new(I) LoadLocalNode(
      Scanner::kNoSourcePos, result_param);

  const Class& future_cls =
      Class::ZoneHandle(I, I->object_store()->future_class());
  ASSERT(!future_cls.IsNull());
  const AbstractType& future_type =
      AbstractType::ZoneHandle(I, future_cls.RareType());
  ASSERT(!future_type.IsNull());

  LocalScope* is_not_future_scope = ChainNewScope(preamble_->scope());
  SequenceNode* is_not_future_branch =
      new (I) SequenceNode(Scanner::kNoSourcePos, is_not_future_scope);

  // if (:result_param is !Future) {
  //   :result_param = Future.value(:result_param);
  // }
  const Function& value_ctor = Function::ZoneHandle(
      I, future_cls.LookupFunction(Symbols::FutureValue()));
  ASSERT(!value_ctor.IsNull());
  ArgumentListNode* ctor_args = new (I) ArgumentListNode(Scanner::kNoSourcePos);
  ctor_args->Add(new (I) LoadLocalNode(Scanner::kNoSourcePos, result_param));
  ConstructorCallNode* ctor_call =
      new (I) ConstructorCallNode(Scanner::kNoSourcePos,
                                  TypeArguments::ZoneHandle(I),
                                  value_ctor,
                                  ctor_args);
  is_not_future_branch->Add(new (I) StoreLocalNode(
      Scanner::kNoSourcePos, result_param, ctor_call));
  AstNode* is_not_future_test = new (I) ComparisonNode(
      Scanner::kNoSourcePos,
      Token::kISNOT,
      load_result_param,
      new (I) TypeNode(Scanner::kNoSourcePos, future_type));
  preamble_->Add(new(I) IfNode(Scanner::kNoSourcePos,
                               is_not_future_test,
                               is_not_future_branch,
                               NULL));

  AwaitMarkerNode* await_marker = new (I) AwaitMarkerNode();
  await_marker->set_scope(preamble_->scope());
  preamble_->Add(await_marker);
  ArgumentListNode* args = new(I) ArgumentListNode(Scanner::kNoSourcePos);

  args->Add(new(I) LoadLocalNode(Scanner::kNoSourcePos, async_op));
  preamble_->Add(new (I) StoreLocalNode(
      Scanner::kNoSourcePos,
      result_param,
      new(I) InstanceCallNode(Scanner::kNoSourcePos,
                              load_result_param,
                              Symbols::FutureThen(),
                              args)));
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const Function& async_catch_helper = Function::ZoneHandle(
      I, core_lib.LookupFunctionAllowPrivate(Symbols::AsyncCatchHelper()));
  ASSERT(!async_catch_helper.IsNull());
  ArgumentListNode* catch_helper_args = new (I) ArgumentListNode(
      Scanner::kNoSourcePos);
  InstanceGetterNode* catch_error_getter = new (I) InstanceGetterNode(
      Scanner::kNoSourcePos,
      load_result_param,
      Symbols::FutureCatchError());
  catch_helper_args->Add(catch_error_getter);
  catch_helper_args->Add(new (I) LoadLocalNode(
      Scanner::kNoSourcePos, async_op));
  preamble_->Add(new (I) StaticCallNode(
      Scanner::kNoSourcePos,
      async_catch_helper,
      catch_helper_args));
  ReturnNode* continuation_return = new(I) ReturnNode(Scanner::kNoSourcePos);
  continuation_return->set_return_type(ReturnNode::kContinuationTarget);
  preamble_->Add(continuation_return);

  // If this expression is part of a try block, also append the code for
  // restoring the saved try context that lives on the stack.
  const String& async_saved_try_ctx_name =
      String::Handle(I, parsed_function_->async_saved_try_ctx_name());
  if (!async_saved_try_ctx_name.IsNull()) {
    LocalVariable* async_saved_try_ctx =
        GetVariableInScope(preamble_->scope(), async_saved_try_ctx_name);
    preamble_->Add(new (I) StoreLocalNode(
        Scanner::kNoSourcePos,
        parsed_function_->saved_try_ctx(),
        new (I) LoadLocalNode(Scanner::kNoSourcePos, async_saved_try_ctx)));
  }

  LoadLocalNode* load_error_param = new (I) LoadLocalNode(
      Scanner::kNoSourcePos, error_param);
  SequenceNode* error_ne_null_branch = new (I) SequenceNode(
      Scanner::kNoSourcePos, ChainNewScope(preamble_->scope()));
  error_ne_null_branch->Add(new (I) ThrowNode(
      Scanner::kNoSourcePos,
      load_error_param,
      NULL));
  preamble_->Add(new (I) IfNode(
      Scanner::kNoSourcePos,
      new (I) ComparisonNode(
          Scanner::kNoSourcePos,
          Token::kNE,
          load_error_param,
          new (I) LiteralNode(Scanner::kNoSourcePos,
                              Object::null_instance())),
          error_ne_null_branch,
          NULL));

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
  SequenceNode* eval = new (I) SequenceNode(
      Scanner::kNoSourcePos, ChainNewScope(preamble_->scope()));
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


LocalScope* AwaitTransformer::ChainNewScope(LocalScope* parent) {
  return new (I) LocalScope(
      parent, parent->function_level(), parent->loop_level());
}


void AwaitTransformer::VisitBinaryOpNode(BinaryOpNode* node) {
  AstNode* new_left = Transform(node->left());
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
  ASSERT((node->kind() != Token::kAND) && (node->kind() != Token::kOR));
  AstNode* new_left = Transform(node->left());
  AstNode* new_right = Transform(node->right());
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
  SequenceNode* new_true = new (I) SequenceNode(
      Scanner::kNoSourcePos, ChainNewScope(preamble_->scope()));
  SequenceNode* saved_preamble = preamble_;
  preamble_ = new_true;
  AstNode* new_true_result = Transform(node->true_expr());
  SequenceNode* new_false = new (I) SequenceNode(
      Scanner::kNoSourcePos, ChainNewScope(preamble_->scope()));
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
  new_args->set_names(node->names());
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
