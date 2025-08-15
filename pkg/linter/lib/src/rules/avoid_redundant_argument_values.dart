// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';

const _desc = r'Avoid redundant argument values.';

class AvoidRedundantArgumentValues extends LintRule {
  AvoidRedundantArgumentValues()
    : super(
        name: LintNames.avoid_redundant_argument_values,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoidRedundantArgumentValues;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addEnumConstantArguments(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void check(ArgumentList argumentList) {
    var arguments = argumentList.arguments;
    if (arguments.isEmpty) {
      return;
    }

    for (var i = arguments.length - 1; i >= 0; --i) {
      var arg = arguments[i];
      var param = arg.correspondingParameter;
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

  void checkArgument(Expression arg, FormalParameterElement? param) {
    if (param == null ||
        param.isRequired ||
        param.metadata.hasRequired ||
        !param.isOptional) {
      return;
    }

    var value = param.computeConstantValue();
    // TODO(pq): reenable and do ecosystem cleanup (https://github.com/dart-lang/linter/issues/4368)
    // if (value == null && arg is NullLiteral) {
    //   rule.reportLint(arg);
    // } else ...
    if (value != null && value.hasKnownValue) {
      var expressionValue = arg.computeConstantValue()?.value;
      if ((expressionValue?.hasKnownValue ?? false) &&
          expressionValue == value) {
        rule.reportAtNode(arg);
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
    var constructor = node.constructorName.element;
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

    var parameters = constructor!.formalParameters;

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
      FormalParameterElement? param;
      if (arg is NamedExpression) {
        param = parameters.firstWhereOrNull(
          (p) => p.isNamed && p.name == arg.name.label.name,
        );
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
