// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';
import '../util/flutter_utils.dart';

const _desc = r'Use key in widget constructors.';

class UseKeyInWidgetConstructors extends AnalysisRule {
  UseKeyInWidgetConstructors()
    : super(name: LintNames.use_key_in_widget_constructors, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.useKeyInWidgetConstructors;

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
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var classElement = node.declaredFragment?.element;
    if (classElement != null &&
        classElement.isPublic &&
        classElement.extendsWidget &&
        classElement.constructors.where((e) => e.isOriginDeclaration).isEmpty) {
      rule.reportAtToken(node.namePart.typeName);
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
      // TODO(scheglov): support primary constructors
      var errorNode = node.name ?? node.typeName!;
      rule.reportAtSourceRange(errorNode.sourceRange);
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
