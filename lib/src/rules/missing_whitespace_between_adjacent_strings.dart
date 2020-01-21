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
```
var s =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed'
  'do eiusmod tempor incididunt ut labore et dolore magna';
```

**GOOD:**
```
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
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // skip regexp
    if (node.parent is ArgumentList) {
      final parentParent = node.parent.parent;
      if (parentParent is InstanceCreationExpression &&
              parentParent.staticElement.enclosingElement.name == 'RegExp' ||
          parentParent is MethodInvocation &&
              parentParent.realTarget == null &&
              const ['RegExp', 'matches']
                  .contains(parentParent.methodName.name)) {
        return;
      }
    }

    for (var i = 0; i < node.strings.length - 1; i++) {
      final current = node.strings[i];
      final next = node.strings[i + 1];
      if (_visit(current, (l) => _endsWithWhitespace(l.last)) ||
          _visit(next, (l) => _startsWithWhitespace(l.first))) {
        continue;
      }
      if (!_visit(current, (l) => l.any(_hasWhitespace))) {
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
      return test(string.elements.map((e) {
        if (e is InterpolationString) return e.value;
        return '';
      }));
    }
    throw ArgumentError('${string.runtimeType}: $string');
  }

  bool _hasWhitespace(String value) => _whitespaces.any(value.contains);
  bool _endsWithWhitespace(String value) => _whitespaces.any(value.endsWith);
  bool _startsWithWhitespace(String value) =>
      _whitespaces.any(value.startsWith);
}

const _whitespaces = [' ', '\n', '\r', '\t'];
