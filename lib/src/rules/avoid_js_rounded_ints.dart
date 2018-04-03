// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid JavaScript rounded ints.';

const _details = r'''

**AVOID** integers that will be rounded.

When a program is compiled to JavaScript `int` and `double` become JavaScript
Numbers. Too large integers (`value < Number.MIN_SAFE_INTEGER` or
`value > Number.MAX_SAFE_INTEGER`) may be rounded to the closest Number value.

**BAD:**
```
int value = 9007199254740995;
```

**GOOD:**
```
BigInt value = BigInt.parse('9007199254740995');
```

''';

class AvoidJsRoundedInts extends LintRule {
  AvoidJsRoundedInts()
      : super(
            name: 'avoid_js_rounded_ints',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitIntegerLiteral(IntegerLiteral node) {
    if (isRounded(node.value)) {
      rule.reportLint(node);
    }
  }

  bool isRounded(int value) {
    int v = value.abs();
    while (v > 9007199254740991) {
      if (v.isOdd) return true;
      v = v ~/ 2;
    }
    return false;
  }
}
