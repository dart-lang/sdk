// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc =
    r"Don't reassign references to parameters of functions or methods.";

const _details = r'''
**DON'T** assign new values to parameters of methods or functions.

Assigning new values to parameters is generally a bad practice unless an
operator such as `??=` is used.  Otherwise, arbitrarily reassigning parameters
is usually a mistake.

**BAD:**
```dart
void badFunction(int parameter) { // LINT
  parameter = 4;
}
```

**BAD:**
```dart
void badFunction(int required, {int optional: 42}) { // LINT
  optional ??= 8;
}
```

**BAD:**
```dart
void badFunctionPositional(int required, [int optional = 42]) { // LINT
  optional ??= 8;
}
```

**BAD:**
```dart
class A {
  void badMethod(int parameter) { // LINT
    parameter = 4;
  }
}
```

**GOOD:**
```dart
void ok(String parameter) {
  print(parameter);
}
```

**GOOD:**
```dart
void actuallyGood(int required, {int optional}) { // OK
  optional ??= ...;
}
```

**GOOD:**
```dart
void actuallyGoodPositional(int required, [int optional]) { // OK
  optional ??= ...;
}
```

**GOOD:**
```dart
class A {
  void ok(String parameter) {
    print(parameter);
  }
}
```

''';

bool _isDefaultFormalParameterWithDefaultValue(FormalParameter parameter) =>
    parameter is DefaultFormalParameter && parameter.defaultValue != null;

bool _isFormalParameterReassigned(
    FormalParameter parameter, AssignmentExpression assignment) {
  var leftHandSide = assignment.leftHandSide;
  return leftHandSide is SimpleIdentifier &&
      leftHandSide.staticElement == parameter.declaredElement;
}

class ParameterAssignments extends LintRule {
  static const LintCode code = LintCode(
      'parameter_assignments', "Invalid assignment to the parameter '{0}'.",
      correctionMessage:
          'Try using a local variable in place of the parameter.');

  ParameterAssignments()
      : super(
            name: 'parameter_assignments',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _DeclarationVisitor extends RecursiveAstVisitor {
  final FormalParameter parameter;
  final LintRule rule;
  final bool paramIsNotNullByDefault;
  final bool paramDefaultsToNull;
  bool hasBeenAssigned = false;

  _DeclarationVisitor(this.parameter, this.rule,
      {required this.paramIsNotNullByDefault,
      required this.paramDefaultsToNull});

  Element? get parameterElement => parameter.declaredElement;

  void checkPatternElements(DartPattern node) {
    NodeList<PatternField>? fields;
    if (node is RecordPattern) fields = node.fields;
    if (node is ObjectPattern) fields = node.fields;
    if (fields != null) {
      for (var field in fields) {
        if (field.pattern.element == parameterElement) {
          reportLint(node);
        }
      }
    } else {
      List<AstNode>? elements;
      if (node is ListPattern) elements = node.elements;
      if (node is MapPattern) elements = node.elements;
      if (elements == null) return;
      for (var element in elements) {
        if (element is MapPatternEntry) {
          element = element.value;
        }
        if (element.element == parameterElement) {
          reportLint(node);
        }
      }
    }
  }

  void reportLint(AstNode node) {
    rule.reportLint(node, arguments: [parameter.name!.lexeme]);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    if (paramIsNotNullByDefault) {
      if (_isFormalParameterReassigned(parameter, node)) {
        reportLint(node);
      }
    } else if (paramDefaultsToNull) {
      if (_isFormalParameterReassigned(parameter, node)) {
        if (hasBeenAssigned) {
          reportLint(node);
        }
        hasBeenAssigned = true;
      }
    }

    super.visitAssignmentExpression(node);
  }

  @override
  visitPatternAssignment(PatternAssignment node) {
    checkPatternElements(node.pattern);

    super.visitPatternAssignment(node);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    if (paramIsNotNullByDefault) {
      var operand = node.operand;
      if (operand is SimpleIdentifier &&
          operand.staticElement == parameterElement) {
        reportLint(node);
      }
    }

    super.visitPostfixExpression(node);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    if (paramIsNotNullByDefault) {
      var operand = node.operand;
      if (operand is SimpleIdentifier &&
          operand.staticElement == parameterElement) {
        reportLint(node);
      }
    }

    super.visitPrefixExpression(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkParameters(
        node.functionExpression.parameters, node.functionExpression.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkParameters(node.parameters, node.body);
  }

  void _checkParameters(FormalParameterList? parameterList, FunctionBody body) {
    if (parameterList == null) return;

    for (var parameter in parameterList.parameters) {
      var declaredElement = parameter.declaredElement;
      if (declaredElement != null &&
          body.isPotentiallyMutatedInScope(declaredElement)) {
        var paramIsNotNullByDefault = parameter is SimpleFormalParameter ||
            _isDefaultFormalParameterWithDefaultValue(parameter);
        var paramDefaultsToNull = parameter is DefaultFormalParameter &&
            parameter.defaultValue == null;
        if (paramDefaultsToNull || paramIsNotNullByDefault) {
          body.accept(_DeclarationVisitor(parameter, rule,
              paramDefaultsToNull: paramDefaultsToNull,
              paramIsNotNullByDefault: paramIsNotNullByDefault));
        }
      }
    }
  }
}

extension on AstNode {
  Element? get element {
    var self = this;
    if (self is AssignedVariablePattern) return self.element;
    return null;
  }
}
