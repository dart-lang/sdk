// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/flutter_utils.dart';

const _desc = r'Use key in widget constructors.';

class UseKeyInWidgetConstructors extends LintRule {
  UseKeyInWidgetConstructors()
    : super(name: LintNames.use_key_in_widget_constructors, description: _desc);

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.useKeyInWidgetConstructors;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var classElement = node.declaredFragment?.element;
    if (classElement != null &&
        classElement.isPublic &&
        classElement.extendsWidget &&
        classElement.constructors.where((e) => !e.isSynthetic).isEmpty) {
      rule.reportAtToken(node.name);
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.isAugmentation) return;

    var constructorElement = node.declaredFragment?.element;
    if (constructorElement == null) {
      return;
    }
    var classElement = constructorElement.enclosingElement;
    if (constructorElement.isPublic &&
        !constructorElement.isFactory &&
        classElement.isPublic &&
        classElement is ClassElement &&
        !classElement.isExactlyWidget &&
        classElement.extendsWidget &&
        !_hasKeySuperParameterInitializerArg(node) &&
        !node.initializers.any((initializer) {
          if (initializer is SuperConstructorInvocation) {
            var staticElement = initializer.element;
            return staticElement != null &&
                (!_defineKeyParameter(staticElement) ||
                    _defineKeyArgument(initializer.argumentList));
          } else if (initializer is RedirectingConstructorInvocation) {
            var staticElement = initializer.element;
            return staticElement != null &&
                (!_defineKeyParameter(staticElement) ||
                    _defineKeyArgument(initializer.argumentList));
          }
          return false;
        })) {
      var errorNode = node.name ?? node.returnType;
      rule.reportAtOffset(errorNode.offset, errorNode.length);
    }
    super.visitConstructorDeclaration(node);
  }

  bool _defineKeyArgument(ArgumentList argumentList) => argumentList.arguments
      .any((a) => a.correspondingParameter?.name == 'key');

  bool _defineKeyParameter(ConstructorElement element) => element
      .formalParameters
      .any((e) => e.name == 'key' && _isKeyType(e.type));

  bool _hasKeySuperParameterInitializerArg(ConstructorDeclaration node) {
    for (var parameter in node.parameters.parameterFragments) {
      var element = parameter?.element;
      if (element is SuperFormalParameterElement && element.name == 'key') {
        return true;
      }
    }

    return false;
  }

  bool _isKeyType(DartType type) => type.implementsInterface('Key', '');
}
