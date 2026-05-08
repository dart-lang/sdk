// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc =
    r"Don't use the Null type, unless you are positive that you don't want void.";

class PreferVoidToNull extends AnalysisRule {
  PreferVoidToNull()
    : super(name: LintNames.prefer_void_to_null, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.preferVoidToNull;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;
  _Visitor(this.rule, this.context);

  bool isFutureOrVoid(DartType type) {
    if (!type.isDartAsyncFutureOr) return false;
    if (type is! InterfaceType) return false;
    return type.typeArguments.first is VoidType;
  }

  bool isVoidIncompatibleOverride(MethodDeclaration parent, AstNode node) {
    // Make sure we're checking a return type.
    if (parent.returnType?.offset != node.offset) return false;

    var member = parent.declaredFragment?.element.overriddenMember;
    if (member == null) return false;

    var returnType = member.returnType;
    if (returnType is VoidType) return false;
    if (isFutureOrVoid(returnType)) return false;

    return true;
  }

  @override
  void visitNamedType(NamedType node) {
    var nodeType = node.type;
    if (nodeType == null || !nodeType.isDartCoreNull) {
      return;
    }

    var parent = node.parent;

    // `Null;` or `t == Null`
    if (parent is TypeLiteral) return;

    // Null Function()
    if (parent is GenericFunctionType) return;

    // case var _ as Null
    if (parent is CastPattern) return;

    // a as Null
    if (parent is AsExpression) return;

    // Function(Null)
    if (parent is SimpleFormalParameter &&
        parent.parent is FormalParameterList &&
        parent.parent?.parent is GenericFunctionType) {
      return;
    }

    if (parent is VariableDeclarationList &&
        node == parent.type &&
        parent.parent is! FieldDeclaration) {
      // We should not recommend to use `void` for local or top-level variables.
      return;
    }

    // <Null>[] or <Null, Null>{}
    if (parent is TypeArgumentList) {
      var literal = parent.parent;
      if (literal is ListLiteral && literal.elements.isEmpty) {
        return;
      } else if (literal is SetOrMapLiteral && literal.elements.isEmpty) {
        return;
      }
    }

    // extension _ on Null {}
    if (parent is ExtensionOnClause) {
      return;
    }

    // extension type N(Null _) ...
    if (parent is SimpleFormalParameter) {
      if (parent.parent case FormalParameterList parent2) {
        if (parent2.parent case PrimaryConstructorDeclaration parent3) {
          if (parent3.parent is ExtensionTypeDeclaration) {
            return;
          }
        }
      }
    }

    // https://github.com/dart-lang/linter/issues/2792
    if (parent is MethodDeclaration &&
        isVoidIncompatibleOverride(parent, node)) {
      return;
    }

    if (parent != null) {
      AstNode? declaration = parent.thisOrAncestorOfType<ClassMember>();
      declaration ??= parent.thisOrAncestorOfType<CompilationUnitMember>();
      if (declaration?.isAugmentation ?? false) return;
    }

    rule.reportAtToken(node.name);
  }
}
