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

AstPrinter::AstPrinter() : indent_(0) { }


AstPrinter::~AstPrinter() { }


void AstPrinter::VisitGenericAstNode(AstNode* node) {
  THR_Print("(%s ", node->Name());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitSequenceNode(SequenceNode* node) {
  indent_++;
  LocalScope* scope = node->scope();
  THR_Print("(%s (scope \"%p\"", node->Name(), scope);
  if (scope != NULL) {
    THR_Print(" (%s-%s) loop %d",
              scope->begin_token_pos().ToCString(),
              scope->end_token_pos().ToCString(),
              scope->loop_level());
    if (scope->HasContextLevel()) {
      THR_Print(" context %d captures %d",
                scope->context_level(),
                scope->num_context_variables());
    } else {
      ASSERT(scope->num_context_variables() == 0);
    }
  }
  THR_Print(")");
  for (int i = 0; i < node->length(); ++i) {
    THR_Print("\n");
    for (intptr_t p = 0; p < indent_; p++) {
      THR_Print("  ");
    }
    node->NodeAt(i)->Visit(this);
  }
  THR_Print(")");
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
  THR_Print("(%s %s", node->Name(), kind);
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitGenericLocalNode(AstNode* node,
                                       const LocalVariable& var) {
  THR_Print("(%s %s%s \"%s\"",
            node->Name(),
            var.is_final() ? "final " : "",
            String::Handle(var.type().Name()).ToCString(),
            var.name().ToCString());
  if (var.HasIndex()) {
    if (var.is_captured()) {
      THR_Print(" (context %d %d)", var.owner()->context_level(), var.index());
    } else {
      THR_Print(" (stack %d)", var.index());
    }
  }
  THR_Print(" ");
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitLoadLocalNode(LoadLocalNode* node) {
  VisitGenericLocalNode(node, node->local());
}


void AstPrinter::VisitStoreLocalNode(StoreLocalNode* node) {
  VisitGenericLocalNode(node, node->local());
}


void AstPrinter::VisitGenericFieldNode(AstNode* node, const Field& field) {
  THR_Print("(%s %s%s \"%s\" ",
            node->Name(),
            field.is_final() ? "final " : "",
            String::Handle(AbstractType::Handle(field.type()).Name()).
                ToCString(),
            String::Handle(field.name()).ToCString());
  node->VisitChildren(this);
  THR_Print(")");
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


void AstPrinter::VisitLetNode(LetNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitArrayNode(ArrayNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitStringInterpolateNode(StringInterpolateNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitLiteralNode(LiteralNode* node) {
  const Instance& literal = node->literal();
  THR_Print("(%s \"%s\")", node->Name(), literal.ToCString());
}


void AstPrinter::VisitTypeNode(TypeNode* node) {
  const AbstractType& type = node->type();
  THR_Print("(%s \"%s\")",
            node->Name(),
            String::Handle(type.Name()).ToCString());
}


void AstPrinter::VisitAssignableNode(AssignableNode* node) {
  const AbstractType& type = node->type();
  const String& dst_name = node->dst_name();
  THR_Print("(%s (type \"%s\") (of \"%s\") ",
            node->Name(),
            String::Handle(type.Name()).ToCString(),
            dst_name.ToCString());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitAwaitNode(AwaitNode* node) {
  THR_Print("(*****%s***** (scope \"%p\") ", node->Name(), node->scope());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitAwaitMarkerNode(AwaitMarkerNode* node) {
  THR_Print("(%s (async_scope \"%p\" await_scope \"%p\"))",
            node->Name(),
            node->async_scope(),
            node->await_scope());
}


void AstPrinter::VisitPrimaryNode(PrimaryNode* node) {
  THR_Print("(*****%s***** \"%s\")",
            node->Name(),
            node->primary().ToCString());
}


void AstPrinter::VisitComparisonNode(ComparisonNode* node) {
  THR_Print("(%s %s ", node->Name(), node->TokenName());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitBinaryOpNode(BinaryOpNode* node) {
  THR_Print("(%s %s ", node->Name(), node->TokenName());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitUnaryOpNode(UnaryOpNode* node) {
  THR_Print("(%s %s ", node->Name(), node->TokenName());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitConditionalExprNode(ConditionalExprNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitIfNode(IfNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitCaseNode(CaseNode* node) {
  THR_Print("(%s (", node->Name());
  for (int i = 0; i < node->case_expressions()->length(); i++) {
    node->case_expressions()->NodeAt(i)->Visit(this);
  }
  if (node->contains_default()) {
    THR_Print(" default");
  }
  THR_Print(")");
  node->statements()->Visit(this);
  THR_Print(")");
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
  THR_Print("(%s (init ", node->Name());
  node->initializer()->Visit(this);
  if (node->condition() != NULL) {
    THR_Print(") (cond ");
    node->condition()->Visit(this);
  }
  THR_Print(") (update ");
  node->increment()->Visit(this);
  THR_Print(") ");
  node->body()->Visit(this);
  THR_Print(")");
}


void AstPrinter::VisitDoWhileNode(DoWhileNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitJumpNode(JumpNode* node) {
  THR_Print("(%s %s %s (scope \"%p\"))",
            node->Name(),
            node->TokenName(),
            node->label()->name().ToCString(),
            node->label()->owner());
}


void AstPrinter::VisitInstanceCallNode(InstanceCallNode* node) {
  THR_Print("(%s \"%s\" ",
            node->Name(),
            node->function_name().ToCString());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitStaticCallNode(StaticCallNode* node) {
  const char* function_fullname = node->function().ToFullyQualifiedCString();
  THR_Print("(%s \"%s\" ", node->Name(), function_fullname);
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitClosureNode(ClosureNode* node) {
  const char* function_fullname = node->function().ToFullyQualifiedCString();
  THR_Print("(%s \"%s\")", node->Name(), function_fullname);
}


void AstPrinter::VisitClosureCallNode(ClosureCallNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitConstructorCallNode(ConstructorCallNode* node) {
  const char* kind = node->constructor().IsFactory() ? "factory " : "";
  const char* constructor_name = node->constructor().ToFullyQualifiedCString();
  THR_Print("(%s %s \"%s\" ", node->Name(), kind, constructor_name);
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitInstanceGetterNode(InstanceGetterNode* node) {
  THR_Print("(%s \"%s\" ", node->Name(), node->field_name().ToCString());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitInstanceSetterNode(InstanceSetterNode* node) {
  THR_Print("(%s \"%s\" ", node->Name(), node->field_name().ToCString());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitInitStaticFieldNode(InitStaticFieldNode* node) {
  THR_Print("(%s \"%s\")",
            node->Name(),
            String::Handle(node->field().name()).ToCString());
}


void AstPrinter::VisitStaticGetterNode(StaticGetterNode* node) {
  String& class_name = String::Handle(node->cls().Name());
  THR_Print("(%s \"%s.%s\")",
            node->Name(),
            class_name.ToCString(),
            node->field_name().ToCString());
}


void AstPrinter::VisitStaticSetterNode(StaticSetterNode* node) {
  String& class_name = String::Handle(node->cls().Name());
  THR_Print("(%s \"%s.%s\" ",
            node->Name(),
            class_name.ToCString(),
            node->field_name().ToCString());
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitLoadIndexedNode(LoadIndexedNode* node) {
  THR_Print("(%s%s ", node->Name(), node->IsSuperLoad() ? " super" : "");
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitStoreIndexedNode(StoreIndexedNode* node) {
  THR_Print("(%s%s ", node->Name(), node->IsSuperStore() ? " super" : "");
  node->VisitChildren(this);
  THR_Print(")");
}


void AstPrinter::VisitNativeBodyNode(NativeBodyNode* node) {
  THR_Print("(%s \"%s\" (%" Pd " args))",
            node->Name(),
            node->native_c_function_name().ToCString(),
            NativeArguments::ParameterCountForResolution(node->function()));
}


void AstPrinter::VisitCatchClauseNode(CatchClauseNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitTryCatchNode(TryCatchNode* node) {
  THR_Print("(%s ", node->Name());
  node->try_block()->Visit(this);
  node->catch_block()->Visit(this);
  if (node->finally_block() != NULL) {
    THR_Print("(finally ");
    node->finally_block()->Visit(this);
    THR_Print(")");
  }
  THR_Print(")");
}


void AstPrinter::VisitThrowNode(ThrowNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitStopNode(StopNode* node) {
  THR_Print("(%s %s)", node->Name(), node->message());
}


void AstPrinter::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::PrintNode(AstNode* node) {
  ASSERT(node != NULL);
  AstPrinter ast_printer;
  node->Visit(&ast_printer);
  THR_Print("\n");
}


static void IndentN(int count) {
  for (int i = 0; i < count; i++) {
    THR_Print(" ");
  }
}


void AstPrinter::PrintLocalScopeVariable(const LocalScope* scope,
                                         LocalVariable* var,
                                         int indent) {
  ASSERT(scope != NULL);
  ASSERT(var != NULL);
  IndentN(indent);
  THR_Print("(%s%s '%s'",
            var->is_final() ? "final " : "",
            String::Handle(var->type().Name()).ToCString(),
            var->name().ToCString());
  if (var->owner() != scope) {
    THR_Print(" alias");
  }
  if (var->HasIndex()) {
    THR_Print(" @%d", var->index());
    if (var->is_captured()) {
      THR_Print(" ctx %d", var->owner()->context_level());
    }
  } else if (var->owner()->function_level() != 0) {
    THR_Print(" lev %d", var->owner()->function_level());
  }
  THR_Print(" valid %s-%s)\n",
            var->token_pos().ToCString(),
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
    THR_Print("{scope %p ", child);
    if (child->HasContextLevel()) {
      THR_Print("ctx %d numctxvar %d ",
                child->context_level(),
                child->num_context_variables());
    }
    THR_Print("llev %d\n", child->loop_level());
    PrintLocalScope(child, 0, indent + kScopeIndent);
    IndentN(indent);
    THR_Print("}\n");
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
  THR_Print("Scope for function '%s'\n{scope %p ", function_name, scope);
  if (scope->HasContextLevel()) {
    THR_Print("ctx %d numctxvar %d ",
              scope->context_level(),
              scope->num_context_variables());
  }
  THR_Print("llev %d\n", scope->loop_level());
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
    THR_Print("(param %s%s '%s'",
              param->is_final() ? "final " : "",
              String::Handle(param->type().Name()).ToCString(),
              param->name().ToCString());
    // Print the default value if the parameter is optional.
    if (pos >= num_fixed_params && pos < num_params) {
      const Instance& default_parameter_value =
          parsed_function.DefaultParameterValueAt(pos - num_fixed_params);
      THR_Print(" =%s", default_parameter_value.ToCString());
    }
    if (param->HasIndex()) {
      THR_Print(" @%d", param->index());
      if (param->is_captured()) {
        THR_Print(" ctx %d", param->owner()->context_level());
      }
    }
    THR_Print(" valid %s-%s)\n",
              param->token_pos().ToCString(),
              scope->end_token_pos().ToCString());
    pos++;
  }
  // Visit remaining non-parameter variables and children scopes.
  PrintLocalScope(scope, pos, indent);
  THR_Print("}\n");
}


void AstPrinter::PrintFunctionNodes(const ParsedFunction& parsed_function) {
  HANDLESCOPE(parsed_function.thread());
  SequenceNode* node_sequence = parsed_function.node_sequence();
  ASSERT(node_sequence != NULL);
  AstPrinter ast_printer;
  const char* function_name =
      parsed_function.function().ToFullyQualifiedCString();
  THR_Print("Ast for function '%s' {\n", function_name);
  node_sequence->Visit(&ast_printer);
  THR_Print("}\n");
}

}  // namespace dart

#endif  // !defined(PRODUCT)
