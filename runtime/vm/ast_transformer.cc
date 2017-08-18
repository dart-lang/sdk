// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast_transformer.h"

#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/thread.h"

namespace dart {

// Quick access to the current thread.
#define T (thread())

// Quick access to the current zone.
#define Z (thread()->zone())

// Quick synthetic token position.
#define ST(token_pos) ((token_pos).ToSynthetic())

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
  V(Stop)                                                                      \
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
  void AwaitTransformer::Visit##BaseName##Node(BaseName##Node* node) {         \
    UNREACHABLE();                                                             \
  }

FOR_EACH_UNREACHABLE_NODE(DEFINE_UNREACHABLE)
#undef DEFINE_UNREACHABLE

AwaitTransformer::AwaitTransformer(SequenceNode* preamble,
                                   LocalScope* async_temp_scope)
    : preamble_(preamble),
      temp_cnt_(0),
      async_temp_scope_(async_temp_scope),
      thread_(Thread::Current()) {
  ASSERT(async_temp_scope_ != NULL);
}

AstNode* AwaitTransformer::Transform(AstNode* expr) {
  expr->Visit(this);
  return result_;
}

LocalVariable* AwaitTransformer::EnsureCurrentTempVar() {
  String& symbol =
      String::ZoneHandle(Z, Symbols::NewFormatted(T, "%d", temp_cnt_));
  symbol = Symbols::FromConcat(T, Symbols::AwaitTempVarPrefix(), symbol);
  ASSERT(!symbol.IsNull());
  // Look up the variable in the scope used for async temp variables.
  LocalVariable* await_tmp = async_temp_scope_->LocalLookupVariable(symbol);
  if (await_tmp == NULL) {
    // We need a new temp variable; add it to the function's top scope.
    await_tmp = new (Z)
        LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                      symbol, Object::dynamic_type());
    async_temp_scope_->AddVariable(await_tmp);
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

LocalVariable* AwaitTransformer::AddNewTempVarToPreamble(
    AstNode* node,
    TokenPosition token_pos) {
  LocalVariable* tmp_var = EnsureCurrentTempVar();
  ASSERT(token_pos.IsSynthetic() || token_pos.IsNoSource());
  preamble_->Add(new (Z) StoreLocalNode(token_pos, tmp_var, node));
  NextTempVar();
  return tmp_var;
}

LoadLocalNode* AwaitTransformer::MakeName(AstNode* node) {
  LocalVariable* temp = AddNewTempVarToPreamble(node, ST(node->token_pos()));
  return new (Z) LoadLocalNode(ST(node->token_pos()), temp);
}

void AwaitTransformer::VisitLiteralNode(LiteralNode* node) {
  result_ = node;
}

void AwaitTransformer::VisitTypeNode(TypeNode* node) {
  if (node->is_deferred_reference()) {
    // Deferred references must use a temporary even after loading
    // happened, so that the number of await temps is the same as
    // before the loading.
    result_ = MakeName(node);
  } else {
    result_ = node;
  }
}

void AwaitTransformer::VisitAwaitNode(AwaitNode* node) {
  // Await transformation:
  //
  //   :await_temp_var_X = <expr>;
  //   AwaitMarker(kNewContinuationState);
  //   :result_param = _awaitHelper(
  //      :await_temp_var_X,
  //      :async_then_callback,
  //      :async_catch_error_callback,
  //      :async_op);
  //   return;  // (return_type() == kContinuationTarget)
  //
  //   :saved_try_ctx_var = :await_saved_try_ctx_var_y;
  //   :await_temp_var_(X+1) = :result_param;

  const TokenPosition token_pos = ST(node->token_pos());
  LocalVariable* async_op =
      GetVariableInScope(preamble_->scope(), Symbols::AsyncOperation());
  LocalVariable* async_then_callback =
      GetVariableInScope(preamble_->scope(), Symbols::AsyncThenCallback());
  LocalVariable* async_catch_error_callback = GetVariableInScope(
      preamble_->scope(), Symbols::AsyncCatchErrorCallback());
  LocalVariable* result_param =
      GetVariableInScope(preamble_->scope(), Symbols::AsyncOperationParam());
  LocalVariable* error_param = GetVariableInScope(
      preamble_->scope(), Symbols::AsyncOperationErrorParam());
  LocalVariable* stack_trace_param = GetVariableInScope(
      preamble_->scope(), Symbols::AsyncOperationStackTraceParam());

  AstNode* transformed_expr = Transform(node->expr());
  LocalVariable* await_temp =
      AddNewTempVarToPreamble(transformed_expr, ST(node->token_pos()));

  AwaitMarkerNode* await_marker =
      new (Z) AwaitMarkerNode(async_temp_scope_, node->scope(), token_pos);
  preamble_->Add(await_marker);

  // :result_param = _awaitHelper(
  //      :await_temp,
  //      :async_then_callback,
  //      :async_catch_error_callback,
  //      :async_op)
  const Library& async_lib = Library::Handle(Library::AsyncLibrary());
  const Function& async_await_helper = Function::ZoneHandle(
      Z, async_lib.LookupFunctionAllowPrivate(Symbols::AsyncAwaitHelper()));
  ASSERT(!async_await_helper.IsNull());
  ArgumentListNode* async_await_helper_args =
      new (Z) ArgumentListNode(token_pos);
  async_await_helper_args->Add(new (Z) LoadLocalNode(token_pos, await_temp));
  async_await_helper_args->Add(
      new (Z) LoadLocalNode(token_pos, async_then_callback));
  async_await_helper_args->Add(
      new (Z) LoadLocalNode(token_pos, async_catch_error_callback));
  async_await_helper_args->Add(new (Z) LoadLocalNode(token_pos, async_op));
  StaticCallNode* await_helper_call = new (Z) StaticCallNode(
      node->token_pos(), async_await_helper, async_await_helper_args);

  preamble_->Add(
      new (Z) StoreLocalNode(token_pos, result_param, await_helper_call));

  ReturnNode* continuation_return = new (Z) ReturnNode(token_pos);
  continuation_return->set_return_type(ReturnNode::kContinuationTarget);
  preamble_->Add(continuation_return);

  // If this expression is part of a try block, also append the code for
  // restoring the saved try context that lives on the stack and possibly the
  // saved try context of the outer try block.
  if (node->saved_try_ctx() != NULL) {
    preamble_->Add(new (Z) StoreLocalNode(
        token_pos, node->saved_try_ctx(),
        new (Z) LoadLocalNode(token_pos, node->async_saved_try_ctx())));
    if (node->outer_saved_try_ctx() != NULL) {
      preamble_->Add(new (Z) StoreLocalNode(
          token_pos, node->outer_saved_try_ctx(),
          new (Z) LoadLocalNode(token_pos, node->outer_async_saved_try_ctx())));
    }
  } else {
    ASSERT(node->outer_saved_try_ctx() == NULL);
  }

  // Load the async_op variable. It is unused, but the observatory uses it
  // to determine if a breakpoint is inside an asynchronous function.
  LoadLocalNode* load_async_op = new (Z) LoadLocalNode(token_pos, async_op);
  preamble_->Add(load_async_op);

  LoadLocalNode* load_error_param =
      new (Z) LoadLocalNode(token_pos, error_param);
  LoadLocalNode* load_stack_trace_param =
      new (Z) LoadLocalNode(token_pos, stack_trace_param);
  SequenceNode* error_ne_null_branch =
      new (Z) SequenceNode(token_pos, ChainNewScope(preamble_->scope()));
  error_ne_null_branch->Add(
      new (Z) ThrowNode(token_pos, load_error_param, load_stack_trace_param));
  preamble_->Add(new (Z) IfNode(
      token_pos,
      new (Z) ComparisonNode(
          token_pos, Token::kNE, load_error_param,
          new (Z) LiteralNode(token_pos, Object::null_instance())),
      error_ne_null_branch, NULL));

  result_ = MakeName(new (Z) LoadLocalNode(token_pos, result_param));
}

// Transforms boolean expressions into a sequence of evaluations that only
// lazily evaluate subexpressions.
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
  const Token::Kind compare_logical_op =
      (logical_op == Token::kAND) ? Token::kEQ : Token::kNE;
  SequenceNode* eval = new (Z) SequenceNode(ST(new_left->token_pos()),
                                            ChainNewScope(preamble_->scope()));
  SequenceNode* saved_preamble = preamble_;
  preamble_ = eval;
  result = Transform(right);
  preamble_ = saved_preamble;
  IfNode* right_body = new (Z)
      IfNode(ST(new_left->token_pos()),
             new (Z) ComparisonNode(
                 ST(new_left->token_pos()), compare_logical_op, new_left,
                 new (Z) LiteralNode(ST(new_left->token_pos()), Bool::True())),
             eval, NULL);
  preamble_->Add(right_body);
  return result;
}

