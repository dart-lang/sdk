// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = 'Prefer int literals over double literals.';

class PreferIntLiterals extends LintRule {
  PreferIntLiterals()
    : super(name: LintNames.prefer_int_literals, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.preferIntLiterals;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addDoubleLiteral(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  /// Determine if the given literal can be replaced by an int literal.
  bool canReplaceWithIntLiteral(DoubleLiteral literal) {
    var parent = literal.parent;
    if (parent is PrefixExpression) {
      if (parent.operator.lexeme == '-') {
        return hasTypeDouble(parent);
      } else {
        return false;
      }
    }
    return hasTypeDouble(literal);
  }

  bool hasReturnTypeDouble(AstNode? node) {
    if (node is FunctionExpression) {
      var functionDeclaration = node.parent;
      if (functionDeclaration is FunctionDeclaration) {
        return _isDartCoreDoubleTypeAnnotation(functionDeclaration.returnType);
      }
    } else if (node is MethodDeclaration) {
      return _isDartCoreDoubleTypeAnnotation(node.returnType);
    }
    return false;
  }

  bool hasTypeDouble(Expression expression) {
    var parent = expression.parent;
    if (parent is ArgumentList) {
      return _isDartCoreDouble(expression.correspondingParameter?.type);
    } else if (parent is ListLiteral) {
      var typeArguments = parent.typeArguments?.arguments;
      return typeArguments?.length == 1 &&
          _isDartCoreDoubleTypeAnnotation(typeArguments!.first);
    } else if (parent is NamedExpression) {
      var argList = parent.parent;
      if (argList is ArgumentList) {
        return _isDartCoreDouble(parent.correspondingParameter?.type);
      }
    } else if (parent is ExpressionFunctionBody) {
      return hasReturnTypeDouble(parent.parent);
    } else if (parent is ReturnStatement) {
      var body = parent.thisOrAncestorOfType<BlockFunctionBody>();
      return body != null && hasReturnTypeDouble(body.parent);
    } else if (parent is VariableDeclaration) {
      var varList = parent.parent;
      if (varList is VariableDeclarationList) {
        return _isDartCoreDoubleTypeAnnotation(varList.type);
      }
    }
    return false;
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    // Check if the double can be represented as an int
    try {
      var value = node.value;
      if (value != value.truncate()) {
        return;
      }
      // ignore: avoid_catching_errors
    } on UnsupportedError catch (_) {
      // The double cannot be represented as an int
      return;
    }

    // Ensure that replacing the double would not change the semantics
    if (canReplaceWithIntLiteral(node)) {
      rule.reportAtNode(node);
    }
  }

  bool _isDartCoreDouble(DartType? type) => type?.isDartCoreDouble ?? false;

  bool _isDartCoreDoubleTypeAnnotation(TypeAnnotation? annotation) =>
      _isDartCoreDouble(annotation?.type);
}
