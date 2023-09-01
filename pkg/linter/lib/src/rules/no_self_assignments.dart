// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't assign a variable to itself.";

const _details = r'''
**DON'T** assign a variable to itself. Usually this is a mistake.

**BAD:**
```dart
class C {
  int x;

  C(int x) {
    x = x;
  }
}
```

**GOOD:**
```dart
class C {
  int x;

  C(int x) : x = x;
}
```

**GOOD:**
```dart
class C {
  int x;

  C(int x) {
    this.x = x;
  }
}
```

**BAD:**
```dart
class C {
  int _x = 5;

  int get x => _x;

  set x(int x) {
    _x = x;
    _customUpdateLogic();
  }

  void _customUpdateLogic() {
    print('updated');
  }

  void example() {
    x = x;
  }
}
```

**GOOD:**
```dart
class C {
  int _x = 5;

  int get x => _x;

  set x(int x) {
    _x = x;
    _customUpdateLogic();
  }

  void _customUpdateLogic() {
    print('updated');
  }

  void example() {
    _customUpdateLogic();
  }
}
```

**BAD:**
```dart
class C {
  int x = 5;

  void update(C other) {
    this.x = this.x;
  }
}
```

**GOOD:**
```dart
class C {
  int x = 5;

  void update(C other) {
    this.x = other.x;
  }
}
```

''';

class NoSelfAssignments extends LintRule {
  static const LintCode code = LintCode('no_self_assignments',
      'The variable or property is being assigned to itself.',
      correctionMessage:
          'Try removing the assignment that has no direct effect.');

  NoSelfAssignments()
      : super(
            name: 'no_self_assignments',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAssignmentExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.EQ) return;
    var lhs = node.leftHandSide;
    var rhs = node.rightHandSide;
    if (lhs is Identifier && rhs is Identifier) {
      if (lhs.name == rhs.name) {
        rule.reportLint(node);
      }
    }
  }
}
