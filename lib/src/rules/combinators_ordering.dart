// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';

const _desc = r'Sort combinator names alphabetically.';

const _details = r'''
**DO** sort combinator names alphabetically.

**BAD:**
```dart
import 'a.dart' show B, A hide D, C;
export 'a.dart' show B, A hide D, C;
```

**GOOD:**
```dart
import 'a.dart' show A, B hide C, D;
export 'a.dart' show A, B hide C, D;
```

''';

class CombinatorsOrdering extends LintRule {
  CombinatorsOrdering()
      : super(
          name: 'combinators_ordering',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addHideCombinator(this, visitor);
    registry.addShowCombinator(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final LintRule rule;

  @override
  void visitHideCombinator(HideCombinator node) {
    if (!node.hiddenNames.map((e) => e.name).isSorted()) {
      rule.reportLint(node);
    }
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    if (!node.shownNames.map((e) => e.name).isSorted()) {
      rule.reportLint(node);
    }
  }
}
