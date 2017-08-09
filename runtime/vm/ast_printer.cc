// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast_printer.h"

#include "vm/handles.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/parser.h"

#if !defined(PRODUCT)

namespace dart {

AstPrinter::AstPrinter(bool log)
    : indent_(0), logger_(log ? Log::Current() : Log::NoOpLog()) {}

AstPrinter::~AstPrinter() {}

void AstPrinter::VisitGenericAstNode(AstNode* node) {
  logger_->Print("(%s ", node->Name());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitSequenceNode(SequenceNode* node) {
  indent_++;
  LocalScope* scope = node->scope();
  logger_->Print("(%s (scope \"%p\"", node->Name(), scope);
  if (scope != NULL) {
    logger_->Print(" (%s-%s) loop %d", scope->begin_token_pos().ToCString(),
                   scope->end_token_pos().ToCString(), scope->loop_level());
    if (scope->HasContextLevel()) {
      logger_->Print(" context %d captures %d", scope->context_level(),
                     scope->num_context_variables());
    } else {
      ASSERT(scope->num_context_variables() == 0);
    }
  }
  logger_->Print(")");
  for (int i = 0; i < node->length(); ++i) {
    PrintNewlineAndIndent();
    node->NodeAt(i)->Visit(this);
  }
  logger_->Print(")");
  indent_--;
}

void AstPrinter::VisitCloneContextNode(CloneContextNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitArgumentListNode(ArgumentListNode* arguments) {
  VisitGenericAstNode(arguments);
}

void AstPrinter::VisitReturnNode(ReturnNode* node) {
  const char* kind;
  switch (node->return_type()) {
    case ReturnNode::kContinuation:
      kind = "continuation ";
      break;
    case ReturnNode::kContinuationTarget:
      kind = "continuation-target ";
      break;
    case ReturnNode::kRegular:
      kind = "";
      break;
    default:
      kind = "";
      UNREACHABLE();
  }
  logger_->Print("(%s %s", node->Name(), kind);
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitGenericLocalNode(AstNode* node,
                                       const LocalVariable& variable) {
  logger_->Print("(%s ", node->Name());
  PrintLocalVariable(&variable);
  logger_->Print(" ");
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitLoadLocalNode(LoadLocalNode* node) {
  VisitGenericLocalNode(node, node->local());
}

void AstPrinter::VisitStoreLocalNode(StoreLocalNode* node) {
  VisitGenericLocalNode(node, node->local());
}

void AstPrinter::VisitGenericFieldNode(AstNode* node, const Field& field) {
  logger_->Print(
      "(%s %s%s \"%s\" ", node->Name(), field.is_final() ? "final " : "",
      String::Handle(AbstractType::Handle(field.type()).Name()).ToCString(),
      String::Handle(field.name()).ToCString());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitLoadInstanceFieldNode(LoadInstanceFieldNode* node) {
  VisitGenericFieldNode(node, node->field());
}

void AstPrinter::VisitStoreInstanceFieldNode(StoreInstanceFieldNode* node) {
  VisitGenericFieldNode(node, Field::ZoneHandle(node->field().Original()));
}

void AstPrinter::VisitLoadStaticFieldNode(LoadStaticFieldNode* node) {
  VisitGenericFieldNode(node, node->field());
}

void AstPrinter::VisitStoreStaticFieldNode(StoreStaticFieldNode* node) {
  VisitGenericFieldNode(node, node->field());
}

void AstPrinter::PrintLocalVariable(const LocalVariable* variable) {
  logger_->Print("%s%s \"%s\"", variable->is_final() ? "final " : "",
                 String::Handle(variable->type().Name()).ToCString(),
                 variable->name().ToCString());
  if (variable->HasIndex()) {
    if (variable->is_captured()) {
      logger_->Print(" (context %d %d)", variable->owner()->context_level(),
                     variable->index());
    } else {
      logger_->Print(" (stack %d)", variable->index());
    }
  }
}

void AstPrinter::PrintNewlineAndIndent() {
  logger_->Print("\n");
  for (intptr_t p = 0; p < indent_; ++p) {
    logger_->Print("  ");
  }
}

void AstPrinter::VisitLetNode(LetNode* node) {
  logger_->Print("(Let (");
  // Indent the variables and initializers by two.
  indent_ += 2;
  for (intptr_t i = 0; i < node->num_temps(); ++i) {
    if (i != 0) PrintNewlineAndIndent();
    logger_->Print("(");
    PrintLocalVariable(node->TempAt(i));
    logger_->Print(" ");
    node->InitializerAt(i)->Visit(this);
    logger_->Print(")");
  }
  logger_->Print(")");

  // Indent the body nodes by one.
  --indent_;
  for (intptr_t i = 0; i < node->nodes().length(); ++i) {
    PrintNewlineAndIndent();
    node->nodes()[i]->Visit(this);
  }
  logger_->Print(")");
  --indent_;
}

void AstPrinter::VisitArrayNode(ArrayNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitStringInterpolateNode(StringInterpolateNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitLiteralNode(LiteralNode* node) {
  const Instance& literal = node->literal();
  logger_->Print("(%s \"%s\")", node->Name(), literal.ToCString());
}

void AstPrinter::VisitTypeNode(TypeNode* node) {
  const AbstractType& type = node->type();
  logger_->Print("(%s \"%s\")", node->Name(),
                 String::Handle(type.Name()).ToCString());
}

void AstPrinter::VisitAssignableNode(AssignableNode* node) {
  const AbstractType& type = node->type();
  const String& dst_name = node->dst_name();
  logger_->Print("(%s (type \"%s\") (of \"%s\") ", node->Name(),
                 String::Handle(type.Name()).ToCString(), dst_name.ToCString());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitAwaitNode(AwaitNode* node) {
  logger_->Print("(*****%s***** (scope \"%p\") ", node->Name(), node->scope());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitAwaitMarkerNode(AwaitMarkerNode* node) {
  logger_->Print("(%s (async_scope \"%p\" await_scope \"%p\"))", node->Name(),
                 node->async_scope(), node->await_scope());
}

void AstPrinter::VisitPrimaryNode(PrimaryNode* node) {
  logger_->Print("(*****%s***** \"%s\")", node->Name(),
                 node->primary().ToCString());
}

void AstPrinter::VisitComparisonNode(ComparisonNode* node) {
  logger_->Print("(%s %s ", node->Name(), node->TokenName());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitBinaryOpNode(BinaryOpNode* node) {
  logger_->Print("(%s %s ", node->Name(), node->TokenName());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitUnaryOpNode(UnaryOpNode* node) {
  logger_->Print("(%s %s ", node->Name(), node->TokenName());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitConditionalExprNode(ConditionalExprNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitIfNode(IfNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitCaseNode(CaseNode* node) {
  logger_->Print("(%s (", node->Name());
  for (int i = 0; i < node->case_expressions()->length(); i++) {
    node->case_expressions()->NodeAt(i)->Visit(this);
  }
  if (node->contains_default()) {
    logger_->Print(" default");
  }
  logger_->Print(")");
  node->statements()->Visit(this);
  logger_->Print(")");
}

void AstPrinter::VisitSwitchNode(SwitchNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitWhileNode(WhileNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitForNode(ForNode* node) {
  // Complicated because the condition is optional and so we clearly want to
  // indicate the subparts.
  logger_->Print("(%s (init ", node->Name());
  node->initializer()->Visit(this);
  if (node->condition() != NULL) {
    logger_->Print(") (cond ");
    node->condition()->Visit(this);
  }
  logger_->Print(") (update ");
  node->increment()->Visit(this);
  logger_->Print(") ");
  node->body()->Visit(this);
  logger_->Print(")");
}

void AstPrinter::VisitDoWhileNode(DoWhileNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitJumpNode(JumpNode* node) {
  logger_->Print("(%s %s %s (scope \"%p\"))", node->Name(), node->TokenName(),
                 node->label()->name().ToCString(), node->label()->owner());
}

void AstPrinter::VisitInstanceCallNode(InstanceCallNode* node) {
  logger_->Print("(%s \"%s\" ", node->Name(),
                 node->function_name().ToCString());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitStaticCallNode(StaticCallNode* node) {
  const char* function_fullname = node->function().ToFullyQualifiedCString();
  logger_->Print("(%s \"%s\" ", node->Name(), function_fullname);
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitClosureNode(ClosureNode* node) {
  const char* function_fullname = node->function().ToFullyQualifiedCString();
  logger_->Print("(%s \"%s\")", node->Name(), function_fullname);
}

void AstPrinter::VisitClosureCallNode(ClosureCallNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitConstructorCallNode(ConstructorCallNode* node) {
  const char* kind = node->constructor().IsFactory() ? "factory " : "";
  const char* constructor_name = node->constructor().ToFullyQualifiedCString();
  logger_->Print("(%s %s \"%s\" ", node->Name(), kind, constructor_name);
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitInstanceGetterNode(InstanceGetterNode* node) {
  logger_->Print("(%s \"%s\" ", node->Name(), node->field_name().ToCString());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitInstanceSetterNode(InstanceSetterNode* node) {
  logger_->Print("(%s \"%s\" ", node->Name(), node->field_name().ToCString());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitInitStaticFieldNode(InitStaticFieldNode* node) {
  logger_->Print("(%s \"%s\")", node->Name(),
                 String::Handle(node->field().name()).ToCString());
}

void AstPrinter::VisitStaticGetterNode(StaticGetterNode* node) {
  String& class_name = String::Handle(node->cls().Name());
  logger_->Print("(%s \"%s.%s\")", node->Name(), class_name.ToCString(),
                 node->field_name().ToCString());
}

void AstPrinter::VisitStaticSetterNode(StaticSetterNode* node) {
  String& class_name = String::Handle(node->cls().Name());
  logger_->Print("(%s \"%s.%s\" ", node->Name(), class_name.ToCString(),
                 node->field_name().ToCString());
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitLoadIndexedNode(LoadIndexedNode* node) {
  logger_->Print("(%s%s ", node->Name(), node->IsSuperLoad() ? " super" : "");
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitStoreIndexedNode(StoreIndexedNode* node) {
  logger_->Print("(%s%s ", node->Name(), node->IsSuperStore() ? " super" : "");
  node->VisitChildren(this);
  logger_->Print(")");
}

void AstPrinter::VisitNativeBodyNode(NativeBodyNode* node) {
  logger_->Print(
      "(%s \"%s\" (%" Pd " args))", node->Name(),
      node->native_c_function_name().ToCString(),
      NativeArguments::ParameterCountForResolution(node->function()));
}

void AstPrinter::VisitCatchClauseNode(CatchClauseNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitTryCatchNode(TryCatchNode* node) {
  logger_->Print("(%s ", node->Name());
  node->try_block()->Visit(this);
  node->catch_block()->Visit(this);
  if (node->finally_block() != NULL) {
    logger_->Print("(finally ");
    node->finally_block()->Visit(this);
    logger_->Print(")");
  }
  logger_->Print(")");
}

void AstPrinter::VisitThrowNode(ThrowNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::VisitStopNode(StopNode* node) {
  logger_->Print("(%s %s)", node->Name(), node->message());
}

void AstPrinter::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  VisitGenericAstNode(node);
}

void AstPrinter::PrintNode(AstNode* node) {
  ASSERT(node != NULL);
  AstPrinter ast_printer;
  node->Visit(&ast_printer);
  logger_->Print("\n");
}

void AstPrinter::IndentN(int count) {
  for (int i = 0; i < count; i++) {
    logger_->Print(" ");
  }
}

void AstPrinter::PrintLocalScopeVariable(const LocalScope* scope,
                                         LocalVariable* var,
                                         int indent) {
  ASSERT(scope != NULL);
  ASSERT(var != NULL);
  IndentN(indent);
  logger_->Print("(%s%s '%s'", var->is_final() ? "final " : "",
                 String::Handle(var->type().Name()).ToCString(),
                 var->name().ToCString());
  if (var->owner() != scope) {
    logger_->Print(" alias");
  }
  if (var->HasIndex()) {
    logger_->Print(" @%d", var->index());
    if (var->is_captured()) {
      logger_->Print(" ctx %d", var->owner()->context_level());
    }
  } else if (var->owner()->function_level() != 0) {
    logger_->Print(" lev %d", var->owner()->function_level());
  }
  logger_->Print(" valid %s-%s)\n", var->token_pos().ToCString(),
                 scope->end_token_pos().ToCString());
}

void AstPrinter::PrintLocalScope(const LocalScope* scope,
                                 int start_index,
                                 int indent) {
  ASSERT(scope != NULL);
  for (int i = start_index; i < scope->num_variables(); i++) {
    LocalVariable* var = scope->VariableAt(i);
    PrintLocalScopeVariable(scope, var, indent);
  }
  const LocalScope* child = scope->child();
  while (child != NULL) {
    IndentN(indent);
    logger_->Print("{scope %p ", child);
    if (child->HasContextLevel()) {
      logger_->Print("ctx %d numctxvar %d ", child->context_level(),
                     child->num_context_variables());
    }
    logger_->Print("llev %d\n", child->loop_level());
    PrintLocalScope(child, 0, indent + kScopeIndent);
    IndentN(indent);
    logger_->Print("}\n");
    child = child->sibling();
  }
}

void AstPrinter::PrintFunctionScope(const ParsedFunction& parsed_function) {
  HANDLESCOPE(parsed_function.thread());
  const Function& function = parsed_function.function();
  SequenceNode* node_sequence = parsed_function.node_sequence();
  ASSERT(node_sequence != NULL);
  const LocalScope* scope = node_sequence->scope();
  ASSERT(scope != NULL);
  const char* function_name = function.ToFullyQualifiedCString();
  logger_->Print("Scope for function '%s'\n{scope %p ", function_name, scope);
  if (scope->HasContextLevel()) {
    logger_->Print("ctx %d numctxvar %d ", scope->context_level(),
                   scope->num_context_variables());
  }
  logger_->Print("llev %d\n", scope->loop_level());
  const int num_fixed_params = function.num_fixed_parameters();
  const int num_params = num_fixed_params + function.NumOptionalParameters();
  // Parameters must be listed first and must all appear in the top scope.
  ASSERT(num_params <= scope->num_variables());
  int pos = 0;  // Current position of variable in scope.
  int indent = kScopeIndent;
  while (pos < num_params) {
    LocalVariable* param = scope->VariableAt(pos);
    ASSERT(param->owner() == scope);  // No aliases should precede parameters.
    IndentN(indent);
    logger_->Print("(param %s%s '%s'", param->is_final() ? "final " : "",
                   String::Handle(param->type().Name()).ToCString(),
                   param->name().ToCString());
    // Print the default value if the parameter is optional.
    if (pos >= num_fixed_params && pos < num_params) {
      const Instance& default_parameter_value =
          parsed_function.DefaultParameterValueAt(pos - num_fixed_params);
      logger_->Print(" =%s", default_parameter_value.ToCString());
    }
    if (param->HasIndex()) {
      logger_->Print(" @%d", param->index());
      if (param->is_captured()) {
        logger_->Print(" ctx %d", param->owner()->context_level());
      }
    }
    logger_->Print(" valid %s-%s)\n", param->token_pos().ToCString(),
                   scope->end_token_pos().ToCString());
    pos++;
  }
  // Visit remaining non-parameter variables and children scopes.
  PrintLocalScope(scope, pos, indent);
  logger_->Print("}\n");
}

void AstPrinter::PrintFunctionNodes(const ParsedFunction& parsed_function) {
  HANDLESCOPE(parsed_function.thread());
  SequenceNode* node_sequence = parsed_function.node_sequence();
  ASSERT(node_sequence != NULL);
  const char* function_name =
      parsed_function.function().ToFullyQualifiedCString();
  logger_->Print("Ast for function '%s' {\n", function_name);
  node_sequence->Visit(this);
  logger_->Print("}\n");
}

}  // namespace dart

#endif  // !defined(PRODUCT)
