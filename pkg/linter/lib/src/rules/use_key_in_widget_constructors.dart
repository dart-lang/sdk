// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../ast.dart';
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
    registry.addPrimaryConstructorDeclaration(this, visitor);
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
        !classElement.metadata.hasVisibleForTesting &&
        classElement.extendsWidget &&
        classElement.constructors.where((e) => e.isOriginDeclaration).isEmpty) {
      rule.reportAtToken(node.namePart.typeName);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.isAugmentation) return;
    _checkConstructor(
      constructorElement: node.declaredFragment?.element,
      parameters: node.parameters,
      initializers: node.initializers,
      errorNode: getNodeToAnnotate(node),
    );
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    if (node.isAugmentation) return;
    _checkConstructor(
      constructorElement: node.declaredFragment?.element,
      parameters: node.formalParameters,
      initializers: node.body?.initializers ?? const [],
      errorNode: getNodeToAnnotate(node),
    );
  }

  void _checkConstructor({
    required ConstructorElement? constructorElement,
    required FormalParameterList parameters,
    required List<ConstructorInitializer> initializers,
    required SyntacticEntity errorNode,
  }) {
    if (constructorElement == null) return;
    if (constructorElement.isPrivate) return;
    if (constructorElement.isFactory) return;
    if (constructorElement.metadata.hasVisibleForTesting) return;
    var classElement = constructorElement.enclosingElement;
    if (classElement.isPrivate) return;
    if (classElement is! ClassElement) return;
    if (classElement.metadata.hasVisibleForTesting) return;
    if (classElement.isExactlyWidget) return;
    if (!classElement.extendsWidget) return;
    if (_hasKeySuperParameterInitializerArg(parameters)) return;
    if (!initializers.any((initializer) => initializer.isMissingKey)) {
      rule.reportAtSourceRange(errorNode.sourceRange);
    }
  }

  bool _hasKeySuperParameterInitializerArg(FormalParameterList parameters) {
    for (var parameter in parameters.parameterFragments) {
      var element = parameter?.element;
      if (element is SuperFormalParameterElement && element.name == 'key') {
        return true;
      }
    }
    return false;
  }
}

extension on ConstructorInitializer {
  bool get isMissingKey => switch (this) {
    SuperConstructorInvocation(:var element?, :var argumentList) ||
    RedirectingConstructorInvocation(
      :var element?,
      :var argumentList,
    ) => !element.definesKeyParameter || argumentList.containsKeyArgument,
    _ => false,
  };
}

extension on ConstructorElement {
  bool get definesKeyParameter => formalParameters.any(
    (e) => e.name == 'key' && e.type.implementsInterface('Key', ''),
  );
}

extension on ArgumentList {
  bool get containsKeyArgument =>
      arguments.any((a) => a.correspondingParameter?.name == 'key');
}
