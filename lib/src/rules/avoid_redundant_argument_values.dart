// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';

const _desc = r'Avoid redundant argument values.';

const _details = r'''
**DON'T** pass an argument that matches the corresponding parameter's default
value.

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
  static const LintCode code = LintCode(
      'avoid_redundant_argument_values',
      'The value of the argument is redundant because it matches the default '
          'value.',
      correctionMessage: 'Try removing the argument.');

  AvoidRedundantArgumentValues()
      : super(
            name: 'avoid_redundant_argument_values',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addEnumConstantArguments(this, visitor);
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
    // todo(pq): reenable and do ecosystem cleanup (https://github.com/dart-lang/linter/issues/4368)
    // if (value == null && arg is NullLiteral) {
    //   rule.reportLint(arg);
    // } else ...
    if (value != null && value.hasKnownValue) {
      var expressionValue = context.evaluateConstant(arg).value;
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
    while (redirectedConstructor?.redirectedConstructor != null) {
      redirectedConstructor = redirectedConstructor?.redirectedConstructor;
    }
    if (redirectedConstructor == null) {
      check(node.argumentList);
      return;
    }

    var parameters = redirectedConstructor.parameters;

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
