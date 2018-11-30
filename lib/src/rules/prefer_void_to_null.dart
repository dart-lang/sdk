// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const _desc =
    r"Don't use the Null type, unless you are positive that you don't want void.";

const _details = r'''

**DO NOT** use the type Null where void would work.

**BAD:**
```
Null f() {}
Future<Null> f() {}
Stream<Null> f() {}
f(Null x) {}
```

**GOOD:**
```
void f() {}
Future<void> f() {}
Stream<void> f() {}
f(void x) {}
```

Some exceptions include formulating special function types:

```
Null Function(Null, Null);
```

and for making empty literals which are safe to pass into read-only locations
for any type of map or list:

```
<Null>[];
<int, Null>{};
```
''';

class PreferVoidToNull extends LintRule implements NodeLintRuleWithContext {
  PreferVoidToNull()
      : super(
            name: 'prefer_void_to_null',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier id) {
    final element = id.staticElement;
    if (element is ClassElement && element.type.isDartCoreNull) {
      final typeName =
          id.parent is PrefixedIdentifier ? id.parent.parent : id.parent;

      final parent = typeName.parent;

      // Null Function()
      if (parent is GenericFunctionType) {
        return;
      }

      // Function(Null)
      if (parent is SimpleFormalParameter &&
          parent.parent is FormalParameterList &&
          parent.parent.parent is GenericFunctionType) {
        return;
      }

      // <Null>[] or <Null, Null>{}
      if (parent is TypeArgumentList) {
        final literal = parent.parent;
        if (literal is ListLiteral && literal.elements.isEmpty) {
          return;
        } else if (literal is MapLiteral && literal.entries.isEmpty) {
          return;
        }
      }

      rule.reportLintForToken(id.token);
    }
  }
}
