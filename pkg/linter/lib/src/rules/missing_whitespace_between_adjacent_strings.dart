// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Missing whitespace between adjacent strings.';

class MissingWhitespaceBetweenAdjacentStrings extends LintRule {
  MissingWhitespaceBetweenAdjacentStrings()
    : super(
        name: LintNames.missing_whitespace_between_adjacent_strings,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.missing_whitespace_between_adjacent_strings;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addAdjacentStrings(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // Skip strings passed to `RegExp()` or any method named `matches`.
    var parent = node.parent;
    if (parent is ArgumentList) {
      var parentParent = parent.parent;
      if (_isRegExpInstanceCreation(parentParent) ||
          parentParent is MethodInvocation &&
              parentParent.realTarget == null &&
              const [
                'RegExp',
                'matches',
              ].contains(parentParent.methodName.name)) {
        return;
      }
    }

    for (var i = 0; i < node.strings.length - 1; i++) {
      var current = node.strings[i];
      var next = node.strings[i + 1];
      if (current.endsWithWhitespace || next.startsWithWhitespace) {
        continue;
      }
      if (!current.hasWhitespace) {
        continue;
      }
      rule.reportAtNode(current);
    }

    return super.visitAdjacentStrings(node);
  }

  static bool _isRegExpInstanceCreation(AstNode? node) {
    if (node is InstanceCreationExpression) {
      var constructorElement = node.constructorName.element;
      return constructorElement?.enclosingElement.name == 'RegExp';
    }
    return false;
  }
}

extension on StringLiteral {
  /// Returns whether this ends with whitespace, where an initial
  /// [InterpolationExpression] counts as whitespace.
  bool get endsWithWhitespace {
    var self = this;
    if (self is SimpleStringLiteral) {
      return self.value.endsWithWhitespace;
    } else if (self is StringInterpolation) {
      var last = self.elements.last as InterpolationString;
      return last.value.isEmpty || last.value.endsWithWhitespace;
    }
    throw ArgumentError(
      'Expected SimpleStringLiteral or StringInterpolation, but got '
      '$runtimeType',
    );
  }

  /// Returns whether this contains whitespace, where any
  /// [InterpolationExpression] does not count as whitespace.
  bool get hasWhitespace {
    var self = this;
    if (self is SimpleStringLiteral) {
      return self.value.hasWhitespace;
    } else if (self is StringInterpolation) {
      return self.elements.any(
        (e) => e is InterpolationString && e.value.hasWhitespace,
      );
    }
    return false;
  }

  /// Returns whether this starts with whitespace, where an initial
  /// [InterpolationExpression] counts as whitespace.
  bool get startsWithWhitespace {
    var self = this;
    if (self is SimpleStringLiteral) {
      return self.value.startsWithWhitespace;
    } else if (self is StringInterpolation) {
      var first = self.elements.first as InterpolationString;
      return first.value.isEmpty || first.value.startsWithWhitespace;
    }
    throw ArgumentError(
      'Expected SimpleStringLiteral or StringInterpolation, but got '
      '$runtimeType',
    );
  }
}

extension on String {
  static const whitespaces = [' ', '\n', '\r', '\t'];
  bool get endsWithWhitespace => whitespaces.any(endsWith);
  bool get hasWhitespace => whitespaces.any(contains);

  bool get startsWithWhitespace => whitespaces.any(startsWith);
}
