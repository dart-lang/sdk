// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Use spread collections when possible.';

const _details = r'''

Use spread collections when possible.

Collection literals are excellent when you want to create a new collection out 
of individual items. But, when existing items are already stored in another 
collection, spread collection syntax leads to simpler code.

**BAD:**

```
Widget build(BuildContext context) {
  return CupertinoPageScaffold(
    child: ListView(
      children: [
        Tab2Header(),
      ]..addAll(buildTab2Conversation()),
    ),
  );
}
```

```
var ints = [1, 2, 3];
print(['a']..addAll(ints.map((i) => i.toString()))..addAll(['c']));
```

```
var things;
var l = ['a']..addAll(things ?? const []);
```


**GOOD:**

```
Widget build(BuildContext context) {
  return CupertinoPageScaffold(
    child: ListView(
      children: [
        Tab2Header(),
        ...buildTab2Conversation(),
      ],
    ),
  );
}
```

```
var ints = [1, 2, 3];
print(['a', ...ints.map((i) => i.toString()), 'c');
```

```
var things;
var l = ['a', ...?things];
```
''';

class SpreadCollections extends LintRule implements NodeLintRule {
  SpreadCollections()
      : super(
            name: 'spread_collections',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation invocation) {
    if (invocation.methodName.name != 'addAll' ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      return;
    }

    CascadeExpression cascade = invocation.thisOrAncestorOfType();
    NodeList<Expression> sections = cascade.cascadeSections;
    Expression target = cascade.target;
    if (target is! ListLiteral || sections[0] != invocation) {
      return;
    }

    rule.reportLint(invocation.methodName);
  }
}
