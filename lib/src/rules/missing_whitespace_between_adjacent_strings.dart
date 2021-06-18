// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Missing whitespace between adjacent strings.';

const _details = r'''

Add a trailing whitespace to prevent missing whitespace between adjacent
strings.

With long text split accross adjacent strings it's easy to forget a whitespace
between strings.

**BAD:**
```dart
var s =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed'
  'do eiusmod tempor incididunt ut labore et dolore magna';
```

**GOOD:**
```dart
var s =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed '
  'do eiusmod tempor incididunt ut labore et dolore magna';
```

''';

class MissingWhitespaceBetweenAdjacentStrings extends LintRule
    implements NodeLintRule {
  MissingWhitespaceBetweenAdjacentStrings()
      : super(
            name: 'missing_whitespace_between_adjacent_strings',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
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
              const ['RegExp', 'matches']
                  .contains(parentParent.methodName.name)) {
        return;
      }
    }

    for (var i = 0; i < node.strings.length - 1; i++) {
      var current = node.strings[i];
      var next = node.strings[i + 1];
      if (_visit(current, (l) => l.last.endsWithWhitespace) ||
          _visit(next, (l) => l.first.startsWithWhitespace)) {
        continue;
      }
      if (!_visit(current, (l) => l.any((e) => e.hasWhitespace))) {
        continue;
      }
      rule.reportLint(current);
    }

    return super.visitAdjacentStrings(node);
  }

  bool _visit(StringLiteral string, bool Function(Iterable<String>) test) {
    if (string is SimpleStringLiteral) {
      return test([string.value]);
    } else if (string is StringInterpolation) {
      var interpolationSubstitutions = <String>[];
      for (var e in string.elements) {
        // Given a [StringInterpolation] like '$text', the elements include
        // empty [InterpolationString]s on either side of the
        // [InterpolationExpression]. Don't include them in the evaluation.
        if (e is InterpolationString && e.value.isNotEmpty) {
          interpolationSubstitutions.add(e.value);
        }
        if (e is InterpolationExpression) {
          // Treat an interpolation expression as a string with whitespace. This
          // prevents over-reporting on adjascent Strings which start or end
          // with interpolations.
          interpolationSubstitutions.add(' ');
        }
      }
      return test(interpolationSubstitutions);
    }
    throw ArgumentError('${string.runtimeType}: $string');
  }

  static bool _isRegExpInstanceCreation(AstNode? node) {
    if (node is InstanceCreationExpression) {
      var constructorElement = node.constructorName.staticElement;
      return constructorElement?.enclosingElement.name == 'RegExp';
    }
    return false;
  }
}

extension on String {
  bool get hasWhitespace => whitespaces.any(contains);
  bool get endsWithWhitespace => whitespaces.any(endsWith);
  bool get startsWithWhitespace => whitespaces.any(startsWith);

  static const whitespaces = [' ', '\n', '\r', '\t'];
}
