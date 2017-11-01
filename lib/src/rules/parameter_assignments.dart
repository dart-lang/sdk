// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc =
    r"Don't reassign references to parameters of functions or methods.";

const _details = r'''

**DON'T** assign new values to parameters of methods or functions.

Assigning new values to parameters is generally a bad practice unless an
operator such as `??=` is used.  Otherwise, arbitrarily reassigning parameters
is usually a mistake.

**BAD:**
```
void badFunction(int parameter) { // LINT
  parameter = 4;
}
```

**BAD:**
```
void badFunction(int required, {int optional: 42}) { // LINT
  optional ??= 8;
}
```

**BAD:**
```
void badFunctionPositional(int required, [int optional = 42]) { // LINT
  optional ??= 8;
}
```

**BAD:**
```
class A {
    void badMethod(int parameter) { // LINT
    parameter = 4;
  }
}
```

**GOOD:**
```
void ok(String parameter) {
  print(parameter);
}
```

**GOOD:**
```
void actuallyGood(int required, {int optional}) { // OK
  optional ??= ...;
}
```

**GOOD:**
```
void actuallyGoodPositional(int required, [int optional]) { // OK
  optional ??= ...;
}
```

**GOOD:**
```
class A {
  void ok(String parameter) {
    print(parameter);
  }
}
```

''';

bool _isDefaultFormalParameterWithDefaultValue(FormalParameter parameter) =>
    parameter is DefaultFormalParameter && parameter.defaultValue != null;

bool _isDefaultFormalParameterWithoutDefaultValueReassigned(
        FormalParameter parameter, AssignmentExpression assignment) =>
    parameter is DefaultFormalParameter &&
    parameter.defaultValue == null &&
    _isFormalParameterReassigned(parameter, assignment);

bool _isFormalParameterReassigned(
        FormalParameter parameter, AssignmentExpression assignment) =>
    assignment.leftHandSide is SimpleIdentifier &&
    (assignment.leftHandSide as SimpleIdentifier).staticElement ==
        parameter.element;

bool _preOrPostFixExpressionMutation(FormalParameter parameter, AstNode n) =>
    n is PrefixExpression &&
        n.operand is SimpleIdentifier &&
        (n.operand as SimpleIdentifier).staticElement == parameter.element ||
    n is PostfixExpression &&
        n.operand is SimpleIdentifier &&
        (n.operand as SimpleIdentifier).staticElement == parameter.element;

class ParameterAssignments extends LintRule {
  _Visitor _visitor;

  ParameterAssignments()
      : super(
            name: 'parameter_assignments',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    FormalParameterList parameters = node.functionExpression.parameters;
    if (parameters != null) {
      // Getter do not have formal parameters.
      parameters.parameters.forEach((e) {
        if (node.functionExpression.body
            .isPotentiallyMutatedInScope(e.element)) {
          _reportIfSimpleParameterOrWithDefaultValue(e, node);
        }
      });
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    FormalParameterList parameterList = node?.parameters;
    if (parameterList != null) {
      // Getters don't have parameters.
      parameterList.parameters.forEach((e) {
        if (node.body.isPotentiallyMutatedInScope(e.element)) {
          _reportIfSimpleParameterOrWithDefaultValue(e, node);
        }
      });
    }
  }

  void _reportIfSimpleParameterOrWithDefaultValue(
      FormalParameter parameter, AstNode functionOrMethodDeclaration) {
    final nodes =
        DartTypeUtilities.traverseNodesInDFS(functionOrMethodDeclaration);

    if (parameter is SimpleFormalParameter ||
        _isDefaultFormalParameterWithDefaultValue(parameter)) {
      final mutatedNodes = nodes.where((n) =>
          (n is AssignmentExpression &&
              _isFormalParameterReassigned(parameter, n)) ||
          _preOrPostFixExpressionMutation(parameter, n));
      mutatedNodes.forEach(rule.reportLint);
      return;
    }

    final assignmentsNodes = nodes
        .where((n) =>
            n is AssignmentExpression &&
            _isDefaultFormalParameterWithoutDefaultValueReassigned(
                parameter, n))
        .toList();

    final nonNullCoalescingAssignments = assignmentsNodes.where((n) =>
        (n as AssignmentExpression).operator.type !=
        TokenType.QUESTION_QUESTION_EQ);

    if (assignmentsNodes.length > 1 ||
        nonNullCoalescingAssignments.isNotEmpty) {
      AstNode node = assignmentsNodes.length > 1
          ? assignmentsNodes.last
          : nonNullCoalescingAssignments.isNotEmpty
              ? nonNullCoalescingAssignments.first
              : parameter;
      rule.reportLint(node);
    }
  }
}
