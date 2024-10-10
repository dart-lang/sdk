// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc =
    r'Avoid <Type>.toString() in production code since results may be minified.';

class AvoidTypeToString extends LintRule {
  AvoidTypeToString()
      : super(
          name: LintNames.avoid_type_to_string,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_type_to_string;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor =
        _Visitor(this, context.typeSystem, context.typeProvider.typeType);
    // Gathering meta information at these nodes.
    // Nodes visited in DFS, so this will be called before
    // each visitMethodInvocation.
    registry.addClassDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
    registry.addExtensionDeclaration(this, visitor);

    registry.addArgumentList(this, visitor);

    // Actually checking things at these nodes.
    // Also delegates to visitArgumentList.
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystem typeSystem;
  final InterfaceType typeType;

  // Null if there is no logical `this` in the given context.
  InterfaceType? thisType;

  _Visitor(this.rule, this.typeSystem, this.typeType);

  @override
  void visitArgumentList(ArgumentList node) {
    node.arguments.forEach(_validateArgument);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    thisType = node.declaredFragment?.element.thisType;
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var extendedType = node.declaredFragment?.element.extendedType;
    // Might not be InterfaceType. Ex: visiting an extension on a dynamic type.
    thisType = extendedType is InterfaceType ? extendedType : null;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    visitArgumentList(node.argumentList);

    var staticType = node.realTarget?.staticType;
    var targetType = staticType is InterfaceType ? staticType : thisType;
    _reportIfToStringOnCoreTypeClass(targetType, node.methodName);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    thisType = node.declaredFragment?.element.thisType;
  }

  bool _isSimpleIdDeclByCoreObj(SimpleIdentifier simpleIdentifier) {
    var encloser = simpleIdentifier.element?.enclosingElement2;
    return encloser is ClassElement2 && encloser.isDartCoreObject;
  }

  bool _isToStringOnCoreTypeClass(
          DartType? targetType, SimpleIdentifier methodIdentifier) =>
      targetType != null &&
      methodIdentifier.name == 'toString' &&
      _isSimpleIdDeclByCoreObj(methodIdentifier) &&
      typeSystem.isSubtypeOf(targetType, typeType);

  void _reportIfToStringOnCoreTypeClass(
      DartType? targetType, SimpleIdentifier methodIdentifier) {
    if (_isToStringOnCoreTypeClass(targetType, methodIdentifier)) {
      rule.reportLint(methodIdentifier);
    }
  }

  void _validateArgument(Expression expression) {
    if (expression is PropertyAccess) {
      var expressionType = expression.realTarget.staticType;
      var targetType =
          (expressionType is InterfaceType) ? expressionType : thisType;
      _reportIfToStringOnCoreTypeClass(targetType, expression.propertyName);
    } else if (expression is PrefixedIdentifier) {
      var prefixType = expression.prefix.staticType;
      if (prefixType is InterfaceType) {
        _reportIfToStringOnCoreTypeClass(prefixType, expression.identifier);
      }
    } else if (expression is SimpleIdentifier) {
      _reportIfToStringOnCoreTypeClass(thisType, expression);
    }
  }
}