LocalScope* AwaitTransformer::ChainNewScope(LocalScope* parent) {
  return new (Z)
      LocalScope(parent, parent->function_level(), parent->loop_level());
}

void AwaitTransformer::VisitBinaryOpNode(BinaryOpNode* node) {
  AstNode* new_left = Transform(node->left());
  AstNode* new_right = NULL;
  // Preserve lazy evaluation.
  if ((node->kind() == Token::kAND) || (node->kind() == Token::kOR)) {
    new_right = LazyTransform(node->kind(), new_left, node->right());
  } else {
    new_right = Transform(node->right());
  }
  result_ = MakeName(new (Z) BinaryOpNode(node->token_pos(), node->kind(),
                                          new_left, new_right));
}

void AwaitTransformer::VisitComparisonNode(ComparisonNode* node) {
  AstNode* new_left = Transform(node->left());
  AstNode* new_right = Transform(node->right());
  result_ = MakeName(new (Z) ComparisonNode(node->token_pos(), node->kind(),
                                            new_left, new_right));
}

void AwaitTransformer::VisitUnaryOpNode(UnaryOpNode* node) {
  AstNode* new_operand = Transform(node->operand());
  result_ = MakeName(
      new (Z) UnaryOpNode(node->token_pos(), node->kind(), new_operand));
}

