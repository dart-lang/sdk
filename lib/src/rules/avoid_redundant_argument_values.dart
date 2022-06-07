// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid redundant argument values.';

const _details = r'''Avoid redundant argument values.

**DON'T** declare arguments with values that match the defaults for the
corresponding parameter.

**BAD:**
```dart
void f({bool valWithDefault = true, bool? val}) {
  ...
}

void main() {
  f(valWithDefault: true);
}
```

**GOOD:**
```dart
void f({bool valWithDefault = true, bool? val}) {
  ...
}

void main() {
  f(valWithDefault: false);
  f();
}
```
''';

class AvoidRedundantArgumentValues extends LintRule {
  AvoidRedundantArgumentValues()
      : super(
            name: 'avoid_redundant_argument_values',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  void check(ArgumentList argumentList) {
    var arguments = argumentList.arguments;
    if (arguments.isEmpty) {
      return;
    }

    for (var i = arguments.length - 1; i >= 0; --i) {
      var arg = arguments[i];
      var param = arg.staticParameterElement;
      if (param == null || param.hasRequired || !param.isOptional) {
        continue;
      }
      var value = param.computeConstantValue();
      if (value != null && value.hasKnownValue) {
        if (arg is NamedExpression) {
          arg = arg.expression;
        }
        var expressionValue = context.evaluateConstant(arg).value;
        if ((expressionValue?.hasKnownValue ?? false) &&
            expressionValue == value) {
          rule.reportLint(arg);
        }
      }
      if (param.isOptionalPositional) {
        break;
      }
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    check(node.argumentList);
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    check(node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    check(node.argumentList);
  }
}
