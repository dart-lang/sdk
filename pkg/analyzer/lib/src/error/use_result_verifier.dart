// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

class UseResultVerifier {
  final DiagnosticReporter _diagnosticReporter;

  UseResultVerifier(this._diagnosticReporter);

  void checkCallInvocation(CallInvocation node) {
    if (node.resolution case ExecutableInvocationResolution(:var element)) {
      _check(node, element);
    }
  }

  void checkConstructorInvocation(ConstructorInvocation node) {
    var element = node.constructorReference.element;
    if (element == null) {
      return;
    }

    _check(node, element);
  }

  void checkDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    var element = node.constructorName.element;
    if (element == null) {
      return;
    }

    _check(node, element);
  }

  void checkDotShorthandInvocation(DotShorthandInvocation node) {
    var element = node.memberName.element;
    if (element == null) {
      return;
    }

    _check(node, element);
  }

  void checkDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    var element = node.propertyName.element;
    if (element == null) {
      return;
    }

    _check(node, element);
  }

  void checkMethodInvocation(MethodInvocation node) {
    var element = node.methodName.element;
    if (element == null) {
      return;
    }

    _check(node, element);
  }

  void checkPropertyAccess(PropertyAccess node) {
    var element = node.propertyName.element;
    if (element == null) {
      return;
    }

    _check(node, element);
  }

  void checkPropertyExtraction(PropertyExtraction node) {
    if (node.resolution case NamedReadResolutionWithElementImpl(:var element)) {
      _check(node, element);
    }
  }

  void checkSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }

    var parent = node.parent2;
    // Covered by the checks for the complete parent expressions.
    if (parent is DotShorthandConstructorInvocation ||
        parent is DotShorthandInvocation ||
        parent is DotShorthandPropertyAccess ||
        parent is PropertyAccess ||
        parent is MethodInvocation ||
        parent is CallInvocation) {
      return;
    }

    var element = node.element;
    if (element == null) {
      return;
    }

    _check(node, element);
  }

  void _check(AstNode node, Element element) {
    var parent = node.parent2;
    if (parent is PrefixedIdentifier) {
      parent = parent.parent2;
    }
    if (parent is CommentReference) {
      // Don't flag references in comments.
      return;
    }
    if (parent is ShowCombinator || parent is HideCombinator) {
      return;
    }

    var annotation = _getUseResultMetadata(element);
    if (annotation == null) {
      return;
    }

    if (_passesUsingParam(node, annotation)) {
      return;
    }

    if (_isUsed(node)) {
      return;
    }

    var toAnnotate = node.nodeToAnnotate;
    var displayName = toAnnotate is SimpleIdentifier
        ? toAnnotate.name
        : element.displayName;

    var message = annotation.useResultMessage;
    if (message == null || message.isEmpty) {
      _diagnosticReporter.report(
        diag.unusedResult.withArguments(name: displayName).at(toAnnotate),
      );
    } else {
      _diagnosticReporter.report(
        diag.unusedResultWithMessage
            .withArguments(name: displayName, message: message)
            .at(toAnnotate),
      );
    }
  }

  bool _passesUsingParam(AstNode node, ElementAnnotation annotation) {
    if (node is! InvocationExpression) {
      return false;
    }

    var unlessParam = annotation.useResultUnlessParameter;
    if (unlessParam == null) {
      return false;
    }

    var argumentList = node.argumentList as ArgumentListImpl;
    var parameters = argumentList.correspondingStaticParameters;
    if (parameters == null) {
      return false;
    }

    for (var param in parameters) {
      var name = param?.name;
      if (unlessParam == name) {
        return true;
      }
    }

    return false;
  }

  static ElementAnnotation? _getUseResultMetadata(Element element) {
    // Implicit getters/setters.
    if (element is PropertyAccessorElement && element.isOriginVariable) {
      element = element.variable;
    }

    var annotations = element.metadata.annotations;
    for (int i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation.isUseResult) return annotation;
    }
    return null;
  }

  static bool _isUsed(AstNode node) {
    var parent = node.parent2;
    if (parent == null) {
      return false;
    }

    if (parent is CascadeExpression) {
      return parent.target2 == node;
    }

    if (parent is PrefixedIdentifier) {
      if (parent.prefix == node) {
        return true;
      } else {
        return _isUsed(parent);
      }
    }

    // Null-checking a result is not a "use".
    if (parent is NullAssertionExpression) {
      return _isUsed(parent);
    }

    if (parent is AsExpression ||
        parent is AwaitExpression ||
        parent is ConditionalExpression ||
        parent is ForElement ||
        parent is IfElement ||
        parent is LogicalNot ||
        parent is ParenthesizedExpression ||
        parent is PrefixIncrement ||
        parent is PrefixDecrement ||
        parent is SpreadElement ||
        parent is UnaryOperatorInvocation) {
      return _isUsed(parent);
    }

    if (parent is ForParts) {
      // If [node] is the condition of a for-loop, it is used; if it is one of
      // the updaters, it is not.
      return parent.condition2 == node;
    }

    return parent is ArgumentList ||
        parent is AssertInitializer ||
        parent is AssertStatement ||
        // Node should always be RHS so no need to check for a property
        // assignment.
        parent is AssignmentExpression ||
        parent is DirectAssignment ||
        parent is IfNullAssignment ||
        parent is BinaryOperatorInvocation ||
        parent is IfNull ||
        parent is ConstructorFieldInitializer ||
        parent is DoStatement ||
        parent is ExpressionFunctionBody ||
        parent is ForEachParts ||
        parent is ForLoopParts ||
        parent is CallInvocation ||
        parent is IfStatement ||
        parent is IndexAssignmentTarget ||
        parent is IndexExpression ||
        parent is IndexExpression2 ||
        parent is InterpolationExpression ||
        parent is ListLiteral ||
        parent is MapLiteralEntry ||
        parent is MethodInvocation ||
        parent is NamedArgument ||
        parent is PatternAssignment ||
        parent is PatternVariableDeclaration ||
        parent is PropertyAccess ||
        parent is PropertyExtraction ||
        parent is RecordLiteral ||
        parent is RecordLiteralNamedField ||
        parent is ReturnStatement ||
        parent is SetOrMapLiteral ||
        parent is SwitchExpression ||
        parent is SwitchExpressionCase ||
        parent is SwitchStatement ||
        parent is ThrowExpression ||
        parent is VariableDeclaration ||
        parent is WhenClause ||
        parent is WhileStatement ||
        parent is YieldStatement;
  }
}

extension on ElementAnnotation {
  String? get useResultMessage {
    if (element is GetterElement) {
      return null;
    }
    return computeConstantValue()?.getField('message')?.toStringValue();
  }

  String? get useResultUnlessParameter {
    return computeConstantValue()
        ?.getField('parameterDefined')
        ?.toStringValue();
  }
}

extension on AstNode {
  AstNode get nodeToAnnotate => switch (this) {
    DotShorthandConstructorInvocation node => node.constructorName,
    DotShorthandInvocation node => node.memberName,
    DotShorthandPropertyAccess node => node.propertyName,
    MethodInvocation node => node.methodName,
    PropertyAccess node => node.propertyName,
    CallInvocation node => node.receiver.nodeToAnnotate,
    _ => this,
  };
}
