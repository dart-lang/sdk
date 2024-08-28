// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Avoid redundant argument values.';

const _details = r'''
**DON'T** pass an argument that matches the corresponding parameter's default
value.

Note that a method override can change the default value of a parameter, so that
an argument may be equal to one default value, and not the other. Take, for
example, two classes, `A` and `B` where `B` is a subclass of `A`, and `B`
overrides a method declared on `A`, and that method has a parameter with one
default value in `A`'s declaration, and a different default value in `B`'s
declaration. If the static type of the target of the invoked method is `B`, and
`B`'s default value matches the argument, then the argument can be omitted (and
if the argument value is different, then a lint is not reported). If, however,
the static type of the target of the invoked method is `A`, then a lint may be
reported, but we cannot know statically which method is invoked, so the reported
lint may be a false positive. Such cases can be ignored inline with a comment
like `// ignore: avoid_redundant_argument_values`.

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
            categories: {LintRuleCategory.brevity, LintRuleCategory.style});

  @override
  LintCode get lintCode => LinterLintCode.avoid_redundant_argument_values;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addEnumConstantArguments(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  void check(ArgumentList argumentList) {
    var arguments = argumentList.arguments;
    if (arguments.isEmpty) {
      return;
    }

    for (var i = arguments.length - 1; i >= 0; --i) {
      var arg = arguments[i];
      var param = arg.staticParameterElement;
      if (arg is NamedExpression) {
        arg = arg.expression;
      }
      checkArgument(arg, param);
      if (param != null && param.isOptionalPositional) {
        // Redundant arguments may be necessary to specify, in order to specify
        // a non-redundant argument for the last optional positional parameter.
        break;
      }
    }
  }

  void checkArgument(Expression arg, ParameterElement? param) {
    if (param == null ||
        param.declaration.isRequired ||
        param.hasRequired ||
        !param.isOptional) {
      return;
    }

    var value = param.computeConstantValue();
    // TODO(pq): reenable and do ecosystem cleanup (https://github.com/dart-lang/linter/issues/4368)
    // if (value == null && arg is NullLiteral) {
    //   rule.reportLint(arg);
    // } else ...
    if (value != null && value.hasKnownValue) {
      var expressionValue = arg.computeConstantValue().value;
      if ((expressionValue?.hasKnownValue ?? false) &&
          expressionValue == value) {
        rule.reportLint(arg);
      }
    }
  }

  @override
  void visitEnumConstantArguments(EnumConstantArguments node) {
    check(node.argumentList);
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    check(node.argumentList);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructor = node.constructorName.staticElement;
    if (constructor != null && !constructor.isFactory) {
      check(node.argumentList);
      return;
    }

    var redirectedConstructor = constructor?.redirectedConstructor;
    if (constructor == null || redirectedConstructor == null) {
      check(node.argumentList);
      return;
    }

    var visitedConstructors = {constructor};
    while (redirectedConstructor != null) {
      if (visitedConstructors.contains(redirectedConstructor)) {
        // Cycle. Compile-time error.
        return;
      }
      visitedConstructors.add(redirectedConstructor);
      constructor = redirectedConstructor;
      redirectedConstructor = redirectedConstructor.redirectedConstructor;
    }

    var parameters = constructor!.parameters;

    // If the constructor being called is a redirecting factory constructor, an
    // argument is redundant if it is equal to the default value of the
    // corresponding parameter on the _redirected constructor_, not this
    // constructor, which may be different.

    var arguments = node.argumentList.arguments;
    if (arguments.isEmpty) {
      return;
    }

    for (var i = arguments.length - 1; i >= 0; --i) {
      var arg = arguments[i];
      ParameterElement? param;
      if (arg is NamedExpression) {
        param = parameters.firstWhereOrNull(
            (p) => p.isNamed && p.name == arg.name.label.name);
      } else {
        // Count which positional argument we're at.
        var positionalCount =
            arguments.take(i + 1).where((a) => a is! NamedExpression).length;
        var positionalIndex = positionalCount - 1;
        if (positionalIndex < parameters.length) {
          if (parameters[positionalIndex].isPositional) {
            param = parameters[positionalIndex];
          }
        }
      }
      checkArgument(arg, param);
      if (param != null && param.isOptionalPositional) {
        // Redundant arguments may be necessary to specify, in order to specify
        // a non-redundant argument for the last optional positional parameter.
        break;
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    check(node.argumentList);
  }
}
