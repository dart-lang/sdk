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
```dart
MyState global;

class MyStateful extends StatefulWidget {
  @override
  MyState createState() {
    global = MyState();
    return global;
  } 
}
```

```dart
class MyStateful extends StatefulWidget {
  @override
  MyState createState() => MyState()..field = 42;
}
```

```dart
class MyStateful extends StatefulWidget {
  @override
  MyState createState() => MyState(42);
}
```


**GOOD:**
```dart
class MyStateful extends StatefulWidget {
  @override
  MyState createState() {
    return MyState();
  }
}
```
''';

class NoLogicInCreateState extends LintRule {
  static const LintCode code = LintCode(
      'no_logic_in_create_state', "Don't put any logic in 'createState'.",
      correctionMessage: "Try moving the logic out of 'createState'.");

  NoLogicInCreateState()
      : super(
            name: 'no_logic_in_create_state',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'createState') {
      return;
    }

    var parent = node.parent;
    if (parent is! ClassDeclaration ||
        !isStatefulWidget(parent.declaredElement)) {
      return;
    }
    var body = node.body;
    Expression? expressionToTest;
    if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length == 1) {
        var statement = statements.first;
        if (statement is ReturnStatement) {
          expressionToTest = statement.expression;
        }
      }
    } else if (body is ExpressionFunctionBody) {
      expressionToTest = body.expression;
    } else if (body is EmptyFunctionBody) {
      return;
    }

    if (expressionToTest is InstanceCreationExpression) {
      if (expressionToTest.argumentList.arguments.isEmpty) {
        return;
      }
    }
    rule.reportLint(expressionToTest ?? body);
  }
}
