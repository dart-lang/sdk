// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't specify the `late` modifier when it is not needed.";

const _details = r'''
**DO** not specify the `late` modifier for top-level and static variables
when the declaration contains an initializer. 

Top-level and static variables with initializers are already evaluated lazily
as if they are marked `late`.

**BAD:**
```dart
late String badTopLevel = '';
```

**GOOD:**
```dart
String goodTopLevel = '';
```

**BAD:**
```dart
class BadExample {
  static late String badStatic = '';
}
```

**GOOD:**
```dart
class GoodExample {
  late String goodStatic;
}
```
''';

class UnnecessaryLate extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_late', "Unnecessary 'late' modifier.",
      correctionMessage: "Try removing the 'late'.");

  UnnecessaryLate()
      : super(
            name: 'unnecessary_late',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic) {
      _visitVariableDeclarations(node.fields);
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _visitVariableDeclarations(node.variables);
  }

  void _visitVariableDeclarations(VariableDeclarationList node) {
    if (node.lateKeyword == null) return;
    if (node.variables.any((v) => v.initializer == null)) {
      return;
    }

    rule.reportLintForToken(node.lateKeyword);
  }
}