// ::= (<condition>) ? <true-branch> : <false-branch>
//
void AwaitTransformer::VisitConditionalExprNode(ConditionalExprNode* node) {
  AstNode* new_condition = Transform(node->condition());
  SequenceNode* new_true = new (Z) SequenceNode(
      ST(node->true_expr()->token_pos()), ChainNewScope(preamble_->scope()));
  SequenceNode* saved_preamble = preamble_;
  preamble_ = new_true;
  AstNode* new_true_result = Transform(node->true_expr());
  SequenceNode* new_false = new (Z) SequenceNode(
      ST(node->false_expr()->token_pos()), ChainNewScope(preamble_->scope()));
  preamble_ = new_false;
  AstNode* new_false_result = Transform(node->false_expr());
  preamble_ = saved_preamble;
  IfNode* new_if =
      new (Z) IfNode(ST(node->token_pos()), new_condition, new_true, new_false);
  preamble_->Add(new_if);
  result_ = MakeName(new (Z) ConditionalExprNode(
      ST(node->token_pos()), new_condition, new_true_result, new_false_result));
}

void AwaitTransformer::VisitArgumentListNode(ArgumentListNode* node) {
  ArgumentListNode* new_args =
      new (Z) ArgumentListNode(node->token_pos(), node->type_arguments());
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
  result_ = new (Z) ArrayNode(node->token_pos(), node->type(), new_elements);
}

void AwaitTransformer::VisitStringInterpolateNode(StringInterpolateNode* node) {
  ArrayNode* new_value = Transform(node->value())->AsArrayNode();
  result_ =
      MakeName(new (Z) StringInterpolateNode(node->token_pos(), new_value));
}

void AwaitTransformer::VisitClosureNode(ClosureNode* node) {
  AstNode* new_receiver = node->receiver();
  if (new_receiver != NULL) {
    new_receiver = Transform(new_receiver);
  }
  result_ = MakeName(new (Z) ClosureNode(node->token_pos(), node->function(),
                                         new_receiver, node->scope()));
}

void AwaitTransformer::VisitInstanceCallNode(InstanceCallNode* node) {
  AstNode* new_receiver = Transform(node->receiver());
  ArgumentListNode* new_args =
      Transform(node->arguments())->AsArgumentListNode();
  result_ = MakeName(new (Z) InstanceCallNode(node->token_pos(), new_receiver,
                                              node->function_name(), new_args,
                                              node->is_conditional()));
}

void AwaitTransformer::VisitStaticCallNode(StaticCallNode* node) {
  ArgumentListNode* new_args =
      Transform(node->arguments())->AsArgumentListNode();
  result_ = MakeName(
      new (Z) StaticCallNode(node->token_pos(), node->function(), new_args));
}

void AwaitTransformer::VisitConstructorCallNode(ConstructorCallNode* node) {
  ArgumentListNode* new_args =
      Transform(node->arguments())->AsArgumentListNode();
  result_ = MakeName(
      new (Z) ConstructorCallNode(node->token_pos(), node->type_arguments(),
                                  node->constructor(), new_args));
}

void AwaitTransformer::VisitInstanceGetterNode(InstanceGetterNode* node) {
  AstNode* new_receiver = Transform(node->receiver());
  result_ = MakeName(new (Z) InstanceGetterNode(node->token_pos(), new_receiver,
                                                node->field_name(),
                                                node->is_conditional()));
}

