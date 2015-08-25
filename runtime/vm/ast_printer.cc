// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast_printer.h"

#include "vm/handles.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/parser.h"

namespace dart {

AstPrinter::AstPrinter() : indent_(0) { }


AstPrinter::~AstPrinter() { }


void AstPrinter::VisitGenericAstNode(AstNode* node) {
  ISL_Print("(%s ", node->PrettyName());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitSequenceNode(SequenceNode* node) {
  indent_++;
  LocalScope* scope = node->scope();
  ISL_Print("(%s (scope \"%p\"", node->PrettyName(), scope);
  if (scope != NULL) {
    ISL_Print(" (%" Pd "-%" Pd ") loop %d",
              scope->begin_token_pos(),
              scope->end_token_pos(),
              scope->loop_level());
    if (scope->HasContextLevel()) {
      ISL_Print(" context %d captures %d",
                scope->context_level(),
                scope->num_context_variables());
    } else {
      ASSERT(scope->num_context_variables() == 0);
    }
  }
  ISL_Print(")");
  for (int i = 0; i < node->length(); ++i) {
    ISL_Print("\n");
    for (intptr_t p = 0; p < indent_; p++) {
      ISL_Print("  ");
    }
    node->NodeAt(i)->Visit(this);
  }
  ISL_Print(")");
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
  ISL_Print("(%s %s", node->PrettyName(), kind);
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitGenericLocalNode(AstNode* node,
                                       const LocalVariable& var) {
  ISL_Print("(%s %s%s \"%s\"",
            node->PrettyName(),
            var.is_final() ? "final " : "",
            String::Handle(var.type().Name()).ToCString(),
            var.name().ToCString());
  if (var.HasIndex()) {
    if (var.is_captured()) {
      ISL_Print(" (context %d %d)", var.owner()->context_level(), var.index());
    } else {
      ISL_Print(" (stack %d)", var.index());
    }
  }
  ISL_Print(" ");
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitLoadLocalNode(LoadLocalNode* node) {
  VisitGenericLocalNode(node, node->local());
}


void AstPrinter::VisitStoreLocalNode(StoreLocalNode* node) {
  VisitGenericLocalNode(node, node->local());
}


void AstPrinter::VisitGenericFieldNode(AstNode* node, const Field& field) {
  ISL_Print("(%s %s%s \"%s\" ",
            node->PrettyName(),
            field.is_final() ? "final " : "",
            String::Handle(AbstractType::Handle(field.type()).Name()).
                ToCString(),
            String::Handle(field.name()).ToCString());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitLoadInstanceFieldNode(LoadInstanceFieldNode* node) {
  VisitGenericFieldNode(node, node->field());
}


void AstPrinter::VisitStoreInstanceFieldNode(StoreInstanceFieldNode* node) {
  VisitGenericFieldNode(node, node->field());
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
  ISL_Print("(%s \"%s\")", node->PrettyName(), literal.ToCString());
}


void AstPrinter::VisitTypeNode(TypeNode* node) {
  const AbstractType& type = node->type();
  ISL_Print("(%s \"%s\")",
            node->PrettyName(),
            String::Handle(type.Name()).ToCString());
}


void AstPrinter::VisitAssignableNode(AssignableNode* node) {
  const AbstractType& type = node->type();
  const String& dst_name = node->dst_name();
  ISL_Print("(%s (type \"%s\") (of \"%s\") ",
            node->PrettyName(),
            String::Handle(type.Name()).ToCString(),
            dst_name.ToCString());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitAwaitNode(AwaitNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitAwaitMarkerNode(AwaitMarkerNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitPrimaryNode(PrimaryNode* node) {
  ISL_Print("*****%s***** \"%s\")",
            node->PrettyName(),
            node->primary().ToCString());
}


void AstPrinter::VisitComparisonNode(ComparisonNode* node) {
  ISL_Print("(%s %s ", node->PrettyName(), node->TokenName());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitBinaryOpNode(BinaryOpNode* node) {
  ISL_Print("(%s %s ", node->PrettyName(), node->TokenName());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitBinaryOpWithMask32Node(BinaryOpWithMask32Node* node) {
  ISL_Print("(%s %s ", node->PrettyName(), node->TokenName());
  node->VisitChildren(this);
  ISL_Print(" & \"0x%" Px64 "", node->mask32());
  ISL_Print("\")");
}


void AstPrinter::VisitUnaryOpNode(UnaryOpNode* node) {
  ISL_Print("(%s %s ", node->PrettyName(), node->TokenName());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitConditionalExprNode(ConditionalExprNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitIfNode(IfNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitCaseNode(CaseNode* node) {
  ISL_Print("(%s (", node->PrettyName());
  for (int i = 0; i < node->case_expressions()->length(); i++) {
    node->case_expressions()->NodeAt(i)->Visit(this);
  }
  if (node->contains_default()) {
    ISL_Print(" default");
  }
  ISL_Print(")");
  node->statements()->Visit(this);
  ISL_Print(")");
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
  ISL_Print("(%s (init ", node->PrettyName());
  node->initializer()->Visit(this);
  if (node->condition() != NULL) {
    ISL_Print(") (cond ");
    node->condition()->Visit(this);
  }
  ISL_Print(") (update ");
  node->increment()->Visit(this);
  ISL_Print(") ");
  node->body()->Visit(this);
  ISL_Print(")");
}


void AstPrinter::VisitDoWhileNode(DoWhileNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitJumpNode(JumpNode* node) {
  ISL_Print("(%s %s %s (scope \"%p\"))",
            node->PrettyName(),
            node->TokenName(),
            node->label()->name().ToCString(),
            node->label()->owner());
}


void AstPrinter::VisitInstanceCallNode(InstanceCallNode* node) {
  ISL_Print("(%s \"%s\" ",
            node->PrettyName(),
            node->function_name().ToCString());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitStaticCallNode(StaticCallNode* node) {
  const char* function_fullname = node->function().ToFullyQualifiedCString();
  ISL_Print("(%s \"%s\" ", node->PrettyName(), function_fullname);
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitClosureNode(ClosureNode* node) {
  const char* function_fullname = node->function().ToFullyQualifiedCString();
  ISL_Print("(%s \"%s\")", node->PrettyName(), function_fullname);
}


void AstPrinter::VisitClosureCallNode(ClosureCallNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitConstructorCallNode(ConstructorCallNode* node) {
  const char* kind = node->constructor().IsFactory() ? "factory " : "";
  const char* constructor_name = node->constructor().ToFullyQualifiedCString();
  ISL_Print("(%s %s \"%s\" ", node->PrettyName(), kind, constructor_name);
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitInstanceGetterNode(InstanceGetterNode* node) {
  ISL_Print("(%s \"%s\" ",
            node->PrettyName(),
            node->field_name().ToCString());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitInstanceSetterNode(InstanceSetterNode* node) {
  ISL_Print("(%s \"%s\" ",
            node->PrettyName(),
            node->field_name().ToCString());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitInitStaticFieldNode(InitStaticFieldNode* node) {
  ISL_Print("(%s \"%s\")", node->PrettyName(),
            String::Handle(node->field().name()).ToCString());
}


void AstPrinter::VisitStaticGetterNode(StaticGetterNode* node) {
  String& class_name = String::Handle(node->cls().Name());
  ISL_Print("(%s \"%s.%s\")",
            node->PrettyName(),
            class_name.ToCString(),
            node->field_name().ToCString());
}


void AstPrinter::VisitStaticSetterNode(StaticSetterNode* node) {
  String& class_name = String::Handle(node->cls().Name());
  ISL_Print("(%s \"%s.%s\" ",
            node->PrettyName(),
            class_name.ToCString(),
            node->field_name().ToCString());
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitLoadIndexedNode(LoadIndexedNode* node) {
  ISL_Print("(%s%s ", node->PrettyName(), node->IsSuperLoad() ? " super" : "");
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitStoreIndexedNode(StoreIndexedNode* node) {
  ISL_Print("(%s%s ", node->PrettyName(), node->IsSuperStore() ? " super" : "");
  node->VisitChildren(this);
  ISL_Print(")");
}


void AstPrinter::VisitNativeBodyNode(NativeBodyNode* node) {
  ISL_Print("(%s \"%s\" (%" Pd " args))",
            node->PrettyName(),
            node->native_c_function_name().ToCString(),
            NativeArguments::ParameterCountForResolution(node->function()));
}


void AstPrinter::VisitCatchClauseNode(CatchClauseNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitTryCatchNode(TryCatchNode* node) {
  ISL_Print("(%s ", node->PrettyName());
  node->try_block()->Visit(this);
  node->catch_block()->Visit(this);
  if (node->finally_block() != NULL) {
    ISL_Print("(finally ");
    node->finally_block()->Visit(this);
    ISL_Print(")");
  }
  ISL_Print(")");
}


void AstPrinter::VisitThrowNode(ThrowNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitStopNode(StopNode* node) {
  ISL_Print("(%s %s)", node->PrettyName(), node->message());
}


void AstPrinter::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::PrintNode(AstNode* node) {
  ASSERT(node != NULL);
  AstPrinter ast_printer;
  node->Visit(&ast_printer);
  ISL_Print("\n");
}


static void IndentN(int count) {
  for (int i = 0; i < count; i++) {
    ISL_Print(" ");
  }
}


void AstPrinter::PrintLocalScopeVariable(const LocalScope* scope,
                                         LocalVariable* var,
                                         int indent) {
  ASSERT(scope != NULL);
  ASSERT(var != NULL);
  IndentN(indent);
  ISL_Print("(%s%s '%s'",
            var->is_final() ? "final " : "",
            String::Handle(var->type().Name()).ToCString(),
            var->name().ToCString());
  if (var->owner() != scope) {
    ISL_Print(" alias");
  }
  if (var->HasIndex()) {
    ISL_Print(" @%d", var->index());
    if (var->is_captured()) {
      ISL_Print(" ctx %d", var->owner()->context_level());
    }
  } else if (var->owner()->function_level() != 0) {
    ISL_Print(" lev %d", var->owner()->function_level());
  }
  ISL_Print(" valid %" Pd "-%" Pd ")\n",
            var->token_pos(),
            scope->end_token_pos());
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
    ISL_Print("{scope %p ", child);
    if (child->HasContextLevel()) {
      ISL_Print("ctx %d numctxvar %d ",
                child->context_level(),
                child->num_context_variables());
    }
    ISL_Print("llev %d\n", child->loop_level());
    PrintLocalScope(child, 0, indent + kScopeIndent);
    IndentN(indent);
    ISL_Print("}\n");
    child = child->sibling();
  }
}


void AstPrinter::PrintFunctionScope(const ParsedFunction& parsed_function) {
  HANDLESCOPE(Isolate::Current());
  const Function& function = parsed_function.function();
  SequenceNode* node_sequence = parsed_function.node_sequence();
  ASSERT(node_sequence != NULL);
  const LocalScope* scope = node_sequence->scope();
  ASSERT(scope != NULL);
  const char* function_name = function.ToFullyQualifiedCString();
  ISL_Print("Scope for function '%s'\n{scope %p ", function_name, scope);
  if (scope->HasContextLevel()) {
    ISL_Print("ctx %d numctxvar %d ",
              scope->context_level(),
              scope->num_context_variables());
  }
  ISL_Print("llev %d\n", scope->loop_level());
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
    ISL_Print("(param %s%s '%s'",
              param->is_final() ? "final " : "",
              String::Handle(param->type().Name()).ToCString(),
              param->name().ToCString());
    // Print the default value if the parameter is optional.
    if (pos >= num_fixed_params && pos < num_params) {
      const Instance& default_parameter_value =
          parsed_function.DefaultParameterValueAt(pos - num_fixed_params);
      ISL_Print(" =%s", default_parameter_value.ToCString());
    }
    if (param->HasIndex()) {
      ISL_Print(" @%d", param->index());
      if (param->is_captured()) {
        ISL_Print(" ctx %d", param->owner()->context_level());
      }
    }
    ISL_Print(" valid %" Pd "-%" Pd ")\n",
              param->token_pos(),
              scope->end_token_pos());
    pos++;
  }
  // Visit remaining non-parameter variables and children scopes.
  PrintLocalScope(scope, pos, indent);
  ISL_Print("}\n");
}


void AstPrinter::PrintFunctionNodes(const ParsedFunction& parsed_function) {
  HANDLESCOPE(Isolate::Current());
  SequenceNode* node_sequence = parsed_function.node_sequence();
  ASSERT(node_sequence != NULL);
  AstPrinter ast_printer;
  const char* function_name =
      parsed_function.function().ToFullyQualifiedCString();
  ISL_Print("Ast for function '%s' {\n", function_name);
  node_sequence->Visit(&ast_printer);
  ISL_Print("}\n");
}

}  // namespace dart
