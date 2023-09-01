// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid positional boolean parameters.';

const _details = r'''
**AVOID** positional boolean parameters.

Positional boolean parameters are a bad practice because they are very
ambiguous.  Using named boolean parameters is much more readable because it
inherently describes what the boolean value represents.

**BAD:**
```dart
Task(true);
Task(false);
ListBox(false, true, true);
Button(false);
```

**GOOD:**
```dart
Task.oneShot();
Task.repeating();
ListBox(scroll: true, showScrollbars: true);
Button(ButtonState.enabled);
```

''';

class AvoidPositionalBooleanParameters extends LintRule {
  static const LintCode code = LintCode('avoid_positional_boolean_parameters',
      "'bool' parameters should be named parameters.",
      correctionMessage: 'Try converting the parameter to a named parameter.');

  AvoidPositionalBooleanParameters()
      : super(
            name: 'avoid_positional_boolean_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addGenericFunctionType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  void checkParams(List<FormalParameter>? parameters) {
    var parameterToLint = parameters?.firstWhereOrNull(_isBoolean);
    if (parameterToLint != null) {
      rule.reportLint(parameterToLint);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement != null && !declaredElement.isPrivate) {
      checkParams(node.parameters.parameters);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement != null && !declaredElement.isPrivate) {
      checkParams(node.functionExpression.parameters?.parameters);
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    checkParams(node.parameters.parameters);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement != null &&
        !node.isSetter &&
        !declaredElement.isPrivate &&
        !node.isOperator &&
        !node.hasInheritedMethod &&
        !_isOverridingMember(declaredElement)) {
      checkParams(node.parameters?.parameters);
    }
  }

  bool _isOverridingMember(Element member) {
    var classElement = member.thisOrAncestorOfType<ClassElement>();
    if (classElement == null) return false;

    var name = member.name;
    if (name == null) return false;

    var libraryUri = classElement.library.source.uri;
    return context.inheritanceManager
            .getInherited(classElement.thisType, Name(libraryUri, name)) !=
        null;
  }

  static bool _isBoolean(FormalParameter node) {
    var type = node.declaredElement?.type;
    return !node.isNamed && type is InterfaceType && type.isDartCoreBool;
  }
}
