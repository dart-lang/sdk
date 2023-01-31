// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

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
  static const LintCode code = LintCode(
      'implicit_call_tearoffs', "Implicit tear-off of the 'call' method.",
      correctionMessage: "Try explicitly tearing off the 'call' method.");

  ImplicitCallTearoffs()
      : super(
          name: 'implicit_call_tearoffs',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

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
