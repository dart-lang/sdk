// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc =
    r'Explicitly tear-off `call` methods when using an object as a Function.';

const _details = r'''
**DO**
Explicitly tear off `.call` methods from objects when assigning to a Function
type. There is less magic with an explicit tear off. Future language versions
may remove the implicit call tear off.

**BAD:**
```dart
class Callable {
  void call() {}
}
void callIt(void Function() f) {
  f();
}

callIt(Callable());
```

**GOOD:**
```dart
class Callable {
  void call() {}
}
void callIt(void Function() f) {
  f();
}

callIt(Callable().call);
```

''';

class ImplicitCallTearoffs extends LintRule {
  ImplicitCallTearoffs()
      : super(
          name: 'implicit_call_tearoffs',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.implicit_call_tearoffs;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addImplicitCallReference(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    rule.reportLint(node);
  }
}
