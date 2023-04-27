// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

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

Iterable<Element?> _extractElementsOfSimpleIdentifiers(AstNode node) =>
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

  /// Returns whether [element] is a `final` variable or property and not
  /// `late`.
  bool isFinalElement(Element? element) {
    if (element is PropertyAccessorElement) {
      return element.isSynthetic &&
          element.variable.isFinal &&
          !element.variable.isLate;
    } else if (element is VariableElement) {
      return element.isFinal && !element.isLate;
    }
    return true;
  }

  bool isFinalNode(Expression? node) {
    if (node == null) {
      return true;
    }

    if (node is FunctionExpression) {
      var referencedElements = _extractElementsOfSimpleIdentifiers(node);
      return !referencedElements.any(parameters.contains);
    }

    if (node is ParenthesizedExpression) {
      return isFinalNode(node.expression);
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
      return isFinalElement(element);
    }

    return false;
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor {
  final _elements = <Element?>[];

  _IdentifierVisitor();

  List<Element?> extractElements(AstNode node) {
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
  final LinterContext context;

  _Visitor(this.rule, this.context)
      : constructorTearOffsEnabled =
            context.isEnabled(Feature.constructor_tearoffs);

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
          _visitInvocationExpression(expression, node);
        }
      }
    } else if (body is ExpressionFunctionBody) {
      var expression = body.expression;
      if (expression is InvocationExpression) {
        _visitInvocationExpression(expression, node);
      } else if (constructorTearOffsEnabled &&
          expression is InstanceCreationExpression) {
        _visitInstanceCreation(expression, node);
      }
    }
  }

  void _visitInstanceCreation(
      InstanceCreationExpression expression, FunctionExpression node) {
    if (expression.isConst) return;

    var arguments = expression.argumentList.arguments;
    var parameters = node.parameters?.parameters ?? <FormalParameter>[];
    if (parameters.length != arguments.length) return;

    bool matches(Expression argument, FormalParameter parameter) {
      if (argument is SimpleIdentifier) {
        return argument.name == parameter.name?.lexeme;
      }
      return false;
    }

    for (var i = 0; i < arguments.length; ++i) {
      if (!matches(arguments[i], parameters[i])) {
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

    bool isTearoffAssignable(DartType? assignedType) {
      if (assignedType != null) {
        var tearoffType = node.staticInvokeType;
        if (tearoffType == null ||
            !context.typeSystem.isSubtypeOf(tearoffType, assignedType)) {
          return false;
        }
      }
      return true;
    }

    var parameters = nodeToLintParams.map((e) => e.declaredElement).toSet();
    if (node is FunctionExpressionInvocation) {
      // todo (pq): consider checking for assignability
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
          for (var import in element.imports) {
            if (import.isDeferred) {
              return;
            }
          }
        }
      }

      var parent = nodeToLint.parent;
      if (parent is NamedExpression) {
        var argType = parent.staticType;
        if (!isTearoffAssignable(argType)) {
          return;
        }
      } else if (parent is VariableDeclaration) {
        var grandparent = parent.parent;
        if (grandparent is VariableDeclarationList) {
          var variableType = grandparent.type?.type;
          if (!isTearoffAssignable(variableType)) {
            return;
          }
        }
      }

      var checker = _FinalExpressionChecker(parameters);
      if (!node.containsNullAwareInvocationInChain() &&
          checker.isFinalNode(node.target) &&
          checker.isFinalElement(node.methodName.staticElement) &&
          node.typeArguments == null) {
        rule.reportLint(nodeToLint);
      }
    }
  }
}

extension LibraryImportElementExtension on LibraryImportElement {
  bool get isDeferred => prefix is DeferredImportElementPrefix;
}
