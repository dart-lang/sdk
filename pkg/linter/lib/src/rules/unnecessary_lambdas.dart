// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/dart_type_utilities.dart';

const _desc = r"Don't create a lambda when a tear-off will do.";

const _details = r'''
**DON'T** create a lambda when a tear-off will do.

**BAD:**
```dart
names.forEach((name) {
  print(name);
});
```

**GOOD:**
```dart
names.forEach(print);
```

''';

Set<Element?> _extractElementsOfSimpleIdentifiers(AstNode node) =>
    _IdentifierVisitor().extractElements(node);

class UnnecessaryLambdas extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_lambdas', 'Closure should be a tearoff.',
      correctionMessage: 'Try using a tearoff rather than a closure.');

  UnnecessaryLambdas()
      : super(
            name: 'unnecessary_lambdas',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addFunctionExpression(this, visitor);
  }
}

class _FinalExpressionChecker {
  final Set<ParameterElement?> parameters;

  _FinalExpressionChecker(this.parameters);

  bool isFinalNode(Expression? node_) {
    if (node_ == null) {
      return true;
    }

    var node = node_.unParenthesized;

    if (node is FunctionExpression) {
      var referencedElements = _extractElementsOfSimpleIdentifiers(node);
      return !referencedElements.any(parameters.contains);
    }

    if (node is PrefixedIdentifier) {
      return isFinalNode(node.prefix) && isFinalNode(node.identifier);
    }

    if (node is PropertyAccess) {
      return isFinalNode(node.target) && isFinalNode(node.propertyName);
    }

    if (node is SimpleIdentifier) {
      var element = node.staticElement;
      if (parameters.contains(element)) {
        return false;
      }
      return element.isFinal;
    }

    return false;
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor {
  final _elements = <Element?>{};

  _IdentifierVisitor();

  Set<Element?> extractElements(AstNode node) {
    node.accept(this);
    return _elements;
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    _elements.add(node.staticElement);
    super.visitSimpleIdentifier(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final bool constructorTearOffsEnabled;
  final LintRule rule;
  final TypeSystem typeSystem;

  _Visitor(this.rule, LinterContext context)
      : constructorTearOffsEnabled =
            context.isEnabled(Feature.constructor_tearoffs),
        typeSystem = context.typeSystem;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.declaredElement?.name != '' || node.body.keyword != null) {
      return;
    }
    var body = node.body;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      var statement = body.block.statements.single;
      if (statement is ExpressionStatement &&
          statement.expression is InvocationExpression) {
        _visitInvocationExpression(
            statement.expression as InvocationExpression, node);
      } else if (statement is ReturnStatement &&
          statement.expression is InvocationExpression) {
        var expression = statement.expression;
        if (expression is InvocationExpression) {
          // In the code, `(e) { f(e); }`, check `f(e)`.
          _visitInvocationExpression(expression, node);
        }
      }
    } else if (body is ExpressionFunctionBody) {
      var expression = body.expression;
      if (expression is InvocationExpression) {
        // In the code, `(e) { return f(e); }`, check `f(e)`.
        _visitInvocationExpression(expression, node);
      } else if (constructorTearOffsEnabled &&
          expression is InstanceCreationExpression) {
        // In the code, `(e) => C(e)`, check `C(e)`.
        _visitInstanceCreation(expression, node);
      }
    }
  }

  /// Checks [expression], the singular child the body of [node], to see whether
  /// [node] unnecessarily wraps [node].
  void _visitInstanceCreation(
      InstanceCreationExpression expression, FunctionExpression node) {
    if (expression.isConst || expression.constructorName.type.isDeferred) {
      return;
    }

    var nodeType = node.declaredElement?.type;
    var invocationType = expression.constructorName.staticElement?.type;
    if (nodeType == null) return;
    if (invocationType == null) return;
    // It is possible that the invocation function type is a valid replacement
    // for the node's function type, even if each of the parameters of `node`
    // is a valid argument for the corresponding parameter of `expression`.
    if (!typeSystem.isAssignableTo(invocationType, nodeType)) {
      return;
    }

    var arguments = expression.argumentList.arguments;
    if (arguments.any((a) => a is! SimpleIdentifier)) return;

    var identifierArguments = arguments.cast<SimpleIdentifier>();
    var parameters = node.parameters?.parameters ?? <FormalParameter>[];
    if (parameters.length != arguments.length) return;

    for (var i = 0; i < arguments.length; ++i) {
      if (identifierArguments[i].name != parameters[i].name?.lexeme) {
        return;
      }
    }

    rule.reportLint(node);
  }

  void _visitInvocationExpression(
      InvocationExpression node, FunctionExpression nodeToLint) {
    var nodeToLintParams = nodeToLint.parameters?.parameters;
    if (nodeToLintParams == null ||
        !argumentsMatchParameters(
            node.argumentList.arguments, nodeToLintParams)) {
      return;
    }

    var parameters = nodeToLintParams.map((e) => e.declaredElement).toSet();
    if (node is FunctionExpressionInvocation) {
      // TODO(pq): consider checking for assignability
      // see: https://github.com/dart-lang/linter/issues/1561
      var checker = _FinalExpressionChecker(parameters);
      if (checker.isFinalNode(node.function)) {
        rule.reportLint(nodeToLint);
      }
    } else if (node is MethodInvocation) {
      var target = node.target;
      if (target is SimpleIdentifier) {
        var element = target.staticElement;
        if (element is PrefixElement) {
          if (element.imports.any((e) => e.isDeferred)) return;
        }
      }

      var tearoffType = node.staticInvokeType;
      if (tearoffType == null) return;

      var parent = nodeToLint.parent;
      if (parent is NamedExpression) {
        var argType = parent.staticType;
        if (argType == null) return;
        if (!typeSystem.isSubtypeOf(tearoffType, argType)) return;
      } else if (parent is VariableDeclaration) {
        var variableType = parent.declaredElement?.type;
        if (variableType == null) return;
        if (!typeSystem.isSubtypeOf(tearoffType, variableType)) return;
      }

      var checker = _FinalExpressionChecker(parameters);
      if (!node.containsNullAwareInvocationInChain() &&
          checker.isFinalNode(node.target) &&
          node.methodName.staticElement.isFinal &&
          node.typeArguments == null) {
        rule.reportLint(nodeToLint);
      }
    }
  }
}

extension on LibraryImportElement {
  bool get isDeferred => prefix is DeferredImportElementPrefix;
}

extension on Element? {
  /// Returns whether this is a `final` variable or property and not `late`.
  bool get isFinal {
    var self = this;
    if (self is PropertyAccessorElement) {
      var variable = self.variable2;
      return self.isSynthetic &&
          variable != null &&
          variable.isFinal &&
          !variable.isLate;
    } else if (self is VariableElement) {
      return self.isFinal && !self.isLate;
    }
    return true;
  }
}
