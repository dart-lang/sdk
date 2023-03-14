// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't use adjacent strings in list.";

const _details = r'''
**DON'T** use adjacent strings in a list.

This can indicate a forgotten comma.

**BAD:**
```dart
List<String> list = <String>[
  'a'
  'b',
  'c',
];
```

**GOOD:**
```dart
List<String> list = <String>[
  'a' +
  'b',
  'c',
];
```

''';

class NoAdjacentStringsInList extends LintRule {
  static const LintCode code = LintCode('no_adjacent_strings_in_list',
      "Don't use adjacent strings in a list literal.",
      correctionMessage: 'Try adding a comma between the strings.');

  NoAdjacentStringsInList()
      : super(
            name: 'no_adjacent_strings_in_list',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addForElement(this, visitor);
    registry.addIfElement(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
    registry.addSwitchPatternCase(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void check(AstNode? element) {
    if (element is AdjacentStrings) {
      rule.reportLint(element);
    }
  }

  @override
  void visitForElement(ForElement node) {
    if (node.body is AdjacentStrings) {
      check(node.body);
    }
  }

  @override
  void visitIfElement(IfElement node) {
    if (node.elseElement == null && node.thenElement is AdjacentStrings) {
      rule.reportLint(node.thenElement);
    } else {
      check(node.elseElement);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    node.elements.forEach(check);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isMap) return;
    node.elements.forEach(check);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    var pattern = node.guardedPattern.pattern.unParenthesized;
    if (pattern is! ListPattern) return;
    for (var element in pattern.elements) {
      if (element is ConstantPattern) {
        check(element.expression.unParenthesized);
      }
    }
  }
}
