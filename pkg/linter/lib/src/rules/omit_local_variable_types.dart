// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

import '../analyzer.dart';

const _desc = r'Omit type annotations for local variables.';

class OmitLocalVariableTypes extends LintRule {
  OmitLocalVariableTypes()
      : super(
          name: LintNames.omit_local_variable_types,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules => const [
        LintNames.always_specify_types,
        LintNames.specify_nonobvious_local_variable_types,
      ];

  @override
  LintCode get lintCode => LinterLintCode.omit_local_variable_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeProvider);
    registry.addForStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final TypeProvider typeProvider;

  _Visitor(this.rule, this.typeProvider);

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForPartsWithDeclarations) {
      _visitVariableDeclarationList(loopParts.variables);
    } else if (loopParts is ForEachPartsWithDeclaration) {
      var loopVariableType = loopParts.loopVariable.type;
      var staticType = loopVariableType?.type;
      if (staticType == null || staticType is DynamicType) return;

      var loopType = loopParts.iterable.staticType;
      if (loopType is! InterfaceType) return;

      var iterableType = loopType.asInstanceOf(typeProvider.iterableElement);
      if (iterableType == null) return;
      if (iterableType.typeArguments.isNotEmpty &&
          iterableType.typeArguments.first == staticType) {
        rule.reportLint(loopVariableType);
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  void _visitVariableDeclarationList(VariableDeclarationList node) {
    var staticType = node.type?.type;
    if (staticType == null ||
        staticType is DynamicType ||
        staticType.isDartCoreNull) {
      return;
    }
    for (var child in node.variables) {
      var initializer = child.initializer;
      if (initializer == null || initializer.staticType != staticType) {
        return;
      }

      if (initializer is IntegerLiteral && !staticType.isDartCoreInt) {
        // Coerced int.
        return;
      }

      if (initializer.dependsOnDeclaredTypeForInference) {
        return;
      }
    }
    rule.reportLint(node.type);
  }
}

extension on Expression {
  bool get dependsOnDeclaredTypeForInference {
    if (this case MethodInvocation(:var methodName, typeArguments: null)) {
      var element = methodName.staticElement;
      if (element is FunctionElement) {
        if (element.returnType is TypeParameterType) {
          return true;
        }
      }
    }
    return false;
  }
}
