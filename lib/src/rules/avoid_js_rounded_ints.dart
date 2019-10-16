// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid JavaScript rounded ints.';

const _details = r'''

**AVOID** integer literals that cannot be represented exactly when compiled to
JavaScript.

When a program is compiled to JavaScript `int` and `double` become JavaScript
Numbers. Too large integers (`value < Number.MIN_SAFE_INTEGER` or
`value > Number.MAX_SAFE_INTEGER`) may be rounded to the closest Number value.

For instance `1000000000000000001` cannot be represented exactly as a JavaScript
Number, so `1000000000000000000` will be used instead.

**BAD:**
```
int value = 9007199254740995;
```

**GOOD:**
```
BigInt value = BigInt.parse('9007199254740995');
```

''';

class AvoidJsRoundedInts extends LintRule implements NodeLintRule {
  AvoidJsRoundedInts()
      : super(
            name: 'avoid_js_rounded_ints',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addIntegerLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isRounded(int value) => value?.toDouble()?.toInt() != value;
  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    if (isRounded(node.value)) {
      rule.reportLint(node);
    }
  }
}
