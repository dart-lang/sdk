// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid redundant argument values.';

const _details = r'''Avoid redundant argument values.

**DON'T** declare arguments with values that match the defaults for the
corresponding parameter.

**BAD:**
```
void f({bool valWithDefault = true, bool val}) {
  ...
}

void main() {
  f(valWithDefault: true);
}
```

**GOOD:**
```
void f({bool valWithDefault = true, bool val}) {
  ...
}

void main() {
  f(valWithDefault: false);
  f();
}
```
''';

class AvoidRedundantArgumentValues extends LintRule implements NodeLintRule {
  AvoidRedundantArgumentValues()
      : super(
            name: 'avoid_redundant_argument_values',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  void check(ArgumentList argumentList, List<ParameterElement> parameters) {
    if (argumentList.arguments.isEmpty || parameters == null) {
      return;
    }

    for (var arg in argumentList.arguments) {
      final param = arg.staticParameterElement;
      if (param == null || param.hasRequired) {
        continue;
      }
      final value = param.constantValue;
      if (value != null) {
        if (arg is NamedExpression) {
          arg = (arg as NamedExpression).expression;
        }
        final expressionValue = context.evaluateConstant(arg);
        if (expressionValue.value == value) {
          rule.reportLint(arg);
        }
      }
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    check(node.argumentList, node.staticElement?.parameters);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final element = node.staticInvokeType.element;
    List<ParameterElement> parameters;
    if (element is MethodElement) {
      parameters = element.parameters;
    }
    if (element is FunctionElement) {
      parameters = element.parameters;
    }

    check(node.argumentList, parameters);
  }
}
