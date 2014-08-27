// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/ast_printer.h"

#include "vm/handles.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/parser.h"

namespace dart {

AstPrinter::AstPrinter() { }


AstPrinter::~AstPrinter() { }


void AstPrinter::VisitGenericAstNode(AstNode* node) {
  OS::Print("(%s ", node->PrettyName());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitSequenceNode(SequenceNode* node) {
  OS::Print("(%s (scope \"%p\")", node->PrettyName(), node->scope());
  for (int i = 0; i < node->length(); ++i) {
    OS::Print("\n");
    node->NodeAt(i)->Visit(this);
  }
  OS::Print(")");
}


void AstPrinter::VisitCloneContextNode(CloneContextNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitArgumentListNode(ArgumentListNode* arguments) {
  VisitGenericAstNode(arguments);
}


void AstPrinter::VisitReturnNode(ReturnNode* node) {
  VisitGenericAstNode(node);
  OS::Print("(%s %s",
            node->PrettyName(),
            (node->return_type() == ReturnNode::kContinuation) ?
                "continuation" : "");
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitGenericLocalNode(AstNode* node,
                                       const LocalVariable& var) {
  OS::Print("(%s %s%s \"%s\"",
            node->PrettyName(),
            var.is_final() ? "final " : "",
            String::Handle(var.type().Name()).ToCString(),
            var.name().ToCString());
  if (var.HasIndex()) {
    if (var.is_captured()) {
      OS::Print(" (context %d %d)", var.owner()->context_level(), var.index());
    } else {
      OS::Print(" (stack %d)", var.index());
    }
  }
  OS::Print(" ");
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitLoadLocalNode(LoadLocalNode* node) {
  VisitGenericLocalNode(node, node->local());
}


void AstPrinter::VisitStoreLocalNode(StoreLocalNode* node) {
  VisitGenericLocalNode(node, node->local());
}


void AstPrinter::VisitGenericFieldNode(AstNode* node, const Field& field) {
  OS::Print("(%s %s%s \"%s\" ",
            node->PrettyName(),
            field.is_final() ? "final " : "",
            String::Handle(AbstractType::Handle(field.type()).Name()).
                ToCString(),
            String::Handle(field.name()).ToCString());
  node->VisitChildren(this);
  OS::Print(")");
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
  OS::Print("(%s \"%s\")", node->PrettyName(), literal.ToCString());
}


void AstPrinter::VisitTypeNode(TypeNode* node) {
  const AbstractType& type = node->type();
  OS::Print("(%s \"%s\")",
            node->PrettyName(),
            String::Handle(type.Name()).ToCString());
}


void AstPrinter::VisitAssignableNode(AssignableNode* node) {
  const AbstractType& type = node->type();
  const String& dst_name = node->dst_name();
  OS::Print("(%s (type \"%s\") (of \"%s\") ",
            node->PrettyName(),
            String::Handle(type.Name()).ToCString(),
            dst_name.ToCString());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitAwaitNode(AwaitNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitAwaitMarkerNode(AwaitMarkerNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitPrimaryNode(PrimaryNode* node) {
  OS::Print("*****%s***** \"%s\")",
            node->PrettyName(),
            node->primary().ToCString());
}


void AstPrinter::VisitComparisonNode(ComparisonNode* node) {
  OS::Print("(%s %s ", node->PrettyName(), node->TokenName());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitBinaryOpNode(BinaryOpNode* node) {
  OS::Print("(%s %s ", node->PrettyName(), node->TokenName());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitBinaryOpWithMask32Node(BinaryOpWithMask32Node* node) {
  OS::Print("(%s %s ", node->PrettyName(), node->TokenName());
  node->VisitChildren(this);
  OS::Print(" & \"0x%" Px64 "", node->mask32());
  OS::Print("\")");
}


void AstPrinter::VisitUnaryOpNode(UnaryOpNode* node) {
  OS::Print("(%s %s ", node->PrettyName(), node->TokenName());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitConditionalExprNode(ConditionalExprNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitIfNode(IfNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitCaseNode(CaseNode* node) {
  OS::Print("(%s (", node->PrettyName());
  for (int i = 0; i < node->case_expressions()->length(); i++) {
    node->case_expressions()->NodeAt(i)->Visit(this);
  }
  if (node->contains_default()) {
    OS::Print(" default");
  }
  OS::Print(")");
  node->statements()->Visit(this);
  OS::Print(")");
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
  OS::Print("(%s (init ", node->PrettyName());
  node->initializer()->Visit(this);
  if (node->condition() != NULL) {
    OS::Print(") (cond ");
    node->condition()->Visit(this);
  }
  OS::Print(") (update ");
  node->increment()->Visit(this);
  OS::Print(") ");
  node->body()->Visit(this);
  OS::Print(")");
}


void AstPrinter::VisitDoWhileNode(DoWhileNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitJumpNode(JumpNode* node) {
  OS::Print("(%s %s %s (scope \"%p\"))",
            node->PrettyName(),
            node->TokenName(),
            node->label()->name().ToCString(),
            node->label()->owner());
}


void AstPrinter::VisitInstanceCallNode(InstanceCallNode* node) {
  OS::Print("(%s \"%s\" ",
            node->PrettyName(),
            node->function_name().ToCString());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitStaticCallNode(StaticCallNode* node) {
  const char* function_fullname = node->function().ToFullyQualifiedCString();
  OS::Print("(%s \"%s\" ", node->PrettyName(), function_fullname);
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitClosureNode(ClosureNode* node) {
  const char* function_fullname = node->function().ToFullyQualifiedCString();
  OS::Print("(%s \"%s\")", node->PrettyName(), function_fullname);
}


void AstPrinter::VisitClosureCallNode(ClosureCallNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitConstructorCallNode(ConstructorCallNode* node) {
  const char* kind = node->constructor().IsFactory() ? "factory " : "";
  const char* constructor_name = node->constructor().ToFullyQualifiedCString();
  OS::Print("(%s %s \"%s\" ", node->PrettyName(), kind, constructor_name);
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitInstanceGetterNode(InstanceGetterNode* node) {
  OS::Print("(%s \"%s\" ",
            node->PrettyName(),
            node->field_name().ToCString());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitInstanceSetterNode(InstanceSetterNode* node) {
  OS::Print("(%s \"%s\" ",
            node->PrettyName(),
            node->field_name().ToCString());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitInitStaticFieldNode(InitStaticFieldNode* node) {
  OS::Print("(%s \"%s\")", node->PrettyName(),
            String::Handle(node->field().name()).ToCString());
}


void AstPrinter::VisitStaticGetterNode(StaticGetterNode* node) {
  String& class_name = String::Handle(node->cls().Name());
  OS::Print("(%s \"%s.%s\")",
            node->PrettyName(),
            class_name.ToCString(),
            node->field_name().ToCString());
}


void AstPrinter::VisitStaticSetterNode(StaticSetterNode* node) {
  String& class_name = String::Handle(node->cls().Name());
  OS::Print("(%s \"%s.%s\" ",
            node->PrettyName(),
            class_name.ToCString(),
            node->field_name().ToCString());
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitLoadIndexedNode(LoadIndexedNode* node) {
  OS::Print("(%s%s ", node->PrettyName(), node->IsSuperLoad() ? " super" : "");
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitStoreIndexedNode(StoreIndexedNode* node) {
  OS::Print("(%s%s ", node->PrettyName(), node->IsSuperStore() ? " super" : "");
  node->VisitChildren(this);
  OS::Print(")");
}


void AstPrinter::VisitNativeBodyNode(NativeBodyNode* node) {
  OS::Print("(%s \"%s\" (%" Pd " args))",
            node->PrettyName(),
            node->native_c_function_name().ToCString(),
            NativeArguments::ParameterCountForResolution(node->function()));
}


void AstPrinter::VisitCatchClauseNode(CatchClauseNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitTryCatchNode(TryCatchNode* node) {
  OS::Print("(%s ", node->PrettyName());
  node->try_block()->Visit(this);
  if (node->catch_block() != NULL) {
    node->catch_block()->Visit(this);
  }
  if (node->finally_block() != NULL) {
    OS::Print("(finally ");
    node->finally_block()->Visit(this);
    OS::Print(")");
  }
  OS::Print(")");
}


void AstPrinter::VisitThrowNode(ThrowNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::VisitInlinedFinallyNode(InlinedFinallyNode* node) {
  VisitGenericAstNode(node);
}


void AstPrinter::PrintNode(AstNode* node) {
  ASSERT(node != NULL);
  AstPrinter ast_printer;
  node->Visit(&ast_printer);
  OS::Print("\n");
}


static void IndentN(int count) {
  for (int i = 0; i < count; i++) {
    OS::Print(" ");
  }
}


void AstPrinter::PrintLocalScopeVariable(const LocalScope* scope,
                                         LocalVariable* var,
                                         int indent) {
  ASSERT(scope != NULL);
  ASSERT(var != NULL);
  IndentN(indent);
  OS::Print("(%s%s '%s'",
            var->is_final() ? "final " : "",
            String::Handle(var->type().Name()).ToCString(),
            var->name().ToCString());
  if (var->owner() != scope) {
    OS::Print(" alias");
  }
  if (var->HasIndex()) {
    OS::Print(" @%d", var->index());
    if (var->is_captured()) {
      OS::Print(" ctx %d", var->owner()->context_level());
    }
  } else if (var->owner()->function_level() != 0) {
    OS::Print(" lev %d", var->owner()->function_level());
  }
  OS::Print(" valid %" Pd "-%" Pd ")\n",
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
    OS::Print("{scope %p ", child);
    if (child->HasContextLevel()) {
      OS::Print("ctx %d numctxvar %d ",
                child->context_level(),
                child->num_context_variables());
    }
    OS::Print("llev %d\n", child->loop_level());
    PrintLocalScope(child, 0, indent + kScopeIndent);
    IndentN(indent);
    OS::Print("}\n");
    child = child->sibling();
  }
}


void AstPrinter::PrintFunctionScope(const ParsedFunction& parsed_function) {
  HANDLESCOPE(Isolate::Current());
  const Function& function = parsed_function.function();
  const Array& default_parameter_values =
      parsed_function.default_parameter_values();
  SequenceNode* node_sequence = parsed_function.node_sequence();
  ASSERT(node_sequence != NULL);
  const LocalScope* scope = node_sequence->scope();
  ASSERT(scope != NULL);
  const char* function_name = function.ToFullyQualifiedCString();
  OS::Print("Scope for function '%s'\n{scope %p ", function_name, scope);
  if (scope->HasContextLevel()) {
    OS::Print("ctx %d numctxvar %d ",
              scope->context_level(),
              scope->num_context_variables());
  }
  OS::Print("llev %d\n", scope->loop_level());
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
    OS::Print("(param %s%s '%s'",
              param->is_final() ? "final " : "",
              String::Handle(param->type().Name()).ToCString(),
              param->name().ToCString());
    // Print the default value if the parameter is optional.
    if (pos >= num_fixed_params && pos < num_params) {
      const Object& default_parameter_value = Object::Handle(
          default_parameter_values.At(pos - num_fixed_params));
      OS::Print(" =%s", default_parameter_value.ToCString());
    }
    if (param->HasIndex()) {
      OS::Print(" @%d", param->index());
      if (param->is_captured()) {
        OS::Print(" ctx %d", param->owner()->context_level());
      }
    }
    OS::Print(" valid %" Pd "-%" Pd ")\n",
              param->token_pos(),
              scope->end_token_pos());
    pos++;
  }
  // Visit remaining non-parameter variables and children scopes.
  PrintLocalScope(scope, pos, indent);
  OS::Print("}\n");
}


void AstPrinter::PrintFunctionNodes(const ParsedFunction& parsed_function) {
  HANDLESCOPE(Isolate::Current());
  SequenceNode* node_sequence = parsed_function.node_sequence();
  ASSERT(node_sequence != NULL);
  AstPrinter ast_printer;
  const char* function_name =
      parsed_function.function().ToFullyQualifiedCString();
  OS::Print("Ast for function '%s' {\n", function_name);
  node_sequence->Visit(&ast_printer);
  OS::Print("}\n");
}

}  // namespace dart