void AwaitTransformer::VisitInstanceSetterNode(InstanceSetterNode* node) {
  AstNode* new_receiver = node->receiver();
  if (new_receiver != NULL) {
    new_receiver = Transform(new_receiver);
  }
  AstNode* new_value = Transform(node->value());
  result_ = MakeName(new (Z) InstanceSetterNode(node->token_pos(), new_receiver,
                                                node->field_name(), new_value,
                                                node->is_conditional()));
}

void AwaitTransformer::VisitStaticGetterNode(StaticGetterNode* node) {
  AstNode* new_receiver = node->receiver();
  if (new_receiver != NULL) {
    new_receiver = Transform(new_receiver);
  }
  StaticGetterNode* new_getter = new (Z) StaticGetterNode(
      node->token_pos(), new_receiver, node->cls(), node->field_name());
  new_getter->set_owner(node->owner());
  result_ = MakeName(new_getter);
}

void AwaitTransformer::VisitStaticSetterNode(StaticSetterNode* node) {
  AstNode* new_receiver = node->receiver();
  if (new_receiver != NULL) {
    new_receiver = Transform(new_receiver);
  }
  AstNode* new_value = Transform(node->value());
  StaticSetterNode* new_setter =
      node->function().IsNull()
          ? new (Z) StaticSetterNode(node->token_pos(), new_receiver,
                                     node->cls(), node->field_name(), new_value)
          : new (Z) StaticSetterNode(node->token_pos(), new_receiver,
                                     node->field_name(), node->function(),
                                     new_value);

  result_ = MakeName(new_setter);
}

void AwaitTransformer::VisitLoadLocalNode(LoadLocalNode* node) {
  result_ = MakeName(node);
}

void AwaitTransformer::VisitStoreLocalNode(StoreLocalNode* node) {
  AstNode* new_value = Transform(node->value());
  result_ = MakeName(
      new (Z) StoreLocalNode(node->token_pos(), &node->local(), new_value));
}

void AwaitTransformer::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  result_ = MakeName(node);
}

void AwaitTransformer::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  AstNode* new_value = Transform(node->value());
  result_ = MakeName(new (Z) StoreStaticFieldNode(
      node->token_pos(), Field::ZoneHandle(Z, node->field().Original()),
      new_value));
}

void AwaitTransformer::VisitLoadIndexedNode(LoadIndexedNode* node) {
  AstNode* new_array = Transform(node->array());
  AstNode* new_index = Transform(node->index_expr());
  result_ = MakeName(new (Z) LoadIndexedNode(node->token_pos(), new_array,
                                             new_index, node->super_class()));
}

void AwaitTransformer::VisitStoreIndexedNode(StoreIndexedNode* node) {
  AstNode* new_array = Transform(node->array());
  AstNode* new_index = Transform(node->index_expr());
  AstNode* new_value = Transform(node->value());
  result_ = MakeName(new (Z) StoreIndexedNode(
      node->token_pos(), new_array, new_index, new_value, node->super_class()));
}

void AwaitTransformer::VisitAssignableNode(AssignableNode* node) {
  AstNode* new_expr = Transform(node->expr());
  result_ = MakeName(new (Z) AssignableNode(node->token_pos(), new_expr,
                                            node->type(), node->dst_name()));
}

void AwaitTransformer::VisitLetNode(LetNode* node) {
  // Add all the initializer nodes to the preamble and the
  // temporary variables to the scope for async temporary variables.
  // The temporary variables will be captured as a side effect of being
  // added to a scope, and the subsequent nodes that are added to the
  // preample can access them.
  for (intptr_t i = 0; i < node->num_temps(); i++) {
    async_temp_scope_->AddVariable(node->TempAt(i));
    AstNode* new_init_val = Transform(node->InitializerAt(i));
    preamble_->Add(new (Z) StoreLocalNode(node->token_pos(), node->TempAt(i),
                                          new_init_val));
  }

  // Add all expressions but the last to the preamble. We must do
  // this because subexpressions of the awaitable expression we
  // are currently transforming may depend on each other,
  // e.g. await foo(a++, a++). Thus we must preserve the order of the
  // transformed subexpressions.
  for (intptr_t i = 0; i < node->nodes().length() - 1; i++) {
    preamble_->Add(Transform(node->nodes()[i]));
  }

  // The last expression in the let node is the value of the node.
  // The result of the transformed let node is this expression.
  ASSERT(node->nodes().length() > 0);
  const intptr_t last_node_index = node->nodes().length() - 1;
  result_ = Transform(node->nodes()[last_node_index]);
}

void AwaitTransformer::VisitThrowNode(ThrowNode* node) {
  AstNode* new_exception = Transform(node->exception());
  result_ = MakeName(
      new (Z) ThrowNode(node->token_pos(), new_exception, node->stacktrace()));
}

}  // namespace dart
