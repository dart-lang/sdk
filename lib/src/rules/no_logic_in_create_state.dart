// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r"Don't put any logic in createState.";

const _details = r'''
**DON'T** put any logic in `createState()`.

Implementations of  `createState()` should return a new instance
of a State object and do nothing more.  Since state access is preferred 
via the `widget` field,  passing data to `State` objects using custom
constructor parameters should also be avoided and so further, the State
constructor is required to be passed no arguments.

**BAD:**
```
MyState global;

class MyStateful extends StatefulWidget {
  @override
  MyState createState() {
    global = MyState();
    return global;
  } 
}
```

```
class MyStateful extends StatefulWidget {
  @override
  MyState createState() => MyState()..field = 42;
}
```

```
class MyStateful extends StatefulWidget {
  @override
  MyState createState() => MyState(42);
}
```


**GOOD:**
```
class MyStateful extends StatefulWidget {
  @override
  MyState createState() {
    return MyState();
  }
}
```
''';

class NoLogicInCreateState extends LintRule implements NodeLintRule {
  NoLogicInCreateState()
      : super(
            name: 'no_logic_in_create_state',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.name != 'createState') {
      return;
    }

    final parent = node.parent;
    if (parent is! ClassDeclaration ||
        !isStatefulWidget((parent as ClassDeclaration).declaredElement)) {
      return;
    }
    final body = node.body;
    Expression expressionToTest;
    if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length == 1) {
        final statement = statements[0];
        if (statement is ReturnStatement) {
          expressionToTest = statement.expression;
        }
      }
    } else if (body is ExpressionFunctionBody) {
      expressionToTest = body.expression;
    }

    if (expressionToTest is InstanceCreationExpression) {
      if (expressionToTest.argumentList.arguments.isEmpty) {
        return;
      }
    }
    rule.reportLint(expressionToTest ?? body);
  }
}
