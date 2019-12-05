// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Await only futures.';

const _details = r'''

**AVOID** using await on anything other than a future.

**BAD:**
```
main() async {
  print(await 23);
}
```

**GOOD:**
```
main() async {
  print(await Future.value(23));
}
```

''';

class AwaitOnlyFutures extends LintRule implements NodeLintRule {
  AwaitOnlyFutures()
      : super(
            name: 'await_only_futures',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addAwaitExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const LintCode _errorCode = LintCode('await_only_futures',
      "'await' applied to '{0}', which is not a 'Future'.");

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (node.expression is NullLiteral) return;

    final type = node.expression.staticType;
    if (!(type == null ||
        type.isDartAsyncFuture ||
        type.isDynamic ||
        DartTypeUtilities.extendsClass(type, 'Future', 'dart.async') ||
        DartTypeUtilities.implementsInterface(type, 'Future', 'dart.async') ||
        DartTypeUtilities.isClass(type, 'FutureOr', 'dart.async'))) {
      rule.reportLintForToken(node.awaitKeyword,
          errorCode: _errorCode, arguments: [type]);
    }
  }
}
